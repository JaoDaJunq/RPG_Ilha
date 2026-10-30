class_name World
extends Node2D
## A ilha: gera o chão, espalha árvores, pedras, plantas e slimes, monta o acampamento,
## cria o jogador e controla o dia e a noite (N).
##
## O formato da ilha é gerado com uma semente fixa (sempre a mesma ilha).
## O mapa feito à mão e os biomas vêm na Etapa 4.

const ARVORE := preload("res://scenes/world/arvore.tscn")
const PEDRA := preload("res://scenes/world/pedra.tscn")
const SLIME := preload("res://scenes/enemies/slime.tscn")
const JOGADOR := preload("res://scenes/player/player.tscn")
const TEX_CHAO := preload("res://assets/sprites/chao/chao.png")
const TEX_AGUA := preload("res://assets/placeholder/ninja/tilesets/TilesetWater.png")
const TEX_PLANTAS := preload("res://assets/sprites/natureza/plantas.png")
const TEX_ACAMPAMENTO := preload("res://assets/sprites/acampamento/acampamento.png")
const LUZ := preload("res://assets/luz/luz_radial.tres")

const T := 16
# Coordenadas (em tiles) dentro das folhas do Ninja Adventure.
## Blocos de chão (L02): cada bloco tem 32x32 = 2x2 tiles, na ordem da folha.
enum Bloco { GRAMA, GRAMA_FLORES, TERRA, AREIA, AGUA, GRAMA_ESCURA }
const GELO := Vector2i(14, 1)  # gelo liso da folha de água (sem colisão: dá para andar)
## Árvores do Tiny Swords: 1 e 2 são pinheiros (quadro 192x256), 3 e 4 árvores de copa
## (192x192). Cada uma tem o seu toco. `pe`: pixels entre a base do tronco e o fundo do quadro.
const ARVORES_TS := [[256, 15], [256, 15], [192, 22], [192, 22]]
## Plantas: os arbustos animados do Tiny Swords e, de vez em quando, o cogumelo azul (L02),
## que brilha à noite (ainda sem versão no estilo novo).
const ARBUSTO_PE := 49
const CHANCE_COGUMELO := 0.08
const COGUMELO_AZUL := 5
## Objetos do acampamento (L02), na ordem da folha.
enum Acamp { BARRACA, FOGUEIRA, BAU, BARRIL, BANCADA, VARAL }
## Raio sem árvores em volta da fogueira.
const RAIO_CLAREIRA := 120.0
const COR_DIA := Color(1, 1, 1)
const COR_NOITE := Color(0.24, 0.27, 0.46)

enum Chao { AGUA, AREIA, GRAMA }

@export var largura := 64
@export var altura := 44
@export var semente := 22117
@export var arvores := 70
@export var pedras := 16
@export var plantas := 110
@export var slimes := 5
## Falso nos testes que precisam de terreno limpo (sem árvores e pedras geradas).
@export var gerar_recursos := true
## Quanto tempo a água fica congelada pela lança de gelo.
@export var duracao_gelo := 10.0
## Arquivo do mundo salvo (vazio = não salva nem carrega; os testes usam isso).
@export var arquivo_salvo := Salvamento.PADRAO
## Salvamento automático a cada tantos segundos (anfitrião).
@export var intervalo_salvar := 60.0

const MENU := "res://scenes/ui/menu.tscn"

## Só para os testes de rede: o outro jogo manda o que viu.
signal relatorio_recebido(peer: int, dados: Dictionary)

## O jogador controlado nesta máquina.
var jogador: Player
var noite := false
var centro := Vector2.ZERO
var _tipo: Dictionary[Vector2i, int] = {}
var _distancia: Dictionary[Vector2i, float] = {}
var _ocupados: Array[Vector2] = []
var _removidos: Array[String] = []
var _nascimentos: Dictionary[int, Vector2] = {}
var _retornos: Dictionary[int, Vector2] = {}
# Progresso salvo: id do jogador → registro; e quem é quem nesta partida.
var _registros: Dictionary = {}
var _id_por_peer: Dictionary[int, String] = {}
var _restaurar_depois: Dictionary[int, Dictionary] = {}
var _tempo_salvar := 0.0
var _gelo: Dictionary[Vector2i, float] = {}  # célula congelada → segundos restantes
var _id_agua := -1  # fonte do gelo
var _id_chao := -1
var _rng := RandomNumberGenerator.new()
var _bosque := FastNoiseLite.new()  # onde ficam os bosques

@onready var chao: TileMapLayer = $Chao
@onready var entidades: Node2D = $Entidades
@onready var ambiente: CanvasModulate = $Ambiente
@onready var hud: Hud = $HUD


func _ready() -> void:
	add_to_group(&"mundo")
	_rng.seed = semente
	centro = Vector2(largura / 2 * T + T / 2, altura / 2 * T + T / 2)
	# O cenário nasce igual em todos os jogadores (mesma semente, mesmos nomes).
	_gerar_chao()
	_montar_acampamento()
	_espalhar()
	_aplicar_ciclo(false, true)

	if Net.iniciar() != OK:
		_voltar_ao_menu.call_deferred()
		return
	multiplayer.peer_disconnected.connect(_on_peer_saiu)
	multiplayer.connected_to_server.connect(func() -> void: _cliente_pronto.rpc_id(1, Net.raca, Net.classe, Net.id_jogador))
	multiplayer.connection_failed.connect(_on_conexao_perdida.bind("Não foi possível conectar ao anfitrião."))
	multiplayer.server_disconnected.connect(_on_conexao_perdida.bind("O anfitrião saiu do jogo."))
	if multiplayer.is_server():
		_carregar_mundo()
		_criar_slimes()
		if Net.modo != Net.Modo.ENTRAR:
			_criar_jogador(1, Net.raca, Net.classe, Net.id_jogador)
	else:
		Events.aviso.emit("Conectando em %s..." % Net.endereco)
	Sfx.tocar_musica()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"alternar_noite"):
		alternar_noite()


## Qualquer jogador pode pedir; o anfitrião troca para todos.
func alternar_noite() -> void:
	_pedir_ciclo.rpc_id(1)


## O Player local chama isto ao nascer nesta máquina.
func registrar_jogador_local(p: Player) -> void:
	jogador = p
	p.ponto_de_retorno = _retornos.get(p.id_rede(), p.position)
	if not multiplayer.is_server():
		# O jogador controlado aqui não aceita a posição enviada no nascimento
		# (quem manda nele é este jogo), então pergunta ao anfitrião onde nascer.
		_pedir_nascimento.rpc_id(1)
	p.camera.limit_left = 0
	p.camera.limit_top = 0
	p.camera.limit_right = largura * T
	p.camera.limit_bottom = altura * T
	p.camera.reset_smoothing()
	hud.configurar(p)
	if multiplayer.is_server() and Net.modo == Net.Modo.HOSPEDAR:
		var ips := ", ".join(Net.enderecos_locais())
		Events.aviso.emit("Você é o anfitrião. Seus amigos entram pelo IP: %s" % (ips if ips != "" else "?"))
	else:
		Events.aviso.emit("Explore a clareira: segure E nas árvores e pedras.")


func ponto_de_nascer(indice: int) -> Vector2:  # abaixo da fogueira, sem encostar nela
	return centro + Vector2(30 * indice, 46)


func registrar_removido(nome: String) -> void:
	_removidos.append(nome)


## Efeito visual em todos os jogadores (chamado pelo anfitrião).
static func efeito_todos(quem: Node, nome: StringName, pos: Vector2) -> void:
	var w: World = quem.get_tree().get_first_node_in_group(&"mundo")
	if w:
		w._efeito.rpc(nome, pos)


## Raio em que os jogadores dividem a experiência de uma derrota.
const RAIO_XP := 160.0


## Experiência para todos os jogadores perto (chamado pelo anfitrião).
static func dar_xp_em_volta(quem: Node, pos: Vector2, quantidade: int) -> void:
	for j in quem.get_tree().get_nodes_in_group(&"jogadores"):
		if (j as Player).global_position.distance_to(pos) <= RAIO_XP:
			(j as Player).ganhar_xp(quantidade)


## Congela a água neste ponto (chamado pelo anfitrião, ex.: lança de gelo passando).
static func congelar_agua_em(quem: Node, pos: Vector2) -> void:
	var w: World = quem.get_tree().get_first_node_in_group(&"mundo")
	if w == null or not w.multiplayer.is_server():
		return
	var cel := w.chao.local_to_map(pos)
	if w.tipo_do_chao(cel) == Chao.AGUA:
		if not w._gelo.has(cel):
			w._definir_gelo.rpc(cel, true)
		w._gelo[cel] = w.duracao_gelo


func eh_gelo(cel: Vector2i) -> bool:
	return _gelo.has(cel)


func _process(delta: float) -> void:
	if not multiplayer.has_multiplayer_peer() or not multiplayer.is_server():
		return
	_process_salvar(delta)
	if _gelo.is_empty():
		return
	for cel in _gelo.keys():
		_gelo[cel] -= delta
		if _gelo[cel] <= 0.0:
			if _alguem_em(cel):
				_gelo[cel] = 0.5  # não derrete com alguém em cima
			else:
				_definir_gelo.rpc(cel, false)


func _alguem_em(cel: Vector2i) -> bool:
	for j in get_tree().get_nodes_in_group(&"jogadores"):
		if chao.local_to_map(j.global_position) == cel:
			return true
	return false


@rpc("any_peer", "call_local", "reliable")
func _definir_gelo(cel: Vector2i, congelado: bool) -> void:
	if not Net.veio_do_anfitriao():
		return
	if congelado:
		chao.set_cell(cel, _id_agua, GELO)
		if not _gelo.has(cel):
			_gelo[cel] = duracao_gelo
	else:
		_pintar(cel, Bloco.AGUA)
		_gelo.erase(cel)
	if congelado:
		_camada_gelo.set_cell(cel, 0, GELO)
	else:
		_camada_gelo.erase_cell(cel)


@rpc("any_peer", "call_local", "reliable")
func _efeito(nome: StringName, pos: Vector2) -> void:
	if Net.veio_do_anfitriao():
		entidades.add_child(Efeito.criar(nome, pos))


## Aviso para todos os jogadores (chamado pelo anfitrião).
static func avisar_todos(quem: Node, texto: String) -> void:
	var w: World = quem.get_tree().get_first_node_in_group(&"mundo")
	if w:
		w._aviso_global.rpc(texto)


# --- Rede ------------------------------------------------------------------------

func _criar_jogador(peer: int, raca: StringName, classe: StringName, id_jogador: String) -> void:
	var p: Player = JOGADOR.instantiate()
	p.name = str(peer)
	p.raca = raca if raca in RacaData.TODAS else RacaData.TODAS[0]
	p.classe = classe if classe in ClasseData.TODAS else ClasseData.TODAS[0]
	# Um personagem salvo por jogador + raça + classe. Duas janelas no mesmo PC com o
	# mesmo personagem: a segunda ganha um sufixo.
	var id := chave_personagem(id_jogador if id_jogador != "" else "anonimo", p.raca, p.classe)
	while id in _id_por_peer.values():
		id += "+"
	_id_por_peer[peer] = id
	var retorno := ponto_de_nascer(get_tree().get_nodes_in_group(&"jogadores").size())
	p.position = retorno
	# Personagem que já estava salvo: volta de onde parou.
	var reg: Dictionary = _registros.get(id, {})
	var mesmo := not reg.is_empty()
	if mesmo and reg.get("pos") is Array and reg["pos"].size() == 2:
		p.position = Vector2(reg["pos"][0], reg["pos"][1])
	_nascimentos[peer] = p.position
	_retornos[peer] = retorno
	entidades.add_child(p, true)
	if mesmo:
		if peer == multiplayer.get_unique_id():
			p.restaurar(reg)
			Events.aviso.emit("Bem-vindo de volta! Seu %s está no nível %d." % [p.ficha.titulo(), p.nivel])
		else:
			# Para os outros, só depois que o jogador já existe lá (ver _pedir_nascimento).
			_restaurar_depois[peer] = reg


@rpc("any_peer", "reliable")
func _pedir_nascimento() -> void:
	var peer := multiplayer.get_remote_sender_id()
	if not multiplayer.is_server() or not _nascimentos.has(peer):
		return
	_definir_nascimento.rpc_id(peer, _nascimentos[peer], _retornos.get(peer, _nascimentos[peer]))
	if _restaurar_depois.has(peer) and entidades.has_node(str(peer)):
		var p: Player = entidades.get_node(str(peer))
		p.restaurar(_restaurar_depois[peer])
		_restaurar_depois.erase(peer)
		p.avisar("Bem-vindo de volta! Seu %s está no nível %d." % [p.ficha.titulo(), p.nivel])


@rpc("any_peer", "reliable")
func _definir_nascimento(pos: Vector2, retorno: Vector2) -> void:
	if not Net.veio_do_anfitriao() or jogador == null:
		return
	jogador.global_position = pos
	jogador.ponto_de_retorno = retorno
	jogador.camera.reset_smoothing()


@rpc("any_peer", "reliable")
func _cliente_pronto(raca: StringName, classe: StringName, id_jogador: String) -> void:
	if not multiplayer.is_server():
		return
	var peer := multiplayer.get_remote_sender_id()
	if entidades.has_node(str(peer)):
		return
	_criar_jogador(peer, raca, classe, id_jogador)
	# Quem entra depois recebe o que já mudou no mundo.
	_aplicar_ciclo_rede.rpc_id(peer, noite, true)
	for cel in _gelo:
		_definir_gelo.rpc_id(peer, cel, true)
	if not _removidos.is_empty():
		_remover_recursos.rpc_id(peer, _removidos)
	for r in get_tree().get_nodes_in_group(&"recursos"):
		(r as ResourceNode).enviar_estado_para(peer)
	for j in get_tree().get_nodes_in_group(&"jogadores"):
		if j.name != str(peer):
			(j as Player).enviar_progresso_para(peer)
	World.avisar_todos(self, "Um amigo entrou na ilha!")


func _on_peer_saiu(peer: int) -> void:
	if multiplayer.is_server() and entidades.has_node(str(peer)):
		var p: Player = entidades.get_node(str(peer))
		if _id_por_peer.has(peer) and not _restaurar_depois.has(peer):
			_registros[_id_por_peer[peer]] = p.registro()
		_id_por_peer.erase(peer)
		p.queue_free()
		salvar()
		World.avisar_todos(self, "Um amigo saiu da ilha.")


# --- Salvar e carregar (só o anfitrião) ---------------------------------------------

static func chave_personagem(id_jogador: String, raca: StringName, classe: StringName) -> String:
	return "%s:%s:%s" % [id_jogador, raca, classe]


## O personagem salvo mais recente deste jogador (para o menu já vir escolhido).
static func ultimo_personagem(dados: Dictionary, id_jogador: String) -> Dictionary:
	var melhor := {}
	var jogadores: Dictionary = dados.get("jogadores", {})
	for chave in jogadores:
		if String(chave).begins_with(id_jogador + ":") and float(jogadores[chave].get("salvo_em", 0)) >= float(melhor.get("salvo_em", -1)):
			melhor = jogadores[chave]
	return melhor


## Grava o mundo e o progresso de todos. Retorna se gravou.
func salvar() -> bool:
	# Quem entrou no jogo de outro não grava nada: o mundo é do anfitrião.
	if not multiplayer.has_multiplayer_peer() or not multiplayer.is_server() or arquivo_salvo == "" or Net.modo == Net.Modo.ENTRAR:
		return false
	for peer in _id_por_peer:
		if entidades.has_node(str(peer)) and not _restaurar_depois.has(peer):
			_registros[_id_por_peer[peer]] = (entidades.get_node(str(peer)) as Player).registro()
	var recursos := {}
	for r in get_tree().get_nodes_in_group(&"recursos"):
		var rn := r as ResourceNode
		if rn.estado != ResourceNode.Estado.INTEIRO or rn.golpes_restantes() != rn.golpes:
			# Árvore queimando é salva como queimada (o fogo não volta aceso).
			var e := ResourceNode.Estado.QUEIMADO if rn.estado == ResourceNode.Estado.QUEIMANDO else rn.estado
			recursos[String(rn.name)] = [e, rn.golpes_restantes()]
	return Salvamento.gravar({
		"semente": semente, "noite": noite,
		"recursos": recursos, "removidos": _removidos.duplicate(),
		"jogadores": _registros,
	}, arquivo_salvo)


func _carregar_mundo() -> void:
	var dados := Salvamento.ler(arquivo_salvo)
	if dados.is_empty():
		return
	if int(dados.get("semente", semente)) != semente:
		push_warning("O mundo salvo é de outra semente; começando um novo.")
		return
	_registros = dados.get("jogadores", {})
	_aplicar_ciclo(bool(dados.get("noite", false)), true)
	for nome in dados.get("removidos", []):
		if entidades.has_node(NodePath(nome)):
			entidades.get_node(NodePath(nome)).free()
		_removidos.append(String(nome))
	var recursos: Dictionary = dados.get("recursos", {})
	for nome in recursos:
		var r := entidades.get_node_or_null(NodePath(nome)) as ResourceNode
		if r:
			r.carregar_estado(int(recursos[nome][0]), int(recursos[nome][1]))


func _process_salvar(delta: float) -> void:
	_tempo_salvar += delta
	if _tempo_salvar >= intervalo_salvar:
		_tempo_salvar = 0.0
		salvar()


## Ao fechar a janela o mundo ainda está inteiro. (No _exit_tree, não: o Godot tira os
## filhos primeiro e o mundo seria gravado sem árvores nem pedras.)
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		salvar()


func _on_conexao_perdida(motivo: String) -> void:
	Net.ultimo_erro = motivo
	_voltar_ao_menu()


func _voltar_ao_menu() -> void:
	salvar()
	Net.encerrar()
	if ResourceLoader.exists(MENU) and get_tree().current_scene == self:
		get_tree().change_scene_to_file(MENU)


@rpc("any_peer", "reliable")
func _remover_recursos(nomes: Array) -> void:
	if not Net.veio_do_anfitriao():
		return
	for n in nomes:
		if entidades.has_node(NodePath(n)):
			entidades.get_node(NodePath(n)).queue_free()


@rpc("any_peer", "call_local", "reliable")
func _aviso_global(texto: String) -> void:
	if Net.veio_do_anfitriao():
		Events.aviso.emit(texto)


@rpc("any_peer", "call_local", "reliable")
func _pedir_ciclo() -> void:
	if multiplayer.is_server():
		_aplicar_ciclo_rede.rpc(not noite, false)


@rpc("any_peer", "call_local", "reliable")
func _aplicar_ciclo_rede(para_noite: bool, imediato: bool) -> void:
	if Net.veio_do_anfitriao():
		_aplicar_ciclo(para_noite, imediato)


@rpc("any_peer", "reliable")
func relatorio_teste(dados: Dictionary) -> void:
	relatorio_recebido.emit(multiplayer.get_remote_sender_id(), dados)


func tipo_do_chao(celula: Vector2i) -> int:
	return _tipo.get(celula, Chao.AGUA)


# --- Geração ---------------------------------------------------------------

func _gerar_chao() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	# Chão novo (L02): 6 blocos de 32x32 lado a lado = 12x2 tiles de 16.
	var src_chao := TileSetAtlasSource.new()
	src_chao.texture = TEX_CHAO
	src_chao.texture_region_size = Vector2i(T, T)
	_id_chao = ts.add_source(src_chao)
	for y in 2:
		for x in 12:
			src_chao.create_tile(Vector2i(x, y))
	# A água não deixa passar.
	for y in 2:
		for x in 2:
			var dados := src_chao.get_tile_data(Vector2i(Bloco.AGUA * 2 + x, y), 0)
			dados.add_collision_polygon(0)
			dados.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]))
	# Gelo da lança de gelo (ainda o placeholder do Ninja Adventure).
	var src_gelo := TileSetAtlasSource.new()
	src_gelo.texture = TEX_AGUA
	src_gelo.texture_region_size = Vector2i(T, T)
	_id_agua = ts.add_source(src_gelo)
	src_gelo.create_tile(GELO)
	chao.tile_set = ts

	var ruido := FastNoiseLite.new()
	ruido.seed = semente
	ruido.frequency = 0.08
	var c := Vector2i(largura / 2, altura / 2)
	for y in altura:
		for x in largura:
			var cel := Vector2i(x, y)
			var nx := (x - largura / 2.0) / (largura * 0.44)
			var ny := (y - altura / 2.0) / (altura * 0.42)
			var d := sqrt(nx * nx + ny * ny) + ruido.get_noise_2d(x, y) * 0.16
			_distancia[cel] = d
			if d > 1.0:
				_tipo[cel] = Chao.AGUA
				_pintar(cel, Bloco.AGUA)
			elif d > 0.87:
				_tipo[cel] = Chao.AREIA
				_pintar(cel, Bloco.AREIA)
			else:
				_tipo[cel] = Chao.GRAMA
				if Vector2(cel - c).length() <= 2.6:
					_pintar(cel, Bloco.TERRA)  # clareira de terra em volta da fogueira
					_terra[cel] = true
				elif _bloco_com_flores(cel):
					_pintar(cel, Bloco.GRAMA_FLORES)
				else:
					_pintar(cel, Bloco.GRAMA)
	_montar_terreno()


# --- Terreno no estilo Tiny Swords ------------------------------------------------
## A camada de tiles (Chao) fica invisível: só serve para a colisão da água e para saber o
## chão de cada tile. Quem desenha é o Terreno, com a arte do Tiny Swords (tile de 64 px,
## escala 0,25): água lisa no fundo, espuma animada embaixo da beira, a ilha inteira em
## grama oliva (no lugar da areia, que o pacote não tem) e a grama por cima. Cada camada
## escolhe o tile pelos 4 vizinhos: o terreno deles tem as 16 combinações (bloco 3x3,
## tira vertical, tira horizontal e tile sozinho).
const TS := 64
const ESCALA_TS := 0.25
const TEX_TS_AGUA := preload("res://assets/tiny_swords/terreno/agua.png")
const TEX_TS_ESPUMA := preload("res://assets/tiny_swords/terreno/espuma.png")
const TEX_TS_AREIA := preload("res://assets/tiny_swords/terreno/grama_oliva.png")
const TEX_TS_GRAMA := preload("res://assets/tiny_swords/terreno/grama.png")

var _terra: Dictionary[Vector2i, bool] = {}
var _camada_gelo: TileMapLayer  # gelo da lança de gelo, por cima da água


func _montar_terreno() -> void:
	chao.visible = false
	var raiz := Node2D.new()
	raiz.name = "Terreno"
	raiz.scale = Vector2(ESCALA_TS, ESCALA_TS)
	add_child(raiz)
	move_child(raiz, chao.get_index() + 1)
	var agua := Sprite2D.new()
	agua.texture = TEX_TS_AGUA
	agua.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	agua.region_enabled = true
	agua.region_rect = Rect2(0, 0, (largura + 40) * TS, (altura + 40) * TS)
	agua.centered = false
	agua.position = Vector2(-20, -20) * TS
	raiz.add_child(agua)

	var terra := func(cel: Vector2i) -> bool: return tipo_do_chao(cel) != Chao.AGUA
	var grama := func(cel: Vector2i) -> bool: return tipo_do_chao(cel) == Chao.GRAMA and not _terra.has(cel)
	var espuma := SpriteFrames.new()
	espuma.remove_animation(&"default")
	SpriteSheets.adicionar_tira(espuma, TEX_TS_ESPUMA, &"onda", Vector2i(192, 192), 16, 10.0)
	for cel in _tipo:
		if terra.call(cel) and _vizinhos(cel, terra) != 15:
			var a := AnimatedSprite2D.new()
			a.sprite_frames = espuma
			a.play(&"onda")
			a.frame = (cel.x * 7 + cel.y * 3) % 16
			a.position = Vector2(cel * TS) + Vector2(TS, TS) / 2.0
			raiz.add_child(a)
	raiz.add_child(_camada_ts(TEX_TS_AREIA, terra))
	raiz.add_child(_camada_ts(TEX_TS_GRAMA, grama))

	# O gelo ainda é o tile provisório do Ninja Adventure, no tamanho do nosso tile.
	_camada_gelo = TileMapLayer.new()
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	var src := TileSetAtlasSource.new()
	src.texture = TEX_AGUA
	src.texture_region_size = Vector2i(T, T)
	ts.add_source(src, 0)
	src.create_tile(GELO)
	_camada_gelo.tile_set = ts
	add_child(_camada_gelo)
	move_child(_camada_gelo, raiz.get_index() + 1)


func _camada_ts(textura: Texture2D, e_desta: Callable) -> TileMapLayer:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TS, TS)
	var src := TileSetAtlasSource.new()
	src.texture = textura
	src.texture_region_size = Vector2i(TS, TS)
	ts.add_source(src, 0)
	for y in 4:
		for x in 4:
			src.create_tile(Vector2i(x, y))
	var camada := TileMapLayer.new()
	camada.tile_set = ts
	for cel in _tipo:
		if e_desta.call(cel):
			camada.set_cell(cel, 0, _tile_ts(_vizinhos(cel, e_desta)))
	return camada


## Bits: 1 norte, 2 sul, 4 oeste, 8 leste (vizinho do mesmo terreno).
func _vizinhos(cel: Vector2i, e_desta: Callable) -> int:
	var n := 0
	if e_desta.call(cel + Vector2i.UP): n |= 1
	if e_desta.call(cel + Vector2i.DOWN): n |= 2
	if e_desta.call(cel + Vector2i.LEFT): n |= 4
	if e_desta.call(cel + Vector2i.RIGHT): n |= 8
	return n


## Coluna: 0 começa à esquerda, 1 meio, 2 termina à direita, 3 tira vertical (sem lados).
## Linha: 0 começa em cima, 1 meio, 2 termina embaixo, 3 tira horizontal (sem cima/baixo).
func _tile_ts(v: int) -> Vector2i:
	var oeste := v & 4 != 0
	var leste := v & 8 != 0
	var norte := v & 1 != 0
	var sul := v & 2 != 0
	var col := 1 if oeste and leste else (2 if oeste else (0 if leste else 3))
	var lin := 1 if norte and sul else (2 if norte else (0 if sul else 3))
	return Vector2i(col, lin)


## Blocos de flores salpicados (alinhados de 2 em 2 tiles para o bloco ficar inteiro).
## Usa a semente, então é igual em todos os jogadores.
func _bloco_com_flores(cel: Vector2i) -> bool:
	var b := Vector2i(floori(cel.x / 2.0), floori(cel.y / 2.0))
	return hash(Vector3i(b.x, b.y, semente)) % 100 < 7


## Pinta a célula com um bloco de 32x32, escolhendo o pedaço certo pela posição
## (assim o desenho continua de um tile para o outro).
func _pintar(cel: Vector2i, bloco: int, fonte := -1) -> void:
	chao.set_cell(cel, _id_chao if fonte < 0 else fonte, Vector2i(bloco * 2 + posmod(cel.x, 2), posmod(cel.y, 2)))


func _montar_acampamento() -> void:
	var fogueira := _objeto_acampamento(Acamp.FOGUEIRA, centro + Vector2(0, 12), Vector2.ZERO)
	var luz := PointLight2D.new()
	luz.texture = LUZ
	luz.color = Color(1, 0.55, 0.25)
	luz.energy = 0.8
	luz.texture_scale = 1.6
	luz.position = Vector2(0, -10)
	luz.add_to_group(&"luzes_noturnas")
	fogueira.add_child(luz)
	var t := luz.create_tween().set_loops()
	t.tween_property(luz, "energy", 0.65, 0.18)
	t.tween_property(luz, "energy", 0.85, 0.23)
	_objeto_acampamento(Acamp.BARRACA, centro + Vector2(-50, -16), Vector2(46, 12))
	_objeto_acampamento(Acamp.BANCADA, centro + Vector2(50, -16), Vector2(40, 10))
	_objeto_acampamento(Acamp.BAU, centro + Vector2(56, 18), Vector2(28, 10))
	_objeto_acampamento(Acamp.BARRIL, centro + Vector2(-44, 20), Vector2(18, 8))
	_objeto_acampamento(Acamp.VARAL, centro + Vector2(-90, 6), Vector2.ZERO)


## Um objeto do acampamento (sprite da folha L02). Com `colisao`, ninguém atravessa.
func _objeto_acampamento(qual: int, pos: Vector2, colisao: Vector2) -> Node2D:
	var regiao := Rect2(qual * 64, 0, 64, 64)
	_ocupados.append(pos)
	if colisao == Vector2.ZERO:
		return _sprite(TEX_ACAMPAMENTO, regiao, pos)
	var corpo := StaticBody2D.new()
	corpo.position = pos
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = colisao
	forma.shape = ret
	forma.position = Vector2(0, -colisao.y / 2.0 - 2.0)
	corpo.add_child(forma)
	entidades.add_child(corpo)
	_sprite(TEX_ACAMPAMENTO, regiao, Vector2.ZERO, corpo)
	return corpo


func _espalhar() -> void:
	var celulas_grama: Array[Vector2i] = []
	for cel in _tipo:
		if _tipo[cel] == Chao.GRAMA and _distancia[cel] < 0.82:
			celulas_grama.append(cel)

	_bosque.seed = semente + 3
	_bosque.frequency = 0.07
	var colocadas := 0
	for i in arvores * 6:
		if colocadas >= arvores:
			break
		var p := _ponto_em(celulas_grama)
		# Árvores em bosques (manchas de ruído), deixando campos abertos entre eles.
		var cel_arvore := Vector2i(p / T)
		if p.distance_to(centro) > RAIO_CLAREIRA and _bosque.get_noise_2d(cel_arvore.x, cel_arvore.y) > 0.0 and _livre(p, 30.0):
			var tipo := _rng.randi() % ARVORES_TS.size()
			_ocupados.append(p)
			colocadas += 1
			if gerar_recursos:
				var a: ResourceNode = ARVORE.instantiate()
				a.name = "Arvore%d" % colocadas
				var quadro := Vector2(192, ARVORES_TS[tipo][0])
				a.textura_inteiro = load("res://assets/tiny_swords/natureza/arvore%d.png" % (tipo + 1))
				a.textura_esgotado = load("res://assets/tiny_swords/natureza/toco%d.png" % (tipo + 1))
				a.regiao_inteiro = Rect2(Vector2.ZERO, quadro)
				a.regiao_queimado = Rect2(Vector2.ZERO, quadro)
				a.pe = ARVORES_TS[tipo][1]
				a.position = p
				entidades.add_child(a)

	colocadas = 0
	for i in pedras * 8:
		if colocadas >= pedras:
			break
		var p := _ponto_em(celulas_grama)
		if p.distance_to(centro) > 70.0 and _livre(p, 26.0):
			var tipo := _rng.randi() % 4
			_ocupados.append(p)
			colocadas += 1
			if gerar_recursos:
				var pd: ResourceNode = PEDRA.instantiate()
				pd.name = "Pedra%d" % colocadas
				pd.textura_inteiro = load("res://assets/tiny_swords/natureza/pedra%d.png" % (tipo + 1))
				pd.position = p
				entidades.add_child(pd)

	var arbustos: Array[SpriteFrames] = []
	for k in 4:
		var f := SpriteFrames.new()
		f.remove_animation(&"default")
		SpriteSheets.adicionar_tira(f, load("res://assets/tiny_swords/natureza/arbusto%d.png" % (k + 1)), &"vento", Vector2i(128, 128), 8, 8.0)
		arbustos.append(f)
	for i in plantas:
		var p := _ponto_em(celulas_grama)
		if p.distance_to(centro) > 100.0 and _livre(p, 14.0):
			_ocupados.append(p)
			if _rng.randf() < CHANCE_COGUMELO:
				# O cogumelo azul brilha à noite (conceito A).
				var s := _sprite(TEX_PLANTAS, Rect2(COGUMELO_AZUL * 32, 0, 32, 32), p)
				var luz := PointLight2D.new()
				luz.texture = LUZ
				luz.color = Color(0.3, 0.95, 0.9)
				luz.energy = 0.7
				luz.texture_scale = 0.35
				luz.position = Vector2(0, -6)
				luz.add_to_group(&"luzes_noturnas")
				s.add_child(luz)
			else:
				var a := AnimatedSprite2D.new()
				a.sprite_frames = arbustos[_rng.randi() % arbustos.size()]
				a.play(&"vento")
				a.frame = _rng.randi() % 8
				a.centered = false
				a.offset = Vector2(-64, -128 + ARBUSTO_PE)
				a.scale = Vector2(ESCALA_TS, ESCALA_TS)
				a.position = p
				entidades.add_child(a)


## Só o anfitrião cria os slimes; o MultiplayerSpawner copia para os outros.
func _criar_slimes() -> void:
	var celulas_grama: Array[Vector2i] = []
	for cel in _tipo:
		if _tipo[cel] == Chao.GRAMA and _distancia[cel] < 0.82:
			celulas_grama.append(cel)
	var colocadas := 0
	for i in slimes * 20:
		if colocadas >= slimes:
			break
		var p := _ponto_em(celulas_grama)
		if p.distance_to(centro) > 150.0 and _livre(p, 14.0):
			colocadas += 1
			var s: Slime = SLIME.instantiate()
			s.name = "Slime%d" % colocadas
			s.position = p
			entidades.add_child(s, true)


func _ponto_em(celulas: Array[Vector2i]) -> Vector2:
	var cel := celulas[_rng.randi() % celulas.size()]
	return Vector2(cel * T) + Vector2(_rng.randf_range(2, 14), _rng.randf_range(6, 15))


func _livre(p: Vector2, raio: float) -> bool:
	for o in _ocupados:
		if o.distance_to(p) < raio:
			return false
	return true


func _sprite(textura: Texture2D, regiao: Rect2, pos: Vector2, pai: Node = null) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = textura
	s.region_enabled = true
	s.region_rect = regiao
	s.centered = false
	s.offset = Vector2(-regiao.size.x / 2.0, -regiao.size.y)
	s.position = pos
	(pai if pai else entidades).add_child(s)
	return s


# --- Dia e noite -------------------------------------------------------------

func _aplicar_ciclo(para_noite: bool, imediato: bool) -> void:
	noite = para_noite
	var cor := COR_NOITE if noite else COR_DIA
	if imediato:
		ambiente.color = cor
	else:
		create_tween().tween_property(ambiente, "color", cor, 1.2)
	for luz in get_tree().get_nodes_in_group(&"luzes_noturnas"):
		(luz as PointLight2D).enabled = noite
	if not imediato:
		Events.aviso.emit("A noite caiu. Fique perto da fogueira." if noite else "Amanheceu.")
