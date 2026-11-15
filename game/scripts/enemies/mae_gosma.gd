class_name MaeGosma
extends CharacterBody2D
## A Mãe Gosma, primeiro guardião (design/proposta_mundo.md, seção 5). Só o anfitrião pensa;
## os outros recebem posição, animação, elemento, fase e o ponto do alvo (propriedades do
## MultiplayerSynchronizer), e cada um desenha o alvo no chão e a barra de boss.
##
## Fase 1: pula e esmaga. O ALVO no chão avisa onde cai (TEMPO_AVISO); a queda dá dano em
##         área e solta slimes pequenos (com limite de vivos).
## Fase 2 (metade da vida): vira fogo, gelo ou veneno (troca a cada SEGUNDOS_POR_ELEMENTO ou
##         PULOS_POR_ELEMENTO), imune ao próprio elemento e frágil ao contrário (mesma tabela
##         do slime, Slime.ELEMENTOS), e deixa poças do elemento onde cai.
## Fase 3 (1/4 da vida): se divide em 3 gosmas menores (uma de cada elemento) com a vida
##         que sobrou dividida. O boss só acaba quando as 3 morrem (ArenaGosma.vencer).
## Nas fases 1 e 2 o golpe nunca passa do limite da fase: ela não morre sem se dividir.

const CENA := "res://scenes/enemies/mae_gosma.tscn"
const SLIME := "res://scenes/enemies/slime.tscn"
const TEXTURA_BASE := preload("res://assets/sprites/tiny/pedras_slime.png")
const TEXTURA_ELEMENTOS := preload("res://assets/sprites/tiny/inimigos/slimes_elementos.png")

const VIDA_BASE := 240.0
## A vida cresce com os jogadores: +75% por jogador a mais.
const VIDA_POR_JOGADOR := 0.75
const DANO_ESMAGAR := 22.0
const RAIO_ESMAGAR := 34.0
const TEMPO_AVISO := 1.0
const TEMPO_NO_AR := 0.45
const TEMPO_DESCANSO := 1.5
const TEMPO_ESMAGANDO := 0.35
const ALTURA_PULO := 48.0
const FASE2_EM := 0.5
const FASE3_EM := 0.25
const SEGUNDOS_POR_ELEMENTO := 15.0
const PULOS_POR_ELEMENTO := 3
const ORDEM_ELEMENTOS: Array[StringName] = [&"fogo", &"gelo", &"veneno"]
## Quanto o elemento contrário dá a mais (fogo no gelo, gelo no fogo, fogo no veneno).
const MULT_FRAGIL := 2.5
const XP_DERROTA := 150

## Animação atual (sincronizada).
@export var animacao: StringName = &"parada"
## &"" na fase 1; depois fogo, gelo ou veneno (sincronizado: troca a folha de todos).
@export var elemento: StringName = &""
## Uma das 3 menores da fase 3.
@export var filhote := false
@export var fase := 1
## Vida atual desta gosma e a vida total da luta (a barra do boss soma as gosmas vivas).
@export var pv := 1.0
@export var pv_ref := 1.0
## O ponto onde ela vai cair e se o aviso está ligado (todo mundo desenha o alvo).
@export var alvo_pos := Vector2.ZERO
@export var em_aviso := false
## Altura do pulo, só para o desenho.
@export var altura := 0.0

## Antes de entrar na cena: vida e total da luta das gosmas menores (anfitrião).
var vida_forcada := 0.0
var pv_ref_inicial := 0.0

enum Est { DESCANSO, AVISO, NO_AR, ESMAGANDO }
var _est := Est.DESCANSO
var _t := 0.0
var _origem := Vector2.ZERO
var _pulos_no_elemento := 0
var _tempo_elemento := 0.0
var _indice_elemento := -1
var _dano_visivel := 0.0
var _elemento_visto: StringName = &"?"
var _escala := 1.0
var _alvo_sprite: Sprite2D
var reacao: ReacaoGolpe

@onready var visual: AnimatedSprite2D = $Visual
@onready var colisao: CollisionShape2D = $Colisao
@onready var vida: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var forma_hurt: CollisionShape2D = $Hurtbox/Forma
@onready var barra: BarraCabeca = $BarraCabeca
@onready var efeitos: EfeitosEstado = $EfeitosEstado


## Vida da luta para este número de jogadores (sem a dificuldade do mundo).
static func vida_para(jogadores: int) -> float:
	return VIDA_BASE * (1.0 + VIDA_POR_JOGADOR * maxi(jogadores - 1, 0))


## Slimes pequenos por pulo: 2 até 2 jogadores, 3 com 3 ou 4, e assim por diante.
static func filhotes_por_pulo(jogadores: int) -> int:
	return 2 + maxi(jogadores - 1, 0) / 2


## Quantos slimes pequenos podem estar vivos ao mesmo tempo.
static func limite_slimes(jogadores: int) -> int:
	return 4 + 2 * maxi(jogadores - 1, 0)


func _ready() -> void:
	add_to_group(&"inimigos")
	add_to_group(&"boss_gosma")
	_escala = (ArteGosma.ESCALA_FILHOTE if filhote else 1.0)
	_montar_forma()
	_montar_frames()
	visual.play(animacao)
	barra.definir_nivel(8)
	barra.ajustar_ao_sprite(visual)
	reacao = ReacaoGolpe.em(self, 6.0)
	reacao.armadura = true  # a gosma não sai do lugar com golpe: só o pulo a move
	reacao.reagiu.connect(func(_q: float, _c: bool, _f: float) -> void: _dano_visivel = 0.25)
	_alvo_sprite = Sprite2D.new()
	_alvo_sprite.top_level = true
	_alvo_sprite.visible = false
	_montar_alvo()
	ArteGosma.no_chao(_alvo_sprite, self)
	if multiplayer.is_server():
		if filhote:
			vida.maximo = maxf(vida_forcada, 1.0)
			pv_ref = pv_ref_inicial
		else:
			vida.maximo = vida_para(get_tree().get_nodes_in_group(&"jogadores").size()) \
					* World.mult_dificuldade(self, &"vida_inimigo")
			pv_ref = vida.maximo
		vida.atual = vida.maximo
		pv = vida.atual
		hurtbox.atingido.connect(_on_atingido)
		vida.morreu.connect(_on_morreu)
		_t = 0.0
		if filhote:
			_indice_elemento = maxi(ORDEM_ELEMENTOS.find(elemento), 0)


func _exit_tree() -> void:
	if _alvo_sprite and is_instance_valid(_alvo_sprite):
		_alvo_sprite.queue_free()


# --- Desenho ---------------------------------------------------------------------------

func _montar_forma() -> void:
	var c := CircleShape2D.new()
	c.radius = 12.0 * _escala
	colisao.shape = c
	colisao.position = Vector2(0, -3)
	var r := RectangleShape2D.new()
	r.size = Vector2(54.0, 46.0) * _escala
	forma_hurt.shape = r
	forma_hurt.position = Vector2(0, -22.0 * _escala)


## Tira de 6 quadros (arte final) ou o slime existente em escala maior (placeholder).
func _montar_frames() -> void:
	var f := SpriteFrames.new()
	f.remove_animation(&"default")
	var t := Vector2i(ArteGosma.QUADRO, ArteGosma.QUADRO)
	var qs: Array[Texture2D] = []
	var s: float
	var folha := ArteGosma.textura(String(ArteGosma.FOLHAS.get(elemento, ArteGosma.FOLHAS[&""])))
	if folha:
		for i in 6:
			qs.append(SpriteSheets.quadro(folha, i, t))
		s = ArteGosma.ESCALA_ARTE
		visual.modulate = Color.WHITE
	else:
		var tex: Texture2D = TEXTURA_BASE if elemento == &"" else TEXTURA_ELEMENTOS
		var q0: int = 4 if elemento == &"" else int(Slime.ELEMENTOS[elemento].quadro)
		var parado := SpriteSheets.quadro(tex, q0, t)
		var achatado := SpriteSheets.quadro(tex, q0 + 1, t)
		qs = [parado, parado, achatado, parado, achatado, achatado]
		s = ArteGosma.ESCALA_PLACEHOLDER
	s *= _escala
	visual.scale = Vector2(s, s)
	_base_y = -64.0 * s + 2.0
	visual.position.y = _base_y
	var Q := ArteGosma.Quadro
	SpriteSheets.adicionar_quadros(f, &"parada", [qs[Q.PARADA], qs[Q.RESPIRANDO]] as Array[Texture2D], 2.0)
	SpriteSheets.adicionar_quadros(f, &"agachando", [qs[Q.AGACHANDO]] as Array[Texture2D], 1.0)
	SpriteSheets.adicionar_quadros(f, &"no_ar", [qs[Q.NO_AR]] as Array[Texture2D], 1.0)
	SpriteSheets.adicionar_quadros(f, &"esmagando", [qs[Q.ESMAGANDO]] as Array[Texture2D], 1.0)
	SpriteSheets.adicionar_quadros(f, &"machucada", [qs[Q.MACHUCADA]] as Array[Texture2D], 1.0)
	visual.sprite_frames = f
	_elemento_visto = elemento
	barra.ajustar_ao_sprite(visual)


var _base_y := 0.0


## O alvo no chão: o quadro 0 da folha da arena; sem ela, o slime achatado escuro e chato.
func _montar_alvo() -> void:
	var q := ArteGosma.quadro_arena(ArteGosma.Arena.ALVO)
	var raio := RAIO_ESMAGAR * _escala
	if q:
		_alvo_sprite.texture = q
		var k := raio * 2.0 / float(ArteGosma.QUADRO) * 1.3
		_alvo_sprite.scale = Vector2(k, k)
		_alvo_sprite.modulate = Color(3.2, 1.3, 1.2)  # o anel escuro da arte fica claro e avermelhado no chão escuro
	else:
		_alvo_sprite.texture = SpriteSheets.quadro(TEXTURA_BASE, 5, Vector2i(128, 128))
		var k2 := raio * 2.0 / 128.0 * 2.2
		_alvo_sprite.scale = Vector2(k2, k2 * 0.6)
		_alvo_sprite.modulate = Color(0.1, 0.05, 0.1, 0.55)


# --- Mundo -----------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if elemento != _elemento_visto:
		_montar_frames()
		_montar_alvo()
	visual.modulate = efeitos.cor()
	visual.position.y = _base_y - altura
	_alvo_sprite.visible = em_aviso
	_alvo_sprite.global_position = alvo_pos
	if em_aviso:
		var k := 0.85 + 0.15 * sin(Time.get_ticks_msec() / 90.0)
		_alvo_sprite.self_modulate = Color(1, 1, 1, k)
	_dano_visivel = maxf(0.0, _dano_visivel - delta)
	var quer: StringName = &"machucada" if _dano_visivel > 0.0 and _est == Est.DESCANSO else animacao
	if visual.animation != quer:
		visual.play(quer)
	if not multiplayer.is_server():
		return
	pv = vida.atual
	if is_queued_for_deletion():
		return
	_verificar_fases()
	if is_queued_for_deletion():
		return
	_t += delta
	if fase == 2 and not filhote:
		_tempo_elemento += delta
		if _tempo_elemento >= SEGUNDOS_POR_ELEMENTO:
			_trocar_elemento()
	match _est:
		Est.DESCANSO:
			animacao = &"parada"
			var espera := TEMPO_DESCANSO * (0.8 if filhote else 1.0) * Combate.ritmo_inimigo(self)
			if _t >= espera and _alguem_na_arena():
				_comecar_aviso()
		Est.AVISO:
			animacao = &"agachando"
			if _t >= (TEMPO_AVISO * 0.8 if filhote else TEMPO_AVISO):
				_origem = global_position
				_mudar(Est.NO_AR)
		Est.NO_AR:
			animacao = &"no_ar"
			var p := clampf(_t / TEMPO_NO_AR, 0.0, 1.0)
			global_position = _origem.lerp(alvo_pos, p)
			altura = sin(p * PI) * ALTURA_PULO * _escala
			if p >= 1.0:
				_esmagar()
		Est.ESMAGANDO:
			animacao = &"esmagando"
			if _t >= TEMPO_ESMAGANDO:
				_mudar(Est.DESCANSO)


func _mudar(novo: Est) -> void:
	_est = novo
	_t = 0.0


func _alguem_na_arena() -> bool:
	return not _alvos_possiveis().is_empty() or get_tree().get_nodes_in_group(&"jogadores").is_empty()


func _alvos_possiveis() -> Array[Player]:
	var lista: Array[Player] = []
	var arena := ArenaGosma.da_cena(self)
	for j in get_tree().get_nodes_in_group(&"jogadores"):
		var p := j as Player
		if p.caido or p.escondido():
			continue
		if arena and not arena.dentro(p.global_position, 40.0):
			continue
		lista.append(p)
	return lista


func _comecar_aviso() -> void:
	var alvos := _alvos_possiveis()
	var onde := global_position
	if not alvos.is_empty():
		onde = alvos[randi() % alvos.size()].global_position
	var arena := ArenaGosma.da_cena(self)
	if arena:
		onde = arena.limitar(onde, 8.0)
	alvo_pos = onde
	em_aviso = true
	_mudar(Est.AVISO)


## A queda: dano em área, poeira, slimes pequenos (fase 1) e poça (depois).
func _esmagar() -> void:
	altura = 0.0
	global_position = alvo_pos
	em_aviso = false
	var raio := RAIO_ESMAGAR * _escala
	var dano := DANO_ESMAGAR * (0.6 if filhote else 1.0)
	for j in get_tree().get_nodes_in_group(&"jogadores"):
		var p := j as Player
		if p.caido or p.global_position.distance_to(alvo_pos) > raio:
			continue
		if efeitos.erra_ataque():
			continue
		if p.vida.tomar_dano(Passivas.ataque_inimigo(self, p, dano), &"fisico"):
			p.reagir_ao_golpe(alvo_pos)
			p.avisar("A Mãe Gosma esmagou! Fuja do alvo no chão.")
			if elemento != &"":
				var e: Dictionary = Slime.ELEMENTOS[elemento]
				EfeitosEstado.aplicar_em(p, e.estado, e.segundos, e.forca, self, 3)
	World.efeito_todos(self, &"poeira", alvo_pos)
	if not filhote and fase == 1:
		_soltar_slimes()
	if elemento != &"":
		_poca.rpc(alvo_pos, elemento)
		_pulos_no_elemento += 1
		if fase == 2 and not filhote and _pulos_no_elemento >= PULOS_POR_ELEMENTO:
			_trocar_elemento()
	_mudar(Est.ESMAGANDO)


func _soltar_slimes() -> void:
	var n := get_tree().get_nodes_in_group(&"jogadores").size()
	var vivos := 0
	for s in get_tree().get_nodes_in_group(&"cria_gosma"):
		if is_instance_valid(s) and not s.is_queued_for_deletion():
			vivos += 1
	var quer := mini(filhotes_por_pulo(n), limite_slimes(n) - vivos)
	for i in maxi(quer, 0):
		var s := (load(SLIME) as PackedScene).instantiate() as Slime
		s.escala_extra = 0.6
		s.name = "SlimeGosma%d" % Time.get_ticks_usec()
		var ang := TAU * (float(i) / maxf(quer, 1.0)) + randf() * 0.6
		s.position = alvo_pos + Vector2.from_angle(ang) * 18.0
		s.add_to_group(&"cria_gosma")
		get_parent().add_child(s, true)


@rpc("authority", "call_local", "reliable")
func _poca(pos: Vector2, quem: StringName) -> void:
	var poca := PocaGosma.new()
	poca.elemento = quem
	poca.position = pos
	poca.raio = (RAIO_ESMAGAR * 0.8) * _escala
	ArteGosma.no_chao(poca, self)


# --- Fases e elemento ------------------------------------------------------------------

func _verificar_fases() -> void:
	if filhote:
		return
	if fase == 1 and vida.atual <= vida.maximo * FASE2_EM + 0.001:
		_entrar_fase2()
	if fase == 2 and vida.atual <= vida.maximo * FASE3_EM + 0.001:
		_dividir()


func _entrar_fase2() -> void:
	fase = 2
	_tempo_elemento = 0.0
	_pulos_no_elemento = 0
	_indice_elemento = -1
	_trocar_elemento()
	World.avisar_todos(self, "A Mãe Gosma muda! Fogo derrete o gelo, gelo apaga o fogo, fogo queima o veneno.")


## Passa para o próximo elemento da ordem fogo, gelo, veneno.
func _trocar_elemento() -> void:
	_indice_elemento = (_indice_elemento + 1) % ORDEM_ELEMENTOS.size()
	elemento = ORDEM_ELEMENTOS[_indice_elemento]
	_tempo_elemento = 0.0
	_pulos_no_elemento = 0
	World.efeito_todos(self, &"poeira", global_position)
	var contra: StringName = Slime.ELEMENTOS[elemento].fraco
	World.avisar_todos(self, "A Mãe Gosma virou %s! Ela é imune a %s e frágil a %s." % [elemento, elemento, contra])
	_montar_frames()
	_montar_alvo()


## Fase 3: três gosmas menores, uma de cada elemento, com a vida que restou dividida.
func _dividir() -> void:
	fase = 3
	remove_from_group(&"boss_gosma")
	var pool := maxf(vida.atual, vida.maximo * 0.05)
	var cena := load(CENA) as PackedScene
	var pai := get_parent()
	for i in 3:
		var g := cena.instantiate() as MaeGosma
		g.filhote = true
		g.fase = 3
		g.elemento = ORDEM_ELEMENTOS[i]
		g.vida_forcada = pool / 3.0
		g.pv_ref_inicial = pv_ref
		g.name = "MaeGosmaFilha%d_%d" % [i, Time.get_ticks_usec()]
		g.position = global_position + Vector2.from_angle(TAU * float(i) / 3.0 + 0.5) * 26.0
		pai.add_child(g, true)
	for s in get_tree().get_nodes_in_group(&"cria_gosma"):
		if is_instance_valid(s):
			s.queue_free()
	World.efeito_todos(self, &"poeira", global_position)
	World.avisar_todos(self, "A Mãe Gosma se partiu em três! Cada uma tem um elemento: separem-se.")
	em_aviso = false
	set_physics_process(false)
	queue_free()


# --- Dano e morte ----------------------------------------------------------------------

func _on_atingido(quantidade: float, tipo: StringName, _origem: Node) -> void:
	var dano := quantidade
	if elemento != &"":
		var e: Dictionary = Slime.ELEMENTOS[elemento]
		if tipo in e.imune:
			World.efeito_todos(self, &"poeira", global_position)
			return  # o próprio elemento não faz nada
		if tipo == e.fraco:
			dano *= MULT_FRAGIL
	# Nas fases 1 e 2 o golpe para no limite da fase: ela só morre dividida (fase 3).
	if not filhote and fase < 3:
		var piso := vida.maximo * (FASE2_EM if fase == 1 else FASE3_EM)
		dano = minf(dano, vida.atual - piso)
		if dano <= 0.0:
			return
	vida.tomar_dano(dano, tipo)  # o ReacaoGolpe pisca e mostra o número
	pv = vida.atual
	_verificar_fases()


func _on_morreu() -> void:
	if not filhote and fase < 3:
		# Morreu por um estado (veneno, queimadura) sem passar pelo limite: divide mesmo assim.
		if not is_queued_for_deletion():
			_dividir()
		return
	var arena := ArenaGosma.da_cena(self)
	World.dar_xp_em_volta(self, global_position, XP_DERROTA / 3)
	remove_from_group(&"boss_gosma")
	var restam := 0
	for g in get_tree().get_nodes_in_group(&"boss_gosma"):
		if g != self and is_instance_valid(g) and not g.is_queued_for_deletion():
			restam += 1
	World.efeito_todos(self, &"poeira", global_position)
	if restam == 0 and arena:
		arena.vencer(global_position)
	elif restam > 0:
		World.avisar_todos(self, "Uma gosma caiu! Faltam %d." % restam)
	queue_free()
