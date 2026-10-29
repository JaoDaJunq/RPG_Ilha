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
const COPAS: Array[Rect2] = [Rect2(48, 288, 48, 48), Rect2(48, 288, 48, 48), Rect2(48, 288, 48, 48), Rect2(0, 288, 48, 48), Rect2(144, 288, 48, 48)]
const PLANTAS: Array[Rect2] = [
	Rect2(0, 160, 16, 16), Rect2(16, 160, 16, 16), Rect2(32, 160, 16, 16), Rect2(48, 160, 16, 16),
	Rect2(96, 160, 16, 16), Rect2(112, 160, 16, 16), Rect2(128, 160, 16, 16), Rect2(144, 160, 16, 16),
	Rect2(0, 176, 16, 16), Rect2(16, 176, 16, 16), Rect2(32, 176, 16, 16), Rect2(48, 176, 16, 16),
	Rect2(64, 176, 16, 16), Rect2(80, 176, 16, 16), Rect2(96, 176, 16, 16), Rect2(144, 176, 16, 16),
]
## Raio sem árvores em volta da fogueira.
const RAIO_CLAREIRA := 110.0
const COR_DIA := Color(1, 1, 1)
const COR_NOITE := Color(0.24, 0.27, 0.46)

enum Chao { AGUA, AREIA, GRAMA }

@export var largura := 64
@export var altura := 44
@export var semente := 22117
@export var arvores := 95
@export var pedras := 16
@export var plantas := 170
@export var slimes := 5

var jogador: Player
var noite := false
var centro := Vector2.ZERO
var _tipo: Dictionary[Vector2i, int] = {}
var _distancia: Dictionary[Vector2i, float] = {}
var _ocupados: Array[Vector2] = []
var _rng := RandomNumberGenerator.new()

@onready var chao: TileMapLayer = $Chao
@onready var entidades: Node2D = $Entidades
@onready var ambiente: CanvasModulate = $Ambiente
@onready var hud: Hud = $HUD


func _ready() -> void:
	_rng.seed = semente
	centro = Vector2(largura / 2 * T + T / 2, altura / 2 * T + T / 2)
	_gerar_chao()
	_montar_acampamento()
	_espalhar()
	_criar_jogador()
	hud.configurar(jogador)
	_aplicar_ciclo(false, true)
	Sfx.tocar_musica()
	Events.aviso.emit("Explore a clareira: segure E nas árvores e pedras.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"alternar_noite"):
		alternar_noite()


func alternar_noite() -> void:
	_aplicar_ciclo(not noite, false)


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
		if p.distance_to(centro) > RAIO_CLAREIRA and _livre(p, 24.0):
			var a: ResourceNode = ARVORE.instantiate()
			a.regiao_inteiro = COPAS[_rng.randi() % COPAS.size()]
			a.position = p
			entidades.add_child(a)
			_ocupados.append(p)
			colocadas += 1

	colocadas = 0
	for i in pedras * 8:
		if colocadas >= pedras:
			break
		var p := _ponto_em(celulas_grama)
		if p.distance_to(centro) > 60.0 and _livre(p, 18.0):
			var pd: ResourceNode = PEDRA.instantiate()
			if _rng.randf() < 0.4:
				pd.regiao_inteiro = Rect2(256, 128, 32, 32)
			pd.position = p
			entidades.add_child(pd)
			_ocupados.append(p)
			colocadas += 1

	for i in plantas:
		var p := _ponto_em(celulas_grama)
		if p.distance_to(centro) > 30.0 and _livre(p, 8.0):
			_sprite(TEX_NATUREZA, PLANTAS[_rng.randi() % PLANTAS.size()], p)

	colocadas = 0
	for i in slimes * 20:
		if colocadas >= slimes:
			break
		var p := _ponto_em(celulas_grama)
		if p.distance_to(centro) > 150.0 and _livre(p, 14.0):
			var s: Slime = SLIME.instantiate()
			s.position = p
			entidades.add_child(s)
			colocadas += 1


func _criar_jogador() -> void:
	jogador = JOGADOR.instantiate()
	jogador.position = centro + Vector2(0, 34)
	entidades.add_child(jogador)
	var cam: Camera2D = jogador.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = largura * T
	cam.limit_bottom = altura * T
	cam.reset_smoothing()


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
