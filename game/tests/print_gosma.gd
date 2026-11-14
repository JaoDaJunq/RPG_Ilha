extends TesteBase
## Prints da Mãe Gosma (L43), dentro do jogo (precisa de janela, 1280x720): altar com a isca,
## fase 1 com o alvo no chão, fase 2 com poça, fase 3 com as 3 filhas e a barra, a coroa.
## Salva em evidence/l43/.


func _gosmas() -> Array[MaeGosma]:
	var l: Array[MaeGosma] = []
	for g in get_tree().get_nodes_in_group(&"boss_gosma"):
		if not g.is_queued_for_deletion():
			l.append(g as MaeGosma)
	return l


func _ready() -> void:
	var w := await criar_mundo(0, true, &"guerreiro", &"humano", true, 0)
	var p := w.jogador
	var a := w.arena_gosma
	a.atraso_chamar = 0.0
	p.camera.position_smoothing_enabled = false
	p.vida.maximo = 100000.0
	p.vida.atual = 100000.0
	p.global_position = a.centro + Vector2(0, -40)
	w.missoes.gosma_isca = true
	await esperar(0.6)
	await salvar_print("l43/01_altar_com_isca.png")

	a.chamar()
	await esperar(0.4)
	var g := _gosmas()[0]
	g._t = -100.0  # espera: nada de pulo agora
	p.global_position = a.centro + Vector2(0, 30)
	await esperar(0.4)
	await salvar_print("l43/02_fase1_parada.png")
	g._t = 100.0
	for i in 40:
		await esperar(0.1)
		if g.em_aviso:
			break
	await esperar(0.2)
	await salvar_print("l43/03_fase1_alvo.png")
	await esperar(1.6)
	await salvar_print("l43/04_fase1_slimes.png")

	g.hurtbox.receber(100000.0, &"fisico", null)
	g.alvo_pos = a.centro + Vector2(-30, 10)
	g._esmagar()
	g._t = -100.0
	await esperar(0.5)
	await salvar_print("l43/05_fase2_fogo_poca.png")
	g._trocar_elemento()
	g.alvo_pos = a.centro + Vector2(30, 10)
	g._esmagar()
	await esperar(0.5)
	await salvar_print("l43/06_fase2_gelo_poca.png")

	g.hurtbox.receber(100000.0, &"fisico", null)
	await esperar(0.5)
	for f in _gosmas():
		f._t = -100.0
	await salvar_print("l43/07_fase3_tres_filhas.png")

	for f in _gosmas():
		f.hurtbox.receber(100000.0, &"fisico", null)
	await esperar(0.6)
	p.global_position = a.centro + Vector2(0, 20)
	await esperar(0.6)
	await salvar_print("l43/08_coroa_depois.png")
	terminar()
