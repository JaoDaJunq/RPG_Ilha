class_name Tema
extends RefCounted
## Tema da interface no estilo Tiny Swords: papel escuro com cantos dourados nos painéis,
## botões azuis, quadradinhos azuis na barra de habilidades e a barra de vida deles.
## As peças do pacote vêm em blocos de 64 px separados por espaços (cantos e meios em
## 0, 128 e 256); aqui elas são juntadas numa moldura contínua de 9 partes e reduzidas à
## metade (vizinho mais próximo), para os cantos não ficarem enormes no painel.

const PASTA := "res://assets/tiny_swords/ui/"
const COR_TEXTO := Color("f4ead2")
const COR_TEXTO_2 := Color("c9d3d6")
const COR_DESTAQUE := Color("f2c75c")
const COR_CONTORNO := Color(0.09, 0.09, 0.13)
## Fundo dos campos e listas: o cinza-azulado do miolo do papel escuro.
const COR_FUNDO := Color("454a57")
const COR_BORDA := Color("d9b864")

static var _tema: Theme
static var _cache: Dictionary = {}


static func tema() -> Theme:
	if _tema:
		return _tema
	var t := Theme.new()
	# Fonte padrão do Godot (legível). Uma fonte pixel própria fica para depois.
	t.default_font_size = 16
	t.set_color(&"font_color", &"Label", COR_TEXTO)
	t.set_color(&"font_outline_color", &"Label", COR_CONTORNO)
	t.set_constant(&"outline_size", &"Label", 4)

	t.set_stylebox(&"panel", &"PanelContainer", painel())
	t.set_stylebox(&"panel", &"Panel", painel())

	# Botões azuis do pacote; com o mouse em cima, um pouco mais claros.
	# Cantos do botão com 22 px (o desenho deles), para ele não achatar numa tira.
	var normal := _caixa("Buttons/BigBlueButton_Regular", Vector4(18, 12, 18, 16), 22)
	var destaque := _caixa("Buttons/BigBlueButton_Regular", Vector4(18, 12, 18, 16), 22)
	destaque.modulate_color = Color(1.18, 1.18, 1.18)
	var apertado := _caixa("Buttons/BigBlueButton_Pressed", Vector4(18, 16, 18, 12), 22)
	# A arte do botão tem uma sobra transparente em volta: desenha um pouco para fora.
	for caixa in [normal, destaque, apertado]:
		caixa.expand_margin_top = 8
		caixa.expand_margin_bottom = 6
		caixa.expand_margin_left = 6
		caixa.expand_margin_right = 6
	for tipo in [&"Button", &"OptionButton"]:
		t.set_stylebox(&"normal", tipo, normal)
		t.set_stylebox(&"hover", tipo, destaque)
		t.set_stylebox(&"pressed", tipo, apertado)
		t.set_stylebox(&"focus", tipo, StyleBoxEmpty.new())
		t.set_stylebox(&"disabled", tipo, normal)
		t.set_color(&"font_color", tipo, COR_TEXTO)
		t.set_color(&"font_hover_color", tipo, Color.WHITE)
		t.set_color(&"font_pressed_color", tipo, COR_DESTAQUE)
		t.set_color(&"font_outline_color", tipo, COR_CONTORNO)
		t.set_constant(&"outline_size", tipo, 4)
		t.set_font_size(&"font_size", tipo, 16)

	_variacoes_de_botao(t)

	# Campo de texto (IP), lista do OptionButton e dicas do mouse.
	var campo := StyleBoxFlat.new()
	campo.bg_color = COR_FUNDO
	campo.border_color = COR_BORDA
	campo.set_border_width_all(2)
	campo.set_corner_radius_all(3)
	campo.content_margin_left = 10
	campo.content_margin_right = 10
	t.set_stylebox(&"normal", &"LineEdit", campo)
	t.set_stylebox(&"focus", &"LineEdit", campo)
	t.set_color(&"font_color", &"LineEdit", COR_TEXTO)
	t.set_font_size(&"font_size", &"LineEdit", 16)
	var lista := campo.duplicate() as StyleBoxFlat
	lista.set_content_margin_all(6)
	t.set_stylebox(&"panel", &"PopupMenu", lista)
	t.set_stylebox(&"panel", &"TooltipPanel", lista)
	t.set_color(&"font_color", &"PopupMenu", COR_TEXTO)
	t.set_color(&"font_hover_color", &"PopupMenu", COR_DESTAQUE)
	t.set_color(&"font_color", &"TooltipLabel", COR_TEXTO)
	_barras_e_controles(t)
	_tema = t
	return t


## Papel escuro com cantos dourados (9 partes: os cantos não esticam).
static func painel() -> StyleBoxTexture:
	var s := _caixa("Papers/SpecialPaper", Vector4(22, 18, 22, 18))
	# O miolo do papel tem manchinhas: repetir em vez de esticar (esticadas viram borrões).
	s.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	s.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	return s


## Quadradinho azul de um espaço da barra de habilidades (peça única de 64 px).
static func espaco() -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = load(PASTA + "Buttons/TinySquareBlueButton.png")
	s.set_texture_margin_all(16)
	return s


## Moldura da barra de vida do pacote (3 partes, metade do tamanho). O miolo escuro fica a
## `inset` da borda: é ali que a cor da barra é pintada.
static func moldura_barra() -> StyleBoxTexture:
	var chave := "barra"
	if not _cache.has(chave):
		var img := (load(PASTA + "Bars/BigBar_Base.png") as Texture2D).get_image()
		img.convert(Image.FORMAT_RGBA8)
		var junta := Image.create(24 + 64 + 24, 51, false, Image.FORMAT_RGBA8)
		junta.blit_rect(img, Rect2i(40, 9, 24, 51), Vector2i(0, 0))
		junta.blit_rect(img, Rect2i(128, 9, 64, 51), Vector2i(24, 0))
		junta.blit_rect(img, Rect2i(256, 9, 24, 51), Vector2i(88, 0))
		junta.resize(junta.get_width() / 2, junta.get_height() / 2, Image.INTERPOLATE_NEAREST)
		_cache[chave] = ImageTexture.create_from_image(junta)
	var s := StyleBoxTexture.new()
	s.texture = _cache[chave]
	s.texture_margin_left = 12
	s.texture_margin_right = 12
	return s


## Peça de 9 partes do pacote (cantos e meios de 64 px em 0, 128 e 256), juntada e
## reduzida à metade.
static func fatias(nome: String) -> Texture2D:
	if _cache.has(nome):
		return _cache[nome]
	var img := (load(PASTA + nome + ".png") as Texture2D).get_image()
	img.convert(Image.FORMAT_RGBA8)
	var junta := Image.create(192, 192, false, Image.FORMAT_RGBA8)
	for j in 3:
		for i in 3:
			junta.blit_rect(img, Rect2i(i * 128, j * 128, 64, 64), Vector2i(i * 64, j * 64))
	junta.resize(96, 96, Image.INTERPOLATE_NEAREST)
	var tex := ImageTexture.create_from_image(junta)
	_cache[nome] = tex
	return tex


# --- Home e menus -----------------------------------------------------------------------

const COR_TINTA := Color("3d2a1a")  # texto escuro sobre o papel claro
const COR_FACIL := Color("3f7d3a")
const COR_NORMAL := Color("8a5f14")
const COR_DIFICIL := Color("a82f2f")
const COR_AVISO := Color("e7b36e")


## Botões do menu: BotaoGrande (azul, Jogar/Configurações), BotaoVermelho (Sair/Apagar),
## BotaoPequeno e BotaoPequenoVermelho (listas e formulários). Com o mouse em cima ou o
## teclado em cima (foco) ficam mais claros; apertados, afundam.
static func _variacoes_de_botao(t: Theme) -> void:
	var tamanhos := {
		&"BotaoGrande": [Vector4(30, 14, 30, 20), 30],
		&"BotaoVermelho": [Vector4(30, 14, 30, 20), 30],
		&"BotaoPequeno": [Vector4(18, 10, 18, 14), 18],
		&"BotaoPequenoVermelho": [Vector4(18, 10, 18, 14), 18],
	}
	for nome in tamanhos:
		var vermelho := String(nome).contains("Vermelho")
		var familia := "Buttons/BigRedButton_" if vermelho else "Buttons/BigBlueButton_"
		var margens: Vector4 = tamanhos[nome][0]
		var normal := _caixa(familia + "Regular", margens, 22)
		var destaque := _caixa(familia + "Regular", margens, 22)
		destaque.modulate_color = Color(1.2, 1.2, 1.2)
		var apertado := _caixa(familia + "Pressed", Vector4(margens.x, margens.y + 4, margens.z, margens.w - 4), 22)
		var desligado := _caixa(familia + "Regular", margens, 22)
		desligado.modulate_color = Color(0.55, 0.55, 0.6, 0.85)
		for caixa in [normal, destaque, apertado, desligado]:
			caixa.expand_margin_top = 8
			caixa.expand_margin_bottom = 6
			caixa.expand_margin_left = 6
			caixa.expand_margin_right = 6
		t.set_type_variation(nome, &"Button")
		t.set_stylebox(&"normal", nome, normal)
		t.set_stylebox(&"hover", nome, destaque)
		t.set_stylebox(&"focus", nome, destaque)
		t.set_stylebox(&"pressed", nome, apertado)
		t.set_stylebox(&"hover_pressed", nome, apertado)
		t.set_stylebox(&"disabled", nome, desligado)
		t.set_font_size(&"font_size", nome, tamanhos[nome][1])
		t.set_font(&"font", nome, fonte_negrito())
		t.set_color(&"font_color", nome, COR_TEXTO)
		t.set_color(&"font_focus_color", nome, Color.WHITE)
		t.set_color(&"font_hover_color", nome, Color.WHITE)
		t.set_color(&"font_pressed_color", nome, COR_DESTAQUE)
		t.set_color(&"font_hover_pressed_color", nome, COR_DESTAQUE)
		t.set_color(&"font_disabled_color", nome, Color(0.8, 0.8, 0.8, 0.7))
		t.set_color(&"font_outline_color", nome, COR_CONTORNO)
		t.set_constant(&"outline_size", nome, 5)
	# Título dentro da fita e rótulos de cabeçalho.
	t.set_type_variation(&"RotuloTitulo", &"Label")
	t.set_font(&"font", &"RotuloTitulo", fonte_negrito())
	t.set_color(&"font_color", &"RotuloTitulo", COR_TEXTO)
	t.set_color(&"font_outline_color", &"RotuloTitulo", COR_CONTORNO)
	t.set_constant(&"outline_size", &"RotuloTitulo", 10)
	# Texto escuro, para as listas de papel claro (sem contorno).
	t.set_type_variation(&"RotuloTinta", &"Label")
	t.set_color(&"font_color", &"RotuloTinta", COR_TINTA)
	t.set_constant(&"outline_size", &"RotuloTinta", 0)


## Barra de rolagem e controle de volume.
static func _barras_e_controles(t: Theme) -> void:
	var trilho := StyleBoxFlat.new()
	trilho.bg_color = Color(0.09, 0.09, 0.13, 0.55)
	trilho.set_corner_radius_all(5)
	trilho.content_margin_left = 10  # sem margem a barra de rolagem some (largura zero)
	trilho.content_margin_right = 10
	trilho.content_margin_top = 10
	trilho.content_margin_bottom = 10
	var alca := StyleBoxFlat.new()
	alca.bg_color = Color("c9a24f")
	alca.border_color = Color("f2dc9a")
	alca.set_border_width_all(1)
	alca.set_corner_radius_all(5)
	var alca_destaque := alca.duplicate() as StyleBoxFlat
	alca_destaque.bg_color = Color("e2bd62")
	for tipo in [&"VScrollBar", &"HScrollBar"]:
		t.set_stylebox(&"scroll", tipo, trilho)
		t.set_stylebox(&"scroll_focus", tipo, trilho)
		t.set_stylebox(&"grabber", tipo, alca)
		t.set_stylebox(&"grabber_highlight", tipo, alca_destaque)
		t.set_stylebox(&"grabber_pressed", tipo, alca_destaque)
	# Volume: trilho escuro, parte cheia dourada e a bolinha azul do pacote.
	var trilho_slider := StyleBoxFlat.new()
	trilho_slider.bg_color = Color(0.09, 0.09, 0.13, 0.7)
	trilho_slider.border_color = COR_BORDA
	trilho_slider.set_border_width_all(2)
	trilho_slider.set_corner_radius_all(6)
	trilho_slider.content_margin_top = 8
	trilho_slider.content_margin_bottom = 8
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = Color("c9a24f")
	cheio.set_corner_radius_all(6)
	cheio.content_margin_top = 8
	cheio.content_margin_bottom = 8
	t.set_stylebox(&"slider", &"HSlider", trilho_slider)
	t.set_stylebox(&"grabber_area", &"HSlider", cheio)
	t.set_stylebox(&"grabber_area_highlight", &"HSlider", cheio)
	var bolinha := bolinha_azul()
	t.set_icon(&"grabber", &"HSlider", bolinha)
	t.set_icon(&"grabber_highlight", &"HSlider", bolinha)
	t.set_icon(&"grabber_disabled", &"HSlider", bolinha)


## Bolinha azul do pacote (controle do volume), reduzida a 40 px.
static func bolinha_azul() -> Texture2D:
	if not _cache.has("bolinha"):
		var img := (load(PASTA + "Buttons/TinyRoundBlueButton.png") as Texture2D).get_image()
		img.convert(Image.FORMAT_RGBA8)
		img.resize(40, 40, Image.INTERPOLATE_NEAREST)
		_cache["bolinha"] = ImageTexture.create_from_image(img)
	return _cache["bolinha"]


## Negrito para os títulos e botões (a fonte padrão, engrossada).
static func fonte_negrito() -> Font:
	if not _cache.has("negrito"):
		var f := FontVariation.new()
		f.base_font = ThemeDB.fallback_font
		f.variation_embolden = 0.55
		_cache["negrito"] = f
	return _cache["negrito"]


## Papel claro (listas): como o painel, mas creme, para texto escuro.
static func papel_claro() -> StyleBoxTexture:
	var s := _caixa("Papers/RegularPaper", Vector4(16, 12, 16, 12), 20)
	s.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	s.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	return s


## Fita do pacote (cabeçalhos e título). `fila`: 0 azul, 1 vermelha, 2 amarela, 3 roxa, 4
## cinza. As pontas ficam como são e o meio estica; `escala` 1.0 é o tamanho original
## (128 px de altura) e 0.5 a metade (pixel inteiro, como o resto da interface).
static func fita(fila: int, escala := 0.5) -> StyleBoxTexture:
	var chave := "fita%d_%.2f" % [fila, escala]
	if not _cache.has(chave):
		var img := (load(PASTA + "Ribbons/BigRibbons.png") as Texture2D).get_image()
		img.convert(Image.FORMAT_RGBA8)
		var junta := Image.create(128 + 64 + 128, 128, false, Image.FORMAT_RGBA8)
		junta.blit_rect(img, Rect2i(0, fila * 128, 128, 128), Vector2i(0, 0))
		junta.blit_rect(img, Rect2i(192, fila * 128, 64, 128), Vector2i(128, 0))
		junta.blit_rect(img, Rect2i(320, fila * 128, 128, 128), Vector2i(192, 0))
		if escala != 1.0:
			junta.resize(int(320 * escala), int(128 * escala), Image.INTERPOLATE_NEAREST)
		_cache[chave] = ImageTexture.create_from_image(junta)
	var s := StyleBoxTexture.new()
	s.texture = _cache[chave]
	s.texture_margin_left = 128 * escala
	s.texture_margin_right = 128 * escala
	s.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	return s


static func _caixa(nome: String, conteudo: Vector4, canto := 32) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = fatias(nome)
	s.set_texture_margin_all(canto)
	s.content_margin_left = conteudo.x
	s.content_margin_top = conteudo.y
	s.content_margin_right = conteudo.z
	s.content_margin_bottom = conteudo.w
	return s
