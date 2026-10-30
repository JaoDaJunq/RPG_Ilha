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
	_tema = t
	return t


## Papel escuro com cantos dourados (9 partes: os cantos não esticam).
static func painel() -> StyleBoxTexture:
	return _caixa("Papers/SpecialPaper", Vector4(22, 18, 22, 18))


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


static func _caixa(nome: String, conteudo: Vector4, canto := 32) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = fatias(nome)
	s.set_texture_margin_all(canto)
	s.content_margin_left = conteudo.x
	s.content_margin_top = conteudo.y
	s.content_margin_right = conteudo.z
	s.content_margin_bottom = conteudo.w
	return s
