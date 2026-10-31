extends TesteBase
## Itens no chão: o saque cai (uma pilha por entidade), só dá para pegar depois de 0.6 s,
## encostar guarda no inventário, mochila cheia deixa a sobra no chão, perto a pilha desliza
## até o jogador e some sozinha depois de 5 minutos. (O lado cliente é conferido no rede_smoke.)


func _ready() -> void:
	var w := await criar_mundo()
	var p := w.jogador
	var inv := p.inventario
	inv.definir([])
	p.global_position = w.ponto_de_nascer(0)
	var ponto := p.global_position + Vector2(70, 0)

	# 1. O saque aparece no chão, perto de onde caiu, sem ir para a mochila.
	World.soltar_itens(w, ponto, [[&"carne_crua", 3]])
	var itens := get_tree().get_nodes_in_group(&"itens_chao")
	checar(itens.size() == 1, "caiu uma pilha no chão (%d)" % itens.size())
	var it: ItemChao = itens[0]
	checar(it.item == &"carne_crua" and it.quantidade == 3, "com o item e a quantidade certos")
	checar(it.global_position.distance_to(ponto) <= 12.5, "perto de onde caiu (%.1f px)" % it.global_position.distance_to(ponto))
	checar(inv.quantidade_de(&"carne_crua") == 0, "nada foi direto para a mochila")

	# 2. Antes de 0.6 s ainda não dá para pegar, mesmo por cima.
	p.global_position = it.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	checar(is_instance_valid(it) and inv.quantidade_de(&"carne_crua") == 0, "antes de 0,6 s não pega")

	# 3. Depois, encostar guarda e a pilha some.
	await esperar(0.7)
	checar(inv.quantidade_de(&"carne_crua") == 3, "depois de 0,6 s pegou (%d)" % inv.quantidade_de(&"carne_crua"))
	await get_tree().process_frame
	checar(not is_instance_valid(it), "a pilha sumiu do chão")

	# 4. Pilhas grandes viram várias entidades (64 por vez).
	World.soltar_itens(w, ponto, [[&"madeira", 100]])
	checar(get_tree().get_nodes_in_group(&"itens_chao").size() == 2, "100 de madeira viram 2 pilhas")
	await pegar_do_chao(p)
	checar(inv.quantidade_de(&"madeira") == 100, "pegou as duas pilhas (%d)" % inv.quantidade_de(&"madeira"))
	await get_tree().process_frame

	# 5. Mochila cheia: o item fica no chão.
	inv.definir([])
	inv.adicionar(&"pedra", Inventory.GUARDAR * 64)
	p.global_position = w.ponto_de_nascer(0)
	World.soltar_itens(w, ponto, [[&"carne_crua", 2]])
	await pegar_do_chao(p)
	await esperar(0.2)
	var restante := get_tree().get_nodes_in_group(&"itens_chao")
	checar(restante.size() == 1 and inv.quantidade_de(&"carne_crua") == 0, "mochila cheia: o item fica no chão")

	# 6. Coube só um pedaço: o resto fica.
	inv.remover(&"pedra", 5)
	World.soltar_itens(w, ponto, [[&"pedra", 10]])
	p.global_position = w.ponto_de_nascer(0)
	await pegar_do_chao(p)
	await esperar(0.2)
	var pedra: ItemChao = null
	for i in get_tree().get_nodes_in_group(&"itens_chao"):
		if (i as ItemChao).item == &"pedra":
			pedra = i
	checar(pedra != null and pedra.quantidade == 5, "coube 5 de 10: a sobra (5) fica no chão (%s)" % [pedra.quantidade if pedra else "-"])
	for i in get_tree().get_nodes_in_group(&"itens_chao"):
		i.queue_free()
	await get_tree().process_frame

	# 7. Perto (dentro de 20 px), a pilha desliza até o jogador.
	inv.definir([])
	p.global_position = w.ponto_de_nascer(0)
	World.soltar_itens(w, p.global_position + Vector2(0, 60), [[&"graveto", 1]])
	await esperar(0.7)
	var g: ItemChao = get_tree().get_nodes_in_group(&"itens_chao")[0]
	p.global_position = g.global_position + Vector2(17, 0)
	await esperar(0.5)
	checar(inv.quantidade_de(&"graveto") == 1, "o ímã puxou o item (graveto %d)" % inv.quantidade_de(&"graveto"))

	# 8. Some sozinho depois de 5 minutos.
	World.soltar_itens(w, p.global_position + Vector2(100, 0), [[&"pena", 1]])
	var velho: ItemChao = get_tree().get_nodes_in_group(&"itens_chao")[0]
	velho._idade = ItemChao.VIDA_TOTAL + 1.0
	await esperar(0.2)
	checar(not is_instance_valid(velho), "depois de 5 minutos o item some")
	terminar()
