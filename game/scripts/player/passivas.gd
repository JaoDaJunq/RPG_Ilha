class_name Passivas
extends RefCounted
## O que as passivas da árvore de habilidades mudam no jogo (ArvoreData tem a lista).
## Cada função recebe o jogador e olha `p.tem(<nó>)`. As de dano rodam no ANFITRIÃO (quem
## confere os acertos); as de andar, carregar o arco e coletar rodam no DONO (quem anda), que
## também conhece a árvore de todos (ela vem no _progresso_sync).

# --- Guerreiro -------------------------------------------------------------------------
const PELE_DE_FERRO := 0.9  # dano físico recebido
const PELE_EMPURRAO := 0.5  # empurrão recebido
const LENHADOR := 1.2  # cortar árvore mais rápido
const MURALHA_VIVA := 0.85
const RAIO_MURALHA := 48.0
const SANGUE_QUENTE := 0.4  # até +40% de dano com a vida no fim
const SEDE := 0.05  # da vida máxima por inimigo derrotado
const COMANDO := 1.05
const VETERANO_POR_ALIADO := 0.1
const VETERANO_MAXIMO := 3
## "Perto" para as passivas de grupo (5 blocos).
const RAIO_ALIADOS := 80.0

# --- Mago ----------------------------------------------------------------------------
const FLUXO_ARCANO := 1.25
const RESSONANCIA := 1.15
const ELEMENTOS_MAGO: Array[StringName] = [&"fogo", &"gelo", &"raio", &"terra"]
const SOBRECARGA_A_CADA := 4
const RAIZES := 0.8
const RAIZES_PARADO := 1.0  # segundos parado
const CONDUCAO_RAIO := 56.0  # distância do salto do Raio
const ESTILHACAR_RAIO := 28.0

# --- Arqueiro ------------------------------------------------------------------------
const MAO_LEVE_CARGA := 1.3  # puxa o arco 30% mais rápido
const MAO_LEVE_TIRO := 1.15  # a flecha voa 15% mais rápido
const OLHO_DE_AGUIA := 1.2
const RASTREADOR := 2.0
const PONTO_FRACO := 1.25
const PONTO_FRACO_DISTANCIA := 6.0 * 16.0  # 6 blocos
const ENGENHOSO_MANA := 0.7
const ENGENHOSO_ARMADILHAS := 3
const HABILIDADES_ENGENHOSO: Array[StringName] = [&"armadilha", &"bomba"]

# --- Ladino --------------------------------------------------------------------------
const PELAS_COSTAS := 1.5
const PASSOS_DE_GATO := 0.7  # os inimigos só notam a 70% da distância
const EMBOSCADA_JANELA_MS := 1000  # depois que a fumaça acaba
const EXECUCAO := 2.0
const EXECUCAO_VIDA := 0.3
const CONTAGIO_RAIO := 36.0
const RITMO_VELOCIDADE := 1.1
const RITMO_MS := 2000

# --- Clérigo -------------------------------------------------------------------------
const AURA_SERENA := 1.0
const AURA_INTERVALO := 3.0
const AURA_RAIO := 56.0
const FE_SEGUNDOS := 5.0
const MAOS_QUE_CURAM := 1.25
const ULTIMO_SUSPIRO_MS := 60000
const RAIO_CLERIGO := 120.0
const EGIDE := 1.3
const VIGILIA := 0.85
const VIGILIA_VIDA := 0.35
const FOGO_SAGRADO := 1.5
const JULGAMENTO := 1.15
const JULGAMENTO_MS := 5000
const LUZ_PROPRIA_RAIO := 40.0

# --- Acerto crítico (todas as classes) --------------------------------------------------
## Chance de todo golpe ou habilidade num inimigo ou animal ser crítico, e quanto ele dá.
## Também são críticos: o 1º golpe depois da fumaça (Emboscada), o golpe depois de uma
## Esquiva perfeita e o Tiro carregado com a carga cheia (forcar_critico).
const CHANCE_CRITICO := 0.05
const CRITICO := 2.0
## -1 = o padrão (CHANCE_CRITICO no jogo; 0 nas cenas de teste, para os números de dano
## serem exatos). Os testes do crítico mudam este valor.
static var chance_critico := -1.0


# --- Dano que o jogador causa (anfitrião) ---------------------------------------------

## Chamado pela Hurtbox do alvo antes de repassar o acerto.
static func dano_causado(p: Player, quantidade: float, tipo: StringName, alvo: Node) -> float:
	var m := 1.0
	if p.tem(&"sangue_quente"):
		m *= 1.0 + SANGUE_QUENTE * (1.0 - p.vida.atual / maxf(p.vida.maximo, 1.0))
	var a := alvo as Node2D
	if a:
		if p.tem(&"rastreador") and a.is_in_group(&"animais"):
			m *= RASTREADOR
		if p.tem(&"pelas_costas") and pelas_costas(p, a):
			m *= PELAS_COSTAS
		if p.tem(&"ponto_fraco") and p.global_position.distance_to(a.global_position) > PONTO_FRACO_DISTANCIA:
			m *= PONTO_FRACO
		var v := a.get_node_or_null("HealthComponent") as HealthComponent
		if p.tem(&"execucao") and v and v.atual < v.maximo * EXECUCAO_VIDA:
			m *= EXECUCAO
		if tipo == &"luz":
			if p.tem(&"fogo_sagrado") and a.get(&"noturno") == true:
				m *= FOGO_SAGRADO
			if p.tem(&"julgamento"):
				a.set_meta(&"julgado_ate_ms", Time.get_ticks_msec() + JULGAMENTO_MS)
		if tipo == &"fisico" and p.tem(&"estilhacar") and a.has_method(&"congelado") and a.congelado():
			_estilhacar(p, a, quantidade * m)
	if a and (a.is_in_group(&"inimigos") or a.is_in_group(&"animais")) and _critico(p):
		m *= CRITICO
		critou(p, a)
	m *= p.buffs.mult(&"dano")
	m *= PassivasGuerreiro.dano_causado(p, quantidade, tipo, alvo) * PassivasMago.dano_causado(p, quantidade, tipo, alvo) \
			* PassivasArqueiro.dano_causado(p, quantidade, tipo, alvo) * PassivasLadino.dano_causado(p, quantidade, tipo, alvo) \
			* PassivasClerigo.dano_causado(p, quantidade, tipo, alvo)
	return quantidade * m


## Este acerto é crítico? (consome o crítico garantido: Emboscada, Esquiva perfeita, Tiro
## carregado cheio). Anfitrião.
static func _critico(p: Player) -> bool:
	var garantido := p.consumir_emboscada()
	if p.get_meta(&"critico_pronto", false):
		p.set_meta(&"critico_pronto", false)
		garantido = true
	return garantido or randf() < _chance_critico(p)


static func _chance_critico(p: Player) -> float:
	if chance_critico >= 0.0:
		return chance_critico
	var cena := p.get_tree().current_scene if p.is_inside_tree() else null
	if cena and cena.scene_file_path.begins_with("res://tests/"):
		return 0.0
	return CHANCE_CRITICO


## O próximo acerto de `p` num inimigo ou animal é crítico (anfitrião).
static func forcar_critico(p: Player) -> void:
	p.set_meta(&"critico_pronto", true)


## `p` acabou de dar um crítico em `alvo`: o brilho do acerto para todos e as passivas
## (Sangue frio). Anfitrião.
static func critou(p: Player, alvo: Node2D) -> void:
	p.set_meta(&"ultimo_critico_ms", Time.get_ticks_msec())
	p.set_meta(&"criticos", int(p.get_meta(&"criticos", 0)) + 1)
	World.efeito_todos(p, &"giro", alvo.global_position + Vector2(0, -8))
	PassivasArqueiro.critou(p, alvo)


## Depois que um golpe ou habilidade do jogador acertou `alvo` (Hurtbox; anfitrião).
static func acertou(p: Player, alvo: Node, quantidade: float, tipo: StringName) -> void:
	p.recursos.ao_acertar(alvo, quantidade, tipo)
	PassivasGuerreiro.acertou(p, alvo, quantidade, tipo)
	PassivasMago.acertou(p, alvo, quantidade, tipo)
	PassivasArqueiro.acertou(p, alvo, quantidade, tipo)
	PassivasLadino.acertou(p, alvo, quantidade, tipo)
	PassivasClerigo.acertou(p, alvo, quantidade, tipo)


## Dano de um inimigo ou animal (`atacante`) em `alvo` (anfitrião): os estados do atacante e
## as passivas que mexem nisso (ex.: Frio que morde).
static func ataque_inimigo(atacante: Node, alvo: Node, dano: float) -> float:
	var m := World.mult_dificuldade(atacante, &"dano_inimigo")
	m *= PassivasGuerreiro.ataque_inimigo(atacante, alvo, dano) * PassivasMago.ataque_inimigo(atacante, alvo, dano) \
			* PassivasArqueiro.ataque_inimigo(atacante, alvo, dano) * PassivasLadino.ataque_inimigo(atacante, alvo, dano) \
			* PassivasClerigo.ataque_inimigo(atacante, alvo, dano)
	return dano * m


## Julgamento: o alvo marcado toma mais dano de qualquer um.
static func marca_no_alvo(alvo: Node) -> float:
	if alvo and alvo.has_meta(&"julgado_ate_ms") and Time.get_ticks_msec() < int(alvo.get_meta(&"julgado_ate_ms")):
		return JULGAMENTO
	return 1.0


## O jogador está atrás do alvo? A frente do alvo é para onde ele anda; parado, para o lado
## em que o desenho olha.
static func pelas_costas(p: Player, alvo: Node2D) -> bool:
	var frente := Vector2.ZERO
	var corpo := alvo as CharacterBody2D
	if corpo and corpo.velocity.length() > 2.0:
		frente = corpo.velocity.normalized()
	else:
		var desenho := alvo.get_node_or_null("Visual") as AnimatedSprite2D
		if desenho:
			frente = Vector2.LEFT if desenho.flip_h else Vector2.RIGHT
	if frente == Vector2.ZERO:
		return false
	return (p.global_position - alvo.global_position).dot(frente) < 0.0


## Estilhaçar: o golpe no congelado também acerta os vizinhos (sem passar de novo pelas
## passivas: origem nula, então não vira cascata).
static func _estilhacar(p: Player, alvo: Node2D, dano: float) -> void:
	for e in inimigos_perto(p, alvo.global_position, ESTILHACAR_RAIO):
		if e != alvo:
			var area := e.get_node_or_null("Hurtbox") as Hurtbox
			if area:
				area.receber(dano, &"fisico", null)
	World.efeito_todos(p, &"congelar", alvo.global_position + Vector2(0, -6))


## O golpe do jogador derrotou `alvo` (anfitrião).
static func derrotou(p: Player, alvo: Node) -> void:
	var a := alvo as Node2D
	if a == null:
		return
	if p.tem(&"sede"):
		p.vida.curar(p.vida.maximo * SEDE)
	if p.tem(&"contagio") and a.get(&"envenenado") == true:
		for e in inimigos_perto(p, a.global_position, CONTAGIO_RAIO):
			if e != a and e.has_method(&"envenenar"):
				e.envenenar(Player.TEMPO_VENENO, maxf(p.dano_veneno(), 1.0))
	if p.tem(&"dedos_leves"):
		var extra: StringName = &""
		if a is Slime:
			extra = &"gel_slime"
		elif a is Atirador:
			extra = &"pena"
		elif a is Animal:
			extra = Animal.ESPECIES[(a as Animal).especie].saque[0][0]
		if extra != &"":
			World.soltar_itens(p, a.global_position, [[extra, 1]])
	PassivasGuerreiro.derrotou(p, a)
	PassivasMago.derrotou(p, a)
	PassivasArqueiro.derrotou(p, a)
	PassivasLadino.derrotou(p, a)
	PassivasClerigo.derrotou(p, a)


static func inimigos_perto(p: Player, centro: Vector2, raio: float) -> Array[Node2D]:
	var l: Array[Node2D] = []
	for n in p.get_tree().get_nodes_in_group(&"inimigos") + p.get_tree().get_nodes_in_group(&"animais"):
		var e := n as Node2D
		if e and not e.is_queued_for_deletion() and e.global_position.distance_to(centro) <= raio:
			l.append(e)
	return l


# --- Dano que o jogador recebe (anfitrião) --------------------------------------------

## Ligado em `vida.ajuste_dano` do jogador (depois do Bloqueio e do Escudo sagrado).
static func dano_recebido(p: Player, quantidade: float, tipo: StringName) -> float:
	var m := 1.0
	if tipo == &"fisico" and p.tem(&"pele_de_ferro"):
		m *= PELE_DE_FERRO
	if p.tem(&"raizes") and p.parado_ha() >= RAIZES_PARADO:
		m *= RAIZES
	var muralha := false
	var vigilia := false
	for o in outros_jogadores(p, RAIO_ALIADOS):
		var d := o.global_position.distance_to(p.global_position)
		if not muralha and o.tem(&"muralha_viva") and d <= RAIO_MURALHA and _atras_de(p, o):
			muralha = true
			m *= MURALHA_VIVA
		if not vigilia and o.tem(&"vigilia") and p.vida.atual < p.vida.maximo * VIGILIA_VIDA:
			vigilia = true
			m *= VIGILIA
	m *= 1.0 - clampf(p.buffs.valor(&"reducao"), 0.0, 1.0)
	m *= PassivasGuerreiro.dano_recebido(p, quantidade, tipo) * PassivasMago.dano_recebido(p, quantidade, tipo) \
			* PassivasArqueiro.dano_recebido(p, quantidade, tipo) * PassivasLadino.dano_recebido(p, quantidade, tipo) \
			* PassivasClerigo.dano_recebido(p, quantidade, tipo)
	quantidade *= m
	# Último suspiro: quem cairia fica com 1 de vida (um Clérigo perto, uma vez por minuto).
	if quantidade - p.vida.escudo >= p.vida.atual:
		for c in p.get_tree().get_nodes_in_group(&"jogadores"):
			var cl := c as Player
			if cl and cl.tem(&"ultimo_suspiro") and cl.global_position.distance_to(p.global_position) <= RAIO_CLERIGO and cl.usar_ultimo_suspiro():
				quantidade = maxf(0.0, p.vida.atual - 1.0 + p.vida.escudo)
				p.avisar("Último suspiro! Você ficou com 1 de vida.")
				break
	return quantidade


## `p` está atrás do guardião `g` (do lado oposto ao que ele olha)?
static func _atras_de(p: Player, g: Player) -> bool:
	return (p.global_position - g.global_position).dot(g.frente()) < 0.0


static func outros_jogadores(p: Player, raio: float) -> Array[Player]:
	var l: Array[Player] = []
	for n in p.get_tree().get_nodes_in_group(&"jogadores"):
		var o := n as Player
		if o and o != p and not o.criando and o.ficha and o.global_position.distance_to(p.global_position) <= raio:
			l.append(o)
	return l


# --- Números que mudam ---------------------------------------------------------------

## Multiplicador de velocidade das passivas (no dono, que é quem anda).
static func velocidade(p: Player) -> float:
	var m := RITMO_VELOCIDADE if p.ritmo_ativo() else 1.0
	for o in outros_jogadores(p, RAIO_ALIADOS):
		if o.tem(&"comando"):
			m *= COMANDO
			break
	m *= p.buffs.mult(&"velocidade") * p.efeitos.mult_velocidade()
	m *= PassivasGuerreiro.velocidade(p) * PassivasMago.velocidade(p) * PassivasArqueiro.velocidade(p) \
			* PassivasLadino.velocidade(p) * PassivasClerigo.velocidade(p)
	return m


## Recarga com as melhorias e o Veterano.
static func recarga(p: Player, hab: HabilidadeData) -> float:
	var r := hab.recarga * (1.0 - NoArvore.RECARGA_POR_MELHORIA * p.melhorias(hab.id))
	if p.tem(&"veterano"):
		r *= 1.0 - VETERANO_POR_ALIADO * mini(VETERANO_MAXIMO, outros_jogadores(p, RAIO_ALIADOS).size())
	r *= PassivasGuerreiro.recarga(p, hab) * PassivasMago.recarga(p, hab) * PassivasArqueiro.recarga(p, hab) \
			* PassivasLadino.recarga(p, hab) * PassivasClerigo.recarga(p, hab)
	return r


static func custo_mana(p: Player, hab: HabilidadeData) -> float:
	var c := hab.custo_mana
	if p.tem(&"engenhoso") and hab.id in HABILIDADES_ENGENHOSO:
		c *= ENGENHOSO_MANA
	return c * PassivasGuerreiro.custo_mana(p, hab) * PassivasMago.custo_mana(p, hab) * PassivasArqueiro.custo_mana(p, hab) \
			* PassivasLadino.custo_mana(p, hab) * PassivasClerigo.custo_mana(p, hab)


## Todo quadro, no anfitrião: as passivas das classes que precisam de relógio ou aura.
static func processar(p: Player, delta: float) -> void:
	PassivasGuerreiro.processar(p, delta)
	PassivasMago.processar(p, delta)
	PassivasArqueiro.processar(p, delta)
	PassivasLadino.processar(p, delta)
	PassivasClerigo.processar(p, delta)


static func alcance(p: Player) -> float:
	return OLHO_DE_AGUIA if p.tem(&"olho_de_aguia") else 1.0


static func regeneracao_mana(p: Player) -> float:
	return FLUXO_ARCANO if p.tem(&"fluxo_arcano") else 1.0


static func carga_maxima(p: Player) -> float:
	return Player.CARGA_MAXIMA / (MAO_LEVE_CARGA if p.tem(&"mao_leve") else 1.0)


static func coleta(p: Player, minerando: bool) -> float:
	return LENHADOR if not minerando and p.tem(&"braco_de_lenhador") else 1.0


static func empurrao(p: Player) -> float:
	return (PELE_EMPURRAO if p.tem(&"pele_de_ferro") else 1.0) * PassivasGuerreiro.empurrao(p)


static func visao_inimiga(p: Player) -> float:
	return PASSOS_DE_GATO if p.tem(&"passos_de_gato") else 1.0


static func armadilhas_maximas(p: Player) -> int:
	return ENGENHOSO_ARMADILHAS if p.tem(&"engenhoso") else 2


static func cura(p: Player) -> float:
	return MAOS_QUE_CURAM if p.tem(&"maos_que_curam") else 1.0


static func escudos(p: Player) -> float:
	return EGIDE if p.tem(&"egide") else 1.0
