extends TesteBase
## Raças e classes novas: Elfo (Passo leve: +10% de velocidade), Anão (Mineiro: pedra 25% mais
## rápido), Ladino (Golpe furtivo, Lâmina envenenada, Bomba de fumaça, Leque de adagas) e
## Clérigo (Cura, Escudo sagrado, Luz sagrada, Bênção).

const SLIME := preload("res://scenes/enemies/slime.tscn")
const ANIMAL := preload("res://scenes/animals/animal.tscn")
const PEDRA := preload("res://scenes/world/pedra.tscn")
const JOGADOR := preload("res://scenes/player/player.tscn")
const VIDA_SLIME := 20.0  # vida alta: nenhum slime morre no meio da medição


func _ready() -> void:
	_dados()
	await _ladino()
	await _clerigo()
	await _elfo()
	await _anao()
	terminar()


# --- Ajudantes --------------------------------------------------------------------------

## Slime que não pensa nem anda, com vida alta: só mede o efeito da habilidade.
func _slime_parado(w: World, pos: Vector2, noturno := false) -> Slime:
	var s: Slime = SLIME.instantiate()
	s.noturno = noturno
	s.position = pos
	w.entidades.add_child(s, true)
	s.set_physics_process(false)
	s.vida.maximo = VIDA_SLIME
	s.vida.atual = VIDA_SLIME
	return s


## Slime vivo (persegue), com vida alta.
func _slime_vivo(w: World, pos: Vector2) -> Slime:
	var s: Slime = colocar(w, SLIME, pos)
	s.vida.maximo = VIDA_SLIME
	s.vida.atual = VIDA_SLIME
	return s


func _tirou(s: Slime) -> float:
	return VIDA_SLIME - (s.vida.atual if is_instance_valid(s) else 0.0)


## Zera recargas e enche a mana para usar a habilidade de novo.
func _recarregar(p: Player) -> void:
	p._recargas.fill(0.0)
	p._prontas_no_anfitriao.clear()
	p.mana = p.ficha.mana_maxima()


## Outro jogador no mundo (aliado do clérigo). Nome = id de rede diferente do anfitrião.
func _aliado(w: World, nome: String, pos: Vector2) -> Player:
	var a: Player = JOGADOR.instantiate()
	a.name = nome
	a.position = pos
	w.entidades.add_child(a)
	return a


func _fim_do_mundo(w: World) -> void:
	w.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


# --- Dados -----------------------------------------------------------------------------------

func _dados() -> void:
	checar(RacaData.TODAS.size() == 4 and ClasseData.TODAS.size() == 5, "4 raças e 5 classes")
	var elfo := Ficha.criar(&"elfo", &"ladino")
	checar(elfo.raca.nome == "Elfo" and elfo.valor(&"agilidade") == 10 and elfo.valor(&"intelecto") == 4 and elfo.valor(&"vitalidade") == 4,
			"Elfo: agilidade +2, intelecto +1, vitalidade -1")
	var anao := Ficha.criar(&"anao", &"guerreiro")
	checar(anao.raca.nome == "Anão" and anao.valor(&"vitalidade") == 9 and anao.valor(&"forca") == 8 and anao.valor(&"agilidade") == 4,
			"Anão: vitalidade +2, força +1, agilidade -1")
	checar(Ficha.criar(&"elfo", &"clerigo").titulo() == "Elfo Clérigo", "o título junta raça e classe")
	for id in [&"ladino", &"clerigo"]:
		var c := ClasseData.carregar(id)
		var total := 0
		for a in Ficha.ATRIBUTOS:
			total += c.atributos.get(a, 0)
		checar(c.habilidades.size() == 4 and total == 25, "%s: 4 habilidades e 25 pontos de atributo" % c.nome)
	checar(Ficha.criar(&"humano", &"ladino").valor(&"agilidade") == 9 and Ficha.criar(&"humano", &"clerigo").valor(&"espirito") == 9,
			"Ladino tem foco em agilidade e Clérigo em espírito")
	for par in [[&"adagas", &""], [&"maca", &""], [&"roupa_ladino", &"corpo"], [&"bandana_ladino", &"cabeca"], [&"roupa_clerigo", &"corpo"], [&"touca_clerigo", &"cabeca"]]:
		var existe := ItemData.existe(par[0])
		checar(existe and ItemData.carregar(par[0]).equipa == par[1], "item %s existe (%s)" % [par[0], "veste na " + String(par[1]) if par[1] != &"" else "arma"])
	checar(ItemData.carregar(&"adagas").ferramenta == &"espada" and ItemData.carregar(&"maca").ferramenta == &"espada", "adagas e maça golpeiam como espada")
	checar(Player.KIT[&"ladino"] == &"adagas" and Player.KIT[&"clerigo"] == &"maca", "o kit do Ladino é adagas e o do Clérigo é maça")
	checar(Player.ROUPAS_BASE[&"ladino"] == [&"bandana_ladino", &"roupa_ladino"] and Player.ROUPAS_BASE[&"clerigo"] == [&"touca_clerigo", &"roupa_clerigo"],
			"roupas base de cada classe nova")
	var texto := TextoHabilidade.de_habilidade(ClasseData.carregar(&"clerigo").habilidades[0], "Q", Ficha.criar(&"humano", &"clerigo"))
	checar(texto.efeitos[0].contains("28"), "o texto da Cura mostra a cura real (%s)" % texto.efeitos[0])


# --- Ladino ----------------------------------------------------------------------------------

func _ladino() -> void:
	var w := await criar_mundo(0, true, &"ladino")
	var p := w.jogador
	var mult := p.ficha.multiplicador_fisico()
	checar(p.inventario.quantidade_de(&"adagas") == 1, "o Ladino nasce com as adagas")
	checar(p.equipado.get("corpo") == &"roupa_ladino" and p.equipado.get("cabeca") == &"bandana_ladino", "o Ladino nasce de colete e bandana")
	checar(p.habilidades().size() == 4 and p.habilidades()[0].id == &"golpe_furtivo", "o Ladino tem 4 habilidades")

	# Golpe furtivo num inimigo que não persegue: dano dobrado, e o ladino avança até ele.
	var parado := _slime_parado(w, p.global_position + Vector2(52, 0))
	await get_tree().physics_frame
	p.mira_forcada = parado.global_position
	var x0 := p.global_position.x
	p.usar_habilidade_por_id(&"golpe_furtivo")
	await esperar(0.4)
	var esperado := 2.5 * mult * 2.0
	checar(absf(_tirou(parado) - esperado) < 0.01, "golpe furtivo em quem não persegue: dano dobrado (%.2f, esperado %.2f)" % [_tirou(parado), esperado])
	checar(p.global_position.x - x0 > 25.0, "o ladino avançou até o inimigo (%.0f px)" % (p.global_position.x - x0))
	parado.queue_free()

	# Contra quem já persegue o ladino, o dano é o normal.
	_recarregar(p)
	p.global_position = w.centro + Vector2(0, 80)
	await get_tree().physics_frame
	var vivo := _slime_vivo(w, p.global_position + Vector2(55, 0))
	await esperar(0.25)
	checar(vivo.persegue(p), "o slime persegue o ladino")
	p.mira_forcada = vivo.global_position
	p.usar_habilidade_por_id(&"golpe_furtivo")
	await esperar(0.2)
	checar(absf(_tirou(vivo) - 2.5 * mult) < 0.01, "golpe furtivo em quem persegue: dano normal (%.2f, esperado %.2f)" % [_tirou(vivo), 2.5 * mult])
	vivo.queue_free()

	# Lâmina envenenada: o golpe dura 6 s e o veneno tira vida por segundo, por 3 s.
	_recarregar(p)
	p.global_position = w.centro + Vector2(0, 80)
	await get_tree().physics_frame
	# Preso (não anda nem ataca), mas "pensando": o veneno corre no _physics_process dele.
	var alvo := _slime_parado(w, p.global_position + Vector2(14, 0))
	alvo.set_physics_process(true)
	alvo.prender(60.0)
	var ovelha: Animal = ANIMAL.instantiate()
	ovelha.especie = &"ovelha"
	ovelha.position = p.global_position + Vector2(0, 60)
	w.entidades.add_child(ovelha, true)
	await get_tree().physics_frame
	checar(not p.golpes_envenenados(), "antes da Lâmina, os golpes não envenenam")
	p.usar_habilidade_por_id(&"lamina_envenenada")
	await esperar(0.2)
	checar(p.golpes_envenenados(), "a Lâmina envenenada liga o veneno nos golpes")
	p.mira_forcada = alvo.global_position
	p.golpear()
	await get_tree().physics_frame
	var golpe := _tirou(alvo)
	checar(golpe > 0.0 and alvo.envenenado, "o golpe acerta e envenena (%.2f de dano)" % golpe)
	ovelha.envenenar(Player.TEMPO_VENENO, 0.5)
	await esperar(1.3)
	var por_tick := 0.6 * mult
	checar(absf(_tirou(alvo) - golpe - por_tick) < 0.01, "primeiro segundo: 1 pancada de veneno (%.2f)" % (_tirou(alvo) - golpe))
	await esperar(2.2)
	var veneno_total := por_tick * 3.0
	checar(absf(_tirou(alvo) - golpe - veneno_total) < 0.01, "o veneno dura 3 s e tira %.2f no total (tirou %.2f)" % [veneno_total, _tirou(alvo) - golpe])
	checar(not alvo.envenenado, "o veneno acaba")
	checar(absf(ovelha.vida.atual - (ovelha.vida.maximo - 1.5)) < 0.01, "animal também envenena (vida %.1f de %.1f)" % [ovelha.vida.atual, ovelha.vida.maximo])
	await esperar(3.0)
	checar(not p.golpes_envenenados(), "depois de 6 s os golpes voltam ao normal")
	alvo.queue_free()
	ovelha.queue_free()

	# Bomba de fumaça: o slime que perseguia perde o ladino de vista; o ladino fica transparente.
	_recarregar(p)
	p.global_position = w.centro + Vector2(0, 80)
	await get_tree().physics_frame
	var perseguidor := _slime_vivo(w, p.global_position + Vector2(70, 0))
	await esperar(0.25)
	checar(perseguidor.persegue(p), "antes da fumaça, o slime persegue")
	p.usar_habilidade_por_id(&"bomba_fumaca")
	await esperar(0.3)
	checar(p.escondido(), "a Bomba de fumaça esconde o ladino")
	checar(p.modulate.a < 0.6, "o ladino fica meio transparente (alfa %.2f)" % p.modulate.a)
	checar(not perseguidor.persegue(p) and perseguidor._alvo_atual == null, "o slime perde o ladino de vista e para de perseguir")
	await esperar(3.0)
	checar(not p.escondido() and is_equal_approx(p.modulate.a, 1.0), "depois de 3 s o ladino volta ao normal")
	perseguidor.queue_free()

	# Leque de adagas: 3 adagas, cada uma acerta um slime do leque.
	_recarregar(p)
	p.global_position = w.centro + Vector2(0, 80)
	await get_tree().physics_frame
	var leque: Array[Slime] = []
	for ang in [-0.28, 0.0, 0.28]:
		leque.append(_slime_parado(w, p.global_position + Vector2(46, 0).rotated(ang)))
	await get_tree().physics_frame
	p.mira_forcada = p.global_position + Vector2(200, -10)
	p.usar_habilidade_por_id(&"leque_adagas")
	await get_tree().physics_frame
	checar(get_tree().get_nodes_in_group(&"projeteis").size() == 3, "o leque lança 3 adagas (%d)" % get_tree().get_nodes_in_group(&"projeteis").size())
	await esperar(0.5)
	var acertos := 0
	for s in leque:
		if absf(_tirou(s) - 1.0 * mult) < 0.01:
			acertos += 1
	checar(acertos == 3, "cada adaga acerta um inimigo (%d de 3)" % acertos)
	await _fim_do_mundo(w)


# --- Clérigo -----------------------------------------------------------------------------------

func _clerigo() -> void:
	var w := await criar_mundo(0, true, &"clerigo")
	var p := w.jogador
	checar(p.inventario.quantidade_de(&"maca") == 1, "o Clérigo nasce com a maça")
	checar(p.equipado.get("corpo") == &"roupa_clerigo" and p.equipado.get("cabeca") == &"touca_clerigo", "o Clérigo nasce de túnica e touca")
	checar(p.habilidades().size() == 4 and p.habilidades()[3].id == &"bencao", "o Clérigo tem 4 habilidades")
	p.global_position = w.centro + Vector2(0, 80)
	var perto := _aliado(w, "2", p.global_position + Vector2(30, 0))
	var longe := _aliado(w, "3", p.global_position + Vector2(220, 0))
	await get_tree().physics_frame
	var todos: Array[Player] = [p, perto, longe]

	# Cura: cura ele e o aliado perto; quem está longe não recebe.
	for j in todos:
		j.vida.atual = j.vida.maximo - 50.0
	var cura := Logicas.Cura.quantidade(p.ficha)
	p.usar_habilidade_por_id(&"cura")
	await esperar(0.2)
	checar(absf(p.vida.atual - (p.vida.maximo - 50.0 + cura)) < 0.01, "Cura cura o clérigo (+%.0f)" % cura)
	checar(absf(perto.vida.atual - (perto.vida.maximo - 50.0 + cura)) < 0.01, "Cura cura o aliado perto (+%.0f)" % cura)
	checar(absf(longe.vida.atual - (longe.vida.maximo - 50.0)) < 0.01, "Cura não chega no aliado longe")

	# Escudo sagrado: 50% menos dano para ele e o aliado perto.
	_recarregar(p)
	for j in todos:
		j.vida.curar_tudo()
	p.usar_habilidade_por_id(&"escudo_sagrado")
	await esperar(0.2)
	for j in todos:
		j.vida.tomar_dano(10.0)
	checar(absf(p.vida.maximo - p.vida.atual - 5.0) < 0.01, "Escudo sagrado: o clérigo toma 5 de 10")
	checar(absf(perto.vida.maximo - perto.vida.atual - 5.0) < 0.01, "Escudo sagrado: o aliado perto toma 5 de 10")
	checar(absf(longe.vida.maximo - longe.vida.atual - 10.0) < 0.01, "Escudo sagrado: o aliado longe toma os 10")
	await esperar(4.0)
	for j in todos:
		j.vida.curar_tudo()
		j.vida.tomar_dano(10.0)
	checar(absf(p.vida.maximo - p.vida.atual - 10.0) < 0.01, "o Escudo sagrado acaba depois de 4 s")

	# Luz sagrada: dano em volta; triplo no slime da noite.
	_recarregar(p)
	p.global_position = w.centro + Vector2(0, 80)
	var dia := _slime_parado(w, p.global_position + Vector2(-24, 0))
	var noite := _slime_parado(w, p.global_position + Vector2(24, 0), true)
	await get_tree().physics_frame
	var dano := 2.0 * p.ficha.multiplicador_magico()
	p.usar_habilidade_por_id(&"luz_sagrada")
	await esperar(0.2)
	checar(absf(_tirou(dia) - dano) < 0.01, "Luz sagrada machuca o slime do dia (%.2f)" % _tirou(dia))
	checar(absf(_tirou(noite) - dano * 3.0) < 0.01, "Luz sagrada dá o triplo no slime da noite (%.2f, esperado %.2f)" % [_tirou(noite), dano * 3.0])
	dia.queue_free()
	noite.queue_free()

	# Bênção: vida aos poucos, por 8 s, só para quem está perto.
	_recarregar(p)
	var base: Dictionary = {}  # vida de cada um logo depois de apanhar
	for j in todos:
		j.vida.atual = j.vida.maximo - 50.0
		base[j] = j.vida.atual
	p.usar_habilidade_por_id(&"bencao")
	await esperar(2.4)
	checar(absf(p.vida.atual - base[p] - 6.0) < 0.01, "Bênção: +3 por segundo (%.1f em 2 s)" % (p.vida.atual - base[p]))
	checar(absf(perto.vida.atual - base[perto] - 6.0) < 0.01, "Bênção: o aliado perto também regenera (%.1f)" % (perto.vida.atual - base[perto]))
	checar(absf(longe.vida.atual - base[longe]) < 0.01, "Bênção: o aliado longe não regenera")
	await esperar(6.4)
	checar(absf(p.vida.atual - base[p] - 24.0) < 0.01 and not p.abencoado(), "Bênção dura 8 s e rende 24 de vida (%.1f)" % (p.vida.atual - base[p]))
	await _fim_do_mundo(w)


# --- Raças ------------------------------------------------------------------------------------

func _elfo() -> void:
	var w := await criar_mundo(0, true, &"ladino", &"elfo")
	var p := w.jogador
	var humano := Ficha.criar(&"humano", &"ladino")
	var esperado := (68.0 + p.ficha.valor(&"agilidade") * 2.0) * 1.1
	checar(is_equal_approx(p.ficha.velocidade(), esperado), "Elfo: Passo leve soma 10%% (%.1f)" % p.ficha.velocidade())
	checar(is_equal_approx(Ficha.criar(&"elfo", &"ladino").velocidade() / (68.0 + 10.0 * 2.0), 1.1), "o bônus de velocidade é de 10% sobre a mesma agilidade")
	checar(p.ficha.velocidade() > humano.velocidade(), "o Elfo é mais rápido que o Humano (%.1f > %.1f)" % [p.ficha.velocidade(), humano.velocidade()])
	var antes := p.global_position
	Input.action_press(&"mover_direita")
	await esperar(0.5)
	Input.action_release(&"mover_direita")
	var andou := p.global_position.x - antes.x
	var previsto := p.ficha.velocidade() * 0.5
	checar(andou > previsto * 0.8 and andou < previsto * 1.1, "o Elfo anda de verdade na velocidade da ficha (%.1f px, previsto %.1f)" % [andou, previsto])
	await _fim_do_mundo(w)


func _anao() -> void:
	var w := await criar_mundo(0, true, &"guerreiro", &"anao")
	var p := w.jogador
	var humano := Ficha.criar(&"humano", &"guerreiro")
	checar(is_equal_approx(p.ficha.tempo_coleta(true), p.ficha.tempo_coleta(false) / 1.25), "Anão: Mineiro quebra pedra 25% mais rápido")
	checar(is_equal_approx(humano.tempo_coleta(true), humano.tempo_coleta(false)), "o Humano não ganha nada na pedra")
	checar(is_equal_approx(p.ficha.tempo_coleta(false), Ficha.criar(&"anao", &"guerreiro").tempo_coleta(false)), "árvore continua como era para o Anão")

	var pedra: ResourceNode = colocar(w, PEDRA, p.position + Vector2(0, 22))
	p.mira_forcada = pedra.global_position + Vector2(0, -12)
	_ferramenta_para(p, p.mira_forcada)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var com_mineiro := p._tempo_coleta()
	var sem_mineiro := pedra.interacao.tempo_segurar * p.ficha.tempo_coleta(false) / p.poder_da_mao(&"picareta")
	checar(is_equal_approx(com_mineiro * 1.25, sem_mineiro), "o golpe de coleta na pedra dura %.2f s (seria %.2f sem o Mineiro)" % [com_mineiro, sem_mineiro])
	# Na prática: 4 golpes da pedra. Com o Mineiro dá para quebrar antes do tempo que o Humano leva.
	var total_anao := com_mineiro * pedra.golpes
	var total_humano := pedra.interacao.tempo_segurar * humano.tempo_coleta(true) / p.poder_da_mao(&"picareta") * pedra.golpes
	checar(total_anao < total_humano - 0.3, "o Anão quebra a pedra em %.2f s e o Humano em %.2f s" % [total_anao, total_humano])
	await segurar_e(p, pedra.global_position + Vector2(0, -12), (total_anao + total_humano) / 2.0)
	checar(not is_instance_valid(pedra) or pedra.is_queued_for_deletion() or pedra.estado == ResourceNode.Estado.ESGOTADO, "dentro do tempo do Anão a pedra já quebrou")
	await _fim_do_mundo(w)
