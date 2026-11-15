class_name BarraBoss
extends Control
## Barra de vida de boss no topo da tela: aparece enquanto há uma Mãe Gosma viva (grupo
## "boss_gosma") e mostra a soma da vida das gosmas contra a vida total da luta. Só lê o que
## o anfitrião manda (pv e pv_ref de cada MaeGosma). Interface por código (barrinha e texto).

const NOME := "Mãe Gosma"

var _barra: ProgressBar
var _rotulo: Label
var _icone: TextureRect


func _ready() -> void:
	name = "BarraBoss"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	custom_minimum_size = Vector2(300, 34)
	offset_left = -150.0
	offset_right = 150.0
	offset_top = 8.0
	offset_bottom = 42.0
	_rotulo = Label.new()
	_rotulo.text = NOME
	_rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rotulo.add_theme_font_size_override(&"font_size", 12)
	_rotulo.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_rotulo.add_theme_constant_override(&"outline_size", 4)
	add_child(_rotulo)
	_barra = ProgressBar.new()
	_barra.show_percentage = false
	_barra.max_value = 100.0
	_barra.value = 100.0
	_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barra.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_barra.offset_top = -12.0
	_barra.offset_bottom = 0.0
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = Color(0.45, 0.8, 0.35)
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.1, 0.1, 0.12, 0.85)
	fundo.set_border_width_all(1)
	fundo.border_color = Color(0.9, 0.9, 0.8, 0.9)
	_barra.add_theme_stylebox_override(&"fill", cheio)
	_barra.add_theme_stylebox_override(&"background", fundo)
	add_child(_barra)
	var tex := ArteGosma.textura(ArteGosma.ICONE_BOSS)
	if tex:
		_icone = TextureRect.new()
		_icone.texture = tex
		_icone.custom_minimum_size = Vector2(28, 28)
		_icone.size = Vector2(28, 28)
		_icone.position = Vector2(-32, 2)
		_icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_icone)


## 0 a 1: a vida que resta da luta, ou -1 se não há boss. (Também usado pelos testes.)
func fracao() -> float:
	var atual := 0.0
	var total := 0.0
	var achou := false
	for g in get_tree().get_nodes_in_group(&"boss_gosma"):
		var m := g as MaeGosma
		if m == null or m.is_queued_for_deletion():
			continue
		achou = true
		atual += m.pv
		total = maxf(total, m.pv_ref)
	if not achou or total <= 0.0:
		return -1.0
	return clampf(atual / total, 0.0, 1.0)


func _process(_delta: float) -> void:
	var f := fracao()
	visible = f >= 0.0
	if f >= 0.0:
		_barra.value = f * 100.0
