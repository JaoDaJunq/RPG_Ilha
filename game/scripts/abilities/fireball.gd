class_name Fireball
extends Area2D
## Bola de fogo: voa em linha reta e acerta a primeira coisa atingível no caminho.
## Quem é atingido decide o efeito (slime perde vida, árvore pega fogo).

const TEXTURA := preload("res://assets/placeholder/ninja/fx/bola_de_fogo.png")
const EXPLOSAO := preload("res://assets/placeholder/ninja/fx/explosao_fogo.png")

@export var velocidade := 170.0
@export var duracao := 1.2
@export var dano := 1.0

var direcao := Vector2.RIGHT
var lancador: Node = null
var _vida := 0.0
var _acertou := false

@onready var visual: AnimatedSprite2D = $Visual


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 4  # "atingivel"
	area_entered.connect(_on_area_entered)
	var f := SpriteFrames.new()
	f.remove_animation(&"default")
	SpriteSheets.adicionar_tira(f, TEXTURA, &"voando", Vector2i(16, 16), 4, 12.0)
	SpriteSheets.adicionar_tira(f, EXPLOSAO, &"explodindo", Vector2i(25, 30), 8, 20.0, false)
	visual.sprite_frames = f
	visual.play(&"voando")
	# A arte aponta para cima-direita (-45°).
	visual.rotation = direcao.angle() + PI / 4.0


func _physics_process(delta: float) -> void:
	if _acertou:
		return
	position += direcao * velocidade * delta
	_vida += delta
	if _vida >= duracao:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _acertou or not area is Hurtbox or area.get_parent() == lancador:
		return
	_acertou = true
	(area as Hurtbox).receber(dano, &"fogo", lancador)
	set_deferred(&"monitoring", false)
	visual.rotation = 0.0
	visual.play(&"explodindo")
	visual.animation_finished.connect(queue_free)
