class_name Criatura
extends CharacterBody2D
## Base dos inimigos novos da etapa 2 (L39): bandidos, cogumelo andante, morcego, esqueleto de
## musgo e golenzinho. Cada um é uma subclasse que diz os números (_configurar), monta a
## animação e decide o que fazer a cada quadro (_pensar). O que é igual para todos fica aqui:
##   - rede: só o anfitrião pensa, anda e bate; os outros recebem posição, animação e lado;
##   - estados (EfeitosEstado): Congelado/Atordoado/Derrubado não anda nem ataca, Preso não
##     anda, Medo foge e não ataca, Provocado persegue quem provocou, Cego erra, Lentidão;
##   - elementos, como no slime: gelo congela, físico num congelado estilhaça (dobro), fogo
##     num congelado derrete (e deixa Molhado), a luz queima as criaturas da noite;
##   - noturno: mais forte, foge da luz e vai embora ao amanhecer;
##   - longe do centro tem mais vida e nível (World.mult_dificuldade e World.nivel_extra);
##   - derrotado: experiência para quem estava perto e o saque no chão.

const TEMPO_CONGELADO := 2.5

## Qual criatura (variações da mesma cena, ex.: guerreiro ou lanceiro). Sincronizado no nascer.
@export var especie: StringName = &""
@export var animacao: StringName = &"parado"
@export var olhando_esquerda := false
## Sem poder andar (congelado, preso, atordoado...), sincronizado.
@export var parado := false
@export var noturno := false
@export var envenenado := false

# --- Números (cada subclasse muda em _configurar) -------------------------------------
var nome := "Inimigo"
var vida_base := 8.0
var velocidade := 28.0
var raio_visao := 110.0
var dano := 10.0
var nivel := 2
var xp := 12
## [[item, mín, máx], ...] ou [[item, mín, máx, chance], ...]
var saque: Array = []
## Multiplicador do dano por tipo (fogo 2,0 = toma o dobro; físico 0,5 = metade).
var resistencias: Dictionary = {}
## Não é empurrado ao apanhar (o golenzinho).
var pesado := false
## Voa: passa por cima da água e das paredes baixas.
var voa := false

var _alvo: Node2D
var _casa := Vector2.INF
var _destino := Vector2.INF
var _tempo_passeio := 0.0
var _empurrao := Vector2.ZERO
var _dano_visivel := 0.0
var _ultimo_tipo: StringName = &""

# --- Ataque corpo a corpo (máquina simples que as subclasses usam) ---------------------
enum Golpe { LIVRE, PREPARANDO, BATENDO, RECUPERANDO }
var _golpe := Golpe.LIVRE
var _tempo_golpe := 0.0
var _recarga := 0.0

@onready var visual: AnimatedSprite2D = $Visual
@onready var vida: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var barra: BarraCabeca = $BarraCabeca
@onready var efeitos: EfeitosEstado = $EfeitosEstado


func _ready() -> void:
	add_to_group(&"inimigos")
	add_to_group(&"criaturas")
	_configurar()
	if voa:
		collision_mask = 0
	var f := SpriteFrames.new()
	f.remove_animation(&"default")
	_montar_animacoes(f)
	visual.sprite_frames = f
	visual.play(animacao)
	vida.maximo = vida_base
	if noturno:
		vida.maximo *= 1.5
		dano *= 1.4
		raio_visao *= 1.2
	vida.atual = vida.maximo
	barra.definir_nivel(nivel + (2 if noturno else 0) + World.nivel_extra(self))
	barra.ajustar_ao_sprite(visual)
	if multiplayer.is_server():
		vida.maximo *= World.mult_dificuldade(self, &"vida_inimigo")
		vida.atual = vida.maximo
		hurtbox.atingido.connect(_on_atingido)
		vida.morreu.connect(_on_morreu)
		_recarga = randf_range(0.3, 1.0)


## Subclasse: os números (vida_base, velocidade, dano, saque...).
func _configurar() -> void:
	pass


## Subclasse: as animações parado, andar, preparo, ataque e dano (as que tiver).
func _montar_animacoes(_f: SpriteFrames) -> void:
	pass


## Subclasse: para onde andar agora (tamanho 0 a 1; a velocidade multiplica). Só no anfitrião.
func _pensar(_delta: float) -> Vector2:
	return Vector2.ZERO


## Animação com os quadros `indices` de uma tira de quadros `tamanho`.
static func anim(f: SpriteFrames, nome_anim: StringName, tex: Texture2D, tamanho: Vector2i, indices: Array, fps: float, loop := true) -> void:
	f.add_animation(nome_anim)
	f.set_animation_speed(nome_anim, fps)
	f.set_animation_loop(nome_anim, loop)
	for i in indices:
		var a := AtlasTexture.new()
		a.atlas = tex
		a.region = Rect2(int(i) * tamanho.x, 0, tamanho.x, tamanho.y)
		f.add_frame(nome_anim, a)


func congelado() -> bool:
	return efeitos.tem(EfeitosEstado.CONGELADO)


func preso() -> bool:
	return efeitos.tem(EfeitosEstado.PRESO)


func prender(segundos: float) -> void:
	efeitos.aplicar(EfeitosEstado.PRESO, segundos)


func envenenar(segundos: float, quanto: float, origem: Node = null) -> void:
	efeitos.aplicar(EfeitosEstado.VENENO, segundos, quanto, origem)
	envenenado = true


## Está atrás deste jogador? (Golpe furtivo: quem não persegue leva o dobro.)
func persegue(jogador: Node) -> bool:
	return _alvo == jogador


func _physics_process(delta: float) -> void:
	visual.modulate = efeitos.cor()
	visual.flip_h = olhando_esquerda
	_dano_visivel = maxf(0.0, _dano_visivel - delta)
	var quer := animacao
	if _dano_visivel > 0.0 and visual.sprite_frames.has_animation(&"dano") and _golpe == Golpe.LIVRE:
		quer = &"dano"
	if parado:
		visual.pause()
	else:
		if visual.animation != quer:
			visual.play(quer)
		elif not visual.is_playing() and visual.sprite_frames.get_animation_loop(quer):
			visual.play()
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
	if not efeitos.pode_atacar() and _golpe in [Golpe.PREPARANDO, Golpe.BATENDO]:
		_mudar_golpe(Golpe.RECUPERANDO)  # congelado ou com medo no meio do ataque: perde o golpe
	_alvo = _escolher_alvo()
	var dir := Vector2.ZERO
	var medo := efeitos.fugir_de()
	var luz := World.luz_que_protege(self, global_position) if noturno else Vector2.INF
	if medo != Vector2.INF:
		dir = _andar((global_position - medo).normalized())
	elif luz != Vector2.INF:
		dir = _andar((global_position - luz).normalized())
	else:
		dir = _pensar(delta)
	var mult := efeitos.mult_velocidade()
	if mult <= 0.0 and animacao == &"andar":
		animacao = &"parado"
	if efeitos.impulso() != Vector2.ZERO:
		_empurrao = Vector2.ZERO
	velocity = dir * velocidade * mult + _empurrao + efeitos.impulso()
	_empurrao = _empurrao.move_toward(Vector2.ZERO, 400.0 * delta)
	move_and_slide()


## Anda nesta direção (vira o desenho e põe a animação de andar).
func _andar(dir: Vector2) -> Vector2:
	if dir.x != 0.0:
		olhando_esquerda = dir.x < 0.0
	animacao = &"andar"
	return dir


func _olhar_para(p: Vector2) -> void:
	if absf(p.x - global_position.x) > 1.0:
		olhando_esquerda = p.x < global_position.x


## Provocado: quem provocou. Senão, o jogador visível mais perto dentro da visão.
func _escolher_alvo() -> Node2D:
	var provocador := efeitos.alvo_provocado()
	if provocador and not (provocador is Player and (provocador as Player).caido):
		return provocador
	var melhor: Node2D = null
	var menor := INF
	for j in get_tree().get_nodes_in_group(&"jogadores"):
		var p := j as Player
		if p == null or p.escondido() or p.criando or p.caido or not p.vida.esta_vivo():
			continue
		if noturno and World.luz_que_protege(self, p.global_position) != Vector2.INF:
			continue  # a luz protege da noite
		var d := global_position.distance_to(p.global_position)
		var visao := raio_visao * p.fator_visao()
		if _alvo == p:
			visao *= 1.5  # quem já viu não perde de vista tão fácil
		if d < visao and d < menor:
			menor = d
			melhor = p
	return melhor


## Sem ninguém por perto: anda devagar em volta de onde nasceu.
func _passear(delta: float, raio := 40.0) -> Vector2:
	if _casa == Vector2.INF:
		_casa = global_position
	_tempo_passeio += delta
	if _destino == Vector2.INF or global_position.distance_to(_destino) < 4.0:
		animacao = &"parado"
		if _tempo_passeio < 2.0:
			return Vector2.ZERO
		_tempo_passeio = 0.0
		_destino = _casa + Vector2(randf_range(-raio, raio), randf_range(-raio, raio))
	if _tempo_passeio > 4.0:
		_destino = Vector2.INF
		_tempo_passeio = 0.0
		return Vector2.ZERO
	return _andar((_destino - global_position).normalized()) * 0.5


# --- Corpo a corpo -------------------------------------------------------------------

## Persegue o alvo e, perto, faz o golpe em 3 tempos: prepara (o aviso para esquivar), bate
## (acerta quem estiver a `alcance` na hora) e recupera. Devolve a direção.
func _corpo_a_corpo(delta: float, alcance: float, preparo: float, recarga: float, batendo := 0.25) -> Vector2:
	_tempo_golpe += delta
	match _golpe:
		Golpe.PREPARANDO:
			animacao = &"preparo"
			if _alvo:
				_olhar_para(_alvo.global_position)
			if _tempo_golpe >= preparo:
				_mudar_golpe(Golpe.BATENDO)
				_tocar_ataque.rpc()
				_ao_bater()
			return Vector2.ZERO
		Golpe.BATENDO:
			animacao = &"ataque"
			if _tempo_golpe >= batendo:
				_mudar_golpe(Golpe.RECUPERANDO)
				_recarga = recarga
			return Vector2.ZERO
		Golpe.RECUPERANDO:
			animacao = &"parado"
			if _tempo_golpe >= 0.3:
				_mudar_golpe(Golpe.LIVRE)
			return Vector2.ZERO
	if _alvo == null:
		return _passear(delta)
	var para := _alvo.global_position - global_position
	if para.length() < alcance:
		_olhar_para(_alvo.global_position)
		if _recarga <= 0.0 and efeitos.pode_atacar():
			_mudar_golpe(Golpe.PREPARANDO)
		animacao = &"parado"
		return Vector2.ZERO
	return _andar(para.normalized())


## Subclasse: o que acontece na hora de bater (padrão: acerta o alvo se estiver perto).
func _ao_bater() -> void:
	if _alvo and _alvo.global_position.distance_to(global_position) < _alcance_golpe():
		golpear(_alvo, dano)


func _alcance_golpe() -> float:
	return 22.0


func _mudar_golpe(novo: Golpe) -> void:
	_golpe = novo
	_tempo_golpe = 0.0


@rpc("authority", "call_local", "reliable")
func _tocar_ataque() -> void:
	if visual.sprite_frames.has_animation(&"ataque"):
		visual.play(&"ataque")
		visual.frame = 0


## Dá `quanto` de dano em `alvo` (jogador ou invocação). Cego pode errar. Devolve se machucou.
func golpear(alvo: Node2D, quanto: float, tipo: StringName = &"fisico") -> bool:
	if efeitos.erra_ataque():
		World.efeito_todos(self, &"poeira", alvo.global_position)
		return false
	var v := alvo.get_node_or_null("HealthComponent") as HealthComponent
	if v == null or not v.tomar_dano(Passivas.ataque_inimigo(self, alvo, quanto), tipo):
		return false
	if alvo is Player:
		(alvo as Player).reagir_ao_golpe(global_position)
	return true


## Todos os jogadores num círculo (o soco no chão do golenzinho, os esporos).
func jogadores_em_volta(centro: Vector2, raio: float) -> Array[Player]:
	var lista: Array[Player] = []
	for j in get_tree().get_nodes_in_group(&"jogadores"):
		var p := j as Player
		if p and not p.caido and p.vida.esta_vivo() and p.global_position.distance_to(centro) <= raio:
			lista.append(p)
	return lista


# --- Apanhar e morrer ----------------------------------------------------------------

func _on_atingido(quantidade: float, tipo: StringName, origem: Node) -> void:
	var q := quantidade
	match tipo:
		&"gelo":
			efeitos.aplicar(EfeitosEstado.CONGELADO, TEMPO_CONGELADO, 0.0, origem)
			World.efeito_todos(self, &"congelar", global_position + Vector2(0, -6))
		&"fogo":
			if congelado():
				efeitos.remover(EfeitosEstado.CONGELADO)
				efeitos.aplicar(EfeitosEstado.MOLHADO, EfeitosEstado.MOLHADO_SEGUNDOS)
		&"luz":
			if noturno:
				q *= 3.0
		&"fisico":
			if congelado():
				q *= 2.0
				efeitos.remover(EfeitosEstado.CONGELADO)
	q *= float(resistencias.get(tipo, 1.0))
	q = _ajustar_dano(q, tipo, origem)
	parado = not efeitos.pode_mover()
	_ultimo_tipo = tipo
	if q <= 0.0 or not vida.tomar_dano(q, tipo):
		return
	if origem is Node2D and not parado and not pesado:
		_empurrao = (global_position - (origem as Node2D).global_position).normalized() * 120.0
	_piscar.rpc(vida.atual, vida.maximo)


## Subclasse: muda o dano recebido (a defesa do bandido, a picareta no golem...).
func _ajustar_dano(q: float, _tipo: StringName, _origem: Node) -> float:
	return q


@rpc("authority", "call_local", "reliable")
func _piscar(atual: float, maximo: float) -> void:
	if not multiplayer.is_server():
		vida.maximo = maximo
		vida.atual = atual
	barra.mostrar_dano()
	Sfx.tocar(&"acerto", -10.0)
	_dano_visivel = 0.25
	var t := create_tween()
	t.tween_property(visual, "self_modulate", Color(1.0, 0.5, 0.5), 0.05)
	t.tween_property(visual, "self_modulate", Color.WHITE, 0.2)


func _on_morreu() -> void:
	_morrer()


## Derrotado de vez: experiência, aviso, saque no chão.
func _morrer() -> void:
	var total := xp * (2 if noturno else 1)
	World.dar_xp_em_volta(self, global_position, total)
	World.avisar_todos(self, "%s derrotado! +%d de experiência para quem estava perto." % [nome, total])
	World.soltar_itens(self, global_position, sortear_saque())
	World.efeito_todos(self, &"poeira", global_position)
	queue_free()


## O saque sorteado ([[id, qtd], ...]).
func sortear_saque() -> Array:
	var itens := []
	for s in saque:
		if s.size() > 3 and randf() >= float(s[3]):
			continue
		var n := randi_range(int(s[1]), int(s[2]))
		if n > 0:
			itens.append([s[0], n])
	return itens


## O sol manda embora a criatura da noite (só o anfitrião chama).
func derreter() -> void:
	World.efeito_todos(self, &"poeira", global_position)
	queue_free()


func _e_noite() -> bool:
	var w := get_tree().get_first_node_in_group(&"mundo") as World
	return w == null or w.noite
