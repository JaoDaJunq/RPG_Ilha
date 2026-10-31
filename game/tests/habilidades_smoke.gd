extends TesteBase
## As 6 habilidades novas (2 por classe), cada uma fazendo o seu trabalho:
## Guerreiro: Bloqueio e Fúria. Mago: Raio e Nova de gelo. Arqueiro: Chuva de flechas e Bomba.

const SLIME := preload("res://scenes/enemies/slime.tscn")
const VIDA_SLIME := 20.0  # vida alta: nenhum slime morre no meio da medição


func _ready() -> void:
	await _guerreiro()
	await _mago()
	await _arqueiro()
	terminar()


## Slime parado no lugar (sem pensar nem andar), para medir só o efeito da habilidade.
func _slime(w: World, pos: Vector2) -> Slime:
	var s: Slime = colocar(w, SLIME, pos)
	s.set_physics_process(false)
	s.vida.maximo = VIDA_SLIME
	s.vida.atual = VIDA_SLIME
	return s


func _tirou(s: Slime) -> float:
	return VIDA_SLIME - (s.vida.atual if is_instance_valid(s) else 0.0)


func _fim_do_mundo(w: World) -> void:
	w.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _guerreiro() -> void:
	var w := await criar_mundo(0, true, &"guerreiro")
	var p := w.jogador
	var v := p.vida

	# Bloqueio: 60% menos dano por 3 s, depois volta ao normal.
	v.curar_tudo()
	var antes := v.atual
	v.tomar_dano(10.0)
	checar(is_equal_approx(antes - v.atual, 10.0), "sem bloqueio: dano cheio (%.1f)" % (antes - v.atual))
	v.curar_tudo()
	checar(p.usar_habilidade_por_id(&"bloqueio"), "guerreiro tem o Bloqueio")
	await esperar(0.2)
	checar(v.reducao_ativa(), "Bloqueio ligou a redução de dano")
	antes = v.atual
	v.tomar_dano(10.0)
	checar(is_equal_approx(antes - v.atual, 4.0), "com Bloqueio o dano cai 60%% (%.1f de 10)" % (antes - v.atual))
	await esperar(3.1)
	v.curar_tudo()
	antes = v.atual
	v.tomar_dano(10.0)
	checar(is_equal_approx(antes - v.atual, 10.0), "o Bloqueio acaba depois de 3 s (%.1f)" % (antes - v.atual))

	# Fúria: +50% no dano do golpe e +25% de velocidade.
	var a := _slime(w, p.global_position + Vector2(40, 0))
	var b := _slime(w, p.global_position + Vector2(40, 40))
	await get_tree().physics_frame
	p.global_position = a.global_position + Vector2(-14, 4)
	p.mira_forcada = a.global_position
	await get_tree().physics_frame
	p.golpear()
	await get_tree().physics_frame
	var normal := _tirou(a)
	checar(normal > 0.5, "golpe normal machuca (%.2f)" % normal)
	checar(is_equal_approx(p.multiplicador_velocidade(), 1.0), "sem Fúria a velocidade é normal")
	checar(p.usar_habilidade_por_id(&"furia"), "guerreiro tem a Fúria")
	await esperar(0.5)
	checar(p.furia_ativa() and is_equal_approx(p.multiplicador_velocidade(), 1.25), "Fúria: +25% de velocidade")
	p.global_position = b.global_position + Vector2(-14, 4)
	p.mira_forcada = b.global_position
	await get_tree().physics_frame
	p.golpear()
	await get_tree().physics_frame
	var furioso := _tirou(b)
	checar(is_equal_approx(furioso, normal * 1.5), "Fúria: golpe com +50%% de dano (%.2f contra %.2f)" % [furioso, normal])
	await esperar(5.0)
	checar(not p.furia_ativa(), "a Fúria acaba depois de 5 s")
	await _fim_do_mundo(w)


func _mago() -> void:
	var w := await criar_mundo(0, true, &"mago")
	var p := w.jogador
	var base := p.global_position

	# Raio: o inimigo mais perto da mira, dentro do alcance; machuca e atordoa.
	var alvo := _slime(w, base + Vector2(60, 0))
	var vizinho := _slime(w, base + Vector2(60, 20))
	var longe := _slime(w, base + Vector2(200, 0))
	await get_tree().physics_frame
	p.mira_forcada = alvo.global_position + Vector2(0, -4)
	checar(p.usar_habilidade_por_id(&"raio"), "mago tem o Raio")
	await esperar(0.2)
	checar(_tirou(alvo) > 1.5, "Raio machuca o inimigo da mira (%.2f)" % _tirou(alvo))
	checar(alvo.preso(), "Raio atordoa o inimigo")
	checar(_tirou(vizinho) == 0.0, "Raio só pega o mais perto da mira")
	await esperar(3.1)  # recarga
	p.mira_forcada = longe.global_position
	p.usar_habilidade_por_id(&"raio")
	await esperar(0.2)
	checar(_tirou(longe) == 0.0 and not longe.preso(), "Raio não alcança quem está além de 120 px do mago")
	await esperar(3.1)
	var sem_alvo := _slime(w, base + Vector2(60, -90))
	p.mira_forcada = base + Vector2(60, -40)  # a 50 px do slime: fora do raio da mira
	var mana := p.mana
	p.usar_habilidade_por_id(&"raio")
	await esperar(0.2)
	checar(_tirou(sem_alvo) == 0.0, "mira longe de qualquer inimigo não acerta ninguém")
	alvo.queue_free()
	vizinho.queue_free()
	longe.queue_free()
	sem_alvo.queue_free()

	# Nova de gelo: congela quem está a até 36 px e deixa os outros em paz.
	await get_tree().physics_frame
	var perto := _slime(w, p.global_position + Vector2(22, 0))
	var fora := _slime(w, p.global_position + Vector2(60, 0))
	await get_tree().physics_frame
	checar(p.usar_habilidade_por_id(&"nova_gelo"), "mago tem a Nova de gelo")
	await esperar(0.2)
	checar(perto.congelado() and perto.parado, "Nova de gelo congela o slime de perto")
	checar(_tirou(perto) > 0.0, "e ainda machuca um pouco (%.2f)" % _tirou(perto))
	checar(not fora.congelado(), "o slime de longe não congela")
	await _fim_do_mundo(w)


func _arqueiro() -> void:
	var w := await criar_mundo(0, true, &"arqueiro")
	var p := w.jogador
	var base := p.global_position

	# Chuva de flechas: nada no começo; passado 0,4 s, machuca todos no ponto marcado.
	var a := _slime(w, base + Vector2(80, 0))
	var b := _slime(w, base + Vector2(95, 12))
	var c := _slime(w, base + Vector2(0, -80))
	await get_tree().physics_frame
	p.mira_forcada = base + Vector2(85, 4)
	checar(p.usar_habilidade_por_id(&"chuva_flechas"), "arqueiro tem a Chuva de flechas")
	await esperar(0.15)
	checar(_tirou(a) == 0.0, "a chuva ainda não caiu (demora 0,4 s)")
	await esperar(0.6)
	checar(_tirou(a) > 0.5 and _tirou(b) > 0.5, "a chuva machuca todos no ponto (%.2f e %.2f)" % [_tirou(a), _tirou(b)])
	checar(_tirou(c) == 0.0, "a chuva não pega quem está fora do ponto")
	a.queue_free()
	b.queue_free()
	c.queue_free()
	await esperar(0.1)

	# Bomba batendo num inimigo: explode e machuca quem está em volta (fogo, dano dobrado em slime).
	var d := _slime(w, base + Vector2(60, 0))
	var e := _slime(w, base + Vector2(60, 25))
	var f := _slime(w, base + Vector2(60, -70))
	await get_tree().physics_frame
	p.mira_forcada = d.global_position + Vector2(0, -6)
	checar(p.usar_habilidade_por_id(&"bomba"), "arqueiro tem a Bomba")
	await esperar(0.8)
	checar(_tirou(d) > 1.5 and _tirou(d) < 2.6, "Bomba machuca quem ela acerta (%.2f)" % _tirou(d))
	checar(_tirou(e) > 1.5, "a explosão pega o vizinho (%.2f)" % _tirou(e))
	checar(_tirou(f) == 0.0, "a explosão não pega quem está longe")
	d.queue_free()
	e.queue_free()
	f.queue_free()
	await esperar(5.0)  # recarga

	# Bomba sem acertar nada: explode sozinha depois de 0,8 s, onde estiver.
	p.global_position = base
	var g := _slime(w, base + Vector2(-120, 0))
	await get_tree().physics_frame
	p.mira_forcada = base + Vector2(-200, -10)
	p.usar_habilidade_por_id(&"bomba")
	await esperar(0.5)
	checar(_tirou(g) == 0.0, "a bomba ainda está voando")
	await esperar(0.6)
	checar(_tirou(g) > 1.5, "sem bater em nada, a bomba explode sozinha (%.2f)" % _tirou(g))
	await _fim_do_mundo(w)
