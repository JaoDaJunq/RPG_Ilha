class_name Slime
extends CharacterBody2D
## Slime: persegue o jogador mais próximo e machuca no contato.
## Rede: só o anfitrião pensa e move o slime; os outros recebem posição e animação.
##
## Reações aos elementos (sempre iguais, para dar para planejar):
##   gelo   → congela (para de andar) por TEMPO_CONGELADO
##   físico num congelado → ESTILHAÇA: dano dobrado e descongela
##   fogo   → dano dobrado; num congelado, só derrete o gelo

## Slime no estilo Tiny Swords (L14): quadros 4 (parado) e 5 (achatado) da folha de pedras.
const TEXTURA := preload("res://assets/sprites/tiny/pedras_slime.png")
const TEMPO_CONGELADO := 2.5
## Experiência para cada jogador perto quando o slime é derrotado.
const XP_DERROTA := 10

@export var velocidade := 28.0
@export var raio_visao := 90.0
@export var dano_contato := 12.0
@export var recarga_contato := 1.0
## Animação atual (sincronizada).
@export var animacao: StringName = &"parado"
## Congelado ou preso (sincronizado para todos verem a cor).
@export var parado := false

var _recarga := 0.0
var _empurrao := Vector2.ZERO
var _congelado := 0.0
var _preso := 0.0
var _dano_visivel := 0.0  # mostra o quadro de dano por um instante

@onready var visual: AnimatedSprite2D = $Visual
@onready var vida: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox


func _ready() -> void:
	add_to_group(&"inimigos")
	var f := SpriteFrames.new()
	f.remove_animation(&"default")
	var t := Vector2i(128, 128)
	var parado := SpriteSheets.quadro(TEXTURA, 4, t)
	var achatado := SpriteSheets.quadro(TEXTURA, 5, t)
	SpriteSheets.adicionar_quadros(f, &"parado", [parado], 1.0)
	SpriteSheets.adicionar_quadros(f, &"pulo", [achatado, parado, parado, achatado], 7.0)
	SpriteSheets.adicionar_quadros(f, &"dano", [achatado], 1.0)
	visual.sprite_frames = f
	visual.play(animacao)
	if multiplayer.is_server():
		hurtbox.atingido.connect(_on_atingido)
		vida.morreu.connect(_on_morreu)


func congelado() -> bool:
	return _congelado > 0.0


func preso() -> bool:
	return _preso > 0.0


## Só o anfitrião chama (armadilha).
func prender(segundos: float) -> void:
	_preso = maxf(_preso, segundos)


func _physics_process(delta: float) -> void:
	visual.modulate = Color(0.6, 0.85, 1.0) if parado else Color.WHITE
	if parado:
		visual.pause()
	elif not visual.is_playing():
		visual.play()
	_dano_visivel = maxf(0.0, _dano_visivel - delta)
	var quer: StringName = &"dano" if _dano_visivel > 0.0 else animacao
	if visual.animation != quer and not parado:
		visual.play(quer)
	if not multiplayer.is_server():
		return
	_recarga = maxf(0.0, _recarga - delta)
	_congelado = maxf(0.0, _congelado - delta)
	_preso = maxf(0.0, _preso - delta)
	parado = congelado() or preso()
	var alvo := _jogador_mais_proximo()
	var dir := Vector2.ZERO
	if alvo and not parado:
		var para_alvo := alvo.global_position - global_position
		if para_alvo.length() < raio_visao:
			dir = para_alvo.normalized()
			visual.flip_h = dir.x < 0.0
		if para_alvo.length() < 12.0 and _recarga <= 0.0:
			_recarga = recarga_contato
			if alvo.vida.tomar_dano(dano_contato, &"fisico"):
				alvo.avisar("O slime te acertou! Clique para golpear.")
	animacao = &"pulo" if dir != Vector2.ZERO else &"parado"
	velocity = dir * velocidade + _empurrao
	_empurrao = _empurrao.move_toward(Vector2.ZERO, 400.0 * delta)
	move_and_slide()


func _jogador_mais_proximo() -> Player:
	var melhor: Player = null
	var menor := INF
	for j in get_tree().get_nodes_in_group(&"jogadores"):
		var d := global_position.distance_to(j.global_position)
		if d < menor:
			menor = d
			melhor = j
	return melhor


func _on_atingido(quantidade: float, tipo: StringName, origem: Node) -> void:
	var dano := quantidade
	match tipo:
		&"gelo":
			_congelado = TEMPO_CONGELADO
			World.efeito_todos(self, &"congelar", global_position + Vector2(0, -6))
		&"fogo":
			if congelado():
				_congelado = 0.0
			else:
				dano *= 2.0
		&"fisico":
			if congelado():
				dano *= 2.0
				_congelado = 0.0
				World.avisar_todos(self, "Estilhaçou! Golpe em inimigo congelado dá dano dobrado.")
	parado = congelado() or preso()
	if not vida.tomar_dano(dano, tipo):
		return
	if origem is Node2D and not parado:
		_empurrao = (global_position - origem.global_position).normalized() * 160.0
	_piscar.rpc()


@rpc("authority", "call_local", "reliable")
func _piscar() -> void:
	Sfx.tocar(&"acerto", -10.0)
	_dano_visivel = 0.3
	var t := create_tween()
	t.tween_property(visual, "self_modulate", Color(1.0, 0.5, 0.5), 0.05)
	t.tween_property(visual, "self_modulate", Color.WHITE, 0.2)


func _on_morreu() -> void:
	World.dar_xp_em_volta(self, global_position, XP_DERROTA)
	World.avisar_todos(self, "Slime derrotado! +%d de experiência para quem estava perto." % XP_DERROTA)
	queue_free()
