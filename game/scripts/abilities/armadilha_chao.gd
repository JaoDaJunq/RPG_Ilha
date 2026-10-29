class_name ArmadilhaChao
extends Area2D
## Armadilha de espinhos do Arqueiro: fica armada no chão e, quando um inimigo pisa,
## prende e machuca. Só o anfitrião confere quem pisou.

const ICONE := preload("res://assets/placeholder/ninja/ui/icone_armadilha.png")
const ESPINHOS := preload("res://assets/placeholder/ninja/fx/espinhos.png")
const TEMPO_PRESO := 3.0

@export var dono_id := 1
var dano := 1.0
var _disparou := false

@onready var visual: AnimatedSprite2D = $Visual


func _ready() -> void:
	add_to_group(&"armadilhas")
	collision_layer = 0
	collision_mask = 1 << 2  # "inimigos"
	monitoring = multiplayer.is_server()
	body_entered.connect(_on_body_entered)
	var f := SpriteFrames.new()
	f.remove_animation(&"default")
	SpriteSheets.adicionar_quadros(f, &"armada", [ICONE], 1.0)
	SpriteSheets.adicionar_tira(f, ESPINHOS, &"disparando", Vector2i(45, 48), 12, 18.0, false)
	visual.sprite_frames = f
	visual.play(&"armada")


func disparou() -> bool:
	return _disparou


func _on_body_entered(corpo: Node2D) -> void:
	if _disparou or not corpo is Slime:
		return
	_disparou = true
	var slime := corpo as Slime
	slime.prender(TEMPO_PRESO)
	slime.hurtbox.receber(dano, &"fisico", null)
	_disparar.rpc()
	visual.animation_finished.connect(queue_free)


@rpc("authority", "call_local", "reliable")
func _disparar() -> void:
	_disparou = true
	visual.modulate.a = 1.0
	visual.scale = Vector2.ONE
	visual.position = Vector2(0, -20)
	visual.play(&"disparando")
	Sfx.tocar(&"golpe_coleta", -6.0)
