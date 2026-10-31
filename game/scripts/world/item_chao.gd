class_name ItemChao
extends Node2D
## Pilha de itens caída no chão (saque de bicho, slime e baú quebrado), como no Minecraft.
## Só o anfitrião decide quem pega: encostando (~10 px) a pilha vai para o inventário de
## quem chegou; o que não couber fica no chão. Perto (~20 px) a pilha desliza até o jogador.
## Some sozinha depois de 5 minutos. Não é salva com o mundo.
## Rede: item, quantidade, ponto de partida e posição vão no nascimento (MultiplayerSpawner);
## a quantidade e a posição seguem sincronizadas. O pulinho de saída e o balanço são só
## visuais, cada jogo faz o seu.

const SOMBRA := preload("res://assets/sprites/tiny/bonecos/humano/base/sombra.png")
## Os ícones são feitos para a interface (8x): 0,3 deixa o ícone com uns 11 px no mundo.
const ESCALA_ICONE := 0.3
const ESCALA_SOMBRA := 0.3
## Segundos até poder pegar (dá tempo de ver o item saltar).
const ATRASO_PEGAR := 0.6
const RAIO_PEGAR := 10.0
const RAIO_IMA := 20.0
const VEL_IMA := 110.0
const VIDA_TOTAL := 300.0
const TEMPO_SALTO := 0.35
const ALTURA_SALTO := 14.0

@export var item: StringName = &"madeira"
@export var quantidade := 1
## De onde o item saiu (só para o salto visual).
@export var origem := Vector2.ZERO

var _idade := 0.0
var _recusado := 0.0  # inventário cheio: não insiste por um tempo
var _fase := 0.0
var _meia := 0.0  # metade da altura do ícone no mundo
var _saida := Vector2.ZERO  # de onde saiu, em relação ao ponto onde caiu
@onready var _icone: Sprite2D = $Icone
@onready var _sombra: Sprite2D = $Sombra


func _ready() -> void:
	add_to_group(&"itens_chao")
	var dados := ItemData.carregar(item)
	_sombra.texture = SOMBRA
	_sombra.scale = Vector2.ONE * ESCALA_SOMBRA
	_icone.texture = dados.icone
	_icone.modulate = dados.cor_icone
	_icone.scale = Vector2.ONE * ESCALA_ICONE
	_meia = dados.icone.get_height() * ESCALA_ICONE / 2.0
	_fase = randf() * TAU
	_saida = origem - global_position if origem != Vector2.ZERO else Vector2.ZERO
	_mostrar()


## Salto de saída (do ponto de partida até onde caiu) e depois o balanço.
func _mostrar() -> void:
	if _idade < TEMPO_SALTO:
		var k := _idade / TEMPO_SALTO
		var chao := _saida * (1.0 - k)
		_sombra.position = chao + Vector2(0, -1)
		_sombra.visible = k > 0.4
		_icone.position = chao + Vector2(0, -_meia - 1.5 - sin(k * PI) * ALTURA_SALTO)
	else:
		_sombra.position = Vector2(0, -1)
		_sombra.visible = true
		_icone.position = Vector2(0, -_meia - 2.0 - sin(_idade * 3.0 + _fase))


func _process(delta: float) -> void:
	_idade += delta
	_mostrar()


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if _idade > VIDA_TOTAL:
		queue_free()
		return
	_recusado = maxf(0.0, _recusado - delta)
	if _idade < ATRASO_PEGAR or _recusado > 0.0:
		return
	var perto: Player = null
	var menor := RAIO_IMA
	for j in get_tree().get_nodes_in_group(&"jogadores"):
		var d := global_position.distance_to((j as Node2D).global_position)
		if d < menor:
			menor = d
			perto = j
	if perto == null:
		return
	if menor > RAIO_PEGAR:
		global_position = global_position.move_toward(perto.global_position, VEL_IMA * delta)
		return
	_pegar(perto)


## Só o anfitrião: guarda no inventário de quem chegou; a sobra fica no chão.
func _pegar(p: Player) -> void:
	var sobra := p.inventario.adicionar(item, quantidade)
	var pegou := quantidade - sobra
	if pegou > 0:
		p.avisar("+%d %s" % [pegou, ItemData.carregar(item).nome.to_lower()], &"item")
	if sobra <= 0:
		queue_free()
		return
	quantidade = sobra
	if pegou <= 0:
		_recusado = 1.0
