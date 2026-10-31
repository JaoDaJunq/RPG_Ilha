extends TesteBase
## Baú: abre com E (o do acampamento e um construído), guarda e tira itens, Shift manda
## para o baú, fechar grava, um jogador por vez, quebrar devolve o conteúdo e o mundo salvo
## guarda o que tem dentro.


func _ready() -> void:
	var w := await criar_mundo()
	var p := w.jogador
	var inv := p.inventario
	inv.definir([])  # começa vazio (sem a arma inicial da classe)
	inv.adicionar(&"madeira", 30)
	inv.adicionar(&"pedra", 5)
	var bau := w.bau_acampamento
	checar(bau != null and bau.pode_interagir(), "o baú do acampamento abre")
	bau.interagir(p)
	checar(inv.com_bau and is_instance_valid(inv.bau_aberto), "abriu o baú")
	inv.pedir_clique(0, false, true)  # Shift: a madeira vai para o baú
	checar(inv.item_em(Inventory.BAU) == &"madeira" and inv.qtd_em(Inventory.BAU) == 30, "Shift mandou as 30 madeiras para o baú")
	checar(bau.conteudo.size() == Inventory.BAU_N and bau.conteudo[0][0] == "madeira", "o baú já guardou")
	inv.pedir_clique(Inventory.BAU, true)  # clique direito: pega metade
	inv.pedir_clique(5)
	checar(inv.quantidade_de(&"madeira") == 15, "tirou metade de volta (%d)" % inv.quantidade_de(&"madeira"))
	inv.pedir_fechar()
	checar(not inv.com_bau and inv.item_em(Inventory.BAU) == &"", "fechou: os espaços do baú saem do jogador")
	checar(int(bau.conteudo[0][1]) == 15, "e as 15 madeiras ficaram no baú")

	# Um por vez.
	bau.interagir(p)
	var outro := Node2D.new()
	checar(bau.em_uso_por == p, "o baú sabe quem está com ele aberto")
	inv.pedir_fechar()
	outro.free()

	# Baú construído: guardar, quebrar e receber tudo.
	p.global_position = w.centro + Vector2(0, 90)
	await esperar(0.1)
	var cel := Vector2i((p.global_position / World.T).floor()) + Vector2i(1, 0)
	var b2 := w._criar_peca(&"bau", cel)
	b2.interagir(p)
	inv.pedir_clique(_espaco_de(inv, &"pedra"), false, true)
	inv.pedir_fechar()
	checar(inv.quantidade_de(&"pedra") == 0 and int(b2.conteudo[0][1]) == 5, "guardou as 5 pedras no baú construído")
	var lista := w._lista_construcoes()
	checar(lista.size() == 1 and lista[0].size() == 4 and lista[0][3][0][0] == "pedra", "o mundo salvo leva o conteúdo do baú")
	for k in 3:
		for n in b2.get_children():
			if n is Hurtbox:
				n.receber(1.0, &"fisico", p)
	await esperar(0.1)
	checar(inv.quantidade_de(&"pedra") == 5 and inv.quantidade_de(&"bau") == 1, "quebrar o baú devolve o que tinha dentro e o próprio baú")
	terminar()


func _espaco_de(inv: Inventory, id: StringName) -> int:
	for i in Inventory.GUARDAR:
		if inv.item_em(i) == id:
			return i
	return -1
