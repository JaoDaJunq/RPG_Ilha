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
	w.jogador.ganhar_xp(60)  # o anfitrião já está no nível 3 quando o cliente entra
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
		"--", "--porta=%d" % PORTA, "--criar", "--com-prints" if prints else "--sem-prints"])
	var pid := OS.create_process(OS.get_executable_path(), args)
	checar(pid > 0, "segundo jogo (cliente) aberto")

	var t := 0.0
	while w.get_tree().get_nodes_in_group(&"jogadores").size() < 2 and t < 20.0:
		await esperar(0.1)
		t += 0.1
	checar(get_tree().get_nodes_in_group(&"jogadores").size() == 2, "cliente entrou: 2 jogadores na ilha (%.1f s)" % t)
	for j in get_tree().get_nodes_in_group(&"jogadores"):
		if j != w.jogador:
			(j as Player).ganhar_xp(25)  # o cliente sobe para o nível 2

	# Um item caído no chão, longe de todos: o cliente tem que ver o mesmo item.
	World.soltar_itens(w, w.centro + Vector2(-220, 140), [[&"couro", 2]])

	# O anfitrião lança uma bola de fogo para o cliente ver.
	await esperar(0.5)
	w.jogador.mira_forcada = w.jogador.global_position + Vector2(-200, 0)
	w.jogador.lancar_bola_de_fogo()
	# Um golpe num slime (vida 4, leva 1): o cliente tem de ver a barra de vida dele (75%).
	var slime_golpeado: Slime = w.entidades.get_node("Slime1")
	slime_golpeado.hurtbox.receber(1.0, &"fisico", null)

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
	var niveis: Dictionary = relatorio.get("niveis_slime", {})
	var niveis_certos := not niveis.is_empty()
	for nome in niveis:
		niveis_certos = niveis_certos and niveis[nome] == ("3" if String(nome).begins_with("SlimeNoite") else "1")
	checar(niveis_certos, "cliente vê o nível dos slimes (1 e, os da noite, 3): %s" % str(niveis))
	checar(absf(float(relatorio.get("barra_slime", -1.0)) - 100.0 * 5.0 / 6.0) < 0.5, "cliente vê a barra de vida do slime que apanhou (%s)" % relatorio.get("barra_slime"))
	var esperado := Ficha.criar(&"ogro", &"arqueiro")
	checar(relatorio.get("vida_vista", 0.0) == esperado.vida_maxima(), "cliente recebe a própria vida do anfitrião (%s)" % relatorio.get("vida_vista"))
	checar(relatorio.get("titulo", "") == "Ogro Arqueiro", "cliente escolheu Ogro Arqueiro (%s)" % relatorio.get("titulo"))
	if cliente:
		checar(cliente.raca == &"ogro" and cliente.classe == &"arqueiro", "anfitrião vê o cliente como Ogro Arqueiro")
		# O cliente passou pela tela de criação (Ogro, rosto 2, pele 3, Arqueiro) e entrou no mundo.
		checar(not cliente.criando and cliente.aparencia.get("rosto") == 1 and cliente.aparencia.get("pele") == 2, "anfitrião vê a aparência escolhida pelo cliente (%s)" % str(cliente.aparencia))
		checar(cliente.equipado.get("corpo") == &"roupa_arqueiro" and cliente.equipado.get("cabeca") == &"", "anfitrião vê o traje completo do arqueiro no cliente")
		checar(cliente.inventario.quantidade_de(&"arco") == 1, "o arco do arqueiro está na barra do cliente")
	checar(relatorio.get("viu_criar", false), "o cliente viu a tela de criação ao entrar")
	checar(relatorio.get("aparencia_anfitriao", "") == "humano" and relatorio.get("roupa_anfitriao", "") == "roupa_mago", "cliente vê o anfitrião Humano de manto de mago (%s, %s)" % [relatorio.get("aparencia_anfitriao"), relatorio.get("roupa_anfitriao")])
	checar(relatorio.get("roupa_propria", "") == "roupa_arqueiro" and relatorio.get("pele_propria", -1) == 2, "cliente se vê com o gibão do arqueiro e a pele escolhida (%s, %s)" % [relatorio.get("roupa_propria"), relatorio.get("pele_propria")])
	var armadilhas := get_tree().get_nodes_in_group(&"armadilhas").filter(func(a: Node) -> bool: return a.dono_id == peer)
	checar(armadilhas.size() == 1, "habilidade do cliente (armadilha) aconteceu no anfitrião")
	checar(relatorio.get("mana_gasta", false), "cliente recebeu do anfitrião a mana gasta na armadilha")
	checar(relatorio.get("nivel", 0) == 2, "cliente recebeu o nível 2 do anfitrião (%s)" % relatorio.get("nivel"))
	checar(relatorio.get("nivel_anfitriao", 0) == 3, "quem entra depois vê o nível do anfitrião (%s)" % relatorio.get("nivel_anfitriao"))
	if cliente:
		checar(cliente.distribuidos.get(&"agilidade", 0) == 1 and cliente.pontos_atributo == 1, "ponto que o cliente colocou chegou no anfitrião")
	checar(relatorio.get("agilidade", 0) == Ficha.criar(&"ogro", &"arqueiro").valor(&"agilidade") + 1, "cliente vê a própria Agilidade subir (%s)" % relatorio.get("agilidade"))
	# Árvore de habilidades: o cliente pediu a Chuva de flechas com o ponto do nível 2.
	if cliente:
		checar(cliente.tem(&"chuva_flechas") and cliente.pontos_habilidade == 0, "o anfitrião aprovou o pedido da árvore do cliente (Chuva de flechas)")
	checar(relatorio.get("arvore_chuva", false) and relatorio.get("teclas", 0) == 3, "cliente recebeu a árvore e a Chuva na tecla T (%s teclas)" % relatorio.get("teclas"))
	checar(relatorio.get("antes_estado", -1) == ResourceNode.Estado.ESGOTADO, "quem entra depois vê a árvore já cortada")
	checar(relatorio.get("noite", false), "quem entra depois recebe a noite que já tinha caído")
	checar(relatorio.get("item_chao", []) == ["couro", 2], "cliente vê o item caído no chão com o item e a quantidade certos (%s)" % [relatorio.get("item_chao")])
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
