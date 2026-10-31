extends TesteBase
## Noite perigosa: slimes da noite nascem longe e no escuro, são mais fortes, fogem da luz,
## deixam gel de slime para quem derrota e derretem ao amanhecer.


func _ready() -> void:
	var w := await criar_mundo()
	var p := w.jogador
	p.global_position = w.ponto_de_nascer(0)
	w.alternar_noite()
	await esperar(0.2)
	w._tempo_noite = World.INTERVALO_NOITE
	await esperar(0.1)
	var da_noite: Array = get_tree().get_nodes_in_group(&"inimigos").filter(func(s: Node) -> bool: return s is Slime and s.noturno)
	checar(da_noite.size() == 1, "nasceu 1 slime da noite (%d)" % da_noite.size())
	var s: Slime = da_noite[0]
	checar(s.global_position.distance_to(p.global_position) >= 150.0, "nasceu longe do jogador")
	checar(World.luz_que_protege(w, s.global_position) == Vector2.INF, "nasceu no escuro")
	checar(s.vida.maximo > 3.0 and s.dano_contato > 12.0, "é mais forte (vida %.0f, dano %.0f)" % [s.vida.maximo, s.dano_contato])

	# Perto da fogueira, ele foge da luz.
	var fogueira := World.luz_que_protege(w, w.centro + Vector2(0, 12))
	checar(fogueira != Vector2.INF, "a fogueira do acampamento protege")
	s.global_position = fogueira + Vector2(30, 0)
	var antes := s.global_position.distance_to(fogueira)
	await esperar(0.6)
	checar(s.global_position.distance_to(fogueira) > antes, "o slime da noite foge da luz (%.0f -> %.0f)" % [antes, s.global_position.distance_to(fogueira)])

	# Derrotar dá gel de slime.
	s.hurtbox.receber(999.0, &"fisico", p)
	await esperar(0.1)
	await pegar_do_chao(p)
	checar(p.inventario.quantidade_de(&"gel_slime") >= 2, "quem derrotou ganhou gel de slime (%d)" % p.inventario.quantidade_de(&"gel_slime"))

	# Outro slime da noite derrete quando amanhece.
	w._tempo_noite = World.INTERVALO_NOITE
	var restantes := 0
	for i in 20:  # o novo slime nasce no próximo passo da noite (às vezes demora uns quadros)
		await esperar(0.05)
		restantes = get_tree().get_nodes_in_group(&"inimigos").filter(func(n: Node) -> bool: return n is Slime and n.noturno).size()
		if restantes >= 1:
			break
	checar(restantes == 1, "nasceu outro")
	w.alternar_noite()
	await esperar(0.2)
	restantes = get_tree().get_nodes_in_group(&"inimigos").filter(func(n: Node) -> bool: return is_instance_valid(n) and n is Slime and n.noturno and not n.is_queued_for_deletion()).size()
	checar(restantes == 0, "ao amanhecer os slimes da noite derretem")
	terminar()
