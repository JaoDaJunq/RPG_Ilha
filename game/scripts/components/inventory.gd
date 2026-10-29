class_name Inventory
extends Node
## Inventário simples: quantidade por item. Slots e empilhamento vêm na T20.
## Quem manda é o anfitrião: ele altera e manda a lista para o dono do jogador.

signal mudou

var _itens: Dictionary[StringName, int] = {}


## Só o anfitrião chama.
func adicionar(item_id: StringName, quantidade: int) -> void:
	if quantidade <= 0:
		return
	_itens[item_id] = quantidade_de(item_id) + quantidade
	_enviar()
	Events.item_coletado.emit(item_id, quantidade, get_parent())


## Só o anfitrião chama.
func remover(item_id: StringName, quantidade: int) -> bool:
	if quantidade_de(item_id) < quantidade:
		return false
	_itens[item_id] -= quantidade
	_enviar()
	return true


## Só o anfitrião chama (ao carregar o mundo salvo).
func definir(itens_salvos: Dictionary) -> void:
	_itens.clear()
	for k in itens_salvos:
		if int(itens_salvos[k]) > 0:
			_itens[StringName(k)] = int(itens_salvos[k])
	_enviar()


## O anfitrião manda o inventário para o dono (quando ele acaba de chegar).
func reenviar() -> void:
	_enviar()


func quantidade_de(item_id: StringName) -> int:
	return _itens.get(item_id, 0)


func itens() -> Dictionary[StringName, int]:
	return _itens.duplicate()


func _enviar() -> void:
	mudou.emit()
	var dono := get_parent().get_multiplayer_authority()
	if dono != multiplayer.get_unique_id():
		_receber.rpc_id(dono, _itens)


@rpc("any_peer", "reliable")
func _receber(itens_do_anfitriao: Dictionary) -> void:
	if not Net.veio_do_anfitriao():
		return
	_itens.clear()
	for k in itens_do_anfitriao:
		_itens[StringName(k)] = int(itens_do_anfitriao[k])
	mudou.emit()
