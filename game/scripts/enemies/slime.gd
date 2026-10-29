class_name Slime
extends CharacterBody2D
## Slime: persegue o jogador mais próximo e machuca no contato.
## Golpe físico tira 1 de vida e empurra; fogo tira 2.

const TEXTURA := preload("res://assets/placeholder/ninja/actors/slime.png")

@export var velocidade := 28.0
@export var raio_visao := 90.0
@export var dano_contato := 12.0
@export var recarga_contato := 1.0

var _recarga := 0.0
var _empurrao := Vector2.ZERO

@onready var visual: AnimatedSprite2D = $Visual
@onready var vida: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox


func _ready() -> void:
	add_to_group(&"inimigos")
	var f := SpriteFrames.new()
	f.remove_animation(&"default")
	SpriteSheets.adicionar_por_direcao(f, TEXTURA, "pulo", Vector2i(16, 16), 0, 4, 6.0)
	visual.sprite_frames = f
	visual.play(&"pulo_baixo")
	hurtbox.atingido.connect(_on_atingido)
	vida.morreu.connect(_on_morreu)


func _physics_process(delta: float) -> void:
	_recarga = maxf(0.0, _recarga - delta)
	var alvo := _jogador_mais_proximo()
	var dir := Vector2.ZERO
	if alvo:
		var para_alvo := alvo.global_position - global_position
		if para_alvo.length() < raio_visao:
			dir = para_alvo.normalized()
			visual.play(StringName("pulo_%s" % SpriteSheets.direcao_de(dir)))
		if para_alvo.length() < 12.0 and _recarga <= 0.0:
			_recarga = recarga_contato
			alvo.vida.tomar_dano(dano_contato, &"fisico")
			Events.aviso.emit("O slime te acertou! Clique para golpear.")
	velocity = dir * velocidade + _empurrao
	_empurrao = _empurrao.move_toward(Vector2.ZERO, 400.0 * delta)
	move_and_slide()


func _jogador_mais_proximo() -> Player:
	var melhor: Player = null
	var menor := INF
	for j in get_tree().get_nodes_in_group(&"jogadores"):
		var d := global_position.distance_to(j.global_position)
		if d < menor:
			menor = d
			melhor = j
	return melhor


func _on_atingido(quantidade: float, tipo: StringName, origem: Node) -> void:
	var dano := quantidade * (2.0 if tipo == &"fogo" else 1.0)
	if not vida.tomar_dano(dano, tipo):
		return
	Sfx.tocar(&"acerto", -10.0)
	if origem is Node2D:
		_empurrao = (global_position - origem.global_position).normalized() * 160.0
	var t := create_tween()
	t.tween_property(visual, "modulate", Color(1.0, 0.5, 0.5), 0.05)
	t.tween_property(visual, "modulate", Color.WHITE, 0.2)


func _on_morreu() -> void:
	Events.aviso.emit("Slime derrotado!")
	queue_free()
