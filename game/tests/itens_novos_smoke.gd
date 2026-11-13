extends TesteBase
## Etapa 2 (L39): os itens novos existem e têm ícone; as receitas do livro fecham (todo
## ingrediente e resultado existe); frutinhas, conchas, cogumelos, ervas e capim se colhem e
## crescem de novo; as pedras com minério das Colinas e das Ruínas se mineram; o coqueiro dá
## coco; a fornalha derrete minério em barra (gastando carvão) e assa; a fogueira assa peixe;
## as poções de cura, mana e resistência funcionam; a vara pesca; as armas de classe de cobre
## e ferro aumentam o dano das habilidades.

const NOVOS := [&"frutinhas", &"coco", &"peixe", &"peixe_assado", &"cogumelo", &"sopa_cogumelo",
	&"carne_sapo", &"carne_sapo_assada", &"espetinho_cogumelo", &"frutinhas_assadas", &"leite",
	&"concha", &"erva", &"fibra", &"corda", &"pinca_caranguejo", &"la", &"osso", &"minerio_cobre",
	&"minerio_ferro", &"cristal", &"barra_cobre", &"barra_ferro", &"fornalha", &"machado_cobre",
	&"machado_ferro", &"picareta_cobre", &"picareta_ferro", &"vara_pescar", &"espada_cobre",
	&"espada_ferro_forjada", &"cajado_cobre", &"cajado_ferro", &"arco_cobre", &"arco_ferro",
	&"adagas_cobre", &"adagas_ferro", &"maca_cobre", &"maca_ferro", &"pocao_cura", &"pocao_mana",
	&"pocao_resistencia"]

var w: World
var p: Player


func _ready() -> void:
	# Os itens e as receitas.
	var sem_icone := NOVOS.filter(func(id: StringName) -> bool: return not ItemData.existe(id) or ItemData.carregar(id).icone == null)
	checar(sem_icone.is_empty(), "os %d itens novos existem e têm ícone %s" % [NOVOS.size(), sem_icone])
	var quebradas := []
	for r in ReceitaData.todas():
		var usados: Array = r.ingredientes.duplicate() if r.sem_forma else r.chave.values()
		usados.append(r.resultado)
		for id in usados:
			if not ItemData.existe(id):
				quebradas.append("%s (%s)" % [r.resultado, id])
	checar(quebradas.is_empty(), "todas as receitas do livro usam itens que existem %s" % [quebradas])
	var com_receita := {}
	for r in ReceitaData.todas():
		com_receita[r.resultado] = true
	var faltam := [&"corda", &"vara_pescar", &"fornalha", &"machado_cobre", &"picareta_ferro", &"espada_cobre",
		&"cajado_ferro", &"arco_cobre", &"adagas_ferro", &"maca_cobre", &"pocao_cura", &"pocao_mana",
		&"pocao_resistencia", &"sopa_cogumelo", &"espetinho_cogumelo"].filter(func(id: StringName) -> bool: return not com_receita.has(id))
	checar(faltam.is_empty(), "as receitas novas estão no livro %s" % [faltam])
	var g2: Array[StringName] = [&"fibra", &"fibra", &"fibra", &""]
	checar(ReceitaData.encontrar(g2, 2) != null and ReceitaData.encontrar(g2, 2).resultado == &"corda", "3 fibras fazem corda")
	var g3: Array[StringName] = [&"pedra", &"pedra", &"pedra", &"pedra", &"", &"pedra", &"pedra", &"pedra", &"pedra"]
	checar(ReceitaData.encontrar(g3, 3) != null and ReceitaData.encontrar(g3, 3).resultado == &"fornalha", "8 pedras em volta fazem a fornalha (na bancada)")

	w = await criar_mundo(0, false, &"guerreiro")
	p = w.jogador
	await _coletaveis()
	await _minerios()
	await _fornalha()
	await _consumiveis()
	await _pesca()
	terminar()


func _recursos(filtro: Callable) -> Array:
	return get_tree().get_nodes_in_group(&"recursos").filter(filtro)


func _coletaveis() -> void:
	for par in [[&"frutinhas", Regioes.Id.BOSQUE], [&"concha", Regioes.Id.PRAIA], [&"erva", -1], [&"fibra", -1], [&"cogumelo", -1]]:
		var item: StringName = par[0]
		var lista := _recursos(func(r: ResourceNode) -> bool: return String(r.name).begins_with("Coleta") and r.item_id == item)
		checar(lista.size() > 0, "há %s para colher pela ilha (%d)" % [item, lista.size()])
		if lista.is_empty():
			continue
		var c: ResourceNode = lista[0]
		if par[1] >= 0:
			checar(lista.all(func(r: Node2D) -> bool: return w.regiao_em(r.global_position) == par[1]), "%s só na região dele" % item)
		var antes := p.inventario.quantidade_de(item)
		c.interagir(p)
		checar(p.inventario.quantidade_de(item) > antes and c.estado == ResourceNode.Estado.ESGOTADO, "colher dá %s (%d)" % [item, p.inventario.quantidade_de(item) - antes])
		if item == &"frutinhas":
			checar(c.sprite.visible and c.textura_esgotado != null, "o arbusto colhido fica sem frutinhas")
		elif item == &"concha":
			checar(not c.sprite.visible, "a concha pega some do chão")
		p.global_position = w.centro  # longe, para crescer de novo
		w.rebrotar_ja(String(c.name))
		await esperar(1.2)
		checar(c.estado == ResourceNode.Estado.INTEIRO and c.sprite.visible, "%s cresce de novo" % item)
	# O coqueiro dá coco junto com a madeira.
	var coqueiros := _recursos(func(r: ResourceNode) -> bool: return r.extra_id == &"coco")
	checar(coqueiros.size() > 0, "os coqueiros dão coco (%d)" % coqueiros.size())
	if coqueiros.size() > 0:
		var cq: ResourceNode = coqueiros[0]
		for k in cq.golpes:
			cq.interagir(p)
		checar(p.inventario.quantidade_de(&"coco") >= 1, "cortar o coqueiro dá coco")


func _minerios() -> void:
	for par in [[&"minerio_cobre", Regioes.Id.COLINAS], [&"minerio_ferro", -1], [&"cristal", -1]]:
		var item: StringName = par[0]
		var lista := _recursos(func(r: ResourceNode) -> bool: return r.has_meta(&"minerio") and r.item_id == item)
		checar(lista.size() > 0, "há pedras com %s (%d)" % [item, lista.size()])
		if lista.is_empty():
			continue
		var regioes := {}
		for r in lista:
			regioes[w.regiao_em(r.global_position)] = true
		checar(regioes.keys().all(func(r: int) -> bool: return r in [Regioes.Id.COLINAS, Regioes.Id.RUINAS]), "%s só nas Colinas e nas Ruínas" % item)
		var m: ResourceNode = lista[0]
		checar(m.acao == "Minerar", "minera com a picareta")
		var antes := p.inventario.quantidade_de(item)
		for k in m.golpes:
			m.interagir(p)
		checar(p.inventario.quantidade_de(item) > antes and is_instance_valid(m) and m.estado == ResourceNode.Estado.ESGOTADO, "minerar dá %s e sobram pedrinhas (que voltam)" % item)


func _na_mao(id: StringName, qtd := 1) -> void:
	if p.inventario.quantidade_de(id) < qtd:
		p.inventario.adicionar(id, qtd - p.inventario.quantidade_de(id))
	for k in Inventory.BARRA:
		if p.inventario.item_em(k) == id:
			p.barra_escolhida = k
			return
	checar(false, "%s não coube na barra" % id)


func _fornalha() -> void:
	p.inventario.definir([])
	p.inventario.adicionar(&"fornalha", 1)
	var cel := Vector2i((w.centro / World.T).floor()) + Vector2i(4, 4)
	for k in 40:
		p.global_position = Vector2(cel * World.T) + Vector2(8, 30)  # o jogador do lado do tile
		await get_tree().physics_frame
		if w.pode_construir(&"fornalha", cel, p):
			break
		cel += Vector2i(1, 0)
	checar(w.pode_construir(&"fornalha", cel, p), "dá para pôr a fornalha")
	var f := w._criar_peca(&"fornalha", cel)
	checar(f != null and f.pode_interagir(), "a fornalha foi construída e dá para usar")
	_na_mao(&"minerio_cobre", 2)
	f.interagir(p)
	checar(p.inventario.quantidade_de(&"barra_cobre") == 0, "sem carvão nem madeira, não derrete")
	p.inventario.adicionar(&"carvao", 1)
	f.interagir(p)
	checar(p.inventario.quantidade_de(&"barra_cobre") == 1 and p.inventario.quantidade_de(&"carvao") == 0 and p.inventario.quantidade_de(&"minerio_cobre") == 1, "minério de cobre + carvão viram barra de cobre")
	checar(f.acesa(), "a fornalha acende")
	p.inventario.adicionar(&"madeira", 1)
	_na_mao(&"minerio_ferro", 1)
	f.interagir(p)
	checar(p.inventario.quantidade_de(&"barra_ferro") == 1, "minério de ferro vira barra de ferro (com madeira)")
	_na_mao(&"peixe", 1)
	f.interagir(p)
	checar(p.inventario.quantidade_de(&"peixe_assado") == 1, "a fornalha também assa o peixe")
	# A fogueira assa peixe e carne de sapo.
	var fog := w.entidades.get_node("FogueiraAcampamento") as Construcao
	_na_mao(&"carne_sapo", 1)
	fog.interagir(p)
	checar(p.inventario.quantidade_de(&"carne_sapo_assada") == 1, "a fogueira assa a carne de sapo")


func _consumiveis() -> void:
	# Cura.
	p.vida.tomar_dano(70.0, &"fisico")
	await esperar(0.3)
	var v := p.vida.atual
	_na_mao(&"pocao_cura")
	p._pedir_usar(p.barra_escolhida)
	checar(p.vida.atual > v + 50.0, "a poção de cura cura muito (%.0f -> %.0f)" % [v, p.vida.atual])
	# Mana.
	p.mana = 0.0
	_na_mao(&"pocao_mana")
	p._pedir_usar(p.barra_escolhida)
	checar(p.mana >= minf(40.0, p.ficha.mana_maxima()) and p.inventario.quantidade_de(&"pocao_mana") == 0, "a poção de mana devolve mana (%.0f)" % p.mana)
	# Resistência.
	_na_mao(&"pocao_resistencia")
	p._pedir_usar(p.barra_escolhida)
	await get_tree().physics_frame
	p.vida.curar_tudo()
	await esperar(0.3)
	var antes := p.vida.atual
	p.vida.tomar_dano(20.0, &"fisico")  # o ajuste do Player passa pelos buffs (Passivas.dano_recebido)
	checar(p.inventario.quantidade_de(&"pocao_resistencia") == 0 and antes - p.vida.atual < 20.0, "a poção de resistência diminui o dano (%.1f de 20)" % (antes - p.vida.atual))
	# Comida nova cura.
	p.vida.tomar_dano(40.0, &"fisico")
	await esperar(0.3)
	v = p.vida.atual
	_na_mao(&"sopa_cogumelo")
	p._pedir_usar(p.barra_escolhida)
	checar(p.vida.atual > v, "a sopa de cogumelo cura")
	# Arma de classe: o Guerreiro com a espada de cobre na barra bate mais forte nas habilidades.
	var hab: HabilidadeData = p.ficha.classe.habilidades[0]
	var sem := HabilidadeLogica.dano_de(p, hab)
	_na_mao(&"espada_cobre")
	var com := HabilidadeLogica.dano_de(p, hab)
	_na_mao(&"espada_ferro_forjada")
	var com_ferro := HabilidadeLogica.dano_de(p, hab)
	checar(com > sem * 1.15 and com_ferro > com, "armas de cobre e ferro aumentam o dano (%.1f, %.1f, %.1f)" % [sem, com, com_ferro])
	checar(UsoItens.visual_mao(&"arco_ferro") == &"arco" and UsoItens.visual_mao(&"cajado_cobre") == &"cajado", "na mão vai o desenho da arma base")
	_na_mao(&"cajado_ferro")
	checar(UsoItens.bonus_arma(p) == 1.4, "arma de outra classe não conta: vale a espada de ferro")


func _pesca() -> void:
	var beira := Vector2.INF
	for cel in w.celulas_da_regiao(Regioes.Id.PRAIA):
		var pos := Vector2(cel * World.T) + Vector2(8, 8)
		if UsoItens.agua_perto(w, pos) != Vector2.INF:
			beira = pos
			break
	checar(beira != Vector2.INF, "há beira de água na praia")
	p.inventario.definir([])
	_na_mao(&"vara_pescar")
	p.global_position = w.centro + Vector2(0, 40)
	await get_tree().physics_frame
	checar(UsoItens.pescar(p) == Vector2.INF, "longe da água, não pesca")
	p.global_position = beira
	await get_tree().physics_frame
	var antes := p.inventario.quantidade_de(&"peixe") + p.inventario.quantidade_de(&"concha")
	p._pedir_usar(p.barra_escolhida)
	checar(p.has_meta(&"pescando"), "na beira da água, joga a linha")
	await esperar(UsoItens.ESPERA_PEIXE.y + 0.3)
	checar(p.inventario.quantidade_de(&"peixe") + p.inventario.quantidade_de(&"concha") > antes, "e pesca um peixe")
	checar(get_tree().get_nodes_in_group(&"pontos_pesca").size() > 0, "há pontos de pesca (ondinhas) na água")
