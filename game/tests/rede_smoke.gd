extends TesteBase
## Teste de rede de verdade: este processo é o ANFITRIÃO e abre um segundo Godot
## (tests/rede_cliente.tscn) que ENTRA pelo 127.0.0.1. O cliente corta uma árvore,
## anda e manda um relatório do que viu. Os dois lados são conferidos.

const ARVORE := preload("res://scenes/world/arvore.tscn")
const PORTA := 7788


func _ready() -> void:
	Net.modo = Net.Modo.HOSPEDAR
	Net.porta = PORTA
	var w := await criar_mundo(2)
	checar(multiplayer.multiplayer_peer is ENetMultiplayerPeer and multiplayer.is_server(), "anfitrião abriu a porta %d" % PORTA)
	var arvore := criar_arvore_teste(w)
	# Coisas que mudam ANTES do cliente entrar: ele precisa receber esse estado.
	var arvore_antes := criar_arvore_teste(w, "ArvoreAntes", w.ponto_de_nascer(0) + Vector2(-40, 0))
	for i in arvore_antes.golpes:
		arvore_antes.interagir(w.jogador)
	w.alternar_noite()
	var prints := "--com-prints" in OS.get_cmdline_user_args()

	var relatorio := {}
	# Funções anônimas copiam variáveis simples; o dicionário é compartilhado, então é preenchido.
	w.relatorio_recebido.connect(func(peer: int, dados: Dictionary) -> void:
		relatorio.merge(dados, true)
		relatorio["peer"] = peer)
	var args := ["--headless"] if not prints else ["--resolution", "960x540", "--position", "980,60"]
	args.append_array(["--log-file", ProjectSettings.globalize_path("user://rede_cliente.log"),
		"--path", ProjectSettings.globalize_path("res://"), "res://tests/rede_cliente.tscn",
		"--", "--porta=%d" % PORTA, "--raca=ogro", "--classe=arqueiro", "--com-prints" if prints else "--sem-prints"])
	var pid := OS.create_process(OS.get_executable_path(), args)
	checar(pid > 0, "segundo jogo (cliente) aberto")

	var t := 0.0
	while w.get_tree().get_nodes_in_group(&"jogadores").size() < 2 and t < 20.0:
		await esperar(0.1)
		t += 0.1
	checar(get_tree().get_nodes_in_group(&"jogadores").size() == 2, "cliente entrou: 2 jogadores na ilha (%.1f s)" % t)

	# O anfitrião lança uma bola de fogo para o cliente ver.
	await esperar(0.5)
	w.jogador.mira_forcada = w.jogador.global_position + Vector2(-200, 0)
	w.jogador.lancar_bola_de_fogo()

	t = 0.0
	while relatorio.is_empty() and t < 25.0:
		await esperar(0.1)
		t += 0.1
	checar(not relatorio.is_empty(), "relatório do cliente chegou")

	var peer: int = relatorio.get("peer", -1)
	var cliente: Player = w.entidades.get_node_or_null(str(peer))
	checar(cliente != null, "anfitrião tem o jogador do cliente (%d)" % peer)
	if cliente:
		var andou := cliente.global_position.x - w.ponto_de_nascer(1).x
		checar(andou > 20.0, "anfitrião viu o cliente andar para a direita (%.0f px)" % andou)
		checar(cliente.inventario.quantidade_de(&"madeira") == 3, "no anfitrião o cliente tem 3 de madeira")
	checar(arvore.estado == ResourceNode.Estado.ESGOTADO, "no anfitrião a árvore cortada pelo cliente virou toco")

	checar(relatorio.get("jogadores", 0) == 2, "cliente vê 2 jogadores (%s)" % relatorio.get("jogadores"))
	checar(relatorio.get("slimes", 0) == 2, "cliente vê os 2 slimes do anfitrião (%s)" % relatorio.get("slimes"))
	checar(relatorio.get("madeira", 0) == 3, "cliente recebeu 3 de madeira (%s)" % relatorio.get("madeira"))
	checar(relatorio.get("arvore_estado", -1) == ResourceNode.Estado.ESGOTADO, "cliente vê a árvore virar toco")
	checar(relatorio.get("viu_bola", false), "cliente viu a bola de fogo do anfitrião")
	var esperado := Ficha.criar(&"ogro", &"arqueiro")
	checar(relatorio.get("vida_vista", 0.0) == esperado.vida_maxima(), "cliente recebe a própria vida do anfitrião (%s)" % relatorio.get("vida_vista"))
	checar(relatorio.get("titulo", "") == "Ogro Arqueiro", "cliente escolheu Ogro Arqueiro (%s)" % relatorio.get("titulo"))
	if cliente:
		checar(cliente.raca == &"ogro" and cliente.classe == &"arqueiro", "anfitrião vê o cliente como Ogro Arqueiro")
	var armadilhas := get_tree().get_nodes_in_group(&"armadilhas").filter(func(a: Node) -> bool: return a.dono_id == peer)
	checar(armadilhas.size() == 1, "habilidade do cliente (armadilha) aconteceu no anfitrião")
	checar(relatorio.get("mana_gasta", false), "cliente recebeu do anfitrião a mana gasta na armadilha")
	checar(relatorio.get("antes_estado", -1) == ResourceNode.Estado.ESGOTADO, "quem entra depois vê a árvore já cortada")
	checar(relatorio.get("noite", false), "quem entra depois recebe a noite que já tinha caído")
	if prints:
		await salvar_print("rede/anfitriao.png")
		await esperar(2.0)  # dá tempo do cliente salvar o print dele

	Net.encerrar()
	OS.kill(pid)
	terminar()


## A mesma árvore, com o mesmo nome e lugar, nos dois jogos.
static func criar_arvore_teste(w: World, nome := "ArvoreTeste", pos := Vector2.INF) -> ResourceNode:
	var a: ResourceNode = ARVORE.instantiate()
	a.name = nome
	a.position = pos if pos != Vector2.INF else w.ponto_de_nascer(1) + Vector2(0, 22)
	w.entidades.add_child(a)
	return a
