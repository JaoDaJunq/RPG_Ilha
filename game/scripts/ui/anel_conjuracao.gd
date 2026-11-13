class_name AnelConjuracao
extends Node2D
## O sinal da conjuração (indicador de INTERFACE, como a roda de fôlego do Zelda): um anel ao
## lado do personagem que vai enchendo. VERMELHO = ainda não sai nada; AMARELO = quase (os
## últimos 25%); VERDE = pode soltar, com uma piscadinha (cresce e brilha rapidinho).
## Nas habilidades de carga (Tiro carregado), depois do verde o miolo vai enchendo de luz
## e pisca de novo quando a carga está cheia.
## Quem manda os números é a Conjuracao (dono ou o que o anfitrião avisou).

const COR_VERMELHO := Color("e0483a")
const COR_AMARELO := Color("f2c84b")
const COR_VERDE := Color("6fdc5c")
const COR_CARGA := Color("fff4c2")
const COR_FUNDO := Color(0.07, 0.07, 0.11, 0.38)
const COR_TRILHO := Color(0.28, 0.27, 0.33, 0.95)
const COR_CONTORNO := Color(0.05, 0.05, 0.08, 0.85)
## Em pixels do mundo (a câmera aproxima 4x): raio 5 → um anel de uns 40 px na tela.
const RAIO := 5.0
const LARGURA := 1.75
## Do lado do corpo, na altura do peito (não cobre o rosto nem a barra de vida).
const POSICAO := Vector2(14, -21)
const TEMPO_PISCAR := 0.22
const TEMPO_SUMIR := 0.15

var progresso := 0.0
var carga := -1.0
var pronta := false
var _piscar := 0.0
var _sumindo := 0.0
var _visivel := false


func _ready() -> void:
	position = POSICAO
	z_index = 20
	z_as_relative = false
	visible = false


func mostrar(prog: float, carga_extra: float) -> void:
	progresso = prog
	carga = carga_extra
	pronta = prog >= 1.0
	_visivel = true
	_sumindo = 0.0
	visible = true
	modulate.a = 1.0


func esconder() -> void:
	if not _visivel:
		return
	_visivel = false
	_sumindo = TEMPO_SUMIR
	pronta = false


func piscar() -> void:
	_piscar = TEMPO_PISCAR


func cor() -> Color:
	if pronta:
		return COR_VERDE
	return COR_AMARELO if progresso >= Conjuracao.AMARELO_A_PARTIR else COR_VERMELHO


func _process(delta: float) -> void:
	if not _visivel:
		if _sumindo > 0.0:
			_sumindo = maxf(0.0, _sumindo - delta)
			modulate.a = _sumindo / TEMPO_SUMIR
			if _sumindo <= 0.0:
				visible = false
		return
	if _piscar > 0.0:
		_piscar = maxf(0.0, _piscar - delta)
	# Piscadinha: cresce até 1,4x e volta, e o brilho sobe junto.
	var t := _piscar / TEMPO_PISCAR
	var s := 1.0 + 0.4 * sin(t * PI)
	scale = Vector2(s, s)
	queue_redraw()


func _draw() -> void:
	var c := cor()
	if _piscar > 0.0:
		c = c.lerp(Color.WHITE, 0.55 * sin(_piscar / TEMPO_PISCAR * PI))
	# Fundo escuro e trilho, para ler em cima da grama, da areia ou da água.
	draw_arc(Vector2.ZERO, RAIO, 0.0, TAU, 40, COR_CONTORNO, LARGURA + 1.0, true)
	draw_circle(Vector2.ZERO, RAIO - LARGURA * 0.5, COR_FUNDO, true, -1.0, true)
	draw_arc(Vector2.ZERO, RAIO, 0.0, TAU, 40, COR_TRILHO, LARGURA, true)
	# O arco que enche, a partir de cima, no sentido do relógio.
	if progresso > 0.0:
		var fim := -PI / 2.0 + TAU * progresso
		draw_arc(Vector2.ZERO, RAIO, -PI / 2.0, fim, maxi(4, int(40 * progresso)), c, LARGURA, true)
	# Carga extra (Tiro carregado): o miolo enche de luz.
	if pronta and carga > 0.0:
		var miolo := (RAIO - LARGURA * 0.5 - 0.4) * clampf(carga, 0.0, 1.0)
		var cc := COR_CARGA if carga < 1.0 else COR_VERDE.lerp(Color.WHITE, 0.6)
		draw_circle(Vector2.ZERO, miolo, cc, true, -1.0, true)
	elif pronta:
		draw_circle(Vector2.ZERO, 1.2, c, true, -1.0, true)
