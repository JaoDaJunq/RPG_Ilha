class_name Mochila
extends Control
## Tela da mochila (I ou Tab) e da bancada, como o inventário do Minecraft: grade de
## fabricação (2x2; 3x3 na bancada) com a seta e o resultado, os 27 espaços da mochila e
## a barra (1-9) embaixo. Clique esquerdo pega ou larga a pilha, clique direito pega metade
## ou põe 1, Shift + clique manda para o outro lado. Cada clique é um PEDIDO ao anfitrião
## (Inventory); a tela só mostra o que ele devolve.

const TAM := 52  # lado de um espaço na tela (os ícones têm até ~49 px, no tamanho real)
const SETA := "res://assets/sprites/tiny/icones/seta.png"

var jogador: Player
var _espacos: Array = []  # [índice no inventário, {fundo, icone, qtd}]
var _resultado: Dictionary
var _grade_2x2: GridContainer
var _grade_3x3: GridContainer
var _titulo: Label
var _cursor: Control
var _cursor_icone: TextureRect
var _cursor_qtd: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP  # aberta, o clique não vira golpe no mundo
	visible = false
	_montar()
	Events.abrir_mochila.connect(abrir)


func configurar(p: Player) -> void:
	jogador = p
	p.inventario.mudou.connect(_atualizar)


func aberta() -> bool:
	return visible


func alternar() -> void:
	if visible:
		fechar()
	else:
		abrir(false)


func abrir(na_bancada: bool) -> void:
	if jogador == null:
		return
	visible = true
	_titulo.text = "Bancada de trabalho" if na_bancada else "Mochila"
	_grade_2x2.visible = not na_bancada
	_grade_3x3.visible = na_bancada
	_atualizar()


func fechar() -> void:
	if not visible:
		return
	visible = false
	jogador.inventario.pedir_fechar()


func _process(_delta: float) -> void:
	if visible:
		_cursor.position = get_local_mouse_position() + Vector2(-TAM / 2.0, -TAM / 2.0)


# --- Montagem ----------------------------------------------------------------------

func _montar() -> void:
	var escuro := ColorRect.new()
	escuro.color = Color(0.05, 0.06, 0.1, 0.45)
	escuro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(escuro)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override(&"panel", Tema.painel())
	centro.add_child(painel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 8)
	painel.add_child(v)

	_titulo = _rotulo("Mochila", 20)
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_titulo)

	# Fabricação: grade, seta e resultado.
	var fab := HBoxContainer.new()
	fab.alignment = BoxContainer.ALIGNMENT_CENTER
	fab.add_theme_constant_override(&"separation", 12)
	v.add_child(fab)
	_grade_2x2 = _grade(2, Inventory.GRADE_2X2)
	fab.add_child(_grade_2x2)
	var nove: Array[int] = []
	for k in 9:
		nove.append(Inventory.GRADE + k)
	_grade_3x3 = _grade(3, nove)
	fab.add_child(_grade_3x3)
	var seta := TextureRect.new()
	seta.texture = load(SETA) if ResourceLoader.exists(SETA) else null
	seta.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	seta.custom_minimum_size = Vector2(44, TAM)
	seta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fab.add_child(seta)
	_resultado = _espaco(-1)
	_resultado.fundo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_resultado.fundo.custom_minimum_size = Vector2(TAM + 12, TAM + 12)
	fab.add_child(_resultado.fundo)

	# Mochila (27) e barra (9).
	var faixa: Array[int] = []
	for i in range(Inventory.BARRA, Inventory.GUARDAR):
		faixa.append(i)
	v.add_child(_grade(9, faixa))
	var barra: Array[int] = []
	for i in Inventory.BARRA:
		barra.append(i)
	var g := _grade(9, barra)
	v.add_child(g)
	var dica := _rotulo("Esquerdo: pega/larga · Direito: metade/1 · Shift: manda para o outro lado", 13)
	dica.add_theme_color_override(&"font_color", Tema.COR_TEXTO_2)
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(dica)

	# Item preso no mouse.
	_cursor = Control.new()
	_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor.size = Vector2(TAM, TAM)
	_cursor.z_index = 10
	add_child(_cursor)
	_cursor_icone = _icone()
	_cursor.add_child(_cursor_icone)
	_cursor_qtd = _qtd()
	_cursor.add_child(_cursor_qtd)


func _grade(colunas: int, indices: Array[int]) -> GridContainer:
	var g := GridContainer.new()
	g.columns = colunas
	g.add_theme_constant_override(&"h_separation", 4)
	g.add_theme_constant_override(&"v_separation", 4)
	g.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for i in indices:
		var e := _espaco(i)
		g.add_child(e.fundo)
		_espacos.append([i, e])
	return g


## Um espaço: fundo azul do pacote, ícone no tamanho real e a quantidade no canto.
func _espaco(indice: int) -> Dictionary:
	var fundo := Panel.new()
	fundo.add_theme_stylebox_override(&"panel", Tema.espaco())
	fundo.custom_minimum_size = Vector2(TAM, TAM)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	fundo.gui_input.connect(_clique.bind(indice))
	var icone := _icone()
	fundo.add_child(icone)
	var qtd := _qtd()
	fundo.add_child(qtd)
	return {fundo = fundo, icone = icone, qtd = qtd}


func _icone() -> TextureRect:
	var t := TextureRect.new()
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED  # tamanho real: pixel nítido
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _qtd() -> Label:
	var l := _rotulo("", 14)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	l.offset_right = -3
	return l


func _rotulo(texto: String, tamanho: int) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override(&"font_size", tamanho)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# --- Cliques e atualização --------------------------------------------------------

func _clique(evento: InputEvent, indice: int) -> void:
	var b := evento as InputEventMouseButton
	if b == null or not b.pressed or not (b.button_index == MOUSE_BUTTON_LEFT or b.button_index == MOUSE_BUTTON_RIGHT):
		return
	accept_event()
	if indice < 0:
		jogador.inventario.pedir_resultado(b.shift_pressed)
	else:
		jogador.inventario.pedir_clique(indice, b.button_index == MOUSE_BUTTON_RIGHT, b.shift_pressed)


func _atualizar() -> void:
	if jogador == null:
		return
	var inv := jogador.inventario
	for par in _espacos:
		_mostrar(par[1], inv.item_em(par[0]), inv.qtd_em(par[0]))
	var r := inv.receita_atual()
	_mostrar(_resultado, r.resultado if r else &"", r.quantidade if r else 0)
	_cursor_icone.texture = _textura(inv.item_em(Inventory.MAO))
	_cursor_qtd.text = str(inv.qtd_em(Inventory.MAO)) if inv.qtd_em(Inventory.MAO) > 1 else ""


func _mostrar(e: Dictionary, id: StringName, qtd: int) -> void:
	e.icone.texture = _textura(id)
	e.qtd.text = str(qtd) if qtd > 1 else ""
	e.fundo.tooltip_text = ItemData.carregar(id).nome if ItemData.existe(id) else ""


func _textura(id: StringName) -> Texture2D:
	return ItemData.carregar(id).icone if ItemData.existe(id) else null
