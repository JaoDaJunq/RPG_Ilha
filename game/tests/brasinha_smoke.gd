extends TesteBase
## O Brasinha (etapa 3): fraquinho no começo, a fome de lenha (10 madeiras e ele acorda,
## com a luz e a zona segura crescendo), madeira como petisco depois, e o capítulo 1 até o
## passo 7 com as entregas: bancada, slimes, gel, pedra do pântano e a isca.


func _ready() -> void:
	var w := await criar_mundo()
	var p := w.jogador
	var m := w.missoes
	var fogueira := w.entidades.get_node("FogueiraAcampamento") as Construcao

	checar(m != null and w.brasinha != null, "o mundo tem o Brasinha e as missões")
	checar(not w.passagem(World.PONTE).aberta and not w.passagem(World.RAIZES).aberta, "as passagens começam fechadas de verdade")
	checar(m.fraquinho() and m.forca() == 0.0, "no começo o Brasinha está fraquinho")
	var raio_fraco: float = fogueira.get_meta(&"raio_luz")
	checar(raio_fraco < World.RAIO_FOGUEIRA, "fraquinho, a zona segura é menor (%.0f < %.0f)" % [raio_fraco, World.RAIO_FOGUEIRA])
	checar(m.marcador() == "!", "tem um '!' em cima dele: há o que ouvir")
	checar(String(m.passo_atual()["id"]) == "acordar", "passo 1: acorde o Brasinha")

	# Passo 1: falar com ele.
	var r := m.conversar(p)
	checar(r["linhas"].size() >= 2, "ele fala (%d balões)" % r["linhas"].size())
	checar(String(m.passo_atual()["id"]) == "lanche", "falar com ele leva ao passo 2 (lanche de fogo)")
	var pedido_lenha := false
	for l in r["linhas"]:
		if String(l).contains("lenha"):
			pedido_lenha = true
	checar(pedido_lenha, "ele pede lenha")

	# Passo 2: entregar 10 madeiras (aos poucos). Começa sem madeira: ele só lembra do que falta.
	p.inventario.remover(&"madeira", p.inventario.quantidade_de(&"madeira"))
	r = m.conversar(p)
	checar(m.lenha == 0 and m.fraquinho(), "sem madeira na mochila, nada muda")
	p.inventario.adicionar(&"madeira", 4)
	m.conversar(p)
	checar(m.lenha == 4 and p.inventario.quantidade_de(&"madeira") == 0, "4 madeiras entregues (lenha %d)" % m.lenha)
	checar(is_equal_approx(m.forca(), 0.4) and m.fraquinho(), "ele cresce um pouco: força %.1f" % m.forca())
	var raio_meio: float = fogueira.get_meta(&"raio_luz")
	checar(raio_meio > raio_fraco and raio_meio < World.RAIO_FOGUEIRA, "a zona segura cresce com a lenha (%.0f)" % raio_meio)
	p.inventario.adicionar(&"madeira", 8)  # sobram 2
	r = m.conversar(p)
	checar(m.acordado and not m.fraquinho(), "com 10 madeiras ele acorda")
	checar(p.inventario.quantidade_de(&"madeira") == 2, "só as 10 foram levadas (sobraram 2)")
	checar(is_equal_approx(float(fogueira.get_meta(&"raio_luz")), World.RAIO_FOGUEIRA), "acordado, a zona segura volta ao normal")
	checar(String(m.passo_atual()["id"]) == "bancada", "passo 3: mãos à obra")
	checar(m.forca() == 1.0, "a força é total")

	# Depois de acordar: madeira é só petisco (nunca mais enfraquece).
	p.barra_escolhida = 0
	p.inventario.definir([])
	p.inventario.adicionar(&"madeira", 3)
	p.barra_escolhida = _espaco_de(p, &"madeira")
	r = m.conversar(p)
	checar(m.contente > 0.0, "madeira na mão vira petisco: ele fica contente")
	checar(p.inventario.quantidade_de(&"madeira") == 2, "gastou 1 madeira só")
	checar(m.lenha == 10 and m.acordado, "o petisco não mexe na fome do começo")
	m.contente = 0.0
	checar(not m.fraquinho(), "ele nunca mais enfraquece sozinho")

	# Contente, quem está perto cura mais rápido (bônus leve).
	m.contente = 10.0
	p.global_position = fogueira.global_position + Vector2(0, 30)
	p.vida.atual = p.vida.maximo * 0.5
	var antes := p.vida.atual
	await esperar(0.6)
	checar(p.vida.atual > antes, "contente, ele cura quem está perto (%.1f -> %.1f)" % [antes, p.vida.atual])
	m.contente = 0.0

	# Passo 3: fazer uma bancada.
	m.notificar_construiu(&"parede_madeira")
	checar(String(m.passo_atual()["id"]) == "bancada", "construir outra coisa não conta")
	m.notificar_construiu(&"bancada")
	checar(String(m.passo_atual()["id"]) == "cheiro", "a bancada vale: passo 4 (que cheiro é esse?)")
	checar(m.tem_novidade(), "ele quer comentar a bancada ('!')")
	r = m.conversar(p)
	checar(_tem_texto(r["linhas"], "bancada"), "ele comenta o trabalho")
	checar(not m.tem_novidade(), "depois de falar, a novidade acabou")

	# Passo 4: 6 slimes.
	for i in 5:
		m.notificar_slime_morto()
	checar(String(m.passo_atual()["id"]) == "cheiro" and m.progresso_texto().contains("5/6"), "5 slimes: %s" % m.progresso_texto())
	m.notificar_slime_morto()
	checar(String(m.passo_atual()["id"]) == "geleia", "6 slimes: passo 5 (geleia estranha)")

	# Passo 5: 5 géis (entrega aos poucos, de qualquer jogador).
	p.inventario.definir([])
	p.inventario.adicionar(&"gel_slime", 3)
	m.conversar(p)
	checar(int(m.entregue.get("gel_slime", 0)) == 3 and String(m.passo_atual()["id"]) == "geleia", "3 géis entregues: %s" % m.progresso_texto())
	p.inventario.adicionar(&"gel_slime", 4)
	r = m.conversar(p)
	checar(String(m.passo_atual()["id"]) == "pedra" and p.inventario.quantidade_de(&"gel_slime") == 2, "5 géis: passo 6 (pedras que lembram); sobraram 2")
	checar(_tem_texto(r["linhas"], "Semente"), "ele revela que a gosma tem gosto de Semente")

	# Passo 6: a pedra do pântano.
	var pedra_praia := w.pedra_lore(Regioes.Id.PRAIA)
	pedra_praia.interagir(p)
	checar(String(m.passo_atual()["id"]) == "pedra", "ler a pedra de outra região não conta para a missão")
	w.pedra_lore(Regioes.Id.PANTANO).interagir(p)
	checar(String(m.passo_atual()["id"]) == "isca", "ler a pedra do pântano leva ao passo 7 (a isca)")
	p.inventario.definir([])
	m.conversar(p)  # ele comenta a pedra e pede a isca

	# Passo 7: a isca (5 géis + 3 cogumelos + 1 carne de sapo), o que falta fica lembrado.
	p.inventario.adicionar(&"gel_slime", 5)
	p.inventario.adicionar(&"cogumelo", 2)
	m.conversar(p)
	checar(String(m.passo_atual()["id"]) == "isca", "faltando cogumelo e carne de sapo, a isca não sai: %s" % m.progresso_texto())
	p.inventario.adicionar(&"cogumelo", 1)
	p.inventario.adicionar(&"carne_sapo", 1)
	r = m.conversar(p)
	checar(String(m.passo_atual()["id"]) == "mae_gosma", "isca completa: passo 8 (Mãe Gosma, em breve)")
	checar(p.inventario.quantidade_de(&"isca_gosma") == 1, "ele entrega a Isca de Gosma")
	checar(p.inventario.quantidade_de(&"gel_slime") == 0 and p.inventario.quantidade_de(&"cogumelo") == 0, "os ingredientes foram gastos (gel %d, cogumelo %d)" % [p.inventario.quantidade_de(&"gel_slime"), p.inventario.quantidade_de(&"cogumelo")])
	checar(ItemData.existe(&"semente_coracao") and ItemData.existe(&"isca_gosma") and ItemData.existe(&"tocha_brasinha"), "os 3 itens novos existem")
	checar(m.regiao_do_objetivo() == Regioes.Id.PANTANO, "o alfinete do mapa aponta o pântano")

	terminar()


func _espaco_de(p: Player, item: StringName) -> int:
	for k in Inventory.BARRA:
		if p.inventario.item_em(k) == item:
			return k
	return 0


func _tem_texto(linhas: Array, trecho: String) -> bool:
	for l in linhas:
		if String(l).to_lower().contains(trecho.to_lower()):
			return true
	return false
