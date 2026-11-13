class_name BalaoBrasinha
extends Control
## O balão de fala do Brasinha em cima da fogueira: o texto aparece letra por letra e um
## clique (ou E, ou espaço) avança. No fim de um pedido novo, dois botões: aceitar ou
## recusar. Só mostra o que o anfitrião mandou (Missoes.fala_recebida).

const CARACTERES_POR_SEGUNDO := 48.0
const ALTURA_ACIMA := 78.0
## Longe da fogueira o balão fecha sozinho.
const DISTANCIA_MAXIMA := 150.0
const COR_TEXTO := Color("3b2a1e")

var missoes: Missoes
var jogador: Player

var _painel: PanelContainer
var _texto: Label
var _retrato: TextureRect
var _dica: Label
var _botoes: HBoxContainer
var _linhas: Array = []
var _indice := 0
var _letras := 0.0
var _escolha := false
var _humor := 0


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_painel = PanelContainer.new()
	_painel.add_theme_stylebox_override(&"panel", Tema.papel_claro())
	_painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_painel)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override(&"separation", 10)
	_painel.add_child(linha)
	_retrato = TextureRect.new()
	_retrato.custom_minimum_size = Vector2(72, 72)
	_retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_retrato.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_retrato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linha.add_child(_retrato)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override(&"separation", 4)
	linha.add_child(coluna)
	var nome := Label.new()
	nome.text = "Brasinha"
	nome.add_theme_font_override(&"font", Tema.fonte_negrito())
	nome.add_theme_color_override(&"font_color", Color("a8431f"))
	nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(nome)
	_texto = Label.new()
	_texto.custom_minimum_size = Vector2(300, 0)
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.add_theme_color_override(&"font_color", COR_TEXTO)
	_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(_texto)
	_botoes = HBoxContainer.new()
	_botoes.add_theme_constant_override(&"separation", 8)
	_botoes.visible = false
	coluna.add_child(_botoes)
	for b in [["Aceito!", true], ["Agora não", false]]:
		var botao := Button.new()
		botao.text = b[0]
		botao.focus_mode = Control.FOCUS_NONE
		botao.pressed.connect(_responder.bind(b[1]))
		_botoes.add_child(botao)
	_dica = Label.new()
	_dica.text = "clique para continuar"
	_dica.add_theme_font_size_override(&"font_size", 10)
	_dica.add_theme_color_override(&"font_color", Color(0.23, 0.16, 0.12, 0.6))
	_dica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(_dica)


func configurar(p: Player, m: Missoes) -> void:
	jogador = p
	missoes = m
	m.fala_recebida.connect(abrir)


func aberta() -> bool:
	return visible


## O texto que está inteiro na tela agora (para os testes).
func texto_inteiro() -> String:
	return String(_linhas[_indice]) if visible and _indice < _linhas.size() else ""


func abrir(linhas: Array, humor: int, escolha: bool) -> void:
	if linhas.is_empty():
		return
	_linhas = linhas
	_indice = 0
	_escolha = escolha
	_humor = humor
	visible = true
	_mostrar_linha()


func _mostrar_linha() -> void:
	_letras = 0.0
	_texto.text = String(_linhas[_indice])
	_texto.visible_characters = 0
	var ultima := _indice >= _linhas.size() - 1
	_botoes.visible = false
	_dica.visible = true
	var fala := ArteBrasinha.quadro(ArteBrasinha.RETRATO, 1 if int(_humor) in [ArteBrasinha.Humor.FALANDO_A, ArteBrasinha.Humor.FALANDO_B] else 0)
	_retrato.texture = fala
	_retrato.visible = fala != null
	_painel.reset_size()
	if ultima and _escolha:
		_dica.visible = false


## Mostra o resto da linha; se já estava inteira, vai para a próxima (ou fecha).
func avancar() -> void:
	if not visible:
		return
	if _texto.visible_characters < _texto.text.length() and _texto.visible_characters >= 0:
		_texto.visible_characters = -1
		_letras = _texto.text.length()
		_mostrar_botoes_se_fim()
		return
	if _indice < _linhas.size() - 1:
		_indice += 1
		_mostrar_linha()
	elif not _escolha:
		fechar()


func _mostrar_botoes_se_fim() -> void:
	if _escolha and _indice >= _linhas.size() - 1:
		_botoes.visible = true
		_dica.visible = false


func _responder(aceitar: bool) -> void:
	missoes.responder(aceitar)
	fechar()


func fechar() -> void:
	if not visible:
		return
	visible = false
	_linhas = []
	if missoes:
		missoes.fim_fala()


func _process(delta: float) -> void:
	if not visible:
		return
	var fogueira := get_tree().get_first_node_in_group(&"mundo").entidades.get_node_or_null("FogueiraAcampamento") as Node2D
	if fogueira == null:
		return
	if jogador and is_instance_valid(jogador) and jogador.global_position.distance_to(fogueira.global_position) > DISTANCIA_MAXIMA:
		fechar()
		return
	if _texto.visible_characters >= 0 and _texto.visible_characters < _texto.text.length():
		_letras += delta * CARACTERES_POR_SEGUNDO
		_texto.visible_characters = int(_letras)
		if _texto.visible_characters >= _texto.text.length():
			_texto.visible_characters = -1
			_mostrar_botoes_se_fim()
	elif _texto.visible_characters == -1:
		_mostrar_botoes_se_fim()
	# Em cima da fogueira, sempre dentro da tela.
	var tela := get_viewport().get_canvas_transform() * (fogueira.global_position - Vector2(0, ALTURA_ACIMA))
	var limite := get_viewport_rect().size - _painel.size - Vector2(8, 8)
	_painel.position = (tela - Vector2(_painel.size.x / 2.0, _painel.size.y)).clamp(Vector2(8, 8), limite.max(Vector2(8, 8)))


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var avanca := event.is_action_pressed(&"habilidade_4") or event.is_action_pressed(&"ui_accept")
	# Com os botões à mostra o clique é deles; senão qualquer clique avança.
	if event.is_action_pressed(&"interagir") and not _botoes.visible:
		avanca = true
	if avanca:
		avancar()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel"):
		fechar()
		get_viewport().set_input_as_handled()
