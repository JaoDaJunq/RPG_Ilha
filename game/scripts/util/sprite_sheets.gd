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
