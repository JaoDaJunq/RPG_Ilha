extends TesteBase
## Criação do personagem dentro do mundo: quem entra sem personagem salvo vê a tela e não age
## até confirmar; raça, aparência e classe viram ficha, roupa completa e arma. A roupa sai e
## volta pela mochila (o boneco volta para a roupa branca); e tudo
## isso é salvo. Usa um arquivo só de teste.

const ARQUIVO := "user://teste_criacao.save"


func _ready() -> void:
	Salvamento.apagar(ARQUIVO)
	var w := await _mundo()
	var p := w.jogador
	var inv := p.inventario

	# 1. Sem personagem salvo: abre a tela e o jogador fica parado, escondido e protegido.
	checar(p.criando and p.tela_de_criacao() != null, "personagem novo abre a tela de criação")
	checar(not p.visual.visible, "enquanto cria, o boneco não aparece no mundo")
	checar(not w.hud._raiz.visible, "enquanto cria, o HUD fica escondido")
	var antes := p.global_position
	Input.action_press(&"mover_direita")
	await esperar(0.4)
	Input.action_release(&"mover_direita")
	checar(p.global_position.distance_to(antes) < 0.5, "enquanto cria, o jogador não anda")
	checar(p.vida.protegido(), "enquanto cria, o jogador não toma dano")
	checar(inv.quantidade_de(&"cajado") == 0 and inv.item_em(Inventory.EQUIP_CORPO) == &"", "ainda sem arma nem roupa")
	var tela := p.tela_de_criacao()
	checar(tela.boneco().visible and tela.roupas().corpo == &"roupa_" + String(tela.classe), "passo 1: o personagem aparece com a arte completa da classe marcada")

	# 2. Passo 1: Ogro, rosto 3 (índice 2), pele 2 (índice 1).
	tela.escolher_raca(&"ogro")
	tela.definir_rosto(2)
	tela.definir_pele(1)
	tela.confirmar()  # ainda no passo 1: não confirma
	checar(p.criando, "confirmar só vale no passo da classe")
	tela.avancar()
	checar(tela.passo == 1, "Próximo leva ao passo da classe")
	tela.escolher_classe(&"mago")
	checar(tela.roupas().corpo == &"roupa_mago" and tela.roupas().cabeca == &"", "passo 2: o boneco veste o traje completo do mago")
	tela.voltar()
	tela.avancar()
	tela.confirmar()
	for i in 4:
		await get_tree().physics_frame

	# 3. Resultado: raça, classe, ficha, roupas base e arma.
	var ficha := Ficha.criar(&"ogro", &"mago")
	checar(not p.criando and p.tela_de_criacao() == null, "confirmar fecha a tela e solta o jogador")
	checar(p.visual.visible and w.hud._raiz.visible, "o boneco e o HUD aparecem")
	checar(p.raca == &"ogro" and p.classe == &"mago", "raça Ogro e classe Mago (%s %s)" % [p.raca, p.classe])
	checar(p.aparencia.get("raca") == &"ogro" and p.aparencia.get("rosto") == 2 and p.aparencia.get("pele") == 1, "aparência: ogro, rosto 2, pele 1 (%s)" % str(p.aparencia))
	checar(p.ficha.titulo() == "Ogro Mago" and p.vida.maximo == ficha.vida_maxima() and p.mana == ficha.mana_maxima(), "ficha, vida e mana do Ogro Mago")
	checar(w.hud._titulo_personagem.text == "Nv 1 · Ogro Mago", "HUD mostra Nv 1 · Ogro Mago (%s)" % w.hud._titulo_personagem.text)
	checar(inv.item_em(Inventory.EQUIP_CORPO) == &"roupa_mago" and inv.item_em(Inventory.EQUIP_CABECA) == &"", "traje completo do mago vestido num espaço só")
	checar(p.equipado.get("corpo") == &"roupa_mago" and p.equipado.get("cabeca") == &"", "equipado (o que todos veem) tem o traje completo")
	var no_bar := false
	for k in Inventory.BARRA:
		no_bar = no_bar or inv.item_em(k) == &"cajado"
	checar(no_bar, "o cajado do mago está na barra")
	checar(p.habilidades().size() == 4 and p.habilidades()[0].id == &"bola_de_fogo", "habilidades do mago")

	# 4. Roupas: tirar com Shift + clique manda para a mochila; a roupa branca volta.
	inv.pedir_clique(Inventory.EQUIP_CORPO, false, true)
	checar(p.equipado.get("corpo") == &"" and inv.item_em(Inventory.EQUIP_CORPO) == &"", "tirar o manto: equipado.corpo vazio (roupa branca)")
	checar(inv.quantidade_de(&"roupa_mago") == 1, "o manto foi para a mochila")
	checar(p.equipado.get("cabeca") == &"", "o chapéu separado não é mais equipado")
	# A roupa completa volta para o único espaço de roupa.
	var espaco_chapeu := _espaco_de(inv, &"roupa_mago")
	inv.pedir_clique(espaco_chapeu)  # pega o manto na mão
	inv.pedir_clique(Inventory.EQUIP_CORPO)  # no corpo: pode
	checar(inv.item_em(Inventory.EQUIP_CORPO) == &"roupa_mago" and inv.item_em(Inventory.MAO) == &"", "arrastar o manto para o corpo veste")
	var espaco_cajado := _espaco_de(inv, &"cajado")
	inv.pedir_clique(espaco_cajado)
	inv.pedir_clique(Inventory.EQUIP_CORPO)  # cajado não é roupa
	checar(inv.item_em(Inventory.EQUIP_CORPO) == &"roupa_mago" and inv.item_em(Inventory.MAO) == &"cajado", "item que não é roupa não entra")
	inv.pedir_clique(espaco_cajado)  # devolve o cajado
	# Chapéus antigos não ocupam espaço visual; o traje completo traz a cobertura da cabeça.
	checar(not Inventory.EQUIPAMENTO.has(Inventory.EQUIP_CABECA), "não existe espaço de equipamento separado para a cabeça")
	# Mochila aberta: o boneco da miniatura acompanha.
	w.hud._mochila.abrir(&"mochila")
	await esperar(0.2)
	checar(w.hud._mochila._boneco != null and w.hud._mochila._boneco.is_visible_in_tree(), "a mochila mostra o bonequinho")
	w.hud._mochila.fechar()

	# 5. Salvar e abrir de novo: não passa pela criação e tudo volta (inclusive sem manto).
	inv.pedir_clique(Inventory.EQUIP_CORPO, false, true)  # sai com o manto na mochila
	checar(w.salvar(), "salvou o mundo")
	w.queue_free()
	await get_tree().process_frame
	w = await _mundo()
	p = w.jogador
	inv = p.inventario
	checar(not p.criando and p.tela_de_criacao() == null, "personagem salvo não passa pela criação")
	checar(p.raca == &"ogro" and p.classe == &"mago" and p.ficha.titulo() == "Ogro Mago", "voltou Ogro Mago")
	checar(p.aparencia.get("rosto") == 2 and p.aparencia.get("pele") == 1, "voltou com rosto 2 e pele 1 (%s)" % str(p.aparencia))
	checar(p.equipado.get("cabeca") == &"" and p.equipado.get("corpo") == &"", "voltou sem traje de classe (roupa branca)")
	checar(inv.quantidade_de(&"roupa_mago") == 1 and inv.quantidade_de(&"cajado") == 1, "manto na mochila e cajado na barra")
	checar(p.visual.visible, "boneco aparece")

	# 6. Registro antigo (sem aparência): ganha as roupas base da classe.
	var antigo := p.registro()
	antigo.erase("aparencia")
	antigo["itens"] = []
	p.restaurar(antigo, false)
	checar(inv.item_em(Inventory.EQUIP_CORPO) == &"roupa_mago" and inv.item_em(Inventory.EQUIP_CABECA) == &"", "personagem salvo antes dos trajes ganha o traje completo da classe")

	Salvamento.apagar(ARQUIVO)
	terminar()


func _espaco_de(inv: Inventory, id: StringName) -> int:
	for i in Inventory.GUARDAR:
		if inv.item_em(i) == id:
			return i
	return -1


func _mundo() -> World:
	Sfx.ligado = false
	Net.classe = &"guerreiro"
	Net.raca = &"humano"
	Net.id_jogador = "teste_criacao"
	Net.pular_criacao = false
	var w: World = MUNDO.instantiate()
	w.arquivo_salvo = ARQUIVO
	w.slimes = 0
	w.gerar_recursos = false
	add_child(w)
	await get_tree().physics_frame
	return w
