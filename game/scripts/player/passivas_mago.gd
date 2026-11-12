class_name PassivasMago
extends RefCounted
## Passivas novas do Mago (árvore de habilidades). Passivas.gd chama estas funções em todo
## jogador, de qualquer classe: cada uma confere `p.tem(&"<nó>")` antes de agir. As
## antigas continuam em passivas.gd. Devolva 1.0 (ou não faça nada) quando não valer.
## Roda no ANFITRIÃO, menos `velocidade`, que roda no dono (quem anda), e `fixas`, que roda
## em todas as máquinas quando a árvore chega.

## Combustão: a Queimadura dura +2 s (4 → 6) e passa para quem está colado no alvo.
const COMBUSTAO_SEGUNDOS := 6.0
const COMBUSTAO_COLADO := 20.0
## Cinzas: quem morre queimando explode em volta.
const CINZAS_RAIO := 28.0
const CINZAS_DANO := 1.0  # × multiplicador mágico
## Frio que morde: acertos de gelo deixam Lentidão; quem está lento por este mago bate menos.
const FRIO_LENTIDAO := 0.4
const FRIO_SEGUNDOS := 3.0
const FRIO_QUE_MORDE := 0.85
const ELEMENTOS_FRIO: Array[StringName] = [&"gelo", &"frio"]
## Tremor: feitiços de terra têm 20% de chance de derrubar o alvo por 1 s.
const TREMOR_CHANCE := 0.2
const TREMOR_SEGUNDOS := 1.0
## Faísca: a luz do mago à noite (a normal é 0,35 de força e 0,6 de tamanho) e o raio em que
## ela afasta os slimes da noite.
const FAISCA_ENERGIA := 0.6
const FAISCA_TAMANHO := 1.0
const FAISCA_RAIO := 24.0
const LUZ_ENERGIA := 0.35
const LUZ_TAMANHO := 0.6


## Multiplicador do dano que `p` causa em `alvo` (antes de aplicar).
static func dano_causado(_p: Player, _quantidade: float, _tipo: StringName, _alvo: Node) -> float:
	return 1.0


## Depois que um golpe ou habilidade de `p` acertou `alvo` (o dano já foi aplicado).
static func acertou(p: Player, alvo: Node, _quantidade: float, tipo: StringName) -> void:
	if not is_instance_valid(alvo):
		return
	if tipo == &"fogo" and p.tem(&"combustao"):
		var dps := LogicasMago.queima_dps(p)
		EfeitosEstado.aplicar_em(alvo, EfeitosEstado.QUEIMADURA, COMBUSTAO_SEGUNDOS, dps, p)
		for e in Golpes.inimigos_em_volta(p, (alvo as Node2D).global_position, COMBUSTAO_COLADO):
			if e != alvo:
				EfeitosEstado.aplicar_em(e, EfeitosEstado.QUEIMADURA, COMBUSTAO_SEGUNDOS, dps, p)
	if tipo in ELEMENTOS_FRIO and p.tem(&"frio_que_morde"):
		EfeitosEstado.aplicar_em(alvo, EfeitosEstado.LENTIDAO, FRIO_SEGUNDOS, FRIO_LENTIDAO, p)
	if tipo == &"terra" and p.tem(&"tremor") and randf() < TREMOR_CHANCE:
		EfeitosEstado.aplicar_em(alvo, EfeitosEstado.DERRUBADO, TREMOR_SEGUNDOS, 0.0, p)


## Multiplicador do dano que `p` recebe.
static func dano_recebido(_p: Player, _quantidade: float, _tipo: StringName) -> float:
	return 1.0


## Frio que morde: inimigo com Lentidão posta por um mago com a passiva dá 15% menos dano.
static func ataque_inimigo(atacante: Node, _alvo: Node, _dano: float) -> float:
	var e := EfeitosEstado.de(atacante)
	if e == null or not e.tem(EfeitosEstado.LENTIDAO):
		return 1.0
	var mago := e.origem(EfeitosEstado.LENTIDAO) as Player
	return FRIO_QUE_MORDE if mago and mago.tem(&"frio_que_morde") else 1.0


## Cinzas: `p` derrotou `alvo` enquanto ele queimava: ele explode e queima quem está perto.
static func derrotou(p: Player, alvo: Node) -> void:
	if not p.tem(&"cinzas"):
		return
	var ef := EfeitosEstado.de(alvo)
	if ef == null or not ef.tem(EfeitosEstado.QUEIMADURA):
		return
	var onde := (alvo as Node2D).global_position
	World.efeito_todos(p, &"explosao", onde)
	var dano := CINZAS_DANO * p.ficha.multiplicador_magico()
	for e in Golpes.inimigos_em_volta(p, onde, CINZAS_RAIO):
		if e != alvo:
			Golpes.acertar(p, e, dano, &"fogo", EfeitosEstado.QUEIMADURA, LogicasMago.QUEIMA_SEGUNDOS, LogicasMago.queima_dps(p))


## Multiplicador de velocidade (roda no DONO).
static func velocidade(_p: Player) -> float:
	return 1.0


## Multiplicador da recarga da habilidade.
static func recarga(_p: Player, _hab: HabilidadeData) -> float:
	return 1.0


## Multiplicador do custo de mana da habilidade.
static func custo_mana(_p: Player, _hab: HabilidadeData) -> float:
	return 1.0


## Todo quadro, no anfitrião (auras, relógios).
static func processar(_p: Player, _delta: float) -> void:
	pass


## Passivas que valem o tempo todo (todas as máquinas, quando a árvore chega).
## Faísca: a luz do mago (que só acende à noite) fica maior e afasta os slimes da noite.
static func fixas(p: Player) -> void:
	var luz := p.get_node_or_null("Luz") as PointLight2D
	if p.tem(&"faisca"):
		if luz:
			luz.energy = FAISCA_ENERGIA
			luz.texture_scale = FAISCA_TAMANHO
		if not p.is_in_group(&"luz_protege"):
			p.set_meta(&"raio_luz", FAISCA_RAIO)
			p.add_to_group(&"luz_protege")
	elif luz and p.has_meta(&"faisca_luz"):
		luz.energy = LUZ_ENERGIA
		luz.texture_scale = LUZ_TAMANHO
	if p.tem(&"faisca"):
		p.set_meta(&"faisca_luz", true)
	elif p.has_meta(&"faisca_luz"):
		p.remove_meta(&"faisca_luz")
