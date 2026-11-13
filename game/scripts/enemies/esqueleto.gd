class_name Esqueleto
extends Criatura
## Esqueleto de musgo das Ruínas (L39 folha 07): corpo a corpo com a espada velha. Derrotado
## SEM fogo, desmonta num montinho de ossos e LEVANTA de novo depois de TEMPO_LEVANTAR. Para
## acabar de vez: fogo (bola de fogo, queimadura, mina...) ou bater nos ossos com uma TOCHA
## na mão. O fogo ganha uso.
## Folha (128 px): 0 parado, 1-2 passos, 3 espada erguida, 4 golpe, 5 montinho de ossos.

const FOLHA := preload("res://assets/sprites/tiny/inimigos/esqueleto.png")
const TEMPO_LEVANTAR := 7.0
const VIDA_AO_LEVANTAR := 0.6
const FOGO: Array[StringName] = [&"fogo", EfeitosEstado.QUEIMADURA]

## Desmontado no chão (sincronizado: os outros veem o montinho).
@export var desmontado := false
var _tempo_desmontado := 0.0
var _desmontou_vezes := 0


func _configurar() -> void:
	nome = "Esqueleto de musgo"
	vida_base = 12.0
	velocidade = 24.0
	raio_visao = 110.0
	dano = 10.0
	nivel = 3
	xp = 18
	saque = [[&"osso", 1, 2], [&"cristal", 1, 1, 0.2], [&"erva", 0, 1]]
	resistencias = {&"veneno": 0.5}


func _montar_animacoes(f: SpriteFrames) -> void:
	var t := Vector2i(128, 128)
	Criatura.anim(f, &"parado", FOLHA, t, [0], 1.0)
	Criatura.anim(f, &"andar", FOLHA, t, [1, 0, 2, 0], 6.0)
	Criatura.anim(f, &"preparo", FOLHA, t, [3], 1.0)
	Criatura.anim(f, &"ataque", FOLHA, t, [4], 1.0, false)
	Criatura.anim(f, &"desmontado", FOLHA, t, [5], 1.0)


func _pensar(delta: float) -> Vector2:
	if desmontado:
		animacao = &"desmontado"
		_tempo_desmontado += delta
		if _tempo_desmontado >= TEMPO_LEVANTAR:
			_levantar()
		return Vector2.ZERO
	return _corpo_a_corpo(delta, 16.0, 0.5, 1.2)


func persegue(jogador: Node) -> bool:
	return not desmontado and super.persegue(jogador)


func _on_atingido(quantidade: float, tipo: StringName, origem: Node) -> void:
	if not desmontado:
		super._on_atingido(quantidade, tipo, origem)
		return
	# Os ossos no chão: só o fogo (ou a tocha na mão) acaba de vez.
	if tipo in FOGO or _tocha_na_mao(origem):
		desmontado = false
		_ultimo_tipo = &"fogo"
		World.efeito_todos(self, &"fogo", global_position)
		_morrer()
	elif origem is Player:
		(origem as Player).avisar("Os ossos se mexem... Queime o esqueleto (fogo ou tocha na mão) senão ele levanta!")


func _tocha_na_mao(origem: Node) -> bool:
	if not origem is Player:
		return false
	var item := (origem as Player).item_na_mao()
	return item != null and item.id == &"tocha"


func _on_morreu() -> void:
	var queimando := efeitos.tem(EfeitosEstado.QUEIMADURA)
	if _ultimo_tipo in FOGO or queimando:
		_morrer()
		return
	# Sem fogo: desmonta e levanta depois.
	desmontado = true
	_tempo_desmontado = 0.0
	_desmontou_vezes += 1
	_mudar_golpe(Golpe.LIVRE)
	animacao = &"desmontado"
	World.efeito_todos(self, &"poeira", global_position)
	World.avisar_todos(self, "O esqueleto desmontou... mas vai levantar! Só o fogo acaba com ele.")


func _levantar() -> void:
	desmontado = false
	vida.reviver(VIDA_AO_LEVANTAR)
	_piscar.rpc(vida.atual, vida.maximo)
	animacao = &"parado"
	World.efeito_todos(self, &"poeira", global_position)
