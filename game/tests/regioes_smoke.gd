extends TesteBase
## O mundo grande (L36): 190 x 130 blocos, a Clareira no centro, as 6 regiões com o chão, a
## decoração e os recursos de cada uma, os caminhos ligando tudo, as passagens (abertas por
## enquanto, mas funcionando) e árvores e pedras que crescem de novo.


func _ready() -> void:
	var w := await criar_mundo(0, false)
	var g := w.gerador
	checar(w.largura == 190 and w.altura == 130, "a ilha tem 190 x 130 blocos (%d x %d)" % [w.largura, w.altura])
	checar(w.regiao_em(w.centro) == Regioes.Id.CLAREIRA, "o acampamento fica na Clareira")
	checar(w.entidades.has_node("FogueiraAcampamento"), "a fogueira do acampamento está lá")

	# Cada região tem um bom pedaço de terra.
	var terra := 0
	for r in Regioes.TODAS:
		var n := w.celulas_da_regiao(r, true).size()
		terra += n
		checar(n >= 400, "%s tem terra (%d blocos)" % [Regioes.nome(r), n])
	checar(terra > 6 * 64 * 44 * 0.5, "a ilha é bem maior que a antiga (%d blocos de terra)" % terra)

	# A mesma semente dá a mesma ilha.
	var outro := GeradorIlha.new()
	outro.gerar(w.semente)
	checar(outro.tipo == g.tipo and outro.regiao == g.regiao and outro.piso == g.piso, "a mesma semente gera a mesma ilha")

	# O perigo cresce com a distância e com a região.
	var perigo := {}
	for r in Regioes.TODAS:
		var soma := 0.0
		var celulas := w.celulas_da_regiao(r)
		for k in range(0, celulas.size(), 7):
			soma += w.perigo_em(Vector2(celulas[k] * World.T))
		perigo[r] = soma / ceili(celulas.size() / 7.0)
	checar(perigo[Regioes.Id.CLAREIRA] == 0.0, "a Clareira é segura (perigo 0)")
	checar(perigo[Regioes.Id.BOSQUE] < perigo[Regioes.Id.PANTANO] and perigo[Regioes.Id.PANTANO] < perigo[Regioes.Id.COLINAS] and perigo[Regioes.Id.COLINAS] < perigo[Regioes.Id.RUINAS],
		"o perigo cresce: Bosque %.2f < Pântano %.2f < Colinas %.2f < Ruínas %.2f" % [perigo[Regioes.Id.BOSQUE], perigo[Regioes.Id.PANTANO], perigo[Regioes.Id.COLINAS], perigo[Regioes.Id.RUINAS]])

	# Chão próprio: lama no Pântano, piso de pedra nas Ruínas, areia na Praia, trilhas.
	var pisos := {}
	for i in g.piso.size():
		var chave := "%d_%d" % [g.regiao[i], g.piso[i]]
		pisos[chave] = pisos.get(chave, 0) + 1
	checar(pisos.get("%d_%d" % [Regioes.Id.PANTANO, GeradorIlha.Piso.LAMA], 0) > 300, "o Pântano tem lama")
	checar(pisos.get("%d_%d" % [Regioes.Id.RUINAS, GeradorIlha.Piso.PEDRA], 0) > 80, "as Ruínas têm piso de pedra antiga")
	var trilha := 0
	for r in Regioes.TODAS:
		var n: int = pisos.get("%d_%d" % [r, GeradorIlha.Piso.TRILHA], 0)
		trilha += n
		checar(n > 10, "tem trilha em %s (%d blocos)" % [Regioes.nome(r), n])

	# Decoração e recursos próprios de cada região.
	var assinatura := {
		Regioes.Id.PRAIA: "coqueiros.png", Regioes.Id.BOSQUE: "arvores.png", Regioes.Id.PANTANO: "pantano.png",
		Regioes.Id.COLINAS: "colinas_ruinas.png", Regioes.Id.RUINAS: "ruinas_altas.png",
	}
	var achou := {}
	var por_regiao := {}
	for n in _todos(w):
		var s := n as Sprite2D
		if s == null or s.texture == null:
			continue
		var pos := s.global_position
		var r := w.regiao_em(pos)
		por_regiao[r] = por_regiao.get(r, 0) + 1
		if assinatura.has(r) and s.texture.resource_path.ends_with(assinatura[r]):
			achou[r] = true
	for r in assinatura:
		checar(achou.has(r), "%s tem a decoração dela (%s)" % [Regioes.nome(r), assinatura[r]])
	for r in Regioes.TODAS:
		checar(por_regiao.get(r, 0) > 40, "%s é bem decorada (%d peças)" % [Regioes.nome(r), por_regiao.get(r, 0)])
	var arvores := 0
	var pedras := 0
	for n in get_tree().get_nodes_in_group(&"recursos"):
		if (n as ResourceNode).acao == "Cortar":
			arvores += 1
		else:
			pedras += 1
	checar(arvores >= 350 and pedras >= 60, "árvores (%d) e pedras (%d) espalhadas" % [arvores, pedras])

	# Os caminhos ligam a Clareira a todas as regiões (passagens abertas).
	var alcance := _alcance(w)
	for r in Regioes.TODAS:
		checar(_alcanca_regiao(w, alcance, r), "dá para ir a pé da Clareira até %s" % Regioes.nome(r))
	# Fechadas, o norte (Colinas e Ruínas) fica isolado, e o resto continua ligado.
	w.abrir_passagem(World.PONTE, false)
	w.abrir_passagem(World.RAIZES, false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	checar(not w.passagem(World.PONTE).aberta and not w.passagem(World.RAIZES).aberta, "as passagens fecham (a ponte quebra e as raízes crescem)")
	alcance = _alcance(w)
	checar(not _alcanca_regiao(w, alcance, Regioes.Id.COLINAS) and not _alcanca_regiao(w, alcance, Regioes.Id.RUINAS), "fechadas, Colinas e Ruínas ficam do outro lado do rio")
	checar(_alcanca_regiao(w, alcance, Regioes.Id.PANTANO) and _alcanca_regiao(w, alcance, Regioes.Id.PRAIA) and _alcanca_regiao(w, alcance, Regioes.Id.BOSQUE), "e o resto da ilha continua ligado")
	# A muralha de raízes bloqueia de verdade.
	var p := w.jogador
	var vau := Vector2(GeradorIlha.VAU * World.T) + Vector2(8, 8)
	p.global_position = vau + Vector2(0, 40)
	p.camera.reset_smoothing()
	await get_tree().physics_frame
	Input.action_press(&"mover_cima")
	await esperar(1.5)
	Input.action_release(&"mover_cima")
	checar(p.global_position.y > vau.y, "as raízes fechadas não deixam passar (y %.0f, raízes em %.0f)" % [p.global_position.y, vau.y])
	w.abrir_passagem(World.RAIZES)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_press(&"mover_cima")
	await esperar(1.5)
	Input.action_release(&"mover_cima")
	checar(p.global_position.y < vau.y - 16, "abertas, dá para passar (y %.0f)" % p.global_position.y)
	w.abrir_passagem(World.PONTE)
	await get_tree().physics_frame
	checar(w.passagem(World.PONTE).aberta and w.chao.get_cell_atlas_coords(g.celulas_ponte[0]) == World.TILE_CHAO, "a ponte aberta deixa passar por cima do rio")

	# Árvores e pedras crescem de novo (com ninguém por perto).
	p.global_position = w.centro + Vector2(0, 60)
	var arvore: ResourceNode = null
	var pedra: ResourceNode = null
	for n in get_tree().get_nodes_in_group(&"recursos"):
		var rn := n as ResourceNode
		if rn.global_position.distance_to(p.global_position) > 400.0:
			if rn.acao == "Cortar" and arvore == null:
				arvore = rn
			elif rn.acao == "Minerar" and pedra == null:
				pedra = rn
	for i in arvore.golpes:
		arvore.interagir(p)
	var nome_pedra := String(pedra.name)
	for i in pedra.golpes:
		pedra.interagir(p)
	await get_tree().physics_frame
	checar(arvore.estado == ResourceNode.Estado.ESGOTADO and not w.entidades.has_node(nome_pedra), "cortou a árvore e minerou a pedra")
	checar(w._rebrotar.get(String(arvore.name), 0.0) > 60.0 and w._rebrotar.get(nome_pedra, 0.0) > 60.0, "elas voltam devagar (minutos)")
	w.rebrotar_ja(String(arvore.name))
	w.rebrotar_ja(nome_pedra)
	await esperar(0.3)
	checar(arvore.estado == ResourceNode.Estado.INTEIRO and arvore.golpes_restantes() == arvore.golpes, "o toco virou árvore de novo")
	checar(w.entidades.has_node(nome_pedra), "a pedra voltou no mesmo lugar")
	terminar()


func _todos(w: World) -> Array:
	var lista: Array = []
	for pai in [w.entidades, w.get_node("DecoracaoChao")]:
		for n in pai.get_children():
			lista.append(n)
			for f in n.get_children():
				if f is Sprite2D:
					lista.append(f)
	return lista


## Blocos alcançáveis a pé a partir do acampamento (pela colisão do chão: água e ponte),
## sem passar pelas raízes fechadas.
func _alcance(w: World) -> Dictionary:
	var visto := {}
	var inicio := GeradorIlha.CENTRO + Vector2i(0, 3)
	var fila: Array[Vector2i] = [inicio]
	visto[inicio] = true
	var raizes := w.passagem(World.RAIZES)
	while not fila.is_empty():
		var c: Vector2i = fila.pop_back()
		for v in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var o: Vector2i = c + v
			if visto.has(o) or not w.gerador.dentro(o):
				continue
			if w.chao.get_cell_atlas_coords(o) != World.TILE_CHAO:
				continue
			if not raizes.aberta and o in w.gerador.celulas_vau:
				continue
			visto[o] = true
			fila.append(o)
	return visto


func _alcanca_regiao(w: World, alcance: Dictionary, r: int) -> bool:
	var n := 0
	for c in alcance:
		if w.gerador.regiao_em(c) == r:
			n += 1
	return n > 100
