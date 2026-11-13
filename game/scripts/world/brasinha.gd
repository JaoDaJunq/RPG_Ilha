class_name Brasinha
extends Node2D
## O Brasinha em cima da fogueira do acampamento: o "!" e o "?" por cima dele e o tamanho
## e a cor conforme o quanto já acordou. É só o que se vê; quem decide tudo é o Missoes.
##
## Enquanto a arte final não chegou (ArteBrasinha.tem_brasinha), o "corpo" dele é a própria
## chama da fogueira: ela fica azulada e fraquinha até ele acordar. Quando os arquivos do
## L42 entrarem nos caminhos de ArteBrasinha, o desenho dele aparece no lugar das chamas.

const ALTURA_MARCADOR := -46.0
const COR_EXCLAMACAO := Color("f3c53a")
const COR_INTERROGACAO := Color("8fd0f0")
const COR_FRACO := Color(0.7, 0.85, 1.25)
const FPS := 8.0

var marcador: Control
var _texto: Label
var _icone: TextureRect
var _parado: AnimatedSprite2D
var _humor: Sprite2D
var _tempo := 0.0
var _forca := 0.0


func _ready() -> void:
	name = "Brasinha"
	z_index = 4
	position = Vector2(0, -12)
	_montar_marcador()
	if ArteBrasinha.tem_brasinha():
		_montar_desenho()


func _montar_marcador() -> void:
	marcador = Control.new()
	marcador.position = Vector2(0, ALTURA_MARCADOR)
	marcador.visible = false
	marcador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(marcador)
	# Se o ícone final existir, usa ele; senão, a letra (interface, não desenho).
	_icone = TextureRect.new()
	_icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icone.scale = Vector2(0.25, 0.25)
	_icone.position = Vector2(-8, -8)
	marcador.add_child(_icone)
	_texto = Label.new()
	_texto.add_theme_font_size_override(&"font_size", 14)
	_texto.add_theme_color_override(&"font_outline_color", Color("2b1d12"))
	_texto.add_theme_constant_override(&"outline_size", 4)
	_texto.position = Vector2(-4, -9)
	_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marcador.add_child(_texto)


func _montar_desenho() -> void:
	var f := get_parent() as Construcao
	var quadros := SpriteFrames.new()
	quadros.remove_animation(&"default")
	SpriteSheets.adicionar_tira(quadros, ArteBrasinha.textura(ArteBrasinha.PARADO), &"parado", Vector2i(ArteBrasinha.QUADRO, ArteBrasinha.QUADRO), 6, FPS)
	_parado = AnimatedSprite2D.new()
	_parado.sprite_frames = quadros
	_parado.centered = false
	_parado.scale = Vector2(0.25, 0.25)
	_parado.offset = Vector2(-ArteBrasinha.QUADRO / 2.0, -ArteBrasinha.QUADRO + 8)
	_parado.position = Vector2(0, 12)
	add_child(_parado)
	_parado.play(&"parado")
	_humor = Sprite2D.new()
	_humor.centered = false
	_humor.scale = Vector2(0.25, 0.25)
	_humor.offset = _parado.offset
	_humor.position = _parado.position
	_humor.visible = false
	add_child(_humor)
	if f:
		f.usar_base_sem_chama(ArteBrasinha.quadro(ArteBrasinha.OBJETOS, ArteBrasinha.Objeto.BASE_FOGUEIRA))


## O estado das missões mudou (Missoes.mudou).
func atualizar(m: Missoes) -> void:
	_forca = m.forca()
	var tipo := m.marcador()
	marcador.visible = tipo != ""
	_texto.text = tipo
	_texto.add_theme_color_override(&"font_color", COR_EXCLAMACAO if tipo == "!" else COR_INTERROGACAO)
	var tex := ArteBrasinha.textura(ArteBrasinha.ICONE_EXCLAMACAO if tipo == "!" else ArteBrasinha.ICONE_INTERROGACAO)
	_icone.texture = tex
	_icone.visible = tex != null
	_texto.visible = tex == null
	var tamanho := lerpf(0.6, 1.0, _forca)
	var f := get_parent() as Construcao
	if _parado:
		scale = Vector2(tamanho, tamanho)
		var h := m.humor_atual()
		var folha := ArteBrasinha.quadro(ArteBrasinha.HUMORES, h)
		var so_parado := h == ArteBrasinha.Humor.FALANDO_A or folha == null
		_parado.visible = so_parado
		_humor.visible = not so_parado
		if not so_parado:
			_humor.texture = folha
	elif f and f.chamas():
		f.chamas().modulate = COR_FRACO.lerp(Color.WHITE, _forca)


func _process(delta: float) -> void:
	if marcador == null or not marcador.visible:
		return
	_tempo += delta
	marcador.position.y = ALTURA_MARCADOR + sin(_tempo * 4.0) * 1.5
