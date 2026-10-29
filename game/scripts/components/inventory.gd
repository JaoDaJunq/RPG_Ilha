class_name Inventory
extends Node
## Inventário simples: quantidade por item. Slots e empilhamento vêm na T20.

signal mudou

var _itens: Dictionary[StringName, int] = {}


func adicionar(item_id: StringName, quantidade: int) -> void:
	if quantidade <= 0:
		return
	_itens[item_id] = quantidade_de(item_id) + quantidade
	mudou.emit()
	Events.item_coletado.emit(item_id, quantidade, get_parent())


func remover(item_id: StringName, quantidade: int) -> bool:
	if quantidade_de(item_id) < quantidade:
		return false
	_itens[item_id] -= quantidade
	mudou.emit()
	return true


func quantidade_de(item_id: StringName) -> int:
	return _itens.get(item_id, 0)


func itens() -> Dictionary[StringName, int]:
	return _itens.duplicate()
