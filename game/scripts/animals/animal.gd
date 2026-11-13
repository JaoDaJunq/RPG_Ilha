class_name Animal
extends CharacterBody2D
## Animal da ilha (L22 + a ovelha do Tiny Swords). Passeia perto de onde nasceu; quando
## apanha, foge de quem bateu (o javali, ao contrário, investe contra quem bateu). Ao morrer,
## o saque cai no chão (ItemChao) para qualquer jogador pegar. Só o anfitrião decide; os outros recebem a
## posição, a animação e o lado (MultiplayerSynchronizer).

const FOLHA := preload("res://assets/sprites/tiny/animais/animais.png")
const OVELHA_PARADA := preload("res://assets/tiny_swords/natureza/ovelha_parada.png")
const OVELHA_ANDANDO := preload("res://assets/tiny_swords/natureza/ovelha_andando.png")

## vida, velocidade, quadros na folha [parado, andando], saque [[item, mín, máx], ...]
const ESPECIES := {
	&"galinha": {vida = 2.0, vel = 22.0, quadros = [0, 1], saque = [[&"carne_crua", 1, 1], [&"pena", 1, 2], [&"ovo", 0, 1]]},
	&"coelho": {vida = 2.0, vel = 42.0, quadros = [2, 3], saque = [[&"carne_crua", 1, 1], [&"couro", 0, 1]]},
	&"javali": {vida = 7.0, vel = 30.0, quadros = [4, 5], saque = [[&"carne_crua", 2, 3], [&"couro", 1, 2]], bravo = true},
	&"ovelha": {vida = 4.0, vel = 20.0, saque = [[&"carne_crua", 2, 2], [&"couro", 1, 1]]},
}
const DANO_JAVALI := 10.0
## Depois da cabeçada o javali quica DIST_RECUO px para trás em TEMPO_RECUO s e para por
## PAUSA_CABECADA s antes de investir de novo.
const DIST_RECUO := 12.0
const TEMPO_RECUO := 0.2
const PAUSA_CABECADA := 1.0
## Nível mostrado em cima da cabeça de cada espécie.
const NIVEIS := {&"galinha": 1, &"coelho": 1, &"ovelha": 1, &"javali": 2}

@export var especie: StringName = &"galinha"
@export var animacao: StringName = &"parado"
@export var olhando_esquerda := false
## Envenenado (sincronizado; o Contágio olha).
@export var envenenado := false

var _casa := Vector2.INF
var _destino := Vector2.INF
var _tempo := 0.0
var _assustado := 0.0
var _de_quem: Node2D
var _recarga := 0.0
var _recuo := 0.0
var _dir_recuo := Vector2.ZERO

@onready var visual: AnimatedSprite2D = $Visual
@onready var vida: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var barra: BarraCabeca = $BarraCabeca
## Estados (Lentidão, Medo, Provocado...): o animal respeita todos ao andar e atacar.
@onready var efeitos: EfeitosEstado = $EfeitosEstado


func _ready() -> void:
	add_to_group(&"animais")
	var dados: Dictionary = ESPECIES[especie]
	var f := SpriteFrames.new()
	f.remove_animation(&"default")
	if especie == &"ovelha":
		SpriteSheets.adicionar_tira(f, OVELHA_PARADA, &"parado", Vector2i(128, 128), 6, 6.0)
		SpriteSheets.adicionar_tira(f, OVELHA_ANDANDO, &"andar", Vector2i(128, 128), 4, 8.0)
		visual.offset = Vector2(0, -24)  # os pés da ovelha do pacote
	else:
		var q: Array = dados.quadros
		var t := Vector2i(128, 128)
		SpriteSheets.adicionar_quadros(f, &"parado", [SpriteSheets.quadro(FOLHA, q[0], t)], 1.0)
		SpriteSheets.adicionar_quadros(f, &"andar", [SpriteSheets.quadro(FOLHA, q[1], t), SpriteSheets.quadro(FOLHA, q[0], t)], 7.0)
		visual.offset = Vector2(0, -56)  # base 8 px acima do fundo do quadro de 128
	visual.sprite_frames = f
	visual.play(animacao)
	vida.maximo = dados.vida
	vida.atual = vida.maximo
	barra.definir_nivel(NIVEIS.get(especie, 1))
	barra.ajustar_ao_sprite(visual)
	if multiplayer.is_server():
		# Dificuldade do mundo (os outros veem a vida pelos avisos de golpe, _piscar).
		vida.maximo *= World.mult_dificuldade(self, &"vida_inimigo")
		vida.atual = vida.maximo
		hurtbox.atingido.connect(_on_atingido)
		vida.morreu.connect(_on_morreu)


## Só o anfitrião chama (Lâmina envenenada): perde `dano` de vida por segundo durante
## `segundos` (um golpe novo recomeça a contagem). `origem`: quem envenenou.
func envenenar(segundos: float, dano: float, origem: Node = null) -> void:
	efeitos.aplicar(EfeitosEstado.VENENO, segundos, dano, origem)
	envenenado = true


## Só o anfitrião chama (armadilha, Raio): não anda por `segundos`.
func prender(segundos: float) -> void:
	efeitos.aplicar(EfeitosEstado.PRESO, segundos)


func congelado() -> bool:
	return efeitos.tem(EfeitosEstado.CONGELADO)


func preso() -> bool:
	return efeitos.tem(EfeitosEstado.PRESO)


## Está atrás deste jogador? (Golpe furtivo: quem não persegue leva o dobro.) Só o javali
## bravo persegue, e só quem bateu nele e ainda não sumiu de vista.
func persegue(jogador: Node) -> bool:
	return ESPECIES[especie].get("bravo", false) and _assustado > 0.0 and _de_quem == jogador


func _physics_process(delta: float) -> void:
	visual.flip_h = olhando_esquerda
	visual.modulate = efeitos.cor()
	if visual.animation != animacao:
		visual.play(animacao)
	if not multiplayer.is_server():
		return
	if _casa == Vector2.INF:
		_casa = global_position
	_tempo += delta
	_assustado = maxf(0.0, _assustado - delta)
	_recarga = maxf(0.0, _recarga - delta)
	envenenado = efeitos.tem(EfeitosEstado.VENENO)
	if is_queued_for_deletion():
		return  # o veneno ou a queimadura o derrotou
	var dados: Dictionary = ESPECIES[especie]
	var dir := Vector2.ZERO
	var rapidez: float = dados.vel
	var recuando := false
	# Provocado: vai atrás de quem provocou (o javali investe; os outros só se aproximam).
	var provocador := efeitos.alvo_provocado()
	if provocador:
		_de_quem = provocador
		_assustado = maxf(_assustado, 0.5)
	# Bomba de fumaça: quem some de vista deixa de ser perseguido (ou de assustar o bicho).
	if _assustado > 0.0 and is_instance_valid(_de_quem) and _de_quem is Player and ((_de_quem as Player).escondido() or (_de_quem as Player).caido):
		_assustado = 0.0
	var medo := efeitos.fugir_de()
	if medo != Vector2.INF:
		dir = (global_position - medo).normalized()  # Medo: foge
		rapidez *= 2.0
	elif _assustado > 0.0 and is_instance_valid(_de_quem):
		var para := _de_quem.global_position - global_position
		if dados.get("bravo", false):
			# Cabeçada: investe, acerta uma vez, recua um pouco, para ~1 s e investe de novo.
			if _recuo > 0.0:
				_recuo -= delta
				recuando = true
				dir = _dir_recuo
				rapidez = DIST_RECUO / TEMPO_RECUO
			elif _recarga > 0.0:
				olhando_esquerda = para.x < 0.0  # parado, de olho em quem vai acertar
			else:
				dir = para.normalized()  # o javali investe
				rapidez *= 1.6
				if para.length() < 14.0 and efeitos.pode_atacar():
					_recarga = TEMPO_RECUO + PAUSA_CABECADA
					if _cabecada(_de_quem):
						_dir_recuo = -para.normalized() if para.length() > 0.1 else -dir
						_recuo = TEMPO_RECUO
		elif provocador:
			dir = para.normalized() if para.length() > 12.0 else Vector2.ZERO
		else:
			dir = -para.normalized()  # os outros fogem
			rapidez *= 2.0
	else:
		# Passeia: anda até um ponto perto de casa, para um pouco e escolhe outro.
		if _destino == Vector2.INF or global_position.distance_to(_destino) < 4.0:
			if _tempo > 2.5:
				_tempo = 0.0
				_destino = _casa + Vector2(randf_range(-48, 48), randf_range(-48, 48))
		elif _tempo > 6.0:
			_destino = Vector2.INF
		else:
			dir = (_destino - global_position).normalized() * 0.6
	rapidez *= efeitos.mult_velocidade()  # Lentidão; 0 se congelado, preso, atordoado...
	if rapidez <= 0.0:
		dir = Vector2.ZERO
	if dir.x != 0.0 and not recuando:  # recuando, continua de frente para quem acertou
		olhando_esquerda = dir.x < 0.0
	animacao = &"andar" if dir != Vector2.ZERO else &"parado"
	velocity = dir * rapidez + efeitos.impulso()
	move_and_slide()


## A cabeçada do javali em `alvo` (jogador ou invocação). Cego pode errar. Devolve se machucou.
func _cabecada(alvo: Node2D) -> bool:
	if efeitos.erra_ataque():
		World.efeito_todos(self, &"poeira", alvo.global_position)
		return false
	var v := alvo.get_node_or_null("HealthComponent") as HealthComponent
	if v == null or not v.tomar_dano(Passivas.ataque_inimigo(self, alvo, DANO_JAVALI), &"fisico"):
		return false
	if alvo is Player:
		(alvo as Player).reagir_ao_golpe(global_position)
	return true


func _on_atingido(quantidade: float, tipo: StringName, origem: Node) -> void:
	if origem is Node2D:
		_de_quem = origem
		_assustado = 4.0
	if vida.tomar_dano(quantidade, tipo):
		_piscar.rpc(vida.atual)


## Todos veem o golpe; a vida vai junto para a barra em cima da cabeça aparecer nos clientes.
@rpc("authority", "call_local", "reliable")
func _piscar(atual: float) -> void:
	if not multiplayer.is_server():
		vida.atual = atual
	barra.mostrar_dano()
	Sfx.tocar(&"acerto", -10.0)
	var t := create_tween()
	t.tween_property(visual, "self_modulate", Color(1.0, 0.5, 0.5), 0.05)
	t.tween_property(visual, "self_modulate", Color.WHITE, 0.2)


func _on_morreu() -> void:
	var saque := []
	for s in ESPECIES[especie].saque:
		var n := randi_range(s[1], s[2])
		if n > 0:
			saque.append([s[0], n])
	World.soltar_itens(self, global_position, saque)
	World.efeito_todos(self, &"poeira", global_position)
	queue_free()
