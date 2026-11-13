class_name Slime
extends CharacterBody2D
## Slime: persegue o jogador mais próximo e machuca no contato.
## Rede: só o anfitrião pensa e move o slime; os outros recebem posição e animação.
##
## Reações aos elementos (sempre iguais, para dar para planejar):
##   gelo   → congela (para de andar) por TEMPO_CONGELADO
##   físico num congelado → ESTILHAÇA: dano dobrado e descongela
##   fogo   → dano dobrado; num congelado, só derrete o gelo
##
## Estados (Lentidão, Medo, Provocado, Cego...): ficam no componente EfeitosEstado (filho
## "EfeitosEstado"); o slime respeita todos ao andar, atacar e tomar dano.

## Slime no estilo Tiny Swords (L14): quadros 4 (parado) e 5 (achatado) da folha de pedras.
const TEXTURA := preload("res://assets/sprites/tiny/pedras_slime.png")
## Slimes dos elementos (L39 folha 09): fogo 0-1, gelo 2-3, veneno 4-5 (parado e achatado).
const TEXTURA_ELEMENTOS := preload("res://assets/sprites/tiny/inimigos/slimes_elementos.png")
## Por elemento: quadro, o estado que o contato deixa (segundos, força), imune a, fraco a e o
## saque a mais [item, chance].
const ELEMENTOS := {
	&"fogo": {quadro = 0, estado = EfeitosEstado.QUEIMADURA, segundos = 3.0, forca = 3.0, imune = [&"fogo", &"queimadura"], fraco = &"gelo", saque = [&"carvao", 0.7]},
	&"gelo": {quadro = 2, estado = EfeitosEstado.LENTIDAO, segundos = 2.5, forca = 0.5, imune = [&"gelo"], fraco = &"fogo", saque = [&"cristal", 0.2]},
	&"veneno": {quadro = 4, estado = EfeitosEstado.VENENO, segundos = 4.0, forca = 2.0, imune = [&"veneno"], fraco = &"fogo", saque = [&"erva", 0.6]},
}
const TEMPO_CONGELADO := 2.5
## Experiência para cada jogador perto quando o slime é derrotado.
const XP_DERROTA := 10
## Nível mostrado em cima da cabeça (o slime comum e o da noite).
const NIVEL := 1
const NIVEL_NOTURNO := 3
## Peso no empurrão do golpe (ReacaoGolpe): 1 = o normal.
const PESO := 1.0

@export var velocidade := 28.0
@export var raio_visao := 90.0
@export var dano_contato := 12.0
@export var recarga_contato := 1.0
## Animação atual (sincronizada).
@export var animacao: StringName = &"parado"
## Sem poder andar: congelado, preso, atordoado ou derrubado (sincronizado).
@export var parado := false
## Slime da noite: nasce no escuro, é mais forte e derrete quando amanhece.
@export var noturno := false
## Envenenado (sincronizado para todos verem a cor verde).
@export var envenenado := false
## Slime de elemento (L39): &"fogo", &"gelo" ou &"veneno" (vazio = o verde comum). Ver
## ELEMENTOS: o que o contato faz e a que ele é imune; o elemento contrário dá o triplo.
@export var elemento: StringName = &""

var _recarga := 0.0
var _dano_visivel := 0.0  # mostra o quadro de dano por um instante
## Reação ao apanhar (empurrão, piscar, número, hit stop): ReacaoGolpe, comum a todos.
var reacao: ReacaoGolpe
## Quem ele persegue (só o anfitrião sabe): um jogador ou, provocado, uma invocação.
var _alvo_atual: Node2D = null

@onready var visual: AnimatedSprite2D = $Visual
@onready var vida: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var barra: BarraCabeca = $BarraCabeca
@onready var efeitos: EfeitosEstado = $EfeitosEstado


func _ready() -> void:
	add_to_group(&"inimigos")
	var f := SpriteFrames.new()
	f.remove_animation(&"default")
	var t := Vector2i(128, 128)
	var tex: Texture2D = TEXTURA if elemento == &"" else TEXTURA_ELEMENTOS
	var q0: int = 4 if elemento == &"" else int(ELEMENTOS[elemento].quadro)
	var parado := SpriteSheets.quadro(tex, q0, t)
	var achatado := SpriteSheets.quadro(tex, q0 + 1, t)
	SpriteSheets.adicionar_quadros(f, &"parado", [parado], 1.0)
	SpriteSheets.adicionar_quadros(f, &"pulo", [achatado, parado, parado, achatado], 7.0)
	SpriteSheets.adicionar_quadros(f, &"dano", [achatado], 1.0)
	visual.sprite_frames = f
	visual.play(animacao)
	if noturno:
		vida.maximo *= 1.6
		vida.atual = vida.maximo
		dano_contato *= 1.5
		velocidade *= 1.15
		raio_visao *= 1.4
	if elemento != &"":
		vida.maximo *= 1.3
		vida.atual = vida.maximo
		dano_contato *= 1.15
	barra.definir_nivel((NIVEL_NOTURNO if noturno else NIVEL) + (1 if elemento != &"" else 0) + World.nivel_extra(self))
	barra.ajustar_ao_sprite(visual)
	reacao = ReacaoGolpe.em(self, PESO)
	reacao.reagiu.connect(func(_q: float, _c: bool, _f: float) -> void: _dano_visivel = 0.3)
	if multiplayer.is_server():
		# Dificuldade do mundo: a vida vai para os outros pelos avisos de golpe (ReacaoGolpe).
		vida.maximo *= World.mult_dificuldade(self, &"vida_inimigo")
		vida.atual = vida.maximo
		hurtbox.atingido.connect(_on_atingido)
		vida.morreu.connect(_on_morreu)


func congelado() -> bool:
	return efeitos.tem(EfeitosEstado.CONGELADO)


func preso() -> bool:
	return efeitos.tem(EfeitosEstado.PRESO)


## Só o anfitrião chama (armadilha, Raio).
func prender(segundos: float) -> void:
	efeitos.aplicar(EfeitosEstado.PRESO, segundos)
	parado = not efeitos.pode_mover()


## Só o anfitrião chama (Lâmina envenenada): perde `dano` de vida por segundo durante
## `segundos` (um golpe novo recomeça a contagem). `origem`: quem envenenou.
func envenenar(segundos: float, dano: float, origem: Node = null) -> void:
	efeitos.aplicar(EfeitosEstado.VENENO, segundos, dano, origem)
	envenenado = true


## Está atrás deste jogador? (Golpe furtivo: quem não persegue leva o dobro.) Só no anfitrião.
func persegue(jogador: Node) -> bool:
	return _alvo_atual == jogador and _estado in [Estado.PERSEGUINDO, Estado.PREPARANDO, Estado.PULANDO, Estado.RECUANDO]


func _physics_process(delta: float) -> void:
	visual.modulate = efeitos.cor()
	if parado:
		visual.pause()
	elif not visual.is_playing():
		visual.play()
	_dano_visivel = maxf(0.0, _dano_visivel - delta)
	var quer: StringName = &"dano" if _dano_visivel > 0.0 else animacao
	if visual.animation != quer and not parado:
		visual.play(quer)
	if not multiplayer.is_server():
		return
	_recarga = maxf(0.0, _recarga - delta)
	parado = not efeitos.pode_mover()
	envenenado = efeitos.tem(EfeitosEstado.VENENO)
	if is_queued_for_deletion():
		return  # o veneno ou a queimadura o derrotou
	var alvo := _escolher_alvo()
	_alvo_atual = alvo
	var dir := Vector2.ZERO
	# A luz protege da noite: o slime noturno foge se estiver dentro dela e não persegue quem
	# está nela (os do dia não ligam). Com Medo, foge de quem o assustou.
	var luz := World.luz_que_protege(self, global_position) if noturno else Vector2.INF
	var medo := efeitos.fugir_de()
	if parado:
		if _estado in [Estado.PREPARANDO, Estado.PULANDO]:
			_mudar(Estado.PASSEANDO)  # congelado ou atordoado no meio do ataque: perde o pulo
	elif medo != Vector2.INF:
		dir = (global_position - medo).normalized()
		_mudar(Estado.PASSEANDO)
		visual.flip_h = dir.x < 0.0
	elif luz != Vector2.INF:
		dir = (global_position - luz).normalized()
	else:
		dir = _decidir(alvo, delta)
	animacao = &"pulo" if dir != Vector2.ZERO or _estado == Estado.PULANDO else &"parado"
	if _estado == Estado.PREPARANDO:
		animacao = &"dano"  # achatado: está tomando impulso (aviso para esquivar)
	var rapidez := velocidade * (_VEL_PULO if _estado == Estado.PULANDO else 1.0)
	if _estado == Estado.RECUANDO:
		rapidez = _DIST_RECUO / _TEMPO_RECUO  # saltinho para trás depois da cabeçada
	if efeitos.impulso() != Vector2.ZERO:
		reacao.parar_empurrao()  # puxado ou empurrado por habilidade: vale só esse movimento
	# Atacando (achatado, no pulo ou quicando), o golpe do jogador não o empurra: o pulo
	# não é cortado, então trocar golpes sem esquivar custa vida.
	reacao.armadura = parado or _estado in [Estado.PREPARANDO, Estado.PULANDO, Estado.RECUANDO]
	velocity = dir * rapidez * efeitos.mult_velocidade() + reacao.empurrao(delta) + efeitos.impulso()
	move_and_slide()


## Quem perseguir: provocado, quem provocou (mesmo uma invocação); senão, o jogador visível
## mais perto.
func _escolher_alvo() -> Node2D:
	var provocador := efeitos.alvo_provocado()
	if provocador and not (provocador is Player and (provocador as Player).caido):
		return provocador
	return _jogador_mais_proximo()


func _jogador_mais_proximo() -> Player:
	var melhor: Player = null
	var menor := INF
	for j in get_tree().get_nodes_in_group(&"jogadores"):
		if (j as Player).escondido() or (j as Player).caido:
			continue  # Bomba de fumaça ou Invisível: perdeu o jogador de vista; caído: ignora
		var d := global_position.distance_to(j.global_position)
		if d < menor:
			menor = d
			melhor = j
	return melhor


func _on_atingido(quantidade: float, tipo: StringName, origem: Node) -> void:
	var dano := quantidade
	if elemento != &"":
		var e: Dictionary = ELEMENTOS[elemento]
		if tipo in e.imune:
			World.efeito_todos(self, &"poeira", global_position)
			return  # o próprio elemento não faz nada
		if tipo == e.fraco:
			# Fogo derrete o gelo, gelo apaga o fogo, fogo queima o veneno: o triplo.
			if tipo == &"gelo":
				dano *= 3.0
				tipo = &"fisico_elemento"  # o gelo apaga o fogo, mas não congela
			else:
				dano *= 1.5  # o fogo já dá o dobro no slime: fica o triplo
	match tipo:
		&"gelo":
			efeitos.aplicar(EfeitosEstado.CONGELADO, TEMPO_CONGELADO, 0.0, origem)
			World.efeito_todos(self, &"congelar", global_position + Vector2(0, -6))
		&"fogo":
			if congelado():
				efeitos.remover(EfeitosEstado.CONGELADO)
				efeitos.aplicar(EfeitosEstado.MOLHADO, EfeitosEstado.MOLHADO_SEGUNDOS)  # o gelo derreteu
			else:
				dano *= 2.0
		&"luz":
			if noturno:
				dano *= 3.0  # a luz sagrada queima o slime da noite
		&"fisico":
			if congelado():
				dano *= 2.0
				efeitos.remover(EfeitosEstado.CONGELADO)
				World.avisar_todos(self, "Estilhaçou! Golpe em inimigo congelado dá dano dobrado.")
	parado = not efeitos.pode_mover()
	reacao.armadura = parado or _estado in [Estado.PREPARANDO, Estado.PULANDO, Estado.RECUANDO]
	vida.tomar_dano(dano, tipo)  # o ReacaoGolpe empurra, pisca e mostra o número


## O pulo acertou `alvo` (um jogador ou uma invocação): dá o dano, se não errar (Cego).
## Devolve se machucou.
func _cabecada(alvo: Node2D) -> bool:
	if efeitos.erra_ataque():
		World.efeito_todos(self, &"poeira", alvo.global_position)
		return false
	var v := alvo.get_node_or_null("HealthComponent") as HealthComponent
	if v == null or not v.tomar_dano(Passivas.ataque_inimigo(self, alvo, dano_contato), &"fisico"):
		return false
	if elemento != &"":
		var e: Dictionary = ELEMENTOS[elemento]
		EfeitosEstado.aplicar_em(alvo, e.estado, e.segundos, e.forca, self, 3)
	if alvo is Player:
		(alvo as Player).avisar("O slime pulou em você! Esquive (Shift) quando ele achatar.")
		(alvo as Player).reagir_ao_golpe(global_position)
	return true




func _on_morreu() -> void:
	var xp := XP_DERROTA * (2 if noturno else 1) + (5 if elemento != &"" else 0)
	World.dar_xp_em_volta(self, global_position, xp)
	World.avisar_todos(self, "Slime derrotado! +%d de experiência para quem estava perto." % xp)
	# Saque: gel de slime no chão (o da noite deixa mais).
	var gel := (2 if noturno else 1) + randi() % 2
	var itens := [[&"gel_slime", gel]]
	if elemento != &"":
		var extra: Array = ELEMENTOS[elemento].saque
		if randf() < float(extra[1]):
			itens.append([extra[0], 1])
	World.soltar_itens(self, global_position, itens)
	queue_free()


## O sol derrete o slime da noite (só o anfitrião chama).
func derreter() -> void:
	World.efeito_todos(self, &"poeira", global_position)
	queue_free()


# --- Comportamento ------------------------------------------------------------------
## PASSEANDO: sem ninguém por perto, dá pulinhos para lugares próximos de onde nasceu.
## PERSEGUINDO: alguém entrou no raio de visão.
## PREPARANDO: chegou perto; achata por um instante (o aviso para o jogador esquivar).
## PULANDO: salta na direção em que o jogador estava; acerta quem estiver no caminho.
## RECUANDO: acertou (cabeçada): dá o dano uma vez e quica para trás; depois espera a recarga.
enum Estado { PASSEANDO, PERSEGUINDO, PREPARANDO, PULANDO, RECUANDO }
const _DIST_ATAQUE := 30.0
const _TEMPO_PREPARO := 0.45
const _TEMPO_PULO := 0.3
const _VEL_PULO := 4.2
const _DIST_RECUO := 12.0  # px que ele quica para trás depois de acertar
const _TEMPO_RECUO := 0.2
## Recarga depois da cabeçada (errando o pulo, vale `recarga_contato`).
const _RECARGA_CABECADA := 0.8

var _estado := Estado.PASSEANDO
var _tempo_estado := 0.0
var _casa := Vector2.INF
var _destino := Vector2.INF
var _dir_pulo := Vector2.ZERO
var _acertou_pulo := false
var _dir_recuo := Vector2.ZERO


func _decidir(alvo: Node2D, delta: float) -> Vector2:
	if _casa == Vector2.INF:
		_casa = global_position
	_tempo_estado += delta
	var para_alvo := alvo.global_position - global_position if alvo else Vector2.INF
	# Passos de gato (Ladino): o slime só nota o jogador mais de perto. Provocado, sempre vê
	# quem provocou.
	var fator: float = (alvo as Player).fator_visao() if alvo is Player else 1.0
	var ve_alvo: bool = alvo != null and para_alvo.length() < raio_visao * fator \
			and not (noturno and World.luz_que_protege(self, alvo.global_position) != Vector2.INF)
	if alvo != null and alvo == efeitos.alvo_provocado():
		ve_alvo = true
	match _estado:
		Estado.PREPARANDO:
			if _tempo_estado >= _TEMPO_PREPARO:
				_mudar(Estado.PULANDO)
				_acertou_pulo = false
			return Vector2.ZERO
		Estado.PULANDO:
			if not _acertou_pulo and alvo and para_alvo.length() < 12.0:
				_acertou_pulo = true
				# Cabeçada: o dano vem uma vez; se pegou, o slime quica para trás.
				if _cabecada(alvo):
					_dir_recuo = -para_alvo.normalized() if para_alvo.length() > 0.1 else -_dir_pulo
					_mudar(Estado.RECUANDO)
					return _dir_recuo
			if _tempo_estado >= _TEMPO_PULO:
				_recarga = recarga_contato * Combate.ritmo_inimigo(self)
				_mudar(Estado.PERSEGUINDO if ve_alvo else Estado.PASSEANDO)
			return _dir_pulo
		Estado.RECUANDO:
			if _tempo_estado >= _TEMPO_RECUO:
				_recarga = _RECARGA_CABECADA * Combate.ritmo_inimigo(self)
				_mudar(Estado.PERSEGUINDO if ve_alvo else Estado.PASSEANDO)
				return Vector2.ZERO
			return _dir_recuo
	if ve_alvo:
		_estado = Estado.PERSEGUINDO
		visual.flip_h = para_alvo.x < 0.0
		if para_alvo.length() < _DIST_ATAQUE and _recarga <= 0.0 and efeitos.pode_atacar():
			_dir_pulo = para_alvo.normalized()
			_mudar(Estado.PREPARANDO)
			return Vector2.ZERO
		if _recarga > 0.0 and para_alvo.length() < _DIST_ATAQUE:
			return Vector2.ZERO  # esperando a recarga: não encosta de novo
		return para_alvo.normalized()
	_estado = Estado.PASSEANDO
	# Pulinhos a esmo: anda até um ponto perto de casa, para um pouco e escolhe outro.
	if _destino == Vector2.INF or global_position.distance_to(_destino) < 4.0:
		if _tempo_estado < 1.5:
			return Vector2.ZERO
		_tempo_estado = 0.0
		_destino = _casa + Vector2(randf_range(-40, 40), randf_range(-40, 40))
	var ir := _destino - global_position
	if _tempo_estado > 4.0:  # preso em algo: desiste deste destino
		_destino = Vector2.INF
		_tempo_estado = 0.0
	visual.flip_h = ir.x < 0.0
	return ir.normalized() * 0.5


func _mudar(novo: Estado) -> void:
	_estado = novo
	_tempo_estado = 0.0
