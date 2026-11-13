class_name PassivasClerigo
extends RefCounted
## Passivas novas do Clérigo (árvore de habilidades). Passivas.gd chama estas funções em todo
## jogador, de qualquer classe: cada uma confere `p.tem(&"<nó>")` antes de agir. As
## antigas continuam em passivas.gd. Devolva 1.0 (ou não faça nada) quando não valer.
## Roda no ANFITRIÃO, menos `velocidade`, que roda no dono (quem anda).
##
## Também guarda o que as habilidades do Clérigo precisam lembrar de cada jogador:
##   - Elo vital: com quem está ligado e até quando (metas no jogador);
##   - Levantar: quando o jogador desmaiou pela última vez.

## Fogo sagrado: Queimadura no que a luz acerta (dano por segundo = esta fração do acerto).
const FOGO_SAGRADO_QUEIMA := 0.25
const FOGO_SAGRADO_SEGUNDOS := 3.0
## Elo vital: cada um toma esta fração do dano; o resto vai para o outro.
const ELO_FRACAO := 0.5
## Levantar: só vale para quem desmaiou há no máximo este tempo.
const LEVANTAR_MS := 60000
## Luz própria: a comida cura mais (quem come perto do Clérigo, ele incluso).
const LUZ_PROPRIA_COMIDA := 1.5
const LUZ_PROPRIA_COMIDA_RAIO := 56.0

static var _dividindo := false  # Elo vital: o dano repassado não volta (sem ping-pong)
static var _curando_elo := false


## Multiplicador do dano que `p` causa em `alvo` (antes de aplicar).
static func dano_causado(_p: Player, _quantidade: float, _tipo: StringName, _alvo: Node) -> float:
	return 1.0


## Depois que um golpe ou habilidade de `p` acertou `alvo` (o dano já foi aplicado).
static func acertou(p: Player, alvo: Node, quantidade: float, tipo: StringName) -> void:
	# Fogo sagrado: a luz deixa o alvo queimando.
	if tipo == &"luz" and p.tem(&"fogo_sagrado") and is_instance_valid(alvo):
		EfeitosEstado.aplicar_em(alvo, EfeitosEstado.QUEIMADURA, FOGO_SAGRADO_SEGUNDOS, maxf(0.1, quantidade * FOGO_SAGRADO_QUEIMA), p)


## Multiplicador do dano que `p` recebe. Elo vital: metade vai para o parceiro.
static func dano_recebido(p: Player, quantidade: float, tipo: StringName) -> float:
	var outro := elo_de(p)
	if outro == null or _dividindo or quantidade <= 0.0:
		return 1.0
	_dividindo = true
	outro.vida.tomar_dano(quantidade * (1.0 - ELO_FRACAO), tipo)
	_dividindo = false
	return ELO_FRACAO


## Multiplicador do dano de um inimigo ou animal (`atacante`) em `alvo` (Ex.: Frio que morde).
static func ataque_inimigo(_atacante: Node, _alvo: Node, _dano: float) -> float:
	return 1.0


## `p` derrotou `alvo`.
static func derrotou(_p: Player, _alvo: Node) -> void:
	pass


## Multiplicador de velocidade (roda no DONO).
static func velocidade(_p: Player) -> float:
	return 1.0


## Multiplicador da recarga da habilidade.
static func recarga(_p: Player, _hab: HabilidadeData) -> float:
	return 1.0


## Multiplicador do custo de mana da habilidade.
static func custo_mana(_p: Player, _hab: HabilidadeData) -> float:
	return 1.0


## Todo quadro, no anfitrião (auras, relógios). Aqui: passa a ouvir o desmaio de cada
## jogador (para o Levantar).
static func processar(p: Player, _delta: float) -> void:
	if not p.has_meta(&"ouve_desmaio"):
		p.set_meta(&"ouve_desmaio", true)
		p.vida.morreu.connect(func() -> void: p.set_meta(&"desmaiou_ms", Time.get_ticks_msec()))


# --- Curas (player.receber_cura chama, anfitrião) ----------------------------------------

## `alvo` acabou de receber `quantidade` de cura de `de` (já com as passivas).
##   - Mãos que curam: a cura também tira Veneno e Queimadura;
##   - Elo vital: a cura vale também para o parceiro.
static func curou(de: Player, alvo: Player, quantidade: float) -> void:
	if de and de.tem(&"maos_que_curam") and alvo.efeitos:
		alvo.efeitos.remover(EfeitosEstado.VENENO)
		alvo.efeitos.remover(EfeitosEstado.QUEIMADURA)
	var outro := elo_de(alvo)
	if outro and not _curando_elo and quantidade > 0.0:
		_curando_elo = true
		outro.vida.curar(quantidade)
		_curando_elo = false


## Luz própria: multiplicador da comida que `quem` dá a um aliado.
static func comida(quem: Player) -> float:
	return LUZ_PROPRIA_COMIDA if quem and quem.tem(&"luz_propria") else 1.0


## Dar comida (anfitrião; Player._pedir_usar com a vida cheia): a comida do espaço `espaco`
## vai para o aliado ferido mais perto (até LUZ_PROPRIA_COMIDA_RAIO). Qualquer um pode dar;
## com a Luz própria, cura 50% a mais. Devolve se deu.
static func dar_comida(quem: Player, espaco: int, dados: ItemData) -> bool:
	var melhor: Player = null
	for o in Passivas.outros_jogadores(quem, LUZ_PROPRIA_COMIDA_RAIO):
		if o.vida.esta_vivo() and o.vida.atual < o.vida.maximo \
				and (melhor == null or o.global_position.distance_to(quem.global_position) < melhor.global_position.distance_to(quem.global_position)):
			melhor = o
	if melhor == null:
		return false
	quem.inventario.gastar(espaco, 1)
	var cura := dados.cura * comida(quem)
	melhor.vida.curar(cura)
	World.efeito_todos(melhor, &"subir_nivel", melhor.global_position)
	quem.avisar("Deu %s para o aliado (+%d de vida)." % [dados.nome.to_lower(), int(cura)], &"item")
	melhor.avisar("Um aliado te deu %s: +%d de vida." % [dados.nome.to_lower(), int(cura)], &"item")
	return true


# --- Elo vital ----------------------------------------------------------------------------

static func ligar_elo(a: Player, b: Player, segundos: float) -> void:
	var ate := Time.get_ticks_msec() + int(segundos * 1000.0)
	a.set_meta(&"elo_com", b)
	a.set_meta(&"elo_ate_ms", ate)
	b.set_meta(&"elo_com", a)
	b.set_meta(&"elo_ate_ms", ate)


## O parceiro do Elo vital de `p` (nulo se não houver, se acabou ou se ele caiu).
static func elo_de(p: Player) -> Player:
	if p == null or not p.has_meta(&"elo_com"):
		return null
	var o: Variant = p.get_meta(&"elo_com")
	if Time.get_ticks_msec() > int(p.get_meta(&"elo_ate_ms", 0)) or o == null or not is_instance_valid(o):
		p.remove_meta(&"elo_com")
		return null
	var outro := o as Player
	return outro if outro.vida.esta_vivo() else null


# --- Levantar -----------------------------------------------------------------------------

## O aliado (não `quem`) que desmaiou por último, há no máximo um minuto. Nulo se nenhum.
static func ultimo_caido(quem: Player) -> Player:
	var melhor: Player = null
	var quando := Time.get_ticks_msec() - LEVANTAR_MS
	for n in quem.get_tree().get_nodes_in_group(&"jogadores"):
		var o := n as Player
		if o and o != quem and not o.criando and o.has_meta(&"desmaiou_ms") and int(o.get_meta(&"desmaiou_ms")) >= quando:
			quando = int(o.get_meta(&"desmaiou_ms"))
			melhor = o
	return melhor


static func esquecer_queda(p: Player) -> void:
	p.remove_meta(&"desmaiou_ms")
