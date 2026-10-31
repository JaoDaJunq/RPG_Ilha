class_name Pecas
extends RefCounted
## Peças prontas dos menus (Home, mundos, configurações, pausa): botões do pacote que
## crescem de leve com o mouse e o teclado em cima, fita de título, painel e rótulos.


## Botão do menu. `variacao`: BotaoGrande, BotaoVermelho, BotaoPequeno ou BotaoPequenoVermelho.
## O mouse em cima passa o foco para ele (assim só um botão fica aceso, também no teclado).
static func botao(texto: String, variacao := &"BotaoGrande", largura := 0.0) -> Button:
	var b := Button.new()
	b.text = texto
	b.theme_type_variation = variacao
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var grande := variacao == &"BotaoGrande" or variacao == &"BotaoVermelho"
	b.custom_minimum_size = Vector2(largura, 64.0 if grande else 40.0)
	b.resized.connect(func() -> void: b.pivot_offset = b.size / 2.0)
	b.mouse_entered.connect(func() -> void:
		if not b.disabled:
			b.grab_focus())
	b.focus_entered.connect(func() -> void: _crescer(b, 1.04 if grande else 1.03))
	b.focus_exited.connect(func() -> void: _crescer(b, 1.0))
	b.pressed.connect(func() -> void: Sfx.tocar(&"item", -14.0))
	return b


static func _crescer(b: Control, escala: float) -> void:
	if not b.is_inside_tree():
		return
	var t := b.create_tween()
	t.tween_property(b, "scale", Vector2(escala, escala), 0.08)


static func rotulo(texto: String, tamanho := 18, cor := Tema.COR_TEXTO, centro := false) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override(&"font_size", tamanho)
	l.add_theme_color_override(&"font_color", cor)
	if centro:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## Rótulo de texto escuro para as listas de papel claro.
static func tinta(texto: String, tamanho := 18, negrito := false) -> Label:
	var l := Label.new()
	l.text = texto
	l.theme_type_variation = &"RotuloTinta"
	l.add_theme_font_size_override(&"font_size", tamanho)
	if negrito:
		l.add_theme_font_override(&"font", Tema.fonte_negrito())
	return l


## Fita do pacote com um título por cima. `fila`: ver Tema.fita.
static func fita(texto: String, fila := 2, escala := 0.75, tamanho := 34) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override(&"panel", Tema.fita(fila, escala))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Label.new()
	l.text = texto
	l.theme_type_variation = &"RotuloTitulo"
	l.add_theme_font_size_override(&"font_size", tamanho)
	l.add_theme_constant_override(&"outline_size", maxi(4, tamanho / 6))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Sai da dobra da ponta da fita para o texto ficar só no pano.
	var ponta := int(128 * escala * 0.62)
	l.add_theme_constant_override(&"line_spacing", 0)
	var margem := MarginContainer.new()
	margem.add_theme_constant_override(&"margin_left", ponta)
	margem.add_theme_constant_override(&"margin_right", ponta)
	margem.add_theme_constant_override(&"margin_top", int(128 * escala * 0.04))
	margem.add_theme_constant_override(&"margin_bottom", int(128 * escala * 0.10))
	margem.add_child(l)
	p.add_child(margem)
	return p


## Painel de papel escuro com cantos dourados e uma coluna dentro (`coluna_de(painel)`).
static func painel(largura := 0.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size.x = largura
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override(&"separation", 12)
	p.add_child(coluna)
	return p


static func coluna_de(painel_: PanelContainer) -> VBoxContainer:
	return painel_.get_child(0) as VBoxContainer
