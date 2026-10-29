extends TesteBase
## Experiência, níveis e pontos: slime e coleta dão experiência, Humano ganha 10% a mais,
## subir de nível dá pontos e cura, e os pontos de atributo mudam a ficha.

const SLIME := preload("res://scenes/enemies/slime.tscn")
const ARVORE := preload("res://scenes/world/arvore.tscn")


func _ready() -> void:
	checar(Ficha.xp_para_subir(1) == 20 and Ficha.xp_para_subir(2) == 35, "curva: 20 para o nível 2, 35 para o 3")
	checar(Ficha.criar(&"humano", &"mago").experiencia_ajustada(10) == 11, "Humano ganha 10% a mais (10 → 11)")
	checar(Ficha.criar(&"ogro", &"mago").experiencia_ajustada(10) == 10, "Ogro ganha o normal")

	var w := await criar_mundo(0, true, &"guerreiro", &"humano")
	var p := w.jogador
	checar(p.nivel == 1 and p.xp == 0, "começa no nível 1")

	# Derrotar um slime perto dá experiência.
	var slime: Slime = colocar(w, SLIME, p.global_position + Vector2(18, 0))
	slime.set_physics_process(false)
	await get_tree().physics_frame
	p.mira_forcada = slime.global_position
	for i in 4:
		if is_instance_valid(slime):
			p.golpear()
		await esperar(0.4)
	checar(not is_instance_valid(slime), "slime derrotado")
	checar(p.xp == 11, "derrotar slime dá 10 de experiência, 11 para Humano (%d)" % p.xp)

	# Coletar dá experiência.
	var arvore: ResourceNode = colocar(w, ARVORE, p.global_position + Vector2(22, 0))
	await segurar_e(p, arvore.global_position + Vector2(0, -20), 2.0)
	checar(p.xp == 13, "cortar uma árvore dá 2 de experiência (%d)" % p.xp)

	# Subir de nível: pontos, cura, aviso.
	p.vida.tomar_dano(30.0)
	var vida_max_antes := p.vida.maximo
	p.ganhar_xp(7)  # 13 + 7 = 20 → nível 2 (7 * 1,1 = 8 → sobra 1)
	await get_tree().physics_frame
	checar(p.nivel == 2, "20 de experiência sobe para o nível 2 (nível %d, xp %d)" % [p.nivel, p.xp])
	checar(p.pontos_atributo == 2 and p.pontos_habilidade == 1, "nível novo dá 2 pontos de atributo e 1 de habilidade")
	checar(p.vida.atual == p.vida.maximo, "subir de nível cura")
	checar(w.hud.texto_aviso().contains("nível 2"), "HUD avisa que subiu de nível")
	checar(w.hud._titulo_personagem.text.begins_with("Nv 2"), "HUD mostra Nv 2")

	# Distribuir pontos.
	var forca := p.ficha.valor(&"forca")
	p.pedir_atributo(&"forca")
	p.pedir_atributo(&"vitalidade")
	p.pedir_atributo(&"vitalidade")  # sem pontos: não pode
	await get_tree().physics_frame
	checar(p.ficha.valor(&"forca") == forca + 1, "ponto em Força aumenta a Força")
	checar(p.vida.maximo == vida_max_antes + 10.0, "ponto em Vitalidade aumenta a vida máxima em 10 (%d)" % p.vida.maximo)
	checar(p.pontos_atributo == 0 and p.distribuidos.get(&"vitalidade", 0) == 1, "sem pontos sobrando não dá para colocar mais")

	# Vários níveis de uma vez e o nível máximo.
	p.ganhar_xp(100000)
	await get_tree().physics_frame
	checar(p.nivel == Ficha.NIVEL_MAXIMO, "não passa do nível máximo (%d)" % p.nivel)
	checar(p.pontos_habilidade == Ficha.NIVEL_MAXIMO - 1, "no nível máximo tem %d pontos de habilidade" % (Ficha.NIVEL_MAXIMO - 1))

	terminar()
