class_name Tema
extends RefCounted
## Tema da interface (arte L04): moldura de madeira e metal, botões, espaços da barra e
## contorno nos textos. A arte é ampliada por números inteiros, para os pixels ficarem nítidos.

const PASTA := "res://assets/sprites/interface/"
const COR_TEXTO := Color("f2e7c6")
const COR_TEXTO_2 := Color("b6ccaf")
const COR_DESTAQUE := Color("f0c860")
const COR_CONTORNO := Color(0.06, 0.08, 0.07)
## Ampliação da moldura dos painéis e dos botões.
const ESCALA := 2

static var _tema: Theme
static var _cache: Dictionary = {}


static func tema() -> Theme:
	if _tema:
		return _tema
	var t := Theme.new()
	# Fonte padrão do Godot (legível). A fonte pixel do pacote placeholder tinha o "i"
	# desenhado errado; uma fonte pixel própria fica para depois.
	t.default_font_size = 16
	t.set_color(&"font_color", &"Label", COR_TEXTO)
	t.set_color(&"font_outline_color", &"Label", COR_CONTORNO)
	t.set_constant(&"outline_size", &"Label", 4)

	t.set_stylebox(&"panel", &"PanelContainer", painel())
	t.set_stylebox(&"panel", &"Panel", painel())

	# Botões de madeira; o destacado é o do mouse em cima.
	var normal := _caixa("botao", 7, Vector4(18, 8, 18, 8))
	var destaque := _caixa("botao_destaque", 7, Vector4(18, 8, 18, 8))
	for tipo in [&"Button", &"OptionButton"]:
		t.set_stylebox(&"normal", tipo, normal)
		t.set_stylebox(&"hover", tipo, destaque)
		t.set_stylebox(&"pressed", tipo, destaque)
		t.set_stylebox(&"focus", tipo, StyleBoxEmpty.new())
		t.set_stylebox(&"disabled", tipo, normal)
		t.set_color(&"font_color", tipo, COR_TEXTO)
		t.set_color(&"font_hover_color", tipo, Color.WHITE)
		t.set_color(&"font_pressed_color", tipo, COR_DESTAQUE)
		t.set_color(&"font_outline_color", tipo, COR_CONTORNO)
		t.set_constant(&"outline_size", tipo, 4)
		t.set_font_size(&"font_size", tipo, 16)

	# Campo de texto (IP): fundo escuro do interior do painel com borda dourada.
	var campo := StyleBoxFlat.new()
	campo.bg_color = Color("1d3326")
	campo.border_color = Color("b48a3a")
	campo.set_border_width_all(2)
	campo.content_margin_left = 10
	campo.content_margin_right = 10
	t.set_stylebox(&"normal", &"LineEdit", campo)
	t.set_stylebox(&"focus", &"LineEdit", campo)
	t.set_color(&"font_color", &"LineEdit", COR_TEXTO)
	t.set_font_size(&"font_size", &"LineEdit", 16)

	# Lista do OptionButton e dicas do mouse.
	var lista := StyleBoxFlat.new()
	lista.bg_color = Color("1d3326")
	lista.border_color = Color("b48a3a")
	lista.set_border_width_all(2)
	lista.set_content_margin_all(6)
	t.set_stylebox(&"panel", &"PopupMenu", lista)
	t.set_stylebox(&"panel", &"TooltipPanel", lista)
	t.set_color(&"font_color", &"PopupMenu", COR_TEXTO)
	t.set_color(&"font_hover_color", &"PopupMenu", COR_DESTAQUE)
	t.set_color(&"font_color", &"TooltipLabel", COR_TEXTO)
	_tema = t
	return t


## Moldura dos painéis (9 partes: os cantos enfeitados não esticam).
static func painel() -> StyleBoxTexture:
	return _caixa("painel", 11, Vector4(24, 22, 24, 22))


## Textura ampliada `vezes` (vizinho mais próximo), guardada para não refazer.
static func ampliada(nome: String, vezes := ESCALA) -> Texture2D:
	var chave := "%s@%d" % [nome, vezes]
	if _cache.has(chave):
		return _cache[chave]
	var img := (load(PASTA + nome + ".png") as Texture2D).get_image()
	img.resize(img.get_width() * vezes, img.get_height() * vezes, Image.INTERPOLATE_NEAREST)
	var tex := ImageTexture.create_from_image(img)
	_cache[chave] = tex
	return tex


static func _caixa(nome: String, margem: int, conteudo: Vector4) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = ampliada(nome)
	s.set_texture_margin_all(margem * ESCALA)  # margem em pixels da arte
	s.content_margin_left = conteudo.x
	s.content_margin_top = conteudo.y
	s.content_margin_right = conteudo.z
	s.content_margin_bottom = conteudo.w
	return s
