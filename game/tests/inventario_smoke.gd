extends TesteBase
## Inventário estilo Minecraft: pilhas, cliques (esquerdo, direito, shift), fabricação 2x2
## na mochila e 3x3 só na bancada, ferramenta na mão e salvar/carregar.

const G := Inventory.GRADE
const MAO := Inventory.MAO


func _ready() -> void:
	var w := await criar_mundo()
	var p := w.jogador
	var inv := p.inventario

	inv.adicionar(&"madeira", 70)
	checar(inv.quantidade_de(&"madeira") == 70, "guardou 70 de madeira")
	checar(inv.qtd_em(0) == 64 and inv.qtd_em(1) == 6, "pilha de 64 na barra e o resto no espaço seguinte (%d, %d)" % [inv.qtd_em(0), inv.qtd_em(1)])

	# Clique esquerdo pega a pilha inteira; clique direito num espaço vazio põe 1.
	inv.pedir_clique(1)
	checar(inv.item_em(MAO) == &"madeira" and inv.qtd_em(MAO) == 6, "clique pega as 6 madeiras na mão")
	inv.pedir_clique(G, true)
	checar(inv.qtd_em(G) == 1 and inv.qtd_em(MAO) == 5, "clique direito põe 1 na grade")
	checar(inv.receita_atual() != null and inv.receita_atual().resultado == &"tabua", "1 madeira na grade vira tábuas")
	inv.pedir_resultado()
	checar(inv.item_em(MAO) == &"madeira", "a mão ainda tem madeira: o resultado não cabe junto (como no Minecraft)")
	inv.pedir_clique(20)  # larga a madeira da mão na mochila
	inv.pedir_resultado()
	checar(inv.item_em(MAO) == &"tabua" and inv.qtd_em(MAO) == 4, "pegou 4 tábuas (%s %d)" % [inv.item_em(MAO), inv.qtd_em(MAO)])
	checar(inv.item_em(G) == &"", "a madeira da grade foi usada")

	# Graveto: 2 tábuas em coluna na grade 2x2.
	inv.pedir_clique(G, true)
	inv.pedir_clique(G + 3, true)
	checar(inv.receita_atual() != null and inv.receita_atual().resultado == &"graveto", "2 tábuas em coluna viram gravetos")
	inv.pedir_clique(21)  # guarda as 2 tábuas que sobraram na mão
	inv.pedir_resultado(true)  # shift: fabrica e guarda direto
	checar(inv.quantidade_de(&"graveto") == 4, "shift no resultado guardou 4 gravetos (tem %d)" % inv.quantidade_de(&"graveto"))

	# Machado (3x3) não sai na mochila; na bancada sai.
	inv.adicionar(&"tabua", 2)
	var t := _espaco_de(inv, &"tabua")
	inv.pedir_clique(t, true)
	inv.pedir_clique(G)  # pôs 1 tábua... (clique esquerdo larga a mão inteira)
	inv.pedir_fechar()
	checar(inv.quantidade_de(&"tabua") >= 3 and inv.item_em(G) == &"" and inv.item_em(MAO) == &"", "fechar devolve grade e mão para a mochila")
	inv.na_bancada = true
	_montar(inv, {G: &"tabua", G + 1: &"tabua", G + 3: &"tabua", G + 4: &"graveto", G + 7: &"graveto"})
	checar(inv.receita_atual() != null and inv.receita_atual().resultado == &"machado_madeira", "na bancada, o padrão do machado faz um machado")
	inv.pedir_resultado(true)
	checar(inv.quantidade_de(&"machado_madeira") == 1, "machado de madeira guardado")
	inv.na_bancada = false

	# Ferramenta na mão: o machado deixa a coleta mais rápida.
	var m := _espaco_de(inv, &"machado_madeira")
	inv.pedir_clique(m)
	inv.pedir_clique(0)
	inv.pedir_clique(m)  # troca: a madeira que estava no 0 vai para onde estava o machado
	p.barra_escolhida = 0
	checar(inv.item_em(0) == &"machado_madeira" and p.poder_da_mao(&"machado") > 1.0, "machado na mão (poder %.1f)" % p.poder_da_mao(&"machado"))
	checar(p.poder_da_mao(&"picareta") == 1.0, "machado não ajuda a minerar")

	# Salvar e carregar.
	var salvo := inv.para_salvar()
	var antes := inv.itens()
	inv.definir([])
	checar(inv.itens().is_empty(), "limpou")
	inv.definir(salvo)
	checar(inv.itens() == antes and inv.item_em(0) == &"machado_madeira", "salvar e carregar mantém tudo no lugar")
	inv.definir({"madeira": 5, "pedra": 3})
	checar(inv.quantidade_de(&"madeira") == 5 and inv.quantidade_de(&"pedra") == 3, "lê o formato antigo do mundo salvo")
	terminar()


func _espaco_de(inv: Inventory, id: StringName) -> int:
	for i in Inventory.GUARDAR:
		if inv.item_em(i) == id:
			return i
	return -1


## Põe 1 item em cada espaço da grade (pegando da mochila com clique direito).
func _montar(inv: Inventory, grade: Dictionary) -> void:
	for e in grade:
		var de := _espaco_de(inv, grade[e])
		if de < 0:
			inv.adicionar(grade[e], 1)
			de = _espaco_de(inv, grade[e])
		inv.pedir_clique(de)  # pega a pilha
		inv.pedir_clique(e, true)  # põe 1
		inv.pedir_clique(de)  # devolve o resto
