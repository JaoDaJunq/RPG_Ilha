extends TesteBase
## Sentir o dano: slime e javali dão uma cabeçada (acertam uma vez e recuam), o jogador dá um
## passo para trás, mostra a dor, treme a tela e fica protegido por 0,5 s; as bordas da tela
## ficam vermelhas com a vida baixa; a dificuldade escala dano e vida dos inimigos.

const SLIME := preload("res://scenes/enemies/slime.tscn")
const ANIMAL := preload("res://scenes/animals/animal.tscn")


func _ready() -> void:
	var w := await criar_mundo(0)
	var p := w.jogador
	p.global_position = w.centro + Vector2(0, 80)

	# --- Slime: cabeçada ------------------------------------------------------------
	var s: Slime = colocar(w, SLIME, p.global_position + Vector2(26, 0))
	await get_tree().physics_frame
	var vida_antes := p.vida.atual
	var pos_p := p.global_position
	var pos_slime := Vector2.ZERO
	var tempo := 0.0
	while p.vida.atual >= vida_antes and tempo < 3.0:
		await get_tree().physics_frame
		tempo += get_physics_process_delta_time()
	checar(p.vida.atual < vida_antes, "o pulo do slime acertou (%.0f -> %.0f)" % [vida_antes, p.vida.atual])
	pos_slime = s.global_position
	var dist_acerto := s.global_position.distance_to(p.global_position)
	checar(s._estado == Slime.Estado.RECUANDO, "ao acertar, o slime passa a recuar")
	await esperar(0.06)
	checar(p.visual._dor > 0.0, "o boneco mostra a dor")
	checar(p.visual.modulate.g < 0.95, "o boneco fica vermelho (g=%.2f)" % p.visual.modulate.g)
	checar(p._tremor > 0.0, "a tela de quem apanhou treme")
	checar(p.vida.protegido(), "o jogador fica protegido depois do golpe")
	checar(not p.vida.tomar_dano(5.0, &"fisico"), "não leva outro golpe na janela de proteção")
	await esperar(0.24)
	var dano_dado := vida_antes - p.vida.atual
	checar(is_equal_approx(dano_dado, s.dano_contato), "só um golpe de %.0f de dano (levou %.0f)" % [s.dano_contato, dano_dado])
	checar(s.global_position.distance_to(pos_slime) > 6.0, "o slime quicou para trás (%.1f px)" % s.global_position.distance_to(pos_slime))
	checar(s.global_position.distance_to(p.global_position) > dist_acerto + 6.0, "ficou mais longe do jogador (%.0f -> %.0f)" % [dist_acerto, s.global_position.distance_to(p.global_position)])
	# O jogador foi empurrado para longe do slime (que veio da direita).
	checar(p.global_position.x < pos_p.x - 5.0, "o jogador deu um passo para trás (%.1f px)" % (pos_p.x - p.global_position.x))
	# Sem encostar de novo: espera a recarga antes de preparar outra cabeçada.
	await esperar(0.3)
	checar(s._estado != Slime.Estado.PREPARANDO and s._estado != Slime.Estado.PULANDO, "espera a recarga antes de atacar de novo")
	checar(is_equal_approx(vida_antes - p.vida.atual, s.dano_contato), "sem dano extra enquanto espera")
	checar(s.vida.maximo == 6.0, "vida do slime na dificuldade normal (%.1f)" % s.vida.maximo)
	s.queue_free()

	# A proteção acaba em 0,5 s.
	await esperar(0.6)
	checar(p.vida.tomar_dano(1.0, &"fisico"), "passada a proteção, o jogador volta a poder apanhar")
	p.vida.curar_tudo()

	# --- Javali: cabeçada -----------------------------------------------------------
	p.global_position = w.centro + Vector2(0, 80)
	p.camera.reset_smoothing()
	var j: Animal = ANIMAL.instantiate()
	j.especie = &"javali"  # vale no _ready, então vem antes de entrar na cena
	j.position = p.global_position + Vector2(30, 0)
	w.entidades.add_child(j, true)
	await get_tree().physics_frame
	vida_antes = p.vida.atual
	pos_p = p.global_position
	j.hurtbox.receber(0.1, &"fisico", p)
	tempo = 0.0
	while p.vida.atual >= vida_antes and tempo < 3.0:
		await get_tree().physics_frame
		tempo += get_physics_process_delta_time()
	checar(is_equal_approx(vida_antes - p.vida.atual, Animal.DANO_JAVALI), "o javali acertou a cabeçada (%.0f)" % (vida_antes - p.vida.atual))
	pos_slime = j.global_position
	dist_acerto = j.global_position.distance_to(p.global_position)
	await esperar(0.35)
	checar(j.global_position.distance_to(p.global_position) > dist_acerto + 6.0, "o javali recuou depois de acertar (%.0f -> %.0f)" % [dist_acerto, j.global_position.distance_to(p.global_position)])
	checar(p.global_position.x < pos_p.x - 5.0, "o jogador foi empurrado para trás pelo javali")
	await esperar(0.5)
	checar(is_equal_approx(vida_antes - p.vida.atual, Animal.DANO_JAVALI), "o javali espera (~1 s) antes de investir de novo")
	j.free()
	p.vida.curar_tudo()

	# --- Bordas vermelhas -----------------------------------------------------------
	var hud: Hud = w.hud
	await esperar(0.6)
	checar(not hud.vinheta_visivel(), "vida cheia: sem bordas vermelhas")
	p.vida.tomar_dano(5.0, &"fisico")
	await get_tree().physics_frame
	await get_tree().process_frame
	checar(hud.vinheta_visivel(), "um golpe dá um clarão vermelho nas bordas")
	await esperar(0.7)
	checar(not hud.vinheta_visivel(), "o clarão passa e some")
	p.vida.curar_tudo()
	p.vida.atual = p.vida.maximo * 0.5
	await esperar(0.8)
	checar(not hud.vinheta_visivel(), "com 50%% da vida não há bordas vermelhas (%.2f)" % hud.vinheta_intensidade())
	p.vida.atual = p.vida.maximo * 0.35
	await esperar(0.8)
	var i35 := hud.vinheta_intensidade()
	checar(hud.vinheta_visivel() and i35 > 0.15, "com 35%% da vida as bordas ficam vermelhas (%.2f)" % i35)
	p.vida.atual = p.vida.maximo * 0.1
	await esperar(0.8)
	var i10 := hud.vinheta_intensidade()
	checar(i10 > i35, "quanto menos vida, mais vermelho (%.2f -> %.2f)" % [i35, i10])
	checar(hud._vinheta.mouse_filter == Control.MOUSE_FILTER_IGNORE, "a vinheta não pega o mouse")
	p.vida.curar_tudo()
	await esperar(1.5)
	checar(not hud.vinheta_visivel(), "curado, as bordas vermelhas somem")

	# --- Dificuldade ----------------------------------------------------------------
	var esperado := {0: [0.6, 0.8], 1: [1.0, 1.0], 2: [1.5, 1.3]}
	for nivel in esperado:
		w.dificuldade = nivel
		checar(is_equal_approx(World.mult_dificuldade(w, &"dano_inimigo"), esperado[nivel][0]), "dificuldade %d: dano x%.1f" % [nivel, esperado[nivel][0]])
		checar(is_equal_approx(World.mult_dificuldade(w, &"vida_inimigo"), esperado[nivel][1]), "dificuldade %d: vida x%.1f" % [nivel, esperado[nivel][1]])
	checar(is_equal_approx(World.mult_dificuldade(w, &"outra_coisa"), 1.0), "tipo desconhecido vale 1,0")
	w.dificuldade = 2
	var s2: Slime = colocar(w, SLIME, p.global_position + Vector2(300, 0))
	checar(is_equal_approx(s2.vida.maximo, 7.8), "slime difícil nasce com mais vida (%.1f)" % s2.vida.maximo)
	s2.free()
	w.dificuldade = 0
	s2 = colocar(w, SLIME, p.global_position + Vector2(300, 0))
	checar(is_equal_approx(s2.vida.maximo, 4.8), "slime fácil nasce com menos vida (%.1f)" % s2.vida.maximo)
	s2.free()
	# O dano do slime no fácil: 12 x 0,6.
	p.global_position = w.centro + Vector2(0, 80)
	var s3: Slime = colocar(w, SLIME, p.global_position + Vector2(26, 0))
	vida_antes = p.vida.atual
	tempo = 0.0
	while p.vida.atual >= vida_antes and tempo < 3.0:
		await get_tree().physics_frame
		tempo += get_physics_process_delta_time()
	checar(is_equal_approx(vida_antes - p.vida.atual, 12.0 * 0.6), "no fácil o pulo do slime tira 7,2 (%.1f)" % (vida_antes - p.vida.atual))
	s3.free()
	terminar()
