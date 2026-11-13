extends TesteBase
## L40: ritmo do golpe por classe, combo com o último golpe forte, buffer de comando, o
## anfitrião barrando a "metralhadora", o inimigo tirando vida de verdade, empurrão, hit stop
## sem mexer no tempo do jogo, piscar/número de dano, andar com aceleração e a câmera.

const SLIME := preload("res://scenes/enemies/slime.tscn")


func _ready() -> void:
	var w := await criar_mundo(0, true, &"guerreiro")
	var p := w.jogador
	p.dar_kit()
	await _ritmo_por_classe()
	await _metralhadora(w, p)
	await _combo(w, p)
	await _buffer(w, p)
	await _empurrao_e_reacao(w, p)
	await _hit_stop(w, p)
	await _inimigo_machuca(w, p)
	await _andar(p)
	await _camera(w, p)
	terminar()


func _slime_parado(w: World, pos: Vector2, vida := 100.0) -> Slime:
	var s: Slime = colocar(w, SLIME, pos)
	s.vida.maximo = vida
	s.vida.atual = vida
	await get_tree().physics_frame
	s.set_physics_process(false)  # parado: o teste mede só o golpe
	return s


func _ritmo_por_classe() -> void:
	var g := Combate.estilo(&"guerreiro")
	var l := Combate.estilo(&"ladino")
	checar(float(g.recarga) > float(l.recarga), "guerreiro bate mais devagar que o ladino (%.2f s contra %.2f s)" % [g.recarga, l.recarga])
	checar(float(g.dano) > float(l.dano), "guerreiro bate mais forte que o ladino (x%.2f contra x%.2f)" % [g.dano, l.dano])
	for c in Combate.ESTILOS:
		var n := Combate.tamanho_combo(c)
		checar(n >= 2 and n <= 3 and Combate.mult_combo(c, n - 1) > Combate.mult_combo(c, 0), "%s: combo de %d golpes, o último mais forte" % [c, n])
	checar(Combate.recarga(&"guerreiro", 2) > Combate.recarga(&"guerreiro", 0), "o golpe final demora mais para voltar")


## O anfitrião confere o ritmo: pedidos seguidos (cliente apressado) não passam.
func _metralhadora(w: World, p: Player) -> void:
	var s := await _slime_parado(w, p.global_position + Vector2(16, -4))
	p.mira_forcada = s.global_position
	p.zerar_golpe()
	for i in 5:
		p._pedir_golpe(Vector2.RIGHT)
	await get_tree().physics_frame
	var tirou := 100.0 - s.vida.atual
	checar(absf(tirou - p.dano_do_golpe(0)) < 0.01, "5 pedidos de golpe no mesmo instante: o anfitrião aceita só 1 (%.2f de dano)" % tirou)
	s.queue_free()
	await get_tree().physics_frame


func _combo(w: World, p: Player) -> void:
	var s := await _slime_parado(w, p.global_position + Vector2(16, -4))
	p.mira_forcada = s.global_position
	p.zerar_golpe()
	var danos: Array[float] = []
	var antes := s.vida.atual
	for i in 3:
		p.golpear()
		await get_tree().physics_frame
		danos.append(antes - s.vida.atual)
		antes = s.vida.atual
		s.vida.tirar_protecao()
		await esperar(Combate.recarga(&"guerreiro", 0) + 0.02)
	checar(is_equal_approx(danos[0], danos[1]) and danos[0] > 0.0, "golpes 1 e 2 do combo iguais (%.2f, %.2f)" % [danos[0], danos[1]])
	checar(absf(danos[2] - danos[0] * 1.8) < 0.01, "o 3º golpe do guerreiro é o forte: x1,8 (%.2f)" % danos[2])
	checar(p.combo_atual() == 2, "o combo chegou ao golpe final")
	checar(p._recarga_golpe > 0.2, "depois do golpe final, a recarga é maior (ainda faltam %.2f s)" % p._recarga_golpe)
	# Esperar demais recomeça o combo.
	await esperar(Combate.recarga(&"guerreiro", 2) + Combate.JANELA_COMBO + 0.1)
	p.golpear()
	await get_tree().physics_frame
	checar(p.combo_atual() == 0, "parar de bater recomeça o combo")
	s.queue_free()
	await get_tree().physics_frame


func _buffer(w: World, p: Player) -> void:
	var s := await _slime_parado(w, p.global_position + Vector2(16, -4))
	p.mira_forcada = s.global_position
	p.zerar_golpe()
	p.golpear()
	await esperar(Combate.recarga(&"guerreiro", 0) - 0.12)
	s.vida.tirar_protecao()
	var antes := s.vida.atual
	p.golpear()  # um pouco antes da hora
	checar(p._golpe_guardado, "golpe apertado um pouco antes da hora fica guardado (buffer)")
	await esperar(0.2)
	checar(s.vida.atual < antes, "o golpe guardado sai sozinho quando fica pronto")
	p.zerar_golpe()
	p.golpear()
	await get_tree().physics_frame
	p.golpear()  # longe da hora: não guarda
	checar(not p._golpe_guardado, "apertar muito antes não guarda (sem metralhadora)")
	s.queue_free()
	await get_tree().physics_frame


func _empurrao_e_reacao(w: World, p: Player) -> void:
	var s: Slime = SLIME.instantiate()
	s.position = p.global_position + Vector2(16, -4)
	s.raio_visao = 0.0  # não persegue nem ataca: só o empurrão mexe nele
	w.entidades.add_child(s, true)
	s.vida.maximo = 100.0
	s.vida.atual = 100.0
	s._tempo_estado = -100.0  # e não sai passeando
	await get_tree().physics_frame
	p.mira_forcada = s.global_position
	p.zerar_golpe()
	var pos := s.global_position
	p.golpear()
	await get_tree().physics_frame
	var r := ReacaoGolpe.de(s)
	checar(r != null and r.branco() > 0.3, "o inimigo pisca branco ao apanhar (%.2f)" % (r.branco() if r else -1.0))
	var numero := _numero()
	checar(numero != null and numero.texto_atual() == NumeroDano.texto(p.dano_do_golpe(0)), "o número do dano sobe (%s)" % (numero.texto_atual() if numero else "nenhum"))
	await esperar(0.4)
	var normal := s.global_position.distance_to(pos)
	checar(normal > 1.0 and normal < 8.0, "golpe normal empurra pouco (%.1f px)" % normal)
	# Golpe final do combo: empurra longe.
	p.zerar_golpe()
	p._combo = 1
	p._combo_anfitriao = 1
	p._ultimo_golpe_ms = p._relogio_ms
	p._desde_golpe = 0.0
	pos = s.global_position
	s.vida.tirar_protecao()
	p.mira_forcada = s.global_position
	p.golpear()
	await esperar(0.5)
	var forte := s.global_position.distance_to(pos)
	checar(forte > 15.0, "o golpe final empurra longe (%.1f px)" % forte)
	# Crítico: número maior e amarelo.
	Passivas.chance_critico = 1.0
	p.zerar_golpe()
	p.global_position = s.global_position + Vector2(-16, 4)
	p.mira_forcada = s.global_position
	s.vida.tirar_protecao()
	p.golpear()
	await get_tree().physics_frame
	Passivas.chance_critico = -1.0
	numero = _numero(true)
	checar(numero != null, "o crítico mostra o número maior e amarelo")
	# Armadura: atacando, o slime não é empurrado.
	r.parar_empurrao()
	r.armadura = true
	r.empurrar(Vector2(500, 0))
	checar(not r.empurrado(), "atacando (armadura), o inimigo não é empurrado")
	r.armadura = false
	s.queue_free()
	await get_tree().physics_frame


func _numero(critico := false) -> NumeroDano:
	var achado: NumeroDano = null
	for n in get_tree().root.find_children("*", "", true, false):
		var nd := n as NumeroDano
		if nd and not nd.is_queued_for_deletion() and (not critico or nd.eh_critico()):
			achado = nd
	return achado


func _hit_stop(w: World, p: Player) -> void:
	var s := await _slime_parado(w, p.global_position + Vector2(16, -4))
	var outro: Slime = colocar(w, SLIME, p.global_position + Vector2(-80, 60))
	await get_tree().physics_frame
	outro.raio_visao = 0.0
	p.mira_forcada = s.global_position
	p.zerar_golpe()
	p.golpear()
	await get_tree().physics_frame
	checar(p.em_hit_stop(), "acertar dá hit stop no personagem")
	checar(ReacaoGolpe.de(s).em_hit_stop(), "e no desenho de quem apanhou")
	checar(is_equal_approx(Engine.time_scale, 1.0), "o hit stop não mexe no tempo do jogo (time_scale %.2f)" % Engine.time_scale)
	var quadros_antes := Engine.get_physics_frames()
	var pos_outro := outro.global_position
	await esperar(0.1)
	checar(not p.em_hit_stop(), "o hit stop dura poucos quadros (acabou em 0,1 s)")
	checar(Engine.get_physics_frames() - quadros_antes >= 5, "a física (e a rede) seguiu rodando durante o hit stop")
	checar(outro.is_physics_processing() and outro.vida.esta_vivo() and pos_outro != Vector2.INF, "os outros inimigos continuam pensando")
	# Golpe forte: treme a câmera.
	p.zerar_golpe()
	p._combo = 1
	p._combo_anfitriao = 1
	p._ultimo_golpe_ms = p._relogio_ms
	p._desde_golpe = 0.0
	s.vida.tirar_protecao()
	p.golpear()
	await get_tree().physics_frame
	checar(p._tremor > 0.0, "o golpe final treme a câmera")
	await esperar(0.3)
	World.efeito_todos(p, &"explosao", p.global_position + Vector2(10, 0))
	await get_tree().process_frame
	checar(p._tremor > 0.0, "uma explosão perto treme a câmera")
	s.queue_free()
	outro.queue_free()
	await esperar(0.3)


## O ponto da reclamação: segurar o clique colado no slime agora custa vida.
func _inimigo_machuca(w: World, p: Player) -> void:
	p.vida.curar_tudo()
	var s: Slime = colocar(w, SLIME, p.global_position + Vector2(24, 0))
	s.vida.maximo = 1000.0
	s.vida.atual = 1000.0
	var onde := p.global_position
	var vida0 := p.vida.atual
	Input.action_press(&"atacar")
	var t := 0.0
	while t < 5.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		p.global_position = onde
		p.mira_forcada = s.global_position + Vector2(0, -6)
	Input.action_release(&"atacar")
	checar(1000.0 - s.vida.atual > 5.0, "segurando o clique, o jogador bate (%.1f de dano)" % (1000.0 - s.vida.atual))
	checar(vida0 - p.vida.atual >= 20.0, "e o slime revida: trocar golpes sem esquivar custa vida (%.0f em 5 s)" % (vida0 - p.vida.atual))
	s.queue_free()
	p.vida.curar_tudo()
	await esperar(0.5)


func _andar(p: Player) -> void:
	var maxima := p.ficha.velocidade() * p.multiplicador_velocidade()
	p.velocity = Vector2.ZERO
	await esperar(0.3)
	Input.action_press(&"mover_direita")
	await get_tree().physics_frame
	await get_tree().physics_frame
	var v1 := p.velocity.length()
	checar(v1 > 0.0 and v1 < maxima * 0.9, "andar acelera (2 quadros: %.0f de %.0f px/s)" % [v1, maxima])
	await esperar(0.15)
	checar(absf(p.velocity.length() - maxima) < 1.0, "em 0,15 s já está na velocidade cheia (%.0f)" % p.velocity.length())
	Input.action_release(&"mover_direita")
	await get_tree().physics_frame
	checar(p.velocity.length() > 0.0, "soltar freia (não para seco)")
	await esperar(0.1)
	checar(p.velocity.length() < 0.5, "e em 0,1 s parou (%.1f)" % p.velocity.length())


func _camera(_w: World, p: Player) -> void:
	p.mira_forcada = p.global_position + Vector2(200, 0)
	await esperar(0.8)
	checar(p.camera.position.x > 4.0, "a câmera olha um pouco para onde se mira (%.1f px)" % p.camera.position.x)
	checar(p.camera.position.x <= Player.CAMERA_A_FRENTE + 0.01, "sem passar do limite")
	checar(p.camera.position_smoothing_enabled, "a câmera segue suave")
	p.mira_forcada = null
