class_name HealthComponent
extends Node
## Vida de qualquer coisa que pode tomar dano.

signal mudou(atual: float, maximo: float)
signal dano_recebido(quantidade: float, tipo: StringName)
signal morreu

@export var maximo := 100.0
## Tempo sem tomar dano depois de um acerto (0 = sem proteção).
@export var invulneravel_por := 0.0

var atual: float
## Escudo temporário (Fé do Clérigo): some antes da vida de verdade.
var escudo := 0.0
## Quem é dono desta vida pode ajustar o dano recebido (passivas da árvore de habilidades):
## func(quantidade: float, tipo: StringName) -> float. Roda depois das reduções.
var ajuste_dano: Callable
var _protecao := 0.0
var _reducao := 0.0
var _reducao_restante := 0.0
var _escudo_restante := 0.0


func _ready() -> void:
	atual = maximo


func _process(delta: float) -> void:
	_protecao = maxf(0.0, _protecao - delta)
	_reducao_restante = maxf(0.0, _reducao_restante - delta)
	if _escudo_restante > 0.0:
		_escudo_restante -= delta
		if _escudo_restante <= 0.0:
			escudo = 0.0


func esta_vivo() -> bool:
	return atual > 0.0


func protegido() -> bool:
	return _protecao > 0.0


func tomar_dano(quantidade: float, tipo: StringName = &"fisico") -> bool:
	if not esta_vivo() or protegido() or quantidade <= 0.0:
		return false
	if _reducao_restante > 0.0:
		quantidade *= 1.0 - _reducao
	if ajuste_dano.is_valid():
		quantidade = maxf(0.0, ajuste_dano.call(quantidade, tipo))
	if escudo > 0.0:
		var absorvido := minf(escudo, quantidade)
		escudo -= absorvido
		quantidade -= absorvido
	_protecao = invulneravel_por
	if quantidade <= 0.0:
		return true  # o escudo segurou tudo
	atual = maxf(0.0, atual - quantidade)
	dano_recebido.emit(quantidade, tipo)
	mudou.emit(atual, maximo)
	if atual <= 0.0:
		morreu.emit()
	return true


## Fica sem tomar dano por alguns segundos (esquiva).
func proteger(segundos: float) -> void:
	_protecao = maxf(_protecao, segundos)


## Tira a proteção de depois do último golpe (golpes em série de uma habilidade, como o
## Mil cortes do Ladino: cada corte conta, mesmo chegando antes dela acabar).
func tirar_protecao() -> void:
	_protecao = 0.0


## Toma menos dano por alguns segundos (Bloqueio): `fracao` 0,6 = 60% a menos.
## Uma redução mais fraca não derruba a mais forte que ainda está valendo (Bloqueio + Escudo).
func reduzir_dano(fracao: float, segundos: float) -> void:
	fracao = clampf(fracao, 0.0, 1.0)
	if _reducao_restante > 0.0 and fracao < _reducao:
		return
	_reducao = fracao
	_reducao_restante = segundos


func reducao_ativa() -> bool:
	return _reducao_restante > 0.0


## Ganha `quantidade` de escudo por `segundos` (soma com o que já tinha, até a vida máxima).
func dar_escudo(quantidade: float, segundos: float) -> void:
	if quantidade <= 0.0:
		return
	escudo = minf(maximo, escudo + quantidade)
	_escudo_restante = maxf(_escudo_restante, segundos)


## Cura e devolve quanto passou da vida máxima (a Fé transforma isso em escudo).
func curar(quantidade: float) -> float:
	var sobra := maxf(0.0, atual + quantidade - maximo)
	atual = minf(maximo, atual + quantidade)
	mudou.emit(atual, maximo)
	return sobra


func curar_tudo() -> void:
	atual = maximo
	_protecao = 0.0
	mudou.emit(atual, maximo)
