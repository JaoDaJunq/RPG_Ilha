class_name ArmadilhaChao
extends Area2D
## Armadilha de ferro do Arqueiro (arte L04): fica armada no chão e, quando um inimigo
## pisa, fecha, prende e machuca. Fica fechada enquanto prende; depois aparece gasta e some.
## Só o anfitrião confere quem pisou.

## Folha (L04): 0 armada, 1 fechando, 2 fechada, 3 fechada e gasta. Quadros de 40x40.
const FOLHA := preload("res://assets/sprites/habilidades/armadilha.png")
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
	var t := Vector2i(40, 40)
	var f := SpriteFrames.new()
	f.remove_animation(&"default")
	SpriteSheets.adicionar_quadros(f, &"armada", [SpriteSheets.quadro(FOLHA, 0, t)], 1.0)
	SpriteSheets.adicionar_quadros(f, &"fechando", [SpriteSheets.quadro(FOLHA, 1, t), SpriteSheets.quadro(FOLHA, 2, t)], 14.0, false)
	SpriteSheets.adicionar_quadros(f, &"gasta", [SpriteSheets.quadro(FOLHA, 3, t)], 1.0)
	visual.sprite_frames = f
	visual.play(&"armada")


func disparou() -> bool:
	return _disparou


func _on_body_entered(corpo: Node2D) -> void:
	if _disparou or not corpo is Slime:
		return
	_disparou = true
	var slime := corpo as Slime
	slime.global_position = global_position + Vector2(0, 3)  # puxado para dentro da armadilha
	slime.prender(TEMPO_PRESO)
	slime.hurtbox.receber(dano, &"fisico", null)
	_disparar.rpc()
	get_tree().create_timer(TEMPO_PRESO + 0.8, false, true).timeout.connect(queue_free)


@rpc("authority", "call_local", "reliable")
func _disparar() -> void:
	_disparou = true
	visual.play(&"fechando")
	Sfx.tocar(&"golpe_coleta", -4.0)
	var t := create_tween()
	t.tween_interval(TEMPO_PRESO)
	t.tween_callback(func() -> void: visual.play(&"gasta"))
	t.tween_property(visual, "modulate:a", 0.0, 0.7)
