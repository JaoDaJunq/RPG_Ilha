class_name Nevoa
extends Node2D
## A névoa do Pântano: nuvens do pacote Tiny Swords, bem transparentes, por cima de tudo,
## indo e voltando devagar com o vento. À noite fica mais forte.

const AMPLITUDE := 10.0
const VELOCIDADE := 0.12

var _base: Dictionary = {}
var _tempo := 0.0


func _process(delta: float) -> void:
	_tempo += delta
	for s in get_children():
		var n := s as Node2D
		if not _base.has(n):
			_base[n] = n.position
		var b: Vector2 = _base[n]
		n.position = b + Vector2(sin(_tempo * VELOCIDADE + b.y * 0.01) * AMPLITUDE, 0)
