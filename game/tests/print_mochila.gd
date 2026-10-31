extends TesteBase
## Prints da mochila (2x2, com tábuas no resultado) e da bancada (3x3, com o machado).
## Precisa de janela. Salva evidence/fundacao/mochila.png e bancada.png.


func _ready() -> void:
	var w := await criar_mundo()
	var p := w.jogador
	var inv := p.inventario
	for par in [[&"madeira", 23], [&"pedra", 12], [&"carvao", 4], [&"machado_madeira", 1], [&"tocha", 8], [&"gel_slime", 3], [&"tabua", 14], [&"graveto", 6], [&"espada_pedra", 1]]:
		inv.adicionar(par[0], par[1])
	p.barra_escolhida = 3
	# Mochila: 1 madeira na grade 2x2 (vira 4 tábuas) e tábuas na mão.
	inv.pedir_clique(0)
	inv.pedir_clique(Inventory.GRADE, true)
	inv.pedir_clique(0)
	inv.pedir_clique(_espaco_de(inv, &"tabua"))
	w.hud._mochila.abrir(&"mochila")
	await esperar(0.3)
	await salvar_print("fundacao/mochila.png")
	inv.pedir_fechar()
	w.hud._mochila.fechar()
	# Bancada: o padrão do machado de pedra na 3x3.
	inv.na_bancada = true
	for par in [[0, &"pedra"], [1, &"pedra"], [3, &"pedra"], [4, &"graveto"], [7, &"graveto"]]:
		var de := _espaco_de(inv, par[1])
		inv.pedir_clique(de)
		inv.pedir_clique(Inventory.GRADE + par[0], true)
		inv.pedir_clique(de)
	w.hud._mochila.abrir(&"bancada")
	await esperar(0.3)
	await salvar_print("fundacao/bancada.png")
	terminar()


func _espaco_de(inv: Inventory, id: StringName) -> int:
	for i in Inventory.GUARDAR:
		if inv.item_em(i) == id:
			return i
	return -1
