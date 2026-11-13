class_name CogumeloAndante
extends Criatura
## Cogumelo andante do Pântano (L39 folha 05): anda devagar e, perto de alguém, incha o
## chapéu (o aviso) e solta uma nuvem de ESPOROS em volta: quem estiver dentro fica Lento e
## perde um pouco de vida. O fogo queima o dobro.
## Folha (128 px): 0 parado, 1-2 passos, 3 inchado (preparo), 4 esporos, 5 machucado.

const FOLHA := preload("res://assets/sprites/tiny/inimigos/cogumelo.png")
const RAIO_ESPOROS := 34.0
const LENTIDAO := 0.45
const TEMPO_LENTO := 3.0
const TEMPO_PREPARO := 0.7


func _configurar() -> void:
	nome = "Cogumelo andante"
	vida_base = 9.0
	velocidade = 14.0
	raio_visao = 90.0
	dano = 4.0
	nivel = 2
	xp = 12
	saque = [[&"cogumelo", 1, 2], [&"erva", 0, 1], [&"fibra", 0, 1]]
	resistencias = {&"fogo": 2.0, &"veneno": 0.0}


func _montar_animacoes(f: SpriteFrames) -> void:
	var t := Vector2i(128, 128)
	Criatura.anim(f, &"parado", FOLHA, t, [0], 1.0)
	Criatura.anim(f, &"andar", FOLHA, t, [1, 0, 2, 0], 6.0)
	Criatura.anim(f, &"preparo", FOLHA, t, [3], 1.0)
	Criatura.anim(f, &"ataque", FOLHA, t, [4], 1.0, false)
	Criatura.anim(f, &"dano", FOLHA, t, [5], 1.0)


func _pensar(delta: float) -> Vector2:
	return _corpo_a_corpo(delta, RAIO_ESPOROS - 6.0, TEMPO_PREPARO, 2.6, 0.6)


## Os esporos: Lento e um pouco de dano em todos os jogadores em volta.
func _ao_bater() -> void:
	World.efeito_laco_todos(self, &"nuvem_toxica", global_position + Vector2(0, -4), 1.2, 0.55)
	for p in jogadores_em_volta(global_position, RAIO_ESPOROS):
		EfeitosEstado.aplicar_em(p, EfeitosEstado.LENTIDAO, TEMPO_LENTO, LENTIDAO, self)
		golpear(p, dano, &"veneno")
		p.avisar("Esporos! Você ficou lento. Fique longe quando o cogumelo inchar.")
