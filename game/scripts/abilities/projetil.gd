class_name Projetil
extends Area2D
## Projétil genérico (bola de fogo, lança de gelo, flecha): voa em linha reta e acerta a
## primeira coisa atingível no caminho. Quem é atingido decide o efeito pelo elemento.
## Rede: só o anfitrião move e confere acertos; os outros recebem a posição.

@export var velocidade := 170.0
@export var duracao := 1.2
@export var dano := 1.0
@export var elemento: StringName = &"fogo"
## Sincronizada ao nascer, para todos desenharem o projétil na direção certa.
@export var direcao := Vector2.RIGHT
## Sobre a água, congela o caminho (lança de gelo).
@export var congela_agua := false

@export_group("Arte")
@export var textura: Texture2D
@export var quadro := Vector2i(16, 16)
@export var quadros := 1
@export var fps := 12.0
## Para onde a arte aponta (radianos). A bola de fogo do placeholder aponta para cima-direita.
@export var angulo_da_arte := 0.0
@export var textura_impacto: Texture2D
@export var quadro_impacto := Vector2i(16, 16)
@export var quadros_impacto := 0
## Escala da arte (o Tiny Swords é feito para tile de 64 px: 0,25 no nosso mundo).
@export var escala_arte := 1.0
@export var escala_impacto := 1.0

var lancador: Node = null
var _vida := 0.0
var _acertou := false

@onready var visual: AnimatedSprite2D = $Visual


func _ready() -> void:
	add_to_group(&"projeteis")
	collision_layer = 0
	collision_mask = 1 << 4  # "atingivel"
	monitoring = multiplayer.is_server()
	area_entered.connect(_on_area_entered)
	var f := SpriteFrames.new()
	f.remove_animation(&"default")
	SpriteSheets.adicionar_tira(f, textura, &"voando", quadro, quadros, fps)
	if textura_impacto and quadros_impacto > 0:
		# Impacto de um quadro só (cristais de gelo) fica um terço de segundo na tela.
		SpriteSheets.adicionar_tira(f, textura_impacto, &"impacto", quadro_impacto, quadros_impacto, 20.0 if quadros_impacto > 1 else 3.0, false)
	visual.sprite_frames = f
	visual.scale = Vector2(escala_arte, escala_arte)
	visual.play(&"voando")
	visual.rotation = direcao.angle() - angulo_da_arte


func _physics_process(delta: float) -> void:
	if _acertou or not multiplayer.is_server():
		return
	position += direcao * velocidade * delta
	if congela_agua:
		World.congelar_agua_em(self, global_position + Vector2(0, 10))
	_vida += delta
	if _vida >= duracao:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _acertou or not area is Hurtbox:
		return
	if area.get_parent() == lancador or area.get_parent() is Player:
		return  # sem fogo amigo
	_acertou = true
	(area as Hurtbox).receber(dano, elemento, lancador)
	set_deferred(&"monitoring", false)
	_impacto.rpc()
	if visual.sprite_frames.has_animation(&"impacto"):
		visual.animation_finished.connect(queue_free)
	else:
		queue_free()


@rpc("authority", "call_local", "reliable")
func _impacto() -> void:
	if visual.sprite_frames.has_animation(&"impacto"):
		visual.rotation = 0.0
		visual.scale = Vector2(escala_impacto, escala_impacto)
		visual.play(&"impacto")
	else:
		visual.visible = false
