class_name PassivasGuerreiro
extends RefCounted
## Passivas novas do Guerreiro (árvore de habilidades). Passivas.gd chama estas funções em todo
## jogador, de qualquer classe: cada uma confere `p.tem(&"<nó>")` antes de agir. As
## antigas continuam em passivas.gd. Devolva 1.0 (ou não faça nada) quando não valer.
## Roda no ANFITRIÃO, menos `velocidade`, que roda no dono (quem anda).
##
## Também guarda os efeitos que duram das supremas (Juramento, Fúria titânica), marcados no
## jogador com set_meta (só o anfitrião lê).

# --- Fôlego de batalha ----------------------------------------------------------------
const FOLEGO_ATORDOAR := 1.0
const FOLEGO_GASTO := 50.0  # metade da Fúria: o atordoar volta depois de uns 7 acertos

# --- Braço de lenhador ----------------------------------------------------------------
const LENHADOR_MADEIRA := 1.2  # cada árvore rende 20% mais madeira (arredondado para cima)

# --- Contra-golpe ---------------------------------------------------------------------
const CONTRA_GOLPE := 0.5  # do dano do atacante, de volta nele
const CONTRA_GOLPE_JANELA_MS := 600  # "instante certo": até 0,6 s depois de levantar o bloqueio
const META_BLOQUEIO := &"guerreiro_bloqueio_ms"

# --- Juramento ------------------------------------------------------------------------
const META_JURAMENTO := &"guerreiro_juramento_ate_ms"
const RAIO_JURAMENTO := 80.0
const JURAMENTO_PARTE := 0.5

# --- Fúria titânica -------------------------------------------------------------------
const META_TITANICA := &"guerreiro_titanica_ate_ms"
const TITANICA_RAIO := 28.0  # em volta do alvo
const TITANICA_DANO := 0.5  # do dano do golpe, nos vizinhos

static var _repassando := false  # Juramento: o dano repassado não se repassa de novo
static var _em_area := false  # Fúria titânica: o golpe em área não vira outro golpe em área


static func _ativo(p: Node, meta: StringName) -> bool:
	return p != null and is_instance_valid(p) and p.has_meta(meta) and Time.get_ticks_msec() < int(p.get_meta(meta))


static func juramento_ativo(p: Player) -> bool:
	return _ativo(p, META_JURAMENTO)


static func titanica_ativa(p: Player) -> bool:
	return _ativo(p, META_TITANICA)


## Multiplicador do dano que `p` causa em `alvo` (antes de aplicar).
static func dano_causado(_p: Player, _quantidade: float, _tipo: StringName, _alvo: Node) -> float:
	return 1.0


## Depois que um golpe ou habilidade de `p` acertou `alvo` (o dano já foi aplicado).
static func acertou(p: Player, alvo: Node, quantidade: float, tipo: StringName) -> void:
	var a := alvo as Node2D
	if a == null or not is_instance_valid(a):
		return
	# Fôlego de batalha: com a Fúria cheia, o golpe atordoa e gasta metade da Fúria.
	if p.tem(&"folego_de_batalha") and p.recursos.furia_cheia():
		if EfeitosEstado.aplicar_em(a, EfeitosEstado.ATORDOADO, FOLEGO_ATORDOAR, 0.0, p):
			p.recursos.gastar_furia(FOLEGO_GASTO)
			World.efeito_todos(p, &"raio", a.global_position)
	# Fúria titânica: o golpe físico também acerta quem está em volta do alvo.
	if not _em_area and tipo == &"fisico" and titanica_ativa(p):
		_em_area = true
		for e in Golpes.inimigos_em_volta(p, a.global_position, TITANICA_RAIO):
			if e != a:
				Golpes.acertar(p, e, quantidade * TITANICA_DANO, &"fisico")
		_em_area = false


## Multiplicador do dano que `p` recebe.
static func dano_recebido(p: Player, quantidade: float, _tipo: StringName) -> float:
	if quantidade <= 0.0:
		return 1.0
	var m := 1.0
	# Juramento (aliado perto): metade do dano vai para o guerreiro.
	if not _repassando:
		for o in Passivas.outros_jogadores(p, RAIO_JURAMENTO):
			if juramento_ativo(o) and o.vida.esta_vivo():
				_repassando = true
				o.vida.tomar_dano(quantidade * JURAMENTO_PARTE, _tipo)
				_repassando = false
				m *= 1.0 - JURAMENTO_PARTE
				break
	# Juramento (o próprio guerreiro): não cai abaixo de 1 de vida.
	if juramento_ativo(p):
		var limite := maxf(0.0, p.vida.atual - 1.0 + p.vida.escudo)
		if quantidade * m > limite:
			m = limite / quantidade
	return m


## Multiplicador do dano de um inimigo ou animal (`atacante`) em `alvo` (Ex.: Frio que morde).
## Contra-golpe: logo depois de levantar o bloqueio, metade do golpe volta no atacante.
static func ataque_inimigo(atacante: Node, alvo: Node, dano: float) -> float:
	var g := alvo as Player
	if g == null or not g.tem(&"contra_golpe") or not is_instance_valid(atacante) or not atacante is Node2D:
		return 1.0
	_marcar_bloqueio(g)
	if g.has_meta(META_BLOQUEIO) and Time.get_ticks_msec() - int(g.get_meta(META_BLOQUEIO)) <= CONTRA_GOLPE_JANELA_MS:
		Golpes.acertar(g, atacante as Node2D, dano * CONTRA_GOLPE, &"fisico", &"", 0.0, 0.0, &"giro")
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


## Todo quadro, no anfitrião (auras, relógios).
static func processar(p: Player, _delta: float) -> void:
	if p.tem(&"contra_golpe"):
		_marcar_bloqueio(p)


## Multiplicador do empurrão que `p` recebe (Fúria titânica: nenhum).
static func empurrao(p: Player) -> float:
	return 0.0 if titanica_ativa(p) else 1.0


## Quanto rende uma coleta (Braço de lenhador: +20% de madeira, arredondado para cima).
static func coleta(p: Player, item: StringName, quantidade: int) -> int:
	if item == &"madeira" and p != null and p.tem(&"braco_de_lenhador"):
		return ceili(quantidade * LENHADOR_MADEIRA - 0.001)
	return quantidade


## Contra-golpe: anota quando o bloqueio (redução de dano) começou; apaga quando acaba.
static func _marcar_bloqueio(p: Player) -> void:
	if p.vida.reducao_ativa():
		if not p.has_meta(META_BLOQUEIO):
			p.set_meta(META_BLOQUEIO, Time.get_ticks_msec())
	elif p.has_meta(META_BLOQUEIO):
		p.remove_meta(META_BLOQUEIO)
