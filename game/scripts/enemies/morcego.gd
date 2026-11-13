class_name Morcego
extends Criatura
## Morcego (L39 folha 06): aparece à noite (e nas cavernas, depois). Rápido e frágil: voa em
## volta do alvo balançando, de tempos em tempos MERGULHA em linha reta (fecha as asas: o
## aviso) e morde; depois sobe e se afasta. Voa por cima da água. Some ao amanhecer.
## Folha (128 px): 0-2 voo (asas em cima, no meio, embaixo), 3 mergulho, 4 mordida, 5 machucado.

const FOLHA := preload("res://assets/sprites/tiny/inimigos/morcego.png")
const RAIO_RODEAR := 42.0
const TEMPO_MIRA := 0.3
const TEMPO_MERGULHO := 0.4
const VEL_MERGULHO := 2.8
const TEMPO_FUGA := 0.7

var _fase := 0.0
var _dir_mergulho := Vector2.ZERO
var _mordeu := false


func _configurar() -> void:
	nome = "Morcego"
	vida_base = 3.5
	velocidade = 52.0
	raio_visao = 150.0
	dano = 6.0
	nivel = 2
	xp = 8
	voa = true
	peso = 0.6
	saque = [[&"couro", 1, 1, 0.5], [&"carne_crua", 1, 1, 0.3]]
	_fase = randf() * TAU


func _montar_animacoes(f: SpriteFrames) -> void:
	var t := Vector2i(128, 128)
	Criatura.anim(f, &"parado", FOLHA, t, [0, 1, 2, 1], 10.0)
	Criatura.anim(f, &"andar", FOLHA, t, [0, 1, 2, 1], 12.0)
	Criatura.anim(f, &"preparo", FOLHA, t, [3], 1.0)
	Criatura.anim(f, &"ataque", FOLHA, t, [4], 1.0, false)
	Criatura.anim(f, &"dano", FOLHA, t, [5], 1.0)


func _pensar(delta: float) -> Vector2:
	_fase += delta * 5.0
	_tempo_golpe += delta
	var balanco := Vector2(0, sin(_fase)) * 0.5
	match _golpe:
		Golpe.PREPARANDO:
			animacao = &"preparo"
			if _alvo:
				_dir_mergulho = (_alvo.global_position - global_position).normalized()
				_olhar_para(_alvo.global_position)
			if _tempo_golpe >= TEMPO_MIRA:
				_mudar_golpe(Golpe.BATENDO)
				_mordeu = false
			return Vector2.ZERO
		Golpe.BATENDO:
			animacao = &"ataque"
			if not _mordeu and _alvo and _alvo.global_position.distance_to(global_position) < 12.0:
				_mordeu = true
				golpear(_alvo, dano)
			if _tempo_golpe >= TEMPO_MERGULHO or _mordeu:
				_mudar_golpe(Golpe.RECUPERANDO)
				_recarga = randf_range(1.4, 2.2) * Combate.ritmo_inimigo(self)
			return _dir_mergulho * VEL_MERGULHO
		Golpe.RECUPERANDO:
			if _tempo_golpe >= TEMPO_FUGA:
				_mudar_golpe(Golpe.LIVRE)
			return _andar(-_dir_mergulho.rotated(0.6)) * 1.2  # sobe e se afasta
	if _alvo == null:
		animacao = &"andar"
		return _passear(delta, 60.0) + balanco
	var para := _alvo.global_position - global_position
	var d := para.length()
	_olhar_para(_alvo.global_position)
	if _recarga <= 0.0 and d < RAIO_RODEAR * 1.4 and efeitos.pode_atacar():
		_mudar_golpe(Golpe.PREPARANDO)
		return Vector2.ZERO
	# Rodeia o alvo: perto da borda do círculo, gira em volta.
	var volta := para.normalized().orthogonal()
	var ajuste := para.normalized() * clampf((d - RAIO_RODEAR) / 20.0, -1.0, 1.0)
	animacao = &"andar"
	return (volta * 0.6 + ajuste + balanco).limit_length(1.0)
