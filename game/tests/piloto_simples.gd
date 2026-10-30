extends TesteBase
## Piloto L08 (arte simples, no sentido do Forager) DENTRO do jogo, antes de integrar.
## Troca o chão da ilha pelos blocos novos e espalha os objetos novos no acampamento e na
## praia, com a câmera mais perto (zoom 4). Lê as folhas convertidas de --pasta=...
## Salva evidence/piloto_simples/acampamento.png e praia.png. Precisa de janela.

const ZOOM := 4
var pasta := ProjectSettings.globalize_path("res://").path_join("../art/sprites/piloto_simples/convertido")  # fora de game/ até o João aprovar


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--pasta="):
			pasta = a.get_slice("=", 1)
	var w := await criar_mundo(0, true, &"mago")
	w.jogador.visible = false
	w.hud.visible = false
	for n in w.entidades.get_children():
		if n is Sprite2D or n is StaticBody2D:
			n.queue_free()
	_trocar_chao(w)
	var cam := Camera2D.new()
	cam.zoom = Vector2(ZOOM, ZOOM)
	w.add_child(cam)
	cam.make_current()

	# Acampamento: fogueira e baú no meio da terra, personagens, árvores em volta.
	var c := w.centro
	_objeto(w, "itens", 0, c + Vector2(0, 8))
	_objeto(w, "itens", 1, c + Vector2(34, 2))
	_objeto(w, "objetos", 0, c + Vector2(-14, 34))
	_objeto(w, "objetos", 1, c + Vector2(12, 36))
	_objeto(w, "itens", 2, c + Vector2(44, 46))
	for p in [Vector2(-120, -40), Vector2(-96, 60), Vector2(110, -50), Vector2(132, 30), Vector2(-60, -64), Vector2(70, 80)]:
		_objeto(w, "objetos", 2, c + p)
	for p in [Vector2(-140, 10), Vector2(-30, -70), Vector2(150, -10), Vector2(100, 76)]:
		_objeto(w, "objetos", 3, c + p)
	for p in [Vector2(-70, 20), Vector2(84, 10), Vector2(-40, 74)]:
		_objeto(w, "objetos", 4, c + p)
	for p in [Vector2(-54, -26), Vector2(56, -30), Vector2(30, 70), Vector2(-120, 70)]:
		_objeto(w, "objetos", 5, c + p)
	cam.position = c + Vector2(0, 10)
	await esperar(0.4)
	await salvar_print("piloto_simples/acampamento.png")

	# Praia: a primeira grama vindo da esquerda, na linha do meio da ilha.
	var x := 0
	while w.tipo_do_chao(Vector2i(x, w.altura / 2)) != World.Chao.GRAMA:
		x += 1
	var b := Vector2(x * World.T, c.y)
	for p in [Vector2(60, -50), Vector2(90, 30), Vector2(120, -10)]:
		_objeto(w, "objetos", 2, b + p)
	for p in [Vector2(40, 60), Vector2(140, 60)]:
		_objeto(w, "objetos", 3, b + p)
	_objeto(w, "objetos", 4, b + Vector2(10, -20))
	_objeto(w, "objetos", 5, b + Vector2(70, 10))
	_objeto(w, "objetos", 0, b + Vector2(-6, 30))
	_objeto(w, "objetos", 1, b + Vector2(20, 24))
	cam.position = b + Vector2(80, 10)
	await esperar(0.4)
	await salvar_print("piloto_simples/praia.png")
	terminar()


## O shader do chão lê 6 blocos de 32x32: grama, grama com flores, terra, areia, água,
## grama lisa. Os blocos novos entram no lugar. O piloto não tem terra nem grama lisa:
## provisoriamente, são a cor principal da terra antiga e da grama nova, sem detalhe.
func _trocar_chao(w: World) -> void:
	var novo := _imagem("chao")
	var velho := World.TEX_CHAO.get_image()
	velho.convert(Image.FORMAT_RGBA8)
	var img := Image.create(192, 32, false, Image.FORMAT_RGBA8)
	for i in 6:
		var bloco: int = [0, 0, -1, 1, 2, -1][i]
		if bloco >= 0:
			img.blit_rect(novo, Rect2i(bloco * 32, 0, 32, 32), Vector2i(i * 32, 0))
	img.fill_rect(Rect2i(2 * 32, 0, 32, 32), _cor_principal(velho, 2))
	img.fill_rect(Rect2i(5 * 32, 0, 32, 32), _cor_principal(novo, 0))
	(w.chao_suave.material as ShaderMaterial).set_shader_parameter(&"chao_tex", ImageTexture.create_from_image(img))


func _cor_principal(img: Image, bloco: int) -> Color:
	var conta := {}
	for y in 32:
		for x in 32:
			var c := img.get_pixel(bloco * 32 + x, y).to_rgba32()
			conta[c] = conta.get(c, 0) + 1
	var melhor: int = conta.keys()[0]
	for c in conta:
		if conta[c] > conta[melhor]:
			melhor = c
	return Color.hex(melhor)


var _cache := {}


func _imagem(folha: String) -> Image:
	if not _cache.has(folha):
		var img := Image.load_from_file(pasta.path_join(folha + ".png"))
		img.convert(Image.FORMAT_RGBA8)
		_cache[folha] = img
	return _cache[folha]


func _objeto(w: World, folha: String, i: int, pos: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(_imagem(folha))
	s.region_enabled = true
	s.region_rect = Rect2(i * 32, 0, 32, 32)
	s.centered = false
	s.offset = Vector2(-16, -32)
	s.position = pos.round()
	w.entidades.add_child(s)
