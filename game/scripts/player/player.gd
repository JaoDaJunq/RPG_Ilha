class_name Player
extends CharacterBody2D
## Jogador: anda com WASD, mira com o mouse, segura E para coletar, clique para golpear,
## Shift para o dash (esquiva) e Q, R, T, E para as habilidades da classe.
##
## Rede: o nome do nó é o id do jogador na rede. Cada jogador controla o próprio
## movimento (sincronizado pelo MultiplayerSynchronizer). Tudo que muda o mundo
## (coletar, golpear, habilidades) é um PEDIDO ao anfitrião, que confere e executa.
## Vida, mana e inventário são do anfitrião, que manda os valores ao dono.

const DURACAO_ESQUIVA := 0.2
const VELOCIDADE_ESQUIVA := 230.0
const CARGA_MAXIMA := 1.0  # segundos segurando para a carga completa
const SONS := {
	&"investida": &"esquiva", &"giro": &"giro", &"bola_de_fogo": &"bola_de_fogo",
	&"lanca_gelo": &"esquiva", &"tiro_carregado": &"flecha", &"armadilha": &"golpe_coleta",
	&"bloqueio": &"esquiva", &"furia": &"giro", &"raio": &"bola_de_fogo", &"nova_gelo": &"esquiva",
	&"chuva_flechas": &"flecha", &"bomba": &"bola_de_fogo",
	&"golpe_furtivo": &"giro", &"lamina_envenenada": &"golpe_coleta", &"bomba_fumaca": &"esquiva",
	&"leque_adagas": &"flecha", &"cura": &"subir_nivel", &"escudo_sagrado": &"esquiva",
	&"luz_sagrada": &"bola_de_fogo", &"bencao": &"subir_nivel",
}

@export var dano_golpe := 1.0
@export var alcance_golpe := 22.0
@export var recarga_golpe := 0.35

## Animação atual (sincronizada para os outros jogadores verem).
@export var animacao: StringName = &"parado_direita"
## Personagem (sincronizado ao nascer).
@export var raca: StringName = &"humano"
@export var classe: StringName = &"guerreiro"
## Rosto e pele ({raca, rosto 0 a 2, pele 0 a 2}) e roupa completa vestida (corpo). Quem
## manda é o anfitrião; todos recebem por _aspecto_sync. `cabeca` fica só por compatibilidade.
var aparencia: Dictionary = {}
var equipado: Dictionary = {&"cabeca": &"", &"corpo": &""}
## Personagem ainda sendo criado (tela de criação aberta): parado, escondido e sem tomar dano.
var criando := false

## Nível, experiência ou pontos mudaram (o HUD escuta).
signal progresso_mudou
## Raça, classe, rosto, pele ou roupas mudaram (o HUD e a mochila escutam).
signal aspecto_mudou

var ficha: Ficha
var mana := 0.0
# Progressão: quem manda é o anfitrião; todos recebem por _progresso_sync.
var nivel := 1
var xp := 0
var pontos_atributo := 0
var pontos_habilidade := 0
var distribuidos: Dictionary[StringName, int] = {}
## Árvore de habilidades (ArvoreData): nó → nível (1 = aprendido; 2 a 4 = com melhorias).
## Os nós que já vêm com a classe não entram aqui. Também vem no _progresso_sync.
var arvore: Dictionary[StringName, int] = {}
## Habilidades nas teclas Q R T E (ids, na ordem). Vazio = as 2 que vêm com a classe.
var teclas: Array[StringName] = []
## Posição de mira fixa (usada pelos testes). Se nula, usa o mouse.
var mira_forcada: Variant = null
var alvo: Interactable = null
var ponto_de_retorno := Vector2.ZERO
## A tela da mochila (ou da bancada, ou do baú) está aberta: sem dash nem habilidades.
## Quem liga e desliga é a própria tela (Mochila); andar continua valendo.
var menu_aberto := false

var _direcao: StringName = &"baixo"
var _progresso := 0.0
var _recarga_golpe := 0.0
var _atacando := 0.0
var _recargas: Dictionary = {}              # id da habilidade → segundos (local, para o HUD)
var _prontas_no_anfitriao: Dictionary = {}  # id da habilidade → ms (o anfitrião confere)
var _recarga_esquiva := 0.0
var _impulso := Vector2.ZERO
var _impulso_restante := 0.0
## Tecla (0-3) da habilidade sendo conjurada/carregada; -1 = nenhuma (o HUD usa).
var _carregando: int:
	get:
		return conjuracao.indice if conjuracao else -1
var conjuracao: Conjuracao  # segurar a tecla para conjurar (Conjuracao)
var _mana_enviada := -1.0

@onready var visual: Boneco = $Visual
@onready var vida: HealthComponent = $HealthComponent
@onready var inventario: Inventory = $Inventory
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var camera: Camera2D = $Camera2D
@onready var luz: PointLight2D = $Luz
## Estados (Lentidão, Invisível...), buffs de aliados e Fúria/combo (criados no _ready).
var efeitos: EfeitosEstado
var buffs: Buffs
var recursos: RecursosClasse
## O último inimigo ou animal que este jogador acertou (anfitrião; o companheiro ataca ele).
var ultimo_alvo: Node2D


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _ready() -> void:
	add_to_group(&"jogadores")
	# Componentes das habilidades (mesmo nome em todas as máquinas, para os RPCs deles).
	efeitos = _componente(EfeitosEstado.new(), "EfeitosEstado")
	buffs = _componente(Buffs.new(), "Buffs")
	recursos = _componente(RecursosClasse.new(), "Recursos")
	conjuracao = _componente(Conjuracao.new(), "Conjuracao")
	if eh_local() and not multiplayer.is_server():
		# O jogador controlado aqui não recebe as propriedades de nascimento.
		raca = Net.raca
		classe = Net.classe
	ficha = Ficha.criar(raca, classe)
	vida.maximo = ficha.vida_maxima()
	vida.atual = vida.maximo
	mana = ficha.mana_maxima()
	_recargas.clear()
	_aplicar_passivas_fixas()
	ponto_de_retorno = position
	if aparencia.is_empty():
		aparencia = aparencia_padrao(raca)
	_atualizar_visual()
	visual.play(animacao)
	camera.enabled = eh_local()
	# A luz do jogador segue o dia e a noite de quem já está na ilha.
	var mundo: World = get_tree().get_first_node_in_group(&"mundo")
	luz.enabled = mundo != null and mundo.noite
	if multiplayer.is_server():
		vida.mudou.connect(func(atual: float, _m: float) -> void: _vida_sync.rpc(atual))
		vida.morreu.connect(_on_morreu)
		inventario.mudou.connect(_roupas_mudaram)
		hurtbox.atingido.connect(func(qtd: float, tipo: StringName, _o: Node) -> void: vida.tomar_dano(qtd, tipo))
		vida.ajuste_dano = func(qtd: float, tipo: StringName) -> float: return Passivas.dano_recebido(self, qtd, tipo)
	if eh_local():
		get_tree().call_group(&"mundo", &"registrar_jogador_local", self)


func _componente(n: Node, nome: String) -> Node:
	n.name = nome
	add_child(n)
	n.set_multiplayer_authority(get_multiplayer_authority())
	return n


## Este jogador é o controlado nesta máquina?
func eh_local() -> bool:
	return is_multiplayer_authority()


func id_rede() -> int:
	return get_multiplayer_authority()


## As habilidades nas teclas Q R T E (as que vêm com a classe e as aprendidas na árvore).
func habilidades() -> Array[HabilidadeData]:
	var l: Array[HabilidadeData] = []
	if ficha == null:
		return l
	for id in ids_nas_teclas():
		var n := ArvoreData.no(classe, id)
		if n and n.usavel() and tem(id):
			l.append(n.habilidade)
	return l


func ids_nas_teclas() -> Array[StringName]:
	return teclas if not teclas.is_empty() else ArvoreData.padrao(classe)


func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		_regenerar_mana(delta)
		_processar_bencao()
		_processar_passivas(delta)
		_enviar_escudo()
		if criando:
			vida.proteger(1.0)  # criando o personagem, ninguém o machuca
	_contar_queda(delta)
	if not eh_local():
		if visual.animation != animacao:
			visual.play(animacao)
		return
	if criando:
		velocity = Vector2.ZERO
		return
	_recarga_golpe = maxf(0.0, _recarga_golpe - delta)
	_recarga_esquiva = maxf(0.0, _recarga_esquiva - delta)
	_atacando = maxf(0.0, _atacando - delta)
	for id in _recargas:
		_recargas[id] = maxf(0.0, _recargas[id] - delta)
	if caido:
		# Caído: parado no chão, sem coletar nem golpear (a tela de morte está aberta).
		velocity = Vector2.ZERO
		_impulso_restante = 0.0
		conjuracao.cancelar()
		_progresso = 0.0
		_cancelar_ajuda()
		return
	_processar_ajuda(delta)

	var entrada := Input.get_vector(&"mover_esquerda", &"mover_direita", &"mover_cima", &"mover_baixo")
	if _impulso_restante > 0.0:
		# O último passo é só o que falta (sem andar um quadro a mais que o pedido).
		velocity = _impulso * minf(1.0, _impulso_restante / delta)
		_impulso_restante -= delta
	else:
		velocity = entrada * ficha.velocidade() * multiplicador_velocidade() * conjuracao.velocidade()
	move_and_slide()

	_atualizar_alvo()
	_processar_interacao(delta)
	_animar(entrada)
	var na_mao := inventario.item_em(barra_escolhida)
	if item_mao != na_mao:
		item_mao = na_mao


func _unhandled_input(event: InputEvent) -> void:
	if not eh_local() or criando or caido:
		return
	# E perto de um aliado caído: segurar levanta ele (_processar_ajuda), em vez da habilidade.
	if event.is_action_pressed(&"habilidade_4") and not menu_aberto and comecar_ajuda():
		return
	# Barra de itens: teclas 1-9 e a rodinha do mouse escolhem o item da mão.
	for k in Inventory.BARRA:
		if event.is_action_pressed(StringName("barra_%d" % (k + 1))):
			barra_escolhida = k
	# Rodinha: troca o item da barra; com uma peça de construção na mão, gira a peça.
	if event is InputEventMouseButton and event.pressed and not Input.is_key_pressed(KEY_CTRL):
		var giro := 1 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else (-1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0)
		if giro != 0:
			var item := item_na_mao()
			if item and item.construcao in [&"parede", &"porta"]:
				rotacao = 1 - rotacao
			else:
				barra_escolhida = (barra_escolhida + giro + Inventory.BARRA) % Inventory.BARRA
	if event.is_action_pressed(&"usar"):
		_pedir_usar.rpc_id(1, barra_escolhida)
	# Clique esquerdo: pôr a peça da mão; abrir baú ou bancada (um clique); segurar em árvore
	# ou pedra coleta (_processar_interacao); em qualquer outro lugar, golpeia (e repete
	# enquanto segura, para quebrar construções e lutar).
	if event.is_action_pressed(&"atacar"):
		if _construir_aqui():
			_ignorar_clique = true
		elif not alvo_ao_alcance():
			golpear()
	# Com a mochila, a bancada ou o baú abertos, o Shift é do Shift + clique (mandar o item
	# para o outro lado) e Q R T E não lançam nada: sem dash e sem habilidade.
	elif event.is_action_pressed(&"esquivar") and not menu_aberto:
		esquivar()
	for i in 4:
		var acao := StringName("habilidade_%d" % (i + 1))
		if event.is_action_pressed(acao):
			if not menu_aberto:
				comecar_habilidade(i)
		elif event.is_action_released(acao) and _carregando == i:
			soltar_carga()


func posicao_mira() -> Vector2:
	return mira_forcada if mira_forcada != null else get_global_mouse_position()


func direcao_mira() -> Vector2:
	var d := posicao_mira() - (global_position + Vector2(0, -10))
	return d.normalized() if d.length() > 0.5 else Vector2.DOWN


## 0 a 1: quanto falta para o próximo "golpe" de coleta (para a barrinha do HUD).
func progresso_interacao() -> float:
	if _ajudando != null:
		return clampf(_tempo_ajuda / TEMPO_AJUDA, 0.0, 1.0)
	if alvo == null:
		return 0.0
	return clampf(_progresso / _tempo_coleta(), 0.0, 1.0)


func alvo_ao_alcance() -> bool:
	return alvo != null and is_instance_valid(alvo) and alvo.perto_de(global_position)


## 0 a 1 do tempo de recarga que falta na habilidade `i` (para o HUD).
func recarga_restante(i: int) -> float:
	var hab := habilidades()
	if i >= hab.size() or hab[i].recarga <= 0.0:
		return 0.0
	return clampf(float(_recargas.get(hab[i].id, 0.0)) / maxf(recarga_de(hab[i]), 0.01), 0.0, 1.0)


func recarga_esquiva_restante() -> float:
	return _recarga_esquiva / ficha.recarga_esquiva()


## Carga extra (0 a 1) enquanto segura uma habilidade de carga (Tiro carregado); -1 fora dela.
func carga_atual() -> float:
	return conjuracao.carga() if conjuracao else -1.0


## Mostra um aviso na tela deste jogador (de onde quer que seja chamado).
func avisar(texto: String, som: StringName = &"") -> void:
	if eh_local():
		_receber_aviso(texto, som)
	else:
		_receber_aviso.rpc_id(id_rede(), texto, som)


# --- Ações (pedidos ao anfitrião) ---------------------------------------------

func golpear() -> void:
	if _recarga_golpe > 0.0 or conjuracao.ativa():  # conjurando, as mãos estão ocupadas
		return
	_recarga_golpe = recarga_golpe * (0.5 if _golpe_rapido else 1.0)  # Ritmo: golpe depois do dash
	_golpe_rapido = false
	_atacando = 0.25
	_animacao_hab = &"golpe"
	var dir := direcao_mira()
	_direcao = SpriteSheets.direcao_de(dir)
	Sfx.tocar(&"ataque", -12.0)
	_pedir_golpe.rpc_id(1, dir)


func esquivar() -> void:
	if _recarga_esquiva > 0.0:
		return
	conjuracao.cancelar()  # o dash interrompe a conjuração
	var entrada := Input.get_vector(&"mover_esquerda", &"mover_direita", &"mover_cima", &"mover_baixo")
	var dir := entrada.normalized() if entrada != Vector2.ZERO else direcao_mira()
	_recarga_esquiva = ficha.recarga_esquiva()
	_impulso = dir * VELOCIDADE_ESQUIVA
	_impulso_restante = DURACAO_ESQUIVA
	if tem(&"ritmo"):
		_ritmo_ate_ms = Time.get_ticks_msec() + Passivas.RITMO_MS
		_golpe_rapido = true
	Sfx.tocar(&"esquiva", -8.0)
	_pedir_esquiva.rpc_id(1)


## Aperta a tecla da habilidade `i`: lança na hora ou começa a conjurar (Conjuracao).
func comecar_habilidade(i: int) -> void:
	var hab := habilidades()
	if i >= hab.size() or float(_recargas.get(hab[i].id, 0.0)) > 0.0 or conjuracao.ativa():
		return
	if mana < custo_de(hab[i]):
		avisar("Sem mana suficiente para %s." % hab[i].nome)
		return
	if Conjuracao.conjura(hab[i]):
		conjuracao.comecar(i, hab[i])
		return
	usar_habilidade(i, 0.0)


## Soltou a tecla: no verde, lança; antes, cancela sem gastar mana nem recarga.
func soltar_carga() -> void:
	if not conjuracao.ativa():
		return
	if not conjuracao.pronta():
		conjuracao.cancelar()
		return
	var i := conjuracao.indice
	var carga := maxf(0.0, conjuracao.carga())
	conjuracao.terminar()
	usar_habilidade(i, carga)


## `atalho`: pula a conjuração (só o atalho dos testes, usar_habilidade_por_id; o anfitrião
## só aceita do jogador dele mesmo).
func usar_habilidade(i: int, carga: float, atalho := false) -> void:
	var hab := habilidades()
	if i >= hab.size() or float(_recargas.get(hab[i].id, 0.0)) > 0.0:
		return
	_recargas[hab[i].id] = recarga_de(hab[i])
	# Animação e som: do .tres; a tabela SONS fica de reserva para as antigas.
	_animacao_hab = hab[i].animacao if hab[i].animacao != &"" else &"golpe"
	_atacando = hab[i].duracao_animacao if hab[i].duracao_animacao > 0.0 else 0.2
	var dir := direcao_mira()
	_direcao = SpriteSheets.direcao_de(dir)
	Sfx.tocar(hab[i].som if hab[i].som != &"" else SONS.get(hab[i].id, &"ataque"), -10.0)
	_pedir_habilidade.rpc_id(1, hab[i].id, dir, posicao_mira(), carga, atalho)


## Atalho usado pelos testes: usa a habilidade pelo id, se a classe tiver, sem esperar a
## conjuração (vale só no anfitrião; ver Conjuracao.liberar_no_anfitriao).
func usar_habilidade_por_id(hab_id: StringName, carga := 0.0) -> bool:
	var hab := habilidades()
	for i in hab.size():
		if hab[i].id == hab_id:
			usar_habilidade(i, carga, true)
			return true
	return false


func lancar_bola_de_fogo() -> void:
	usar_habilidade_por_id(&"bola_de_fogo")


## O anfitrião desloca o jogador (investida). Quem anda é o dono, então ele recebe o pedido.
func mover_por_habilidade(deslocamento: Vector2, duracao: float) -> void:
	if eh_local():
		_impulsionar(deslocamento, duracao)
	else:
		_impulsionar.rpc_id(id_rede(), deslocamento, duracao)


@rpc("any_peer", "reliable")
func _impulsionar(deslocamento: Vector2, duracao: float) -> void:
	if not Net.veio_do_anfitriao():
		return
	_impulso = deslocamento / duracao
	_impulso_restante = duracao


# --- Reação ao golpe de inimigo ou animal ---------------------------------------------
## Dar um passo para trás, mostrar a dor (corpo vermelho e encolhido, visível para todos) e
## tremer de leve a tela de quem apanhou. A proteção de 0,5 s depois do golpe vem do
## HealthComponent (invulneravel_por), então inimigos amontoados não encadeiam golpes.
const EMPURRAO_DANO := 9.0  # px, para longe de quem bateu
const DURACAO_EMPURRAO := 0.12
const TREMOR_DANO := 0.75  # px do mundo (3 px na tela com o zoom 4)
const DURACAO_TREMOR := 0.2

var _tremor := 0.0
var _tween_dano: Tween
var _vida_vista := -1.0


## Só o anfitrião chama, logo depois de um golpe de inimigo ou animal que tirou vida.
## `origem` é onde estava quem bateu.
func reagir_ao_golpe(origem: Vector2) -> void:
	var dir := global_position - origem
	dir = dir.normalized() if dir.length() > 0.1 else Vector2.DOWN
	mover_por_habilidade(dir * EMPURRAO_DANO * Passivas.empurrao(self), DURACAO_EMPURRAO)
	_reagir_dor.rpc(dir)
	conjuracao.apanhou()  # apanhar não cancela a conjuração, só atrasa um pouco


@rpc("any_peer", "call_local", "reliable")
func _reagir_dor(dir: Vector2) -> void:
	if not Net.veio_do_anfitriao():
		return
	visual.dor(dir)
	if eh_local():
		_tremor = DURACAO_TREMOR


## A câmera do dono treme de leve e vai parando.
func _tremer(delta: float) -> void:
	if _tremor > 0.0:
		_tremor = maxf(0.0, _tremor - delta)
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * TREMOR_DANO * (_tremor / DURACAO_TREMOR)
	elif camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO


@rpc("any_peer", "call_local", "reliable")
func _pedir_golpe(dir: Vector2) -> void:
	if not multiplayer.is_server() or not _pedido_do_dono() or caido:
		return
	dir = dir.normalized()
	var forma := CircleShape2D.new()
	forma.radius = alcance_golpe * 0.6
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.transform = Transform2D(0.0, global_position + Vector2(0, -10) + dir * alcance_golpe * 0.6)
	consulta.collide_with_areas = true
	consulta.collide_with_bodies = false
	consulta.collision_mask = 1 << 4
	for r in get_world_2d().direct_space_state.intersect_shape(consulta, 16):
		var area := r.collider as Hurtbox
		if area and area != hurtbox and not area.get_parent() is Player:
			area.receber(dano_golpe * ficha.multiplicador_fisico() * bonus_dano_fisico() * poder_da_mao(&"espada"), &"fisico", self)
			envenenar_atingido(area)


@rpc("any_peer", "call_local", "reliable")
func _pedir_esquiva() -> void:
	if not multiplayer.is_server() or not _pedido_do_dono() or caido:
		return
	vida.proteger(DURACAO_ESQUIVA + 0.1)
	World.efeito_todos(self, &"poeira", global_position)
	PassivasLadino.esquivou(self)  # Esquiva perfeita e Tempestade de aço


@rpc("any_peer", "call_local", "reliable")
func _pedir_habilidade(hab_id: StringName, dir: Vector2, alvo_mira: Vector2, carga: float, atalho := false) -> void:
	if not multiplayer.is_server() or not _pedido_do_dono() or caido:
		return
	# Só vale a habilidade que está numa das teclas (aprendida na árvore).
	var hab: HabilidadeData = null
	for h in habilidades():
		if h.id == hab_id:
			hab = h
	if hab == null:
		return
	# Conjuração: o anfitrião confere o tempo pelo relógio dele (nada sai antes da hora).
	if Conjuracao.conjura(hab):
		var espera := conjuracao.liberar_no_anfitriao(hab, atalho)
		if espera < 0.0:
			conjuracao.recusar_no_anfitriao(hab)
			return
		if not (atalho and eh_local()):
			carga = conjuracao.carga_no_anfitriao(hab, carga, espera)
		conjuracao.terminar_no_anfitriao()
		if espera > 0.0:
			await get_tree().create_timer(espera).timeout
			if caido or not is_inside_tree():
				return
	var agora := Time.get_ticks_msec()
	var custo := custo_de(hab)
	# Folga de 100 ms: o pedido pode chegar um pouco antes do relógio do anfitrião.
	if agora < int(_prontas_no_anfitriao.get(hab_id, 0)) - 100 or mana < custo:
		return
	_prontas_no_anfitriao[hab_id] = agora + int(recarga_de(hab) * 1000.0)
	mana -= custo
	_enviar_mana()
	_contar_feitico(custo <= 0.0 and hab.custo_mana > 0.0)
	# Ressonância: elemento diferente do último dá mais dano neste lançamento.
	_mult_lancamento = 1.0
	if hab.elemento in Passivas.ELEMENTOS_MAGO:
		if tem(&"ressonancia") and _ultimo_elemento != &"" and _ultimo_elemento != hab.elemento:
			_mult_lancamento = Passivas.RESSONANCIA
		_ultimo_elemento = hab.elemento
	Logicas.criar(hab.logica).executar(self, hab, dir.normalized(), alvo_mira, carga)
	_mult_lancamento = 1.0


@rpc("any_peer", "call_local", "reliable")
func _pedir_interacao(caminho_alvo: NodePath) -> void:
	if not multiplayer.is_server() or not _pedido_do_dono() or caido:
		return
	var no := get_node_or_null(caminho_alvo)
	if no == null or not no.has_method("interagir"):
		return
	var area: Interactable = no.get_node_or_null("Interactable")
	# Folga de 8 px: a posição que o anfitrião vê chega com um pouco de atraso.
	if area and area.global_position.distance_to(global_position) <= area.alcance + 8.0:
		no.interagir(self)


func _pedido_do_dono() -> bool:
	var s := multiplayer.get_remote_sender_id()
	return s == id_rede() or (s == 0 and eh_local())


# --- Experiência e níveis ------------------------------------------------------

## Só o anfitrião chama. Sobe quantos níveis a experiência permitir.
func ganhar_xp(quantidade: int) -> void:
	if not multiplayer.is_server() or nivel >= Ficha.NIVEL_MAXIMO:
		return
	xp += ficha.experiencia_ajustada(quantidade)
	var subiu := 0
	while nivel < Ficha.NIVEL_MAXIMO and xp >= Ficha.xp_para_subir(nivel):
		xp -= Ficha.xp_para_subir(nivel)
		nivel += 1
		pontos_atributo += Ficha.PONTOS_ATRIBUTO_POR_NIVEL
		pontos_habilidade += Ficha.PONTOS_HABILIDADE_POR_NIVEL
		subiu += 1
	if nivel >= Ficha.NIVEL_MAXIMO:
		xp = 0
	_enviar_progresso()
	if subiu > 0:
		if not caido:  # caído não levanta por subir de nível
			vida.curar_tudo()
		mana = ficha.mana_maxima()
		_enviar_mana()
		World.efeito_todos(self, &"subir_nivel", global_position + Vector2(0, -14))
		avisar("Subiu para o nível %d! +%d pontos de atributo: abra a ficha (C)." % [nivel, Ficha.PONTOS_ATRIBUTO_POR_NIVEL * subiu], &"subir_nivel")


func xp_para_subir() -> int:
	return Ficha.xp_para_subir(nivel)


## O dono pede para colocar 1 ponto num atributo.
func pedir_atributo(atributo: StringName) -> void:
	_pedir_atributo.rpc_id(1, atributo)


@rpc("any_peer", "call_local", "reliable")
func _pedir_atributo(atributo: StringName) -> void:
	if not multiplayer.is_server() or not _pedido_do_dono():
		return
	if pontos_atributo <= 0 or not atributo in Ficha.ATRIBUTOS:
		return
	pontos_atributo -= 1
	distribuidos[atributo] = distribuidos.get(atributo, 0) + 1
	_enviar_progresso()


func _enviar_progresso() -> void:
	_progresso_sync.rpc(nivel, xp, pontos_atributo, pontos_habilidade, distribuidos, arvore, teclas)


## O anfitrião manda o progresso para todos (o nível aparece no nome em cima da cabeça; a
## árvore de cada um vale para as passivas de grupo, como Comando e Vigília).
func enviar_progresso_para(peer: int) -> void:
	_progresso_sync.rpc_id(peer, nivel, xp, pontos_atributo, pontos_habilidade, distribuidos, arvore, teclas)
	_enviar_aspecto(peer)
	if caido:
		_caido_sync.rpc_id(peer, true, tempo_caido)  # quem entrou agora vê o boneco caído


@rpc("any_peer", "call_local", "reliable")
func _progresso_sync(n: int, x: int, pa: int, ph: int, dist: Dictionary, arv: Dictionary, tec: Array) -> void:
	if not Net.veio_do_anfitriao():
		return
	nivel = n
	xp = x
	pontos_atributo = pa
	pontos_habilidade = ph
	# Copia antes de limpar: na chamada local, `dist` é o próprio `distribuidos`.
	var copia := dist.duplicate()
	distribuidos.clear()
	for k in copia:
		distribuidos[StringName(k)] = int(copia[k])
	_definir_arvore(arv, tec)
	_recalcular_ficha()
	_aplicar_passivas_fixas()
	progresso_mudou.emit()


## Árvore para o arquivo do mundo (JSON: chaves e valores simples).
func _arvore_para_salvar() -> Dictionary:
	var d := {}
	for k in arvore:
		d[String(k)] = arvore[k]
	return d


## Copia a árvore e as teclas recebidas (ou salvas), só com nós que existem na classe.
func _definir_arvore(arv: Dictionary, tec: Array) -> void:
	var copia_arv := arv.duplicate()
	var copia_tec := tec.duplicate()
	arvore.clear()
	for k in copia_arv:
		var n := ArvoreData.no(classe, StringName(k))
		if n:
			arvore[n.id] = clampi(int(copia_arv[k]), 0, n.rank_maximo())
	teclas.clear()
	for k in copia_tec:
		var n := ArvoreData.no(classe, StringName(k))
		if n and n.usavel() and tem(n.id) and not n.id in teclas and teclas.size() < TECLAS:
			teclas.append(n.id)


## O que o anfitrião guarda deste jogador no arquivo do mundo.
func registro() -> Dictionary:
	return {
		"raca": String(raca), "classe": String(classe),
		"nivel": nivel, "xp": xp,
		"pontos_atributo": pontos_atributo, "pontos_habilidade": pontos_habilidade,
		"distribuidos": distribuidos.duplicate(),
		"arvore": _arvore_para_salvar(),
		"teclas": Array(teclas).map(func(id: StringName) -> String: return String(id)),
		"itens": inventario.para_salvar(),
		"aparencia": aparencia.duplicate(),
		"kit": true,
		"pos": [_pos_salvar().x, _pos_salvar().y],
		"salvo_em": Time.get_unix_time_from_system(),
	}


## Só o anfitrião chama, logo depois de criar o jogador: devolve o progresso salvo.
## `pular_criacao`: quem entrou já traz o personagem pronto (testes e linha de comando), então
## o novo personagem é criado direto, sem a tela de criação.
func restaurar(reg: Dictionary, pular_criacao := true) -> void:
	if reg.is_empty():
		if pular_criacao:
			criar_personagem(raca, classe, aparencia_padrao(raca))
		else:
			_iniciar_criacao()
		return
	var salva: Variant = reg.get("aparencia")
	var veio_aparencia := salva is Dictionary
	aparencia = normalizar_aparencia(salva if veio_aparencia else {}, raca)
	nivel = clampi(int(reg.get("nivel", 1)), 1, Ficha.NIVEL_MAXIMO)
	xp = int(reg.get("xp", 0))
	pontos_atributo = int(reg.get("pontos_atributo", 0))
	pontos_habilidade = int(reg.get("pontos_habilidade", 0))
	distribuidos.clear()
	var dist: Dictionary = reg.get("distribuidos", {})
	for k in dist:
		distribuidos[StringName(k)] = int(dist[k])
	_definir_arvore(reg.get("arvore", {}), reg.get("teclas", []))
	_recalcular_ficha()
	_aplicar_passivas_fixas()
	vida.curar_tudo()
	mana = ficha.mana_maxima()
	inventario.definir(reg.get("itens", {}))
	if not reg.get("kit", false):
		dar_kit()
	if not veio_aparencia:
		_vestir_base()  # salvo antes das roupas existirem: ganha as da classe
	_roupas_mudaram()
	_enviar_aspecto()
	_enviar_progresso()


## Refaz a ficha com os pontos distribuídos; vida e mana máximas acompanham.
func _recalcular_ficha() -> void:
	var vida_antes := vida.maximo
	ficha = Ficha.criar(raca, classe, distribuidos)
	vida.maximo = ficha.vida_maxima()
	if multiplayer.is_server() and vida.maximo > vida_antes:
		vida.atual += vida.maximo - vida_antes
		vida.mudou.emit(vida.atual, vida.maximo)


# --- Do anfitrião para o dono -------------------------------------------------

func _regenerar_mana(delta: float) -> void:
	var maximo := ficha.mana_maxima()
	if mana < maximo:
		mana = minf(maximo, mana + ficha.regeneracao_mana() * Passivas.regeneracao_mana(self) * delta)
		if absf(mana - _mana_enviada) >= 1.0 or mana >= maximo:
			_enviar_mana()


func _enviar_mana() -> void:
	_mana_enviada = mana
	if not eh_local():
		_mana_sync.rpc_id(id_rede(), mana)


@rpc("any_peer", "reliable")
func _mana_sync(valor: float) -> void:
	if Net.veio_do_anfitriao():
		mana = valor


@rpc("any_peer", "call_local", "reliable")
func _vida_sync(atual: float) -> void:
	if not Net.veio_do_anfitriao():
		return
	# No anfitrião a vida já mudou antes deste aviso chegar: compara com a última que viu.
	var antes := vida.atual
	if multiplayer.is_server():
		antes = _vida_vista if _vida_vista >= 0.0 else vida.maximo
	_vida_vista = atual
	if not multiplayer.is_server():
		vida.atual = atual
		vida.mudou.emit(atual, vida.maximo)
	if atual < antes:
		Sfx.tocar(&"acerto", -6.0)
		if _tween_dano:
			_tween_dano.kill()
		_tween_dano = create_tween()
		_tween_dano.tween_property(visual, "modulate", Color(1.0, 0.3, 0.3), 0.04)
		_tween_dano.tween_interval(0.08)
		_tween_dano.tween_property(visual, "modulate", Color.WHITE, 0.3)


@rpc("any_peer", "reliable")
func _receber_aviso(texto: String, som: StringName) -> void:
	if not Net.veio_do_anfitriao():
		return
	if som != &"":
		Sfx.tocar(som)
	Events.aviso.emit(texto)


# --- Caído e tela de morte ------------------------------------------------------------
## Vida 0 = CAÍDO: o boneco deita no chão, não anda, não ataca, não usa habilidade nem item,
## os inimigos o ignoram e ele não toma mais dano. Quem cai vê a tela de morte (TelaMorte):
## volta sozinho no acampamento aos TEMPO_REVIVER s, ou antes pelo botão (liberado aos
## TEMPO_BOTAO s). Um Clérigo (Levantar) ou um aliado segurando E perto levantam ali mesmo.
## Quem manda é o anfitrião; todos recebem por _caido_sync.
const TEMPO_REVIVER := 8.0
const TEMPO_BOTAO := 4.0
const PROTECAO_REVIVER := 2.0
## Aliado segurando E perto do caído: levanta com pouca vida.
const TEMPO_AJUDA := 3.0
const RAIO_AJUDA := 28.0
const VIDA_AJUDA := 0.25

var caido := false
## Segundos desde a queda (o anfitrião manda; as outras máquinas contam junto para a tela).
var tempo_caido := 0.0
var _tela_morte: TelaMorte
var _ajudando: Player  # local: o aliado caído que este jogador está levantando (segurando E)
var _tempo_ajuda := 0.0


func _on_morreu() -> void:
	if caido:
		return
	caido = true
	tempo_caido = 0.0
	_caido_sync.rpc(true, 0.0)


## Todo quadro, em todas as máquinas: conta o tempo da queda; o anfitrião levanta aos 8 s.
func _contar_queda(delta: float) -> void:
	if not caido:
		return
	tempo_caido += delta
	if multiplayer.is_server() and tempo_caido >= TEMPO_REVIVER:
		reviver_no_acampamento()


## Segundos que faltam para voltar sozinho.
func falta_reviver() -> float:
	return maxf(0.0, TEMPO_REVIVER - tempo_caido)


## O botão "Reviver agora" já pode ser apertado?
func pode_reviver_agora() -> bool:
	return caido and tempo_caido >= TEMPO_BOTAO


## O dono apertou "Reviver agora" (a tela de morte chama).
func pedir_reviver() -> void:
	if pode_reviver_agora():
		_pedir_reviver.rpc_id(1)


@rpc("any_peer", "call_local", "reliable")
func _pedir_reviver() -> void:
	# Folga de 0,2 s: o relógio do dono pode estar um pouco à frente do anfitrião.
	if not multiplayer.is_server() or not _pedido_do_dono() or not caido or tempo_caido < TEMPO_BOTAO - 0.2:
		return
	reviver_no_acampamento()


## Só o anfitrião: volta no acampamento, com a vida cheia e protegido por 2 s.
func reviver_no_acampamento() -> void:
	if levantar(ponto_de_retorno, 1.0, PROTECAO_REVIVER):
		avisar("Você acordou no acampamento.")


## Só o anfitrião: levanta o caído em `pos` com `fracao` da vida e `protecao` s sem tomar
## dano. Fecha a tela de morte dele. Devolve se levantou (falso se não estava caído).
func levantar(pos: Vector2, fracao: float, protecao: float) -> bool:
	if not multiplayer.is_server() or not caido:
		return false
	caido = false
	tempo_caido = 0.0
	vida.reviver(fracao)
	vida.proteger(protecao)
	teleportar(pos)
	_caido_sync.rpc(false, 0.0)
	return true


@rpc("any_peer", "call_local", "reliable")
func _caido_sync(valor: bool, tempo: float) -> void:
	if not Net.veio_do_anfitriao():
		return
	caido = valor
	tempo_caido = tempo
	visual.caido = valor
	if not eh_local():
		return
	conjuracao.cancelar()
	_impulso_restante = 0.0
	velocity = Vector2.ZERO
	if valor:
		if _tela_morte == null:
			_tela_morte = TelaMorte.new(self)
			add_child(_tela_morte)
	else:
		if _tela_morte:
			_tela_morte.queue_free()
			_tela_morte = null
		camera.reset_smoothing()


## A tela de morte aberta (nula se não caiu). Para os testes.
func tela_morte() -> TelaMorte:
	return _tela_morte


## O aliado caído mais perto (a até RAIO_AJUDA), ou nulo.
func aliado_caido_perto() -> Player:
	var melhor: Player = null
	var menor := RAIO_AJUDA
	for n in get_tree().get_nodes_in_group(&"jogadores"):
		var o := n as Player
		if o and o != self and o.caido:
			var d := o.global_position.distance_to(global_position)
			if d <= menor:
				menor = d
				melhor = o
	return melhor


## Local: apertou E. Se há um aliado caído perto, começa a levantar ele (e devolve true).
func comecar_ajuda() -> bool:
	var o := aliado_caido_perto()
	if o == null:
		return false
	_ajudando = o
	_tempo_ajuda = 0.0
	return true


## O aliado caído que este jogador está levantando agora (nulo se nenhum). Para o HUD.
func ajudando() -> Player:
	return _ajudando


func _cancelar_ajuda() -> void:
	_ajudando = null
	_tempo_ajuda = 0.0


## Local, todo quadro: segurando E perto do caído por TEMPO_AJUDA s, pede ao anfitrião.
func _processar_ajuda(delta: float) -> void:
	if _ajudando == null:
		return
	if not is_instance_valid(_ajudando) or not _ajudando.caido or not Input.is_action_pressed(&"habilidade_4") \
			or _ajudando.global_position.distance_to(global_position) > RAIO_AJUDA + 4.0:
		_cancelar_ajuda()
		return
	_tempo_ajuda += delta
	if _tempo_ajuda >= TEMPO_AJUDA:
		_pedir_ajuda.rpc_id(1, _ajudando.get_path())
		_cancelar_ajuda()


@rpc("any_peer", "call_local", "reliable")
func _pedir_ajuda(caminho: NodePath) -> void:
	if not multiplayer.is_server() or not _pedido_do_dono() or caido:
		return
	var o := get_node_or_null(caminho) as Player
	# Folga de 8 px: a posição que o anfitrião vê chega com um pouco de atraso.
	if o == null or o == self or not o.caido or o.global_position.distance_to(global_position) > RAIO_AJUDA + 8.0:
		return
	if o.levantar(o.global_position, VIDA_AJUDA, PROTECAO_REVIVER):
		World.efeito_todos(o, &"subir_nivel", o.global_position + Vector2(0, -14))
		o.avisar("Um aliado levantou você!", &"subir_nivel")


# --- Local: alvo, coleta e animação -------------------------------------------

func _tempo_coleta() -> float:
	if not alvo:
		return 1.0
	var recurso := alvo.dono() as ResourceNode
	var minerando := recurso != null and recurso.acao == "Minerar"
	var ferramenta := &"picareta" if minerando else &"machado"
	return maxf(alvo.tempo_segurar * ficha.tempo_coleta(minerando) / poder_da_mao(ferramenta) / Passivas.coleta(self, minerando), 0.01)


func _atualizar_alvo() -> void:
	var novo: Interactable = null
	var consulta := PhysicsPointQueryParameters2D.new()
	consulta.position = posicao_mira()
	consulta.collide_with_areas = true
	consulta.collide_with_bodies = false
	consulta.collision_mask = 1 << 3
	var melhor := INF
	for r in get_world_2d().direct_space_state.intersect_point(consulta, 8):
		var area := r.collider as Interactable
		if area and area.disponivel():
			var d := area.global_position.distance_to(consulta.position)
			if d < melhor:
				melhor = d
				novo = area
	if novo != alvo:
		if alvo and is_instance_valid(alvo) and alvo.dono().has_method("destacar"):
			alvo.dono().destacar(false)
		alvo = novo
		_progresso = 0.0
		if alvo:
			alvo.dono().destacar(true)


func _processar_interacao(delta: float) -> void:
	# Clique esquerdo (fora da interface): segurar coleta árvore e pedra e golpeia o resto;
	# um clique rápido (soltou antes de 0,3 s) em baú ou bancada abre; segurar neles quebra.
	var antes := _segurando
	_segurando = (Input.is_action_pressed(&"atacar") or Input.is_action_pressed(&"interagir")) \
			and get_viewport().gui_get_hovered_control() == null
	if _segurando:
		_tempo_segurando += delta
	elif antes:
		if not _ignorar_clique and _tempo_segurando < 0.3 and alvo_ao_alcance() and not alvo.dono() is ResourceNode:
			_pedir_interacao.rpc_id(1, alvo.dono().get_path())
		_tempo_segurando = 0.0
		_ignorar_clique = false
	var em_recurso := alvo_ao_alcance() and alvo.dono() is ResourceNode
	if not _segurando or not em_recurso:
		_progresso = 0.0
		var na_mao := item_na_mao()
		var em_objeto := alvo_ao_alcance() and not em_recurso
		if _segurando and not _ignorar_clique and (na_mao == null or na_mao.construcao == &"") \
				and (not em_objeto or _tempo_segurando > 0.35):
			golpear()  # golpes seguidos: lutar e quebrar construções
		return
	_progresso += delta
	if _progresso >= _tempo_coleta():
		_progresso = 0.0
		_direcao = SpriteSheets.direcao_de(alvo.global_position - global_position)
		_atacando = 0.2
		_pedir_interacao.rpc_id(1, alvo.dono().get_path())


func _animar(entrada: Vector2) -> void:
	var tipo := &"parado"
	if conjuracao.ativa():
		# Conjurando: a arma erguida (boneco: quadro "golpe preparação"), olhando para a mira.
		_direcao = SpriteSheets.direcao_de(direcao_mira())
		tipo = &"conjurar"
	elif _atacando > 0.0:
		tipo = &"golpe" if _animacao_hab == &"" else _animacao_hab
	elif entrada != Vector2.ZERO:
		_direcao = SpriteSheets.direcao_de(entrada)
		tipo = &"andar"
	# O boneco tem perfil (direita e esquerda), frente (baixo) e costas (cima).
	if _direcao == &"direita" or _direcao == &"esquerda":
		_lado = _direcao
	animacao = StringName("%s_%s" % [tipo, _direcao])
	visual.play(animacao)


var _lado: StringName = &"direita"
var _animacao_hab: StringName = &""  # animação da habilidade lançada (HabilidadeData.animacao)


# --- Barra de itens e item na mão --------------------------------------------------
## Espaço da barra (0-8) escolhido pelo dono; sincronizado, para todos saberem o que ele
## tem na mão (o anfitrião usa para a força da ferramenta).
var barra_escolhida := 0


func item_na_mao() -> ItemData:
	var id := inventario.item_em(barra_escolhida)
	return ItemData.carregar(id) if ItemData.existe(id) else null


## Quanto a ferramenta da mão ajuda (1 = mão vazia ou ferramenta de outro tipo).
func poder_da_mao(tipo: StringName) -> float:
	var item := item_na_mao()
	return item.poder if item and item.ferramenta == tipo else 1.0


## O anfitrião manda o dono abrir a tela: &"bancada" (grade 3x3) ou &"bau" (o baú em cima).
@rpc("any_peer", "call_local", "reliable")
func abrir_mochila(modo: StringName) -> void:
	if Net.veio_do_anfitriao() and eh_local():
		Events.abrir_mochila.emit(modo)


# --- Item na mão (F05) ------------------------------------------------------------
## O item da barra vai na mão da frente do boneco (Boneco). `item_mao` é sincronizado: os
## outros jogadores veem o mesmo item.
var item_mao: StringName = &""
## Quanto a corda do arco está puxada (0 a 1; -1 sem puxar). Sincronizada pelo dono.
var carga_arco := -1.0


func _process(delta: float) -> void:
	_atualizar_previa()
	var alfa := ALFA_ESCONDIDO if escondido() else 1.0  # Bomba de fumaça: meio transparente
	var tom := efeitos.cor() if efeitos else Color.WHITE  # estados (Lentidão, Veneno...)
	tom.a = alfa
	if not modulate.is_equal_approx(tom):
		modulate = tom
	if eh_local():
		carga_arco = conjuracao.puxada()
		_tremer(delta)
	visual.item = UsoItens.visual_mao(item_mao)  # armas de cobre e ferro: o desenho da base
	visual.carga = carga_arco


# --- Construção (item da mão com construcao) ---------------------------------------
## Com uma peça na mão (parede, porta, tocha...), o tile embaixo do mouse mostra o ícone
## dela, verde se dá para pôr e vermelho se não; o clique põe (o anfitrião confere).
var _previa: Sprite2D


func _tile_da_mira() -> Vector2i:
	return Vector2i((posicao_mira() / World.T).floor())


func _construir_aqui() -> bool:
	var item := item_na_mao()
	if item == null or item.construcao == &"":
		return false
	var w := get_tree().get_first_node_in_group(&"mundo") as World
	w.pedir_construir.rpc_id(1, _tile_da_mira(), rotacao)
	return true


func _atualizar_previa() -> void:
	var item := item_na_mao()
	var mostrar := eh_local() and item != null and item.construcao != &""
	if _previa == null:
		if not mostrar:
			return
		_previa = Sprite2D.new()
		_previa.top_level = true
		_previa.scale = Vector2(0.25, 0.25)
		_previa.z_index = 5
		add_child(_previa)
	_previa.visible = mostrar
	if not mostrar:
		return
	var w := get_tree().get_first_node_in_group(&"mundo") as World
	var cel := _tile_da_mira()
	_previa.texture = item.icone
	_previa.rotation = PI / 2.0 if rotacao == 1 and item.construcao in [&"parede", &"porta"] else 0.0
	_previa.global_position = Vector2(cel * World.T) + Vector2(World.T, World.T) / 2.0
	_previa.modulate = Color(0.6, 1.0, 0.6, 0.75) if w.pode_construir(item.id, cel, self) else Color(1.0, 0.45, 0.45, 0.6)


## Arma inicial de cada classe (vai para a barra, na mão): o personagem por peças não tem
## arma desenhada, então ela é um item como os outros.
const KIT := {&"guerreiro": &"espada_ferro", &"mago": &"cajado", &"arqueiro": &"arco", &"ladino": &"adagas", &"clerigo": &"maca"}


## Só o anfitrião: personagem novo (ou salvo antes do kit existir) ganha a arma da classe.
## O traje completo correspondente é vestido por `_vestir_base`.
func dar_kit() -> void:
	if KIT.has(classe) and inventario.quantidade_de(KIT[classe]) == 0:
		inventario.adicionar(KIT[classe], 1)


# --- Criação do personagem e roupas (L24) -----------------------------------------------
## Roupa completa de cada classe: inclui cabeça e corpo numa única peça vestível.
const ROUPAS_BASE := {
	&"guerreiro": [&"roupa_guerreiro"],
	&"mago": [&"roupa_mago"],
	&"arqueiro": [&"roupa_arqueiro"],
	&"ladino": [&"roupa_ladino"],
	&"clerigo": [&"roupa_clerigo"],
}
const OPCOES_ROSTO := 3
const OPCOES_PELE := 3

var _tela_criacao: Criacao
var _vestido: Array = []  # [raça, aparência, roupas] que o boneco veste agora


static func aparencia_padrao(raca_id: StringName) -> Dictionary:
	return {"raca": raca_id, "rosto": 0, "pele": 0}


## Aparência válida (o anfitrião não confia no que o cliente manda).
static func normalizar_aparencia(ap: Dictionary, raca_id: StringName) -> Dictionary:
	return {
		"raca": raca_id,
		"rosto": clampi(int(ap.get("rosto", 0)), 0, OPCOES_ROSTO - 1),
		"pele": clampi(int(ap.get("pele", 0)), 0, OPCOES_PELE - 1),
	}


## Só o anfitrião: personagem novo em mundo com a tela de criação. Fica parado, escondido e
## protegido até o dono confirmar raça, aparência e classe (o mundo segue rodando).
func _iniciar_criacao() -> void:
	criando = true
	_enviar_aspecto()
	if eh_local():
		_abrir_criacao()
	else:
		_abrir_criacao.rpc_id(id_rede())


@rpc("any_peer", "reliable")
func _abrir_criacao() -> void:
	if not Net.veio_do_anfitriao() or not eh_local() or _tela_criacao != null:
		return
	_tela_criacao = Criacao.new()
	_tela_criacao.confirmado.connect(_confirmou_criacao)
	add_child(_tela_criacao)


func tela_de_criacao() -> Criacao:
	return _tela_criacao


func _confirmou_criacao(raca_id: StringName, classe_id: StringName, ap: Dictionary) -> void:
	_pedir_criar_personagem.rpc_id(1, raca_id, classe_id, ap)


@rpc("any_peer", "call_local", "reliable")
func _pedir_criar_personagem(raca_id: StringName, classe_id: StringName, ap: Dictionary) -> void:
	if not multiplayer.is_server() or not _pedido_do_dono() or not criando:
		return
	if not raca_id in RacaData.TODAS or not classe_id in ClasseData.TODAS:
		return
	criar_personagem(raca_id, classe_id, ap)


## Só o anfitrião: define raça, classe e aparência, refaz a ficha, veste as roupas base da
## classe, põe a arma dela na barra e solta o jogador no mundo.
func criar_personagem(raca_id: StringName, classe_id: StringName, ap: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	raca = raca_id
	classe = classe_id
	aparencia = normalizar_aparencia(ap, raca_id)
	criando = false
	distribuidos.clear()
	ficha = Ficha.criar(raca, classe, distribuidos)
	vida.maximo = ficha.vida_maxima()
	vida.curar_tudo()
	mana = ficha.mana_maxima()
	_enviar_mana()
	_recargas.clear()
	_prontas_no_anfitriao.clear()
	arvore.clear()
	teclas.clear()
	_aplicar_passivas_fixas()
	dar_kit()
	_vestir_base()
	_roupas_mudaram()
	_enviar_aspecto()
	_enviar_progresso()
	get_tree().call_group(&"mundo", &"personagem_criado", self)


## Só o anfitrião: veste as roupas base da classe.
func _vestir_base() -> void:
	for id in ROUPAS_BASE.get(classe, []):
		if inventario.item_em(Inventory.EQUIP_CORPO) != id:
			inventario.vestir(id)


## Só o anfitrião: o inventário mudou, então as roupas vestidas podem ter mudado.
func _roupas_mudaram() -> void:
	var novas := inventario.roupas()
	if novas == equipado:
		return
	equipado = novas
	_enviar_aspecto()


## Só o anfitrião: manda a todos (ou só a `para`) raça, classe, rosto, pele e roupas.
func _enviar_aspecto(para := 0) -> void:
	if para == 0:
		_aspecto_sync.rpc(raca, classe, aparencia, equipado, criando)
	else:
		_aspecto_sync.rpc_id(para, raca, classe, aparencia, equipado, criando)


## A aparência com a raça e a classe: o boneco usa a arte completa da classe.
func aparencia_completa() -> Dictionary:
	var a := aparencia.duplicate()
	a["raca"] = a.get("raca", raca)
	a["classe"] = classe
	return a


## Veste o boneco se a raça, a aparência ou as roupas mudaram desde a última vez.
func _atualizar_visual() -> void:
	var chave := [raca, classe, aparencia.duplicate(), equipado.duplicate()]
	if chave != _vestido:
		_vestido = chave
		visual.vestir(aparencia_completa(), equipado)


@rpc("any_peer", "call_local", "reliable")
func _aspecto_sync(raca_id: StringName, classe_id: StringName, ap: Dictionary, roupas: Dictionary, em_criacao: bool) -> void:
	if not Net.veio_do_anfitriao():
		return
	var trocou_classe := raca_id != raca or classe_id != classe
	var novo_equipado := {&"cabeca": StringName(roupas.get("cabeca", &"")), &"corpo": StringName(roupas.get("corpo", &""))}
	raca = raca_id
	classe = classe_id
	aparencia = normalizar_aparencia(ap, raca_id)
	equipado = novo_equipado
	criando = em_criacao
	if trocou_classe:
		_recalcular_ficha()
		_recargas.clear()
		_aplicar_passivas_fixas()
		if not multiplayer.is_server():
			arvore.clear()  # a árvore da classe nova chega logo depois (_progresso_sync)
			teclas.clear()
			vida.atual = vida.maximo
			vida.mudou.emit(vida.atual, vida.maximo)
			mana = ficha.mana_maxima()
	_atualizar_visual()
	visual.visible = not criando
	if not criando and _tela_criacao != null:
		_tela_criacao.queue_free()
		_tela_criacao = null
	aspecto_mudou.emit()
	progresso_mudou.emit()


## Botão direito: usa o item da mão (por enquanto, só os que curam).
@rpc("any_peer", "call_local", "reliable")
func _pedir_usar(espaco: int) -> void:
	if not multiplayer.is_server() or not _pedido_do_dono() or caido or espaco < 0 or espaco >= Inventory.BARRA:
		return
	var id := inventario.item_em(espaco)
	if not ItemData.existe(id):
		return
	var dados := ItemData.carregar(id)
	if UsoItens.usar(self, espaco, dados):  # poções de mana e resistência, vara de pescar (L39)
		return
	if dados.cura > 0.0:
		if vida.atual >= vida.maximo:
			# Vida cheia: dá a comida ao aliado ferido mais perto (Luz própria: cura +50%).
			if not PassivasClerigo.dar_comida(self, espaco, dados):
				avisar("Sua vida já está cheia.")
			return
		inventario.gastar(espaco, 1)
		var cura := dados.cura
		vida.curar(cura)
		World.efeito_todos(self, &"subir_nivel", global_position)
		avisar("+%d de vida" % int(cura), &"item")


## O clique esquerdo foi apertado no mundo (não na mochila) e continua apertado.
var _segurando := false
var _tempo_segurando := 0.0
var _ignorar_clique := false  # o clique pôs uma peça: não abre nem golpeia
## Peça de construção girada (0 de frente, 1 de lado), escolhida com a rodinha.
var rotacao := 0


# --- Buffs de habilidade (Bloqueio e Fúria) ---------------------------------------------
## O anfitrião aplica; a Fúria também é avisada ao dono, que é quem anda (velocidade).
const BONUS_FURIA_DANO := 1.5
const BONUS_FURIA_VELOCIDADE := 1.25
var _furia_ate_ms := 0


## Só o anfitrião chama (Bloqueio): `fracao` do dano a menos por `segundos`.
func bloquear(fracao: float, segundos: float) -> void:
	vida.reduzir_dano(fracao, segundos)


## Só o anfitrião chama (Fúria): mais dano físico e mais velocidade por `segundos`.
func enfurecer(segundos: float) -> void:
	_furia_ate_ms = Time.get_ticks_msec() + int(segundos * 1000.0)
	if not eh_local():
		_furia_sync.rpc_id(id_rede(), segundos)


func furia_ativa() -> bool:
	return Time.get_ticks_msec() < _furia_ate_ms


## Multiplicador do dano físico (golpe e habilidades físicas) com a Fúria.
func bonus_dano_fisico() -> float:
	return BONUS_FURIA_DANO if furia_ativa() else 1.0


func multiplicador_velocidade() -> float:
	return (BONUS_FURIA_VELOCIDADE if furia_ativa() else 1.0) * Passivas.velocidade(self)


@rpc("any_peer", "reliable")
func _furia_sync(segundos: float) -> void:
	if Net.veio_do_anfitriao():
		_furia_ate_ms = Time.get_ticks_msec() + int(segundos * 1000.0)


## Só o anfitrião chama (Fúria titânica): o desenho fica `fator` vezes maior por `segundos`,
## em todas as máquinas.
func crescer(fator: float, segundos: float) -> void:
	_crescer.rpc(fator, segundos)


var _crescer_ate_ms := 0


@rpc("any_peer", "call_local", "reliable")
func _crescer(fator: float, segundos: float) -> void:
	if not Net.veio_do_anfitriao():
		return
	_crescer_ate_ms = Time.get_ticks_msec() + int(segundos * 1000.0)
	_escalar_visual(fator)
	get_tree().create_timer(segundos, false).timeout.connect(func() -> void:
		if is_instance_valid(self) and Time.get_ticks_msec() >= _crescer_ate_ms - 10:
			_escalar_visual(1.0))


## O boneco vira o lado pelo sinal de scale.x: muda só o tamanho (escala da cena: 0,25).
func _escalar_visual(fator: float) -> void:
	var s := 0.25 * fator
	visual.scale = Vector2(s * (-1.0 if visual.scale.x < 0.0 else 1.0), s)


# --- Buffs do Ladino e do Clérigo ------------------------------------------------------
## Quem manda é o anfitrião (as habilidades rodam lá). A fumaça também vai a todos, para
## verem o jogador meio transparente; os inimigos olham `escondido()` no anfitrião.
const TEMPO_VENENO := 3.0  # quanto tempo o inimigo envenenado perde vida
const ALFA_ESCONDIDO := 0.45
var _veneno_golpes_ate_ms := 0
var _veneno_dano := 0.0
var _fumaca_ate_ms := 0
var _bencao_ate_ms := 0
var _bencao_proximo_ms := 0
var _bencao_vida := 0.0


## Só o anfitrião chama (Lâmina envenenada): por `segundos`, os golpes envenenam.
func envenenar_golpes(segundos: float, dano_por_segundo: float) -> void:
	_veneno_golpes_ate_ms = Time.get_ticks_msec() + int(segundos * 1000.0)
	_veneno_dano = dano_por_segundo


func golpes_envenenados() -> bool:
	return Time.get_ticks_msec() < _veneno_golpes_ate_ms


## Só o anfitrião chama, logo depois de um golpe: com a Lâmina ativa, envenena quem apanhou.
func envenenar_atingido(area: Hurtbox) -> void:
	if not golpes_envenenados() or not is_instance_valid(area):
		return
	var alvo := area.get_parent()
	if alvo and alvo.has_method(&"envenenar"):
		alvo.envenenar(TEMPO_VENENO, _veneno_dano, self)


## Só o anfitrião chama (Bomba de fumaça): os inimigos perdem este jogador de vista.
func esconder(segundos: float) -> void:
	if tem(&"emboscada"):
		_emboscada_pronta = true
	_fumaca_sync.rpc(segundos)


## Os inimigos não veem este jogador (Bomba de fumaça ou o estado Invisível).
func escondido() -> bool:
	return Time.get_ticks_msec() < _fumaca_ate_ms or (efeitos != null and efeitos.invisivel())


@rpc("any_peer", "call_local", "reliable")
func _fumaca_sync(segundos: float) -> void:
	if Net.veio_do_anfitriao():
		_fumaca_ate_ms = Time.get_ticks_msec() + int(segundos * 1000.0)


## Só o anfitrião chama (Bênção): recupera `vida_por_segundo` a cada segundo, por `segundos`.
## `de`: quem abençoou (as passivas de cura dele valem).
func abencoar(segundos: float, vida_por_segundo: float, de: Player = null) -> void:
	var agora := Time.get_ticks_msec()
	_bencao_ate_ms = agora + int(segundos * 1000.0)
	_bencao_proximo_ms = agora + 1000
	_bencao_vida = vida_por_segundo
	_bencao_de = de


func abencoado() -> bool:
	return _bencao_ate_ms > 0


## Só o anfitrião: uma cura por segundo enquanto a Bênção dura.
func _processar_bencao() -> void:
	if _bencao_ate_ms == 0 or Time.get_ticks_msec() < _bencao_proximo_ms:
		return
	_bencao_proximo_ms += 1000
	var de := _bencao_de if is_instance_valid(_bencao_de) else null
	if vida.esta_vivo() and (vida.atual < vida.maximo or (de and de.tem(&"fe"))):
		receber_cura(de, _bencao_vida)
	if _bencao_proximo_ms > _bencao_ate_ms:
		_bencao_ate_ms = 0


## Só o anfitrião: cura vinda de `de` (Clérigo). Mãos que curam aumenta; com a Fé, o que
## passaria da vida máxima vira escudo por 5 s (a Égide deixa o escudo mais forte).
func receber_cura(de: Player, quantidade: float) -> void:
	if de:
		quantidade *= Passivas.cura(de)
	var sobra := vida.curar(quantidade)
	if de and de.tem(&"fe") and sobra > 0.0:
		vida.dar_escudo(sobra * Passivas.escudos(de), Passivas.FE_SEGUNDOS)
	PassivasClerigo.curou(de, self, quantidade)  # Mãos que curam (limpa), Elo vital (divide)


## Só o anfitrião (Levantar do Clérigo): põe o jogador em `pos`. Quem anda é o dono.
func teleportar(pos: Vector2) -> void:
	global_position = pos
	if not eh_local() and multiplayer.get_peers().has(id_rede()):
		_teleportar.rpc_id(id_rede(), pos)


@rpc("any_peer", "reliable")
func _teleportar(pos: Vector2) -> void:
	if Net.veio_do_anfitriao():
		global_position = pos
		camera.reset_smoothing()


## Só o anfitrião (Amanhecer do Clérigo): a luz deste jogador fica grande e forte por
## `segundos` em todas as máquinas (é a mesma luz da noite, só maior).
func clarear(segundos: float, raio: float) -> void:
	_clarear.rpc(segundos, raio)


@rpc("any_peer", "call_local", "reliable")
func _clarear(segundos: float, raio: float) -> void:
	if not Net.veio_do_anfitriao():
		return
	var escala := luz.texture_scale
	var energia := luz.energy
	luz.texture_scale = escala * raio / 24.0
	luz.energy = 1.0
	luz.enabled = true
	get_tree().create_timer(segundos, false).timeout.connect(func() -> void:
		if not is_instance_valid(self):
			return
		luz.texture_scale = escala
		luz.energy = energia
		var mundo: World = get_tree().get_first_node_in_group(&"mundo")
		luz.enabled = mundo != null and mundo.noite)


## Fé: o escudo fica só na vida do anfitrião; o dono recebe o valor para o HUD mostrar.
var _escudo_enviado := 0.0


func _enviar_escudo() -> void:
	if is_equal_approx(vida.escudo, _escudo_enviado):
		return
	_escudo_enviado = vida.escudo
	if not eh_local() and multiplayer.get_peers().has(id_rede()):
		_escudo_sync.rpc_id(id_rede(), vida.escudo)


@rpc("any_peer", "reliable")
func _escudo_sync(valor: float) -> void:
	if Net.veio_do_anfitriao():
		vida.escudo = valor


# --- Árvore de habilidades ----------------------------------------------------------------
## Os nós ficam em ArvoreData; o que as passivas fazem, em Passivas. O dono PEDE para
## aprender (ou melhorar) um nó e para trocar o que vai em cada tecla; o anfitrião confere
## pontos, nível, pré-requisitos e o ramo escolhido, aplica e manda para todos.
const TECLAS := 4

var _bencao_de: Player
var _mult_lancamento := 1.0  # Ressonância (vale só durante um lançamento)
var _ultimo_elemento: StringName = &""
var _feiticos := 0  # Sobrecarga: feitiços seguidos pagos
var _feitico_gratis := false
var _emboscada_pronta := false
var _ritmo_ate_ms := 0
var _golpe_rapido := false
var _aura := 0.0
var _pos_parado := Vector2.INF
var _parado_desde_ms := 0
var _suspiro_pronto_ms := 0


## Nível do nó: 0 não aprendido, 1 aprendido, 2 a 4 com melhorias. Os da classe valem 1.
func rank(no_id: StringName) -> int:
	var r: int = arvore.get(no_id, 0)
	if r == 0 and ArvoreData.eh_padrao(classe, no_id):
		return 1
	return r


func tem(no_id: StringName) -> bool:
	return rank(no_id) > 0


func melhorias(no_id: StringName) -> int:
	return maxi(0, rank(no_id) - 1)


## O ramo que o jogador escolheu (o primeiro nó de ramo aprendido), ou vazio.
func ramo_escolhido() -> StringName:
	for id in arvore:
		var n := ArvoreData.no(classe, id)
		if n and n.ramo != NoArvore.RAMO_CLASSE and n.ramo != NoArvore.RAMO_INICIAIS and arvore[id] > 0:
			return n.ramo
	return &""


## Por que não dá para aprender (ou melhorar) o nó agora. Vazio: dá. Os mesmos testes
## rodam na tela (para o botão) e no anfitrião (que é quem decide).
func motivo_bloqueio(n: NoArvore) -> String:
	if n == null:
		return "Esse nó não é da sua classe."
	var r := rank(n.id)
	if r >= n.rank_maximo():
		if n.padrao and n.rank_maximo() == 1:
			return "Já vem com a classe."
		return "Já aprendido." if n.rank_maximo() == 1 else "Melhorias completas."
	if r == 0:
		if nivel < n.nivel:
			return "Precisa do nível %d." % n.nivel
		for req in n.requisitos:
			if not tem(req):
				return "Precisa aprender antes: %s." % _nome_no(req)
		if not n.algum_de.is_empty() and not n.algum_de.any(func(id: StringName) -> bool: return tem(id)):
			var nomes: Array[String] = []
			for id in n.algum_de:
				nomes.append(_nome_no(id))
			return "Precisa aprender antes uma destas: %s." % ", ".join(nomes)
		var escolhido := ramo_escolhido()
		if n.ramo != NoArvore.RAMO_CLASSE and n.ramo != NoArvore.RAMO_INICIAIS and escolhido != &"" and escolhido != n.ramo:
			return "Você já escolheu o ramo %s (só um ramo por personagem)." % ArvoreData.nome_ramo(classe, escolhido)
	var custo := n.custo if r == 0 else 1
	if pontos_habilidade < custo:
		return "Sem pontos de habilidade (ganhe 1 a cada nível)."
	return ""


func _nome_no(no_id: StringName) -> String:
	var n := ArvoreData.no(classe, no_id)
	return n.nome if n else String(no_id)


## O dono pede para aprender ou melhorar um nó.
func pedir_aprender(no_id: StringName) -> void:
	_pedir_aprender.rpc_id(1, no_id)


@rpc("any_peer", "call_local", "reliable")
func _pedir_aprender(no_id: StringName) -> void:
	if not multiplayer.is_server() or not _pedido_do_dono():
		return
	var n := ArvoreData.no(classe, no_id)
	var motivo := motivo_bloqueio(n)
	if motivo != "":
		avisar(motivo)
		return
	var r := rank(no_id)
	pontos_habilidade -= n.custo if r == 0 else 1
	arvore[no_id] = r + 1
	if r == 0 and n.usavel():
		_por_numa_tecla_livre(no_id)
	_aplicar_passivas_fixas()
	_enviar_progresso()
	if r == 0:
		avisar("Aprendeu %s!" % n.nome, &"subir_nivel")
	else:
		avisar("%s melhorou (%d de %d)." % [n.nome, r, NoArvore.MELHORIAS], &"subir_nivel")


## Atalho dos testes (só no anfitrião): aprende o nó sem gastar ponto nem olhar o nível.
func aprender_de_graca(no_id: StringName) -> void:
	var n := ArvoreData.no(classe, no_id)
	if not multiplayer.is_server() or n == null or tem(no_id):
		return
	arvore[no_id] = 1
	if n.usavel():
		_por_numa_tecla_livre(no_id)
	_aplicar_passivas_fixas()
	_enviar_progresso()


func _por_numa_tecla_livre(no_id: StringName) -> void:
	if teclas.is_empty():
		teclas = ArvoreData.padrao(classe).duplicate()
	if not no_id in teclas and teclas.size() < TECLAS:
		teclas.append(no_id)


## O dono pede para pôr a habilidade `no_id` na tecla `posicao` (0 a 3 = Q R T E).
func pedir_tecla(no_id: StringName, posicao: int) -> void:
	_pedir_tecla.rpc_id(1, no_id, posicao)


@rpc("any_peer", "call_local", "reliable")
func _pedir_tecla(no_id: StringName, posicao: int) -> void:
	if not multiplayer.is_server() or not _pedido_do_dono():
		return
	var n := ArvoreData.no(classe, no_id)
	if n == null or not n.usavel() or not tem(no_id) or posicao < 0 or posicao >= TECLAS:
		return
	var t: Array[StringName] = ids_nas_teclas().duplicate()
	var onde := t.find(no_id)
	if onde >= 0:
		if posicao >= t.size():
			return
		t[onde] = t[posicao]  # troca de lugar com a que estava lá
		t[posicao] = no_id
	elif posicao < t.size():
		t[posicao] = no_id
	else:
		t.append(no_id)
	teclas = t
	_enviar_progresso()


func recarga_de(hab: HabilidadeData) -> float:
	return Passivas.recarga(self, hab)


func custo_de(hab: HabilidadeData) -> float:
	if _feitico_gratis and tem(&"sobrecarga") and hab.custo_mana > 0.0:
		return 0.0
	return Passivas.custo_mana(self, hab)


## Dano das habilidades: melhorias e Ressonância.
func mult_habilidade(hab: HabilidadeData) -> float:
	return (1.0 + NoArvore.DANO_POR_MELHORIA * melhorias(hab.id)) * _mult_lancamento


## Sobrecarga (anfitrião): a cada 4 feitiços pagos, o próximo sai de graça.
func _contar_feitico(foi_gratis: bool) -> void:
	if not tem(&"sobrecarga"):
		return
	if foi_gratis:
		_feiticos = 0
		_definir_gratis(false)
		return
	_feiticos += 1
	if _feiticos >= Passivas.SOBRECARGA_A_CADA:
		_feiticos = 0
		_definir_gratis(true)
		avisar("Sobrecarga! O próximo feitiço sai sem gastar mana.")


func _definir_gratis(valor: bool) -> void:
	_feitico_gratis = valor
	if not eh_local():
		_gratis_sync.rpc_id(id_rede(), valor)


@rpc("any_peer", "reliable")
func _gratis_sync(valor: bool) -> void:
	if Net.veio_do_anfitriao():
		_feitico_gratis = valor


func feitico_gratis() -> bool:
	return _feitico_gratis


## Emboscada (anfitrião): o primeiro golpe depois da fumaça é crítico.
func consumir_emboscada() -> bool:
	if not _emboscada_pronta:
		return false
	_emboscada_pronta = false
	return Time.get_ticks_msec() <= _fumaca_ate_ms + Passivas.EMBOSCADA_JANELA_MS


func ritmo_ativo() -> bool:
	return Time.get_ticks_msec() < _ritmo_ate_ms


## Segundos que o jogador está parado no mesmo lugar (Raízes; anfitrião).
func parado_ha() -> float:
	if _pos_parado == Vector2.INF:
		return 0.0
	return (Time.get_ticks_msec() - _parado_desde_ms) / 1000.0


func dano_veneno() -> float:
	return _veneno_dano


## Último suspiro (anfitrião): gasta a vez deste Clérigo, se estiver pronta.
func usar_ultimo_suspiro() -> bool:
	var agora := Time.get_ticks_msec()
	if _suspiro_pronto_ms > 0 and agora < _suspiro_pronto_ms:
		return false
	_suspiro_pronto_ms = agora + Passivas.ULTIMO_SUSPIRO_MS
	return true


## Para onde o jogador olha (das animações sincronizadas; vale em todas as máquinas).
func frente() -> Vector2:
	var a := String(animacao)
	if a.ends_with("esquerda"):
		return Vector2.LEFT
	if a.ends_with("direita"):
		return Vector2.RIGHT
	if a.ends_with("cima"):
		return Vector2.UP
	return Vector2.DOWN


## Quanto os inimigos enxergam este jogador (Passos de gato).
func fator_visao() -> float:
	return Passivas.visao_inimiga(self)


## Passivas que valem o tempo todo: a Luz própria do Clérigo afasta os slimes da noite
## (World.luz_que_protege olha o grupo "luz_protege").
func _aplicar_passivas_fixas() -> void:
	if tem(&"luz_propria"):
		set_meta(&"raio_luz", Passivas.LUZ_PROPRIA_RAIO)
		if not is_in_group(&"luz_protege"):
			add_to_group(&"luz_protege")
	elif is_in_group(&"luz_protege"):
		remove_from_group(&"luz_protege")
	PassivasMago.fixas(self)  # Faísca


## Só o anfitrião, todo quadro: Aura serena e o relógio das Raízes.
func _processar_passivas(delta: float) -> void:
	if ficha == null or criando:
		return
	if _pos_parado == Vector2.INF or global_position.distance_to(_pos_parado) > 1.0:
		_pos_parado = global_position
		_parado_desde_ms = Time.get_ticks_msec()
	Passivas.processar(self, delta)
	if tem(&"aura_serena"):
		_aura += delta
		if _aura >= Passivas.AURA_INTERVALO:
			_aura -= Passivas.AURA_INTERVALO
			for j in Logicas.jogadores_em_volta(self, Passivas.AURA_RAIO):
				if j.vida.esta_vivo() and j.vida.atual < j.vida.maximo:
					j.receber_cura(self, Passivas.AURA_SERENA)


## Cambalhota (o anfitrião manda): o dash fica pronto na hora, para o segundo pulo.
func liberar_esquiva() -> void:
	if eh_local():
		_liberar_esquiva()
	else:
		_liberar_esquiva.rpc_id(id_rede())


@rpc("any_peer", "reliable")
func _liberar_esquiva() -> void:
	if Net.veio_do_anfitriao():
		_recarga_esquiva = 0.0


## Onde salvar o jogador: caído, ele volta no acampamento (como se tivesse revivido).
func _pos_salvar() -> Vector2:
	return ponto_de_retorno if caido else global_position
