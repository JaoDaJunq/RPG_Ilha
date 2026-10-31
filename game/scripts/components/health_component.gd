class_name HealthComponent
extends Node
## Vida de qualquer coisa que pode tomar dano.

signal mudou(atual: float, maximo: float)
signal dano_recebido(quantidade: float, tipo: StringName)
signal morreu

@export var maximo := 100.0
## Tempo sem tomar dano depois de um acerto (0 = sem proteção).
@export var invulneravel_por := 0.0

var atual: float
var _protecao := 0.0


func _ready() -> void:
	atual = maximo


func _process(delta: float) -> void:
	_protecao = maxf(0.0, _protecao - delta)


func esta_vivo() -> bool:
	return atual > 0.0


func protegido() -> bool:
	return _protecao > 0.0


func tomar_dano(quantidade: float, tipo: StringName = &"fisico") -> bool:
	if not esta_vivo() or protegido() or quantidade <= 0.0:
		return false
	atual = maxf(0.0, atual - quantidade)
	_protecao = invulneravel_por
	dano_recebido.emit(quantidade, tipo)
	mudou.emit(atual, maximo)
	if atual <= 0.0:
		morreu.emit()
	return true


## Fica sem tomar dano por alguns segundos (esquiva).
func proteger(segundos: float) -> void:
	_protecao = maxf(_protecao, segundos)


func curar(quantidade: float) -> void:
	atual = minf(maximo, atual + quantidade)
	mudou.emit(atual, maximo)


func curar_tudo() -> void:
	atual = maximo
	_protecao = 0.0
	mudou.emit(atual, maximo)
