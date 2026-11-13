class_name Atirador
extends CharacterBody2D
## Arqueiro inimigo (o Archer preto do Tiny Swords): fica de longe e atira flechas nos
## jogadores. Mantém distância: se o jogador chega perto, recua; se está longe, chega mais.
## Antes de soltar a flecha ele para e puxa o arco (a animação é o aviso para esquivar).
## A flecha dele é um Projetil com `do_inimigo`: machuca jogadores e invocações, para nas
## paredes e portas, na Barreira do Clérigo e na cúpula do Bastião do Guerreiro.
##
## Rede: só o anfitrião pensa, anda e atira; os outros recebem posição e animação.
##
## Estados (EfeitosEstado): Congelado/Atordoado/Derrubado não anda nem atira; Preso não anda
## mas atira; Medo foge e não atira; Provocado corre atrás de quem provocou (e atira nele);
## Cego erra (a flecha sai torta); Lentidão anda mais devagar. Reage aos elementos como o
## slime: gelo congela, físico num congelado estilhaça (dobro), fogo num congelado derrete
## (e deixa Molhado).

const PARADO := preload("res://assets/tiny_swords/unidades/preto/arqueiro_parado.png")
const CORRENDO := preload("res://assets/tiny_swords/unidades/preto/arqueiro_correndo.png")
const ATIRANDO := preload("res://assets/tiny_swords/unidades/preto/arqueiro_atirando.png")
const FLECHA := "res://scenes/abilities/flecha.tscn"  # load na hora (preload faria ciclo com o projetil)
const QUADRO := Vector2i(192, 192)
const TEMPO_CONGELADO := 2.5
const XP_DERROTA := 15
const NIVEL := 2
const NIVEL_NOTURNO := 4
## Distância que ele tenta manter do alvo (px): recua abaixo de PERTO, chega mais acima de LONGE.
const PERTO := 56.0
const LONGE := 104.0
## Puxar o arco: a flecha sai depois deste tempo (o aviso). A animação tem 8 quadros.
const TEMPO_MIRA := 0.5
const FPS_TIRO := 14.0
## Cego: quanto a flecha sai torta (radianos, para um lado ou para o outro).
const DESVIO_CEGO := 0.6

@export var velocidade := 26.0
@export var raio_visao := 128.0
@export var dano_flecha := 9.0
@export var recarga_tiro := 2.4
## Velocidade da flecha dele (a do jogador é 200: esta dá para esquivar).
@export var velocidade_flecha := 140.0
@export var alcance_flecha := 150.0
@export var animacao: StringName = &"parado"
@export var parado := false
## Arqueiro da noite: nasce no escuro, é mais forte, foge da luz e vai embora ao amanhecer.
@export var noturno := false
@export var envenenado := false
@export var olhando_esquerda := false

var _recarga := 1.0
var _mirando := -1.0  # segundos puxando o arco (-1 = não está mirando)
var _dir_tiro := Vector2.RIGHT
var _empurrao := Vector2.ZERO
var _alvo_atual: Node2D = null
var _casa := Vector2.INF
var _destino := Vector2.INF
var _tempo_passeio := 0.0
## Para os lados enquanto espera a recarga (não fica plantado no lugar).
var _lado := 1.0
var _tempo_lado := 0.0

@onready var visual: AnimatedSprite2D = $Visual
@onready var vida: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var barra: BarraCabeca = $BarraCabeca
@onready var efeitos: EfeitosEstado = $EfeitosEstado


func _ready() -> void:
	add_to_group(&"inimigos")
	add_to_group(&"atiradores")
	var f := SpriteFrames.new()
	f.remove_animation(&"default")
	SpriteSheets.adicionar_tira(f, PARADO, &"parado", QUADRO, 6, 8.0)
	SpriteSheets.adicionar_tira(f, CORRENDO, &"andando", QUADRO, 4, 10.0)
	SpriteSheets.adicionar_tira(f, ATIRANDO, &"atirando", QUADRO, 8, FPS_TIRO, false)
	visual.sprite_frames = f
	visual.play(animacao)
	if noturno:
		vida.maximo *= 1.5
		vida.atual = vida.maximo
		dano_flecha *= 1.4
		raio_visao *= 1.2
	barra.definir_nivel((NIVEL_NOTURNO if noturno else NIVEL) + World.nivel_extra(self))
	barra.ajustar_ao_sprite(visual)
	if multiplayer.is_server():
		vida.maximo *= World.mult_dificuldade(self, &"vida_inimigo")
		vida.atual = vida.maximo
		hurtbox.atingido.connect(_on_atingido)
		vida.morreu.connect(_on_morreu)
		_recarga = randf_range(0.6, 1.4)  # o grupo não atira todo junto


func congelado() -> bool:
	return efeitos.tem(EfeitosEstado.CONGELADO)


func preso() -> bool:
	return efeitos.tem(EfeitosEstado.PRESO)


func prender(segundos: float) -> void:
	efeitos.aplicar(EfeitosEstado.PRESO, segundos)


func envenenar(segundos: float, dano: float, origem: Node = null) -> void:
	efeitos.aplicar(EfeitosEstado.VENENO, segundos, dano, origem)
	envenenado = true


## Está mirando neste jogador? (Golpe furtivo: quem não te via leva o dobro.)
func persegue(jogador: Node) -> bool:
	return _alvo_atual == jogador


func mirando() -> bool:
	return _mirando >= 0.0


func _physics_process(delta: float) -> void:
	visual.modulate = efeitos.cor()
	visual.flip_h = olhando_esquerda
	var congelado_na_pose := parado and animacao != &"atirando"  # o Preso ainda puxa o arco
	if congelado_na_pose:
		visual.pause()
	elif not visual.is_playing() and visual.animation != &"atirando":
		visual.play()
	if visual.animation != animacao and not congelado_na_pose:
		visual.play(animacao)
	if not multiplayer.is_server():
		return
	parado = not efeitos.pode_mover()
	envenenado = efeitos.tem(EfeitosEstado.VENENO)
	if is_queued_for_deletion():
		return
	if noturno and not _e_noite():
		derreter()
		return
	_recarga = maxf(0.0, _recarga - delta)
	var dir := _pensar(delta)
	if efeitos.mult_velocidade() <= 0.0 and animacao == &"andando":
		animacao = &"parado"  # preso, congelado...: o Preso ainda atira
	if efeitos.impulso() != Vector2.ZERO:
		_empurrao = Vector2.ZERO
	velocity = dir * velocidade * efeitos.mult_velocidade() + _empurrao + efeitos.impulso()
	_empurrao = _empurrao.move_toward(Vector2.ZERO, 400.0 * delta)
	move_and_slide()


## Decide para onde andar (e atira). Devolve a direção (tamanho 0 a 1).
func _pensar(delta: float) -> Vector2:
	var alvo := _escolher_alvo()
	_alvo_atual = alvo
	var medo := efeitos.fugir_de()
	# Congelado, atordoado, derrubado ou com Medo: perde o tiro que estava puxando.
	if not efeitos.pode_atacar():
		_cancelar_tiro()
	if medo != Vector2.INF:
		var foge := (global_position - medo).normalized()
		return _andar(foge)
	var luz := World.luz_que_protege(self, global_position) if noturno else Vector2.INF
	if luz != Vector2.INF:
		_cancelar_tiro()
		return _andar((global_position - luz).normalized())
	if mirando():
		return _mirar(alvo, delta)
	if alvo == null:
		return _passear(delta)
	var para := alvo.global_position - global_position
	var d := para.length()
	olhando_esquerda = para.x < 0.0
	var provocado := alvo == efeitos.alvo_provocado()
	# Provocado: corre atrás de quem provocou até ficar bem perto (e atira nele).
	if provocado and d > PERTO * 0.5:
		if _recarga <= 0.0 and d < alcance_flecha * 0.9 and efeitos.pode_atacar():
			_comecar_tiro(alvo)
			return Vector2.ZERO
		return _andar(para / d)
	if _recarga <= 0.0 and d < alcance_flecha * 0.9 and efeitos.pode_atacar():
		_comecar_tiro(alvo)
		return Vector2.ZERO
	if d < PERTO:
		return _andar(-para / d)  # recua
	if d > LONGE:
		return _andar(para / d)  # chega mais
	# Na distância boa: anda de lado devagar esperando a recarga.
	_tempo_lado -= delta
	if _tempo_lado <= 0.0:
		_tempo_lado = randf_range(0.8, 1.6)
		_lado = -_lado
	animacao = &"andando"
	return para.normalized().orthogonal() * _lado * 0.4


func _andar(dir: Vector2) -> Vector2:
	if dir.x != 0.0:
		olhando_esquerda = dir.x < 0.0
	animacao = &"andando"
	return dir


## Puxa o arco: parado, olhando para o alvo; no fim da mira, solta a flecha.
func _mirar(alvo: Node2D, delta: float) -> Vector2:
	animacao = &"atirando"
	if alvo:
		_dir_tiro = (alvo.global_position - global_position).normalized()
		olhando_esquerda = _dir_tiro.x < 0.0
	_mirando += delta
	if _mirando >= TEMPO_MIRA:
		_soltar()
	return Vector2.ZERO


func _comecar_tiro(alvo: Node2D) -> void:
	_mirando = 0.0
	_dir_tiro = (alvo.global_position - global_position).normalized()
	animacao = &"atirando"
	_tocar_tiro.rpc()


func _cancelar_tiro() -> void:
	if mirando():
		_mirando = -1.0
		_recarga = maxf(_recarga, 0.6)


## Solta a flecha (anfitrião). Cego: sai torta e pode errar.
func _soltar() -> void:
	_mirando = -1.0
	_recarga = recarga_tiro
	var dir := _dir_tiro
	if efeitos.erra_ataque():
		dir = dir.rotated(DESVIO_CEGO * (1.0 if randf() < 0.5 else -1.0))
	atirar(dir)


## Cria a flecha inimiga na direção `dir` (anfitrião). Devolve o projétil.
func atirar(dir: Vector2) -> Projetil:
	var p: Projetil = (load(FLECHA) as PackedScene).instantiate()
	p.lancador = self
	p.do_inimigo = true
	p.direcao = dir.normalized()
	p.dano = dano_flecha
	p.velocidade = velocidade_flecha
	p.duracao = alcance_flecha / velocidade_flecha
	p.position = global_position + Vector2(0, -10) + p.direcao * 8.0
	get_parent().add_child(p, true)
	Sfx.tocar(&"flecha", -8.0)
	return p


@rpc("authority", "call_local", "reliable")
func _tocar_tiro() -> void:
	visual.play(&"atirando")
	visual.frame = 0


## Sem ninguém por perto: anda devagar em volta de onde nasceu.
func _passear(delta: float) -> Vector2:
	if _casa == Vector2.INF:
		_casa = global_position
	_tempo_passeio += delta
	if _destino == Vector2.INF or global_position.distance_to(_destino) < 4.0:
		animacao = &"parado"
		if _tempo_passeio < 2.0:
			return Vector2.ZERO
		_tempo_passeio = 0.0
		_destino = _casa + Vector2(randf_range(-36, 36), randf_range(-36, 36))
	if _tempo_passeio > 4.0:
		_destino = Vector2.INF
		_tempo_passeio = 0.0
	return _andar((_destino - global_position).normalized()) * 0.5


## Provocado: quem provocou. Senão, o jogador visível mais perto dentro da visão.
func _escolher_alvo() -> Node2D:
	var provocador := efeitos.alvo_provocado()
	if provocador:
		return provocador
	var melhor: Player = null
	var menor := INF
	for j in get_tree().get_nodes_in_group(&"jogadores"):
		var p := j as Player
		if p == null or p.escondido() or p.criando or not p.vida.esta_vivo():
			continue
		if noturno and World.luz_que_protege(self, p.global_position) != Vector2.INF:
			continue  # a luz protege da noite
		var d := global_position.distance_to(p.global_position)
		if d < raio_visao * p.fator_visao() and d < menor:
			menor = d
			melhor = p
	return melhor


func _e_noite() -> bool:
	var w := get_tree().get_first_node_in_group(&"mundo") as World
	return w == null or w.noite


func _on_atingido(quantidade: float, tipo: StringName, origem: Node) -> void:
	var dano := quantidade
	match tipo:
		&"gelo":
			efeitos.aplicar(EfeitosEstado.CONGELADO, TEMPO_CONGELADO, 0.0, origem)
			World.efeito_todos(self, &"congelar", global_position + Vector2(0, -6))
		&"fogo":
			if congelado():
				efeitos.remover(EfeitosEstado.CONGELADO)
				efeitos.aplicar(EfeitosEstado.MOLHADO, EfeitosEstado.MOLHADO_SEGUNDOS)  # o gelo derreteu
		&"luz":
			if noturno:
				dano *= 3.0
		&"fisico":
			if congelado():
				dano *= 2.0
				efeitos.remover(EfeitosEstado.CONGELADO)
	parado = not efeitos.pode_mover()
	if not vida.tomar_dano(dano, tipo):
		return
	if origem is Node2D and not parado:
		_empurrao = (global_position - origem.global_position).normalized() * 120.0
	_piscar.rpc(vida.atual, vida.maximo)


@rpc("authority", "call_local", "reliable")
func _piscar(atual: float, maximo: float) -> void:
	if not multiplayer.is_server():
		vida.maximo = maximo
		vida.atual = atual
	barra.mostrar_dano()
	Sfx.tocar(&"acerto", -10.0)
	var t := create_tween()
	t.tween_property(visual, "self_modulate", Color(1.0, 0.5, 0.5), 0.05)
	t.tween_property(visual, "self_modulate", Color.WHITE, 0.2)


func _on_morreu() -> void:
	var xp := XP_DERROTA * (2 if noturno else 1)
	World.dar_xp_em_volta(self, global_position, xp)
	World.avisar_todos(self, "Arqueiro inimigo derrotado! +%d de experiência para quem estava perto." % xp)
	World.soltar_itens(self, global_position, [[&"pena", 1 + randi() % 2], [&"carvao", randi() % 2]])
	queue_free()


## O sol manda embora o arqueiro da noite (só o anfitrião chama).
func derreter() -> void:
	World.efeito_todos(self, &"poeira", global_position)
	queue_free()
