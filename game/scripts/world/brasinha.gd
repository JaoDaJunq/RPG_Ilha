class_name Brasinha
extends Node2D
## O Brasinha em cima da fogueira do acampamento: o desenho dele (parado em laço e os
## humores), o "!" e o "?" por cima e o tamanho conforme o quanto já acordou. É só o que se
## vê; quem decide tudo é o Missoes.
##
## Com a arte do L42 (ArteBrasinha.tem_brasinha) a fogueira vira só a base (sem chamas) e o
## Brasinha fica em cima da lenha. Sem os arquivos, o "corpo" dele é a própria chama da
## fogueira (azulada e fraquinha até ele acordar).

const ALTURA_MARCADOR := -14.0
const COR_EXCLAMACAO := Color("f3c53a")
const COR_INTERROGACAO := Color("8fd0f0")
const COR_FRACO := Color(0.7, 0.85, 1.25)
const FPS := 8.0
## Onde ficam os pés dele, em cima da lenha da base (em relação ao pé da fogueira).
const PE_NA_LENHA := Vector2(0, -5)
const ESCALA_ARTE := 0.25
const ESCALA_ICONE := 0.2
const TROCA_FALA := 0.28

var marcador: Control
var _texto: Label
var _icone: TextureRect
var _parado: AnimatedSprite2D
var _humor: Sprite2D
var _tempo := 0.0
var _forca := 0.0
var _m: Missoes
var _noite_vista := false
var _falando := false
var _tempo_fala := 0.0


func _ready() -> void:
	name = "Brasinha"
	z_index = 4
	_montar_marcador()
	if ArteBrasinha.tem_brasinha():
		position = PE_NA_LENHA
		_montar_desenho()
	else:
		position = Vector2(0, -12)


func _montar_marcador() -> void:
	marcador = Control.new()
	marcador.position = Vector2(0, ALTURA_MARCADOR)
	marcador.visible = false
	marcador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(marcador)
	# Ícone final se existir; senão, a letra (interface, não desenho).
	_icone = TextureRect.new()
	_icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icone.scale = Vector2(ESCALA_ICONE, ESCALA_ICONE)
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
	_parado.scale = Vector2(ESCALA_ARTE, ESCALA_ARTE)
	_parado.offset = Vector2(-ArteBrasinha.QUADRO / 2.0, -ArteBrasinha.QUADRO + 8)
	add_child(_parado)
	_parado.play(&"parado")
	_humor = Sprite2D.new()
	_humor.centered = false
	_humor.scale = Vector2(ESCALA_ARTE, ESCALA_ARTE)
	_humor.offset = _parado.offset
	_humor.visible = false
	add_child(_humor)
	if f:
		f.usar_base_sem_chama(ArteBrasinha.quadro(ArteBrasinha.OBJETOS, ArteBrasinha.Objeto.BASE_FOGUEIRA))


## O balão de fala abriu ou fechou: enquanto fala, a boca mexe (humores A e B).
func falando(valor: bool) -> void:
	_falando = valor
	_tempo_fala = 0.0
	if _m:
		atualizar(_m)


## O estado das missões mudou (Missoes.mudou).
func atualizar(m: Missoes) -> void:
	_m = m
	_forca = m.forca()
	var tipo := m.marcador()
	marcador.visible = tipo != ""
	_texto.text = tipo
	_texto.add_theme_color_override(&"font_color", COR_EXCLAMACAO if tipo == "!" else COR_INTERROGACAO)
	var tex := ArteBrasinha.textura(ArteBrasinha.ICONE_EXCLAMACAO if tipo == "!" else ArteBrasinha.ICONE_INTERROGACAO)
	_icone.texture = tex
	_icone.visible = tex != null
	_texto.visible = tex == null
	if tex:
		_icone.position = Vector2(-tex.get_width() * ESCALA_ICONE / 2.0, -tex.get_height() * ESCALA_ICONE)
	var f := get_parent() as Construcao
	if _parado:
		# Fraquinho cresce aos poucos com a lenha; acordado é do tamanho normal.
		var tamanho := 1.0 if m.acordado else lerpf(0.85, 1.15, _forca)
		_parado.scale = Vector2(ESCALA_ARTE, ESCALA_ARTE) * tamanho
		_humor.scale = _parado.scale
		_mostrar_humor(_humor_a_mostrar(m))
	elif f and f.chamas():
		f.chamas().modulate = COR_FRACO.lerp(Color.WHITE, _forca)


func _humor_a_mostrar(m: Missoes) -> int:
	var h := m.humor_atual()
	if _falando and h in [ArteBrasinha.Humor.FALANDO_A, ArteBrasinha.Humor.FALANDO_B]:
		return ArteBrasinha.Humor.FALANDO_A if int(_tempo_fala / TROCA_FALA) % 2 == 0 else ArteBrasinha.Humor.FALANDO_B
	return h


func _mostrar_humor(h: int) -> void:
	var folha := ArteBrasinha.quadro(ArteBrasinha.HUMORES, h)
	var so_parado := (h == ArteBrasinha.Humor.FALANDO_A and not _falando) or folha == null
	_parado.visible = so_parado
	_humor.visible = not so_parado
	if not so_parado:
		_humor.texture = folha.atlas
		_humor.region_enabled = true
		_humor.region_rect = folha.region


func _process(delta: float) -> void:
	_tempo += delta
	if marcador and marcador.visible:
		marcador.position.y = ALTURA_MARCADOR + sin(_tempo * 4.0) * 1.0
	if _m == null or _parado == null:
		return
	var noite := _m.w != null and _m.w.noite
	if noite != _noite_vista:
		_noite_vista = noite
		atualizar(_m)
	elif _falando:
		var antes := int(_tempo_fala / TROCA_FALA)
		_tempo_fala += delta
		if int(_tempo_fala / TROCA_FALA) != antes:
			_mostrar_humor(_humor_a_mostrar(_m))
