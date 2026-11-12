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
	terminar()
