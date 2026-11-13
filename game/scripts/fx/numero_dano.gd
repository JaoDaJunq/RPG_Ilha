class_name NumeroDano
extends Node2D
## Número de dano que sobe de quem apanhou e some (L40). Local de cada máquina (quem chama
## é o ReacaoGolpe, que roda em todas). O texto fica numa camada de tela, como a barra em
## cima da cabeça (BarraCabeca): nítido com o zoom 4, em pixels inteiros.
## Pequeno e legível; o crítico é maior e amarelo.

const CAMADA := 6  # acima das barras das criaturas (5) e abaixo do HUD (10)
const SUBIDA := 12.0  # px do mundo
const DURACAO := 0.65
const SUMIR := 0.25  # os últimos segundos vão apagando
const TAMANHO := 13
const TAMANHO_CRITICO := 19
const COR := Color("f4ead2")
const COR_CRITICO := Color("f2c75c")

var _t := 0.0
var _inicio := Vector2.ZERO
var _rotulo: Label
var _camada: CanvasLayer


## Põe um número sobre `quem` (perto da cabeça). Devolve o número (os testes olham).
static func mostrar(quem: Node2D, valor: float, critico := false, altura := 18.0) -> NumeroDano:
	if quem == null or not quem.is_inside_tree():
		return null
	var n := NumeroDano.new()
	n.name = "NumeroDano"
	var pai := quem.get_parent() if quem.get_parent() is Node2D else quem
	pai.add_child(n)
	n._inicio = quem.global_position + Vector2(randf_range(-4.0, 4.0), -altura)
	n.global_position = n._inicio
	n._montar(texto(valor), critico)
	return n


## 2,4 → "2,4"; 12,3 → "12"; menos de 0,1 → "0,1".
static func texto(valor: float) -> String:
	valor = maxf(valor, 0.1)
	if valor >= 10.0 or is_equal_approx(valor, roundf(valor)):
		return str(roundi(valor))
	return ("%.1f" % valor).replace(".", ",")


func texto_atual() -> String:
	return _rotulo.text if _rotulo else ""


func eh_critico() -> bool:
	return _rotulo != null and _rotulo.get_theme_font_size(&"font_size") == TAMANHO_CRITICO


func _montar(t: String, critico: bool) -> void:
	_camada = CanvasLayer.new()
	_camada.layer = CAMADA
	add_child(_camada)
	_rotulo = Label.new()
	_rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rotulo.text = t + ("!" if critico else "")
	_rotulo.add_theme_font_override(&"font", Tema.fonte_negrito())
	_rotulo.add_theme_font_size_override(&"font_size", TAMANHO_CRITICO if critico else TAMANHO)
	_rotulo.add_theme_color_override(&"font_color", COR_CRITICO if critico else COR)
	_rotulo.add_theme_color_override(&"font_outline_color", Tema.COR_CONTORNO)
	_rotulo.add_theme_constant_override(&"outline_size", 4)
	_camada.add_child(_rotulo)
	_posicionar()


func _process(delta: float) -> void:
	_t += delta
	if _t >= DURACAO:
		queue_free()
		return
	# Sobe rápido no começo e vai parando (ease out).
	var k := 1.0 - pow(1.0 - _t / DURACAO, 3.0)
	global_position = _inicio - Vector2(0, SUBIDA * k)
	_rotulo.modulate.a = clampf((DURACAO - _t) / SUMIR, 0.0, 1.0)
	_posicionar()


func _posicionar() -> void:
	if not is_inside_tree():
		return
	var tela := get_viewport().get_canvas_transform() * global_position
	_rotulo.position = (tela - _rotulo.get_combined_minimum_size() / 2.0).round()
