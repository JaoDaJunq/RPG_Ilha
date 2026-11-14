class_name RastreadorMissao
extends PanelContainer
## O lembrete pequeno no canto da tela: o objetivo da missão atual do Brasinha.

var missoes: Missoes
var _titulo: Label
var _objetivo: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	offset_right = -12.0
	offset_left = -12.0
	offset_top = 10.0
	var coluna := VBoxContainer.new()
	coluna.custom_minimum_size = Vector2(210, 0)
	coluna.add_theme_constant_override(&"separation", 2)
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(coluna)
	_titulo = Label.new()
	_titulo.add_theme_font_override(&"font", Tema.fonte_negrito())
	_titulo.add_theme_font_size_override(&"font_size", 14)
	_titulo.add_theme_color_override(&"font_color", Tema.COR_TEXTO)
	_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(_titulo)
	_objetivo = Label.new()
	_objetivo.add_theme_font_size_override(&"font_size", 12)
	_objetivo.add_theme_color_override(&"font_color", Tema.COR_TEXTO_2)
	_objetivo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objetivo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(_objetivo)
	atualizar()


func configurar(m: Missoes) -> void:
	missoes = m
	m.mudou.connect(atualizar)
	atualizar()


func atualizar() -> void:
	if missoes == null or _titulo == null:
		return
	_titulo.text = missoes.titulo_atual()
	_objetivo.text = missoes.objetivo_texto()
	reset_size()
	# Colado no canto de cima à direita, com 12 px de folga.
	offset_left = -12.0 - maxf(size.x, get_combined_minimum_size().x)
	offset_right = -12.0
