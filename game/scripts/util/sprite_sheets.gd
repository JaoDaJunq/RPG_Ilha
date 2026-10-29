class_name SpriteSheets
extends RefCounted
## Monta SpriteFrames a partir das folhas dos placeholders.
## Layout do Ninja Adventure: cada COLUNA é uma direção (baixo, cima, esquerda, direita)
## e cada LINHA é um quadro da animação.

const DIRECOES: Array[StringName] = [&"baixo", &"cima", &"esquerda", &"direita"]


## Cria animações "<nome>_<direção>" lendo `linhas` linhas a partir de `linha_inicial`.
static func adicionar_por_direcao(frames: SpriteFrames, textura: Texture2D, nome: String,
		tamanho: Vector2i, linha_inicial: int, linhas: int, fps: float, loop := true) -> void:
	for coluna in DIRECOES.size():
		var anim := StringName("%s_%s" % [nome, DIRECOES[coluna]])
		frames.add_animation(anim)
		frames.set_animation_speed(anim, fps)
		frames.set_animation_loop(anim, loop)
		for linha in range(linha_inicial, linha_inicial + linhas):
			frames.add_frame(anim, _recorte(textura, Rect2i(Vector2i(coluna, linha) * tamanho, tamanho)))


## Cria uma animação a partir de uma tira horizontal de quadros.
static func adicionar_tira(frames: SpriteFrames, textura: Texture2D, nome: StringName,
		tamanho: Vector2i, quantidade: int, fps: float, loop := true) -> void:
	frames.add_animation(nome)
	frames.set_animation_speed(nome, fps)
	frames.set_animation_loop(nome, loop)
	for i in quantidade:
		frames.add_frame(nome, _recorte(textura, Rect2i(Vector2i(i * tamanho.x, 0), tamanho)))


## Um quadro de uma tira horizontal como textura própria, opcionalmente espelhado
## (para a esquerda reaproveitar a direita) ou erguido alguns pixels (passo de costas).
static func quadro(textura: Texture2D, indice: int, tamanho: Vector2i, espelhar := false, subir := 0) -> Texture2D:
	var img := textura.get_image().get_region(Rect2i(Vector2i(indice * tamanho.x, 0), tamanho))
	if espelhar:
		img.flip_x()
	if subir > 0:
		var erguida := Image.create_empty(tamanho.x, tamanho.y, false, img.get_format())
		erguida.blit_rect(img, Rect2i(Vector2i(0, subir), tamanho - Vector2i(0, subir)), Vector2i.ZERO)
		img = erguida
	return ImageTexture.create_from_image(img)


## Cria uma animação a partir de uma lista de texturas.
static func adicionar_quadros(frames: SpriteFrames, nome: StringName, quadros: Array[Texture2D], fps: float, loop := true) -> void:
	frames.add_animation(nome)
	frames.set_animation_speed(nome, fps)
	frames.set_animation_loop(nome, loop)
	for q in quadros:
		frames.add_frame(nome, q)


static func direcao_de(vetor: Vector2) -> StringName:
	if absf(vetor.x) > absf(vetor.y):
		return &"esquerda" if vetor.x < 0.0 else &"direita"
	return &"cima" if vetor.y < 0.0 else &"baixo"


static func _recorte(textura: Texture2D, regiao: Rect2i) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = textura
	a.region = regiao
	a.filter_clip = true
	return a
