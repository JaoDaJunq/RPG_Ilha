class_name Mapa
extends Control
## O mapa da ilha (tecla M). Mostra a ilha de cima com as regiões, o acampamento e os
## jogadores. O que o grupo ainda não viu fica coberto pelo papel e vai aparecendo ao andar
## (World.mapa_revelado, salvo com o mundo).
##
## A imagem da ilha é uma "foto" do próprio mundo, tirada uma vez por uma SubViewport que
## enxerga o mesmo canvas, reduzida 4 vezes (a arte de verdade, só que pequena). Sem tela
## (testes --headless) fica um desenho simples com a cor de cada região.

const ESCALA := 0.25  # 1 px do mapa = 4 px do mundo
const SHADER := preload("res://shaders/mapa_neblina.gdshader")
const TEX_ACAMPAMENTO := preload("res://assets/sprites/tiny/acampamento.png")
const COR_AGUA := Color("4fa4b8")
const COR_AREIA := Color("d8c38c")

var w: World
var _area: Control
var _foto: TextureRect
var _mascara: ImageTexture
var _marcas: Control
var _fogueira: TextureRect
var _rotulos: Array = []  # [Label, posição no mundo]
var _jogadores: Dictionary = {}  # Player → TextureRect
var _rodape: Label
var _alfinete: Label
var _mascara_suja := true
var foto_tirada := false


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	w = get_tree().get_first_node_in_group(&"mundo")
	if w == null:
		return
	var fundo := ColorRect.new()  # escurece o jogo atrás (interface)
	fundo.color = Color(0, 0, 0, 0.55)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override(&"panel", Tema.papel_claro())
	centro.add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override(&"separation", 6)
	painel.add_child(coluna)
	var titulo := Label.new()
	titulo.text = "Mapa da ilha"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_override(&"font", Tema.fonte_negrito())
	titulo.add_theme_font_size_override(&"font_size", 22)
	titulo.add_theme_color_override(&"font_color", Color("3b2a1e"))
	coluna.add_child(titulo)

	var tamanho := Vector2(w.largura * World.T, w.altura * World.T) * ESCALA
	_area = Control.new()
	_area.custom_minimum_size = tamanho
	_area.clip_contents = true
	coluna.add_child(_area)
	_foto = TextureRect.new()
	_foto.size = tamanho
	_foto.stretch_mode = TextureRect.STRETCH_SCALE
	_foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_foto.texture = _desenho_simples()
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	_foto.material = mat
	_area.add_child(_foto)
	_marcas = Control.new()
	_marcas.size = tamanho
	_marcas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_area.add_child(_marcas)

	# Nomes das regiões, no meio de cada uma (só aparecem depois de vistos).
	for r in Regioes.TODAS:
		var soma := Vector2.ZERO
		var n := 0
		for cel in w.celulas_da_regiao(r, true):
			soma += Vector2(cel)
			n += 1
		if n == 0:
			continue
		var l := Label.new()
		l.text = Regioes.nome(r)
		l.add_theme_font_override(&"font", Tema.fonte_negrito())
		l.add_theme_font_size_override(&"font_size", 15)
		l.add_theme_color_override(&"font_color", Color("fff4dc"))
		l.add_theme_color_override(&"font_outline_color", Color("2a1a14"))
		l.add_theme_constant_override(&"outline_size", 5)
		_marcas.add_child(l)
		_rotulos.append([l, (soma / n + Vector2(0.5, 0.5)) * World.T])
	# O acampamento (a fogueira da folha do acampamento).
	_fogueira = _icone(_atlas(TEX_ACAMPAMENTO, Rect2(0, 0, 128, 128)), Vector2(30, 30))
	_marcas.add_child(_fogueira)
	# Alfinete da missão do Brasinha: aponta a região do objetivo (letra de interface).
	_alfinete = Label.new()
	_alfinete.text = "!"
	_alfinete.add_theme_font_override(&"font", Tema.fonte_negrito())
	_alfinete.add_theme_font_size_override(&"font_size", 22)
	_alfinete.add_theme_color_override(&"font_color", Color("f3c53a"))
	_alfinete.add_theme_color_override(&"font_outline_color", Color("2a1a14"))
	_alfinete.add_theme_constant_override(&"outline_size", 6)
	_alfinete.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marcas.add_child(_alfinete)
	_rodape = Label.new()
	_rodape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rodape.add_theme_color_override(&"font_color", Color("3b2a1e"))
	coluna.add_child(_rodape)
	w.mapa_mudou.connect(func() -> void: _mascara_suja = true)


func alternar() -> void:
	if visible:
		fechar()
	else:
		abrir()


func abrir() -> void:
	if w == null:
		return
	visible = true
	if not foto_tirada:
		tirar_foto()
	_atualizar()


func fechar() -> void:
	visible = false


func _process(_delta: float) -> void:
	if visible:
		_atualizar()


func _atualizar() -> void:
	if _mascara_suja:
		_mascara_suja = false
		var dados := w.mapa_revelado.duplicate()
		for i in dados.size():
			dados[i] = 255 if dados[i] != 0 else 0
		var img := Image.create_from_data(World.MAPA_L, World.MAPA_A, false, Image.FORMAT_L8, dados)
		if _mascara == null:
			_mascara = ImageTexture.create_from_image(img)
			(_foto.material as ShaderMaterial).set_shader_parameter(&"revelado", _mascara)
		else:
			_mascara.update(img)
	for r in _rotulos:
		var l: Label = r[0]
		var pos: Vector2 = r[1]
		l.visible = _visto(pos)
		l.position = pos * ESCALA - l.size / 2.0
	_fogueira.position = w.centro * ESCALA - _fogueira.size / 2.0 + Vector2(0, -6)
	_fogueira.visible = _visto(w.centro)
	if _alfinete and w.missoes:
		_alfinete.visible = true
		_alfinete.position = w.missoes.posicao_do_objetivo() * ESCALA - Vector2(_alfinete.size.x / 2.0, _alfinete.size.y + 2.0)
	# Jogadores (todos; o daqui fica por cima).
	for j in get_tree().get_nodes_in_group(&"jogadores"):
		var p := j as Player
		if not _jogadores.has(p):
			var ic := _icone(Boneco.retrato(p.aparencia_completa(), p.equipado), Vector2(30, 30))
			_marcas.add_child(ic)
			_jogadores[p] = ic
		var icone: TextureRect = _jogadores[p]
		icone.position = p.global_position * ESCALA - icone.size / 2.0 + Vector2(0, -8)
		if p == w.jogador:
			_marcas.move_child(icone, -1)
	for p in _jogadores.keys():
		if not is_instance_valid(p):
			(_jogadores[p] as Node).queue_free()
			_jogadores.erase(p)
	var aqui := Regioes.nome(w.regiao_em(w.jogador.global_position)) if w.jogador else ""
	_rodape.text = "Você está em: %s    ·    %d%% da ilha explorada    ·    M fecha" % [aqui, roundi(w.fracao_revelada() * 100.0)]


func _visto(pos: Vector2) -> bool:
	return w.revelado(Vector2i((pos / (World.T * World.MAPA_BLOCO)).floor()))


func _icone(tex: Texture2D, tam: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = tam
	t.size = tam
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


static func _atlas(tex: Texture2D, regiao: Rect2) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = regiao
	return a


## Sem tela: a ilha pintada com a cor de cada região (1 px por bloco).
func _desenho_simples() -> Texture2D:
	var img := Image.create(w.largura, w.altura, false, Image.FORMAT_RGBA8)
	for y in w.altura:
		for x in w.largura:
			var i := y * w.largura + x
			var cor: Color = COR_AGUA
			if w.gerador.tipo[i] != World.Chao.AGUA:
				cor = COR_AREIA if w.gerador.tipo[i] == World.Chao.AREIA else Regioes.COR_MAPA[w.gerador.regiao[i]]
			img.set_pixel(x, y, cor)
	return ImageTexture.create_from_image(img)


## Tira a "foto" da ilha: uma SubViewport que olha o mesmo canvas do mundo, de dia,
## reduzida. Uma vez só (a ilha não muda de forma).
func tirar_foto() -> void:
	if DisplayServer.get_name() == "headless" or foto_tirada:
		return
	foto_tirada = true
	var tamanho := Vector2i(Vector2(w.largura * World.T, w.altura * World.T) * ESCALA)
	var vp := SubViewport.new()
	vp.size = tamanho
	vp.world_2d = get_viewport().world_2d
	vp.canvas_transform = Transform2D.IDENTITY.scaled(Vector2(ESCALA, ESCALA))
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.transparent_bg = false
	w.add_child(vp)
	var cor := w.ambiente.color
	w.ambiente.color = World.COR_DIA  # a foto é sempre de dia
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	w.ambiente.color = cor
	vp.queue_free()
	if img and not img.is_empty():
		_foto.texture = ImageTexture.create_from_image(img)
