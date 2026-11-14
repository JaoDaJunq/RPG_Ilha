class_name MissoesTela
extends Control
## O diário de missões (tecla J): a missão atual com o progresso, o pedido do dia e as
## pedras de lore já lidas, com o retrato do Brasinha. Só lê o estado de Missoes.

const COR_TEXTO := Color("3b2a1e")

var missoes: Missoes
var _retrato: TextureRect
var _capitulo: Label
var _missao: Label
var _objetivo: Label
var _pedido: Label
var _pedras: Label


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var fundo := ColorRect.new()
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
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(painel)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override(&"separation", 14)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(linha)
	_retrato = TextureRect.new()
	_retrato.custom_minimum_size = Vector2(96, 96)
	_retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_retrato.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_retrato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	linha.add_child(_retrato)
	var coluna := VBoxContainer.new()
	coluna.custom_minimum_size = Vector2(360, 0)
	coluna.add_theme_constant_override(&"separation", 6)
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linha.add_child(coluna)
	var titulo := _rotulo("Missões do Brasinha", 22, true)
	coluna.add_child(titulo)
	_capitulo = _rotulo("", 14)
	coluna.add_child(_capitulo)
	_missao = _rotulo("", 18, true)
	coluna.add_child(_missao)
	_objetivo = _rotulo("", 14)
	coluna.add_child(_objetivo)
	coluna.add_child(_rotulo("Pedido do dia", 16, true))
	_pedido = _rotulo("", 14)
	coluna.add_child(_pedido)
	coluna.add_child(_rotulo("Pedras lidas", 16, true))
	_pedras = _rotulo("", 14)
	coluna.add_child(_pedras)
	coluna.add_child(_rotulo("J fecha", 10))


func _rotulo(texto: String, tamanho: int, negrito := false) -> Label:
	var l := Label.new()
	l.text = texto
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if negrito:
		l.add_theme_font_override(&"font", Tema.fonte_negrito())
	l.add_theme_font_size_override(&"font_size", tamanho)
	l.add_theme_color_override(&"font_color", COR_TEXTO)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func configurar(m: Missoes) -> void:
	missoes = m
	m.mudou.connect(atualizar)
	atualizar()


func alternar() -> void:
	visible = not visible
	if visible:
		atualizar()


func fechar() -> void:
	visible = false


func atualizar() -> void:
	if missoes == null or _missao == null:
		return
	var retrato := ArteBrasinha.quadro(ArteBrasinha.RETRATO, 0)
	_retrato.texture = retrato
	_retrato.visible = retrato != null
	_capitulo.text = missoes.titulo_capitulo()
	_missao.text = missoes.titulo_atual()
	_objetivo.text = missoes.objetivo_texto()
	_pedido.text = texto_do_pedido()
	_pedras.text = texto_das_pedras()


func texto_do_pedido() -> String:
	var p := missoes.pedido
	if p.is_empty():
		return "Nenhum pedido por enquanto. Um novo pode aparecer ao amanhecer." if missoes.pedidos_liberados() else "O Brasinha ainda não está pedindo nada."
	var item := String(p["item"])
	var nome := ItemData.carregar(StringName(item)).nome if ItemData.existe(StringName(item)) else item
	var rec: Array = p.get("rec", [])
	var premio := ""
	if rec.size() == 2:
		var rid := StringName(rec[0])
		premio = "  (prêmio: %d %s)" % [int(rec[1]), ItemData.carregar(rid).nome if ItemData.existe(rid) else String(rid)]
	if String(p.get("estado", "")) == "oferecido":
		return "Ele tem um pedido: %d %s. Fale com ele para aceitar ou recusar.%s" % [int(p["qtd"]), nome.to_lower(), premio]
	return "Entregue %d %s ao Brasinha.%s\nPedidos feitos: %d" % [int(p["qtd"]), nome.to_lower(), premio, missoes.pedidos_feitos]


func texto_das_pedras() -> String:
	if missoes.pedras.is_empty():
		return "Nenhuma ainda. Há uma pedra antiga em cada região (menos a Clareira)."
	var nomes: Array[String] = []
	for r in missoes.pedras:
		nomes.append("%s: %s" % [Regioes.nome(r), String(FalasBrasinha.LORE_TITULO.get(r, ""))])
	return "%d de 5\n%s" % [missoes.pedras.size(), "\n".join(nomes)]


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		fechar()
		get_viewport().set_input_as_handled()
