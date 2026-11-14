extends TesteBase
## A interface do Brasinha: balão de fala com texto letra por letra (clique avança), botões
## de aceitar/recusar o pedido, painel da pedra de lore, diário (J), rastreador do canto,
## "!" e "?" em cima dele e o alfinete no mapa. Clicar na fogueira do acampamento fala com ele.


func _ready() -> void:
	var w := await criar_mundo()
	var p := w.jogador
	var m := w.missoes
	var hud := w.hud
	var fogueira := w.entidades.get_node("FogueiraAcampamento") as Construcao

	checar(hud.balao() != null and hud.painel_lore() != null and hud.diario() != null, "o HUD tem balão, painel de lore e diário")
	checar(fogueira.texto_acao() == "Falar com o Brasinha", "a fogueira do acampamento diz 'Falar com o Brasinha'")
	checar(w.brasinha.marcador.visible, "o '!' aparece em cima do Brasinha")

	# Clicar na fogueira abre o balão (passando pelo caminho de interação do anfitrião).
	p.global_position = fogueira.global_position + Vector2(0, 20)
	p.barra_escolhida = 0
	fogueira.interagir(p)
	var balao := hud.balao()
	checar(balao.aberta(), "falar com a fogueira abre o balão")
	checar(balao._texto.visible_characters == 0, "o texto começa vazio")
	await esperar(0.15)
	var parcial := balao._texto.visible_characters
	checar(parcial > 0 and parcial < balao._texto.text.length(), "e aparece letra por letra (%d de %d)" % [parcial, balao._texto.text.length()])
	var linha1 := balao.texto_inteiro()
	balao.avancar()
	checar(balao._texto.visible_characters == -1, "um clique mostra a linha inteira")
	balao.avancar()
	checar(balao.texto_inteiro() != linha1, "outro clique passa para o próximo balão")
	# Cliques seguidos na fogueira não reabrem nem repetem a fala enquanto o balão está aberto.
	var passo_antes := m.passo
	fogueira.interagir(p)
	checar(balao.texto_inteiro() != linha1 and m.passo == passo_antes, "clicar de novo na fogueira não recomeça a fala")
	for i in 10:
		balao.avancar()
	checar(not balao.aberta(), "no fim das falas o balão fecha")
	fogueira.interagir(p)
	checar(not balao.aberta(), "o clique que fecha o balão não abre outro na hora")

	# Pedido com botões.
	await esperar(1.0)
	m.pedido = {"item": "concha", "qtd": 3, "texto": "3 conchas bonitas.", "rec": ["pocao_cura", 2], "estado": "oferecido"}
	fogueira.interagir(p)
	checar(balao.aberta(), "falar de novo reabre o balão")
	for i in 10:
		balao.avancar()
		if balao._botoes.visible:
			break
		await esperar(0.05)
	await esperar(2.5)
	balao.avancar()
	checar(balao._botoes.visible and balao.aberta(), "no fim da oferta aparecem os botões Aceito e Agora não")
	balao._responder(true)
	checar(String(m.pedido["estado"]) == "aceito" and not balao.aberta(), "clicar em Aceito aceita o pedido")

	# Painel da pedra de lore.
	var lore := hud.painel_lore()
	w.pedra_lore(Regioes.Id.COLINAS).interagir(p)
	checar(lore.visible and lore.regiao == Regioes.Id.COLINAS, "ler a pedra abre o painel de lore")
	checar(lore._frase.text == FalasBrasinha.LORE[Regioes.Id.COLINAS], "com a frase da região")
	lore.fechar()
	checar(not lore.visible, "e ele fecha")

	# Diário (J) e rastreador.
	var diario := hud.diario()
	var ev := InputEventAction.new()
	ev.action = &"missoes"
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	await get_tree().process_frame
	checar(diario.visible, "a tecla J abre o diário de missões")
	checar(diario._missao.text == m.titulo_atual() and diario._objetivo.text.contains(m.objetivo_texto().get_slice("\n", 0)), "o diário mostra a missão atual")
	checar(diario._pedras.text.contains("Colinas"), "e as pedras lidas")
	checar(diario._pedido.text.contains("Concha"), "e o pedido do dia")
	diario.fechar()
	checar(not diario.visible, "fecha de novo")
	checar(hud._rastreador._titulo.text == m.titulo_atual(), "o rastreador do canto mostra o objetivo")

	# Marcadores e alfinete.
	m.passo = 1
	m.acordado = false
	m._pendentes.clear()
	m.pedido = {}
	m._emitir()
	checar(m.marcador() == "?" and w.brasinha._texto.text == "?", "faltando entregar, o marcador vira '?'")
	m.passo = 3
	m._pendentes = [["oi"]]
	m._emitir()
	checar(w.brasinha._texto.text == "!", "com novidade, volta o '!'")
	checar(m.posicao_do_objetivo().distance_to(w.centro) > 100.0, "o alfinete do mapa aponta o pântano, fora do acampamento")
	var mapa := hud.mapa()
	mapa.abrir()
	await get_tree().process_frame
	checar(mapa._alfinete.visible and mapa._alfinete.position.distance_to(m.posicao_do_objetivo() * Mapa.ESCALA) < 40.0, "o alfinete aparece no mapa (M)")
	mapa.fechar()

	terminar()
