extends TesteBase
## Piloto do estilo Tiny Swords DENTRO do jogo, antes de integrar: a ilha com o terreno, a
## espuma da água, as árvores, pedras, arbustos, ovelhas e personagens do pacote gratuito
## (art/terceiros/tiny_swords, fora de game/ até o João aprovar).
## A arte deles é feita para tiles de 64 px; o nosso mundo usa 16. Por isso tudo entra com
## escala 0,25 e a câmera em zoom 4: na tela fica 1 pixel da arte = 1 pixel da tela (nítido).
## O pacote não tem areia: a beira da ilha usa a grama oliva (cor 4) no lugar, por enquanto.
## Salva evidence/piloto_tiny/acampamento.png e praia.png. Precisa de janela.

const ZOOM := 4
const ESCALA := 0.25
const TS := 64  # tile do Tiny Swords
var pack := ProjectSettings.globalize_path("res://").path_join("../art/terceiros/tiny_swords/Tiny Swords (Free Pack)")
var _cache := {}


func _ready() -> void:
	var w := await criar_mundo(0, true, &"mago")
	w.jogador.visible = false
	w.hud.visible = false
	for n in w.entidades.get_children():
		if n is Sprite2D or n is StaticBody2D:
			n.queue_free()
	w.chao_suave.visible = false
	_montar_terreno(w)
	var cam := Camera2D.new()
	cam.zoom = Vector2(ZOOM, ZOOM)
	w.add_child(cam)
	cam.make_current()

	var c := w.centro
	_animado(w, "Particle FX/Fire_01.png", Vector2i(64, 64), c + Vector2(0, 8), 56)
	_animado(w, "Units/Blue Units/Warrior/Warrior_Idle.png", Vector2i(192, 192), c + Vector2(-34, 30), 130)
	_animado(w, "Units/Blue Units/Archer/Archer_Idle.png", Vector2i(192, 192), c + Vector2(-8, 36), 130)
	_animado(w, "Units/Blue Units/Monk/Idle.png", Vector2i(192, 192), c + Vector2(20, 34), 130)
	# Os nossos (L11), feitos pelo Codex no estilo deles, ao lado das unidades do pacote.
	_nosso(w, 0, c + Vector2(46, 32))
	_nosso(w, 1, c + Vector2(70, 30))
	_animado(w, "Units/Yellow Units/Pawn/Pawn_Interact Axe.png", Vector2i(192, 192), c + Vector2(-70, -10), 130)
	for p in [Vector2(-90, -20), Vector2(-120, 30), Vector2(80, -36), Vector2(110, 20), Vector2(-40, -50), Vector2(60, 60), Vector2(-100, 64), Vector2(130, -10)]:
		_animado(w, "Terrain/Resources/Wood/Trees/Tree%d.png" % (1 + int(absf(p.x + p.y)) % 4), Vector2i(192, 256), c + p, 230)
	_parado(w, "Terrain/Resources/Wood/Trees/Stump 1.png", c + Vector2(40, -40), 230)
	for p in [Vector2(-60, 16), Vector2(70, 30)]:
		_parado(w, "Terrain/Decorations/Rocks/Rock2.png", c + p, 52)
	for p in [Vector2(-20, 64), Vector2(44, -14), Vector2(-60, 50)]:
		_animado(w, "Terrain/Decorations/Bushes/Bushe%d.png" % (1 + int(absf(p.x)) % 4), Vector2i(128, 128), c + p, 100)
	for p in [Vector2(30, 70), Vector2(90, 46)]:
		_animado(w, "Terrain/Resources/Meat/Sheep/Sheep_Idle.png", Vector2i(128, 128), c + p, 96)
	cam.position = c + Vector2(0, 10)
	await esperar(0.5)
	await salvar_print("piloto_tiny/acampamento.png")

	var x := 0
	while w.tipo_do_chao(Vector2i(x, w.altura / 2)) == World.Chao.AGUA:
		x += 1
	var b := Vector2(x * World.T, c.y)
	for p in [Vector2(70, -50), Vector2(110, 30), Vector2(150, -20)]:
		_animado(w, "Terrain/Resources/Wood/Trees/Tree%d.png" % (1 + int(p.x) % 4), Vector2i(192, 256), b + p, 230)
	_animado(w, "Units/Blue Units/Archer/Archer_Idle.png", Vector2i(192, 192), b + Vector2(30, 20), 130)
	_animado(w, "Terrain/Resources/Meat/Sheep/Sheep_Idle.png", Vector2i(128, 128), b + Vector2(60, 50), 96)
	_animado(w, "Terrain/Decorations/Rocks in the Water/Water Rocks_01.png", Vector2i(64, 64), b + Vector2(-40, 0), 44)
	cam.position = b + Vector2(40, 10)
	await esperar(0.5)
	await salvar_print("piloto_tiny/praia.png")
	terminar()


func _textura(caminho: String) -> Texture2D:
	if not _cache.has(caminho):
		_cache[caminho] = ImageTexture.create_from_image(Image.load_from_file(pack.path_join(caminho)))
	return _cache[caminho]


# --- Terreno ---------------------------------------------------------------------
## Água lisa no fundo, espuma animada embaixo da beira, "areia" (grama oliva) em toda a
## ilha e a grama por cima. Cada camada escolhe o tile pelos 4 vizinhos: o terreno deles
## tem as 16 combinações (bloco 3x3, tira vertical, tira horizontal e tile sozinho).
func _montar_terreno(w: World) -> void:
	var raiz := Node2D.new()
	raiz.scale = Vector2(ESCALA, ESCALA)
	w.add_child(raiz)
	w.move_child(raiz, w.chao_suave.get_index() + 1)
	var agua := Sprite2D.new()
	agua.texture = _textura("Terrain/Tileset/Water Background color.png")
	agua.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	agua.region_enabled = true
	agua.region_rect = Rect2(0, 0, (w.largura + 20) * TS, (w.altura + 20) * TS)
	agua.centered = false
	agua.position = Vector2(-10, -10) * TS
	raiz.add_child(agua)

	var terra := func(cel: Vector2i) -> bool: return w.tipo_do_chao(cel) != World.Chao.AGUA
	var grama := func(cel: Vector2i) -> bool: return w.tipo_do_chao(cel) == World.Chao.GRAMA and not w._terra.has(cel)
	var espuma := SpriteFrames.new()
	espuma.remove_animation(&"default")
	SpriteSheets.adicionar_tira(espuma, _textura("Terrain/Tileset/Water Foam.png"), &"onda", Vector2i(192, 192), 16, 10.0)
	for y in w.altura:
		for x in w.largura:
			var cel := Vector2i(x, y)
			if terra.call(cel) and _vizinhos(cel, terra) != 15:
				var a := AnimatedSprite2D.new()
				a.sprite_frames = espuma
				a.play(&"onda")
				a.frame = (x * 7 + y * 3) % 16
				a.position = Vector2(cel * TS) + Vector2(TS, TS) / 2.0
				raiz.add_child(a)
	raiz.add_child(_camada(w, "Terrain/Tileset/Tilemap_color4.png", terra))
	raiz.add_child(_camada(w, "Terrain/Tileset/Tilemap_color1.png", grama))


func _camada(w: World, folha: String, e_desta: Callable) -> TileMapLayer:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TS, TS)
	var src := TileSetAtlasSource.new()
	src.texture = _textura(folha)
	src.texture_region_size = Vector2i(TS, TS)
	ts.add_source(src, 0)
	for y in 4:
		for x in 4:
			src.create_tile(Vector2i(x, y))
	var camada := TileMapLayer.new()
	camada.tile_set = ts
	for y in w.altura:
		for x in w.largura:
			var cel := Vector2i(x, y)
			if e_desta.call(cel):
				camada.set_cell(cel, 0, _tile(_vizinhos(cel, e_desta)))
	return camada


## Bits: 1 norte, 2 sul, 4 oeste, 8 leste (vizinho do mesmo terreno).
func _vizinhos(cel: Vector2i, e_desta: Callable) -> int:
	var n := 0
	if e_desta.call(cel + Vector2i.UP): n |= 1
	if e_desta.call(cel + Vector2i.DOWN): n |= 2
	if e_desta.call(cel + Vector2i.LEFT): n |= 4
	if e_desta.call(cel + Vector2i.RIGHT): n |= 8
	return n


## Coluna: 0 começa à esquerda, 1 meio, 2 termina à direita, 3 tira vertical (sem lados).
## Linha: 0 começa em cima, 1 meio, 2 termina embaixo, 3 tira horizontal (sem cima/baixo).
func _tile(v: int) -> Vector2i:
	var oeste := v & 4 != 0
	var leste := v & 8 != 0
	var norte := v & 1 != 0
	var sul := v & 2 != 0
	var col := 1 if oeste and leste else (2 if oeste else (0 if leste else 3))
	var lin := 1 if norte and sul else (2 if norte else (0 if sul else 3))
	return Vector2i(col, lin)


# --- Objetos ---------------------------------------------------------------------
## `pe`: em que altura do quadro (em pixels da arte) fica a base, para pôr a base em `pos`.
func _animado(w: World, folha: String, quadro: Vector2i, pos: Vector2, pe: int) -> void:
	var tex := _textura(folha)
	var f := SpriteFrames.new()
	f.remove_animation(&"default")
	SpriteSheets.adicionar_tira(f, tex, &"a", quadro, tex.get_width() / quadro.x, 10.0)
	var a := AnimatedSprite2D.new()
	a.sprite_frames = f
	a.play(&"a")
	a.frame = int(absf(pos.x)) % f.get_frame_count(&"a")
	a.centered = false
	a.offset = Vector2(-quadro.x / 2.0, -pe)
	a.scale = Vector2(ESCALA, ESCALA)
	a.position = pos.round()
	w.entidades.add_child(a)


func _parado(w: World, folha: String, pos: Vector2, pe: int) -> void:
	var s := Sprite2D.new()
	s.texture = _textura(folha)
	s.centered = false
	s.offset = Vector2(-s.texture.get_width() / 2.0, -pe)
	s.scale = Vector2(ESCALA, ESCALA)
	s.position = pos.round()
	w.entidades.add_child(s)


## Personagem nosso (L11): quadros de 64x64 com o pixel 2x maior que o deles, então
## escala dupla (0,5) para ficar do tamanho das unidades do pacote.
func _nosso(w: World, i: int, pos: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(Image.load_from_file(pack.path_join("../../../sprites/tiny/convertido/personagens_nativo.png").simplify_path()))
	s.region_enabled = true
	s.region_rect = Rect2(i * 64, 0, 64, 64)
	s.centered = false
	s.offset = Vector2(-32, -60)
	s.scale = Vector2(ESCALA * 2, ESCALA * 2)
	s.position = pos.round()
	w.entidades.add_child(s)
