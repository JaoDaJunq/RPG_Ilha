class_name Inventory
extends Node
## Inventário estilo Minecraft. Espaços, cada um com um item e a quantidade:
##   0 a 8    barra (teclas 1-9; o item escolhido fica na mão)
##   9 a 35   mochila
##   36 a 44  grade de fabricação 3x3 (na mochila só a 2x2 de cima à esquerda vale;
##            a 3x3 inteira só na bancada)
##   45       mão: o item que o mouse está segurando na tela da mochila
## Quem manda é o anfitrião: o dono PEDE cada clique, o anfitrião aplica e manda a lista
## inteira de volta (pedido_clique, pedido_resultado, pedido_fechar).

signal mudou

const BARRA := 9
const MOCHILA := 27
const GUARDAR := BARRA + MOCHILA  # 36 espaços de guardar
const GRADE := GUARDAR  # primeiro espaço da grade 3x3
const MAO := GUARDAR + 9
const ESPACOS := MAO + 1
## Na mochila, a grade 2x2 são estes espaços da 3x3.
const GRADE_2X2: Array[int] = [GRADE, GRADE + 1, GRADE + 3, GRADE + 4]

var _ids: Array[StringName] = []
var _qtds: PackedInt32Array = PackedInt32Array()
## Grade 3x3 liberada (o dono está na bancada).
var na_bancada := false


func _init() -> void:
	_ids.resize(ESPACOS)
	_ids.fill(&"")
	_qtds.resize(ESPACOS)


# --- Leitura (anfitrião e dono) ----------------------------------------------------

func item_em(i: int) -> StringName:
	return _ids[i]


func qtd_em(i: int) -> int:
	return _qtds[i]


func quantidade_de(item_id: StringName) -> int:
	var n := 0
	for i in GUARDAR:
		if _ids[i] == item_id:
			n += _qtds[i]
	return n


## Total de cada item guardado (barra + mochila).
func itens() -> Dictionary[StringName, int]:
	var d: Dictionary[StringName, int] = {}
	for i in GUARDAR:
		if _ids[i] != &"":
			d[_ids[i]] = d.get(_ids[i], 0) + _qtds[i]
	return d


## A receita que a grade forma agora (2x2 na mochila, 3x3 na bancada), ou null.
func receita_atual() -> ReceitaData:
	var lado := 3 if na_bancada else 2
	var grade: Array[StringName] = []
	if na_bancada:
		for k in 9:
			grade.append(_ids[GRADE + k])
	else:
		for k in GRADE_2X2:
			grade.append(_ids[k])
	return ReceitaData.encontrar(grade, lado)


# --- Mudanças (só o anfitrião) -------------------------------------------------------

## Guarda o item: primeiro completa pilhas iguais, depois ocupa espaços vazios (a barra
## antes da mochila, como no Minecraft). Retorna o que não coube.
func adicionar(item_id: StringName, quantidade: int) -> int:
	if quantidade <= 0:
		return 0
	var sobra := _guardar(item_id, quantidade, 0, GUARDAR)
	if quantidade - sobra > 0:
		Events.item_coletado.emit(item_id, quantidade - sobra, get_parent())
	_enviar()
	return sobra


func remover(item_id: StringName, quantidade: int) -> bool:
	if quantidade_de(item_id) < quantidade:
		return false
	for i in range(GUARDAR - 1, -1, -1):
		if quantidade <= 0:
			break
		if _ids[i] == item_id:
			var tira := mini(_qtds[i], quantidade)
			_tirar(i, tira)
			quantidade -= tira
	_enviar()
	return true


## Carrega o que foi salvo: a lista de espaços [[id, qtd], ...] ou o formato antigo
## {item: quantidade}.
func definir(salvo: Variant) -> void:
	_ids.fill(&"")
	_qtds.fill(0)
	if salvo is Dictionary:
		for k in salvo:
			_guardar(StringName(k), int(salvo[k]), 0, GUARDAR)
	elif salvo is Array:
		for i in mini(salvo.size(), ESPACOS):
			var e: Array = salvo[i]
			if e.size() == 2 and ItemData.existe(StringName(e[0])) and int(e[1]) > 0:
				_ids[i] = StringName(e[0])
				_qtds[i] = int(e[1])
	_enviar()


func para_salvar() -> Array:
	var lista := []
	for i in ESPACOS:
		lista.append([String(_ids[i]), _qtds[i]])
	return lista


## O anfitrião manda o inventário para o dono (quando ele acaba de chegar).
func reenviar() -> void:
	_enviar()


# --- Pedidos do dono (cliques na tela da mochila) ------------------------------------

func pedir_clique(espaco: int, direito := false, rapido := false) -> void:
	_pedido_clique.rpc_id(1, espaco, direito, rapido)


func pedir_resultado(rapido := false) -> void:
	_pedido_resultado.rpc_id(1, rapido)


## Fecha a tela: o que estava na grade e na mão volta para a mochila.
func pedir_fechar() -> void:
	_pedido_fechar.rpc_id(1)


func pedir_bancada(ligada: bool) -> void:
	_pedido_bancada.rpc_id(1, ligada)


@rpc("any_peer", "call_local", "reliable")
func _pedido_clique(espaco: int, direito: bool, rapido: bool) -> void:
	if not _pedido_do_dono() or espaco < 0 or espaco >= MAO:
		return
	if not na_bancada and espaco >= GRADE and not espaco in GRADE_2X2:
		return
	if rapido:
		_mover_rapido(espaco)
	elif direito:
		_clique_direito(espaco)
	else:
		_clique_esquerdo(espaco)
	_enviar()


@rpc("any_peer", "call_local", "reliable")
func _pedido_resultado(rapido: bool) -> void:
	if not _pedido_do_dono():
		return
	var feitos := 0
	while feitos < 64:
		var r := receita_atual()
		if r == null:
			break
		var dados := ItemData.carregar(r.resultado)
		if rapido:
			if _cabe(r.resultado, r.quantidade, 0, GUARDAR) < r.quantidade:
				break
			_consumir_grade()
			_guardar(r.resultado, r.quantidade, 0, GUARDAR)
		else:
			if _ids[MAO] != &"" and (_ids[MAO] != r.resultado or _qtds[MAO] + r.quantidade > dados.pilha):
				break
			_consumir_grade()
			_ids[MAO] = r.resultado
			_qtds[MAO] += r.quantidade
		Events.item_fabricado.emit(r.resultado, r.quantidade, get_parent())
		feitos += 1
		if not rapido:
			break
	_enviar()


@rpc("any_peer", "call_local", "reliable")
func _pedido_fechar() -> void:
	if not _pedido_do_dono():
		return
	for i in range(GRADE, ESPACOS):
		if _ids[i] != &"":
			var sobra := _guardar(_ids[i], _qtds[i], 0, GUARDAR)
			if sobra > 0:
				continue  # não coube: fica onde está (nada se perde)
			_ids[i] = &""
			_qtds[i] = 0
	na_bancada = false
	_enviar()


@rpc("any_peer", "call_local", "reliable")
func _pedido_bancada(ligada: bool) -> void:
	if not _pedido_do_dono():
		return
	na_bancada = ligada and _perto_de_bancada()
	_enviar()


func _pedido_do_dono() -> bool:
	if not multiplayer.is_server():
		return false
	var quem := multiplayer.get_remote_sender_id()
	return (1 if quem == 0 else quem) == get_parent().get_multiplayer_authority()


func _perto_de_bancada() -> bool:
	var corpo := get_parent() as Node2D
	for b in get_tree().get_nodes_in_group(&"bancadas"):
		if (b as Node2D).global_position.distance_to(corpo.global_position) < 48.0:
			return true
	return false


# --- Regras do clique (iguais às do Minecraft) ------------------------------------

func _clique_esquerdo(i: int) -> void:
	if _ids[MAO] == &"":
		_trocar(i, MAO)
	elif _ids[i] == &"":
		_trocar(i, MAO)
	elif _ids[i] == _ids[MAO]:
		var passa := mini(_qtds[MAO], _pilha(i) - _qtds[i])
		_qtds[i] += passa
		_tirar(MAO, passa)
	else:
		_trocar(i, MAO)


func _clique_direito(i: int) -> void:
	if _ids[MAO] == &"":
		if _ids[i] != &"":
			var metade := ceili(_qtds[i] / 2.0)
			_ids[MAO] = _ids[i]
			_qtds[MAO] = metade
			_tirar(i, metade)
	elif _ids[i] == &"" or (_ids[i] == _ids[MAO] and _qtds[i] < _pilha(i)):
		_ids[i] = _ids[MAO]
		_qtds[i] += 1
		_tirar(MAO, 1)


## Shift + clique: da barra para a mochila, da mochila para a barra, da grade para guardar.
func _mover_rapido(i: int) -> void:
	if _ids[i] == &"":
		return
	var de := 0
	var ate := GUARDAR
	if i < BARRA:
		de = BARRA
	elif i < GUARDAR:
		ate = BARRA
	var sobra := _guardar(_ids[i], _qtds[i], de, ate)
	if sobra == 0:
		_ids[i] = &""
	_qtds[i] = sobra


func _consumir_grade() -> void:
	var espacos: Array[int] = []
	if na_bancada:
		for k in 9:
			espacos.append(GRADE + k)
	else:
		espacos = GRADE_2X2
	for k in espacos:
		if _ids[k] != &"":
			_tirar(k, 1)


## Guarda nos espaços [de, ate): completa pilhas iguais, depois ocupa vazios. Retorna a sobra.
func _guardar(item_id: StringName, quantidade: int, de: int, ate: int) -> int:
	if not ItemData.existe(item_id):
		return quantidade
	var pilha := ItemData.carregar(item_id).pilha
	for i in range(de, ate):
		if quantidade <= 0:
			break
		if _ids[i] == item_id and _qtds[i] < pilha:
			var passa := mini(quantidade, pilha - _qtds[i])
			_qtds[i] += passa
			quantidade -= passa
	for i in range(de, ate):
		if quantidade <= 0:
			break
		if _ids[i] == &"":
			var passa := mini(quantidade, pilha)
			_ids[i] = item_id
			_qtds[i] = passa
			quantidade -= passa
	return quantidade


## Quanto desse item cabe nos espaços [de, ate).
func _cabe(item_id: StringName, quantidade: int, de: int, ate: int) -> int:
	var pilha := ItemData.carregar(item_id).pilha
	var cabe := 0
	for i in range(de, ate):
		if _ids[i] == item_id:
			cabe += pilha - _qtds[i]
		elif _ids[i] == &"":
			cabe += pilha
	return mini(cabe, quantidade)


func _pilha(i: int) -> int:
	return ItemData.carregar(_ids[i]).pilha if _ids[i] != &"" else 64


func _tirar(i: int, quantidade: int) -> void:
	_qtds[i] -= quantidade
	if _qtds[i] <= 0:
		_qtds[i] = 0
		_ids[i] = &""


func _trocar(a: int, b: int) -> void:
	var id := _ids[a]
	var q := _qtds[a]
	_ids[a] = _ids[b]
	_qtds[a] = _qtds[b]
	_ids[b] = id
	_qtds[b] = q


func _enviar() -> void:
	mudou.emit()
	if not multiplayer.has_multiplayer_peer():
		return
	var dono := get_parent().get_multiplayer_authority()
	if dono != multiplayer.get_unique_id():
		_receber.rpc_id(dono, _ids, _qtds, na_bancada)


@rpc("any_peer", "reliable")
func _receber(ids: Array, qtds: PackedInt32Array, bancada: bool) -> void:
	if not Net.veio_do_anfitriao():
		return
	for i in mini(ids.size(), ESPACOS):
		_ids[i] = StringName(ids[i])
	_qtds = qtds
	na_bancada = bancada
	mudou.emit()


## Gasta do espaço `i` (o anfitrião, ao pôr uma construção da mão).
func gastar(i: int, quantidade: int) -> void:
	_tirar(i, quantidade)
	_enviar()
