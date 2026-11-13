class_name Efeito
extends AnimatedSprite2D
## Efeito visual que toca uma vez e some (poeira, giro, congelar...).
## Criado em todos os jogadores pela World (efeito_todos), nunca sincronizado.
## [textura, tamanho do quadro, quadros, fps, escala, (deslocamento em pixels da arte)].
## A arte do Tiny Swords é feita para tile de 64 px: escala 0,25 no nosso mundo. Os efeitos
## do Pixelbolt (art/fx_receitas/) já vêm no pixel do pacote e também entram com 0,25.
##
## As PEÇAS (arte das habilidades novas, pedido L33) são desenhos inteiros, um por arquivo,
## também com escala 0,25. Ver PECAS.

const TABELA := {
	&"giro": [preload("res://assets/sprites/tiny/fx/giro.png"), Vector2i(94, 67), 1, 4.0, 0.25],
	&"poeira": [preload("res://assets/tiny_swords/fx/poeira.png"), Vector2i(64, 64), 8, 18.0, 0.25],
	&"congelar": [preload("res://assets/sprites/tiny/fx/cristais.png"), Vector2i(81, 63), 1, 1.5, 0.25],
	&"explosao": [preload("res://assets/tiny_swords/fx/explosao.png"), Vector2i(192, 192), 8, 20.0, 0.3],
	&"subir_nivel": [preload("res://assets/tiny_swords/fx/brilho.png"), Vector2i(192, 192), 11, 14.0, 0.25],
	# Chamas do pacote (as da árvore queimando): Rastro de chamas, Tornado de fogo.
	&"fogo": [preload("res://assets/tiny_swords/fx/fogo.png"), Vector2i(64, 64), 8, 12.0, 0.25, Vector2(0, -24)],
	# Habilidades 3 e 4 (Pixelbolt). O deslocamento põe o "chão" do desenho no ponto do efeito.
	&"escudo": [preload("res://assets/sprites/tiny/fx/escudo.png"), Vector2i(120, 120), 12, 12.5, 0.25],
	&"furia": [preload("res://assets/sprites/tiny/fx/furia.png"), Vector2i(128, 128), 19, 15.8, 0.25, Vector2(0, -16)],
	&"raio": [preload("res://assets/sprites/tiny/fx/raio.png"), Vector2i(144, 156), 12, 18.7, 0.25, Vector2(0, -50)],
	&"nova_gelo": [preload("res://assets/sprites/tiny/fx/nova_gelo.png"), Vector2i(160, 160), 22, 16.8, 0.25, Vector2(0, -20)],
}

## Pasta da arte das habilidades novas (pedido L33).
const HAB := "res://assets/sprites/tiny/habilidades/"

## Peças das habilidades novas: desenhos inteiros (um quadro por arquivo).
##   t: quadros; fps: velocidade (com 2 quadros ou mais, a animação repete);
##   pe: quanto do desenho fica acima do ponto (0 = centrado; 0,5 = a base no ponto);
##   chao: deitada no chão (embaixo de quem pisa); z: camada (a cúpula e a nuvem por cima);
##   alfa: transparência;
##   dura: segundos na tela quando toca uma vez (depois some aos poucos);
##   gira: radianos por segundo; orbita: raio (x, y) da volta em torno do ponto e
##   orbita_vel: radianos por segundo da volta (o Martelo giratório em volta do Clérigo).
const PECAS := {
	&"rede_chao": {t = [preload("res://assets/sprites/tiny/habilidades/rede_chao.png")], pe = 0.3},
	&"estandarte": {t = [preload("res://assets/sprites/tiny/habilidades/estandarte.png")], pe = 0.5},
	&"martelo_orbita": {t = [preload("res://assets/sprites/tiny/habilidades/martelo_luz.png")], gira = 14.0, orbita = Vector2(20, 9), orbita_vel = 7.0},
	&"poca_acido": {t = [preload("res://assets/sprites/tiny/habilidades/poca_acido.png")], pe = 0.0, chao = true},
	&"nuvem_toxica": {t = [preload("res://assets/sprites/tiny/habilidades/nuvem_toxica.png")], pe = 0.2, z = 2, alfa = 0.65},
	&"circulo_cura": {t = [preload("res://assets/sprites/tiny/habilidades/circulo_cura.png")], pe = 0.0, chao = true},
	&"espinhos": {t = [preload("res://assets/sprites/tiny/habilidades/espinhos.png")], pe = 0.45, dura = 1.2},
	&"fenda": {t = [preload("res://assets/sprites/tiny/habilidades/fenda.png")], pe = 0.0, chao = true},
	&"muralha_gelo": {t = [preload("res://assets/sprites/tiny/habilidades/muralha_gelo.png")], pe = 0.45},
	&"cupula_luz": {t = [preload("res://assets/sprites/tiny/habilidades/cupula_luz.png")], pe = 0.3, z = 2, alfa = 0.55},
	&"parede_luz": {t = [preload("res://assets/sprites/tiny/habilidades/parede_luz.png")], pe = 0.0, alfa = 0.85},
	&"meteoro": {t = [preload("res://assets/sprites/tiny/habilidades/meteoro.png")], pe = 0.0, dura = 0.4},
	&"tornado": {t = [preload("res://assets/sprites/tiny/habilidades/tornado_a.png"), preload("res://assets/sprites/tiny/habilidades/tornado_b.png")], fps = 10.0, pe = 0.48},
	&"pedra_rolando": {t = [preload("res://assets/sprites/tiny/habilidades/pedra_rolando.png")], pe = 0.0, gira = 12.0},
	&"nevasca": {t = [preload("res://assets/sprites/tiny/habilidades/nevasca.png")], pe = 0.35, chao = true},
	&"marca_alvo": {t = [preload("res://assets/sprites/tiny/habilidades/marca_alvo.png")], pe = 0.0},
	&"marca_morte": {t = [preload("res://assets/sprites/tiny/habilidades/marca_morte.png")], pe = 0.0},
	&"coluna_luz": {t = [preload("res://assets/sprites/tiny/habilidades/coluna_luz.png")], pe = 0.48, dura = 0.45},
	&"forma_relampago": {t = [preload("res://assets/sprites/tiny/habilidades/forma_relampago.png")], pe = 0.48, dura = 0.25},
}

## Segundos do "sumir aos poucos" (no fim de uma peça ou de um efeito em laço).
const SUMIR := 0.3

## Peça girando (rad/s), em volta do ponto (`orbita`), e quando some (só peças que tocam uma vez).
var gira := 0.0
var orbita := Vector2.ZERO
var orbita_vel := 0.0
var centro := Vector2.ZERO
## Peça deitada no chão (poça, círculo, nuvem...): fica embaixo de quem está em cima dela.
var no_chao := false
var _angulo := 0.0
var _dura := -1.0
var _base := Vector2.ZERO

## No chão: o ponto de ordenação (y-sort das Entidades) sobe este tanto acima da peça, e o
## desenho desce o mesmo tanto; assim quem pisa nela é desenhado por cima.
const ACIMA_NO_CHAO := 96.0


## Escala de uma peça: 0,25 (o pixel do pacote) × `mult`. Refaz o deslocamento do desenho
## (depois de mudar a `rotation`, chame de novo).
func ajustar_escala(mult: float) -> void:
	scale = Vector2(0.25, 0.25) * mult
	offset = _base
	position = centro
	if no_chao:
		position.y -= ACIMA_NO_CHAO
		offset += Vector2(0, ACIMA_NO_CHAO).rotated(-rotation) / scale.x


## `repetir`: o efeito fica tocando em laço até alguém tirá-lo (o escudo do Bloqueio).
static func criar(nome: StringName, pos: Vector2, repetir := false) -> Efeito:
	var e := Efeito.new()
	if PECAS.has(nome):
		return _criar_peca(e, PECAS[nome], pos, repetir)
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


static func _criar_peca(e: Efeito, dados: Dictionary, pos: Vector2, repetir: bool) -> Efeito:
	var quadros: Array[Texture2D] = []
	quadros.assign(dados.t)
	var f := SpriteFrames.new()
	f.remove_animation(&"default")
	SpriteSheets.adicionar_quadros(f, &"tocar", quadros, float(dados.get(&"fps", 1.0)), true)
	e.sprite_frames = f
	e._base = Vector2(0, -quadros[0].get_height() * float(dados.get(&"pe", 0.0)))
	e.no_chao = bool(dados.get(&"chao", false))
	e.position = pos
	e.centro = pos
	e.ajustar_escala(1.0)
	# z 0: o y-sort das Entidades decide quem fica na frente (a cúpula pede z 2: por cima).
	e.z_index = int(dados.get(&"z", 0))
	e.modulate.a = float(dados.get(&"alfa", 1.0))  # a nuvem deixa ver quem está dentro
	e.gira = float(dados.get(&"gira", 0.0))
	e.orbita = dados.get(&"orbita", Vector2.ZERO)
	e.orbita_vel = float(dados.get(&"orbita_vel", 0.0))
	if not repetir:
		e._dura = float(dados.get(&"dura", 0.6))
	e.play(&"tocar")
	return e


## Multiplicador de escala para a peça `nome` cobrir uma área de raio `raio` (a largura do
## desenho = o diâmetro × `fator`). Arredondado para um número inteiro: cada pixel da arte
## vira um quadrado inteiro de pixels na tela (fica nítido).
static func escala_para_raio(nome: StringName, raio: float, fator := 1.0) -> float:
	var dados: Dictionary = PECAS.get(nome, {})
	if dados.is_empty():
		return 1.0
	var largura := (dados.t[0] as Texture2D).get_width() * 0.25
	return maxf(1.0, roundf(2.0 * raio * fator / largura))


## Ponto (no espaço de `alvo`) logo acima da cabeça dele e do selo do nível: onde ficam a
## marca do alvo e a caveira da Marca da morte.
static func acima_da_cabeca(alvo: Node) -> Vector2:
	var barra := alvo.get_node_or_null("BarraCabeca") as BarraCabeca
	if barra:
		return Vector2(0, -(barra.altura + 13.0))
	return Vector2(0, -30.0)


## Some aos poucos e sai do mundo.
func sumir(segundos := SUMIR) -> void:
	if is_queued_for_deletion() or has_meta(&"sumindo"):
		return
	set_meta(&"sumindo", true)
	if not is_inside_tree():
		queue_free()
		return
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, segundos)
	t.tween_callback(queue_free)


func _process(delta: float) -> void:
	if gira != 0.0:
		rotation += gira * delta
	if orbita != Vector2.ZERO:
		_angulo += orbita_vel * delta
		position = centro + Vector2(cos(_angulo) * orbita.x, sin(_angulo) * orbita.y)
		# Atrás de quem está no centro (o dono) na metade de cima da volta.
		show_behind_parent = sin(_angulo) < 0.0
		z_index = 0
	if _dura >= 0.0:
		_dura -= delta
		if _dura < 0.0:
			sumir()
