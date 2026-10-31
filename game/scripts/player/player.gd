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
}

@export var dano_golpe := 1.0
@export var alcance_golpe := 22.0
@export var recarga_golpe := 0.35

## Animação atual (sincronizada para os outros jogadores verem).
@export var animacao: StringName = &"parado_direita"
## Personagem (sincronizado ao nascer).
@export var raca: StringName = &"humano"
@export var classe: StringName = &"guerreiro"

## Nível, experiência ou pontos mudaram (o HUD escuta).
signal progresso_mudou

var ficha: Ficha
var mana := 0.0
# Progressão: quem manda é o anfitrião; todos recebem por _progresso_sync.
var nivel := 1
var xp := 0
var pontos_atributo := 0
var pontos_habilidade := 0
var distribuidos: Dictionary[StringName, int] = {}
## Posição de mira fixa (usada pelos testes). Se nula, usa o mouse.
var mira_forcada: Variant = null
var alvo: Interactable = null
var ponto_de_retorno := Vector2.ZERO

var _direcao: StringName = &"baixo"
var _progresso := 0.0
var _recarga_golpe := 0.0
var _atacando := 0.0
var _recargas: Array[float] = []          # local (para o HUD)
var _prontas_no_anfitriao: Dictionary = {}  # índice → ms (o anfitrião confere)
var _recarga_esquiva := 0.0
var _impulso := Vector2.ZERO
var _impulso_restante := 0.0
var _carregando := -1
var _inicio_carga := 0.0
var _mana_enviada := -1.0

@onready var visual: Boneco = $Visual
@onready var vida: HealthComponent = $HealthComponent
@onready var inventario: Inventory = $Inventory
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var camera: Camera2D = $Camera2D
@onready var luz: PointLight2D = $Luz


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _ready() -> void:
	add_to_group(&"jogadores")
	if eh_local() and not multiplayer.is_server():
		# O jogador controlado aqui não recebe as propriedades de nascimento.
		raca = Net.raca
		classe = Net.classe
	ficha = Ficha.criar(raca, classe)
	vida.maximo = ficha.vida_maxima()
	vida.atual = vida.maximo
	mana = ficha.mana_maxima()
	_recargas.resize(habilidades().size())
	_recargas.fill(0.0)
	ponto_de_retorno = position
	visual.configurar(raca, classe)
	visual.play(animacao)
	camera.enabled = eh_local()
	# A luz do jogador segue o dia e a noite de quem já está na ilha.
	var mundo: World = get_tree().get_first_node_in_group(&"mundo")
	luz.enabled = mundo != null and mundo.noite
	if multiplayer.is_server():
		vida.mudou.connect(func(atual: float, _m: float) -> void: _vida_sync.rpc(atual))
		vida.morreu.connect(_on_morreu)
		hurtbox.atingido.connect(func(qtd: float, tipo: StringName, _o: Node) -> void: vida.tomar_dano(qtd, tipo))
	if eh_local():
		get_tree().call_group(&"mundo", &"registrar_jogador_local", self)


## Este jogador é o controlado nesta máquina?
func eh_local() -> bool:
	return is_multiplayer_authority()


func id_rede() -> int:
	return get_multiplayer_authority()


func habilidades() -> Array[HabilidadeData]:
	return ficha.classe.habilidades if ficha else ([] as Array[HabilidadeData])


func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		_regenerar_mana(delta)
	if not eh_local():
		if visual.animation != animacao:
			visual.play(animacao)
		return
	_recarga_golpe = maxf(0.0, _recarga_golpe - delta)
	_recarga_esquiva = maxf(0.0, _recarga_esquiva - delta)
	_atacando = maxf(0.0, _atacando - delta)
	for i in _recargas.size():
		_recargas[i] = maxf(0.0, _recargas[i] - delta)

	var entrada := Input.get_vector(&"mover_esquerda", &"mover_direita", &"mover_cima", &"mover_baixo")
	if _impulso_restante > 0.0:
		_impulso_restante -= delta
		velocity = _impulso
	else:
		velocity = entrada * ficha.velocidade() * multiplicador_velocidade()
	move_and_slide()

	_atualizar_alvo()
	_processar_interacao(delta)
	_animar(entrada)
	var na_mao := inventario.item_em(barra_escolhida)
	if item_mao != na_mao:
		item_mao = na_mao


func _unhandled_input(event: InputEvent) -> void:
	if not eh_local():
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
	elif event.is_action_pressed(&"esquivar"):
		esquivar()
	for i in 4:
		var acao := StringName("habilidade_%d" % (i + 1))
		if event.is_action_pressed(acao):
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
	return _recargas[i] / hab[i].recarga


func recarga_esquiva_restante() -> float:
	return _recarga_esquiva / ficha.recarga_esquiva()


## 0 a 1 enquanto segura uma habilidade de carregar; -1 se não está carregando.
func carga_atual() -> float:
	if _carregando < 0:
		return -1.0
	return clampf((Time.get_ticks_msec() / 1000.0 - _inicio_carga) / CARGA_MAXIMA, 0.0, 1.0)


## Mostra um aviso na tela deste jogador (de onde quer que seja chamado).
func avisar(texto: String, som: StringName = &"") -> void:
	if eh_local():
		_receber_aviso(texto, som)
	else:
		_receber_aviso.rpc_id(id_rede(), texto, som)


# --- Ações (pedidos ao anfitrião) ---------------------------------------------

func golpear() -> void:
	if _recarga_golpe > 0.0:
		return
	_recarga_golpe = recarga_golpe
	_atacando = 0.25
	var dir := direcao_mira()
	_direcao = SpriteSheets.direcao_de(dir)
	Sfx.tocar(&"ataque", -12.0)
	_pedir_golpe.rpc_id(1, dir)


func esquivar() -> void:
	if _recarga_esquiva > 0.0:
		return
	var entrada := Input.get_vector(&"mover_esquerda", &"mover_direita", &"mover_cima", &"mover_baixo")
	var dir := entrada.normalized() if entrada != Vector2.ZERO else direcao_mira()
	_recarga_esquiva = ficha.recarga_esquiva()
	_impulso = dir * VELOCIDADE_ESQUIVA
	_impulso_restante = DURACAO_ESQUIVA
	Sfx.tocar(&"esquiva", -8.0)
	_pedir_esquiva.rpc_id(1)


## Aperta a tecla da habilidade `i`: lança na hora ou começa a carregar.
func comecar_habilidade(i: int) -> void:
	var hab := habilidades()
	if i >= hab.size() or _recargas[i] > 0.0:
		return
	if mana < hab[i].custo_mana:
		avisar("Sem mana suficiente para %s." % hab[i].nome)
		return
	if hab[i].modo == HabilidadeData.Modo.CARREGAR:
		_carregando = i
		_inicio_carga = Time.get_ticks_msec() / 1000.0
		return
	usar_habilidade(i, 0.0)


func soltar_carga() -> void:
	if _carregando < 0:
		return
	var i := _carregando
	var carga := carga_atual()
	_carregando = -1
	usar_habilidade(i, carga)


func usar_habilidade(i: int, carga: float) -> void:
	var hab := habilidades()
	if i >= hab.size() or _recargas[i] > 0.0:
		return
	_recargas[i] = hab[i].recarga
	_atacando = 0.2
	var dir := direcao_mira()
	_direcao = SpriteSheets.direcao_de(dir)
	Sfx.tocar(SONS.get(hab[i].id, &"ataque"), -10.0)
	_pedir_habilidade.rpc_id(1, i, dir, posicao_mira(), carga)


## Atalho usado pelos testes: usa a habilidade pelo id, se a classe tiver.
func usar_habilidade_por_id(hab_id: StringName, carga := 0.0) -> bool:
	var hab := habilidades()
	for i in hab.size():
		if hab[i].id == hab_id:
			usar_habilidade(i, carga)
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


@rpc("any_peer", "call_local", "reliable")
func _pedir_golpe(dir: Vector2) -> void:
	if not multiplayer.is_server() or not _pedido_do_dono():
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


@rpc("any_peer", "call_local", "reliable")
func _pedir_esquiva() -> void:
	if not multiplayer.is_server() or not _pedido_do_dono():
		return
	vida.proteger(DURACAO_ESQUIVA + 0.1)
	World.efeito_todos(self, &"poeira", global_position)


@rpc("any_peer", "call_local", "reliable")
func _pedir_habilidade(i: int, dir: Vector2, alvo_mira: Vector2, carga: float) -> void:
	if not multiplayer.is_server() or not _pedido_do_dono():
		return
	var hab := habilidades()
	if i < 0 or i >= hab.size():
		return
	var agora := Time.get_ticks_msec()
	# Folga de 100 ms: o pedido pode chegar um pouco antes do relógio do anfitrião.
	if agora < int(_prontas_no_anfitriao.get(i, 0)) - 100 or mana < hab[i].custo_mana:
		return
	_prontas_no_anfitriao[i] = agora + int(hab[i].recarga * 1000.0)
	mana -= hab[i].custo_mana
	_enviar_mana()
	Logicas.criar(hab[i].logica).executar(self, hab[i], dir.normalized(), alvo_mira, carga)


@rpc("any_peer", "call_local", "reliable")
func _pedir_interacao(caminho_alvo: NodePath) -> void:
	if not multiplayer.is_server() or not _pedido_do_dono():
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
	_progresso_sync.rpc(nivel, xp, pontos_atributo, pontos_habilidade, distribuidos)


## O anfitrião manda o progresso para todos (o nível aparece no nome em cima da cabeça).
func enviar_progresso_para(peer: int) -> void:
	_progresso_sync.rpc_id(peer, nivel, xp, pontos_atributo, pontos_habilidade, distribuidos)


@rpc("any_peer", "call_local", "reliable")
func _progresso_sync(n: int, x: int, pa: int, ph: int, dist: Dictionary) -> void:
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
	_recalcular_ficha()
	progresso_mudou.emit()


## O que o anfitrião guarda deste jogador no arquivo do mundo.
func registro() -> Dictionary:
	return {
		"raca": String(raca), "classe": String(classe),
		"nivel": nivel, "xp": xp,
		"pontos_atributo": pontos_atributo, "pontos_habilidade": pontos_habilidade,
		"distribuidos": distribuidos.duplicate(),
		"itens": inventario.para_salvar(),
		"kit": true,
		"pos": [global_position.x, global_position.y],
		"salvo_em": Time.get_unix_time_from_system(),
	}


## Só o anfitrião chama, logo depois de criar o jogador: devolve o progresso salvo.
func restaurar(reg: Dictionary) -> void:
	if reg.is_empty():
		# Personagem novo: só ganha a arma da classe (sem zerar o que já ganhou ao entrar).
		dar_kit()
		return
	nivel = clampi(int(reg.get("nivel", 1)), 1, Ficha.NIVEL_MAXIMO)
	xp = int(reg.get("xp", 0))
	pontos_atributo = int(reg.get("pontos_atributo", 0))
	pontos_habilidade = int(reg.get("pontos_habilidade", 0))
	distribuidos.clear()
	var dist: Dictionary = reg.get("distribuidos", {})
	for k in dist:
		distribuidos[StringName(k)] = int(dist[k])
	_recalcular_ficha()
	vida.curar_tudo()
	mana = ficha.mana_maxima()
	inventario.definir(reg.get("itens", {}))
	if not reg.get("kit", false):
		dar_kit()
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
		mana = minf(maximo, mana + ficha.regeneracao_mana() * delta)
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
	var antes := vida.atual
	if not multiplayer.is_server():
		vida.atual = atual
		vida.mudou.emit(atual, vida.maximo)
	if atual < antes:
		Sfx.tocar(&"acerto", -6.0)
		var t := create_tween()
		t.tween_property(visual, "modulate", Color(1.0, 0.45, 0.45), 0.05)
		t.tween_property(visual, "modulate", Color.WHITE, 0.25)


@rpc("any_peer", "reliable")
func _receber_aviso(texto: String, som: StringName) -> void:
	if not Net.veio_do_anfitriao():
		return
	if som != &"":
		Sfx.tocar(som)
	Events.aviso.emit(texto)


@rpc("any_peer", "call_local", "reliable")
func _renascer() -> void:
	if not Net.veio_do_anfitriao():
		return
	global_position = ponto_de_retorno
	camera.reset_smoothing()
	Events.aviso.emit("Você desmaiou e acordou no acampamento.")


func _on_morreu() -> void:
	vida.curar_tudo()
	if eh_local():
		_renascer()
	else:
		_renascer.rpc_id(id_rede())


# --- Local: alvo, coleta e animação -------------------------------------------

func _tempo_coleta() -> float:
	if not alvo:
		return 1.0
	var recurso := alvo.dono() as ResourceNode
	var ferramenta := &"picareta" if recurso and recurso.acao == "Minerar" else &"machado"
	return maxf(alvo.tempo_segurar * ficha.tempo_coleta() / poder_da_mao(ferramenta), 0.01)


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
	if _atacando > 0.0 or _carregando >= 0:
		if _carregando >= 0:
			_direcao = SpriteSheets.direcao_de(direcao_mira())
		tipo = &"golpe"
	elif entrada != Vector2.ZERO:
		_direcao = SpriteSheets.direcao_de(entrada)
		tipo = &"andar"
	# O boneco tem perfil (direita e esquerda), frente (baixo) e costas (cima).
	if _direcao == &"direita" or _direcao == &"esquerda":
		_lado = _direcao
	animacao = StringName("%s_%s" % [tipo, _direcao])
	visual.play(animacao)


var _lado: StringName = &"direita"


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


func _process(_delta: float) -> void:
	_atualizar_previa()
	if eh_local():
		carga_arco = carga_atual()
	visual.item = item_mao
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
const KIT := {&"guerreiro": &"espada_ferro", &"mago": &"cajado", &"arqueiro": &"arco"}


## Só o anfitrião: personagem novo (ou salvo antes do kit existir) ganha a arma da classe.
func dar_kit() -> void:
	if KIT.has(classe) and inventario.quantidade_de(KIT[classe]) == 0:
		inventario.adicionar(KIT[classe], 1)


## Botão direito: usa o item da mão (por enquanto, só os que curam).
@rpc("any_peer", "call_local", "reliable")
func _pedir_usar(espaco: int) -> void:
	if not multiplayer.is_server() or not _pedido_do_dono() or espaco < 0 or espaco >= Inventory.BARRA:
		return
	var id := inventario.item_em(espaco)
	if not ItemData.existe(id):
		return
	var dados := ItemData.carregar(id)
	if dados.cura > 0.0:
		if vida.atual >= vida.maximo:
			avisar("Sua vida já está cheia.")
			return
		inventario.gastar(espaco, 1)
		vida.curar(dados.cura)
		World.efeito_todos(self, &"subir_nivel", global_position)
		avisar("+%d de vida" % int(dados.cura), &"item")


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
	return BONUS_FURIA_VELOCIDADE if furia_ativa() else 1.0


@rpc("any_peer", "reliable")
func _furia_sync(segundos: float) -> void:
	if Net.veio_do_anfitriao():
		_furia_ate_ms = Time.get_ticks_msec() + int(segundos * 1000.0)
