class_name Player
extends CharacterBody2D
## Jogador: anda com WASD, mira com o mouse, segura E para coletar,
## clique para golpear e 1 para a bola de fogo.
##
## Preparado para o multiplayer: o input vira "intenções" (mover, mirar, interagir,
## atacar, lançar) e as mudanças no mundo acontecem em funções que, na Etapa 1,
## passam a rodar no anfitrião.

const TEXTURA := preload("res://assets/placeholder/ninja/actors/heroi.png")
const BOLA_DE_FOGO := preload("res://scenes/abilities/fireball.tscn")

@export var velocidade := 80.0
@export var dano_golpe := 1.0
@export var alcance_golpe := 22.0
@export var recarga_golpe := 0.35
@export var recarga_fogo := 0.6

## Posição de mira fixa (usada pelos testes). Se nula, usa o mouse.
var mira_forcada: Variant = null
var alvo: Interactable = null
var ponto_de_retorno := Vector2.ZERO

var _direcao: StringName = &"baixo"
var _progresso := 0.0
var _recarga_golpe := 0.0
var _recarga_fogo := 0.0
var _atacando := 0.0

@onready var visual: AnimatedSprite2D = $Visual
@onready var vida: HealthComponent = $HealthComponent
@onready var inventario: Inventory = $Inventory
@onready var hurtbox: Hurtbox = $Hurtbox


func _ready() -> void:
	add_to_group(&"jogadores")
	ponto_de_retorno = global_position
	visual.sprite_frames = _montar_frames()
	visual.play(&"parado_baixo")
	vida.dano_recebido.connect(_on_dano)
	vida.morreu.connect(_on_morreu)
	hurtbox.atingido.connect(func(qtd: float, tipo: StringName, _o: Node) -> void: vida.tomar_dano(qtd, tipo))


func _physics_process(delta: float) -> void:
	_recarga_golpe = maxf(0.0, _recarga_golpe - delta)
	_recarga_fogo = maxf(0.0, _recarga_fogo - delta)
	_atacando = maxf(0.0, _atacando - delta)

	var entrada := Input.get_vector(&"mover_esquerda", &"mover_direita", &"mover_cima", &"mover_baixo")
	velocity = entrada * velocidade
	move_and_slide()

	_atualizar_alvo()
	_processar_interacao(delta)
	_animar(entrada)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"atacar"):
		golpear()
	elif event.is_action_pressed(&"habilidade_1"):
		lancar_bola_de_fogo()


func posicao_mira() -> Vector2:
	return mira_forcada if mira_forcada != null else get_global_mouse_position()


func direcao_mira() -> Vector2:
	var d := posicao_mira() - global_position
	return d.normalized() if d.length() > 0.5 else Vector2.DOWN


## 0 a 1: quanto falta para o próximo "golpe" de coleta (para a barrinha do HUD).
func progresso_interacao() -> float:
	if alvo == null:
		return 0.0
	return clampf(_progresso / maxf(alvo.tempo_segurar, 0.01), 0.0, 1.0)


func alvo_ao_alcance() -> bool:
	return alvo != null and alvo.perto_de(global_position)


func golpear() -> void:
	if _recarga_golpe > 0.0:
		return
	_recarga_golpe = recarga_golpe
	_atacando = 0.25
	var dir := direcao_mira()
	_direcao = SpriteSheets.direcao_de(dir)
	Sfx.tocar(&"ataque", -12.0)
	var forma := CircleShape2D.new()
	forma.radius = alcance_golpe * 0.6
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.transform = Transform2D(0.0, global_position + Vector2(0, -6) + dir * alcance_golpe * 0.6)
	consulta.collide_with_areas = true
	consulta.collide_with_bodies = false
	consulta.collision_mask = 1 << 4
	for r in get_world_2d().direct_space_state.intersect_shape(consulta, 16):
		var area := r.collider as Hurtbox
		if area and area != hurtbox:
			area.receber(dano_golpe, &"fisico", self)


func lancar_bola_de_fogo() -> void:
	if _recarga_fogo > 0.0:
		return
	_recarga_fogo = recarga_fogo
	_atacando = 0.2
	var dir := direcao_mira()
	_direcao = SpriteSheets.direcao_de(dir)
	var bola: Fireball = BOLA_DE_FOGO.instantiate()
	bola.lancador = self
	bola.direcao = dir
	get_parent().add_child(bola)
	bola.global_position = global_position + Vector2(0, -6) + dir * 8.0
	Sfx.tocar(&"bola_de_fogo", -10.0)


func recarga_fogo_restante() -> float:
	return _recarga_fogo / recarga_fogo


func _atualizar_alvo() -> void:
	var novo: Interactable = null
	var consulta := PhysicsPointQueryParameters2D.new()
	consulta.position = posicao_mira()
	consulta.collide_with_areas = true
	consulta.collide_with_bodies = false
	consulta.collision_mask = 1 << 3
	var melhor := INF
	for r in get_world_2d().direct_space_state.intersect_point(consulta, 8):
		var area := r.collider as Interactable
		if area and area.disponivel():
			var d := area.global_position.distance_to(consulta.position)
			if d < melhor:
				melhor = d
				novo = area
	if novo != alvo:
		if alvo and is_instance_valid(alvo) and alvo.dono().has_method("destacar"):
			alvo.dono().destacar(false)
		alvo = novo
		_progresso = 0.0
		if alvo:
			alvo.dono().destacar(true)


func _processar_interacao(delta: float) -> void:
	if not Input.is_action_pressed(&"interagir") or not alvo_ao_alcance():
		_progresso = 0.0
		return
	_progresso += delta
	if _progresso >= alvo.tempo_segurar:
		_progresso = 0.0
		_direcao = SpriteSheets.direcao_de(alvo.global_position - global_position)
		_atacando = 0.2
		alvo.dono().interagir(self)


func _animar(entrada: Vector2) -> void:
	if _atacando > 0.0:
		visual.play(StringName("golpe_%s" % _direcao))
		return
	if entrada != Vector2.ZERO:
		_direcao = SpriteSheets.direcao_de(entrada)
		visual.play(StringName("andar_%s" % _direcao))
	else:
		visual.play(StringName("parado_%s" % _direcao))


func _on_dano(_qtd: float, _tipo: StringName) -> void:
	Sfx.tocar(&"acerto", -6.0)
	var t := create_tween()
	t.tween_property(visual, "modulate", Color(1.0, 0.45, 0.45), 0.05)
	t.tween_property(visual, "modulate", Color.WHITE, 0.25)


func _on_morreu() -> void:
	global_position = ponto_de_retorno
	vida.curar_tudo()
	Events.aviso.emit("Você desmaiou e acordou no acampamento.")


func _montar_frames() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation(&"default")
	var t := Vector2i(16, 16)
	SpriteSheets.adicionar_por_direcao(f, TEXTURA, "parado", t, 0, 1, 1.0)
	SpriteSheets.adicionar_por_direcao(f, TEXTURA, "andar", t, 0, 4, 8.0)
	SpriteSheets.adicionar_por_direcao(f, TEXTURA, "golpe", t, 4, 1, 1.0)
	return f
