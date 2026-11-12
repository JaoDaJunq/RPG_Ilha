extends TesteBase
## Captura o livro de receitas: na mochila (tocha com um ingrediente faltando, como
## sombra) e na bancada (tábuas montadas pelo clique, prontas para pegar).

func _ready() -> void:
	var w: World = await criar_mundo()
	var inv: Inventory = w.jogador.inventario
	var m: Mochila = w.hud._mochila
	inv.definir([])
	for par in [[&"carvao", 1], [&"madeira", 7], [&"pedra", 5], [&"gel_slime", 3], [&"tabua", 8]]:
		inv.adicionar(par[0], par[1])
	m.abrir(&"mochila")
	m._selecionar_receita(&"tocha")
	await esperar(0.5)
	await salvar_print("novidades/receitas_auxilio.png")
	m.fechar()
	inv.na_bancada = true
	m.abrir(&"bancada")
	m._selecionar_receita(&"tabua")
	await esperar(0.5)
	await salvar_print("novidades/receitas_bancada.png")
	terminar()
