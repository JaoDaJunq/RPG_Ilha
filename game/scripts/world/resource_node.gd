class_name ResourceNode
extends StaticBody2D
## Árvore, pedra e qualquer coisa que se coleta segurando E.
##
## Estados: INTEIRO → (fogo) QUEIMANDO → QUEIMADO → (coleta) ESGOTADO
##          INTEIRO → (coleta) ESGOTADO
## Cortar rende o item normal; queimar transforma o que ele rende (árvore → carvão).

enum Estado { INTEIRO, QUEIMANDO, QUEIMADO, ESGOTADO }

const TEXTURA_CHAMAS := preload("res://assets/placeholder/ninja/fx/chamas.png")

@export var acao := "Cortar"
@export var golpes := 3
@export var item_id: StringName = &"madeira"
@export var quantidade := 3
@export var acao_queimado := "Recolher carvão"
@export var item_queimado: StringName = &"carvao"
@export var quantidade_queimado := 2
## Some do mapa ao esgotar (pedra); se falso, vira a região "esgotado" (toco).
@export var some_ao_esgotar := false
@export var regiao_inteiro := Rect2()
@export var regiao_queimado := Rect2()
@export var regiao_esgotado := Rect2()

var estado := Estado.INTEIRO
var _golpes_restantes: int

@onready var sprite: Sprite2D = $Sprite2D
@onready var interacao: Interactable = $Interactable
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var inflamavel: Flammable = get_node_or_null("Flammable")
@onready var chamas: Node2D = get_node_or_null("Chamas")


func _ready() -> void:
	_golpes_restantes = golpes
	hurtbox.atingido.connect(_on_atingido)
	if inflamavel:
		inflamavel.apagou_queimado.connect(_on_queimou)
	if chamas:
		chamas.visible = false
		var f := SpriteFrames.new()
		f.remove_animation(&"default")
		SpriteSheets.adicionar_tira(f, TEXTURA_CHAMAS, &"queimando", Vector2i(12, 12), 8, 12.0)
		for c in chamas.get_children():
			if c is AnimatedSprite2D:
				c.sprite_frames = f
				c.play(&"queimando")
				c.frame = randi() % 8
	_mostrar(regiao_inteiro)


func pode_interagir() -> bool:
	return estado == Estado.INTEIRO or estado == Estado.QUEIMADO


func texto_acao() -> String:
	return acao_queimado if estado == Estado.QUEIMADO else acao


func destacar(ligado: bool) -> void:
	sprite.modulate = Color(1.15, 1.15, 1.05) if ligado else Color.WHITE


## Um "golpe" de coleta. Chamado pelo jogador a cada ciclo de segurar E.
## (No multiplayer, só o anfitrião chama isto.)
func interagir(quem: Node) -> void:
	if not pode_interagir():
		return
	Sfx.tocar(&"golpe_coleta")
	_tremer()
	if estado == Estado.QUEIMADO:
		_entregar(quem, item_queimado, quantidade_queimado)
		_esgotar()
		return
	_golpes_restantes -= 1
	if _golpes_restantes <= 0:
		_entregar(quem, item_id, quantidade)
		_esgotar()


func golpes_restantes() -> int:
	return _golpes_restantes


func _on_atingido(_quantidade: float, tipo: StringName, _origem: Node) -> void:
	if tipo == &"fogo" and estado == Estado.INTEIRO and inflamavel and inflamavel.acender():
		estado = Estado.QUEIMANDO
		chamas.visible = true
		Sfx.tocar(&"fogo")
		Events.aviso.emit("A árvore pegou fogo! Queimada, ela vira carvão em vez de madeira.")


func _on_queimou() -> void:
	estado = Estado.QUEIMADO
	chamas.visible = false
	_mostrar(regiao_queimado)


func _entregar(quem: Node, item: StringName, qtd: int) -> void:
	var inv: Inventory = quem.get_node_or_null("Inventory")
	if inv:
		inv.adicionar(item, qtd)
		Sfx.tocar(&"item")
		Events.aviso.emit("+%d %s" % [qtd, ItemData.carregar(item).nome.to_lower()])


func _esgotar() -> void:
	estado = Estado.ESGOTADO
	destacar(false)
	if some_ao_esgotar:
		queue_free()
		return
	_mostrar(regiao_esgotado)


func _mostrar(regiao: Rect2) -> void:
	sprite.region_enabled = true
	sprite.region_rect = regiao
	sprite.centered = false
	sprite.offset = Vector2(-regiao.size.x / 2.0, -regiao.size.y)


func _tremer() -> void:
	var t := create_tween()
	t.tween_property(sprite, "position:x", 1.5, 0.04)
	t.tween_property(sprite, "position:x", -1.5, 0.06)
	t.tween_property(sprite, "position:x", 0.0, 0.04)
