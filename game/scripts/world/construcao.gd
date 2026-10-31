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
## Golpes para quebrar cada peça.
const GOLPES := {&"parede": 4, &"porta": 3, &"chao": 2, &"tocha": 1, &"fogueira": 2, &"bau": 3, &"bancada": 3}
## Camada só das portas: os slimes batem nela, os jogadores não.
const CAMADA_PORTA := 1 << 6

var tipo: StringName  # a construção (parede, porta...)
var item: StringName  # o item que volta ao quebrar
var celula: Vector2i
var _golpes := 0
var _sprite: Sprite2D
var _aberta := false
## Baú: o que está guardado ([[id, qtd], ...], só o anfitrião sabe) e quem está com ele aberto.
var conteudo: Array = []
var em_uso_por: Node
## Peça do acampamento: não quebra.
var fixa := false


func _ready() -> void:
	add_to_group(&"construcoes")
	_golpes = GOLPES.get(tipo, 2)
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.scale = Vector2(0.25, 0.25)
	add_child(_sprite)
	match tipo:
		&"parede":
			_mostrar(load(ARTE + "parede.png"))
			_colisao(Vector2(16, 8), 1)
		&"porta":
			_mostrar(load(ARTE + "porta_fechada.png"))
			_colisao(Vector2(16, 8), CAMADA_PORTA)
		&"chao":
			_mostrar(load(ARTE + "chao.png"))  # fica no nó Pisos, embaixo do resto (World)
		&"tocha":
			_mostrar(load(ARTE + "tocha.png"))
			_luz(0.8, 0.8, 44.0)
		&"fogueira":
			_mostrar_acampamento(0)
			_luz(3.6, 0.8, 60.0)
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
	return tipo == &"bancada" or tipo == &"bau"


func texto_acao() -> String:
	return "Abrir baú" if tipo == &"bau" else "Usar bancada"


func destacar(ligado: bool) -> void:
	_sprite.modulate = Color(1.15, 1.15, 1.05) if ligado else Color.WHITE


func altura_visivel() -> float:
	return 20.0


func interagir(quem: Player) -> void:
	if tipo == &"bancada":
		quem.inventario.na_bancada = true
		quem.inventario.reenviar()
		quem.abrir_mochila.rpc_id(quem.get_multiplayer_authority(), &"bancada")
	elif tipo == &"bau":
		if quem.inventario.abrir_bau(self):
			quem.abrir_mochila.rpc_id(quem.get_multiplayer_authority(), &"bau")
		else:
			quem.avisar("Outro jogador está com este baú aberto.")


# --- Porta e quebrar ---------------------------------------------------------------

func _process(_delta: float) -> void:
	if tipo != &"porta":
		return
	var perto := false
	for j in get_tree().get_nodes_in_group(&"jogadores"):
		if (j as Node2D).global_position.distance_to(global_position) < 18.0:
			perto = true
	if perto != _aberta:
		_aberta = perto
		_mostrar(load(ARTE + ("porta_aberta.png" if perto else "porta_fechada.png")))


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
		# Baú quebrado: quem estava com ele aberto fecha, e o que tinha dentro vai para quem quebrou.
		if is_instance_valid(em_uso_por):
			(em_uso_por as Player).inventario.fechar_bau_servidor()
		for e in conteudo:
			if ItemData.existe(StringName(e[0])) and int(e[1]) > 0:
				(origem as Player).inventario.adicionar(StringName(e[0]), int(e[1]))
		(origem as Player).inventario.adicionar(item, 1)
		World.quebrar_construcao(self)
