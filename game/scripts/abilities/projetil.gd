class_name Projetil
extends Area2D
## Projétil genérico (bola de fogo, lança de gelo, flecha): voa em linha reta e acerta a
## primeira coisa atingível no caminho. Quem é atingido decide o efeito pelo elemento.
## Rede: só o anfitrião move e confere acertos; os outros recebem a posição.

@export var velocidade := 170.0
@export var duracao := 1.2
@export var dano := 1.0
@export var elemento: StringName = &"fogo"
## Sincronizada ao nascer, para todos desenharem o projétil na direção certa.
@export var direcao := Vector2.RIGHT
## Sobre a água, congela o caminho (lança de gelo).
@export var congela_agua := false

@export_group("Arte")
@export var textura: Texture2D
@export var quadro := Vector2i(16, 16)
@export var quadros := 1
@export var fps := 12.0
## Para onde a arte aponta (radianos). A bola de fogo do placeholder aponta para cima-direita.
@export var angulo_da_arte := 0.0
@export var textura_impacto: Texture2D
@export var quadro_impacto := Vector2i(16, 16)
@export var quadros_impacto := 0
## Escala da arte (o Tiny Swords é feito para tile de 64 px: 0,25 no nosso mundo).
@export var escala_arte := 1.0
@export var escala_impacto := 1.0
## Gira a arte enquanto voa (radianos por segundo; a bomba gira, as flechas não).
@export var girar := 0.0
## Vira a arte para a direção do voo (a rede não vira: voa aberta, de frente).
@export var alinhar_arte := true

## O projétil acabou: onde parou e se acertou algo (a bomba explode aqui). Só no anfitrião.
signal terminou(pos: Vector2, acertou: bool)
## Acertou `alvo` (a cada acerto; o perfurante e o que quica avisam várias vezes). Anfitrião.
signal acertou(alvo: Node, pos: Vector2)

var lancador: Node = null

# --- Variações (o anfitrião liga depois de criar, antes ou logo depois de pôr no mundo) ---
## Atravessa os inimigos (acerta cada um uma vez) em vez de parar no primeiro.
var perfura := false
## Depois de acertar, salta para o inimigo mais perto (até `raio_quique` px) mais N vezes.
var quiques := 0
var raio_quique := 64.0
## Bumerangue: vai até o fim (`duracao`), volta para o lançador e acerta de novo na volta.
var volta := false
## Puxa o atingido até `puxa` px na direção do lançador (Corrente do Guerreiro).
var puxa := 0.0
## Estado aplicado em quem for acertado (vazio = nenhum). Ver EfeitosEstado.
var estado: StringName = &""
var estado_segundos := 1.0
var estado_forca := 0.0
## Projétil de INIMIGO (flecha do Atirador): acerta jogadores e invocações (nunca inimigos,
## animais nem recursos) e para nas paredes e portas e no que estiver no grupo
## "bloqueia_projeteis" (Barreira do Clérigo, cúpula do Bastião): ver `bloqueado()`.
var do_inimigo := false
## Força o próximo acerto deste projétil a ser crítico (Tiro carregado completo).
var critico := false

var _vida := 0.0
var _acertou := false
var _atingidos: Array[Node] = []
var _voltando := false

@onready var visual: AnimatedSprite2D = $Visual


func _ready() -> void:
	add_to_group(&"projeteis")
	collision_layer = 0
	collision_mask = 1 << 4  # "atingivel"
	monitoring = multiplayer.is_server()
	area_entered.connect(_on_area_entered)
	var f := SpriteFrames.new()
	f.remove_animation(&"default")
	SpriteSheets.adicionar_tira(f, textura, &"voando", quadro, quadros, fps)
	if textura_impacto and quadros_impacto > 0:
		# Impacto de um quadro só (cristais de gelo) fica um terço de segundo na tela.
		SpriteSheets.adicionar_tira(f, textura_impacto, &"impacto", quadro_impacto, quadros_impacto, 20.0 if quadros_impacto > 1 else 3.0, false)
	visual.sprite_frames = f
	visual.scale = Vector2(escala_arte, escala_arte)
	visual.play(&"voando")
	visual.rotation = direcao.angle() - angulo_da_arte if alinhar_arte else 0.0


func _physics_process(delta: float) -> void:
	if girar != 0.0 and not _acertou:
		visual.rotation += girar * delta
	if _acertou or not multiplayer.is_server():
		return
	var antes := global_position
	position += direcao * velocidade * delta
	if do_inimigo and Projetil.bloqueado(self, antes, global_position):
		World.efeito_todos(self, &"poeira", global_position)
		_parar(false)
		return
	if congela_agua:
		World.congelar_agua_em(self, global_position + Vector2(0, 10))
	_vida += delta
	if volta:
		_voar_bumerangue()
		return
	if _vida >= duracao:
		terminou.emit(global_position, false)
		queue_free()


## Bumerangue: no fim da ida, vira para o lançador; some ao chegar nele (ou depois de 3x a
## duração, se ele sumiu).
func _voar_bumerangue() -> void:
	var dono := lancador as Node2D if is_instance_valid(lancador) else null
	if not _voltando and _vida >= duracao:
		_voltando = true
		_atingidos.clear()  # acerta de novo na volta
	if _voltando and dono:
		var para := dono.global_position + Vector2(0, -10) - global_position
		direcao = para.normalized()
		if para.length() < 10.0:
			terminou.emit(global_position, not _atingidos.is_empty())
			queue_free()
			return
	if _vida >= duracao * 3.0 or (_voltando and dono == null):
		terminou.emit(global_position, false)
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _acertou or not area is Hurtbox:
		return
	var dono := area.get_parent()
	if do_inimigo:
		_acerto_inimigo(area as Hurtbox, dono)
		return
	if dono == lancador or dono is Player or dono is Construcao:
		return  # sem fogo amigo; flechas e magias passam por cima das construções
	if dono is ResourceNode and not (dono as ResourceNode).para_projetil(elemento):
		return  # passam por cima de árvores, tocos e pedras (só o fogo para numa árvore e a acende)
	if dono in _atingidos:
		return
	_atingidos.append(dono)
	if critico and lancador is Player:
		critico = false
		lancador.set_meta(&"critico_pronto", true)  # = Passivas.forcar_critico (sem citar a classe: ciclo de preload)
	(area as Hurtbox).receber(dano, elemento, lancador)
	_no_alvo(dono)
	acertou.emit(dono, global_position)
	if dono is ResourceNode:
		pass  # árvore que segura o projétil: ele para (abaixo)
	elif perfura or volta:
		return  # segue voando
	elif quiques > 0:
		var proximo := Golpes.mais_perto(self, global_position, raio_quique, _atingidos)
		if proximo:
			quiques -= 1
			_vida = 0.0
			_virar.rpc((proximo.global_position + Vector2(0, -6) - global_position).normalized())
			return
	_parar(true)


## Acaba o voo aqui (acertou algo ou foi bloqueado). Anfitrião.
func _parar(acertou_algo: bool) -> void:
	_acertou = true
	set_deferred(&"monitoring", false)
	terminou.emit(global_position, acertou_algo)
	_impacto.rpc()
	if visual.sprite_frames.has_animation(&"impacto"):
		visual.animation_finished.connect(queue_free)
	else:
		queue_free()


## Flecha inimiga: machuca jogador ou invocação (com as passivas de defesa e a dificuldade,
## como a cabeçada do slime); para numa parede ou porta.
func _acerto_inimigo(area: Hurtbox, dono: Node) -> void:
	if dono is Construcao:
		if (dono as Construcao).tipo in [&"parede", &"porta"]:
			World.efeito_todos(self, &"poeira", global_position)
			_parar(false)
		return
	if not (dono is Player or dono.is_in_group(&"invocacoes")) or dono in _atingidos:
		return
	var v := dono.get_node_or_null("HealthComponent") as HealthComponent
	if v == null or not v.esta_vivo():
		return
	_atingidos.append(dono)
	var atacante: Node = lancador if is_instance_valid(lancador) else self
	# Passivas.ataque_inimigo (dificuldade, Frio que morde, Contra-golpe...). Pelo nome, sem
	# citar a classe aqui: Passivas carrega as cenas dos projéteis (ciclo de preload).
	var passivas: Script = load("res://scripts/player/passivas.gd")
	area.receber(passivas.call(&"ataque_inimigo", atacante, dono, dano), elemento, atacante)
	if dono is Player:
		(dono as Player).reagir_ao_golpe(global_position - direcao * 8.0)
	_no_alvo(dono)
	acertou.emit(dono, global_position)
	_parar(true)


## Algo do grupo "bloqueia_projeteis" está no caminho de `de` até `ate`? (o projétil voa a
## 10 px do chão: a conta usa o ponto no chão). Quem bloqueia guarda numa meta:
##   bloqueio_segmento = [a, b, grossura]  parede (Barreira)
##   bloqueio_raio = r                      cúpula (Bastião), em volta do nó
static func bloqueado(quem: Node, de: Vector2, ate: Vector2) -> bool:
	var chao := Vector2(0, 10)
	de += chao
	ate += chao
	for n in quem.get_tree().get_nodes_in_group(&"bloqueia_projeteis"):
		var b := n as Node2D
		if b == null or b.is_queued_for_deletion():
			continue
		if b.has_meta(&"bloqueio_segmento"):
			var s: Array = b.get_meta(&"bloqueio_segmento")
			var a: Vector2 = s[0]
			var c: Vector2 = s[1]
			if Geometry2D.segment_intersects_segment(de, ate, a, c) != null \
					or Geometry2D.get_closest_point_to_segment(ate, a, c).distance_to(ate) < float(s[2]):
				return true
		elif b.has_meta(&"bloqueio_raio") and b.global_position.distance_to(ate) <= float(b.get_meta(&"bloqueio_raio")):
			return true
	return false


## Estado e puxão no atingido (anfitrião).
func _no_alvo(alvo: Node) -> void:
	if not is_instance_valid(alvo):
		return
	if estado != &"":
		EfeitosEstado.aplicar_em(alvo, estado, estado_segundos, estado_forca, lancador)
	if puxa > 0.0 and is_instance_valid(lancador) and alvo is Node2D:
		Golpes.puxar(alvo as Node2D, (lancador as Node2D).global_position, puxa)


## Muda a direção (quique) em todos, para a arte apontar certo.
@rpc("authority", "call_local", "reliable")
func _virar(nova: Vector2) -> void:
	direcao = nova
	if girar == 0.0:
		visual.rotation = direcao.angle() - angulo_da_arte


@rpc("authority", "call_local", "reliable")
func _impacto() -> void:
	if visual.sprite_frames.has_animation(&"impacto"):
		visual.rotation = 0.0
		visual.scale = Vector2(escala_impacto, escala_impacto)
		visual.play(&"impacto")
	else:
		visual.visible = false
