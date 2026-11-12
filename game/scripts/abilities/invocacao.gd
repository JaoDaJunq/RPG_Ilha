class_name Invocacao
extends CharacterBody2D
## Invocação ou torreta: tem vida, some depois de `duracao` segundos e ataca sozinha o
## inimigo mais perto. Serve para Golem de pedra, Totem tesla, Torre de besta, Estandarte...
## O Companheiro (falcão, animal domado) é uma Invocação que segue o dono (companheiro.gd).
##
## Rede: o ANFITRIÃO cria (com `Invocacao.criar`), pensa e move; o MultiplayerSpawner do mundo
## copia para os outros, que recebem a posição e a arte (escolhida ao nascer).
## Os inimigos só atacam uma invocação provocados por ela (`provoca_raio` > 0): aí ela
## precisa de vida (o HealthComponent) para aguentar.
##
## Uso (numa HabilidadeLogica):
##   var g := Invocacao.criar(quem, ponto)
##   g.textura_caminho = "res://assets/sprites/tiny/pedras_slime.png"  # arte (placeholder)
##   g.duracao = 15.0
##   g.dano = dano_de(quem, hab)
##   g.alcance = 18.0          # soco (perto) ou 100 (torre que atira)
##   g.velocidade = 30.0       # 0 = parada (torre, totem)
##   g.provoca_raio = 60.0     # chama os inimigos em volta
##   g.iniciar()

const CENA := "res://scenes/abilities/invocacao.tscn"  # carregada na hora (a cena usa este script)

# --- Arte (sincronizada ao nascer) ---------------------------------------------------------
## Folha da arte, quadro (tamanho), primeiro quadro e quantos quadros a animação tem.
@export var textura_caminho := "res://assets/sprites/tiny/pedras_slime.png"
@export var quadro := Vector2i(128, 128)
@export var quadro_inicial := 0
@export var quadros := 1
@export var fps := 6.0
## Escala da arte (0,25 = pixel do Tiny Swords) e deslocamento (os pés no ponto).
@export var escala := 0.25
@export var deslocamento := Vector2(0, -56)
@export var olhando_esquerda := false

# --- Comportamento (só no anfitrião) ----------------------------------------------------
## Quem invocou (id na rede) e o jogador, se ainda estiver no mundo.
var dono_id := 1
var dono: Player
var vida_maxima := 30.0
## Segundos até sumir (0 = não some sozinho).
var duracao := 10.0
var dano := 1.0
var elemento: StringName = &"fisico"
## Distância do ataque (perto = soco; longe = tiro/choque) e segundos entre ataques.
var alcance := 20.0
var intervalo := 1.0
## Até onde enxerga um inimigo para ir atrás ou mirar.
var visao := 110.0
## Velocidade para ir até o alvo (0 = parada).
var velocidade := 0.0
## Ataque à distância com um projétil (vazio = acerta direto, como soco ou choque).
var projetil: PackedScene
## Efeito (tabela de Efeito) em cima do alvo a cada ataque (ex.: &"raio" no totem).
var efeito_ataque: StringName = &""
## Estado aplicado no alvo a cada ataque (vazio = nenhum).
var estado: StringName = &""
var estado_segundos := 1.0
var estado_forca := 0.0
## Provoca os inimigos a até este raio (0 = não provoca): eles vêm bater nela.
var provoca_raio := 0.0
## Também ataca animais?
var ataca_animais := false
## Chamada a cada ataque, para o que as opções acima não cobrem: func(invocacao, alvo) -> void
var ao_atacar: Callable

var _tempo := 0.0
var _espera := 0.0
var _provocar := 0.0

@onready var visual: AnimatedSprite2D = $Visual
@onready var vida: HealthComponent = $HealthComponent


## Cria a invocação de `quem` em `pos` (configure e chame `iniciar()`). `cena`: outra cena
## com este script (ex.: a do Companheiro).
static func criar(quem: Player, pos: Vector2, cena: PackedScene = null) -> Invocacao:
	var i: Invocacao = (cena if cena else load(CENA) as PackedScene).instantiate()
	i.dono = quem
	i.dono_id = quem.id_rede() if quem else 1
	i.position = pos
	return i


## Põe no mundo (anfitrião), ao lado de quem invocou.
func iniciar(pai: Node = null) -> Invocacao:
	if pai == null and dono:
		pai = dono.get_parent()
	pai.add_child(self, true)
	return self


func _ready() -> void:
	add_to_group(&"invocacoes")
	collision_layer = 0
	collision_mask = 1  # só o chão (água e paredes do mundo)
	var f := SpriteFrames.new()
	f.remove_animation(&"default")
	var tex := load(textura_caminho) as Texture2D
	if tex:
		var lista: Array[Texture2D] = []
		for k in maxi(1, quadros):
			lista.append(SpriteSheets.quadro(tex, quadro_inicial + k, quadro))
		SpriteSheets.adicionar_quadros(f, &"parado", lista, fps)
	visual.sprite_frames = f
	visual.scale = Vector2(escala, escala)
	visual.offset = deslocamento / escala
	visual.play(&"parado")
	if multiplayer.is_server():
		vida.maximo = vida_maxima
		vida.atual = vida_maxima
		vida.morreu.connect(sumir)


func _physics_process(delta: float) -> void:
	visual.flip_h = olhando_esquerda
	if not multiplayer.is_server():
		return
	_tempo += delta
	if duracao > 0.0 and _tempo >= duracao:
		sumir()
		return
	if provoca_raio > 0.0:
		_provocar -= delta
		if _provocar <= 0.0:
			_provocar = 1.0
			Golpes.estado_em_volta(self, global_position, provoca_raio, EfeitosEstado.PROVOCADO, 1.5, 0.0, ataca_animais)
	_espera = maxf(0.0, _espera - delta)
	var alvo := escolher_alvo()
	var dir := Vector2.ZERO
	if alvo:
		var para := alvo.global_position - global_position
		olhando_esquerda = para.x < 0.0
		if para.length() <= alcance:
			if _espera <= 0.0:
				_espera = intervalo
				atacar(alvo)
		elif velocidade > 0.0:
			dir = para.normalized()
	else:
		dir = mover_sem_alvo()
	velocity = dir * velocidade
	move_and_slide()


## Quem atacar agora: o inimigo mais perto que ela enxerga. (O Companheiro troca.)
func escolher_alvo() -> Node2D:
	return Golpes.mais_perto(self, global_position, visao, [], ataca_animais)


## Para onde andar sem alvo (0 = fica). O Companheiro segue o dono.
func mover_sem_alvo() -> Vector2:
	return Vector2.ZERO


## Um ataque em `alvo`: projétil ou acerto direto (com estado e efeito).
func atacar(alvo: Node2D) -> void:
	if projetil:
		var p: Projetil = projetil.instantiate()
		p.lancador = self
		p.direcao = (alvo.global_position + Vector2(0, -6) - global_position).normalized()
		p.dano = dano
		p.position = global_position + Vector2(0, -10)
		get_parent().add_child(p, true)
		if estado != &"":
			p.estado = estado
			p.estado_segundos = estado_segundos
			p.estado_forca = estado_forca
	else:
		Golpes.acertar(self, alvo, dano, elemento, estado, estado_segundos, estado_forca, efeito_ataque)
	if ao_atacar.is_valid():
		ao_atacar.call(self, alvo)


## Some (acabou o tempo ou a vida). Só o anfitrião.
func sumir() -> void:
	if is_queued_for_deletion():
		return
	World.efeito_todos(self, &"poeira", global_position)
	queue_free()


## Segundos que faltam (0 se não some sozinha).
func restante() -> float:
	return maxf(0.0, duracao - _tempo) if duracao > 0.0 else 0.0
