extends TesteBase
## As mecânicas que faltavam na árvore: acerto crítico (Sangue frio, Tiro carregado cheio),
## Molhado (água, gelo derretido, Queimadura, Condução), baú trancado (Dedos leves ou
## golpes), Faísca (fogueira sem graveto), dar comida (Luz própria), Despertar da ilha
## (pedras) e Amanhecer (cura).

const SLIME := preload("res://scenes/enemies/slime.tscn")
const JOGADOR := preload("res://scenes/player/player.tscn")
const PEDRA := preload("res://scenes/world/pedra.tscn")

var w: World
var p: Player


func _ready() -> void:
	w = await criar_mundo(0, true, &"arqueiro")
	p = w.jogador
	p.global_position = w.centro + Vector2(0, 60)
	await get_tree().physics_frame
	await _critico()
	await _molhado()
	await _bau_trancado()
	_faisca()
	await _comida()
	await _despertar_e_amanhecer()
	Passivas.chance_critico = -1.0
	terminar()


func _slime(pos: Vector2) -> Slime:
	var s: Slime = colocar(w, SLIME, pos)
	s.set_physics_process(false)
	s.raio_visao = 0.0
	s.vida.maximo = 500.0
	s.vida.atual = 500.0
	s.vida.invulneravel_por = 0.0
	return s


func _tira(s: Slime, dano: float) -> float:
	var antes := s.vida.atual
	Golpes.acertar(p, s, dano, &"fisico")
	return antes - s.vida.atual


func _critico() -> void:
	var s := _slime(p.global_position + Vector2(30, 0))
	await get_tree().physics_frame
	checar(Passivas._chance_critico(p) == 0.0, "nas cenas de teste o crítico aleatório fica desligado (números exatos)")
	Passivas.chance_critico = 0.0
	var normal := _tira(s, 1.0)
	Passivas.chance_critico = 1.0
	var criticos := int(p.get_meta(&"criticos", 0))
	var forte := _tira(s, 1.0)
	checar(normal > 0.0 and is_equal_approx(forte, normal * Passivas.CRITICO), "crítico: dano x2 (%.2f contra %.2f)" % [forte, normal])
	checar(int(p.get_meta(&"criticos", 0)) == criticos + 1, "o crítico fica registrado (e o brilho do golpe aparece para todos)")
	Passivas.chance_critico = 0.0
	Passivas.forcar_critico(p)
	checar(is_equal_approx(_tira(s, 1.0), normal * 2.0) and is_equal_approx(_tira(s, 1.0), normal), "crítico garantido (Emboscada, Esquiva perfeita): só o próximo golpe")
	# Árvore e baú não dão crítico (só inimigos e animais).
	Passivas.chance_critico = 1.0
	criticos = int(p.get_meta(&"criticos", 0))
	var b := BauTrancado.new()
	b.position = p.global_position + Vector2(0, 40)
	w.entidades.add_child(b)
	Golpes.acertar(p, b, 1.0, &"fisico")
	checar(int(p.get_meta(&"criticos", 0)) == criticos, "golpe num baú não conta como crítico")
	b.queue_free()
	Passivas.chance_critico = 0.0

	# Sangue frio: cada crítico devolve 3 de mana.
	p.aprender_de_graca(&"sangue_frio")
	p.mana = 10.0
	Passivas.forcar_critico(p)
	_tira(s, 1.0)
	checar(p.mana >= 10.0 + PassivasArqueiro.SANGUE_FRIO_MANA - 0.01, "Sangue frio: o crítico devolveu mana (%.1f)" % p.mana)
	p.mana = 10.0
	await get_tree().create_timer(0.3).timeout
	var antes := p.mana
	_tira(s, 1.0)
	checar(p.mana < antes + 1.0, "Sangue frio: golpe sem crítico não devolve mana")

	# Tiro carregado com a carga cheia é crítico; sem carga, não.
	for carga in [0.0, 1.0]:
		p._recargas.clear()
		p._prontas_no_anfitriao.clear()
		p.mana = p.ficha.mana_maxima()
		p.mira_forcada = s.global_position + Vector2(0, -6)
		criticos = int(p.get_meta(&"criticos", 0))
		p.usar_habilidade_por_id(&"tiro_carregado", carga)
		await esperar(0.5)
		var deu := int(p.get_meta(&"criticos", 0)) > criticos
		checar(deu == (carga >= 1.0), "Tiro carregado com carga %.0f%%: %s" % [carga * 100.0, "crítico" if deu else "normal"])
	s.queue_free()
	await get_tree().physics_frame


func _celula_de_agua() -> Vector2:
	for cel in w._tipo:
		if w._tipo[cel] == World.Chao.AGUA:
			var pos := w.chao.to_global(w.chao.map_to_local(cel))
			var vizinhos_agua := true
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				vizinhos_agua = vizinhos_agua and w.tipo_do_chao(cel + d) == World.Chao.AGUA
			if vizinhos_agua:
				return pos
	return Vector2.INF


func _molhado() -> void:
	var agua := _celula_de_agua()
	checar(agua != Vector2.INF, "achou água no mapa")
	var s := _slime(agua)
	await esperar(0.5)
	checar(s.efeitos.tem(EfeitosEstado.MOLHADO), "na água o slime fica Molhado")
	s.global_position = p.global_position + Vector2(40, 0)
	await esperar(0.5)
	checar(s.efeitos.tem(EfeitosEstado.MOLHADO) and LogicasMago.molhado(s), "fora da água continua Molhado por um tempo (a Condução salta mais nele)")
	EfeitosEstado.aplicar_em(s, EfeitosEstado.QUEIMADURA, 4.0, 1.0, p)
	checar(not s.efeitos.tem(EfeitosEstado.QUEIMADURA) and not s.efeitos.tem(EfeitosEstado.MOLHADO), "Molhado: a Queimadura não pega (o fogo só seca)")
	EfeitosEstado.aplicar_em(s, EfeitosEstado.QUEIMADURA, 4.0, 1.0, p)
	checar(s.efeitos.tem(EfeitosEstado.QUEIMADURA), "seco, a Queimadura pega")
	EfeitosEstado.aplicar_em(s, EfeitosEstado.MOLHADO, EfeitosEstado.MOLHADO_SEGUNDOS)
	checar(not s.efeitos.tem(EfeitosEstado.QUEIMADURA), "ficar Molhado apaga a Queimadura")
	await esperar(EfeitosEstado.MOLHADO_SEGUNDOS + 0.2)
	checar(not s.efeitos.tem(EfeitosEstado.MOLHADO) and not LogicasMago.molhado(s), "o Molhado seca sozinho")
	# Gelo derretido: o fogo num congelado deixa Molhado.
	EfeitosEstado.aplicar_em(s, EfeitosEstado.CONGELADO, 3.0)
	Golpes.acertar(p, s, 0.1, &"fogo")
	checar(not s.efeitos.tem(EfeitosEstado.CONGELADO) and s.efeitos.tem(EfeitosEstado.MOLHADO), "fogo no congelado: o gelo derrete e ele fica Molhado")
	s.queue_free()
	await get_tree().physics_frame


func _bau_trancado() -> void:
	var b := BauTrancado.new()
	b.name = "BauTeste1"
	b.position = p.global_position + Vector2(24, 0)
	w.entidades.add_child(b)
	await get_tree().physics_frame
	var itens := get_tree().get_nodes_in_group(&"itens_chao").size()
	b.interagir(p)
	checar(is_instance_valid(b) and b.pode_interagir() and get_tree().get_nodes_in_group(&"itens_chao").size() == itens, "sem Dedos leves, o baú trancado não abre")
	for k in BauTrancado.GOLPES_QUEBRAR - 1:
		Golpes.acertar(p, b, 1.0, &"fisico")
	checar(is_instance_valid(b) and b.golpes_restantes() == 1, "cada golpe estraga a tranca (falta 1)")
	Golpes.acertar(p, b, 1.0, &"fisico")
	await get_tree().physics_frame
	checar(not is_instance_valid(b) and get_tree().get_nodes_in_group(&"itens_chao").size() > itens, "a tranca quebrou: o saque caiu no chão e o baú sumiu")
	checar("BauTeste1" in w._removidos, "o baú aberto fica registrado (não volta ao carregar o mundo)")
	# Ladino com Dedos leves: abre na hora.
	var b2 := BauTrancado.new()
	b2.name = "BauTeste2"
	b2.position = p.global_position + Vector2(-24, 0)
	w.entidades.add_child(b2)
	await get_tree().physics_frame
	itens = get_tree().get_nodes_in_group(&"itens_chao").size()
	p.arvore[&"dedos_leves"] = 1
	b2.interagir(p)
	await get_tree().physics_frame
	checar(not is_instance_valid(b2) and get_tree().get_nodes_in_group(&"itens_chao").size() > itens, "Dedos leves: o baú trancado abre na hora")
	p.arvore.erase(&"dedos_leves")
	await pegar_do_chao(p)
	p.global_position = w.centro + Vector2(0, 60)
	# O mundo espalha os baús (iguais em todos, longe da fogueira).
	var antes := get_tree().get_nodes_in_group(&"baus_trancados").size()
	w.gerar_recursos = true
	w._espalhar_baus(_celulas_grama())
	w.gerar_recursos = false
	var baus := get_tree().get_nodes_in_group(&"baus_trancados")
	var longe := true
	for x in baus:
		longe = longe and (x as Node2D).global_position.distance_to(w.centro) > 200.0
	checar(baus.size() - antes == w.baus_trancados and longe, "o mundo espalha %d baús trancados longe da fogueira" % (baus.size() - antes))
	for x in baus:
		x.queue_free()


func _celulas_grama() -> Array[Vector2i]:
	var l: Array[Vector2i] = []
	for cel in w._tipo:
		if w._tipo[cel] == World.Chao.GRAMA:
			l.append(cel)
	return l


## Monta a fogueira (2 gravetos + 2 pedras) e fabrica. Devolve quantos gravetos sobraram.
func _fabricar_fogueira(inv: Inventory) -> int:
	inv.pedir_fechar()
	inv.definir([])
	inv.adicionar(&"graveto", 2)
	inv.adicionar(&"pedra", 2)
	inv.pedir_receita(&"fogueira")
	inv.pedir_resultado(true)
	inv.pedir_fechar()
	return inv.quantidade_de(&"graveto") if inv.quantidade_de(&"fogueira") == 1 else -1


func _faisca() -> void:
	var inv := p.inventario
	checar(_fabricar_fogueira(inv) == 0, "sem Faísca, a fogueira gasta os 2 gravetos")
	p.arvore[&"faisca"] = 1
	checar(_fabricar_fogueira(inv) == 2, "Faísca: a fogueira sai sem gastar graveto")
	p.arvore.erase(&"faisca")
	inv.definir([])


func _comida() -> void:
	var aliado: Player = JOGADOR.instantiate()
	aliado.name = "2"
	aliado.classe = &"guerreiro"
	aliado.position = p.global_position + Vector2(24, 0)
	w.entidades.add_child(aliado)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var inv := p.inventario
	inv.definir([])
	inv.adicionar(&"carne_assada", 3)
	var espaco := -1
	for k in Inventory.BARRA:
		if inv.item_em(k) == &"carne_assada":
			espaco = k
	var cura := ItemData.carregar(&"carne_assada").cura
	p.vida.curar_tudo()
	# Ferido, você come; com a vida cheia, dá ao aliado ferido perto.
	aliado.vida.atual = aliado.vida.maximo - 60.0
	p._pedir_usar(espaco)
	checar(is_equal_approx(aliado.vida.atual, aliado.vida.maximo - 60.0 + cura) and inv.quantidade_de(&"carne_assada") == 2,
			"com a vida cheia, usar comida dá para o aliado ferido (+%.0f)" % cura)
	p.arvore[&"luz_propria"] = 1
	aliado.vida.atual = aliado.vida.maximo - 60.0
	p._pedir_usar(espaco)
	checar(is_equal_approx(aliado.vida.atual, aliado.vida.maximo - 60.0 + cura * PassivasClerigo.LUZ_PROPRIA_COMIDA),
			"Luz própria: a comida que você dá cura 50%% a mais (+%.0f)" % (cura * PassivasClerigo.LUZ_PROPRIA_COMIDA))
	p.vida.atual = p.vida.maximo - 60.0
	p._pedir_usar(espaco)
	checar(is_equal_approx(p.vida.atual, p.vida.maximo - 60.0 + cura), "comer a própria comida cura o normal (+%.0f)" % cura)
	p.arvore.erase(&"luz_propria")
	aliado.vida.curar_tudo()
	p.vida.curar_tudo()
	aliado.queue_free()
	await get_tree().physics_frame


func _despertar_e_amanhecer() -> void:
	var pedra: ResourceNode = colocar(w, PEDRA, p.global_position + Vector2(40, 0))
	await get_tree().physics_frame
	var antes := p.inventario.quantidade_de(&"pedra")
	var partidas := LogicasMago.DespertarDaIlha.partir_pedras(p, p.global_position, LogicasMago.DespertarDaIlha.RAIO)
	await get_tree().physics_frame
	checar(partidas == 1 and p.inventario.quantidade_de(&"pedra") > antes, "Despertar da ilha: as pedras em volta se partem e as pedras vão para a mochila (+%d)" % (p.inventario.quantidade_de(&"pedra") - antes))
	if is_instance_valid(pedra):
		pedra.queue_free()
	# Amanhecer: os aliados dentro da luz se curam.
	var hab := ArvoreData.no(&"clerigo", &"amanhecer").habilidade
	p.vida.atual = p.vida.maximo - 30.0
	var vida := p.vida.atual
	(Logicas.classe_da_logica(hab.logica).new() as HabilidadeLogica).executar(p, hab, Vector2.RIGHT, p.global_position, 0.0)
	await esperar(2.2)
	checar(p.vida.atual > vida, "Amanhecer: quem está na luz se cura (%.1f → %.1f)" % [vida, p.vida.atual])
