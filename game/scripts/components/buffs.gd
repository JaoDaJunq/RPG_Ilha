class_name Buffs
extends Node
## Buffs temporários de um jogador (auras, estandartes, gritos): mais dano, mais
## velocidade, menos dano recebido, regeneração e escudo. Fica como filho do Player com o
## nome "Buffs" (o Player cria).
##
## Rede: só o ANFITRIÃO dá buffs; a lista vai para todos por RPC (o dono precisa da
## velocidade, que é ele quem anda). Onde cada um vale:
##   DANO        → Passivas.dano_causado (multiplicador: 0,15 = +15%)
##   VELOCIDADE  → Passivas.velocidade (0,1 = +10%)
##   REDUCAO     → Passivas.dano_recebido (0,3 = 30% menos dano)
##   REGENERACAO → vida por segundo, curada aqui (anfitrião)
##   ESCUDO      → na hora, vira escudo da vida (HealthComponent.dar_escudo) pelos segundos
##
## Uso (anfitrião):  p.buffs.dar(Buffs.DANO, 0.15, 6.0, quem)
## Vários buffs do mesmo tipo: vale o mais forte; a duração é a mais longa entre os iguais.

signal mudou

const DANO := &"dano"
const VELOCIDADE := &"velocidade"
const REDUCAO := &"reducao"
const REGENERACAO := &"regeneracao"
const ESCUDO := &"escudo"
const TIPOS: Array[StringName] = [DANO, VELOCIDADE, REDUCAO, REGENERACAO, ESCUDO]

var _buffs: Dictionary = {}  # tipo → {v: valor, t: segundos que faltam, de: Player ou nulo}
var _regen := 0.0


## Anfitrião: dá o buff `tipo` de força `valor` por `segundos`. `de`: quem deu (a cura da
## regeneração passa pelas passivas de cura dele).
func dar(tipo: StringName, valor: float, segundos: float, de: Player = null) -> void:
	if not multiplayer.is_server() or not tipo in TIPOS or segundos <= 0.0:
		return
	if tipo == ESCUDO:
		var vida := _vida()
		if vida:
			vida.dar_escudo(valor, segundos)
		return
	var b: Dictionary = _buffs.get(tipo, {v = 0.0, t = 0.0, de = null})
	if valor >= float(b.v):
		b.v = valor
		b.de = de
	b.t = maxf(float(b.t), segundos)
	_buffs[tipo] = b
	_enviar()


func tirar(tipo: StringName) -> void:
	if multiplayer.is_server() and _buffs.erase(tipo):
		_enviar()


func tem(tipo: StringName) -> bool:
	return _buffs.has(tipo)


## A força do buff (0 sem ele).
func valor(tipo: StringName) -> float:
	return float(_buffs[tipo].v) if _buffs.has(tipo) else 0.0


## 1 + força (para multiplicar): DANO 0,15 → 1,15.
func mult(tipo: StringName) -> float:
	return 1.0 + valor(tipo)


func restante(tipo: StringName) -> float:
	return float(_buffs[tipo].t) if _buffs.has(tipo) else 0.0


func _physics_process(delta: float) -> void:
	if _buffs.is_empty():
		return
	var servidor := multiplayer.is_server()
	if servidor and _buffs.has(REGENERACAO):
		_regen += delta
		if _regen >= 1.0:
			_regen -= 1.0
			var dono := get_parent() as Player
			var vida := _vida()
			if dono and vida and vida.esta_vivo() and vida.atual < vida.maximo:
				var de: Variant = _buffs[REGENERACAO].de
				dono.receber_cura(de if de != null and is_instance_valid(de) else null, valor(REGENERACAO))
	var acabou := false
	for t in _buffs.keys():
		_buffs[t].t = float(_buffs[t].t) - delta
		if float(_buffs[t].t) <= 0.0:
			_buffs.erase(t)
			acabou = true
	if acabou:
		if not _buffs.has(REGENERACAO):
			_regen = 0.0
		if servidor:
			_enviar()
		else:
			mudou.emit()


func _vida() -> HealthComponent:
	return get_parent().get_node_or_null("HealthComponent") as HealthComponent


func _enviar() -> void:
	mudou.emit()
	var dados := {}
	for t in _buffs:
		dados[t] = [float(_buffs[t].v), float(_buffs[t].t)]
	if multiplayer.has_multiplayer_peer() and multiplayer.get_peers().size() > 0:
		_receber.rpc(dados)


@rpc("any_peer", "call_remote", "reliable")
func _receber(dados: Dictionary) -> void:
	if not Net.veio_do_anfitriao():
		return
	_buffs.clear()
	for t in dados:
		_buffs[StringName(t)] = {v = dados[t][0], t = dados[t][1], de = null}
	mudou.emit()
