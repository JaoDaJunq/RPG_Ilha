extends TesteBase
## Prints do Brasinha (L42), dentro do jogo (precisa de janela): fraquinho e acordado na
## fogueira com o balão de fala, o diário (J), o rastreador e uma pedra de lore com o painel
## aberto. Salva em evidence/l42/.


func _ready() -> void:
	var w := await criar_mundo(0, true, &"guerreiro", &"humano", true, 0)
	var p := w.jogador
	var m := w.missoes
	var fogueira := w.entidades.get_node("FogueiraAcampamento") as Construcao
	p.position = fogueira.position + Vector2(-30, 14)
	p.visual.play(&"parado_direita")
	p.camera.position_smoothing_enabled = false
	await esperar(0.5)

	# Perto, sem interface: fraquinho e acordado (o tamanho e o alinhamento na lenha).
	var cam: Camera2D = p.camera
	w.hud.visible = false
	cam.zoom *= 3.0
	await esperar(0.4)
	await salvar_print("l42/brasinha_fraquinho_perto.png")
	m.lenha = 5
	m._emitir()
	await esperar(0.3)
	await salvar_print("l42/brasinha_crescendo_perto.png")
	m.lenha = 10
	m.acordado = true
	m._emitir()
	await esperar(0.3)
	await salvar_print("l42/brasinha_acordado_perto.png")
	m.comemora = 0.0
	cam.zoom /= 3.0
	w.hud.visible = true

	# Fraquinho com balão e rastreador, no zoom normal.
	m.acordado = false
	m.lenha = 0
	m.comemora = 0.0
	m._emitir()
	await esperar(0.3)
	fogueira.interagir(p)
	await esperar(1.5)
	await salvar_print("l42/balao_fraquinho.png")
	w.hud.balao().fechar()
	await esperar(1.0)

	# Acordado, com o balão (o passo 3 e um pedido).
	m.lenha = 10
	m.acordado = true
	m.passo = 2
	m._emitir()
	await esperar(0.3)
	fogueira.interagir(p)
	await esperar(0.4)
	for i in 3:
		w.hud.balao().avancar()
	await esperar(2.0)
	await salvar_print("l42/balao_acordado.png")
	w.hud.balao().fechar()
	await esperar(1.0)

	# O "!" em cima dele, sem balão, de perto.
	m._pendentes = [["oi"]]
	m._emitir()
	cam.zoom *= 2.0
	await esperar(0.3)
	await salvar_print("l42/marcador.png")
	cam.zoom /= 2.0

	# Diário (J).
	m.pedras = [Regioes.Id.BOSQUE]
	m.pedido = {"item": "concha", "qtd": 4, "texto": "4 conchas bonitas.", "rec": ["pocao_cura", 2], "estado": "aceito"}
	m.passo = 4
	m._emitir()
	w.hud.diario().alternar()
	await esperar(0.3)
	await salvar_print("l42/diario.png")
	w.hud.diario().fechar()

	# Pedra de lore.
	var pedra := w.pedra_lore(Regioes.Id.PANTANO)
	p.position = pedra.position + Vector2(-24, 6)
	cam.reset_smoothing()
	await esperar(0.6)
	await salvar_print("l42/pedra_antes.png")
	pedra.interagir(p)
	await esperar(0.4)
	await salvar_print("l42/pedra_painel.png")
	w.hud.painel_lore().fechar()
	await esperar(0.3)
	await salvar_print("l42/pedra_lida.png")
	terminar()
