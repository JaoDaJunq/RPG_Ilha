class_name World
extends Node2D
## A ilha: gera o chão, espalha árvores, pedras, plantas e slimes, monta o acampamento,
## cria o jogador e controla o dia e a noite (N).
##
## O formato da ilha é gerado com uma semente fixa (sempre a mesma ilha).
## O mapa feito à mão e os biomas vêm na Etapa 4.

const ARVORE := preload("res://scenes/world/arvore.tscn")
const PEDRA := preload("res://scenes/world/pedra.tscn")
const SLIME := preload("res://scenes/enemies/slime.tscn")
const JOGADOR := preload("res://scenes/player/player.tscn")
const TEX_CHAO := preload("res://assets/placeholder/ninja/tilesets/TilesetFloor.png")
const TEX_AGUA := preload("res://assets/placeholder/ninja/tilesets/TilesetWater.png")
const TEX_NATUREZA := preload("res://assets/placeholder/ninja/tilesets/TilesetNature.png")
const TEX_ACAMPAMENTO := preload("res://assets/placeholder/ninja/tilesets/tileset_camp.png")
const LUZ := preload("res://assets/luz/luz_radial.tres")

const T := 16
# Coordenadas (em tiles) dentro das folhas do Ninja Adventure.
const GRAMA := Vector2i(0, 12)
const GRAMA_DETALHES: Array[Vector2i] = [Vector2i(1, 12), Vector2i(2, 12), Vector2i(3, 12), Vector2i(4, 12)]
const AREIA := Vector2i(1, 1)
const AREIA_DETALHES: Array[Vector2i] = [Vector2i(0, 4), Vector2i(1, 4)]
const TERRA_CIRCULO := Vector2i(0, 7)  # canto de cima-esquerda de um círculo 3x3 de terra
const AGUA := Vector2i(11, 0)
# Regiões (em pixels) na folha de natureza.
## Variações da árvore na folha L01: verde (mais comum) e flor rosa.
const COPA_VERDE := Rect2(0, 0, 64, 64)
const COPA_ROSA := Rect2(256, 0, 64, 64)
const PEDRA_MARROM := Rect2(144, 0, 48, 48)
const PLANTAS: Array[Rect2] = [
	Rect2(0, 160, 16, 16), Rect2(16, 160, 16, 16), Rect2(32, 160, 16, 16), Rect2(48, 160, 16, 16),
	Rect2(96, 160, 16, 16), Rect2(112, 160, 16, 16), Rect2(128, 160, 16, 16), Rect2(144, 160, 16, 16),
	Rect2(0, 176, 16, 16), Rect2(16, 176, 16, 16), Rect2(32, 176, 16, 16), Rect2(48, 176, 16, 16),
	Rect2(64, 176, 16, 16), Rect2(80, 176, 16, 16), Rect2(96, 176, 16, 16), Rect2(144, 176, 16, 16),
]
## Raio sem árvores em volta da fogueira.
const RAIO_CLAREIRA := 120.0
const COR_DIA := Color(1, 1, 1)
const COR_NOITE := Color(0.24, 0.27, 0.46)

enum Chao { AGUA, AREIA, GRAMA }

@export var largura := 64
@export var altura := 44
@export var semente := 22117
@export var arvores := 80
@export var pedras := 16
@export var plantas := 170
@export var slimes := 5
## Falso nos testes que precisam de terreno limpo (sem árvores e pedras geradas).
@export var gerar_recursos := true

const MENU := "res://scenes/ui/menu.tscn"

## Só para os testes de rede: o outro jogo manda o que viu.
signal relatorio_recebido(peer: int, dados: Dictionary)

## O jogador controlado nesta máquina.
var jogador: Player
var noite := false
var centro := Vector2.ZERO
var _tipo: Dictionary[Vector2i, int] = {}
var _distancia: Dictionary[Vector2i, float] = {}
var _ocupados: Array[Vector2] = []
var _removidos: Array[String] = []
var _nascimentos: Dictionary[int, Vector2] = {}
var _rng := RandomNumberGenerator.new()

@onready var chao: TileMapLayer = $Chao
@onready var entidades: Node2D = $Entidades
@onready var ambiente: CanvasModulate = $Ambiente
@onready var hud: Hud = $HUD


func _ready() -> void:
	add_to_group(&"mundo")
	_rng.seed = semente
	centro = Vector2(largura / 2 * T + T / 2, altura / 2 * T + T / 2)
	# O cenário nasce igual em todos os jogadores (mesma semente, mesmos nomes).
	_gerar_chao()
	_montar_acampamento()
	_espalhar()
	_aplicar_ciclo(false, true)

	if Net.iniciar() != OK:
		_voltar_ao_menu.call_deferred()
		return
	multiplayer.peer_disconnected.connect(_on_peer_saiu)
	multiplayer.connected_to_server.connect(func() -> void: _cliente_pronto.rpc_id(1))
	multiplayer.connection_failed.connect(_on_conexao_perdida.bind("Não foi possível conectar ao anfitrião."))
	multiplayer.server_disconnected.connect(_on_conexao_perdida.bind("O anfitrião saiu do jogo."))
	if multiplayer.is_server():
		_criar_slimes()
		if Net.modo != Net.Modo.ENTRAR:
			_criar_jogador(1)
	else:
		Events.aviso.emit("Conectando em %s..." % Net.endereco)
	Sfx.tocar_musica()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"alternar_noite"):
		alternar_noite()


## Qualquer jogador pode pedir; o anfitrião troca para todos.
func alternar_noite() -> void:
	_pedir_ciclo.rpc_id(1)


## O Player local chama isto ao nascer nesta máquina.
func registrar_jogador_local(p: Player) -> void:
	jogador = p
	p.ponto_de_retorno = p.position
	if not multiplayer.is_server():
		# O jogador controlado aqui não aceita a posição enviada no nascimento
		# (quem manda nele é este jogo), então pergunta ao anfitrião onde nascer.
		_pedir_nascimento.rpc_id(1)
	p.camera.limit_left = 0
	p.camera.limit_top = 0
	p.camera.limit_right = largura * T
	p.camera.limit_bottom = altura * T
	p.camera.reset_smoothing()
	hud.configurar(p)
	if multiplayer.is_server() and Net.modo == Net.Modo.HOSPEDAR:
		var ips := ", ".join(Net.enderecos_locais())
		Events.aviso.emit("Você é o anfitrião. Seus amigos entram pelo IP: %s" % (ips if ips != "" else "?"))
	else:
		Events.aviso.emit("Explore a clareira: segure E nas árvores e pedras.")


func ponto_de_nascer(indice: int) -> Vector2:
	return centro + Vector2(30 * indice, 34)


func registrar_removido(nome: String) -> void:
	_removidos.append(nome)


## Aviso para todos os jogadores (chamado pelo anfitrião).
static func avisar_todos(quem: Node, texto: String) -> void:
	var w: World = quem.get_tree().get_first_node_in_group(&"mundo")
	if w:
		w._aviso_global.rpc(texto)


# --- Rede ------------------------------------------------------------------------

func _criar_jogador(peer: int) -> void:
	var p: Player = JOGADOR.instantiate()
	p.name = str(peer)
	p.position = ponto_de_nascer(get_tree().get_nodes_in_group(&"jogadores").size())
	_nascimentos[peer] = p.position
	entidades.add_child(p, true)


@rpc("any_peer", "reliable")
func _pedir_nascimento() -> void:
	var peer := multiplayer.get_remote_sender_id()
	if multiplayer.is_server() and _nascimentos.has(peer):
		_definir_nascimento.rpc_id(peer, _nascimentos[peer])


@rpc("any_peer", "reliable")
func _definir_nascimento(pos: Vector2) -> void:
	if not Net.veio_do_anfitriao() or jogador == null:
		return
	jogador.global_position = pos
	jogador.ponto_de_retorno = pos
	jogador.camera.reset_smoothing()


@rpc("any_peer", "reliable")
func _cliente_pronto() -> void:
	if not multiplayer.is_server():
		return
	var peer := multiplayer.get_remote_sender_id()
	if entidades.has_node(str(peer)):
		return
	_criar_jogador(peer)
	# Quem entra depois recebe o que já mudou no mundo.
	_aplicar_ciclo_rede.rpc_id(peer, noite, true)
	if not _removidos.is_empty():
		_remover_recursos.rpc_id(peer, _removidos)
	for r in get_tree().get_nodes_in_group(&"recursos"):
		(r as ResourceNode).enviar_estado_para(peer)
	World.avisar_todos(self, "Um amigo entrou na ilha!")


func _on_peer_saiu(peer: int) -> void:
	if multiplayer.is_server() and entidades.has_node(str(peer)):
		entidades.get_node(str(peer)).queue_free()
		World.avisar_todos(self, "Um amigo saiu da ilha.")


func _on_conexao_perdida(motivo: String) -> void:
	Net.ultimo_erro = motivo
	_voltar_ao_menu()


func _voltar_ao_menu() -> void:
	Net.encerrar()
	if ResourceLoader.exists(MENU) and get_tree().current_scene == self:
		get_tree().change_scene_to_file(MENU)


@rpc("any_peer", "reliable")
func _remover_recursos(nomes: Array) -> void:
	if not Net.veio_do_anfitriao():
		return
	for n in nomes:
		if entidades.has_node(NodePath(n)):
			entidades.get_node(NodePath(n)).queue_free()


@rpc("any_peer", "call_local", "reliable")
func _aviso_global(texto: String) -> void:
	if Net.veio_do_anfitriao():
		Events.aviso.emit(texto)


@rpc("any_peer", "call_local", "reliable")
func _pedir_ciclo() -> void:
	if multiplayer.is_server():
		_aplicar_ciclo_rede.rpc(not noite, false)


@rpc("any_peer", "call_local", "reliable")
func _aplicar_ciclo_rede(para_noite: bool, imediato: bool) -> void:
	if Net.veio_do_anfitriao():
		_aplicar_ciclo(para_noite, imediato)


@rpc("any_peer", "reliable")
func relatorio_teste(dados: Dictionary) -> void:
	relatorio_recebido.emit(multiplayer.get_remote_sender_id(), dados)


func tipo_do_chao(celula: Vector2i) -> int:
	return _tipo.get(celula, Chao.AGUA)


# --- Geração ---------------------------------------------------------------

func _gerar_chao() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	var src_chao := TileSetAtlasSource.new()
	src_chao.texture = TEX_CHAO
	src_chao.texture_region_size = Vector2i(T, T)
	var id_chao := ts.add_source(src_chao)
	var coords: Array[Vector2i] = [GRAMA, AREIA]
	coords.append_array(GRAMA_DETALHES)
	coords.append_array(AREIA_DETALHES)
	for y in 3:
		for x in 3:
			coords.append(TERRA_CIRCULO + Vector2i(x, y))
	for c in coords:
		src_chao.create_tile(c)
	var src_agua := TileSetAtlasSource.new()
	src_agua.texture = TEX_AGUA
	src_agua.texture_region_size = Vector2i(T, T)
	var id_agua := ts.add_source(src_agua)
	src_agua.create_tile(AGUA)
	var dados := src_agua.get_tile_data(AGUA, 0)
	dados.add_collision_polygon(0)
	dados.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]))
	chao.tile_set = ts

	var ruido := FastNoiseLite.new()
	ruido.seed = semente
	ruido.frequency = 0.08
	for y in altura:
		for x in largura:
			var cel := Vector2i(x, y)
			var nx := (x - largura / 2.0) / (largura * 0.44)
			var ny := (y - altura / 2.0) / (altura * 0.42)
			var d := sqrt(nx * nx + ny * ny) + ruido.get_noise_2d(x, y) * 0.16
			_distancia[cel] = d
			if d > 1.0:
				_tipo[cel] = Chao.AGUA
				chao.set_cell(cel, id_agua, AGUA)
			elif d > 0.87:
				_tipo[cel] = Chao.AREIA
				chao.set_cell(cel, id_chao, _sortear(AREIA, AREIA_DETALHES, 0.12))
			else:
				_tipo[cel] = Chao.GRAMA
				chao.set_cell(cel, id_chao, _sortear(GRAMA, GRAMA_DETALHES, 0.18))
	# Clareira de terra embaixo da fogueira.
	var c := Vector2i(largura / 2, altura / 2)
	for y in 3:
		for x in 3:
			chao.set_cell(c + Vector2i(x - 1, y - 1), id_chao, TERRA_CIRCULO + Vector2i(x, y))


func _sortear(base: Vector2i, detalhes: Array[Vector2i], chance: float) -> Vector2i:
	if _rng.randf() < chance:
		return detalhes[_rng.randi() % detalhes.size()]
	return base


func _montar_acampamento() -> void:
	var fogueira := _sprite(TEX_ACAMPAMENTO, Rect2(192, 80, 32, 32), centro + Vector2(0, 10))
	var luz := PointLight2D.new()
	luz.texture = LUZ
	luz.color = Color(1, 0.55, 0.25)
	luz.energy = 0.8
	luz.texture_scale = 1.6
	luz.position = Vector2(0, -10)
	luz.add_to_group(&"luzes_noturnas")
	fogueira.add_child(luz)
	var t := luz.create_tween().set_loops()
	t.tween_property(luz, "energy", 0.65, 0.18)
	t.tween_property(luz, "energy", 0.85, 0.23)
	_ocupados.append(fogueira.position)

	var barraca := StaticBody2D.new()
	barraca.position = centro + Vector2(-44, -14)
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = Vector2(40, 12)
	forma.shape = ret
	forma.position = Vector2(0, -6)
	barraca.add_child(forma)
	entidades.add_child(barraca)
	_sprite(TEX_ACAMPAMENTO, Rect2(64, 0, 48, 48), Vector2.ZERO, barraca)
	_ocupados.append(barraca.position)


func _espalhar() -> void:
	var celulas_grama: Array[Vector2i] = []
	for cel in _tipo:
		if _tipo[cel] == Chao.GRAMA and _distancia[cel] < 0.82:
			celulas_grama.append(cel)

	var colocadas := 0
	for i in arvores * 6:
		if colocadas >= arvores:
			break
		var p := _ponto_em(celulas_grama)
		if p.distance_to(centro) > RAIO_CLAREIRA and _livre(p, 34.0):
			var rosa := _rng.randf() < 0.22
			_ocupados.append(p)
			colocadas += 1
			if gerar_recursos:
				var a: ResourceNode = ARVORE.instantiate()
				a.name = "Arvore%d" % colocadas
				if rosa:
					a.regiao_inteiro = COPA_ROSA
					a.regioes_por_golpe = []
				a.position = p
				entidades.add_child(a)

	colocadas = 0
	for i in pedras * 8:
		if colocadas >= pedras:
			break
		var p := _ponto_em(celulas_grama)
		if p.distance_to(centro) > 70.0 and _livre(p, 26.0):
			var marrom := _rng.randf() < 0.35
			_ocupados.append(p)
			colocadas += 1
			if gerar_recursos:
				var pd: ResourceNode = PEDRA.instantiate()
				pd.name = "Pedra%d" % colocadas
				if marrom:
					pd.regiao_inteiro = PEDRA_MARROM
					pd.regioes_por_golpe = []
				pd.position = p
				entidades.add_child(pd)

	for i in plantas:
		var p := _ponto_em(celulas_grama)
		if p.distance_to(centro) > 30.0 and _livre(p, 8.0):
			_sprite(TEX_NATUREZA, PLANTAS[_rng.randi() % PLANTAS.size()], p)


## Só o anfitrião cria os slimes; o MultiplayerSpawner copia para os outros.
func _criar_slimes() -> void:
	var celulas_grama: Array[Vector2i] = []
	for cel in _tipo:
		if _tipo[cel] == Chao.GRAMA and _distancia[cel] < 0.82:
			celulas_grama.append(cel)
	var colocadas := 0
	for i in slimes * 20:
		if colocadas >= slimes:
			break
		var p := _ponto_em(celulas_grama)
		if p.distance_to(centro) > 150.0 and _livre(p, 14.0):
			colocadas += 1
			var s: Slime = SLIME.instantiate()
			s.name = "Slime%d" % colocadas
			s.position = p
			entidades.add_child(s, true)


func _ponto_em(celulas: Array[Vector2i]) -> Vector2:
	var cel := celulas[_rng.randi() % celulas.size()]
	return Vector2(cel * T) + Vector2(_rng.randf_range(2, 14), _rng.randf_range(6, 15))


func _livre(p: Vector2, raio: float) -> bool:
	for o in _ocupados:
		if o.distance_to(p) < raio:
			return false
	return true


func _sprite(textura: Texture2D, regiao: Rect2, pos: Vector2, pai: Node = null) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = textura
	s.region_enabled = true
	s.region_rect = regiao
	s.centered = false
	s.offset = Vector2(-regiao.size.x / 2.0, -regiao.size.y)
	s.position = pos
	(pai if pai else entidades).add_child(s)
	return s


# --- Dia e noite -------------------------------------------------------------

func _aplicar_ciclo(para_noite: bool, imediato: bool) -> void:
	noite = para_noite
	var cor := COR_NOITE if noite else COR_DIA
	if imediato:
		ambiente.color = cor
	else:
		create_tween().tween_property(ambiente, "color", cor, 1.2)
	for luz in get_tree().get_nodes_in_group(&"luzes_noturnas"):
		(luz as PointLight2D).enabled = noite
	if not imediato:
		Events.aviso.emit("A noite caiu. Fique perto da fogueira." if noite else "Amanheceu.")
