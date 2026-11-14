class_name ArenaGosma
extends StaticBody2D
## A arena da Mãe Gosma no coração do Pântano e o ALTAR (este nó fica no altar, na borda norte
## da arena; `centro` é o meio dela). Quem tem a Isca de Gosma interage com o altar: a isca é
## consumida e, depois de um aviso curto, a Mãe Gosma aparece (o grupo escolhe a hora).
##
## Só o anfitrião decide: chamar, vigiar (ela não sai da arena), resetar se todos saírem ou
## caírem (a isca fica no altar) e dar a recompensa. O estado "derrotada" e "isca no altar"
## mora no Missoes (salvo no mundo e mandado aos outros); a luta em si é o MaeGosma.
##
## Arte: altar em objetos_historia.png (quadros ALTAR_VAZIO e ALTAR_ISCA, ArteBrasinha) e a
## coroa caída em arena_gosma.png (quadro COROA, ArteGosma). Sem elas, usa placeholders.

const RAIO := 80.0
const CELULAS_LIVRES := 5  # raio, em blocos, de chão livre que a arena exige
const ATRASO_CHAMAR := 2.0
const TEMPO_RESET := 6.0
const CENA_BOSS := "res://scenes/enemies/mae_gosma.tscn"
const PLACEHOLDER := preload("res://assets/sprites/tiny/pedras_slime.png")
const COR_ALTAR := Color(0.8, 1.0, 0.8)
const COR_ALTAR_ISCA := Color(1.1, 1.1, 0.7)

var centro := Vector2.ZERO
## Segundos até a Mãe Gosma aparecer (-1 = ninguém chamou). Pode ser zerado nos testes.
var atraso_chamar := ATRASO_CHAMAR
var _chamando := -1.0
var _sem_ninguem := 0.0
var _sprite: Sprite2D
var _coroa: Sprite2D
var _chave := ""


static func da_cena(n: Node) -> ArenaGosma:
	return n.get_tree().get_first_node_in_group(&"arena_gosma") as ArenaGosma


func _ready() -> void:
	add_to_group(&"arena_gosma")
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.scale = Vector2(0.25, 0.25)
	_sprite.offset = Vector2(-64, -128 + 8)
	add_child(_sprite)
	var forma := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 7.0
	forma.shape = c
	forma.position = Vector2(0, -5)
	add_child(forma)
	var area := Area2D.new()
	area.name = "Interactable"
	area.set_script(preload("res://scripts/components/interactable.gd"))
	area.set(&"alcance", 34.0)
	area.set(&"tempo_segurar", 0.15)
	var f2 := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(28, 26)
	f2.shape = r
	f2.position = Vector2(0, -12)
	area.add_child(f2)
	add_child(area)
	_atualizar_visual()


# --- Estado (lido do Missoes, igual em todos) ----------------------------------------------

func _missoes() -> Missoes:
	var w := get_tree().get_first_node_in_group(&"mundo") as World
	return w.missoes if w else null


func derrotada() -> bool:
	var m := _missoes()
	return m != null and m.gosma_derrotada


func isca_no_altar() -> bool:
	var m := _missoes()
	return m != null and m.gosma_isca


## Tem alguma gosma da luta viva (ou foi chamada e está para aparecer)?
func luta_ativa() -> bool:
	return _chamando >= 0.0 or not get_tree().get_nodes_in_group(&"boss_gosma").is_empty()


func dentro(pos: Vector2, folga := 0.0) -> bool:
	return pos.distance_to(centro) <= RAIO + folga


## O ponto mais perto de `pos` que fica dentro da arena (com `folga` de sobra para dentro).
func limitar(pos: Vector2, folga := 0.0) -> Vector2:
	var d := pos - centro
	var max_d := RAIO - folga
	return centro + d.limit_length(max_d)


# --- Desenho ---------------------------------------------------------------------------

func _process(_delta: float) -> void:
	var chave := "%s%s%s" % [derrotada(), isca_no_altar() or luta_ativa(), luta_ativa()]
	if chave != _chave:
		_atualizar_visual()


func _atualizar_visual() -> void:
	_chave = "%s%s%s" % [derrotada(), isca_no_altar() or luta_ativa(), luta_ativa()]
	var com_isca := isca_no_altar() or luta_ativa()
	var q := ArteBrasinha.quadro(ArteBrasinha.OBJETOS, ArteBrasinha.Objeto.ALTAR_ISCA if com_isca else ArteBrasinha.Objeto.ALTAR_VAZIO)
	_sprite.region_enabled = true
	if q:
		_sprite.texture = q.atlas
		_sprite.region_rect = q.region
		_sprite.modulate = Color.WHITE
	else:
		_sprite.texture = PLACEHOLDER
		_sprite.region_rect = Rect2(0, 0, 128, 128)
		_sprite.modulate = COR_ALTAR_ISCA if com_isca else COR_ALTAR
	if derrotada() and _coroa == null:
		_montar_coroa()


## A coroa caída da Mãe Gosma, decoração no meio da arena (fica depois de derrotada).
func _montar_coroa() -> void:
	_coroa = Sprite2D.new()
	_coroa.top_level = true
	_coroa.global_position = centro
	_coroa.z_index = -1
	var q := ArteGosma.quadro_arena(ArteGosma.Arena.COROA)
	if q:
		_coroa.texture = q
		_coroa.scale = Vector2(0.25, 0.25)
	else:
		_coroa.texture = SpriteSheets.quadro(PLACEHOLDER, 5, Vector2i(128, 128))
		_coroa.scale = Vector2(0.18, 0.12)
		_coroa.modulate = Color(1.6, 1.3, 0.4)
	add_child(_coroa)


func coroa_visivel() -> bool:
	return _coroa != null


# --- Interação (altar) ---------------------------------------------------------------------

func pode_interagir() -> bool:
	return not derrotada() and not luta_ativa()


func texto_acao() -> String:
	return "Chamar a Mãe Gosma" if isca_no_altar() else "Pôr a Isca de Gosma"


func destacar(ligado: bool) -> void:
	if _sprite:
		_sprite.self_modulate = Color(1.15, 1.15, 1.05) if ligado else Color.WHITE


func altura_visivel() -> float:
	return 24.0


## Só o anfitrião chama (o jogador clicou no altar).
func interagir(quem: Player) -> void:
	if not multiplayer.is_server() or derrotada() or luta_ativa():
		return
	var m := _missoes()
	if m == null:
		return
	if not m.gosma_isca:
		if quem == null or quem.inventario.quantidade_de(&"isca_gosma") < 1:
			if quem:
				quem.avisar("O altar pede a Isca de Gosma. O Brasinha sabe fazer.")
			return
		quem.inventario.remover(&"isca_gosma", 1)
		quem.avisar("-1 isca de gosma", &"item")
		m.definir_gosma(true, false)
	chamar()


## Começa a chamada (anfitrião): depois de ATRASO_CHAMAR a Mãe Gosma aparece no meio.
func chamar() -> void:
	if not multiplayer.is_server() or derrotada() or luta_ativa():
		return
	_chamando = atraso_chamar
	World.avisar_todos(self, "A isca borbulha no altar... Preparem-se!")


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if _chamando >= 0.0:
		_chamando -= delta
		if _chamando < 0.0:
			_chamando = -1.0
			_aparecer()
		return
	var gosmas := get_tree().get_nodes_in_group(&"boss_gosma")
	if gosmas.is_empty():
		_sem_ninguem = 0.0
		return
	# Ela não sai da arena (volta se for longe)...
	for g in gosmas:
		var n := g as Node2D
		if n.global_position.distance_to(centro) > RAIO + 6.0:
			n.global_position = limitar(n.global_position, 6.0)
	# ...e a luta reseta se todos saírem ou caírem.
	var alguem := false
	for j in get_tree().get_nodes_in_group(&"jogadores"):
		var p := j as Player
		if not p.caido and dentro(p.global_position, 160.0):
			alguem = true
	_sem_ninguem = 0.0 if alguem else _sem_ninguem + delta
	if _sem_ninguem >= TEMPO_RESET:
		resetar()


func _aparecer() -> void:
	var g := (load(CENA_BOSS) as PackedScene).instantiate() as MaeGosma
	g.name = "MaeGosma"
	g.position = centro
	get_parent().add_child(g, true)
	_sem_ninguem = 0.0


## Todos saíram ou caíram: a Mãe Gosma volta para a lama e a isca fica no altar.
func resetar() -> void:
	_limpar_luta()
	var m := _missoes()
	if m:
		m.definir_gosma(true, m.gosma_derrotada)
	World.avisar_todos(self, "A Mãe Gosma voltou para a lama. A isca continua no altar.")
	_sem_ninguem = 0.0


func _limpar_luta() -> void:
	_chamando = -1.0
	for grupo in [&"boss_gosma", &"cria_gosma", &"pocas_gosma"]:
		for n in get_tree().get_nodes_in_group(grupo):
			if is_instance_valid(n):
				n.remove_from_group(grupo)
				n.queue_free()


## As 3 menores caíram (anfitrião): a recompensa e o fim do boss.
func vencer(pos: Vector2) -> void:
	if not multiplayer.is_server() or derrotada():
		return
	_limpar_luta()
	World.soltar_itens(self, pos, [[&"semente_coracao", 1], [&"gosma_real", 2]])
	var m := _missoes()
	if m:
		m.definir_gosma(false, true)
	World.avisar_todos(self, "A Mãe Gosma foi derrotada! Leve a Semente do Coração ao Brasinha.")
