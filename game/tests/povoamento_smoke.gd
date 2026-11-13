extends TesteBase
## Spawn por região (Povoamento): cada região enche até o limite com os bichos da tabela dela;
## nada nasce na tela do jogador nem perto da fogueira; morto, volta depois de um tempo; o
## limite cresce com os jogadores; à noite vêm as criaturas da noite; e longe é mais difícil.


func _ready() -> void:
	var w := await criar_mundo(0, false)
	var pv := w.povoamento
	var p := w.jogador
	checar(pv != null, "o mundo tem o Povoamento")

	# Cheio até o limite, com as espécies da tabela de cada região.
	for r in Regioes.TODAS:
		var lim := Regioes.limite(r, 1, false)
		var quem := _da_regiao(r, false)
		checar(quem.size() == lim, "%s tem %d bichos (limite %d)" % [Regioes.nome(r), quem.size(), lim])
		var tabela := {}
		for e in Regioes.dados(r)["dia"]:
			tabela[_especie_de(String(e[0]))] = true
		var certos := quem.all(func(n: Node) -> bool: return tabela.has(_especie(n)))
		checar(certos, "%s só tem os bichos da tabela dela" % Regioes.nome(r))
		checar(quem.all(func(n: Node2D) -> bool: return w.regiao_em(n.global_position) == r), "os de %s nasceram dentro dela" % Regioes.nome(r))
	var todos := get_tree().get_nodes_in_group(&"povoamento")
	checar(todos.all(func(n: Node2D) -> bool: return n.global_position.distance_to(p.global_position) >= Povoamento.LONGE_DA_TELA), "nenhum nasceu na tela do jogador")
	checar(todos.all(func(n: Node2D) -> bool: return n.global_position.distance_to(w.centro) >= Povoamento.RAIO_SEGURO), "nenhum nasceu perto da fogueira")
	var especies := {}
	for a in get_tree().get_nodes_in_group(&"animais"):
		especies[a.especie] = true
	checar(especies.size() == 4, "as 4 espécies de animais estão na ilha (%s)" % ", ".join(especies.keys()))

	# Uma construção é zona segura.
	var perto := w.centro + Vector2(400, 0)
	checar(pv.pode_nascer_em(perto) or not w.pode_pisar(perto), "longe de tudo pode nascer")
	var tocha := Node2D.new()  # faz as vezes de uma construção do jogador
	tocha.add_to_group(&"construcoes")
	tocha.position = perto
	w.entidades.add_child(tocha)
	checar(not pv.pode_nascer_em(perto + Vector2(30, 0)), "perto de construção não nasce")
	tocha.queue_free()

	# Morreu: a vaga fica fechada um tempo e depois o bicho volta.
	var r := Regioes.Id.BOSQUE
	var lim := Regioes.limite(r, 1, false)
	var vitima: Node = _da_regiao(r, false)[0]
	vitima.queue_free()
	await get_tree().process_frame
	pv._tempo = Povoamento.INTERVALO
	await esperar(0.2)
	checar(_da_regiao(r, false).size() == lim - 1, "morto não volta na hora (%d de %d)" % [_da_regiao(r, false).size(), lim])
	checar((pv._vagas_fechadas[r] as Array).size() == 1 and pv._vagas_fechadas[r][0] > 60.0, "a vaga abre de novo em ~%d s" % Povoamento.TEMPO_VOLTA)
	var antes := _da_regiao(r, false).map(func(n: Node) -> String: return String(n.name))
	pv._vagas_fechadas[r][0] = 0.01
	pv._tempo = Povoamento.INTERVALO
	var novo := false
	for k in 30:
		await esperar(0.1)
		novo = _da_regiao(r, false).any(func(n: Node) -> bool: return not String(n.name) in antes)
		if novo:
			break
	checar(novo and _da_regiao(r, false).size() + (pv._vagas_fechadas[r] as Array).size() == lim, "depois do tempo, nasce outro no lugar (%d)" % _da_regiao(r, false).size())

	# Mais jogadores, mais bichos.
	checar(Regioes.limite(r, 2, false) > lim and Regioes.limite(r, 4, false) > Regioes.limite(r, 2, false), "o limite cresce com os jogadores (%d, %d, %d)" % [lim, Regioes.limite(r, 2, false), Regioes.limite(r, 4, false)])

	# À noite: as criaturas da noite da região, em volta de quem está jogando, no escuro.
	var bosque := Vector2(GeradorIlha.SEMENTES[Regioes.Id.BOSQUE][0] * World.T)
	p.global_position = bosque
	w.noite = true
	var noturnos: Array[Node2D] = []
	for k in 12:
		var n := pv.nascer(Regioes.Id.BOSQUE, true)
		if n:
			noturnos.append(n)
	checar(noturnos.size() > 0, "à noite nascem as criaturas da noite (%d)" % noturnos.size())
	checar(noturnos.all(func(n: Node2D) -> bool:
		var d := n.global_position.distance_to(p.global_position)
		return d >= Povoamento.LONGE_DA_TELA and d <= Povoamento.NOITE_PERTO.y + 1.0 and n.get(&"noturno") == true),
		"perto do jogador, mas fora da tela, e da noite")
	w._aplicar_ciclo(false, true)
	await esperar(0.3)
	checar(noturnos.all(func(n) -> bool: return not is_instance_valid(n) or n.is_queued_for_deletion()), "ao amanhecer as criaturas da noite vão embora")

	# Longe é mais difícil: o mesmo slime nas Ruínas tem mais vida e nível maior.
	var perto_c := pv.criar("slime", Vector2(GeradorIlha.SEMENTES[Regioes.Id.BOSQUE][1] * World.T), Regioes.Id.BOSQUE) as Slime
	var longe := pv.criar("slime", Vector2(GeradorIlha.SEMENTES[Regioes.Id.RUINAS][0] * World.T), Regioes.Id.RUINAS) as Slime
	await get_tree().process_frame
	checar(longe.vida.maximo > perto_c.vida.maximo * 1.2, "nas Ruínas o slime tem mais vida (%.1f x %.1f)" % [longe.vida.maximo, perto_c.vida.maximo])
	checar(longe.barra.nivel > perto_c.barra.nivel, "e mostra nível maior (%d x %d)" % [longe.barra.nivel, perto_c.barra.nivel])
	terminar()


func _da_regiao(r: int, da_noite: bool) -> Array:
	return get_tree().get_nodes_in_group(&"povoamento").filter(func(n: Node) -> bool:
		return not n.is_queued_for_deletion() and int(n.get_meta(&"regiao", -1)) == r and bool(n.get_meta(&"da_noite", false)) == da_noite)


func _especie(n: Node) -> String:
	if n is Animal:
		return String(n.especie)
	return "slime" if n is Slime else "atirador"


func _especie_de(tipo: String) -> String:
	return tipo.trim_suffix("_noite")
