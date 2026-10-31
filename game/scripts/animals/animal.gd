class_name Animal
extends CharacterBody2D
## Animal da ilha (L22 + a ovelha do Tiny Swords). Passeia perto de onde nasceu; quando
## apanha, foge de quem bateu (o javali, ao contrário, investe contra quem bateu). Ao morrer,
## o saque vai para quem deu o último golpe. Só o anfitrião decide; os outros recebem a
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

@export var especie: StringName = &"galinha"
@export var animacao: StringName = &"parado"
@export var olhando_esquerda := false

var _casa := Vector2.INF
var _destino := Vector2.INF
var _tempo := 0.0
var _assustado := 0.0
var _de_quem: Node2D
var _recarga := 0.0

@onready var visual: AnimatedSprite2D = $Visual
@onready var vida: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox


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
	if multiplayer.is_server():
		hurtbox.atingido.connect(_on_atingido)
		vida.morreu.connect(_on_morreu)


func _physics_process(delta: float) -> void:
	visual.flip_h = olhando_esquerda
	if visual.animation != animacao:
		visual.play(animacao)
	if not multiplayer.is_server():
		return
	if _casa == Vector2.INF:
		_casa = global_position
	_tempo += delta
	_assustado = maxf(0.0, _assustado - delta)
	_recarga = maxf(0.0, _recarga - delta)
	var dados: Dictionary = ESPECIES[especie]
	var dir := Vector2.ZERO
	var rapidez: float = dados.vel
	if _assustado > 0.0 and is_instance_valid(_de_quem):
		var para := _de_quem.global_position - global_position
		if dados.get("bravo", false):
			dir = para.normalized()  # o javali investe
			rapidez *= 1.6
			if para.length() < 14.0 and _recarga <= 0.0 and _de_quem is Player:
				_recarga = 1.2
				(_de_quem as Player).vida.tomar_dano(DANO_JAVALI, &"fisico")
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
	if dir.x != 0.0:
		olhando_esquerda = dir.x < 0.0
	animacao = &"andar" if dir != Vector2.ZERO else &"parado"
	velocity = dir * rapidez
	move_and_slide()


func _on_atingido(quantidade: float, tipo: StringName, origem: Node) -> void:
	if origem is Node2D:
		_de_quem = origem
		_assustado = 4.0
	if vida.tomar_dano(quantidade, tipo):
		_piscar.rpc()


@rpc("authority", "call_local", "reliable")
func _piscar() -> void:
	Sfx.tocar(&"acerto", -10.0)
	var t := create_tween()
	t.tween_property(visual, "self_modulate", Color(1.0, 0.5, 0.5), 0.05)
	t.tween_property(visual, "self_modulate", Color.WHITE, 0.2)


func _on_morreu() -> void:
	if _de_quem is Player:
		var p := _de_quem as Player
		var ganhou: Array[String] = []
		for s in ESPECIES[especie].saque:
			var n := randi_range(s[1], s[2])
			if n > 0:
				p.inventario.adicionar(s[0], n)
				ganhou.append("%d %s" % [n, ItemData.carregar(s[0]).nome.to_lower()])
		p.avisar("+" + ", ".join(ganhou), &"item")
	World.efeito_todos(self, &"poeira", global_position)
	queue_free()
