extends TesteBase
## Confere a lista de receitas, o preenchimento automático pelo anfitrião e as sombras.

func _ready() -> void:
	var w: World = await criar_mundo()
	var inv: Inventory = w.jogador.inventario
	inv.definir([])
	inv.adicionar(&"madeira", 1)
	var antes_madeira: int = inv.quantidade_de(&"madeira")
	inv.pedir_receita(&"tabua")
	checar(inv.item_em(Inventory.GRADE) == &"madeira" and inv.qtd_em(Inventory.GRADE) == 1, "selecionar tábuas põe madeira na posição da receita")
	checar(inv.quantidade_de(&"madeira") == antes_madeira - 1, "a madeira saiu da mochila")
	checar(inv.receita_atual() != null and inv.receita_atual().resultado == &"tabua", "o resultado aparece na saída da grade")
	inv.pedir_receita(&"tocha")
	checar(inv.quantidade_de(&"madeira") == antes_madeira and inv.item_em(Inventory.GRADE) == &"", "a receita anterior volta para a mochila antes de preparar outra")
	inv.pedir_fechar()
	inv.definir([])
	inv.adicionar(&"carvao", 1)
	inv.pedir_receita(&"tocha")
	checar(inv.item_em(Inventory.GRADE) == &"carvao", "ingrediente disponível foi para a primeira posição da tocha")
	checar(inv.item_em(Inventory.GRADE + 3) == &"" and inv.sombras_receita.get(Inventory.GRADE + 3, &"") == &"graveto", "graveto faltante aparece como sombra embaixo do carvão")
	checar(inv.quantidade_de(&"carvao") == 0, "o carvão saiu da mochila")
	inv.adicionar(&"graveto", 1)
	var espaco_graveto: int = _espaco_de(inv, &"graveto")
	inv.pedir_clique(espaco_graveto)
	inv.pedir_clique(Inventory.GRADE + 1, true)
	checar(inv.item_em(Inventory.GRADE + 1) == &"graveto" and not inv.sombras_receita.has(Inventory.GRADE + 1), "colocar o item na posição apaga a sombra")
	w.hud._mochila.abrir(&"mochila")
	await get_tree().process_frame
	checar(w.hud._mochila._lista_receitas != null and w.hud._mochila._lista_receitas.get_child_count() > 0, "a mochila mostra a lista de receitas")
	terminar()


func _espaco_de(inv: Inventory, item_id: StringName) -> int:
	for indice in Inventory.GUARDAR:
		if inv.item_em(indice) == item_id:
			return indice
	return -1
