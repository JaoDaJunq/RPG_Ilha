extends TesteBase
## Vitrine para aprovar arte nova DENTRO do jogo, antes de integrar de verdade.
## Lê as folhas já convertidas de uma pasta (--pasta=...) e coloca tudo na ilha, ao lado
## das árvores e do aventureiro atual; monta também um painel de teste com a interface nova.
## Salva evidence/vitrine/<nome>.png. Precisa de janela.

const FONTE := preload("res://assets/placeholder/ninja/fonte/fonte_pixel.ttf")

var pasta := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--pasta="):
			pasta = a.get_slice("=", 1)
	var w := await criar_mundo(0, false, &"guerreiro")
	var p := w.jogador
	var ancora := w.centro + Vector2(10, 78)
	p.global_position = ancora + Vector2(150, 0)
	var cam := Camera2D.new()
	cam.zoom = Vector2(3, 3)
	cam.position = ancora + Vector2(0, -6)
	w.add_child(cam)
	cam.make_current()
	_limpar_em_volta(w, ancora, 190.0)

	# Chão novo: blocos de 32x32 repetidos 2x2, por baixo de tudo.
	var chao := Node2D.new()
	w.add_child(chao)
	w.move_child(chao, w.chao.get_index() + 1)
	for i in 6:
		for dy in 2:
			for dx in 2:
				_quadro(chao, "chao", i, Vector2i(32, 32), ancora + Vector2(-205 + i * 70 + dx * 32, 52 + dy * 32), false)

	# Personagens novos (6) e o aventureiro atual à direita, para comparar.
	for i in 6:
		_quadro(w.entidades, "personagens", i, Vector2i(40, 40), ancora + Vector2(-130 + i * 40, 0))
	# Slime (5 poses) e armadilha (armada, fechando, fechada, gasta).
	for i in 5:
		_quadro(w.entidades, "slime", i, Vector2i(32, 32), ancora + Vector2(-190 + i * 26, 40))
	for i in 4:
		_quadro(w.entidades, "armadilha", i, Vector2i(40, 40), ancora + Vector2(-50 + i * 40, 40))
	# Plantas e acampamento.
	for i in 6:
		_quadro(w.entidades, "plantas", i, Vector2i(32, 32), ancora + Vector2(110 + (i % 3) * 30, 30 + (i / 3) * 24))
	for i in 6:
		_quadro(w.entidades, "acampamento", i, Vector2i(64, 64), ancora + Vector2(-175 + i * 58, -46))

	_painel_de_teste(w, ancora)
	await esperar(0.4)
	await salvar_print("vitrine/l02_l03_l04.png")
	terminar()


func _limpar_em_volta(w: World, centro: Vector2, raio: float) -> void:
	for n in w.entidades.get_children():
		if (n is ResourceNode or n is Sprite2D) and (n as Node2D).global_position.distance_to(centro) < raio:
			n.queue_free()


func _quadro(pai: Node, folha: String, i: int, tamanho: Vector2i, pos: Vector2, base_no_chao := true) -> Sprite2D:
	var img := Image.load_from_file(pasta.path_join(folha + ".png"))
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.region_enabled = true
	s.region_rect = Rect2(Vector2(i * tamanho.x, 0), tamanho)
	s.centered = false
	s.offset = Vector2(-tamanho.x / 2.0, -tamanho.y) if base_no_chao else Vector2.ZERO
	s.position = pos
	pai.add_child(s)
	return s


## Painel tipo "ficha" com a moldura, os ícones, os espaços e a tecla E novos.
func _painel_de_teste(w: World, ancora: Vector2) -> void:
	var camada := CanvasLayer.new()
	camada.layer = 20
	w.add_child(camada)
	var interface := ImageTexture.create_from_image(Image.load_from_file(pasta.path_join("interface.png")))
	var icones := ImageTexture.create_from_image(Image.load_from_file(pasta.path_join("icones.png")))

	var painel := NinePatchRect.new()
	painel.texture = _recorte(interface, Rect2(0, 0, 64, 64))
	painel.patch_margin_left = 16
	painel.patch_margin_top = 16
	painel.patch_margin_right = 16
	painel.patch_margin_bottom = 16
	painel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	painel.position = Vector2(16, 16)
	painel.size = Vector2(170, 124)
	painel.scale = Vector2(2, 2)
	camada.add_child(painel)
	var tema := Theme.new()
	tema.default_font = FONTE
	tema.default_font_size = 8
	var col := VBoxContainer.new()
	col.theme = tema
	col.position = Vector2(16, 16)
	col.add_theme_constant_override(&"separation", 1)
	painel.add_child(col)
	var titulo := Label.new()
	titulo.text = "OGRO GUERREIRO · NÍVEL 3"
	titulo.add_theme_color_override(&"font_color", Color("f2e7c6"))
	col.add_child(titulo)
	var nomes := ["Força 9", "Vitalidade 8", "Agilidade 5", "Intelecto 2", "Espírito 3"]
	for i in 5:
		var linha := HBoxContainer.new()
		col.add_child(linha)
		var ic := TextureRect.new()
		ic.texture = _recorte(icones, Rect2(i * 16, 0, 16, 16))
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		linha.add_child(ic)
		var l := Label.new()
		l.text = nomes[i]
		l.add_theme_color_override(&"font_color", Color("f2e7c6"))
		linha.add_child(l)

	# Barra de espaços (slot normal e selecionado) e botões.
	for i in 6:
		var slot := TextureRect.new()
		slot.texture = _recorte(interface, Rect2((4 if i == 0 else 3) * 64, 0, 64, 64))
		slot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		slot.position = Vector2(820 + i * 70, 620)
		slot.scale = Vector2(1.5, 1.5)
		camada.add_child(slot)
	for i in 2:
		var botao := TextureRect.new()
		botao.texture = _recorte(interface, Rect2((1 + i) * 64, 0, 64, 64))
		botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		botao.position = Vector2(400 + i * 210, 470)
		botao.scale = Vector2(3, 3)
		camada.add_child(botao)

	# Tecla E em cima da pedra/árvore mais próxima do personagem atual (no mundo).
	var tecla := Sprite2D.new()
	tecla.texture = _recorte(interface, Rect2(5 * 64, 0, 64, 64))
	tecla.scale = Vector2(0.35, 0.35)
	tecla.position = ancora + Vector2(150, -36)
	w.entidades.add_child(tecla)


func _recorte(tex: Texture2D, regiao: Rect2) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = regiao
	return a
