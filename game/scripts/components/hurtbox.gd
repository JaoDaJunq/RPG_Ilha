class_name Hurtbox
extends Area2D
## Área que recebe acertos (golpe, bola de fogo...). Repassa para o dono pelo sinal.
## O dono decide o que cada tipo de dano faz: o slime perde vida, a árvore pega fogo.

signal atingido(quantidade: float, tipo: StringName, origem: Node)


func _ready() -> void:
	collision_layer = 1 << 4  # camada 5: "atingivel"
	collision_mask = 0
	monitoring = false


func receber(quantidade: float, tipo: StringName, origem: Node) -> void:
	atingido.emit(quantidade, tipo, origem)
