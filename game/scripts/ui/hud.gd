class_name Hud
extends CanvasLayer
## Interface: recursos, vida, barra de habilidades, avisos e o aviso de interação
## que aparece em cima do objeto sob o mouse.

const ITENS: Array[StringName] = [&"madeira", &"pedra", &"carvao"]
const ICONE_FOGO := preload("res://assets/placeholder/ninja/ui/icone_bola_de_fogo.png")
const COR_FUNDO := Color(0.07, 0.13, 0.13, 0.9)
const COR_BORDA := Color("947c50")
const COR_TEXTO := Color("f2e7c6")
const COR_TEXTO_2 := Color("b6ccaf")

var jogador: Player
var _contagens: Dictionary[StringName, Label] = {}
var _barra_vida: ProgressBar
var _aviso: Label
var _aviso_tempo := 0.0
var _dica: PanelContainer
var _dica_texto: Label
var _dica_progresso: ProgressBar
var _recarga_fogo: ColorRect


func _ready() -> void:
	layer = 10
	Events.aviso.connect(mostrar_aviso)
	_montar()


func configurar(p: Player) -> void:
	jogador = p
	jogador.inventario.mudou.connect(_atualizar_itens)
	jogador.vida.mudou.connect(func(atual: float, maximo: float) -> void: _barra_vida.value = atual / maximo * 100.0)
	_atualizar_itens()


func mostrar_aviso(texto: String) -> void:
	_aviso.text = texto
	_aviso.modulate.a = 1.0
	_aviso_tempo = 4.0


func texto_aviso() -> String:
	return _aviso.text


func _process(delta: float) -> void:
	_aviso_tempo -= delta
	if _aviso_tempo < 1.0:
		_aviso.modulate.a = clampf(_aviso_tempo, 0.0, 1.0)
	if jogador == null:
		return
	_recarga_fogo.anchor_top = 1.0 - jogador.recarga_fogo_restante()
	_atualizar_dica()


func _atualizar_dica() -> void:
	var alvo := jogador.alvo
	if alvo == null or not is_instance_valid(alvo):
		_dica.visible = false
		return
	_dica.visible = true
	if jogador.alvo_ao_alcance():
		_dica_texto.text = "SEGURE E  ·  " + alvo.dono().texto_acao().to_upper()
		_dica_progresso.visible = jogador.progresso_interacao() > 0.0
		_dica_progresso.value = jogador.progresso_interacao() * 100.0
	else:
		_dica_texto.text = "CHEGUE MAIS PERTO"
		_dica_progresso.visible = false
	var tela := get_viewport().get_canvas_transform() * (alvo.global_position + Vector2(0, -52))
	_dica.position = (tela - Vector2(_dica.size.x / 2.0, _dica.size.y)).round()


func _atualizar_itens() -> void:
	for id in _contagens:
		_contagens[id].text = str(jogador.inventario.quantidade_de(id))


# --- Montagem da interface -------------------------------------------------------

func _montar() -> void:
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)

	# Título (cima-esquerda)
	var titulo := _painel(raiz)
	titulo.position = Vector2(16, 14)
	var tv := VBoxContainer.new()
	titulo.add_child(tv)
	tv.add_child(_rotulo("ILHA VIVA", 20, COR_TEXTO))
	tv.add_child(_rotulo("Fundação · protótipo", 13, COR_TEXTO_2))

	# Recursos e vida (cima-direita)
	var recursos := _painel(raiz)
	recursos.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	recursos.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	var rv := VBoxContainer.new()
	recursos.add_child(rv)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override(&"separation", 14)
	rv.add_child(linha)
	for id in ITENS:
		var dados := ItemData.carregar(id)
		var icone := TextureRect.new()
		icone.texture = dados.icone
		icone.modulate = dados.cor_icone
		icone.custom_minimum_size = Vector2(32, 32)
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.tooltip_text = dados.nome
		linha.add_child(icone)
		var n := _rotulo("0", 20, COR_TEXTO)
		linha.add_child(n)
		_contagens[id] = n
	_barra_vida = ProgressBar.new()
	_barra_vida.custom_minimum_size = Vector2(0, 12)
	_barra_vida.show_percentage = false
	_barra_vida.value = 100.0
	_barra_vida.add_theme_stylebox_override(&"background", _caixa(Color("473e36"), Color.TRANSPARENT, 0))
	_barra_vida.add_theme_stylebox_override(&"fill", _caixa(Color("d0564a"), Color.TRANSPARENT, 0))
	rv.add_child(_barra_vida)

	# Barra de baixo: avisos, controles e habilidades
	var base := PanelContainer.new()
	base.add_theme_stylebox_override(&"panel", _caixa(Color("172b29"), Color("b49b66"), 0, 3))
	base.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	base.grow_vertical = Control.GROW_DIRECTION_BEGIN
	base.custom_minimum_size = Vector2(0, 84)
	raiz.add_child(base)
	var bh := HBoxContainer.new()
	base.add_child(bh)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	bh.add_child(textos)
	_aviso = _rotulo("", 17, COR_TEXTO)
	textos.add_child(_aviso)
	textos.add_child(_rotulo("WASD mover  ·  segure E coletar  ·  clique golpear  ·  1 bola de fogo  ·  N dia/noite  ·  M som", 14, COR_TEXTO_2))
	var barra := HBoxContainer.new()
	barra.alignment = BoxContainer.ALIGNMENT_CENTER
	barra.add_theme_constant_override(&"separation", 8)
	bh.add_child(barra)
	for i in 6:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(52, 52)
		slot.add_theme_stylebox_override(&"panel", _caixa(Color("354640"), Color("9c885e"), 2))
		barra.add_child(slot)
		if i == 0:
			var ic := TextureRect.new()
			ic.texture = ICONE_FOGO
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			slot.add_child(ic)
			var sombra := Control.new()
			slot.add_child(sombra)
			_recarga_fogo = ColorRect.new()
			_recarga_fogo.color = Color(0, 0, 0, 0.55)
			_recarga_fogo.set_anchors_preset(Control.PRESET_FULL_RECT)
			_recarga_fogo.anchor_top = 1.0
			sombra.add_child(_recarga_fogo)
		var num := _rotulo(str(i + 1), 12, COR_TEXTO_2)
		num.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		num.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		slot.add_child(num)
	var folga := Control.new()
	folga.custom_minimum_size = Vector2(8, 0)
	bh.add_child(folga)

	# Dica de interação (segue o objeto sob o mouse)
	_dica = PanelContainer.new()
	_dica.add_theme_stylebox_override(&"panel", _caixa(Color("223b35"), Color("d1b67d"), 2))
	_dica.visible = false
	_dica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(_dica)
	var dv := VBoxContainer.new()
	_dica.add_child(dv)
	_dica_texto = _rotulo("", 14, COR_TEXTO)
	_dica_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dv.add_child(_dica_texto)
	_dica_progresso = ProgressBar.new()
	_dica_progresso.custom_minimum_size = Vector2(0, 5)
	_dica_progresso.show_percentage = false
	_dica_progresso.add_theme_stylebox_override(&"background", _caixa(Color("473e36"), Color.TRANSPARENT, 0))
	_dica_progresso.add_theme_stylebox_override(&"fill", _caixa(Color("e7b36e"), Color.TRANSPARENT, 0))
	dv.add_child(_dica_progresso)


func _painel(pai: Control) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override(&"panel", _caixa(COR_FUNDO, COR_BORDA, 2))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(p)
	return p


func _rotulo(texto: String, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override(&"font_size", tamanho)
	l.add_theme_color_override(&"font_color", cor)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _caixa(fundo: Color, borda: Color, largura_borda: int, borda_cima := -1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.border_color = borda
	s.set_border_width_all(largura_borda)
	if borda_cima >= 0:
		s.border_width_top = borda_cima
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s
