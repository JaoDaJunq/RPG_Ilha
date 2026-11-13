class_name BarraCabeca
extends Node
## Nível (sempre) e barra de vida (só depois de levar dano) em cima da cabeça de um
## inimigo ou animal. Vai como filho da criatura, ao lado do HealthComponent.
##
## A interface fica numa camada de tela (CanvasLayer) e é posicionada pela câmera, igual aos
## nomes dos jogadores no HUD: assim o número fica nítido com o zoom 4 do mundo, em pixels
## inteiros. Funciona em todas as máquinas: quem recebe o dano (anfitrião ou cliente) chama
## `mostrar_dano()` e a vida é lida do HealthComponent da criatura.

## Segundos com a barra à vista depois do último golpe (os últimos 0,5 s são o sumir aos poucos).
@export var tempo_visivel := 4.0
@export var sumir_em := 0.5
## Altura (em px do mundo) do chão até o topo da cabeça. `ajustar_ao_sprite` calcula pelo desenho.
@export var altura := 30.0

const CAMADA := 5  # abaixo do HUD (10): a mochila e a ficha cobrem as barras
const LARGURA_BARRA := 52
const ALTURA_BARRA := 7
const ALTURA_SELO := 18
const FOLGA := 2  # px de tela entre o selo, a barra e a cabeça

var nivel := 1: set = definir_nivel

var _vida: HealthComponent
var _camada: CanvasLayer
var _raiz: Control
var _selo: PanelContainer
var _numero: Label
var _barra: ProgressBar
var _restante := 0.0


## A criatura dormiu (longe de todos, ver Soneca): a barra some, senão ficaria parada na tela.
func _notification(what: int) -> void:
	if _camada == null:
		return
	if what == NOTIFICATION_DISABLED:
		_camada.visible = false
	elif what == NOTIFICATION_ENABLED:
		_camada.visible = true
		_atualizar_posicao()


func _ready() -> void:
	_vida = get_parent().get_node_or_null("HealthComponent") as HealthComponent
	_montar()
	definir_nivel(nivel)
	_atualizar_barra()
	_atualizar_posicao()


## Põe a barra um pouco acima do ponto mais alto do desenho do bicho (primeiro quadro de
## "parado"), para cada espécie ficar com a barra encostada na própria cabeça.
func ajustar_ao_sprite(visual: AnimatedSprite2D) -> void:
	var quadros := visual.sprite_frames
	if quadros == null:
		return
	var anim: StringName = &"parado" if quadros.has_animation(&"parado") else visual.animation
	if not quadros.has_animation(anim) or quadros.get_frame_count(anim) == 0:
		return
	var tex := quadros.get_frame_texture(anim, 0)
	if tex == null:
		return
	var usado := tex.get_image().get_used_rect()
	if usado.size == Vector2i.ZERO:
		return
	var centro_y := tex.get_height() / 2.0
	var topo := visual.position.y + (usado.position.y - centro_y + visual.offset.y) * visual.scale.y
	altura = roundf(-topo)


func definir_nivel(n: int) -> void:
	nivel = n
	if _numero:
		_numero.text = str(n)


## A criatura levou dano (em qualquer máquina): mostra a barra e reinicia o tempo.
func mostrar_dano() -> void:
	_restante = tempo_visivel
	_atualizar_barra()


## A barra está à mostra agora? (Ela fica sempre no lugar e só some a cor, para o selo do
## nível não pular quando ela aparece.)
func barra_visivel() -> bool:
	return _barra != null and _barra.modulate.a > 0.0


func texto_nivel() -> String:
	return _numero.text


func _process(delta: float) -> void:
	_restante = maxf(0.0, _restante - delta)
	_atualizar_barra()
	_atualizar_posicao()


func _atualizar_barra() -> void:
	if _vida:
		_barra.value = clampf(_vida.atual / maxf(_vida.maximo, 0.001), 0.0, 1.0) * 100.0
	_barra.modulate.a = clampf(_restante / sumir_em, 0.0, 1.0)


func _atualizar_posicao() -> void:
	var pai := get_parent() as Node2D
	if pai == null or not is_inside_tree():
		return
	var tela := get_viewport().get_canvas_transform() * (pai.global_position - Vector2(0, altura))
	# O fundo do bloco (a barra) encosta na cabeça; o selo fica em cima dela, centrado.
	var tamanho := _raiz.get_combined_minimum_size()
	_raiz.position = (tela - Vector2(tamanho.x / 2.0, tamanho.y)).round()


func _montar() -> void:
	_camada = CanvasLayer.new()
	_camada.layer = CAMADA
	add_child(_camada)
	_raiz = VBoxContainer.new()
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_theme_constant_override(&"separation", FOLGA)
	_camada.add_child(_raiz)

	_selo = PanelContainer.new()
	_selo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var caixa := StyleBoxFlat.new()
	caixa.bg_color = Color(0.09, 0.09, 0.13, 0.88)
	caixa.border_color = Tema.COR_BORDA
	caixa.set_border_width_all(1)
	caixa.set_corner_radius_all(4)
	caixa.content_margin_left = 6
	caixa.content_margin_right = 6
	caixa.content_margin_top = 1
	caixa.content_margin_bottom = 1
	_selo.add_theme_stylebox_override(&"panel", caixa)
	_selo.custom_minimum_size = Vector2(0, ALTURA_SELO)
	_raiz.add_child(_selo)
	_numero = Label.new()
	_numero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_numero.add_theme_font_size_override(&"font_size", 12)
	_numero.add_theme_color_override(&"font_color", Tema.COR_DESTAQUE)
	_numero.add_theme_color_override(&"font_outline_color", Tema.COR_CONTORNO)
	_numero.add_theme_constant_override(&"outline_size", 3)
	_numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_selo.add_child(_numero)

	_barra = ProgressBar.new()
	_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barra.show_percentage = false
	_barra.custom_minimum_size = Vector2(LARGURA_BARRA, ALTURA_BARRA)
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color("2a2a22")
	fundo.border_color = Color("0e100d")
	fundo.set_border_width_all(1)
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = Color("d0564a")
	_barra.add_theme_stylebox_override(&"background", fundo)
	_barra.add_theme_stylebox_override(&"fill", cheio)
	_barra.value = 100.0
	_barra.modulate.a = 0.0
	_raiz.add_child(_barra)
