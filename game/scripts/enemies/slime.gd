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
## Nível mostrado em cima da cabeça (o slime comum e o da noite).
const NIVEL := 1
const NIVEL_NOTURNO := 3

@export var velocidade := 28.0
@export var raio_visao := 90.0
@export var dano_contato := 12.0
@export var recarga_contato := 1.0
## Animação atual (sincronizada).
@export var animacao: StringName = &"parado"
## Congelado ou preso (sincronizado para todos verem a cor).
@export var parado := false
## Slime da noite: nasce no escuro, é mais forte e derrete quando amanhece.
@export var noturno := false

var _recarga := 0.0
var _empurrao := Vector2.ZERO
var _congelado := 0.0
var _preso := 0.0
var _dano_visivel := 0.0  # mostra o quadro de dano por um instante

@onready var visual: AnimatedSprite2D = $Visual
@onready var vida: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var barra: BarraCabeca = $BarraCabeca


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
	if noturno:
		vida.maximo *= 1.6
		vida.atual = vida.maximo
		dano_contato *= 1.5
		velocidade *= 1.15
		raio_visao *= 1.4
	barra.definir_nivel(NIVEL_NOTURNO if noturno else NIVEL)
	barra.ajustar_ao_sprite(visual)
	if multiplayer.is_server():
		# Dificuldade do mundo: a vida vai para os outros pelos avisos de golpe (_piscar).
		vida.maximo *= World.mult_dificuldade(self, &"vida_inimigo")
		vida.atual = vida.maximo
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
	# A luz protege da noite: o slime noturno foge se estiver dentro dela e não persegue quem
	# está nela (os do dia não ligam).
	var luz := World.luz_que_protege(self, global_position) if noturno else Vector2.INF
	if luz != Vector2.INF and not parado:
		dir = (global_position - luz).normalized()
	elif not parado:
		dir = _decidir(alvo, delta)
	animacao = &"pulo" if dir != Vector2.ZERO or _estado == Estado.PULANDO else &"parado"
	if _estado == Estado.PREPARANDO:
		animacao = &"dano"  # achatado: está tomando impulso (aviso para esquivar)
	var rapidez := velocidade * (_VEL_PULO if _estado == Estado.PULANDO else 1.0)
	if _estado == Estado.RECUANDO:
		rapidez = _DIST_RECUO / _TEMPO_RECUO  # saltinho para trás depois da cabeçada
	velocity = dir * rapidez + _empurrao
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
	_piscar.rpc(vida.atual, vida.maximo)


## Todos veem o golpe; a vida vai junto para a barra em cima da cabeça aparecer nos clientes.
@rpc("authority", "call_local", "reliable")
func _piscar(atual: float, maximo: float) -> void:
	if not multiplayer.is_server():
		vida.maximo = maximo
		vida.atual = atual
	barra.mostrar_dano()
	Sfx.tocar(&"acerto", -10.0)
	_dano_visivel = 0.3
	var t := create_tween()
	t.tween_property(visual, "self_modulate", Color(1.0, 0.5, 0.5), 0.05)
	t.tween_property(visual, "self_modulate", Color.WHITE, 0.2)


func _on_morreu() -> void:
	var xp := XP_DERROTA * (2 if noturno else 1)
	World.dar_xp_em_volta(self, global_position, xp)
	World.avisar_todos(self, "Slime derrotado! +%d de experiência para quem estava perto." % xp)
	# Saque: gel de slime no chão (o da noite deixa mais).
	var gel := (2 if noturno else 1) + randi() % 2
	World.soltar_itens(self, global_position, [[&"gel_slime", gel]])
	queue_free()


## O sol derrete o slime da noite (só o anfitrião chama).
func derreter() -> void:
	World.efeito_todos(self, &"poeira", global_position)
	queue_free()


# --- Comportamento ------------------------------------------------------------------
## PASSEANDO: sem ninguém por perto, dá pulinhos para lugares próximos de onde nasceu.
## PERSEGUINDO: alguém entrou no raio de visão.
## PREPARANDO: chegou perto; achata por um instante (o aviso para o jogador esquivar).
## PULANDO: salta na direção em que o jogador estava; acerta quem estiver no caminho.
## RECUANDO: acertou (cabeçada): dá o dano uma vez e quica para trás; depois espera a recarga.
enum Estado { PASSEANDO, PERSEGUINDO, PREPARANDO, PULANDO, RECUANDO }
const _DIST_ATAQUE := 30.0
const _TEMPO_PREPARO := 0.45
const _TEMPO_PULO := 0.3
const _VEL_PULO := 4.2
const _DIST_RECUO := 12.0  # px que ele quica para trás depois de acertar
const _TEMPO_RECUO := 0.2
## Recarga depois da cabeçada (errando o pulo, vale `recarga_contato`).
const _RECARGA_CABECADA := 0.8

var _estado := Estado.PASSEANDO
var _tempo_estado := 0.0
var _casa := Vector2.INF
var _destino := Vector2.INF
var _dir_pulo := Vector2.ZERO
var _acertou_pulo := false
var _dir_recuo := Vector2.ZERO


func _decidir(alvo: Player, delta: float) -> Vector2:
	if _casa == Vector2.INF:
		_casa = global_position
	_tempo_estado += delta
	var para_alvo := alvo.global_position - global_position if alvo else Vector2.INF
	var ve_alvo := alvo != null and para_alvo.length() < raio_visao \
			and not (noturno and World.luz_que_protege(self, alvo.global_position) != Vector2.INF)
	match _estado:
		Estado.PREPARANDO:
			if _tempo_estado >= _TEMPO_PREPARO:
				_mudar(Estado.PULANDO)
				_acertou_pulo = false
			return Vector2.ZERO
		Estado.PULANDO:
			if not _acertou_pulo and alvo and para_alvo.length() < 12.0:
				_acertou_pulo = true
				# Cabeçada: o dano vem uma vez; se pegou, o slime quica para trás.
				if alvo.vida.tomar_dano(dano_contato * World.mult_dificuldade(self, &"dano_inimigo"), &"fisico"):
					alvo.avisar("O slime pulou em você! Esquive (Shift) quando ele achatar.")
					alvo.reagir_ao_golpe(global_position)
					_dir_recuo = -para_alvo.normalized() if para_alvo.length() > 0.1 else -_dir_pulo
					_mudar(Estado.RECUANDO)
					return _dir_recuo
			if _tempo_estado >= _TEMPO_PULO:
				_recarga = recarga_contato
				_mudar(Estado.PERSEGUINDO if ve_alvo else Estado.PASSEANDO)
			return _dir_pulo
		Estado.RECUANDO:
			if _tempo_estado >= _TEMPO_RECUO:
				_recarga = _RECARGA_CABECADA
				_mudar(Estado.PERSEGUINDO if ve_alvo else Estado.PASSEANDO)
				return Vector2.ZERO
			return _dir_recuo
	if ve_alvo:
		_estado = Estado.PERSEGUINDO
		visual.flip_h = para_alvo.x < 0.0
		if para_alvo.length() < _DIST_ATAQUE and _recarga <= 0.0:
			_dir_pulo = para_alvo.normalized()
			_mudar(Estado.PREPARANDO)
			return Vector2.ZERO
		if _recarga > 0.0 and para_alvo.length() < _DIST_ATAQUE:
			return Vector2.ZERO  # esperando a recarga: não encosta de novo
		return para_alvo.normalized()
	_estado = Estado.PASSEANDO
	# Pulinhos a esmo: anda até um ponto perto de casa, para um pouco e escolhe outro.
	if _destino == Vector2.INF or global_position.distance_to(_destino) < 4.0:
		if _tempo_estado < 1.5:
			return Vector2.ZERO
		_tempo_estado = 0.0
		_destino = _casa + Vector2(randf_range(-40, 40), randf_range(-40, 40))
	var ir := _destino - global_position
	if _tempo_estado > 4.0:  # preso em algo: desiste deste destino
		_destino = Vector2.INF
		_tempo_estado = 0.0
	visual.flip_h = ir.x < 0.0
	return ir.normalized() * 0.5


func _mudar(novo: Estado) -> void:
	_estado = novo
	_tempo_estado = 0.0
