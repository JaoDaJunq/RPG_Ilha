extends TesteBase
## Prints da criação do personagem com 4 raças (passo 1) e 5 classes (passo 2). Precisa de
## janela. Salva evidence/novidades/classes_novas_*.png.


func _ready() -> void:
	var w := await criar_mundo(0, true, &"guerreiro", &"humano", false)
	var p := w.jogador
	await esperar(0.3)
	var tela := p.tela_de_criacao()
	tela.escolher_raca(&"elfo")
	await esperar(0.4)
	await salvar_print("novidades/classes_novas_1_racas_elfo.png")
	tela.escolher_raca(&"anao")
	tela.definir_rosto(1)
	await esperar(0.4)
	await salvar_print("novidades/classes_novas_1_racas_anao.png")
	tela.avancar()
	tela.escolher_classe(&"ladino")
	await esperar(0.4)
	await salvar_print("novidades/classes_novas_2_classes_ladino.png")
	tela.escolher_classe(&"clerigo")
	await esperar(0.4)
	await salvar_print("novidades/classes_novas_2_classes_clerigo.png")
	terminar()
