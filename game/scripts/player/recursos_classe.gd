class_name RecursosClasse
extends Node
## Recursos de classe: a barra de FÚRIA do Guerreiro (0 a 100; enche ao bater e ao apanhar)
## e os PONTOS DE COMBO do Ladino (0 a 5; cada acerto dá 1; os finalizadores gastam).
## Fica como filho do Player com o nome "Recursos" (o Player cria).
##
## Rede: só o ANFITRIÃO muda os valores; o dono recebe por RPC (o HUD mostra a barra).
## Uso nas lógicas (anfitrião):
##   if quem.recursos.furia_cheia(): ...        quem.recursos.gastar_furia(50.0)
##   var pontos := quem.recursos.gastar_combo()  # devolve quantos tinha e zera

signal mudou

const FURIA_MAXIMA := 100.0
const FURIA_POR_ACERTO := 8.0
const FURIA_POR_DANO := 1.5  # por ponto de vida perdido
const FURIA_DESCANSO := 6.0  # segundos sem lutar até a Fúria começar a baixar
const FURIA_QUEDA := 10.0  # por segundo, fora de luta
const COMBO_MAXIMO := 5
const COMBO_INTERVALO_MS := 150  # um ponto por golpe (o leque de adagas não dá 3 de uma vez)
const COMBO_DURA := 10.0  # segundos sem acertar até perder os pontos

var furia := 0.0
var combo := 0
var _sem_lutar := 0.0
var _ultimo_combo_ms := -100000
var _enviado := Vector2(-1, -1)


func _ready() -> void:
	if multiplayer.is_server():
		var vida := get_parent().get_node_or_null("HealthComponent") as HealthComponent
		if vida:
			vida.dano_recebido.connect(func(qtd: float, _t: StringName) -> void: ao_apanhar(qtd))


func _classe() -> StringName:
	var p := get_parent() as Player
	return p.classe if p else &""


## Este jogador usa a Fúria (Guerreiro)?
func usa_furia() -> bool:
	return _classe() == &"guerreiro"


## Este jogador usa pontos de combo (Ladino)?
func usa_combo() -> bool:
	return _classe() == &"ladino"


func furia_cheia() -> bool:
	return furia >= FURIA_MAXIMA


# --- Anfitrião ------------------------------------------------------------------------

## Um golpe ou habilidade deste jogador acertou (chamado por Passivas.acertou).
func ao_acertar(_alvo: Node, _quantidade: float, _tipo: StringName) -> void:
	if usa_furia():
		ganhar_furia(FURIA_POR_ACERTO)
	if usa_combo():
		var agora := Time.get_ticks_msec()
		if agora - _ultimo_combo_ms >= COMBO_INTERVALO_MS:
			_ultimo_combo_ms = agora
			ganhar_combo(1)


func ao_apanhar(quantidade: float) -> void:
	if usa_furia():
		ganhar_furia(quantidade * FURIA_POR_DANO)


func ganhar_furia(quantidade: float) -> void:
	if not multiplayer.is_server():
		return
	_sem_lutar = 0.0
	furia = clampf(furia + quantidade, 0.0, FURIA_MAXIMA)
	_enviar()


## Gasta `quantidade` de Fúria, se tiver. Devolve se gastou.
func gastar_furia(quantidade: float) -> bool:
	if not multiplayer.is_server() or furia < quantidade:
		return false
	furia -= quantidade
	_enviar()
	return true


func ganhar_combo(pontos := 1) -> void:
	if not multiplayer.is_server():
		return
	_sem_lutar = 0.0
	combo = clampi(combo + pontos, 0, COMBO_MAXIMO)
	_enviar()


## Finalizador: devolve os pontos de combo que havia (0 a 5) e zera.
func gastar_combo() -> int:
	if not multiplayer.is_server():
		return 0
	var n := combo
	combo = 0
	_enviar()
	return n


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or (furia <= 0.0 and combo <= 0):
		return
	_sem_lutar += delta
	if furia > 0.0 and _sem_lutar >= FURIA_DESCANSO:
		furia = maxf(0.0, furia - FURIA_QUEDA * delta)
		_enviar()
	if combo > 0 and _sem_lutar >= COMBO_DURA:
		combo = 0
		_enviar()


func _enviar() -> void:
	mudou.emit()
	var agora := Vector2(roundf(furia), combo)
	if agora == _enviado:
		return
	_enviado = agora
	var p := get_parent() as Player
	if p and not p.eh_local():
		_receber.rpc_id(p.id_rede(), furia, combo)


@rpc("any_peer", "reliable")
func _receber(f: float, c: int) -> void:
	if Net.veio_do_anfitriao():
		furia = f
		combo = c
		mudou.emit()
