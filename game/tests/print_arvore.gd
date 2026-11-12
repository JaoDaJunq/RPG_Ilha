extends TesteBase
## Print da tela da árvore de habilidades (precisa de janela). Um Mago de nível 9 que liberou
## o Raio e o Piscar e entrou no ramo Raio (Condução e Corrente elétrica), com 2 pontos
## sobrando; a Condução fica selecionada. Salva evidence/novidades/arvore_habilidades.png.
## Com `-- --classe=<id>` usa outra classe (só as habilidades padrão, nível 5).


func _ready() -> void:
	var classe := &"mago"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--classe="):
			classe = StringName(a.get_slice("=", 1))
	var w := await criar_mundo(0, true, classe, &"elfo")
	var p := w.jogador
	if classe == &"mago":
		while p.nivel < 9:
			p.ganhar_xp(Ficha.xp_para_subir(p.nivel))
		for id in [&"raio", &"piscar", &"conducao", &"corrente_eletrica", &"bola_de_fogo", &"raio"]:
			p.pedir_aprender(id)
		await get_tree().physics_frame
		checar(p.tem(&"conducao") and p.pontos_habilidade == 2, "Mago nível 9 no ramo Raio, 2 pontos sobrando (%d)" % p.pontos_habilidade)
		w.hud.arvore().selecionar(&"conducao")
	else:
		while p.nivel < 5:
			p.ganhar_xp(Ficha.xp_para_subir(p.nivel))
	w.hud.mostrar_aviso("")
	w.hud.arvore().abrir()
	await esperar(0.4)
	var sufixo := "" if classe == &"mago" else "_" + String(classe)
	await salvar_print("novidades/arvore_habilidades%s.png" % sufixo)
	terminar()
