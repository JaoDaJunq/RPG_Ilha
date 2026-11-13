class_name Soneca
extends Node
## "Só fica ativo o que está perto": bichos, inimigos e árvores animadas longe de todos os
## jogadores dormem (process_mode DISABLED: sem IA, sem física, sem animação) e acordam
## quando alguém chega perto. Os pedaços de decoração animada (espuma, arbustos) também.
##
## Rede: no anfitrião, cada bicho, inimigo e item no chão só é mandado para o jogador que
## está perto dele (filtro de visibilidade do MultiplayerSynchronizer). Quem fica longe
## some no outro jogo e volta quando ele se aproxima (o Godot recria com o estado atual).

## Acorda a menos disto de algum jogador; dorme a mais de RAIO_DORMIR (a folga evita
## ficar ligando e desligando na beira).
const RAIO_ACORDAR := 560.0
const RAIO_DORMIR := 640.0
## A rede manda para cada jogador o que está a menos disto dele.
const RAIO_REDE := 720.0
const GRUPOS_VIVOS: Array[StringName] = [&"inimigos", &"animais"]
const INTERVALO_VIVOS := 0.2
const INTERVALO_PARADOS := 1.0

## Liga o filtro de rede por distância (desligar volta ao "todos veem tudo").
static var rede_por_perto := true

var w: World
var _tempo_vivos := 0.0
var _tempo_parados := 0.0
var _filtrados: Dictionary = {}  # sync → true
## Pedaços de decoração animada: [Node2D, centro em px do mundo]
var _pedacos: Array = []


func _init(mundo: World) -> void:
	w = mundo
	name = "Soneca"
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		w.entidades.child_entered_tree.connect(_ao_entrar)


## Um pedaço de decoração animada que dorme junto (World cria um por área).
func registrar_pedaco(n: Node2D, centro: Vector2) -> void:
	_pedacos.append([n, centro])


func _process(delta: float) -> void:
	_tempo_vivos += delta
	_tempo_parados += delta
	if _tempo_vivos >= INTERVALO_VIVOS:
		_tempo_vivos = 0.0
		_atualizar_vivos()
	if _tempo_parados >= INTERVALO_PARADOS:
		_tempo_parados = 0.0
		_atualizar_parados()


func _posicoes() -> PackedVector2Array:
	var lista := PackedVector2Array()
	for j in get_tree().get_nodes_in_group(&"jogadores"):
		lista.append((j as Node2D).global_position)
	var cam := get_viewport().get_camera_2d() if is_inside_tree() else null
	if cam:
		lista.append(cam.get_screen_center_position())  # prints e a câmera do mapa
	return lista


static func _distancia(pos: Vector2, perto: PackedVector2Array) -> float:
	var menor := INF
	for p in perto:
		menor = minf(menor, p.distance_to(pos))
	return menor


## Dorme ou acorda conforme a distância (com folga).
static func _ajustar(n: Node, d: float) -> void:
	if n.process_mode == Node.PROCESS_MODE_DISABLED:
		if d < RAIO_ACORDAR:
			n.process_mode = Node.PROCESS_MODE_INHERIT
	elif d > RAIO_DORMIR:
		n.process_mode = Node.PROCESS_MODE_DISABLED


func _atualizar_vivos() -> void:
	var perto := _posicoes()
	if perto.is_empty():
		return
	# Só o anfitrião pensa por eles; nos outros jogadores eles só mostram o que chega.
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		for g in GRUPOS_VIVOS:
			for n in get_tree().get_nodes_in_group(g):
				_ajustar(n, _distancia((n as Node2D).global_position, perto))
	if rede_por_perto and multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		for s in _filtrados.keys():
			if is_instance_valid(s):
				(s as MultiplayerSynchronizer).update_visibility()
			else:
				_filtrados.erase(s)


func _atualizar_parados() -> void:
	var perto := _posicoes()
	if perto.is_empty():
		return
	for n in get_tree().get_nodes_in_group(&"recursos"):
		_ajustar(n, _distancia((n as Node2D).global_position, perto))
	for p in _pedacos:
		if is_instance_valid(p[0]):
			_ajustar(p[0], _distancia(p[1], perto))


## Quantos estão dormindo agora (bichos, inimigos e recursos).
func dormindo() -> int:
	var n := 0
	for g in [&"inimigos", &"animais", &"recursos"]:
		for c in get_tree().get_nodes_in_group(g):
			if c.process_mode == Node.PROCESS_MODE_DISABLED:
				n += 1
	return n


# --- Rede: cada um recebe só o que está perto dele ---------------------------------

func _ao_entrar(n: Node) -> void:
	if not rede_por_perto or n is Player:
		return
	if not (n.is_in_group(&"inimigos") or n.is_in_group(&"animais") or n.is_in_group(&"itens_chao")):
		# Os grupos são postos no _ready, que vem depois do child_entered_tree.
		n.ready.connect(_ao_entrar_pronto.bind(n), CONNECT_ONE_SHOT)
		return
	_filtrar(n)


func _ao_entrar_pronto(n: Node) -> void:
	if n.is_in_group(&"inimigos") or n.is_in_group(&"animais") or n.is_in_group(&"itens_chao"):
		_filtrar(n)


func _filtrar(n: Node) -> void:
	var s := n.get_node_or_null(^"Sync") as MultiplayerSynchronizer
	if s == null or _filtrados.has(s):
		return
	s.add_visibility_filter(_ve.bind(n))
	_filtrados[s] = true


## O jogador `peer` recebe o nó `n`? (o anfitrião sempre; os outros, se estão perto)
func _ve(peer: int, n: Node2D) -> bool:
	if peer == 1 or peer == 0 or not is_instance_valid(n):
		return true
	var j := w.entidades.get_node_or_null(str(peer)) as Node2D
	return j == null or j.global_position.distance_to(n.global_position) <= RAIO_REDE
