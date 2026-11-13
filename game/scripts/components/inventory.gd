class_name Inventory
extends Node
## Inventário estilo Minecraft. Espaços, cada um com um item e a quantidade:
##   0 a 8    barra (teclas 1-9; o item escolhido fica na mão)
##   9 a 35   mochila
##   36 a 44  grade de fabricação 3x3 (na mochila só a 2x2 de cima à esquerda vale;
##            a 3x3 inteira só na bancada)
##   45       mão: o item que o mouse está segurando na tela da mochila
##   46 a 72  o baú aberto (cópia do conteúdo do baú; o anfitrião grava de volta no baú)
##   73, 74   espaço antigo de cabeça e roupa do corpo. Cabeça fica reservado para saves
##            antigos; só o corpo aceita roupa nova.
## Quem manda é o anfitrião: o dono PEDE cada clique, o anfitrião aplica e manda a lista
## inteira de volta (pedido_clique, pedido_resultado, pedido_fechar).

signal mudou

const BARRA := 9
const MOCHILA := 27
const GUARDAR := BARRA + MOCHILA  # 36 espaços de guardar
const GRADE := GUARDAR  # primeiro espaço da grade 3x3
const MAO := GUARDAR + 9
const BAU := MAO + 1
const BAU_N := 27
const EQUIP_CABECA := BAU + BAU_N
const EQUIP_CORPO := EQUIP_CABECA + 1
const ESPACOS := EQUIP_CORPO + 1
## Espaço de roupa → o `equipa` que ele aceita.
const EQUIPAMENTO := {EQUIP_CORPO: &"corpo"}
## Na mochila, a grade 2x2 são estes espaços da 3x3.
const GRADE_2X2: Array[int] = [GRADE, GRADE + 1, GRADE + 3, GRADE + 4]

var _ids: Array[StringName] = []
var _qtds: PackedInt32Array = PackedInt32Array()
## Grade 3x3 liberada (o dono está na bancada).
var na_bancada := false
## Baú aberto (o dono vê os espaços 46-72). No anfitrião, `bau_aberto` é o nó do baú.
var com_bau := false
var bau_aberto: Node
## Itens que faltavam na receita escolhida; usados só como sombras pela interface.
var sombras_receita: Dictionary[int, StringName] = {}


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
		for i in mini(salvo.size(), MAO + 1):
			_carregar_espaco(i, salvo[i])
		# Depois da mão vêm as duas roupas vestidas (o baú aberto fica no baú, não aqui).
		if salvo.size() >= MAO + 3:
			_carregar_espaco(EQUIP_CABECA, salvo[MAO + 1])
			_carregar_espaco(EQUIP_CORPO, salvo[MAO + 2])
		# Chapéus antigos deixam de ser equipamento visual. Tenta devolvê-los à mochila.
		if _ids[EQUIP_CABECA] != &"":
			var id_antigo := _ids[EQUIP_CABECA]
			var qtd_antiga := _qtds[EQUIP_CABECA]
			if _guardar(id_antigo, qtd_antiga, 0, GUARDAR) == 0:
				_ids[EQUIP_CABECA] = &""
				_qtds[EQUIP_CABECA] = 0
	_enviar()


func _carregar_espaco(i: int, e: Array) -> void:
	if e.size() != 2 or not ItemData.existe(StringName(e[0])) or int(e[1]) <= 0:
		return
	if EQUIPAMENTO.has(i) and ItemData.carregar(StringName(e[0])).equipa != EQUIPAMENTO[i]:
		return
	_ids[i] = StringName(e[0])
	_qtds[i] = int(e[1])


func para_salvar() -> Array:
	var lista := []
	for i in MAO + 1:  # o baú aberto fica no baú, não no jogador
		lista.append([String(_ids[i]), _qtds[i]])
	lista.append([String(_ids[EQUIP_CABECA]), _qtds[EQUIP_CABECA]])
	lista.append([String(_ids[EQUIP_CORPO]), _qtds[EQUIP_CORPO]])
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


func pedir_receita(resultado: StringName) -> void:
	_pedido_receita.rpc_id(1, resultado)


func pedir_bancada(ligada: bool) -> void:
	_pedido_bancada.rpc_id(1, ligada)


@rpc("any_peer", "call_local", "reliable")
func _pedido_clique(espaco: int, direito: bool, rapido: bool) -> void:
	if not _pedido_do_dono() or espaco < 0 or espaco >= ESPACOS or espaco == MAO:
		return
	if espaco >= BAU and espaco < BAU + BAU_N and not is_instance_valid(bau_aberto):
		return
	if not na_bancada and espaco >= GRADE and espaco < MAO and not espaco in GRADE_2X2:
		return
	if EQUIPAMENTO.has(espaco):
		_clique_roupa(espaco, rapido)
	elif rapido:
		_mover_rapido(espaco)
	elif direito:
		_clique_direito(espaco)
	else:
		_clique_esquerdo(espaco)
	if espaco >= GRADE and espaco < MAO and _ids[espaco] != &"":
		sombras_receita.erase(espaco)
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
			_consumir_grade(r)
			_guardar(r.resultado, r.quantidade, 0, GUARDAR)
		else:
			if _ids[MAO] != &"" and (_ids[MAO] != r.resultado or _qtds[MAO] + r.quantidade > dados.pilha):
				break
			_consumir_grade(r)
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
	_fechar_bau()
	for i in range(GRADE, MAO + 1):
		if _ids[i] != &"":
			var sobra := _guardar(_ids[i], _qtds[i], 0, GUARDAR)
			if sobra > 0:
				continue  # não coube: fica onde está (nada se perde)
			_ids[i] = &""
			_qtds[i] = 0
	na_bancada = false
	sombras_receita.clear()
	_enviar()


@rpc("any_peer", "call_local", "reliable")
func _pedido_receita(resultado: StringName) -> void:
	if not _pedido_do_dono():
		return
	var receita: ReceitaData = null
	for candidata in ReceitaData.todas():
		if candidata.resultado == resultado and _receita_cabe(candidata):
			receita = candidata
			break
	if receita == null:
		return
	var indices: Array[int] = []
	if na_bancada:
		for k in 9:
			indices.append(GRADE + k)
	else:
		indices = GRADE_2X2.duplicate()
	# Simula a devolução primeiro para não perder itens se a mochila estiver cheia.
	var ids_teste: Array[StringName] = _ids.duplicate()
	var qtds_teste: PackedInt32Array = _qtds.duplicate()
	for i in indices:
		if ids_teste[i] != &"":
			var sobra_teste: int = _guardar_em(ids_teste, qtds_teste, ids_teste[i], qtds_teste[i], 0, GUARDAR)
			if sobra_teste > 0:
				return
			ids_teste[i] = &""
			qtds_teste[i] = 0
	_ids = ids_teste
	_qtds = qtds_teste
	var alvos: Dictionary[int, StringName] = _posicoes_receita(receita, indices.size())
	sombras_receita.clear()
	for espaco in alvos:
		var item: StringName = alvos[espaco]
		var origem: int = _buscar_item_guardado(item)
		if origem < 0:
			sombras_receita[espaco] = item
		else:
			_ids[espaco] = item
			_qtds[espaco] = 1
			_tirar(origem, 1)
	_enviar()


func _receita_cabe(receita: ReceitaData) -> bool:
	if receita.sem_forma:
		return receita.ingredientes.size() <= (9 if na_bancada else 4)
	if receita.padrao.is_empty() or receita.padrao[0].is_empty():
		return false
	return receita.padrao.size() <= (3 if na_bancada else 2) and receita.padrao[0].length() <= (3 if na_bancada else 2)


func _posicoes_receita(receita: ReceitaData, total: int) -> Dictionary[int, StringName]:
	var alvos: Dictionary[int, StringName] = {}
	var indices: Array[int] = []
	if total == 4:
		indices = GRADE_2X2.duplicate()
	else:
		for k in 9:
			indices.append(GRADE + k)
	if receita.sem_forma:
		for k in receita.ingredientes.size():
			alvos[indices[k]] = receita.ingredientes[k]
		return alvos
	for y in receita.padrao.size():
		for x in receita.padrao[y].length():
			var letra: String = receita.padrao[y][x]
			if letra != " ":
				alvos[indices[y * (3 if total == 9 else 2) + x]] = receita.chave.get(letra, &"")
	return alvos


func _buscar_item_guardado(item: StringName) -> int:
	for i in GUARDAR:
		if _ids[i] == item and _qtds[i] > 0:
			return i
	return -1


func _guardar_em(ids: Array[StringName], qtds: PackedInt32Array, item_id: StringName, quantidade: int, de: int, ate: int) -> int:
	if not ItemData.existe(item_id):
		return quantidade
	var pilha: int = ItemData.carregar(item_id).pilha
	for i in range(de, ate):
		if ids[i] == item_id and qtds[i] < pilha:
			var passa: int = mini(quantidade, pilha - qtds[i])
			qtds[i] += passa
			quantidade -= passa
	for i in range(de, ate):
		if quantidade <= 0:
			break
		if ids[i] == &"":
			var passa: int = mini(quantidade, pilha)
			ids[i] = item_id
			qtds[i] = passa
			quantidade -= passa
	return quantidade


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


## Clique num espaço de roupa: troca com o que está na mão do mouse, mas só aceita roupa
## daquele lugar (cabeça ou corpo). Mão vazia pega a roupa (tirar). Shift + clique tira a
## roupa direto para a mochila.
func _clique_roupa(i: int, rapido: bool) -> void:
	if rapido:
		if _ids[i] == &"":
			return
		var sobra := _guardar(_ids[i], _qtds[i], 0, GUARDAR)
		if sobra == 0:
			_ids[i] = &""
			_qtds[i] = 0
		return
	if _ids[MAO] != &"" and not _veste_em(_ids[MAO], i):
		return
	_trocar(i, MAO)


## Esta roupa serve neste espaço de roupa?
func _veste_em(item_id: StringName, espaco: int) -> bool:
	return ItemData.existe(item_id) and ItemData.carregar(item_id).equipa == EQUIPAMENTO.get(espaco, &"?")


## Shift + clique numa roupa da barra ou da mochila: veste (e a que estava vestida vai
## para o lugar dela). Retorna se vestiu.
func _vestir_rapido(i: int) -> bool:
	if not ItemData.existe(_ids[i]):
		return false
	var onde := ItemData.carregar(_ids[i]).equipa
	if onde == &"":
		return false
	for espaco in EQUIPAMENTO:
		if EQUIPAMENTO[espaco] == onde:
			_trocar(i, espaco)
			return true
	return false


## Shift + clique: da barra para a mochila, da mochila para a barra, da grade para guardar.
func _mover_rapido(i: int) -> void:
	if _ids[i] == &"":
		return
	if i < GUARDAR and not is_instance_valid(bau_aberto) and _vestir_rapido(i):
		return
	var de := 0
	var ate := GUARDAR
	if is_instance_valid(bau_aberto) and i < GUARDAR:
		de = BAU  # com o baú aberto, Shift manda para o baú
		ate = BAU + BAU_N
	elif i >= BAU:
		pass  # do baú para a barra e a mochila
	elif i < BARRA:
		de = BARRA
	elif i < GUARDAR:
		ate = BARRA
	var sobra := _guardar(_ids[i], _qtds[i], de, ate)
	if sobra == 0:
		_ids[i] = &""
	_qtds[i] = sobra


## Gasta 1 de cada espaço da grade. Faísca (Mago): a fogueira e a tocha não gastam o graveto.
func _consumir_grade(r: ReceitaData = null) -> void:
	# Pelo caminho (sem citar PassivasMago): a classe carrega as cenas dos feitiços (ciclo de preload).
	var poupa := r != null and bool(load("res://scripts/player/passivas_mago.gd").call(&"poupa_graveto", get_parent() as Player, r.resultado))
	var espacos: Array[int] = []
	if na_bancada:
		for k in 9:
			espacos.append(GRADE + k)
	else:
		espacos = GRADE_2X2
	for k in espacos:
		if _ids[k] != &"" and not (poupa and _ids[k] == &"graveto"):
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
	if is_instance_valid(bau_aberto) and multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		var c := []
		for k in BAU_N:
			c.append([String(_ids[BAU + k]), _qtds[BAU + k]])
		bau_aberto.set(&"conteudo", c)
	com_bau = is_instance_valid(bau_aberto) or (com_bau and not multiplayer.is_server())
	mudou.emit()
	if not multiplayer.has_multiplayer_peer():
		return
	var dono := get_parent().get_multiplayer_authority()
	if dono != multiplayer.get_unique_id():
		_receber.rpc_id(dono, _ids, _qtds, na_bancada, is_instance_valid(bau_aberto), sombras_receita)


@rpc("any_peer", "reliable")
func _receber(ids: Array, qtds: PackedInt32Array, bancada: bool, bau: bool, sombras: Dictionary) -> void:
	if not Net.veio_do_anfitriao():
		return
	for i in mini(ids.size(), ESPACOS):
		_ids[i] = StringName(ids[i])
	_qtds = qtds
	na_bancada = bancada
	com_bau = bau
	sombras_receita.clear()
	for espaco in sombras:
		sombras_receita[int(espaco)] = StringName(sombras[espaco])
	mudou.emit()


## O que o boneco veste: {cabeca: "", corpo: id}; roupa vazia = roupinha branca. Só leitura.
func roupas() -> Dictionary:
	return {&"cabeca": &"", &"corpo": _ids[EQUIP_CORPO]}


## Só o anfitrião: veste a roupa direto no espaço dela (a que estava vestida vai para a
## mochila). Retorna se vestiu.
func vestir(item_id: StringName) -> bool:
	if not ItemData.existe(item_id):
		return false
	for espaco in EQUIPAMENTO:
		if EQUIPAMENTO[espaco] != ItemData.carregar(item_id).equipa:
			continue
		if _ids[espaco] != &"" and _guardar(_ids[espaco], 1, 0, GUARDAR) > 0:
			return false  # mochila cheia: não há onde pôr a roupa velha
		_ids[espaco] = item_id
		_qtds[espaco] = 1
		_enviar()
		return true
	return false


## Gasta do espaço `i` (o anfitrião, ao pôr uma construção da mão).
func gastar(i: int, quantidade: int) -> void:
	_tirar(i, quantidade)
	_enviar()


# --- Baú (só o anfitrião) -------------------------------------------------------------
## Abre o baú `b` (nó com `conteudo` = [[id, qtd], ...] e `em_uso_por`) para o dono:
## copia o conteúdo para os espaços 46-72. Um jogador por vez. Retorna se abriu.
func abrir_bau(b: Node) -> bool:
	var usando = b.get(&"em_uso_por")
	if is_instance_valid(usando) and usando != get_parent():
		return false
	_fechar_bau()
	b.set(&"em_uso_por", get_parent())
	bau_aberto = b
	na_bancada = false
	var c: Array = b.get(&"conteudo")
	for k in BAU_N:
		var e: Array = c[k] if k < c.size() else ["", 0]
		var id := StringName(e[0])
		_ids[BAU + k] = id if ItemData.existe(id) else &""
		_qtds[BAU + k] = int(e[1]) if _ids[BAU + k] != &"" else 0
	_enviar()
	return true


## Grava o baú de volta e solta (ao fechar a tela, sair do jogo ou o baú quebrar).
func _fechar_bau() -> void:
	if not is_instance_valid(bau_aberto):
		bau_aberto = null
		return
	_enviar()  # grava o conteúdo atual no baú
	bau_aberto.set(&"em_uso_por", null)
	bau_aberto = null
	for k in BAU_N:
		_ids[BAU + k] = &""
		_qtds[BAU + k] = 0


func fechar_bau_servidor() -> void:
	_fechar_bau()
	_enviar()
