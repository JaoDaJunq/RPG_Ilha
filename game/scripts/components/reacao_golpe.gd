class_name ReacaoGolpe
extends Node
## Como um inimigo ou animal reage ao apanhar (L40). Serve para QUALQUER criatura: os
## inimigos novos só precisam disto (ver design/combate.md, "Inimigo novo"):
##
##   var reacao: ReacaoGolpe
##   func _ready() -> void:
##       reacao = ReacaoGolpe.em(self, 1.0)      # em TODAS as máquinas (o nome é fixo)
##   func _physics_process(delta) -> void:       # no anfitrião, ao andar:
##       velocity = minha_direcao * velocidade + reacao.empurrao(delta)
##       reacao.armadura = atacando               # atacando: o golpe dele não é cortado
##
## A criatura precisa de filhos "Visual" (o desenho), "HealthComponent" e "Hurtbox"; a
## "BarraCabeca" é opcional. O componente escuta o HealthComponent no anfitrião: todo dano
## de verdade (passou da proteção e do escudo) dispara a reação. Se veio de um golpe (pela
## Hurtbox), empurra para longe de quem bateu, pela força do golpe dividida pelo `peso`.
##
## Todos veem (RPC): o desenho pisca branco, sacode, para por alguns quadros (hit stop), o
## número do dano sobe (crítico maior e amarelo), o som do acerto toca com o tom variando e
## a barra de vida aparece (com a vida, para os clientes). Nada disso mexe no tempo do jogo.

const NOME := "ReacaoGolpe"
const PISCAR := preload("res://shaders/piscar_branco.gdshader")
const TEMPO_PISCAR := 0.12
const TEMPO_SACUDIR := 0.14
const SACUDIR_PX := 1.0
## Golpe forte (força acima disto): sacode mais e o som sai mais grave.
const FORTE := 2.0

## Avisa em todas as máquinas que apanhou (o slime mostra o quadro achatado, por exemplo).
signal reagiu(quantidade: float, critico: bool, forca: float)

## Mais pesado = empurrado menos (1 = slime; o javali é 1,6).
@export var peso := 1.0
## Ligado pela criatura enquanto ataca: não é empurrado (só no anfitrião).
var armadura := false
## Altura do número de dano acima dos pés.
var altura_numero := 18.0

var _dono: Node2D
var _visual: CanvasItem
var _vida: HealthComponent
var _hurtbox: Hurtbox
var _barra: BarraCabeca
var _material: ShaderMaterial
var _empurrao := Vector2.ZERO
var _base_visual := Vector2.ZERO
var _sacudir := 0.0
var _forca_sacudir := 0.0
var _parado := 0.0
var _piscar := 0.0


## Cria o componente como filho de `dono` (chamar no _ready, em todas as máquinas).
static func em(dono: Node2D, peso_dono := 1.0) -> ReacaoGolpe:
	var r := ReacaoGolpe.new()
	r.name = NOME
	r.peso = peso_dono
	dono.add_child(r)
	return r


static func de(no: Node) -> ReacaoGolpe:
	return no.get_node_or_null(NOME) as ReacaoGolpe if no else null


func _ready() -> void:
	_dono = get_parent() as Node2D
	_visual = _dono.get_node_or_null("Visual") as CanvasItem
	_vida = _dono.get_node_or_null("HealthComponent") as HealthComponent
	_hurtbox = _dono.get_node_or_null("Hurtbox") as Hurtbox
	_barra = _dono.get_node_or_null("BarraCabeca") as BarraCabeca
	if _visual is Node2D:
		_base_visual = (_visual as Node2D).position
	if _visual and _visual.material == null:
		_material = ShaderMaterial.new()
		_material.shader = PISCAR
		_visual.material = _material
	if multiplayer.is_server() and _vida:
		_vida.dano_recebido.connect(_on_dano)


## Empurrão desta física (somar na velocity). Vai freando sozinho.
func empurrao(delta: float) -> Vector2:
	var v := _empurrao
	_empurrao = _empurrao.move_toward(Vector2.ZERO, Combate.FREIO * delta)
	return v


func empurrado() -> bool:
	return _empurrao.length() > 1.0


## Empurra com esta velocidade (px/s) agora (anfitrião). A armadura segura.
func empurrar(velocidade: Vector2) -> void:
	if armadura:
		return
	_empurrao = velocidade / maxf(peso, 0.1)


## Tira o empurrão (puxado por habilidade, preso...).
func parar_empurrao() -> void:
	_empurrao = Vector2.ZERO


func _on_dano(quantidade: float, _tipo: StringName) -> void:
	var golpe := _hurtbox != null and _hurtbox.em_golpe
	var forca := _hurtbox.forca_golpe if golpe else 0.0
	var critico := _hurtbox.critico_golpe if golpe else false
	if golpe and forca > 0.0 and _hurtbox.origem_golpe is Node2D:
		var dir := _dono.global_position - (_hurtbox.origem_golpe as Node2D).global_position
		if dir.length() > 0.1:
			empurrar(dir.normalized() * Combate.empurrao(forca))
	_mostrar.rpc(quantidade, critico, forca, _vida.atual, _vida.maximo)


@rpc("authority", "call_local", "reliable")
func _mostrar(quantidade: float, critico: bool, forca: float, atual: float, maximo: float) -> void:
	if not multiplayer.is_server() and _vida:
		_vida.maximo = maximo
		_vida.atual = atual
	if _barra:
		_barra.mostrar_dano()
	NumeroDano.mostrar(_dono, quantidade, critico, altura_numero)
	var forte := forca >= FORTE or critico
	Sfx.tocar(&"acerto", -7.0 if forte else -10.0, 0.8 if forte else 1.0, 0.12)
	_piscar = TEMPO_PISCAR
	if forca > 0.0:
		_sacudir = TEMPO_SACUDIR
		_forca_sacudir = SACUDIR_PX * (2.0 if forte else 1.0)
		_parado = Combate.HIT_STOP_FORTE if forte else Combate.HIT_STOP
	reagiu.emit(quantidade, critico, forca)


## Está no hit stop agora? (o desenho parado por alguns quadros; para os testes)
func em_hit_stop() -> bool:
	return _parado > 0.0


func branco() -> float:
	return float(_material.get_shader_parameter(&"branco")) if _material else 0.0


func _process(delta: float) -> void:
	if _visual == null:
		return
	if _piscar > 0.0:
		_piscar = maxf(0.0, _piscar - delta)
	if _material:
		_material.set_shader_parameter(&"branco", clampf(_piscar / TEMPO_PISCAR, 0.0, 1.0) * 0.85)
	var sprite := _visual as AnimatedSprite2D
	if _parado > 0.0:
		_parado = maxf(0.0, _parado - delta)
		if sprite:
			sprite.speed_scale = 0.0 if _parado > 0.0 else 1.0
	if _visual is Node2D:
		var n := _visual as Node2D
		if _sacudir > 0.0:
			_sacudir = maxf(0.0, _sacudir - delta)
			var k := _sacudir / TEMPO_SACUDIR
			n.position = _base_visual + Vector2(randf_range(-1.0, 1.0), randf_range(-0.5, 0.5)) * _forca_sacudir * k
		elif n.position != _base_visual:
			n.position = _base_visual
