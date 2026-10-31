extends TesteBase
## Print do arco na mão (L23): parado e puxando a corda (precisa de janela).
## Salva evidence/novidades/arco_<n>.png.


func _ready() -> void:
	var w := await criar_mundo(0, true, &"arqueiro", &"humano")
	var p := w.jogador
	for i in Inventory.BARRA:
		if p.inventario.item_em(i) == &"arco":
			p.barra_escolhida = i
	p.mira_forcada = p.global_position + Vector2(60, -8)
	await esperar(0.5)
	await salvar_print("novidades/arco_0_parado.png")
	p.comecar_habilidade(0)
	await esperar(0.15)
	await salvar_print("novidades/arco_1_pouco.png")
	await esperar(0.4)
	await salvar_print("novidades/arco_2_metade.png")
	await esperar(0.6)
	checar(p.carga_arco >= 0.99, "corda toda puxada (%.2f)" % p.carga_arco)
	await salvar_print("novidades/arco_3_toda.png")
	p.soltar_carga()
	await esperar(0.1)
	checar(p.carga_arco < 0.0, "soltou a corda")
	await salvar_print("novidades/arco_4_soltou.png")
	terminar()
