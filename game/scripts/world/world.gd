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
const ATIRADOR := preload("res://scenes/enemies/atirador.tscn")
const JOGADOR := preload("res://scenes/player/player.tscn")
const ITEM_CHAO := preload("res://scenes/world/item_chao.tscn")
## Nossas peças no estilo Tiny Swords (L14): acampamento e pedras/criaturas, quadros de
## 128x128 no MESMO pixel do pacote (escala 0,25 como as peças dele), base 8 px acima do fundo.
const TEX_ACAMPAMENTO := preload("res://assets/sprites/tiny/acampamento.png")
const TEX_NATUREZA := preload("res://assets/sprites/tiny/pedras_slime.png")
const QUADRO_NOSSO := 128
const PE_NOSSO := 8
const LUZ := preload("res://assets/luz/luz_radial.tres")

const T := 16
## Camada invisível de colisão (Chao): só dois tiles, chão (anda; também o gelo) e água (bloqueia).
const TILE_CHAO := Vector2i(0, 0)
const TILE_AGUA := Vector2i(1, 0)
## Árvores do Tiny Swords: 1 e 2 são pinheiros (quadro 192x256), 3 e 4 árvores de copa
## (192x192). Cada uma tem o seu toco. `pe`: pixels entre a base do tronco e o fundo do quadro.
const ARVORES_TS := [[256, 15], [256, 15], [192, 22], [192, 22]]
## Plantas: os arbustos animados do Tiny Swords e, de vez em quando, o cogumelo azul (L02),
## que brilha à noite (ainda sem versão no estilo novo).
const ARBUSTO_PE := 49
const CHANCE_COGUMELO := 0.08
const COGUMELO_AZUL := 3  # quadro na folha de pedras e criaturas
## Objetos do acampamento (L14), na ordem da folha.
enum Acamp { FOGUEIRA, BARRACA, BAU, BARRIL, BANCADA, VARAL }
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
## Acampamentos de arqueiros inimigos (2 em cada), longe da fogueira. Os testes usam 0.
@export var grupos_atiradores := 2
## Baús trancados espalhados longe da fogueira (só com gerar_recursos).
@export var baus_trancados := 3
## Falso nos testes que precisam de terreno limpo (sem árvores e pedras geradas).
@export var gerar_recursos := true
## Quanto tempo a água fica congelada pela lança de gelo.
@export var duracao_gelo := 10.0
## Arquivo do mundo salvo (vazio = não salva nem carrega; os testes usam isso).
@export var arquivo_salvo := Salvamento.PADRAO
## Salvamento automático a cada tantos segundos (anfitrião).
@export var intervalo_salvar := 60.0
## Só o cenário (chão, árvores, acampamento), sem rede, jogador, bichos nem HUD: é o fundo
## vivo da Home.
@export var somente_cenario := false

const MENU := "res://scenes/ui/menu.tscn"

## Só para os testes de rede: o outro jogo manda o que viu.
signal relatorio_recebido(peer: int, dados: Dictionary)

## O jogador controlado nesta máquina.
var jogador: Player
var noite := false
## Dificuldade do mundo (a tela de criação define).
var dificuldade := 1  # 0 fácil, 1 normal, 2 difícil
## Nome do mundo (o que o jogador escolheu ao criar), para salvar junto.
var nome_mundo := ""
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
var _ident_por_peer: Dictionary[int, String] = {}  # identidade do jogador entre sessões
var _pular_por_peer: Dictionary[int, bool] = {}  # entrou com personagem pronto (sem criação)
var _tempo_salvar := 0.0
var _contador_itens := 0
var _gelo: Dictionary[Vector2i, float] = {}  # célula congelada → segundos restantes
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
	if somente_cenario:
		arquivo_salvo = ""
		hud.visible = false
		return
	# O mundo escolhido no menu (se o teste ou o atalho não indicou outro arquivo).
	if Net.mundo_arquivo != "" and arquivo_salvo == Salvamento.PADRAO:
		arquivo_salvo = Net.mundo_arquivo
		# Vale o que o menu escolheu; se o arquivo já tem nome e dificuldade, eles ganham (ver _carregar_mundo).
		dificuldade = Net.mundo_dificuldade
		nome_mundo = Net.mundo_nome

	if Net.iniciar() != OK:
		_voltar_ao_menu.call_deferred()
		return
	# Esc: menu de pausa. Fica como primeiro filho, para receber o Esc depois do HUD (que
	# usa o Esc para fechar a mochila e a janelinha das habilidades).
	var pausa := Pausa.new(self)
	add_child(pausa)
	move_child(pausa, 0)
	multiplayer.peer_disconnected.connect(_on_peer_saiu)
	multiplayer.connected_to_server.connect(func() -> void: _cliente_pronto.rpc_id(1, Net.raca, Net.classe, Net.id_jogador, Net.pular_criacao))
	multiplayer.connection_failed.connect(_on_conexao_perdida.bind("Não foi possível conectar ao anfitrião."))
	multiplayer.server_disconnected.connect(_on_conexao_perdida.bind("O anfitrião saiu do jogo."))
	if multiplayer.is_server():
		_carregar_mundo()
		_criar_slimes()
		_criar_animais()
		_criar_atiradores()
		if Net.modo != Net.Modo.ENTRAR:
			_criar_jogador(1, Net.raca, Net.classe, Net.id_jogador, Net.pular_criacao)
	else:
		Events.aviso.emit("Conectando em %s..." % Net.endereco)
	Sfx.tocar_musica()


func _unhandled_input(event: InputEvent) -> void:
	if somente_cenario:
		return
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
		Events.aviso.emit("Explore a clareira: segure o clique nas árvores e pedras.")


func ponto_de_nascer(indice: int) -> Vector2:  # abaixo da fogueira, sem encostar nela
	return centro + Vector2(30 * indice, 46)


func registrar_removido(nome: String) -> void:
	_removidos.append(nome)


## Multiplicadores da dificuldade (fácil, normal, difícil): o dano que slime e javali causam
## (&"dano_inimigo") e a vida máxima de slimes e animais (&"vida_inimigo").
const MULT_DIFICULDADE := {
	&"dano_inimigo": [0.6, 1.0, 1.5],
	&"vida_inimigo": [0.8, 1.0, 1.3],
}


## Multiplicador da dificuldade do mundo para `tipo`; 1,0 se não houver mundo.
static func mult_dificuldade(quem: Node, tipo: StringName) -> float:
	if not quem.is_inside_tree() or not MULT_DIFICULDADE.has(tipo):
		return 1.0
	var w: World = quem.get_tree().get_first_node_in_group(&"mundo")
	if w == null:
		return 1.0
	var tabela: Array = MULT_DIFICULDADE[tipo]
	return float(tabela[clampi(w.dificuldade, 0, tabela.size() - 1)])


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


## Solta itens no chão ao redor de `pos` (chamado pelo anfitrião): `itens` é uma lista de
## [id, quantidade]; cada pilha vira uma ItemChao que salta para um ponto perto (até 12 px).
static func soltar_itens(quem: Node, pos: Vector2, itens: Array) -> void:
	var w: World = quem.get_tree().get_first_node_in_group(&"mundo")
	if w == null or not w.multiplayer.is_server():
		return
	for e in itens:
		var id := StringName(e[0])
		var resto := int(e[1])
		if not ItemData.existe(id):
			continue
		var pilha := maxi(1, ItemData.carregar(id).pilha)
		while resto > 0:
			var n := mini(resto, pilha)
			resto -= n
			w._contador_itens += 1
			var i: ItemChao = ITEM_CHAO.instantiate()
			i.name = "ItemChao%d" % w._contador_itens
			i.item = id
			i.quantidade = n
			i.origem = pos
			i.position = pos + Vector2.from_angle(randf() * TAU) * randf_range(4.0, 12.0)
			w.entidades.add_child(i, true)


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
	if somente_cenario:
		return
	if not multiplayer.has_multiplayer_peer() or not multiplayer.is_server():
		return
	_process_salvar(delta)
	_process_noite(delta)
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
		chao.set_cell(cel, 0, TILE_CHAO)  # gelo: dá para andar
		_camada_gelo.set_cell(cel, 0, Vector2i.ZERO)
		if not _gelo.has(cel):
			_gelo[cel] = duracao_gelo
	else:
		chao.set_cell(cel, 0, TILE_AGUA)
		_camada_gelo.erase_cell(cel)
		_gelo.erase(cel)


@rpc("any_peer", "call_local", "reliable")
func _efeito(nome: StringName, pos: Vector2) -> void:
	if Net.veio_do_anfitriao():
		entidades.add_child(Efeito.criar(nome, pos))


## Efeito em laço preso a alguém (o escudo do Bloqueio), em todos os jogadores.
static func efeito_preso_todos(quem: Node2D, nome: StringName, segundos: float, pos_local := Vector2.ZERO) -> void:
	var w: World = quem.get_tree().get_first_node_in_group(&"mundo")
	if w:
		w._efeito_preso.rpc(w.get_path_to(quem), nome, segundos, pos_local)


@rpc("any_peer", "call_local", "reliable")
func _efeito_preso(caminho: NodePath, nome: StringName, segundos: float, pos_local: Vector2) -> void:
	var dono := get_node_or_null(caminho)
	if not Net.veio_do_anfitriao() or dono == null:
		return
	var e := Efeito.criar(nome, pos_local, true)
	e.name = String(nome)  # a marca do alvo some enquanto a caveira (marca_morte) estiver lá
	dono.add_child(e, true)
	# Ligado ao método (sem lambda): se o efeito sair antes (o dono sumiu), a ligação cai sozinha.
	get_tree().create_timer(segundos, false).timeout.connect(e.sumir.bind(Efeito.SUMIR))


## Efeito em laço parado num ponto do chão por `segundos` (zonas: Círculo de cura, Nuvem
## tóxica...), em todos os jogadores. `escala` multiplica o tamanho da tabela do Efeito;
## `rotacao` gira o desenho (a Fenda e a Barreira seguem a direção da mira). `dono`: quem
## pode tirá-lo antes da hora (tirar_laco_todos; ex.: a Nuvem tóxica que explodiu).
static func efeito_laco_todos(quem: Node, nome: StringName, pos: Vector2, segundos: float, escala := 1.0, rotacao := 0.0, dono: Node = null) -> void:
	var w: World = quem.get_tree().get_first_node_in_group(&"mundo")
	if w:
		w._efeito_laco.rpc(nome, pos, segundos, escala, rotacao, dono.get_instance_id() if dono else 0)


## Tira antes da hora os efeitos em laço de `dono` (passado em efeito_laco_todos).
static func tirar_laco_todos(dono: Node) -> void:
	var w: World = dono.get_tree().get_first_node_in_group(&"mundo")
	if w:
		w._tirar_laco.rpc(dono.get_instance_id())


## Efeitos em laço que podem sair antes da hora: id do dono (no anfitrião) → [Efeito].
var _lacos: Dictionary = {}


@rpc("any_peer", "call_local", "reliable")
func _efeito_laco(nome: StringName, pos: Vector2, segundos: float, escala: float, rotacao: float, dono_id: int) -> void:
	if not Net.veio_do_anfitriao():
		return
	var e := Efeito.criar(nome, pos, true)
	e.rotation = rotacao
	if Efeito.PECAS.has(nome):
		e.ajustar_escala(escala)
	else:
		e.scale *= escala
		e.z_index = 0  # no chão, embaixo de quem pisa
	entidades.add_child(e)
	if dono_id != 0:
		var lista: Array = _lacos.get_or_add(dono_id, [])
		lista.append(e)
		get_tree().create_timer(segundos, false).timeout.connect(_esquecer_laco.bind(dono_id))
	get_tree().create_timer(segundos, false).timeout.connect(e.sumir.bind(Efeito.SUMIR))


func _esquecer_laco(dono_id: int) -> void:
	_lacos.erase(dono_id)


@rpc("any_peer", "call_local", "reliable")
func _tirar_laco(dono_id: int) -> void:
	if not Net.veio_do_anfitriao():
		return
	for e in _lacos.get(dono_id, []):
		if is_instance_valid(e):
			(e as Efeito).sumir()
	_lacos.erase(dono_id)


## Peça que anda de `de` até `ate` em `ida` segundos, em todos os jogadores (o Tornado de
## fogo, a Pedra viva, o meteoro caindo, a Forma de relâmpago). Fica `fica` segundos a mais
## parada no fim e some aos poucos; ao chegar, toca o efeito `ao_chegar` (vazio = nenhum).
static func efeito_movel_todos(quem: Node, nome: StringName, de: Vector2, ate: Vector2, ida: float, fica := 0.0, ao_chegar: StringName = &"", escala := 1.0) -> void:
	var w: World = quem.get_tree().get_first_node_in_group(&"mundo")
	if w:
		w._efeito_movel.rpc(nome, de, ate, ida, fica, ao_chegar, escala)


@rpc("any_peer", "call_local", "reliable")
func _efeito_movel(nome: StringName, de: Vector2, ate: Vector2, ida: float, fica: float, ao_chegar: StringName, escala: float) -> void:
	if not Net.veio_do_anfitriao():
		return
	var e := Efeito.criar(nome, de, true)
	if Efeito.PECAS.has(nome):
		e.ajustar_escala(escala)
	else:
		e.scale *= escala
	entidades.add_child(e)
	var t := e.create_tween()
	t.tween_property(e, "position", ate, maxf(ida, 0.01))
	t.tween_callback(func() -> void:
		e.centro = ate
		if ao_chegar != &"":
			entidades.add_child(Efeito.criar(ao_chegar, ate)))
	t.tween_interval(fica)
	t.tween_callback(e.sumir)


## Chuva de flechas: as flechas do pacote caem do céu em volta do ponto e chegam ao chão
## em `queda` segundos (quando o dano acontece). Só visual, em todos os jogadores.
const FLECHA_CAINDO := preload("res://assets/tiny_swords/fx/flecha.png")


static func chuva_de_flechas_todos(quem: Node, ponto: Vector2, raio: float, flechas: int, queda: float) -> void:
	var w: World = quem.get_tree().get_first_node_in_group(&"mundo")
	if w:
		w._chuva_de_flechas.rpc(ponto, raio, flechas, queda)


@rpc("any_peer", "call_local", "reliable")
func _chuva_de_flechas(ponto: Vector2, raio: float, flechas: int, queda: float) -> void:
	if not Net.veio_do_anfitriao():
		return
	for i in flechas:
		var chao := ponto + Vector2.from_angle(TAU * i / flechas + randf() * 0.6) * raio * randf_range(0.2, 0.8)
		var f := Sprite2D.new()
		f.texture = FLECHA_CAINDO
		f.scale = Vector2(0.25, 0.25)
		f.rotation = PI / 2.0  # a flecha do pacote aponta para a direita: aqui, para baixo
		f.position = chao + Vector2(0, -70)
		f.z_index = 2
		entidades.add_child(f)
		var atraso := randf() * queda * 0.3
		var t := f.create_tween()
		t.tween_interval(atraso)
		t.tween_property(f, "position", chao, queda - atraso).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		t.tween_callback(func() -> void:
			entidades.add_child(Efeito.criar(&"poeira", chao))
			f.queue_free())


## Aviso para todos os jogadores (chamado pelo anfitrião).
static func avisar_todos(quem: Node, texto: String) -> void:
	var w: World = quem.get_tree().get_first_node_in_group(&"mundo")
	if w:
		w._aviso_global.rpc(texto)


# --- Rede ------------------------------------------------------------------------

## `pular_criacao`: quem entra já traz raça e classe (testes e linha de comando): o personagem
## é o salvo dessa raça e classe, ou um novo criado direto. Sem isso, o personagem é o salvo
## mais recente do jogador neste mundo; se não houver, ele passa pela tela de criação.
func _criar_jogador(peer: int, raca: StringName, classe: StringName, id_jogador: String, pular_criacao := true) -> void:
	var p: Player = JOGADOR.instantiate()
	p.name = str(peer)
	p.raca = raca if raca in RacaData.TODAS else RacaData.TODAS[0]
	p.classe = classe if classe in ClasseData.TODAS else ClasseData.TODAS[0]
	var ident := id_jogador if id_jogador != "" else "anonimo"
	_ident_por_peer[peer] = ident
	_pular_por_peer[peer] = pular_criacao
	var id := "" if pular_criacao else _chave_salva_livre(ident)
	if id != "":
		var salvo: Dictionary = _registros[id]
		p.raca = StringName(salvo.get("raca", p.raca)) if StringName(salvo.get("raca", "")) in RacaData.TODAS else p.raca
		p.classe = StringName(salvo.get("classe", p.classe)) if StringName(salvo.get("classe", "")) in ClasseData.TODAS else p.classe
	else:
		# Um personagem salvo por jogador + raça + classe. Duas janelas no mesmo PC com o
		# mesmo personagem: a segunda ganha um sufixo.
		id = chave_personagem(ident, p.raca, p.classe)
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
	# Personagem novo também passa por restaurar (com registro vazio): ganha a arma da classe.
	if peer == multiplayer.get_unique_id():
		p.restaurar(reg, pular_criacao)
		if mesmo:
			Events.aviso.emit("Bem-vindo de volta! Seu %s está no nível %d." % [p.ficha.titulo(), p.nivel])
	else:
		# Para os outros, só depois que o jogador já existe lá (ver _pedir_nascimento).
		_restaurar_depois[peer] = reg


## A chave do personagem salvo mais recente deste jogador que ninguém está usando agora.
func _chave_salva_livre(ident: String) -> String:
	var melhor := ""
	var quando := -1.0
	for chave in _registros:
		var salvo_em := float(_registros[chave].get("salvo_em", 0))
		if String(chave).begins_with(ident + ":") and not chave in _id_por_peer.values() and salvo_em >= quando:
			melhor = chave
			quando = salvo_em
	return melhor


## O personagem acabou de ser criado (raça e classe escolhidas): a chave dele no arquivo passa
## a ser a da raça e classe escolhidas.
func personagem_criado(p: Player) -> void:
	var peer := p.id_rede()
	if not _id_por_peer.has(peer):
		return
	_id_por_peer.erase(peer)
	var id := chave_personagem(_ident_por_peer.get(peer, "anonimo"), p.raca, p.classe)
	while id in _id_por_peer.values():
		id += "+"
	_id_por_peer[peer] = id


@rpc("any_peer", "reliable")
func _pedir_nascimento() -> void:
	var peer := multiplayer.get_remote_sender_id()
	if not multiplayer.is_server() or not _nascimentos.has(peer):
		return
	_definir_nascimento.rpc_id(peer, _nascimentos[peer], _retornos.get(peer, _nascimentos[peer]))
	if _restaurar_depois.has(peer) and entidades.has_node(str(peer)):
		var p: Player = entidades.get_node(str(peer))
		p.inventario.fechar_bau_servidor()  # o que estava no baú aberto fica no baú
		var reg: Dictionary = _restaurar_depois[peer]
		p.restaurar(reg, _pular_por_peer.get(peer, true))
		_restaurar_depois.erase(peer)
		if not reg.is_empty():
			p.avisar("Bem-vindo de volta! Seu %s está no nível %d." % [p.ficha.titulo(), p.nivel])


@rpc("any_peer", "reliable")
func _definir_nascimento(pos: Vector2, retorno: Vector2) -> void:
	if not Net.veio_do_anfitriao() or jogador == null:
		return
	jogador.global_position = pos
	jogador.ponto_de_retorno = retorno
	jogador.camera.reset_smoothing()


@rpc("any_peer", "reliable")
func _cliente_pronto(raca: StringName, classe: StringName, id_jogador: String, pular_criacao: bool) -> void:
	if not multiplayer.is_server():
		return
	var peer := multiplayer.get_remote_sender_id()
	if entidades.has_node(str(peer)):
		return
	_criar_jogador(peer, raca, classe, id_jogador, pular_criacao)
	# Quem entra depois recebe o que já mudou no mundo.
	_aplicar_ciclo_rede.rpc_id(peer, noite, true)
	for cel in _gelo:
		_definir_gelo.rpc_id(peer, cel, true)
	if not _removidos.is_empty():
		_remover_recursos.rpc_id(peer, _removidos)
	for r in get_tree().get_nodes_in_group(&"recursos"):
		(r as ResourceNode).enviar_estado_para(peer)
	for c in _lista_construcoes():
		_construir.rpc_id(peer, c[0], Vector2i(c[1], c[2]), int(c[3]) if c[0] != "bau" and c.size() > 3 else 0)  # o conteúdo dos baús fica só aqui
	for j in get_tree().get_nodes_in_group(&"jogadores"):
		if j.name != str(peer):
			(j as Player).enviar_progresso_para(peer)
	World.avisar_todos(self, "Um amigo entrou na ilha!")


func _on_peer_saiu(peer: int) -> void:
	if multiplayer.is_server() and entidades.has_node(str(peer)):
		var p: Player = entidades.get_node(str(peer))
		if _id_por_peer.has(peer) and not _restaurar_depois.has(peer):
			if not p.criando:  # quem ainda cria o personagem não tem o que salvar
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
			var jogador_salvo := entidades.get_node(str(peer)) as Player
			if not jogador_salvo.criando:  # quem ainda cria o personagem não tem o que salvar
				_registros[_id_por_peer[peer]] = jogador_salvo.registro()
	var recursos := {}
	for r in get_tree().get_nodes_in_group(&"recursos"):
		var rn := r as ResourceNode
		if rn.estado != ResourceNode.Estado.INTEIRO or rn.golpes_restantes() != rn.golpes:
			# Árvore queimando é salva como queimada (o fogo não volta aceso).
			var e := ResourceNode.Estado.QUEIMADO if rn.estado == ResourceNode.Estado.QUEIMANDO else rn.estado
			recursos[String(rn.name)] = [e, rn.golpes_restantes()]
	return Salvamento.gravar({
		"semente": semente, "noite": noite,
		"nome": nome_mundo, "dificuldade": dificuldade,
		"recursos": recursos, "removidos": _removidos.duplicate(),
		"construcoes": _lista_construcoes(),
		"bau_acampamento": bau_acampamento.conteudo,
		"jogadores": _registros,
	}, arquivo_salvo)


func _carregar_mundo() -> void:
	var dados := Salvamento.ler(arquivo_salvo)
	if dados.is_empty():
		return
	dificuldade = clampi(int(dados.get("dificuldade", dificuldade)), 0, 2)
	nome_mundo = String(dados.get("nome", nome_mundo))
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
	for c in dados.get("construcoes", []):
		var baus: bool = c[0] == "bau"
		var p := _criar_peca(StringName(c[0]), Vector2i(int(c[1]), int(c[2])), int(c[3]) if not baus and c.size() > 3 else 0)
		if p and baus and c.size() > 3:
			p.conteudo = c[3]
	bau_acampamento.conteudo = dados.get("bau_acampamento", [])


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


## Sai do mundo para a Home, salvando antes (menu de pausa).
func sair_para_o_menu() -> void:
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
	# A camada não aparece (quem desenha é o Terreno); a textura só serve de suporte aos tiles.
	var src := TileSetAtlasSource.new()
	src.texture = preload("res://assets/sprites/tiny/fx/gelo.png")
	src.texture_region_size = Vector2i(T, T)
	ts.add_source(src, 0)
	src.create_tile(TILE_CHAO)
	src.create_tile(TILE_AGUA)
	# A água não deixa passar.
	var dados := src.get_tile_data(TILE_AGUA, 0)
	dados.add_collision_polygon(0)
	dados.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]))
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
			elif d > 0.87:
				_tipo[cel] = Chao.AREIA
			else:
				_tipo[cel] = Chao.GRAMA
				if Vector2(cel - c).length() <= 2.6:
					_terra[cel] = true  # clareira de areia em volta da fogueira
			chao.set_cell(cel, 0, TILE_AGUA if _tipo[cel] == Chao.AGUA else TILE_CHAO)
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
const TEX_TS_AREIA := preload("res://assets/sprites/tiny/areia.png")  # L12, feita sobre a grama deles
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

	# Gelo da lança de gelo (L16): bloco de 64 px no pixel do pacote, escala 0,25.
	_camada_gelo = TileMapLayer.new()
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TS, TS)
	var src := TileSetAtlasSource.new()
	src.texture = preload("res://assets/sprites/tiny/fx/gelo.png")
	src.texture_region_size = Vector2i(TS, TS)
	ts.add_source(src, 0)
	src.create_tile(Vector2i.ZERO)
	_camada_gelo.tile_set = ts
	_camada_gelo.scale = Vector2(ESCALA_TS, ESCALA_TS)
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


func _montar_acampamento() -> void:
	# A fogueira do acampamento: ilumina, protege da noite e assa carne (clique com carne
	# crua na mão). Igual à fogueira construída, mas não quebra.
	var fogueira := Construcao.new()
	fogueira.tipo = &"fogueira"
	fogueira.item = &"fogueira"
	fogueira.fixa = true
	fogueira.name = "FogueiraAcampamento"
	fogueira.position = centro + Vector2(0, 12)
	entidades.add_child(fogueira)
	fogueira.set_meta(&"raio_luz", 72.0)
	_ocupados.append(fogueira.position)
	_objeto_acampamento(Acamp.BARRACA, centro + Vector2(-50, -16), Vector2(22, 8))
	_objeto_acampamento(Acamp.BANCADA, centro + Vector2(50, -16), Vector2(24, 8))
	# O baú do acampamento guarda coisas (igual ao baú construído, mas não quebra).
	var bau := Construcao.new()
	bau.tipo = &"bau"
	bau.item = &"bau"
	bau.fixa = true
	bau.name = "BauAcampamento"
	bau.position = centro + Vector2(48, 18)
	entidades.add_child(bau)
	_ocupados.append(bau.position)
	bau_acampamento = bau
	_objeto_acampamento(Acamp.BARRIL, centro + Vector2(-40, 20), Vector2(10, 5))
	_objeto_acampamento(Acamp.VARAL, centro + Vector2(-84, 6), Vector2.ZERO)


## Um objeto do acampamento (sprite da folha L12). Com `colisao`, ninguém atravessa.
func _objeto_acampamento(qual: int, pos: Vector2, colisao: Vector2) -> Node2D:
	var regiao := Rect2(qual * QUADRO_NOSSO, 0, QUADRO_NOSSO, QUADRO_NOSSO)
	_ocupados.append(pos)
	if colisao == Vector2.ZERO:
		return _sprite(TEX_ACAMPAMENTO, regiao, pos, null, ESCALA_TS, PE_NOSSO)
	# A bancada abre a fabricação 3x3 (segurar E). Nome fixo: igual em todos os jogadores.
	var corpo: StaticBody2D = Bancada.new() if qual == Acamp.BANCADA else StaticBody2D.new()
	corpo.name = "Acamp%d" % qual
	corpo.position = pos
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = colisao
	forma.shape = ret
	forma.position = Vector2(0, -colisao.y / 2.0 - 2.0)
	corpo.add_child(forma)
	entidades.add_child(corpo)
	_sprite(TEX_ACAMPAMENTO, regiao, Vector2.ZERO, corpo, ESCALA_TS, PE_NOSSO)
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
			_ocupados.append(p)
			colocadas += 1
			if gerar_recursos:
				var pd: ResourceNode = PEDRA.instantiate()
				pd.name = "Pedra%d" % colocadas
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
				var s := _sprite(TEX_NATUREZA, Rect2(COGUMELO_AZUL * QUADRO_NOSSO, 0, QUADRO_NOSSO, QUADRO_NOSSO), p, null, ESCALA_TS, PE_NOSSO)
				var luz := PointLight2D.new()
				luz.texture = LUZ
				luz.color = Color(0.3, 0.95, 0.9)
				luz.energy = 0.7
				luz.texture_scale = 1.4  # o sprite do cogumelo tem escala 0,25
				luz.position = Vector2(0, -24)
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

	_espalhar_baus(celulas_grama)


## Baús trancados (BauTrancado): nascem iguais em todos (mesma semente, mesmos nomes), longe
## da fogueira. Vem por último em _espalhar para não mudar onde ficam as outras coisas.
func _espalhar_baus(celulas: Array[Vector2i]) -> void:
	if not gerar_recursos:
		return
	var colocados := 0
	for i in baus_trancados * 30:
		if colocados >= baus_trancados:
			break
		var p := _ponto_em(celulas)
		if p.distance_to(centro) > 220.0 and _livre(p, 24.0):
			_ocupados.append(p)
			colocados += 1
			var b := BauTrancado.new()
			b.name = "BauTrancado%d" % colocados
			b.position = p
			entidades.add_child(b)


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



## Arqueiros inimigos (Atirador): grupos de 2 longe da fogueira, nas bordas da ilha (só o
## anfitrião; o MultiplayerSpawner copia). À noite nascem mais (_atirador_da_noite).
func _criar_atiradores() -> void:
	if not gerar_recursos or grupos_atiradores <= 0:
		return
	var celulas: Array[Vector2i] = []
	for cel in _tipo:
		if _tipo[cel] == Chao.GRAMA and _distancia[cel] > 0.45 and _distancia[cel] < 0.85:
			celulas.append(cel)
	if celulas.is_empty():
		return
	var grupos := 0
	var n := 0
	for tentativa in grupos_atiradores * 30:
		if grupos >= grupos_atiradores:
			break
		var p := _ponto_em(celulas)
		if p.distance_to(centro) < 260.0 or not _livre(p, 20.0):
			continue
		grupos += 1
		for k in 2:
			n += 1
			var a: Atirador = ATIRADOR.instantiate()
			a.name = "Atirador%d" % n
			a.position = p + Vector2(18.0 * k, 6.0 * k)
			entidades.add_child(a, true)


func _ponto_em(celulas: Array[Vector2i]) -> Vector2:
	var cel := celulas[_rng.randi() % celulas.size()]
	return Vector2(cel * T) + Vector2(_rng.randf_range(2, 14), _rng.randf_range(6, 15))


func _livre(p: Vector2, raio: float) -> bool:
	for o in _ocupados:
		if o.distance_to(p) < raio:
			return false
	return true


func _sprite(textura: Texture2D, regiao: Rect2, pos: Vector2, pai: Node = null, escala := 1.0, pe := 4) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = textura
	s.region_enabled = true
	s.region_rect = regiao
	s.centered = false
	s.offset = Vector2(-regiao.size.x / 2.0, -regiao.size.y + pe)
	s.scale = Vector2(escala, escala)
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
	if not noite and multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		for s in get_tree().get_nodes_in_group(&"inimigos"):
			if s is Slime and s.noturno:
				s.derreter()


# --- Noite perigosa ----------------------------------------------------------------
## À noite o anfitrião faz nascer slimes mais fortes no escuro, longe dos jogadores e da
## luz (mais jogadores, mais slimes). A fogueira e as tochas protegem: o slime foge da luz
## e não persegue quem está dentro dela. Ao amanhecer os slimes da noite derretem.
const INTERVALO_NOITE := 6.0
const LIMITE_NOITE := 4  # + 2 por jogador
var _tempo_noite := 0.0
var _nascidos_noite := 0


func _process_noite(delta: float) -> void:
	if not noite:
		return
	_tempo_noite += delta
	if _tempo_noite < INTERVALO_NOITE:
		return
	_tempo_noite = 0.0
	var jogadores := get_tree().get_nodes_in_group(&"jogadores")
	_atirador_da_noite(jogadores)
	var da_noite := 0
	for s in get_tree().get_nodes_in_group(&"inimigos"):
		if s is Slime and s.noturno:
			da_noite += 1
	if da_noite >= LIMITE_NOITE + 2 * jogadores.size():
		return
	var celulas: Array[Vector2i] = []
	for cel in _tipo:
		if _tipo[cel] == Chao.GRAMA:
			celulas.append(cel)
	for tentativa in 20:
		var p := _ponto_em(celulas)
		var longe := true
		for j in jogadores:
			if (j as Node2D).global_position.distance_to(p) < 150.0:
				longe = false
		if longe and luz_que_protege(self, p) == Vector2.INF:
			_nascidos_noite += 1
			var s: Slime = SLIME.instantiate()
			s.name = "SlimeNoite%d" % _nascidos_noite
			s.noturno = true
			s.position = p
			entidades.add_child(s, true)
			return



## À noite, de vez em quando nasce um arqueiro da noite no escuro, longe de todos (no máximo
## 1 + 1 por jogador ao mesmo tempo). Ele foge da luz e vai embora quando amanhece.
const CHANCE_ATIRADOR_NOITE := 0.35
var _nascidos_atiradores := 0


func _atirador_da_noite(jogadores: Array[Node]) -> void:
	if grupos_atiradores <= 0 or randf() > CHANCE_ATIRADOR_NOITE:
		return
	var vivos := 0
	for a in get_tree().get_nodes_in_group(&"atiradores"):
		if (a as Atirador).noturno:
			vivos += 1
	if vivos >= 1 + jogadores.size():
		return
	var celulas: Array[Vector2i] = []
	for cel in _tipo:
		if _tipo[cel] == Chao.GRAMA:
			celulas.append(cel)
	for tentativa in 20:
		var p := _ponto_em(celulas)
		var longe := true
		for j in jogadores:
			if (j as Node2D).global_position.distance_to(p) < 170.0:
				longe = false
		if longe and luz_que_protege(self, p) == Vector2.INF:
			_nascidos_atiradores += 1
			var a: Atirador = ATIRADOR.instantiate()
			a.name = "AtiradorNoite%d" % _nascidos_atiradores
			a.noturno = true
			a.position = p
			entidades.add_child(a, true)
			return


## Centro da luz que protege este ponto (fogueira, tocha), ou Vector2.INF se está no escuro.
static func luz_que_protege(quem: Node, pos: Vector2) -> Vector2:
	for luz in quem.get_tree().get_nodes_in_group(&"luz_protege"):
		var n := luz as Node2D
		if n.global_position.distance_to(pos) <= float(n.get_meta(&"raio_luz", 48.0)):
			return n.global_position
	return Vector2.INF


# --- Construção ----------------------------------------------------------------------
## Peças postas pelos jogadores (Construcao), uma por tile e por camada ("piso" para o chão
## de madeira, "obj" para o resto). O anfitrião confere e manda todos criarem igual.
var _pecas: Dictionary[String, Construcao] = {}
var _pisos: Node2D  # chão de madeira: embaixo das pessoas e das coisas
var bau_acampamento: Construcao


static func camada_de(tipo: StringName) -> String:
	return "piso" if tipo == &"chao" else "obj"


func _chave(cel: Vector2i, camada: String) -> String:
	return "%d_%d_%s" % [cel.x, cel.y, camada]


## Pode pôr o item `item_id` no tile `cel`? (o anfitrião confere de verdade; o jogador usa
## para pintar a prévia de verde ou vermelho)
func pode_construir(item_id: StringName, cel: Vector2i, quem: Node2D) -> bool:
	if not ItemData.existe(item_id):
		return false
	var tipo := ItemData.carregar(item_id).construcao
	if tipo == &"" or tipo_do_chao(cel) == Chao.AGUA or not Rect2i(0, 0, largura, altura).has_point(cel):
		return false
	if _pecas.has(_chave(cel, camada_de(tipo))):
		return false
	var centro := Vector2(cel * T) + Vector2(T, T) / 2.0
	if quem.global_position.distance_to(centro) > 44.0:
		return false
	if camada_de(tipo) == "obj":
		# Nada com corpo no tile (árvore, pedra, acampamento, gente, slime).
		var consulta := PhysicsShapeQueryParameters2D.new()
		var forma := RectangleShape2D.new()
		forma.size = Vector2(T - 4, T - 4)
		consulta.shape = forma
		consulta.transform = Transform2D(0.0, centro)
		consulta.collision_mask = 1 | 2 | 4 | Construcao.CAMADA_PORTA
		for r in get_world_2d().direct_space_state.intersect_shape(consulta, 4):
			if r.collider != chao:
				return false
	return true


## O jogador pede para pôr o item da mão no tile.
@rpc("any_peer", "call_local", "reliable")
func pedir_construir(cel: Vector2i, rot := 0) -> void:
	if not multiplayer.is_server():
		return
	var peer := multiplayer.get_remote_sender_id()
	var quem := entidades.get_node_or_null(str(1 if peer == 0 else peer)) as Player
	if quem == null:
		return
	var item_id := quem.inventario.item_em(quem.barra_escolhida)
	if not pode_construir(item_id, cel, quem):
		return
	quem.inventario.gastar(quem.barra_escolhida, 1)
	_construir.rpc(String(item_id), cel, rot)


@rpc("any_peer", "call_local", "reliable")
func _construir(item_id: String, cel: Vector2i, rot := 0) -> void:
	if Net.veio_do_anfitriao():
		_criar_peca(StringName(item_id), cel, rot)


func _criar_peca(item_id: StringName, cel: Vector2i, rot := 0) -> Construcao:
	var tipo := ItemData.carregar(item_id).construcao
	var chave := _chave(cel, camada_de(tipo))
	if _pecas.has(chave):
		return null
	var c := Construcao.new()
	c.tipo = tipo
	c.item = item_id
	c.celula = cel
	c.lateral = rot == 1
	c.name = "Peca_" + chave
	c.position = Vector2(cel * T) + Vector2(T / 2.0, T)
	if _pisos == null:
		_pisos = Node2D.new()
		_pisos.name = "Pisos"
		add_child(_pisos)
		move_child(_pisos, entidades.get_index())
	(_pisos if tipo == &"chao" else entidades).add_child(c)
	_pecas[chave] = c
	Sfx.tocar(&"golpe_coleta", -6.0)
	return c


## Só o anfitrião (a peça quebrou).
static func quebrar_construcao(c: Construcao) -> void:
	var w := c.get_tree().get_first_node_in_group(&"mundo") as World
	w._remover_peca.rpc(w._chave(c.celula, camada_de(c.tipo)))


@rpc("any_peer", "call_local", "reliable")
func _remover_peca(chave: String) -> void:
	if not Net.veio_do_anfitriao() or not _pecas.has(chave):
		return
	_pecas[chave].queue_free()
	_pecas.erase(chave)


func _lista_construcoes() -> Array:
	var lista := []
	for chave in _pecas:
		var c := _pecas[chave]
		lista.append([String(c.item), c.celula.x, c.celula.y, c.conteudo] if c.tipo == &"bau" else [String(c.item), c.celula.x, c.celula.y, 1 if c.lateral else 0])
	return lista


# --- Animais -------------------------------------------------------------------------
## Quantos de cada espécie nascem na ilha (só o anfitrião; o MultiplayerSpawner copia).
@export var animais := {&"galinha": 4, &"coelho": 4, &"ovelha": 4, &"javali": 3}
const ANIMAL := preload("res://scenes/animals/animal.tscn")


func _criar_animais() -> void:
	if not gerar_recursos:
		return  # os testes com terreno limpo não querem bichos andando
	var celulas: Array[Vector2i] = []
	for cel in _tipo:
		if _tipo[cel] == Chao.GRAMA and _distancia[cel] < 0.85:
			celulas.append(cel)
	var n := 0
	for especie in animais:
		for i in int(animais[especie]):
			for tentativa in 20:
				var p := _ponto_em(celulas)
				if p.distance_to(centro) > 110.0 and _livre(p, 12.0):
					n += 1
					var a: Animal = ANIMAL.instantiate()
					a.especie = especie
					a.name = "Animal%d" % n
					a.position = p
					entidades.add_child(a, true)
					break
