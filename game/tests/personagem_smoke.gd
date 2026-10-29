extends TesteBase
## Raça + classe dão os atributos certos; esquiva, mana e a ficha (C) funcionam.


func _ready() -> void:
	var hg := Ficha.criar(&"humano", &"guerreiro")
	var om := Ficha.criar(&"ogro", &"mago")
	var og := Ficha.criar(&"ogro", &"guerreiro")
	checar(hg.valor(&"forca") == 8 and hg.vida_maxima() == 120.0 and hg.mana_maxima() == 30.0,
		"Humano Guerreiro: Força 8, vida 120, mana 30 (%d, %d, %d)" % [hg.valor(&"forca"), hg.vida_maxima(), hg.mana_maxima()])
	checar(om.valor(&"intelecto") == 7 and om.mana_maxima() == 45.0,
		"Ogro Mago existe e tem menos mana que um mago comum (Intelecto 7, mana %d)" % om.mana_maxima())
	checar(og.multiplicador_fisico() > hg.multiplicador_fisico(), "Ogro Guerreiro bate mais forte que Humano Guerreiro")
	checar(og.tempo_coleta() < hg.tempo_coleta(), "mais Força coleta mais rápido")

	var w := await criar_mundo(0, true, &"mago", &"ogro")
	var p := w.jogador
	checar(p.vida.maximo == 90.0 and p.mana == 45.0, "jogador nasce com a vida e a mana da ficha (%d / %d)" % [p.vida.maximo, p.mana])
	checar(w.hud._titulo_personagem.text == "Nv 1 · Ogro Mago", "HUD mostra nível, raça e classe (%s)" % w.hud._titulo_personagem.text)

	# Esquiva: desloca rápido, protege do dano e tem recarga.
	p.mira_forcada = p.global_position + Vector2(200, -10)
	var x0 := p.global_position.x
	p.esquivar()
	checar(p.vida.protegido(), "durante a esquiva o jogador não toma dano")
	await esperar(0.35)
	var andou := p.global_position.x - x0
	checar(andou > 30.0, "esquiva desloca o jogador (%.0f px)" % andou)
	var x1 := p.global_position.x
	p.esquivar()
	await esperar(0.3)
	checar(absf(p.global_position.x - x1) < 2.0, "esquiva tem recarga")

	# Mana: gastar e faltar.
	var antes := p.mana
	p.mira_forcada = p.global_position + Vector2(0, 80)
	p.usar_habilidade_por_id(&"lanca_gelo")
	await get_tree().physics_frame
	checar(absf(antes - p.mana - 8.0) < 0.5, "lança de gelo gasta 8 de mana (%.1f → %.1f)" % [antes, p.mana])
	await esperar(1.5)
	p.mana = 2.0
	var projeteis := get_tree().get_nodes_in_group(&"projeteis").size()
	p.comecar_habilidade(1)  # lança de gelo de novo, sem mana
	await get_tree().physics_frame
	checar(get_tree().get_nodes_in_group(&"projeteis").size() == projeteis, "sem mana a habilidade não sai")
	var m := p.mana
	await esperar(1.0)
	checar(p.mana > m, "mana volta com o tempo (%.1f → %.1f)" % [m, p.mana])

	# Ficha (C)
	var ev := InputEventAction.new()
	ev.action = &"ficha"
	ev.pressed = true
	Input.parse_input_event(ev)
	for i in 3:
		await get_tree().process_frame
	checar(w.hud.ficha_visivel(), "C abre a ficha do personagem")

	terminar()
