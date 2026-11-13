class_name Golem
extends Criatura
## Golenzinho de pedra das Colinas (L39 folha 08): lento, forte e pesado (não é empurrado).
## Perto de alguém, ergue os punhos (o aviso bem longo) e SOCA O CHÃO: quem estiver na frente
## apanha muito e cai (Derrubado). É de pedra: golpe físico tira pouco, mas a PICARETA na mão
## quebra rápido (quanto melhor a picareta, mais). O fogo quase não faz nada.
## Folha (128 px): 0 parado, 1-2 passos, 3 punhos erguidos, 4 soco no chão, 5 rachado.

const FOLHA := preload("res://assets/sprites/tiny/inimigos/golem.png")
const RAIO_SOCO := 28.0
const TEMPO_PREPARO := 0.85
const DEFESA_PEDRA := 0.45
const BONUS_PICARETA := 1.6  # vezes o poder da picareta (pedra 5,3 → bem mais)


func _configurar() -> void:
	nome = "Golenzinho de pedra"
	vida_base = 26.0
	velocidade = 13.0
	raio_visao = 100.0
	dano = 18.0
	nivel = 4
	xp = 30
	peso = 3.0  # pesado: quase não é empurrado
	saque = [[&"pedra", 2, 4], [&"minerio_cobre", 0, 2], [&"minerio_ferro", 1, 1, 0.5], [&"cristal", 1, 1, 0.2]]
	resistencias = {&"fogo": 0.5, &"veneno": 0.0}


func _montar_animacoes(f: SpriteFrames) -> void:
	var t := Vector2i(128, 128)
	Criatura.anim(f, &"parado", FOLHA, t, [0], 1.0)
	Criatura.anim(f, &"andar", FOLHA, t, [1, 0, 2, 0], 4.0)
	Criatura.anim(f, &"preparo", FOLHA, t, [3], 1.0)
	Criatura.anim(f, &"ataque", FOLHA, t, [4], 1.0, false)
	Criatura.anim(f, &"dano", FOLHA, t, [5], 1.0)


func _pensar(delta: float) -> Vector2:
	return _corpo_a_corpo(delta, RAIO_SOCO - 8.0, TEMPO_PREPARO, 1.8, 0.4)


func _ao_bater() -> void:
	var frente := global_position + Vector2(-8 if olhando_esquerda else 8, 0)
	World.efeito_todos(self, &"poeira", frente)
	World.efeito_laco_todos(self, &"fenda", frente, 0.8, 0.6)
	for p in jogadores_em_volta(frente, RAIO_SOCO):
		if golpear(p, dano):
			EfeitosEstado.aplicar_em(p, EfeitosEstado.DERRUBADO, 0.6, 0.0, self)


## Pedra: o físico tira pouco, a picareta na mão quebra rápido.
func _ajustar_dano(q: float, tipo: StringName, origem: Node) -> float:
	if tipo != &"fisico":
		return q
	if origem is Player:
		var item := (origem as Player).item_na_mao()
		if item and item.ferramenta == &"picareta":
			return q * maxf(1.0, item.poder * BONUS_PICARETA * 0.25)
	return q * DEFESA_PEDRA
