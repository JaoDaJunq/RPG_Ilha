extends TesteBase
## Sprite completo (L30/L31): os personagens das 4 raças usam a tira de 6 quadros nas 3 vistas,
## trocam de quadro andando e no golpe, e o item fica na mão marcada em maos.json.


func _ready() -> void:
	for raca in [&"humano", &"ogro", &"elfo", &"anao"]:
		var b := Boneco.new()
		add_child(b)
		b.vestir({"raca": raca, "pele": 0, "classe": &"guerreiro"}, {})
		checar(b._completo != null, "%s guerreiro usa o sprite completo" % raca)
		b.item = &"espada_ferro"
		b.play(&"parado_direita")
		await get_tree().process_frame
		await get_tree().process_frame
		checar(b.quadro_atual() in [0, 1], "%s parado mostra o quadro parado/respirando" % raca)
		var mao: Vector2 = b._maos[""][b.quadro_atual()] - Boneco.PES_COMPLETO
		checar(b._item.visible and b._item.position.distance_to(mao) < 0.5, "%s: o item fica na mão da frente" % raca)
		b.play(&"andar_baixo")
		var vistos := {}
		for i in 12:
			await esperar(0.05)
			vistos[b.quadro_atual()] = true
		checar(vistos.has(2) and vistos.has(3) and b._completo.texture == b._tiras["_frente"], "%s andando para baixo usa a vista de frente e os 2 passos" % raca)
		b.play(&"andar_cima")
		await esperar(0.05)
		checar(b._completo.texture == b._tiras["_costas"] and b._item.get_index() < b._completo.get_index(), "%s de costas: arma atrás do corpo" % raca)
		b.play(&"andar_esquerda")
		await esperar(0.05)
		checar(b.scale.x < 0.0, "%s olhando para a esquerda é o perfil espelhado" % raca)
		b.play(&"golpe_direita")
		var golpe := {}
		for i in 8:
			await esperar(0.04)
			golpe[b.quadro_atual()] = true
		checar(golpe.has(4) and golpe.has(5), "%s no golpe passa pela preparação e pelo ataque" % raca)
		checar(Boneco.retrato({"raca": raca, "classe": &"guerreiro"}, {}) != null, "%s tem retrato" % raca)
		b.queue_free()
	# Todas as 20 combinações de raça e classe usam o sprite completo, com 6 mãos por vista.
	for raca in RacaData.TODAS:
		for classe in ClasseData.TODAS:
			var m := Boneco.new()
			m.vestir({"raca": raca, "pele": 0, "classe": classe}, {})
			var ok := m._completo != null
			for v in ["", "_frente", "_costas"]:
				ok = ok and m._maos.get(v, []).size() == 6
			checar(ok, "%s %s usa o sprite completo nas 3 vistas" % [raca, classe])
			m.free()
	await _armas_l37()
	terminar()


## L37: armas com desenho próprio na mão, as 2 adagas do Ladino e o arco puxando em cada vista.
func _armas_l37() -> void:
	var g := Boneco.new()
	add_child(g)
	g.vestir({"raca": &"humano", "pele": 0, "classe": &"guerreiro"}, {})
	for arma in [&"espada_ferro", &"cajado", &"maca"]:
		g.item = arma
		await get_tree().process_frame
		await get_tree().process_frame
		checar(g._item.visible and g._item.texture == Boneco.ARMAS_MAO[arma][0], "%s usa o desenho da mão (não o ícone)" % arma)
	g.queue_free()
	for raca in RacaData.TODAS:
		var l := Boneco.new()
		add_child(l)
		l.vestir({"raca": raca, "pele": 0, "classe": &"ladino"}, {})
		l.item = &"adagas"
		for v in [["parado_direita", ""], ["parado_baixo", "_frente"], ["parado_cima", "_costas"]]:
			l.play(StringName(v[0]))
			await get_tree().process_frame
			var q := l.quadro_atual()
			var tras: Vector2 = l._maos_tras[v[1]][q] - Boneco.PES_COMPLETO
			var frente: Vector2 = l._maos[v[1]][q] - Boneco.PES_COMPLETO
			checar(l._item.visible and l._item_tras.visible and l._item.texture == Boneco.ADAGA_MAO and l._item_tras.texture == Boneco.ADAGA_MAO,
				"%s ladino%s: uma adaga em cada mão" % [raca, v[1]])
			checar(l._item_tras.position.distance_to(tras) < 0.5 and frente.distance_to(tras) > 10.0,
				"%s ladino%s: a 2ª adaga fica na mão de trás marcada" % [raca, v[1]])
		l.queue_free()
	var a := Boneco.new()
	add_child(a)
	a.vestir({"raca": &"humano", "pele": 0, "classe": &"arqueiro"}, {})
	a.item = &"arco"
	for v in [["parado_direita", ""], ["parado_baixo", "_frente"], ["parado_cima", "_costas"]]:
		a.play(StringName(v[0]))
		a.carga = -1.0
		await get_tree().process_frame
		checar(a._item.texture == Boneco.ARCO_VISTAS[""] and a._item.region_rect.position.x == 0.0, "arco%s sem puxar: em pé, em repouso" % v[1])
		var quadros := []
		for c in [0.1, 0.5, 0.9]:
			a.carga = c
			await get_tree().process_frame
			quadros.append(int(a._item.region_rect.position.x / Boneco.QUADRO_ARCO))
		checar(a._item.texture == Boneco.ARCO_VISTAS[v[1]] and quadros == [1, 2, 3], "arco%s puxando: a tira da vista, 3 tempos (%s)" % [v[1], quadros])
	a.queue_free()
