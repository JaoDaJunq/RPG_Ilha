class_name Efeito
extends AnimatedSprite2D
## Efeito visual que toca uma vez e some (poeira, giro, congelar...).
## Criado em todos os jogadores pela World (efeito_todos), nunca sincronizado.
## [textura, tamanho do quadro, quadros, fps, escala, (deslocamento em pixels da arte)].
## A arte do Tiny Swords é feita para tile de 64 px: escala 0,25 no nosso mundo. Os efeitos
## do Pixelbolt (art/fx_receitas/) já vêm no pixel do pacote e também entram com 0,25.

const TABELA := {
	&"giro": [preload("res://assets/sprites/tiny/fx/giro.png"), Vector2i(94, 67), 1, 4.0, 0.25],
	&"poeira": [preload("res://assets/tiny_swords/fx/poeira.png"), Vector2i(64, 64), 8, 18.0, 0.25],
	&"congelar": [preload("res://assets/sprites/tiny/fx/cristais.png"), Vector2i(81, 63), 1, 1.5, 0.25],
	&"explosao": [preload("res://assets/tiny_swords/fx/explosao.png"), Vector2i(192, 192), 8, 20.0, 0.3],
	&"subir_nivel": [preload("res://assets/tiny_swords/fx/brilho.png"), Vector2i(192, 192), 11, 14.0, 0.25],
	# Habilidades 3 e 4 (Pixelbolt). O deslocamento põe o "chão" do desenho no ponto do efeito.
	&"escudo": [preload("res://assets/sprites/tiny/fx/escudo.png"), Vector2i(120, 120), 12, 12.5, 0.25],
	&"furia": [preload("res://assets/sprites/tiny/fx/furia.png"), Vector2i(128, 128), 19, 15.8, 0.25, Vector2(0, -16)],
	&"raio": [preload("res://assets/sprites/tiny/fx/raio.png"), Vector2i(144, 156), 12, 18.7, 0.25, Vector2(0, -50)],
	&"nova_gelo": [preload("res://assets/sprites/tiny/fx/nova_gelo.png"), Vector2i(160, 160), 22, 16.8, 0.25, Vector2(0, -20)],
}


## `repetir`: o efeito fica tocando em laço até alguém tirá-lo (o escudo do Bloqueio).
static func criar(nome: StringName, pos: Vector2, repetir := false) -> Efeito:
	var e := Efeito.new()
	var dados: Array = TABELA.get(nome, [])
	if dados.is_empty():
		return e
	var f := SpriteFrames.new()
	f.remove_animation(&"default")
	SpriteSheets.adicionar_tira(f, dados[0], &"tocar", dados[1], dados[2], dados[3], repetir)
	e.sprite_frames = f
	e.scale = Vector2(dados[4], dados[4])
	if dados.size() > 5:
		e.offset = dados[5]
	e.position = pos
	e.z_index = 1
	if not repetir:
		e.animation_finished.connect(e.queue_free)
	e.play(&"tocar")
	return e
