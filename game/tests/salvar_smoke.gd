extends TesteBase
## Salvar e carregar: árvores cortadas, pedras mineradas, noite, nível, pontos, itens e
## posição voltam iguais. Personagem diferente começa do zero. Usa um arquivo só de teste.

const ARVORE := preload("res://scenes/world/arvore.tscn")
const ARQUIVO := "user://teste_salvar.save"


func _ready() -> void:
	Salvamento.apagar(ARQUIVO)
	var w := await _mundo(&"mago")
	var p := w.jogador

	# Mexe no mundo.
	var arvores: Array[ResourceNode] = []
	var pedra: ResourceNode = null
	for n in w.entidades.get_children():
		if n is ResourceNode:
			if n.acao == "Cortar" and arvores.size() < 2:
				arvores.append(n)
			elif n.acao == "Minerar" and pedra == null:
				pedra = n
	var nome_cortada := arvores[0].name
	var nome_marcada := arvores[1].name
	var nome_pedra := pedra.name
	for i in arvores[0].golpes:
		arvores[0].interagir(p)
	arvores[1].interagir(p)
	for i in pedra.golpes:
		pedra.interagir(p)
	await get_tree().physics_frame
	p.ganhar_xp(30)
	p.pedir_atributo(&"intelecto")
	p.global_position = w.centro + Vector2(50, 60)
	w.alternar_noite()
	await esperar(0.2)
	var madeira := p.inventario.quantidade_de(&"madeira")
	var pedras := p.inventario.quantidade_de(&"pedra")
	checar(w.salvar(), "salvou o mundo")
	checar(FileAccess.file_exists(ARQUIVO), "arquivo do mundo existe")

	# Fecha e abre de novo, com o mesmo personagem.
	w.queue_free()
	await get_tree().process_frame
	w = await _mundo(&"mago")
	p = w.jogador
	var cortada := w.entidades.get_node_or_null(NodePath(nome_cortada)) as ResourceNode
	var marcada := w.entidades.get_node_or_null(NodePath(nome_marcada)) as ResourceNode
	checar(cortada != null and cortada.estado == ResourceNode.Estado.ESGOTADO, "árvore cortada continua toco")
	checar(marcada != null and marcada.golpes_restantes() == marcada.golpes - 1 and (marcada.regioes_por_golpe.is_empty() or marcada.sprite.region_rect == marcada.regioes_por_golpe[0]),
		"árvore com 1 golpe continua marcada")
	checar(not w.entidades.has_node(NodePath(nome_pedra)), "pedra minerada continua sumida")
	checar(w.noite, "a noite continua")
	checar(p.nivel == 2 and p.distribuidos.get(&"intelecto", 0) == 1 and p.pontos_atributo == 1,
		"nível e pontos voltaram (nível %d, intelecto +%d)" % [p.nivel, p.distribuidos.get(&"intelecto", 0)])
	checar(p.inventario.quantidade_de(&"madeira") == madeira and p.inventario.quantidade_de(&"pedra") == pedras,
		"itens voltaram (%d madeira, %d pedra)" % [p.inventario.quantidade_de(&"madeira"), p.inventario.quantidade_de(&"pedra")])
	checar(p.global_position.distance_to(w.centro + Vector2(50, 60)) < 1.0, "voltou para onde estava")
	checar(p.ponto_de_retorno == w.ponto_de_nascer(0), "desmaiando, volta para o acampamento (não para onde salvou)")

	# Fechar a janela salva (é assim que o João sai do jogo).
	p.ganhar_xp(40)
	w.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	var ao_fechar: Dictionary = Salvamento.ler(ARQUIVO).get("jogadores", {}).get(World.chave_personagem("teste", &"humano", &"mago"), {})
	checar(int(ao_fechar.get("nivel", 0)) == p.nivel and p.nivel > 2, "fechar a janela salva o progresso (nível %d)" % int(ao_fechar.get("nivel", 0)))

	# Outro personagem (outra classe) começa do zero, sem apagar o salvo.
	w.queue_free()
	await get_tree().process_frame
	w = await _mundo(&"guerreiro")
	checar(w.jogador.nivel == 1 and w.jogador.inventario.quantidade_de(&"madeira") == 0, "outra classe começa do zero")
	w.salvar()
	w.queue_free()
	await get_tree().process_frame
	var salvos: Dictionary = Salvamento.ler(ARQUIVO).get("jogadores", {})
	checar(salvos.size() == 2, "Mago e Guerreiro ficam salvos separados (%d)" % salvos.size())
	checar(int(salvos.get(World.chave_personagem("teste", &"humano", &"mago"), {}).get("nivel", 0)) >= 2, "jogar com outra classe não apaga o Mago")
	checar(World.ultimo_personagem(Salvamento.ler(ARQUIVO), "teste").get("classe") == "guerreiro", "o último usado (Guerreiro) é o que o menu escolhe")

	Salvamento.apagar(ARQUIVO)
	terminar()


func _mundo(classe: StringName) -> World:
	Sfx.ligado = false
	Net.classe = classe
	Net.raca = &"humano"
	Net.id_jogador = "teste"
	var w: World = MUNDO.instantiate()
	w.arquivo_salvo = ARQUIVO
	w.slimes = 0
	add_child(w)
	await get_tree().physics_frame
	return w
