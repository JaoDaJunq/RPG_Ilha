extends Node2D
## Laboratório isolado. Usa os candidatos L07, sem alterar cenas ou saves do jogo.
var jogador: Sprite2D
var atores: Node2D
var quadros: Array[Texture2D] = []
var raca := 0
var direcao := 0
var noite := false
var captura := false

func folha(nome: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path("res://assets/" + nome))
	assert(img != null, "Imagem ausente: " + nome)
	img.convert(Image.FORMAT_RGBA8)
	return img

func recorte(img: Image, area: Rect2i, altura: int) -> Texture2D:
	var parte := img.get_region(area)
	for y in parte.get_height():
		for x in parte.get_width():
			var cor := parte.get_pixel(x, y)
			if cor.r > 0.55 and cor.b > 0.55 and cor.g < 0.45:
				parte.set_pixel(x, y, Color.TRANSPARENT)
	var limites := parte.get_used_rect()
	assert(limites.has_area(), "Recorte vazio")
	parte = parte.get_region(limites)
	parte.resize(maxi(1, roundi(float(parte.get_width()) * altura / parte.get_height())), altura, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(parte)

func objeto(tex: Texture2D, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.position = pos
	s.offset.y = -tex.get_height() / 2.0
	atores.add_child(s)
	return s

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var fundo := Sprite2D.new()
	var terreno := folha("terreno_v2.png")
	terreno.resize(1280, 854, Image.INTERPOLATE_NEAREST)
	fundo.texture = ImageTexture.create_from_image(terreno)
	fundo.centered = false
	add_child(fundo)
	atores = Node2D.new()
	atores.y_sort_enabled = true
	add_child(atores)
	var personagens := folha("personagens_v2.png")
	for linha in 2:
		for coluna in 3:
			quadros.append(recorte(personagens, Rect2i(coluna * 512, linha * 512, 512, 512), 72))
	var natureza := folha("natureza_v1.png")
	# As árvores ultrapassam y512: recortes medidos visualmente, sem cortar o tronco.
	var arvore := recorte(natureza, Rect2i(0, 0, 512, 640), 230)
	var cortada := recorte(natureza, Rect2i(512, 0, 512, 640), 230)
	var queimada := recorte(natureza, Rect2i(1024, 0, 512, 640), 230)
	var toco := recorte(natureza, Rect2i(0, 640, 512, 384), 65)
	var pedra := recorte(natureza, Rect2i(512, 640, 512, 384), 80)
	var rachada := recorte(natureza, Rect2i(1024, 640, 512, 384), 80)
	for p in [Vector2(130, 300), Vector2(340, 240), Vector2(180, 650)]:
		objeto(arvore, p)
	objeto(cortada, Vector2(550, 260))
	objeto(queimada, Vector2(740, 270))
	objeto(toco, Vector2(310, 540))
	objeto(pedra, Vector2(760, 490))
	objeto(rachada, Vector2(650, 630))
	objeto(quadros[5], Vector2(590, 420))
	jogador = objeto(quadros[0], Vector2(475, 425))
	var hud := CanvasLayer.new()
	add_child(hud)
	var texto := Label.new()
	texto.text = "ILHA VIVA · laboratório visual C02\nWASD: mover  |  Tab: mago/ogro  |  N: iluminação  |  Esc: sair\nSprites parados · estudo de escala e sobreposição · sem combate"
	texto.position = Vector2(18, 14)
	texto.add_theme_color_override("font_shadow_color", Color.BLACK)
	texto.add_theme_constant_override("shadow_offset_x", 2)
	texto.add_theme_constant_override("shadow_offset_y", 2)
	hud.add_child(texto)
	if "--capturar" in OS.get_cmdline_user_args():
		captura = true
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var destino := ProjectSettings.globalize_path("res://../../evidence/piloto_c02/dia.png")
		DirAccess.make_dir_recursive_absolute(destino.get_base_dir())
		var erro := get_viewport().get_texture().get_image().save_png(destino)
		print("CAPTURA ", destino, " ", error_string(erro))
		get_tree().quit(erro)

func _process(delta: float) -> void:
	if jogador == null or captura:
		return
	var v := Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	if v != Vector2.ZERO:
		jogador.position += v.normalized() * 180 * delta
		jogador.position = jogador.position.clamp(Vector2(40, 130), Vector2(880, 700))
		if v.x != 0:
			direcao = 2
			jogador.flip_h = v.x < 0
		else:
			direcao = 1 if v.y < 0 else 0
			jogador.flip_h = false
		jogador.texture = quadros[raca * 3 + direcao]
		jogador.offset.y = -jogador.texture.get_height() / 2.0

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.keycode == KEY_ESCAPE:
		get_tree().quit()
	elif event.keycode == KEY_TAB:
		raca = 1 - raca
		jogador.texture = quadros[raca * 3 + direcao]
	elif event.keycode == KEY_N:
		noite = not noite
		modulate = Color(0.48, 0.55, 0.8) if noite else Color.WHITE
