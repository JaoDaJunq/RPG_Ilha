extends TesteBase
## Captura a mochila com a lista de receitas e um ingrediente faltante como sombra.

func _ready() -> void:
	var w: World = await criar_mundo()
	var inv: Inventory = w.jogador.inventario
	inv.definir([])
	for par in [[&"carvao", 1], [&"madeira", 7], [&"pedra", 5], [&"gel_slime", 3], [&"tabua", 8]]:
		inv.adicionar(par[0], par[1])
	inv.pedir_receita(&"tocha")
	w.hud._mochila.abrir(&"mochila")
	await esperar(0.5)
	await salvar_print("novidades/receitas_auxilio.png")
	terminar()
