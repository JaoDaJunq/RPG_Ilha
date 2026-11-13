class_name PainelLore
extends Control
## O painel de uma pedra de lore: uma imagem e uma frase curta, sem textão. Fecha com
## clique, E, espaço ou Esc. A imagem final é lore_1..5.png (ArteBrasinha.lore); sem ela,
## o painel mostra só o título e a frase.

var _titulo: Label
var _imagem: TextureRect
var _frase: Label
var regiao := -1


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.6)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override(&"panel", Tema.papel_claro())
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override(&"separation", 8)
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(coluna)
	_titulo = Label.new()
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.add_theme_font_override(&"font", Tema.fonte_negrito())
	_titulo.add_theme_font_size_override(&"font_size", 22)
	_titulo.add_theme_color_override(&"font_color", Color("3b2a1e"))
	coluna.add_child(_titulo)
	_imagem = TextureRect.new()
	_imagem.custom_minimum_size = Vector2(320, 240)
	_imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_imagem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_imagem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(_imagem)
	_frase = Label.new()
	_frase.custom_minimum_size = Vector2(320, 0)
	_frase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_frase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_frase.add_theme_color_override(&"font_color", Color("3b2a1e"))
	_frase.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(_frase)
	var dica := Label.new()
	dica.text = "clique para fechar"
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dica.add_theme_font_size_override(&"font_size", 10)
	dica.add_theme_color_override(&"font_color", Color(0.23, 0.16, 0.12, 0.6))
	dica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(dica)


func configurar(m: Missoes) -> void:
	m.lore_aberta.connect(abrir)


func abrir(r: int) -> void:
	regiao = r
	_titulo.text = String(FalasBrasinha.LORE_TITULO.get(r, ""))
	_frase.text = String(FalasBrasinha.LORE.get(r, ""))
	var tex := ArteBrasinha.lore(r)
	_imagem.texture = tex
	_imagem.visible = tex != null
	visible = true


func fechar() -> void:
	visible = false


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"interagir") or event.is_action_pressed(&"habilidade_4") \
			or event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"ui_cancel"):
		fechar()
		get_viewport().set_input_as_handled()
