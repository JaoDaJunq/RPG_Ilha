extends TesteBase
## Animais: nascem na ilha, passeiam, fogem de quem bate (o javali investe), deixam saque
## para quem derrota, e a carne crua vira assada na fogueira (e cura ao comer).


func _ready() -> void:
	var w := await criar_mundo(0, false, &"guerreiro")
	var p := w.jogador
	var bichos := get_tree().get_nodes_in_group(&"animais")
	checar(bichos.size() >= 10, "nasceram animais na ilha (%d)" % bichos.size())
	var especies := {}
	for b in bichos:
		especies[b.especie] = true
	checar(especies.size() == 4, "das 4 espécies (%s)" % ", ".join(especies.keys()))

	# Uma galinha perto do jogador: apanha, foge e, derrotada, deixa carne e pena.
	var g: Animal = bichos.filter(func(b: Animal) -> bool: return b.especie == &"galinha")[0]
	g.global_position = p.global_position + Vector2(20, 0)
	await esperar(0.1)
	var antes := g.global_position.distance_to(p.global_position)
	g.hurtbox.receber(0.5, &"fisico", p)
	await esperar(0.8)
	checar(is_instance_valid(g) and g.global_position.distance_to(p.global_position) > antes + 8.0, "a galinha foge de quem bateu")
	g.hurtbox.receber(9.0, &"fisico", p)
	await esperar(0.2)
	checar(get_tree().get_nodes_in_group(&"itens_chao").size() >= 2, "o saque caiu no chão (e não foi direto para a mochila)")
	checar(p.inventario.quantidade_de(&"carne_crua") == 0, "nada na mochila antes de pegar")
	await pegar_do_chao(p)
	checar(p.inventario.quantidade_de(&"carne_crua") >= 1 and p.inventario.quantidade_de(&"pena") >= 1, "a galinha deixou carne crua e pena")

	# O javali investe contra quem bateu.
	var j: Animal = get_tree().get_nodes_in_group(&"animais").filter(func(b: Node) -> bool: return b.especie == &"javali")[0]
	j.global_position = p.global_position + Vector2(40, 0)
	await esperar(0.1)
	var d0 := j.global_position.distance_to(p.global_position)
	j.hurtbox.receber(0.5, &"fisico", p)
	await esperar(0.5)
	checar(j.global_position.distance_to(p.global_position) < d0, "o javali vem para cima (%.0f -> %.0f)" % [d0, j.global_position.distance_to(p.global_position)])

	# Assar na fogueira do acampamento e comer.
	var fog := w.entidades.get_node("FogueiraAcampamento") as Construcao
	for k in Inventory.BARRA:
		if p.inventario.item_em(k) == &"carne_crua":
			p.barra_escolhida = k
	fog.interagir(p)
	checar(p.inventario.quantidade_de(&"carne_assada") == 1, "a fogueira assou a carne")
	for k in Inventory.BARRA:
		if p.inventario.item_em(k) == &"carne_assada":
			p.barra_escolhida = k
	p.vida.tomar_dano(40.0, &"fisico")
	var vida := p.vida.atual
	p._pedir_usar(p.barra_escolhida)
	checar(p.vida.atual > vida and p.inventario.quantidade_de(&"carne_assada") == 0, "comer a carne assada cura (%.0f -> %.0f)" % [vida, p.vida.atual])
	terminar()
