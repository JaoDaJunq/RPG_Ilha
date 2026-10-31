extends TesteBase
## Prints da criação do personagem (passo 1 e passo 2) e da mochila com o bonequinho e as
## roupas. Precisa de janela. Salva evidence/novidades/criacao_*.png.


func _ready() -> void:
	var w := await criar_mundo(0, true, &"guerreiro", &"humano", false)
	var p := w.jogador
	await esperar(0.3)
	var tela := p.tela_de_criacao()
	tela.escolher_raca(&"ogro")
	tela.definir_rosto(1)
	tela.definir_pele(1)
	await esperar(0.4)
	await salvar_print("novidades/criacao_1_raca.png")
	tela.avancar()
	tela.escolher_classe(&"mago")
	await esperar(0.4)
	await salvar_print("novidades/criacao_2_classe.png")
	tela.escolher_classe(&"arqueiro")
	await esperar(0.4)
	await salvar_print("novidades/criacao_2_classe_arqueiro.png")
	tela.confirmar()
	await esperar(0.6)
	await salvar_print("novidades/criacao_3_no_mundo.png")
	var inv := p.inventario
	for par in [[&"madeira", 23], [&"pedra", 12], [&"tocha", 8], [&"tabua", 14]]:
		inv.adicionar(par[0], par[1])
	w.hud._mochila.abrir(&"mochila")
	await esperar(0.4)
	await salvar_print("novidades/criacao_4_mochila.png")
	# Tirar o gibão: o bonequinho volta para a roupa branca.
	inv.pedir_clique(Inventory.EQUIP_CORPO, false, true)
	await esperar(0.4)
	await salvar_print("novidades/criacao_5_mochila_sem_roupa.png")
	terminar()
