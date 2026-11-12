class_name EfeitosEstado
extends Node
## Estados de quem tem vida (slimes, animais e jogadores): Queimadura, Veneno, Lentidão,
## Congelado, Atordoado, Preso, Medo, Marcado, Derrubado, Cego, Provocado e Invisível.
## Fica como filho do dono, com o nome "EfeitosEstado".
##
## Rede: só o ANFITRIÃO aplica e tira estados (e dá o dano por segundo). A lista vai para
## todos por RPC: os outros usam para a cor e, no dono de um jogador, para andar (Lentidão,
## Preso...). Quem lê: `tem()`, `pode_mover()`, `pode_atacar()`, `mult_velocidade()`...
##
## Uso (anfitrião):  EfeitosEstado.aplicar_em(inimigo, EfeitosEstado.LENTIDAO, 3.0, 0.4, quem)

signal mudou

const QUEIMADURA := &"queimadura"  ## força = dano por segundo (fogo)
const VENENO := &"veneno"          ## força = dano por segundo por acúmulo
const LENTIDAO := &"lentidao"      ## força = fração da velocidade perdida (0,4 = 40% mais lento)
const CONGELADO := &"congelado"    ## não anda nem ataca
const ATORDOADO := &"atordoado"    ## não anda nem ataca
const PRESO := &"preso"            ## não anda (enraizado)
const MEDO := &"medo"              ## foge de quem aplicou e não ataca
const MARCADO := &"marcado"        ## força = dano a mais recebido (0,2 = +20%; 0 usa 0,2)
const DERRUBADO := &"derrubado"    ## desequilíbrio: não anda nem ataca
const CEGO := &"cego"              ## força = chance de errar o ataque (0 usa 1 = erra sempre)
const PROVOCADO := &"provocado"    ## persegue quem aplicou (a origem), mesmo um golem
const INVISIVEL := &"invisivel"    ## jogadores: os inimigos não veem
const TODOS: Array[StringName] = [QUEIMADURA, VENENO, LENTIDAO, CONGELADO, ATORDOADO, PRESO, MEDO, MARCADO, DERRUBADO, CEGO, PROVOCADO, INVISIVEL]
## Com tique de dano a cada segundo.
const COM_DANO: Array[StringName] = [QUEIMADURA, VENENO]
const MARCADO_PADRAO := 0.2

## Tom do desenho (modulate) de cada estado; vale o primeiro da lista PRIORIDADE.
const COR := {
	&"congelado": Color(0.6, 0.85, 1.0),
	&"atordoado": Color(1.0, 0.95, 0.55),
	&"derrubado": Color(0.85, 0.8, 0.65),
	&"preso": Color(0.8, 0.7, 0.5),
	&"queimadura": Color(1.0, 0.68, 0.45),
	&"veneno": Color(0.65, 1.0, 0.55),
	&"medo": Color(0.8, 0.65, 1.0),
	&"provocado": Color(1.0, 0.75, 0.6),
	&"cego": Color(0.62, 0.62, 0.66),
	&"marcado": Color(1.0, 0.6, 0.6),
	&"lentidao": Color(0.75, 0.85, 1.0),
}
const PRIORIDADE: Array[StringName] = [CONGELADO, ATORDOADO, DERRUBADO, PRESO, QUEIMADURA, VENENO, MEDO, PROVOCADO, CEGO, MARCADO, LENTIDAO]

## tipo → {t: segundos que faltam, f: força, n: acúmulos, o: origem (Node ou nulo),
##         k: tiques de dano que faltam, e: segundos até o próximo tique}
var _estados: Dictionary = {}
var _empurrao := Vector2.ZERO
var _empurrao_t := 0.0


## O componente de `alvo` (nulo se ele não tiver).
static func de(alvo: Node) -> EfeitosEstado:
	if alvo == null or not is_instance_valid(alvo):
		return null
	return alvo.get_node_or_null("EfeitosEstado") as EfeitosEstado


## Atalho do anfitrião: aplica em `alvo`, se ele tiver o componente. Devolve se aplicou.
static func aplicar_em(alvo: Node, tipo: StringName, segundos: float, forca := 0.0, origem: Node = null, max_acumulos := 1) -> bool:
	var e := de(alvo)
	if e == null:
		return false
	e.aplicar(tipo, segundos, forca, origem, max_acumulos)
	return true


# --- Anfitrião -------------------------------------------------------------------------

## Aplica o estado por `segundos` (o mais longo vale; a força mais alta vale). O Veneno
## acumula até `max_acumulos` (cada aplicação soma 1). Queimadura e Veneno: um tique de
## dano a cada segundo, `segundos` tiques ao todo (o primeiro depois de 1 s).
func aplicar(tipo: StringName, segundos: float, forca := 0.0, origem: Node = null, max_acumulos := 1) -> void:
	if not multiplayer.is_server() or not tipo in TODOS or segundos <= 0.0:
		return
	var vida := _vida()
	if vida and not vida.esta_vivo():
		return
	var e: Dictionary = _estados.get(tipo, {})
	if e.is_empty():
		e = {t = 0.0, f = 0.0, n = 0, o = null, k = 0, e = 1.0}
	e.t = maxf(e.t, segundos)
	e.f = maxf(e.f, forca)
	if tipo == VENENO:
		# Toxina: acumula até 5 (e outro envenenador não derruba os acúmulos que já tem).
		max_acumulos = maxi(maxi(max_acumulos, PassivasLadino.acumulos_veneno(origem)), int(e.n))
	e.n = mini(int(e.n) + 1, maxi(1, max_acumulos))
	if origem:
		e.o = origem
	if tipo in COM_DANO:
		# Golpe novo recomeça a contagem (como a Lâmina envenenada sempre fez).
		e.k = maxi(1, roundi(segundos))
		e.e = 1.0
		e.t = float(e.k)
	_estados[tipo] = e
	_enviar()


func remover(tipo: StringName) -> void:
	if not multiplayer.is_server() or not _estados.has(tipo):
		return
	_estados.erase(tipo)
	_enviar()


## Tira todos os estados ruins (fica só o Invisível). Ex.: Fonte da vida, Mãos que curam.
func limpar_ruins() -> void:
	if not multiplayer.is_server():
		return
	var tinha := _estados.size()
	for t in _estados.keys():
		if t != INVISIVEL:
			_estados.erase(t)
	if _estados.size() != tinha:
		_enviar()


## Empurra (ou puxa) o dono por `deslocamento` px em `duracao` s, respeitando paredes.
## Slimes e animais somam `impulso()` à velocidade; jogadores andam pelo mover_por_habilidade.
func empurrar(deslocamento: Vector2, duracao := 0.15) -> void:
	if not multiplayer.is_server():
		return
	var dono := get_parent()
	if dono is Player:
		(dono as Player).mover_por_habilidade(deslocamento, duracao)
		return
	duracao = maxf(duracao, 0.01)
	_empurrao = deslocamento / duracao
	_empurrao_t = duracao


# --- Leitura (qualquer máquina) --------------------------------------------------------

func tem(tipo: StringName) -> bool:
	return _estados.has(tipo)


func restante(tipo: StringName) -> float:
	return float(_estados[tipo].t) if _estados.has(tipo) else 0.0


func forca(tipo: StringName) -> float:
	return float(_estados[tipo].f) if _estados.has(tipo) else 0.0


func acumulos(tipo: StringName) -> int:
	return int(_estados[tipo].n) if _estados.has(tipo) else 0


## Quem aplicou (só no anfitrião; nulo se já sumiu).
func origem(tipo: StringName) -> Node:
	if not _estados.has(tipo):
		return null
	var o: Variant = _estados[tipo].o
	return o if o != null and is_instance_valid(o) else null


## Dano que o estado com tique ainda vai dar (Praga: tudo de uma vez).
func dano_restante(tipo: StringName) -> float:
	if not _estados.has(tipo) or not tipo in COM_DANO:
		return 0.0
	var e: Dictionary = _estados[tipo]
	return float(e.f) * int(e.n) * int(e.k)


func ativos() -> Array[StringName]:
	var l: Array[StringName] = []
	for t in _estados:
		l.append(t)
	return l


func pode_mover() -> bool:
	return not (tem(CONGELADO) or tem(ATORDOADO) or tem(PRESO) or tem(DERRUBADO))


func pode_atacar() -> bool:
	return not (tem(CONGELADO) or tem(ATORDOADO) or tem(DERRUBADO) or tem(MEDO))


## 0 sem poder andar; com Lentidão, 1 − força.
func mult_velocidade() -> float:
	if not pode_mover():
		return 0.0
	return clampf(1.0 - forca(LENTIDAO), 0.0, 1.0) if tem(LENTIDAO) else 1.0


## Marcado: quanto a mais o dono toma de dano (Hurtbox aplica para todo mundo).
func mult_dano_recebido() -> float:
	if not tem(MARCADO):
		return 1.0
	return 1.0 + (forca(MARCADO) if forca(MARCADO) > 0.0 else MARCADO_PADRAO)


## Cego: sorteia se este ataque erra (anfitrião, na hora do ataque).
func erra_ataque() -> bool:
	if not tem(CEGO):
		return false
	return randf() < (forca(CEGO) if forca(CEGO) > 0.0 else 1.0)


## Provocado: quem ele tem de perseguir (nulo se não está provocado ou o alvo sumiu).
func alvo_provocado() -> Node2D:
	return origem(PROVOCADO) as Node2D if tem(PROVOCADO) else null


## Medo: de onde fugir (Vector2.INF sem medo). Sem origem, foge do jogador mais perto.
func fugir_de() -> Vector2:
	if not tem(MEDO):
		return Vector2.INF
	var o := origem(MEDO) as Node2D
	if o:
		return o.global_position
	var dono := get_parent() as Node2D
	var melhor := Vector2.INF
	if dono:
		for j in get_tree().get_nodes_in_group(&"jogadores"):
			var p := (j as Node2D).global_position
			if melhor == Vector2.INF or p.distance_to(dono.global_position) < melhor.distance_to(dono.global_position):
				melhor = p
	return melhor


func invisivel() -> bool:
	return tem(INVISIVEL)


## Empurrão em andamento (px/s), para somar à velocidade do dono.
func impulso() -> Vector2:
	return _empurrao if _empurrao_t > 0.0 else Vector2.ZERO


## Tom do desenho pelo estado mais importante (branco sem estado).
func cor() -> Color:
	for t in PRIORIDADE:
		if _estados.has(t):
			return COR[t]
	return Color.WHITE


# --- Relógio ------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _empurrao_t > 0.0:
		_empurrao_t -= delta
	if _estados.is_empty():
		return
	var servidor := multiplayer.is_server()
	var mudou_algo := false
	for tipo in _estados.keys():
		var e: Dictionary = _estados[tipo]
		e.t = float(e.t) - delta
		if servidor and tipo in COM_DANO:
			e.e = float(e.e) - delta
			if e.e <= 0.0:
				e.e = float(e.e) + 1.0
				e.k = int(e.k) - 1
				_tique(tipo, float(e.f) * int(e.n), e.o)
				if not is_instance_valid(self) or not _estados.has(tipo):
					return  # o tique derrotou o dono (ou alguém limpou)
				if int(e.k) <= 0:
					_estados.erase(tipo)
					mudou_algo = true
			continue
		if float(e.t) <= 0.0:
			_estados.erase(tipo)
			mudou_algo = true
	if mudou_algo:
		if servidor:
			_enviar()
		else:
			mudou.emit()


## Um tique de Queimadura ou Veneno: passa pela Hurtbox (Marcado e Julgamento valem) sem
## repetir as passivas de quem aplicou; se derrotar, quem aplicou fica sabendo (Contágio, Sede).
func _tique(tipo: StringName, dano: float, quem: Variant) -> void:
	var dono := get_parent()
	var area := dono.get_node_or_null("Hurtbox") as Hurtbox
	var vida := _vida()
	if area == null or vida == null or dano <= 0.0:
		return
	var vivo := vida.esta_vivo()
	area.receber(dano, tipo, null)
	if vivo and not vida.esta_vivo() and quem != null and is_instance_valid(quem) and quem is Player:
		Passivas.derrotou(quem as Player, dono)


func _vida() -> HealthComponent:
	return get_parent().get_node_or_null("HealthComponent") as HealthComponent


func _enviar() -> void:
	mudou.emit()
	var dados := {}
	for t in _estados:
		dados[t] = [float(_estados[t].t), float(_estados[t].f), int(_estados[t].n)]
	if multiplayer.has_multiplayer_peer() and multiplayer.get_peers().size() > 0:
		_receber.rpc(dados)


@rpc("any_peer", "call_remote", "reliable")
func _receber(dados: Dictionary) -> void:
	if not Net.veio_do_anfitriao():
		return
	_estados.clear()
	for t in dados:
		var d: Array = dados[t]
		_estados[StringName(t)] = {t = d[0], f = d[1], n = d[2], o = null, k = 0, e = 1.0}
	mudou.emit()
