class_name Construcao
extends StaticBody2D
## Peça construída pelo jogador, ocupando um tile (16x16): parede, porta, chão, tocha,
## fogueira, baú e bancada. Golpear quebra (alguns golpes) e devolve o item a quem quebrou,
## como no Minecraft.
##   parede   bloqueia todo mundo
##   porta    jogador passa (abre sozinha quando alguém chega perto); slime não passa
##   chão     fica embaixo de tudo, não bloqueia
##   tocha    ilumina à noite e protege dos slimes da noite (raio pequeno)
##   fogueira ilumina e protege (raio maior)
##   bancada  segurar E abre a fabricação 3x3
## O anfitrião decide pôr e quebrar (World); todos criam a peça com o mesmo nome.

const ARTE := "res://assets/sprites/tiny/construcao/"
const ACAMPAMENTO := preload("res://assets/sprites/tiny/acampamento.png")
const LUZ := preload("res://assets/luz/luz_radial.tres")
## Fogueira (L41): UM desenho inteiro por quadro (anel de pedras, lenha e chamas), 6 quadros
## de 128x128 em laço, pedido do zero ao Codex (art/prompts/pedidos/L41_fogueira.md) e
## terminado por tools/montar_fogueira.gd (pedras firmes entre os quadros e sombra do pacote).
## As faíscas já vêm no desenho. Substitui a de remendo do L37 (pedras do L12 sem as chamas +
## chamas por cima + faíscas do Pixelbolt).
const FOGUEIRA := preload("res://assets/sprites/tiny/fogueira.png")
const QUADRO_FOGUEIRA := Vector2i(128, 128)
const QUADROS_CHAMAS := 6
const FPS_CHAMAS := 8.0
## A luz da fogueira tremula: energia e tamanho variam um pouco, sem parar.
const TREMOR_LUZ := 0.12
static var _quadros_chamas: SpriteFrames
## Golpes para quebrar cada peça.
const GOLPES := {&"parede": 4, &"porta": 3, &"chao": 2, &"tocha": 1, &"fogueira": 2, &"bau": 3, &"bancada": 3}
## Camada só das portas: os slimes batem nela, os jogadores não.
const CAMADA_PORTA := 1 << 6

var tipo: StringName  # a construção (parede, porta...)
var item: StringName  # o item que volta ao quebrar
var celula: Vector2i
## Parede ou porta girada (vista de lado, correndo de cima para baixo): rodinha do mouse.
var lateral := false
var _golpes := 0
var _sprite: Sprite2D
var _aberta := false
## Baú: o que está guardado ([[id, qtd], ...], só o anfitrião sabe) e quem está com ele aberto.
var conteudo: Array = []
var em_uso_por: Node
## Peça do acampamento: não quebra.
var fixa := false
var _chamas: AnimatedSprite2D
var _luz_no: PointLight2D
var _luz_energia := 0.0
var _luz_escala := 0.0
var _tempo := 0.0


func _ready() -> void:
	add_to_group(&"construcoes")
	_golpes = GOLPES.get(tipo, 2)
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.scale = Vector2(0.25, 0.25)
	add_child(_sprite)
	match tipo:
		&"parede":
			_mostrar(_arte("parede"))
			_colisao(Vector2(6, 16) if lateral else Vector2(16, 8), 1)
		&"porta":
			_mostrar(_arte("porta_fechada"))
			_colisao(Vector2(6, 16) if lateral else Vector2(16, 8), CAMADA_PORTA)
		&"chao":
			_mostrar(load(ARTE + "chao.png"))  # fica no nó Pisos, embaixo do resto (World)
		&"tocha":
			_mostrar(load(ARTE + "tocha.png"))
			_luz(0.8, 0.8, 44.0)
		&"fogueira":
			_mostrar_fogueira()
			_luz(3.6, 0.8, 60.0)
			_area_de_uso()
		&"bau":
			_mostrar_acampamento(2)
			_colisao(Vector2(13, 6), 1)
			_area_de_uso()
		&"bancada":
			_mostrar_acampamento(4)
			_colisao(Vector2(24, 8), 1)
			add_to_group(&"bancadas")
			_area_de_uso()
	_hurtbox()


## Pés da arte no fundo do tile (as peças do L18 vêm com a base 0; o acampamento com 8 px).
func _mostrar(tex: Texture2D, pe := 0) -> void:
	_sprite.texture = tex
	_sprite.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height() + pe)
	_sprite.position = Vector2(0, 0)


func _mostrar_acampamento(quadro: int) -> void:
	_sprite.texture = ACAMPAMENTO
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(quadro * 128, 0, 128, 128)
	_sprite.offset = Vector2(-64, -128 + 8)


## A fogueira inteira (pedras, lenha e chamas) num desenho animado só. Ele fica dentro do
## sprite da peça (o brilho de "dá para usar" e o tremor do golpe valem para ele). Cada
## fogueira começa num quadro diferente, para duas fogueiras não piscarem juntas.
func _mostrar_fogueira() -> void:
	if _quadros_chamas == null:
		_quadros_chamas = SpriteFrames.new()
		_quadros_chamas.remove_animation(&"default")
		SpriteSheets.adicionar_tira(_quadros_chamas, FOGUEIRA, &"fogo", QUADRO_FOGUEIRA, QUADROS_CHAMAS, FPS_CHAMAS)
	_chamas = AnimatedSprite2D.new()
	_chamas.name = "Chamas"
	_chamas.sprite_frames = _quadros_chamas
	_chamas.centered = false
	_chamas.offset = Vector2(-QUADRO_FOGUEIRA.x / 2.0, -QUADRO_FOGUEIRA.y + 8)
	_sprite.add_child(_chamas)
	_chamas.play(&"fogo")
	_chamas.frame = absi(hash(name)) % QUADROS_CHAMAS


## A fogueira está animada? (Para os testes.)
func chamas() -> AnimatedSprite2D:
	return _chamas


func _colisao(tamanho: Vector2, camada: int) -> void:
	collision_layer = camada
	var forma := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = tamanho
	forma.shape = r
	forma.position = Vector2(0, -tamanho.y / 2.0)
	add_child(forma)


func _luz(escala: float, energia: float, raio_protecao: float) -> void:
	var luz := PointLight2D.new()
	luz.texture = LUZ
	luz.color = Color(1, 0.6, 0.3)
	luz.energy = energia
	luz.texture_scale = escala
	luz.position = Vector2(0, -12)
	luz.add_to_group(&"luzes_noturnas")
	var w := get_tree().get_first_node_in_group(&"mundo") as World
	luz.enabled = w != null and w.noite
	add_child(luz)
	_luz_no = luz
	_luz_energia = energia
	_luz_escala = escala
	add_to_group(&"luz_protege")
	set_meta(&"raio_luz", raio_protecao)


func _hurtbox() -> void:
	var h := Hurtbox.new()
	var forma := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(16, 14)
	forma.shape = r
	forma.position = Vector2(0, -7)
	h.add_child(forma)
	add_child(h)
	if multiplayer.is_server():
		h.atingido.connect(_on_atingido)


func _area_de_uso() -> void:
	var area := Area2D.new()
	area.name = "Interactable"
	area.set_script(preload("res://scripts/components/interactable.gd"))
	area.set(&"alcance", 34.0)
	area.set(&"tempo_segurar", 0.15)
	var forma := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(26, 18)
	forma.shape = r
	forma.position = Vector2(0, -10)
	area.add_child(forma)
	add_child(area)


# --- Bancada (Interactable) --------------------------------------------------------

func pode_interagir() -> bool:
	return tipo in [&"bancada", &"bau", &"fogueira"]


func texto_acao() -> String:
	return {&"bau": "Abrir baú", &"fogueira": "Assar carne"}.get(tipo, "Usar bancada")


func destacar(ligado: bool) -> void:
	_sprite.modulate = Color(1.15, 1.15, 1.05) if ligado else Color.WHITE


func altura_visivel() -> float:
	return 20.0


func interagir(quem: Player) -> void:
	if tipo == &"bancada":
		quem.inventario.na_bancada = true
		quem.inventario.reenviar()
		quem.abrir_mochila.rpc_id(quem.get_multiplayer_authority(), &"bancada")
	elif tipo == &"fogueira":
		# Assar: a carne crua da mão vira carne assada (uma por clique).
		var i := quem.barra_escolhida
		if quem.inventario.item_em(i) == &"carne_crua":
			quem.inventario.gastar(i, 1)
			quem.inventario.adicionar(&"carne_assada", 1)
			quem.avisar("+1 carne assada", &"item")
		else:
			quem.avisar("Clique na fogueira com carne crua na mão para assar.")
	elif tipo == &"bau":
		if quem.inventario.abrir_bau(self):
			quem.abrir_mochila.rpc_id(quem.get_multiplayer_authority(), &"bau")
		else:
			quem.avisar("Outro jogador está com este baú aberto.")


# --- Porta e quebrar ---------------------------------------------------------------

func _process(delta: float) -> void:
	if tipo == &"fogueira":
		_tremer_luz(delta)
		return
	if tipo != &"porta":
		return
	var perto := false
	for j in get_tree().get_nodes_in_group(&"jogadores"):
		if (j as Node2D).global_position.distance_to(global_position) < 18.0:
			perto = true
	if perto != _aberta:
		_aberta = perto
		_mostrar(_arte("porta_aberta" if perto else "porta_fechada"))


## A luz da fogueira tremula de leve: duas ondas de velocidades diferentes, como uma chama.
func _tremer_luz(delta: float) -> void:
	if _luz_no == null or not _luz_no.enabled:
		return
	_tempo += delta
	var t := sin(_tempo * 7.3) * 0.6 + sin(_tempo * 13.1 + 1.7) * 0.4
	_luz_no.energy = _luz_energia * (1.0 + TREMOR_LUZ * t)
	_luz_no.texture_scale = _luz_escala * (1.0 + TREMOR_LUZ * 0.25 * t)


## Só o anfitrião: cada golpe de jogador tira um pouco; no último, a peça volta como item.
func _on_atingido(_quantidade: float, dano: StringName, origem: Node) -> void:
	if dano != &"fisico" or not origem is Player or fixa:
		return
	_golpes -= 1
	Sfx.tocar(&"golpe_coleta")
	var t := create_tween()
	t.tween_property(_sprite, "position:x", 1.5, 0.04)
	t.tween_property(_sprite, "position:x", -1.5, 0.06)
	t.tween_property(_sprite, "position:x", 0.0, 0.04)
	if _golpes <= 0:
		# Baú quebrado: quem estava com ele aberto fecha, e o que tinha dentro cai no chão.
		if is_instance_valid(em_uso_por):
			(em_uso_por as Player).inventario.fechar_bau_servidor()
		World.soltar_itens(self, global_position + Vector2(0, -6), conteudo)
		(origem as Player).inventario.adicionar(item, 1)
		World.quebrar_construcao(self)


## Arte da peça; girada usa a versão vista de lado (<nome>_lado.png), se existir.
func _arte(nome: String) -> Texture2D:
	var lado := ARTE + nome + "_lado.png"
	return load(lado) if lateral and ResourceLoader.exists(lado) else load(ARTE + nome + ".png")
