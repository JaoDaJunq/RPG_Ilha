class_name Efeito
extends AnimatedSprite2D
## Efeito visual que toca uma vez e some (poeira, giro, congelar...).
## Criado em todos os jogadores pela World (efeito_todos), nunca sincronizado.

const TABELA := {
	&"giro": [preload("res://assets/placeholder/ninja/fx/giro.png"), Vector2i(32, 32), 4, 16.0],
	&"poeira": [preload("res://assets/placeholder/ninja/fx/poeira.png"), Vector2i(32, 32), 6, 18.0],
	&"congelar": [preload("res://assets/placeholder/ninja/fx/congelar.png"), Vector2i(32, 32), 10, 16.0],
}


static func criar(nome: StringName, pos: Vector2) -> Efeito:
	var e := Efeito.new()
	var dados: Array = TABELA.get(nome, [])
	if dados.is_empty():
		return e
	var f := SpriteFrames.new()
	f.remove_animation(&"default")
	SpriteSheets.adicionar_tira(f, dados[0], &"tocar", dados[1], dados[2], dados[3], false)
	e.sprite_frames = f
	e.position = pos
	e.z_index = 1
	e.animation_finished.connect(e.queue_free)
	e.play(&"tocar")
	return e
