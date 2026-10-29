class_name Flammable
extends Node
## Faz algo pegar fogo, queimar por um tempo e terminar queimado.

signal acendeu
signal apagou_queimado

## Quanto tempo queima até virar "queimado".
@export var duracao := 3.0

var queimando := false
var queimado := false
var _restante := 0.0


func acender() -> bool:
	if queimando or queimado:
		return false
	queimando = true
	_restante = duracao
	acendeu.emit()
	return true


func _process(delta: float) -> void:
	if not queimando:
		return
	_restante -= delta
	if _restante <= 0.0:
		queimando = false
		queimado = true
		apagou_queimado.emit()
