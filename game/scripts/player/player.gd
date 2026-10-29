class_name Player
extends CharacterBody2D
## Jogador: anda com WASD, mira com o mouse, segura E para coletar,
## clique para golpear e 1 para a bola de fogo.
##
## Rede: o nome do nó é o id do jogador na rede. Cada jogador controla o próprio
## movimento (sincronizado pelo MultiplayerSynchronizer). Tudo que muda o mundo
## (coletar, golpear, lançar) é um PEDIDO ao anfitrião, que confere e executa.
## Vida e inventário são do anfitrião, que manda os valores ao dono.

const TEXTURA := preload("res://assets/sprites/personagens/aventureiro.png")
const BOLA_DE_FOGO := preload("res://scenes/abilities/fireball.tscn")

@export var velocidade := 80.0
@export var dano_golpe := 1.0
@export var alcance_golpe := 22.0
@export var recarga_golpe := 0.35
@export var recarga_fogo := 0.6

## Animação atual (sincronizada para os outros jogadores verem).
@export var animacao: StringName = &"parado_baixo"

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
@onready var camera: Camera2D = $Camera2D
@onready var luz: PointLight2D = $Luz


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _ready() -> void:
	add_to_group(&"jogadores")
	ponto_de_retorno = position
	visual.sprite_frames = _montar_frames()
	visual.play(animacao)
	camera.enabled = eh_local()
	if multiplayer.is_server():
		vida.mudou.connect(func(atual: float, _m: float) -> void: _vida_sync.rpc(atual))
		vida.morreu.connect(_on_morreu)
		hurtbox.atingido.connect(func(qtd: float, tipo: StringName, _o: Node) -> void: vida.tomar_dano(qtd, tipo))
	if eh_local():
		get_tree().call_group(&"mundo", &"registrar_jogador_local", self)


## Este jogador é o controlado nesta máquina?
func eh_local() -> bool:
	return is_multiplayer_authority()


func id_rede() -> int:
	return get_multiplayer_authority()


func _physics_process(delta: float) -> void:
	if not eh_local():
		if visual.animation != animacao:
			visual.play(animacao)
		return
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
	if not eh_local():
		return
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
	return alvo != null and is_instance_valid(alvo) and alvo.perto_de(global_position)


func recarga_fogo_restante() -> float:
	return _recarga_fogo / recarga_fogo


## Mostra um aviso na tela deste jogador (de onde quer que seja chamado).
func avisar(texto: String, som: StringName = &"") -> void:
	if eh_local():
		_receber_aviso(texto, som)
	else:
		_receber_aviso.rpc_id(id_rede(), texto, som)


# --- Ações (pedidos ao anfitrião) ---------------------------------------------

func golpear() -> void:
	if _recarga_golpe > 0.0:
		return
	_recarga_golpe = recarga_golpe
	_atacando = 0.25
	var dir := direcao_mira()
	_direcao = SpriteSheets.direcao_de(dir)
	Sfx.tocar(&"ataque", -12.0)
	_pedir_golpe.rpc_id(1, dir)


func lancar_bola_de_fogo() -> void:
	if _recarga_fogo > 0.0:
		return
	_recarga_fogo = recarga_fogo
	_atacando = 0.2
	var dir := direcao_mira()
	_direcao = SpriteSheets.direcao_de(dir)
	Sfx.tocar(&"bola_de_fogo", -10.0)
	_pedir_bola_de_fogo.rpc_id(1, dir)


@rpc("any_peer", "call_local", "reliable")
func _pedir_golpe(dir: Vector2) -> void:
	if not multiplayer.is_server() or not _pedido_do_dono():
		return
	dir = dir.normalized()
	var forma := CircleShape2D.new()
	forma.radius = alcance_golpe * 0.6
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.transform = Transform2D(0.0, global_position + Vector2(0, -10) + dir * alcance_golpe * 0.6)
	consulta.collide_with_areas = true
	consulta.collide_with_bodies = false
	consulta.collision_mask = 1 << 4
	for r in get_world_2d().direct_space_state.intersect_shape(consulta, 16):
		var area := r.collider as Hurtbox
		if area and area != hurtbox:
			area.receber(dano_golpe, &"fisico", self)


@rpc("any_peer", "call_local", "reliable")
func _pedir_bola_de_fogo(dir: Vector2) -> void:
	if not multiplayer.is_server() or not _pedido_do_dono():
		return
	var bola: Fireball = BOLA_DE_FOGO.instantiate()
	bola.lancador = self
	bola.direcao = dir.normalized()
	bola.position = global_position + Vector2(0, -10) + bola.direcao * 8.0
	get_parent().add_child(bola, true)


@rpc("any_peer", "call_local", "reliable")
func _pedir_interacao(caminho_alvo: NodePath) -> void:
	if not multiplayer.is_server() or not _pedido_do_dono():
		return
	var no := get_node_or_null(caminho_alvo)
	if no == null or not no.has_method("interagir"):
		return
	var area: Interactable = no.get_node_or_null("Interactable")
	# Folga de 8 px: a posição que o anfitrião vê chega com um pouco de atraso.
	if area and area.global_position.distance_to(global_position) <= area.alcance + 8.0:
		no.interagir(self)


func _pedido_do_dono() -> bool:
	var s := multiplayer.get_remote_sender_id()
	return s == id_rede() or (s == 0 and eh_local())


# --- Recebidos do anfitrião --------------------------------------------------

@rpc("any_peer", "call_local", "reliable")
func _vida_sync(atual: float) -> void:
	if not Net.veio_do_anfitriao():
		return
	var antes := vida.atual
	if not multiplayer.is_server():
		vida.atual = atual
		vida.mudou.emit(atual, vida.maximo)
	if atual < antes:
		Sfx.tocar(&"acerto", -6.0)
		var t := create_tween()
		t.tween_property(visual, "modulate", Color(1.0, 0.45, 0.45), 0.05)
		t.tween_property(visual, "modulate", Color.WHITE, 0.25)


@rpc("any_peer", "reliable")
func _receber_aviso(texto: String, som: StringName) -> void:
	if not Net.veio_do_anfitriao():
		return
	if som != &"":
		Sfx.tocar(som)
	Events.aviso.emit(texto)


@rpc("any_peer", "call_local", "reliable")
func _renascer() -> void:
	if not Net.veio_do_anfitriao():
		return
	global_position = ponto_de_retorno
	camera.reset_smoothing()
	Events.aviso.emit("Você desmaiou e acordou no acampamento.")


func _on_morreu() -> void:
	vida.curar_tudo()
	if eh_local():
		_renascer()
	else:
		_renascer.rpc_id(id_rede())


# --- Local: alvo, coleta e animação -------------------------------------------

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
		_pedir_interacao.rpc_id(1, alvo.dono().get_path())


func _animar(entrada: Vector2) -> void:
	if _atacando > 0.0:
		animacao = StringName("golpe_%s" % _direcao)
	elif entrada != Vector2.ZERO:
		_direcao = SpriteSheets.direcao_de(entrada)
		animacao = StringName("andar_%s" % _direcao)
	else:
		animacao = StringName("parado_%s" % _direcao)
	visual.play(animacao)


## Folha do aventureiro (L01): 0 frente, 1 costas, 2 direita, 3 andando de frente,
## 4 andando para a direita. A esquerda é o espelho da direita. Enquanto não chegam
## mais quadros, o passo alterna parado/andando e o golpe usa a pose de passo.
func _montar_frames() -> SpriteFrames:
	var t := Vector2i(32, 32)
	var frente: Texture2D = SpriteSheets.quadro(TEXTURA, 0, t)
	var costas: Texture2D = SpriteSheets.quadro(TEXTURA, 1, t)
	var direita: Texture2D = SpriteSheets.quadro(TEXTURA, 2, t)
	var esquerda: Texture2D = SpriteSheets.quadro(TEXTURA, 2, t, true)
	var passo_frente: Texture2D = SpriteSheets.quadro(TEXTURA, 3, t)
	var passo_frente_b: Texture2D = SpriteSheets.quadro(TEXTURA, 3, t, true)
	var passo_costas: Texture2D = SpriteSheets.quadro(TEXTURA, 1, t, false, 1)
	var passo_direita: Texture2D = SpriteSheets.quadro(TEXTURA, 4, t)
	var passo_esquerda: Texture2D = SpriteSheets.quadro(TEXTURA, 4, t, true)
	var f := SpriteFrames.new()
	f.remove_animation(&"default")
	SpriteSheets.adicionar_quadros(f, &"parado_baixo", [frente], 1.0)
	SpriteSheets.adicionar_quadros(f, &"parado_cima", [costas], 1.0)
	SpriteSheets.adicionar_quadros(f, &"parado_direita", [direita], 1.0)
	SpriteSheets.adicionar_quadros(f, &"parado_esquerda", [esquerda], 1.0)
	SpriteSheets.adicionar_quadros(f, &"andar_baixo", [passo_frente, frente, passo_frente_b, frente], 7.0)
	SpriteSheets.adicionar_quadros(f, &"andar_cima", [passo_costas, costas], 5.0)
	SpriteSheets.adicionar_quadros(f, &"andar_direita", [passo_direita, direita], 6.0)
	SpriteSheets.adicionar_quadros(f, &"andar_esquerda", [passo_esquerda, esquerda], 6.0)
	SpriteSheets.adicionar_quadros(f, &"golpe_baixo", [passo_frente], 1.0)
	SpriteSheets.adicionar_quadros(f, &"golpe_cima", [passo_costas], 1.0)
	SpriteSheets.adicionar_quadros(f, &"golpe_direita", [passo_direita], 1.0)
	SpriteSheets.adicionar_quadros(f, &"golpe_esquerda", [passo_esquerda], 1.0)
	return f
