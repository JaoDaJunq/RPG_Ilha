extends TesteBase
## Peças das habilidades (design/habilidades_base.md): registro das lógicas por classe,
## zona, invocação, projéteis especiais, corrente, avanço, buffs, companheiro e os
## recursos de classe (Fúria e combo) com a barra no HUD.

const SLIME := preload("res://scenes/enemies/slime.tscn")
const FLECHA := preload("res://scenes/abilities/flecha.tscn")
const ADAGA := preload("res://scenes/abilities/adaga.tscn")


func _ready() -> void:
	var w := await criar_mundo(0, true, &"mago")
	var p := w.jogador
	p.global_position = w.centro + Vector2(0, 60)
	await get_tree().physics_frame
	_organizacao()
	await _zona(w, p)
	await _invocacao(w, p)
	await _projeteis(w, p)
	await _corrente_e_avanco(w, p)
	await _buffs(w, p)
	await _companheiro(w, p)
	await _recursos(w, p)
	terminar()


## Slime parado (sem pensar), com 100 de vida.
func _slime(w: World, pos: Vector2) -> Slime:
	var s: Slime = colocar(w, SLIME, pos)
	s.set_physics_process(false)
	s.vida.maximo = 100.0
	s.vida.atual = 100.0
	return s


func _tirou(s: Slime) -> float:
	return 100.0 - (s.vida.atual if is_instance_valid(s) else 0.0)


func _limpar(lista: Array) -> void:
	for n in lista:
		if is_instance_valid(n):
			n.queue_free()


func _organizacao() -> void:
	checar(Logicas.criar(&"Investida") is Logicas.Investida and Logicas.criar(&"Cambalhota") is Logicas.Cambalhota, "Logicas.criar acha as lógicas pelo nome da classe interna")
	checar(Logicas.POR_CLASSE.size() == 5, "os 5 arquivos logicas_<classe>.gd estão registrados")
	var todos := true
	for c in [&"guerreiro", &"mago", &"arqueiro", &"ladino", &"clerigo"]:
		todos = todos and ArvoreData.nos(c).size() == 3 + 5 + 6 * ArvoreData.ramos(c).size() and ArvoreData.ramos(c).size() >= 3
	checar(todos and ArvoreData.TABELA[&"mago"] == ArvoreMago.DADOS, "a árvore de cada classe vem do arquivo dela (arvore_<classe>.gd)")
	var h := HabilidadeData.new()
	checar(h.animacao == &"" and h.som == &"" and h.duracao_animacao == 0.0, "HabilidadeData tem animação e som (vazio = tabela antiga)")


func _zona(w: World, p: Player) -> void:
	var dentro := _slime(w, p.global_position + Vector2(60, 0))
	var fora := _slime(w, p.global_position + Vector2(140, 0))
	await get_tree().physics_frame
	var z := Zona.criar(p, dentro.global_position, 20.0, 2.0)
	z.dano = 1.0
	z.estado = EfeitosEstado.LENTIDAO
	z.estado_forca = 0.3
	z.efeito_visual = &"nova_gelo"
	var tiques := [0]
	z.ao_tique = func(_z: Zona, _i: Array[Node2D], _j: Array[Player]) -> void: tiques[0] += 1
	z.iniciar()
	await esperar(0.1)
	checar(dentro.efeitos.tem(EfeitosEstado.LENTIDAO), "zona aplica o estado em quem está dentro")
	await esperar(2.2)
	checar(tiques[0] == 3 and absf(_tirou(dentro) - 3.0) < 0.01, "zona de 2 s com tique de 1 s: 3 tiques de dano (%d tiques, %.1f de dano)" % [tiques[0], _tirou(dentro)])
	checar(_tirou(fora) == 0.0 and not is_instance_valid(z), "fora da zona nada acontece; a zona some no fim")
	# Zona de cura com buff, seguindo o jogador.
	p.vida.atual = p.vida.maximo - 10.0
	var cura := Zona.criar(p, p.global_position, 16.0, 1.0)
	cura.cura = 4.0
	cura.buff = Buffs.VELOCIDADE
	cura.buff_valor = 0.2
	cura.seguir = p
	var chamadas := [0]
	cura.ao_tique = func(_z: Zona, _i: Array[Node2D], j: Array[Player]) -> void: chamadas[0] += j.size()
	cura.iniciar()
	await esperar(0.1)
	checar(is_equal_approx(p.vida.atual, p.vida.maximo - 6.0) and p.buffs.tem(Buffs.VELOCIDADE), "zona cura e dá buff a quem está dentro")
	checar(chamadas[0] == 1, "ao_tique é chamado com os jogadores dentro")
	p.vida.curar_tudo()
	await esperar(1.2)
	_limpar([dentro, fora])


func _invocacao(w: World, p: Player) -> void:
	var alvo := _slime(w, p.global_position + Vector2(60, 0))
	var torre := Invocacao.criar(p, p.global_position + Vector2(30, 0))
	torre.dano = 2.0
	torre.alcance = 50.0
	torre.intervalo = 0.5
	torre.duracao = 1.2
	torre.efeito_ataque = &"raio"
	torre.estado = EfeitosEstado.ATORDOADO
	torre.iniciar()
	await esperar(0.2)
	checar(_tirou(alvo) >= 2.0 and alvo.efeitos.tem(EfeitosEstado.ATORDOADO), "torreta ataca o inimigo mais perto e aplica o estado (%.1f)" % _tirou(alvo))
	await esperar(1.3)
	checar(not is_instance_valid(torre) and absf(_tirou(alvo) - 6.0) < 0.01, "torreta ataca a cada 0,5 s e some no fim do tempo (%.1f)" % _tirou(alvo))
	alvo.queue_free()
	# Golem que provoca: o slime vai bater nele, e ele tem vida.
	var bravo: Slime = colocar(w, SLIME, p.global_position + Vector2(-60, 0))
	bravo.vida.maximo = 100.0
	bravo.vida.atual = 100.0
	var golem := Invocacao.criar(p, p.global_position + Vector2(-35, 0))
	golem.dano = 0.0
	golem.provoca_raio = 60.0
	golem.vida_maxima = 50.0
	golem.duracao = 10.0
	golem.iniciar()
	await esperar(2.5)
	checar(bravo._alvo_atual == golem and golem.vida.atual < 50.0, "golem provoca: o slime vai atrás dele e bate (vida do golem %.0f)" % golem.vida.atual)
	golem.vida.curar_tudo()  # tira a proteção depois do último golpe
	golem.vida.tomar_dano(100.0)
	await get_tree().physics_frame
	checar(not is_instance_valid(golem) or golem.is_queued_for_deletion(), "sem vida, a invocação some")
	bravo.queue_free()
	await get_tree().physics_frame


func _lancar(cena: PackedScene, p: Player, dir: Vector2) -> Projetil:
	var pr: Projetil = cena.instantiate()
	pr.lancador = p
	pr.direcao = dir
	pr.dano = 1.0
	pr.elemento = &"fisico"
	pr.position = p.global_position + Vector2(0, -10)
	return pr


func _projeteis(w: World, p: Player) -> void:
	var o := p.global_position + Vector2(0, -10)
	# Perfura: acerta os 3 em linha.
	var linha: Array[Slime] = []
	for k in 3:
		linha.append(_slime(w, p.global_position + Vector2(30 + 22 * k, 0)))
	await get_tree().physics_frame
	var f := _lancar(FLECHA, p, Vector2.RIGHT)
	f.perfura = true
	var acertos := [0]
	f.acertou.connect(func(_a: Node, _pos: Vector2) -> void: acertos[0] += 1)
	w.entidades.add_child(f, true)
	await esperar(0.9)
	checar(acertos[0] == 3 and linha.all(func(s: Slime) -> bool: return _tirou(s) > 0.0), "perfurante atravessa e acerta os 3 (%d acertos)" % acertos[0])
	_limpar(linha)
	# Quica: acerta 1 e salta para mais 2 (espalhados, fora da linha).
	var grupo: Array[Slime] = [_slime(w, p.global_position + Vector2(40, 0)), _slime(w, p.global_position + Vector2(60, -40)), _slime(w, p.global_position + Vector2(20, -70))]
	await get_tree().physics_frame
	var q := _lancar(FLECHA, p, Vector2.RIGHT)
	q.quiques = 2
	q.raio_quique = 60.0
	q.duracao = 2.0
	w.entidades.add_child(q, true)
	await esperar(1.5)
	checar(grupo.all(func(s: Slime) -> bool: return _tirou(s) > 0.0), "quica entre 3 alvos (%s)" % str(grupo.map(func(s: Slime) -> float: return _tirou(s))))
	_limpar(grupo)
	# Volta (bumerangue): acerta na ida e na volta e some ao chegar no dono.
	var b_alvo := _slime(w, p.global_position + Vector2(36, 0))
	await get_tree().physics_frame
	var b := _lancar(ADAGA, p, Vector2.RIGHT)
	b.volta = true
	b.duracao = 0.45
	w.entidades.add_child(b, true)
	await esperar(0.3)
	var ida := _tirou(b_alvo)
	await esperar(1.0)
	checar(ida > 0.0 and _tirou(b_alvo) > ida and not is_instance_valid(b), "bumerangue acerta na ida e na volta e volta para a mão (%.1f → %.1f)" % [ida, _tirou(b_alvo)])
	b_alvo.queue_free()
	# Puxa: traz o alvo para perto do lançador e aplica estado.
	var longe := _slime(w, p.global_position + Vector2(70, 0))
	longe.raio_visao = 0.0
	longe.set_physics_process(true)  # quem anda com o puxão é o próprio slime
	await get_tree().physics_frame
	var c := _lancar(FLECHA, p, Vector2.RIGHT)
	c.puxa = 40.0
	c.estado = EfeitosEstado.ATORDOADO
	w.entidades.add_child(c, true)
	await esperar(0.7)
	var dist := longe.global_position.distance_to(p.global_position)
	checar(dist < 45.0 and longe.efeitos.tem(EfeitosEstado.ATORDOADO), "puxa o alvo até o lançador e atordoa (%.0f px)" % dist)
	longe.queue_free()
	await get_tree().physics_frame
	checar(o.distance_to(p.global_position + Vector2(0, -10)) < 1.0, "o jogador não saiu do lugar")


func _corrente_e_avanco(w: World, p: Player) -> void:
	var fila: Array[Slime] = []
	for k in 4:
		fila.append(_slime(w, p.global_position + Vector2(40 + 30 * k, 0)))
	await get_tree().physics_frame
	var feitos := Golpes.corrente(p, fila[0], 3, 40.0, 1.0, &"raio", &"raio")
	checar(feitos.size() == 3 and _tirou(fila[2]) > 0.0 and _tirou(fila[3]) == 0.0, "corrente salta entre 3 alvos e para (%d)" % feitos.size())
	_limpar(fila)
	await get_tree().physics_frame
	# Avanço com dano no caminho; o teleporte chega na hora.
	var no_caminho := _slime(w, p.global_position + Vector2(40, 0))
	var de_lado := _slime(w, p.global_position + Vector2(40, 40))
	await get_tree().physics_frame
	var antes := p.global_position
	var acertados := Golpes.avancar(p, p.global_position + Vector2(200, 0), 80.0, 2.0, &"fisico", 12.0, true)
	await esperar(0.2)
	checar(acertados.size() == 1 and _tirou(no_caminho) > 0.0 and _tirou(de_lado) == 0.0, "avanço acerta só quem está no caminho")
	checar(absf(p.global_position.x - antes.x - 80.0) < 4.0, "o avanço vai até o alcance (%.0f px)" % (p.global_position.x - antes.x))
	p.global_position = antes
	_limpar([no_caminho, de_lado])
	# Estado em volta (Medo do Grito de guerra).
	var perto := _slime(w, p.global_position + Vector2(20, 0))
	var distante := _slime(w, p.global_position + Vector2(120, 0))
	await get_tree().physics_frame
	Golpes.estado_em_volta(p, p.global_position, 50.0, EfeitosEstado.MEDO, 1.5)
	checar(perto.efeitos.tem(EfeitosEstado.MEDO) and not distante.efeitos.tem(EfeitosEstado.MEDO), "estado em volta pega só quem está perto")
	_limpar([perto, distante])


func _buffs(w: World, p: Player) -> void:
	var alvo := _slime(w, p.global_position + Vector2(16, -4))
	await get_tree().physics_frame
	p.mira_forcada = alvo.global_position
	p.golpear()
	await get_tree().physics_frame
	var normal := _tirou(alvo)
	var ganharam := Golpes.buff_em_volta(p, 60.0, Buffs.DANO, 0.5, 2.0)
	checar(ganharam.has(p) and is_equal_approx(p.buffs.mult(Buffs.DANO), 1.5), "buff em volta dá o buff ao jogador")
	await esperar(0.4)
	p.zerar_golpe()  # L40: recomeça o ritmo e o combo (número exato)
	p.golpear()
	await get_tree().physics_frame
	var forte := _tirou(alvo) - normal
	checar(absf(forte - normal * 1.5) < 0.01, "buff de dano: +50%% (%.2f contra %.2f)" % [forte, normal])
	alvo.queue_free()
	var vel := p.multiplicador_velocidade()
	p.buffs.dar(Buffs.VELOCIDADE, 0.2, 1.0)
	checar(absf(p.multiplicador_velocidade() - vel * 1.2) < 0.01, "buff de velocidade: +20%")
	p.buffs.dar(Buffs.REDUCAO, 0.5, 1.0)
	var v := p.vida.atual
	p.hurtbox.receber(10.0, &"fisico", null)
	checar(absf(v - p.vida.atual - 5.0) < 0.01, "buff de redução: 50%% menos dano (%.1f)" % (v - p.vida.atual))
	p.buffs.dar(Buffs.ESCUDO, 7.0, 2.0)
	checar(is_equal_approx(p.vida.escudo, 7.0), "buff de escudo vira escudo da vida")
	p.vida.atual = p.vida.maximo - 10.0
	p.buffs.dar(Buffs.REGENERACAO, 2.0, 2.5)
	await esperar(2.1)
	checar(is_equal_approx(p.vida.atual, p.vida.maximo - 6.0), "regeneração: 2 por segundo (vida %.0f de %.0f)" % [p.vida.atual, p.vida.maximo])
	await esperar(0.5)
	checar(not p.buffs.tem(Buffs.REGENERACAO) and not p.buffs.tem(Buffs.VELOCIDADE), "os buffs acabam sozinhos")
	p.vida.curar_tudo()


func _companheiro(w: World, p: Player) -> void:
	var c := Companheiro.criar_companheiro(p)
	c.dano = 1.0
	c.intervalo = 0.3
	c.iniciar()
	await get_tree().physics_frame
	var meus := Companheiro.de(p)
	checar(meus.size() == 1 and meus[0] == c, "o companheiro é do jogador")
	# Sem alvo, segue o dono.
	p.global_position += Vector2(-60, 0)
	await esperar(1.2)
	checar(c.global_position.distance_to(p.global_position) < 26.0, "sem alvo, segue o dono (%.0f px)" % c.global_position.distance_to(p.global_position))
	# O dono acerta um slime: o companheiro vai atrás e ataca.
	var alvo := _slime(w, p.global_position + Vector2(16, -4))
	await get_tree().physics_frame
	p.mira_forcada = alvo.global_position
	p.golpear()
	await get_tree().physics_frame
	checar(p.ultimo_alvo == alvo, "o jogador lembra o último alvo")
	var depois_golpe := _tirou(alvo)
	await esperar(1.0)
	checar(_tirou(alvo) > depois_golpe, "o companheiro ataca o alvo do dono (%.1f → %.1f)" % [depois_golpe, _tirou(alvo)])
	alvo.queue_free()
	c.queue_free()
	await get_tree().physics_frame


func _recursos(w: World, p: Player) -> void:
	checar(w.hud.barra_recurso() == null, "o mago não tem barra de Fúria nem de combo")
	# Guerreiro: a Fúria enche ao bater e ao apanhar.
	p.classe = &"guerreiro"
	var alvo := _slime(w, p.global_position + Vector2(16, -4))
	await get_tree().physics_frame
	p.mira_forcada = alvo.global_position
	p.golpear()
	await get_tree().physics_frame
	checar(is_equal_approx(p.recursos.furia, RecursosClasse.FURIA_POR_ACERTO), "Fúria enche ao bater (%.0f)" % p.recursos.furia)
	p.hurtbox.receber(10.0, &"fisico", null)
	checar(p.recursos.furia > RecursosClasse.FURIA_POR_ACERTO, "Fúria enche ao apanhar (%.0f)" % p.recursos.furia)
	await esperar(0.05)
	var barra := w.hud.barra_recurso()
	checar(barra != null and absf(barra.value - p.recursos.furia) < 0.01, "o HUD mostra a barra de Fúria (%.0f)" % (barra.value if barra else -1.0))
	p.recursos.ganhar_furia(200.0)
	checar(p.recursos.furia_cheia() and p.recursos.gastar_furia(50.0) and is_equal_approx(p.recursos.furia, 50.0), "Fúria enche até 100 e gasta")
	p.recursos.furia = 0.0
	# Ladino: cada golpe dá 1 ponto de combo (até 5); o finalizador gasta todos.
	p.classe = &"ladino"
	for k in 6:
		await esperar(0.4)
		p.zerar_golpe()  # L40: o ritmo do ladino não importa aqui, só a contagem
		p.golpear()
		await get_tree().physics_frame
	checar(p.recursos.combo == RecursosClasse.COMBO_MAXIMO, "cada golpe dá 1 ponto de combo, até 5 (%d)" % p.recursos.combo)
	await esperar(0.05)
	barra = w.hud.barra_recurso()
	checar(barra != null and is_equal_approx(barra.value, 100.0), "o HUD mostra os pontos de combo")
	checar(p.recursos.gastar_combo() == 5 and p.recursos.combo == 0, "o finalizador gasta os pontos")
	alvo.queue_free()
	p.classe = &"mago"
	await esperar(0.05)
