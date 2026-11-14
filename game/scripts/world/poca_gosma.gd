class_name PocaGosma
extends Node2D
## Poça de gosma do elemento da Mãe Gosma (fogo, gelo ou veneno). Cada jogador desenha a sua
## (a gosma manda criar em todos); só o anfitrião aplica o estado em quem pisa nela.
## Arte final: arena_gosma.png, quadro POCA. Sem ela, usa o slime achatado (placeholder).

const DURACAO := 9.0
const INTERVALO := 0.5
const MAX_POCAS := 10
const TEXTURA_BASE := preload("res://assets/sprites/tiny/pedras_slime.png")

var elemento: StringName = &"veneno"
var raio := 24.0
var _tempo := 0.0
var _tique := 0.0
var _sprite: Sprite2D


func _ready() -> void:
	add_to_group(&"pocas_gosma")
	# Poucas por vez: a mais velha some quando passa do limite.
	var todas := get_tree().get_nodes_in_group(&"pocas_gosma")
	if todas.size() > MAX_POCAS:
		todas[0].queue_free()
	_sprite = Sprite2D.new()
	var q := ArteGosma.quadro_arena(ArteGosma.Arena.POCA)
	var k: float
	if q:
		_sprite.texture = q
		k = raio * 2.0 / float(ArteGosma.QUADRO) * 1.3
		_sprite.scale = Vector2(k, k)
		_sprite.modulate = ArteGosma.COR.get(elemento, Color.WHITE)
	else:
		_sprite.texture = SpriteSheets.quadro(TEXTURA_BASE, 5, Vector2i(128, 128))
		k = raio * 2.0 / 128.0 * 1.8
		_sprite.scale = Vector2(k, k * 0.6)
		_sprite.modulate = ArteGosma.COR.get(elemento, Color.WHITE)
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	_tempo += delta
	_sprite.modulate.a = clampf((DURACAO - _tempo) / 1.5, 0.0, 1.0) * 0.9
	if _tempo >= DURACAO:
		queue_free()
		return
	if not multiplayer.is_server():
		return
	_tique += delta
	if _tique < INTERVALO:
		return
	_tique = 0.0
	var e: Dictionary = Slime.ELEMENTOS.get(elemento, {})
	if e.is_empty():
		return
	for j in get_tree().get_nodes_in_group(&"jogadores"):
		var p := j as Player
		if not p.caido and p.global_position.distance_to(global_position) <= raio:
			EfeitosEstado.aplicar_em(p, e.estado, 1.5, e.forca, null, 3)
