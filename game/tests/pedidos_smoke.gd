extends TesteBase
## Os pedidos do dia a dia do Brasinha: só depois da bancada, no máximo 1 aberto, aparece ao
## amanhecer, dá para recusar sem punição, só pede coisa de região já visitada, quantidades
## pequenas, recompensa ao entregar e 1 ponto de árvore a cada 5 pedidos.


func _ready() -> void:
	var w := await criar_mundo()
	var p := w.jogador
	var m := w.missoes

	# Antes da bancada (passo 3) não há pedido.
	m.ao_amanhecer()
	checar(not m.pedido_aberto() and not m.pedidos_liberados(), "no começo o Brasinha não pede nada")
	m.passo = Missoes.PASSO_LIBERA_PEDIDOS
	m.acordado = true
	checar(m.pedidos_liberados(), "depois da bancada os pedidos começam")

	# Aparece ao amanhecer (a noite passa e o sol nasce).
	w.alternar_noite()
	await esperar(0.2)
	checar(w.noite and not m.pedido_aberto(), "de noite não aparece pedido")
	w.alternar_noite()
	await esperar(0.2)
	checar(not w.noite and m.pedido_aberto(), "ao amanhecer o Brasinha tem um pedido")
	checar(String(m.pedido["estado"]) == "oferecido" and m.marcador() == "!", "ele só oferece: o '!' aparece")

	# No máximo 1 aberto: outro amanhecer não troca o pedido.
	var texto := String(m.pedido["texto"])
	m.ao_amanhecer()
	checar(String(m.pedido["texto"]) == texto, "com um pedido aberto, não vem outro")

	# Recusar: ele faz drama e pronto. Sem punição.
	var fala := m.responder_pedido(p, false)
	checar(not fala.is_empty() and not m.pedido_aberto() and m.pedidos_feitos == 0, "recusar fecha o pedido, com drama e sem punição")
	checar(m.acordado and not m.fraquinho(), "recusar não deixa o Brasinha fraco")

	# Só pede de regiões visitadas.
	m.visitadas = [Regioes.Id.CLAREIRA]
	var itens_vistos := {}
	for i in 30:
		m.pedido = {}
		m.ao_amanhecer()
		itens_vistos[String(m.pedido["item"])] = true
	checar(itens_vistos.keys() == ["pena"], "só a Clareira visitada: só pede o que se acha nela (%s)" % str(itens_vistos.keys()))
	m.visitadas = [Regioes.Id.CLAREIRA, Regioes.Id.PRAIA]
	itens_vistos.clear()
	var qtd_min := 99
	var qtd_max := 0
	for i in 60:
		m.pedido = {}
		m.ao_amanhecer()
		itens_vistos[String(m.pedido["item"])] = true
		qtd_min = mini(qtd_min, int(m.pedido["qtd"]))
		qtd_max = maxi(qtd_max, int(m.pedido["qtd"]))
	var so_visitadas := true
	for item in itens_vistos:
		var ok := false
		for e in FalasBrasinha.PEDIDOS:
			if String(e["item"]) == item and int(e["regiao"]) in m.visitadas:
				ok = true
		so_visitadas = so_visitadas and ok
	checar(so_visitadas and itens_vistos.has("concha"), "com a Praia visitada, pede coisas da Clareira e da Praia (%s)" % str(itens_vistos.keys()))
	checar(qtd_min >= 2 and qtd_max <= 6, "as quantidades são pequenas (%d a %d)" % [qtd_min, qtd_max])
	var recompensa_ok := true
	for i in 20:
		var rec: Array = FalasBrasinha.escolher(FalasBrasinha.RECOMPENSAS, m._rng)
		recompensa_ok = recompensa_ok and ItemData.existe(StringName(rec[0]))
	checar(recompensa_ok, "todas as recompensas são itens que existem")

	# Aceitar e entregar.
	p.inventario.definir([])
	m.pedido = {"item": "concha", "qtd": 3, "texto": "3 conchas bonitas.", "rec": ["pocao_cura", 2], "estado": "oferecido"}
	var r := m.conversar(p)
	checar(r["escolha"] and _tem_texto(r["linhas"], "conchas"), "ao falar com ele, o pedido é oferecido com escolha")
	m.responder_pedido(p, true)
	checar(String(m.pedido["estado"]) == "aceito" and m.marcador() == "?", "aceito: o '?' pede a entrega")
	p.inventario.adicionar(&"concha", 2)
	r = m.conversar(p)
	checar(m.pedido_aberto() and p.inventario.quantidade_de(&"concha") == 2, "com 2 de 3, ele só lembra o que falta")
	p.inventario.adicionar(&"concha", 1)
	m.conversar(p)
	checar(not m.pedido_aberto() and m.pedidos_feitos == 1, "entregue: o pedido fecha e conta")
	checar(p.inventario.quantidade_de(&"concha") == 0 and p.inventario.quantidade_de(&"pocao_cura") == 2, "ele leva as conchas e dá a recompensa (2 poções de cura)")

	# 1 ponto de árvore a cada 5 pedidos.
	var pontos := p.pontos_habilidade
	for i in 4:
		m.pedido = {"item": "concha", "qtd": 3, "texto": "x", "rec": ["pocao_cura", 1], "estado": "aceito"}
		p.inventario.adicionar(&"concha", 3)
		m.conversar(p)
	checar(m.pedidos_feitos == 5, "5 pedidos feitos")
	checar(p.pontos_habilidade == pontos + 1, "o quinto pedido dá 1 ponto de árvore (%d -> %d)" % [pontos, p.pontos_habilidade])
	m.pedido = {"item": "concha", "qtd": 3, "texto": "x", "rec": ["pocao_cura", 1], "estado": "aceito"}
	p.inventario.adicionar(&"concha", 3)
	m.conversar(p)
	checar(p.pontos_habilidade == pontos + 1, "o sexto não dá ponto")

	terminar()


func _tem_texto(linhas: Array, trecho: String) -> bool:
	for l in linhas:
		if String(l).to_lower().contains(trecho.to_lower()):
			return true
	return false
