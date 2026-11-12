extends TesteBase
## Árvore do Arqueiro: cada nó que era pendente agora funciona. Para cada ativa: aprende, vai
## para as teclas, usa e confere o efeito com números. Para cada passiva: mede a mudança.

const SLIME := preload("res://scenes/enemies/slime.tscn")
const ANIMAL := preload("res://scenes/animals/animal.tscn")

const ATIVAS: Array[StringName] = [
	&"assobio", &"flecha_perfurante", &"marca_do_cacador", &"rajada", &"flecha_do_horizonte",
	&"rede", &"mina_de_fogo", &"torre_de_besta", &"campo_minado",
	&"domar", &"ataque", &"estouro_da_boiada", &"espirito_da_fera",
]

var w: World
var p: Player


func _ready() -> void:
	w = await criar_mundo(0, true, &"arqueiro", &"humano")
	p = w.jogador
	p.global_position = w.centro + Vector2(0, 60)
	await get_tree().physics_frame
	_tabela()
	await _vai_para_as_teclas()
	await _atirador()
	await _engenhoqueiro()
	await _rastreador()
	await _domador()
	terminar()


# --- Ajudas ---------------------------------------------------------------------------

## Slime parado (sem pensar), com 100 de vida.
func _slime(pos: Vector2) -> Slime:
	var s: Slime = colocar(w, SLIME, pos)
	s.set_physics_process(false)
	s.vida.maximo = 100.0
	s.vida.atual = 100.0
	return s


func _tirou(s: Node) -> float:
	if not is_instance_valid(s):
		return 100.0
	return s.vida.maximo - s.vida.atual


func _limpar() -> void:
	for g in [&"inimigos", &"animais", &"invocacoes", &"projeteis", &"armadilhas"]:
		for n in get_tree().get_nodes_in_group(g):
			n.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame


## Usa a habilidade `id` mirando em `mira` (mana cheia, sem recarga).
func _usar(id: StringName, mira: Vector2) -> void:
	p.aprender_de_graca(id)
	p.teclas = [id] as Array[StringName]
	p.mana = p.ficha.mana_maxima()
	p._recargas.clear()
	p._prontas_no_anfitriao.clear()
	p.mira_forcada = mira
	await get_tree().physics_frame
	checar(p.usar_habilidade_por_id(id), "%s está nas teclas e foi usada" % id)
	await get_tree().physics_frame


func _hab(id: StringName) -> HabilidadeData:
	return ArvoreData.no(&"arqueiro", id).habilidade


func _dano(id: StringName) -> float:
	return HabilidadeLogica.dano_de(p, _hab(id))


# --- Testes ---------------------------------------------------------------------------

func _tabela() -> void:
	var ruins: Array[String] = []
	for n in ArvoreData.nos(&"arqueiro"):
		if n.pendente or n.falta != "":
			ruins.append(String(n.id))
	checar(ruins.is_empty(), "nenhum nó do Arqueiro está pendente ou parcial (%s)" % ", ".join(ruins))
	var sem: Array[String] = []
	for id in ATIVAS:
		var n := ArvoreData.no(&"arqueiro", id)
		if not n.usavel() or n.rank_maximo() != 4 or n.habilidade.logica == &"" or Logicas.classe_da_logica(n.habilidade.logica) == null:
			sem.append(String(id))
	checar(sem.is_empty(), "as 13 ativas novas têm .tres, lógica registrada e aceitam 3 melhorias (%s)" % ", ".join(sem))


func _vai_para_as_teclas() -> void:
	p.aprender_de_graca(&"assobio")
	await get_tree().physics_frame
	checar(p.ids_nas_teclas().size() == 3 and p.ids_nas_teclas()[2] == &"assobio", "aprendido, o Assobio vai para a tecla T")
	# Melhoria: +15% de dano e 10% menos recarga.
	p.arvore[&"rajada"] = 3
	var h := _hab(&"rajada")
	checar(is_equal_approx(p.mult_habilidade(h), 1.3) and is_equal_approx(p.recarga_de(h), h.recarga * 0.8), "Rajada com 2 melhorias: dano x%.2f e recarga %.2f s" % [p.mult_habilidade(h), p.recarga_de(h)])
	p.arvore[&"rajada"] = 1


func _atirador() -> void:
	var o := p.global_position
	# Flecha perfurante: 3 slimes em linha.
	var linha: Array[Slime] = []
	for k in 3:
		linha.append(_slime(o + Vector2(30 + 22 * k, 0)))
	await _usar(&"flecha_perfurante", o + Vector2(100, -10))
	await esperar(0.8)
	var esperado := _dano(&"flecha_perfurante")
	checar(linha.all(func(s: Slime) -> bool: return absf(_tirou(s) - esperado) < 0.01), "Flecha perfurante: atravessa e tira %.2f de cada um dos 3 (%.2f, %.2f, %.2f)" % [esperado, _tirou(linha[0]), _tirou(linha[1]), _tirou(linha[2])])
	await _limpar()

	# Marca do caçador: Marcado +20% por 8 s.
	var s := _slime(o + Vector2(50, 0))
	await _usar(&"marca_do_cacador", s.global_position + Vector2(0, -6))
	await esperar(0.5)
	checar(s.efeitos.tem(EfeitosEstado.MARCADO) and is_equal_approx(s.efeitos.mult_dano_recebido(), 1.2) and s.efeitos.restante(EfeitosEstado.MARCADO) > 7.0, "Marca do caçador: o alvo fica Marcado (toma x%.2f) por %.1f s" % [s.efeitos.mult_dano_recebido(), s.efeitos.restante(EfeitosEstado.MARCADO)])
	await _limpar()

	# Rajada: 3 flechas no mesmo alvo.
	s = _slime(o + Vector2(50, 0))
	await _usar(&"rajada", s.global_position + Vector2(0, -6))
	await esperar(1.0)
	checar(absf(_tirou(s) - 3.0 * _dano(&"rajada")) < 0.01, "Rajada: 3 flechas, %.2f de dano (3 x %.2f)" % [_tirou(s), _dano(&"rajada")])
	await _limpar()

	# Flecha do horizonte: atravessa e vai longe (perto e a 300 px).
	var perto := _slime(o + Vector2(40, 0))
	var longe := _slime(o + Vector2(300, 0))
	await _usar(&"flecha_do_horizonte", o + Vector2(100, -10))
	await esperar(1.6)
	checar(absf(_tirou(perto) - _dano(&"flecha_do_horizonte")) < 0.01 and absf(_tirou(longe) - _dano(&"flecha_do_horizonte")) < 0.01, "Flecha do horizonte: %.1f de dano no de perto e %.1f no de 300 px" % [_tirou(perto), _tirou(longe)])
	await _limpar()

	# Sangue frio: acerto crítico (de mais de 6 blocos) devolve 3 de mana.
	var gasto_sem := await _mana_gasta_tiro_longe()
	p.aprender_de_graca(&"sangue_frio")
	var gasto_com := await _mana_gasta_tiro_longe()
	checar(absf((gasto_sem - gasto_com) - PassivasArqueiro.SANGUE_FRIO_MANA) < 0.05, "Sangue frio: o tiro de longe custou %.2f de mana (sem a passiva: %.2f)" % [gasto_com, gasto_sem])
	# Num alvo Marcado (de perto) também é crítico.
	var m := _slime(o + Vector2(40, 0))
	EfeitosEstado.aplicar_em(m, EfeitosEstado.MARCADO, 5.0, 0.2, p)
	checar(PassivasArqueiro.critico(p, m) and not PassivasArqueiro.critico(p, _slime(o + Vector2(-40, 0))), "Sangue frio: alvo Marcado conta como crítico; de perto sem marca, não")
	await _limpar()


## Mana gasta por um Tiro carregado num slime a 120 px (sem regenerar no meio).
func _mana_gasta_tiro_longe() -> float:
	var s := _slime(p.global_position + Vector2(120, 0))
	p.teclas = [&"tiro_carregado"] as Array[StringName]
	p._recargas.clear()
	p._prontas_no_anfitriao.clear()
	p.mana = 20.0
	p.mira_forcada = s.global_position + Vector2(0, -6)
	await get_tree().physics_frame
	var antes := p.mana
	var regen := p.ficha.regeneracao_mana() * Passivas.regeneracao_mana(p)
	var t0 := Time.get_ticks_msec()
	p.usar_habilidade_por_id(&"tiro_carregado", 0.0)
	await esperar(1.0)
	var depois := p.mana - regen * (Time.get_ticks_msec() - t0) / 1000.0
	checar(_tirou(s) > 0.0, "o tiro de longe acertou")
	s.queue_free()
	await get_tree().physics_frame
	return antes - depois


func _engenhoqueiro() -> void:
	var o := p.global_position
	# Rede: o alvo fica Preso por 3 s.
	var s := _slime(o + Vector2(50, 0))
	await _usar(&"rede", s.global_position + Vector2(0, -6))
	await esperar(0.6)
	checar(s.efeitos.tem(EfeitosEstado.PRESO) and s.efeitos.restante(EfeitosEstado.PRESO) > 2.0 and not s.efeitos.pode_mover(), "Rede: o alvo fica preso (não anda) por mais %.1f s" % s.efeitos.restante(EfeitosEstado.PRESO))
	await _limpar()

	# Mina de fogo: armada no chão; quem pisa explode e queima.
	await _usar(&"mina_de_fogo", o + Vector2(40, 0))
	var minas := get_tree().get_nodes_in_group(&"minas")
	checar(minas.size() == 1 and (minas[0] as Node2D).global_position.distance_to(o + Vector2(40, 0)) < 1.0, "Mina de fogo: uma mina armada no ponto da mira")
	var vitima := _slime(o + Vector2(40, 2))
	var vizinho := _slime(o + Vector2(60, 0))
	await esperar(0.3)
	checar(_tirou(vitima) > 0.0 and vitima.efeitos.tem(EfeitosEstado.QUEIMADURA) and _tirou(vizinho) > 0.0, "Mina de fogo: explode ao pisar, machuca quem está perto (%.2f e %.2f) e deixa Queimadura" % [_tirou(vitima), _tirou(vizinho)])
	checar(get_tree().get_nodes_in_group(&"minas").is_empty(), "a mina some depois de explodir")
	await _limpar()

	# Torre de besta: atira sozinha no inimigo mais perto e some depois de 12 s.
	s = _slime(o + Vector2(80, 0))
	await _usar(&"torre_de_besta", o + Vector2(20, 0))
	var torres := get_tree().get_nodes_in_group(&"torres_besta")
	checar(torres.size() == 1 and is_equal_approx((torres[0] as Invocacao).duracao, 12.0), "Torre de besta: uma torreta de 12 s")
	await esperar(2.0)
	checar(_tirou(s) >= 2.0 * _dano(&"torre_de_besta") - 0.01, "Torre de besta: em 2 s acertou o slime (%.2f de dano)" % _tirou(s))
	await _limpar()

	# Campo minado: 6 minas em volta.
	await _usar(&"campo_minado", o + Vector2(40, 0))
	minas = get_tree().get_nodes_in_group(&"minas")
	checar(minas.size() == 6 and minas.all(func(n: Node2D) -> bool: return absf(n.global_position.distance_to(p.global_position) - 30.0) < 1.0), "Campo minado: 6 minas a 30 px em volta (%d)" % minas.size())
	await _limpar()

	# Reaproveitar: passar por cima de uma mina sua (armada há 1,5 s) recolhe e devolve a mana.
	p.aprender_de_graca(&"reaproveitar")
	await _usar(&"mina_de_fogo", p.global_position + Vector2(30, 0))
	p.mana = 10.0
	await esperar(1.7)
	checar(get_tree().get_nodes_in_group(&"minas").size() == 1, "Reaproveitar: longe da mina, ela continua lá")
	var antes := p.mana
	p.global_position += Vector2(30, 0)
	await esperar(0.1)
	checar(get_tree().get_nodes_in_group(&"minas").is_empty() and p.mana - antes >= _hab(&"mina_de_fogo").custo_mana - 0.01, "Reaproveitar: pisou na mina, recolheu e ganhou %.1f de mana" % (p.mana - antes))
	p.global_position -= Vector2(30, 0)
	await _limpar()


func _rastreador() -> void:
	var bicho: Animal = colocar(w, ANIMAL, p.global_position + Vector2(100, 0))
	bicho.set_physics_process(false)
	p.set_meta(&"pegadas_t", 0.0)  # sem esperar os 5 s do relógio
	await esperar(0.2)
	var efeitos := w.entidades.get_children().filter(func(n: Node) -> bool: return n is Efeito and (n as Node2D).global_position.distance_to(bicho.global_position) < 8.0)
	checar(efeitos.size() >= 1 and float(p.get_meta(&"pegadas_t", 0.0)) > 0.0, "Rastreador: aparecem pegadas (poeira) no animal a 100 px (%d)" % efeitos.size())
	var bicho2: Animal = colocar(w, ANIMAL, p.global_position + Vector2(220, 0))
	p.set_meta(&"pegadas_t", 0.0)
	await esperar(0.1)
	var longe := w.entidades.get_children().filter(func(n: Node) -> bool: return n is Efeito and (n as Node2D).global_position.distance_to(bicho2.global_position) < 8.0)
	checar(longe.is_empty(), "Rastreador: animal a mais de 10 blocos não mostra pegadas")
	await _limpar()


func _domador() -> void:
	var o := p.global_position
	# Assobio: o falcão bica e deixa Marcado por 5 s.
	var s := _slime(o + Vector2(70, 0))
	await _usar(&"assobio", s.global_position)
	var falcao := LogicasArqueiro.falcao_de(p)
	checar(falcao != null and is_equal_approx(falcao.duracao, _duracao_falcao()), "Assobio: chama um falcão temporário")
	await esperar(1.2)
	checar(absf(_tirou(s) - _dano(&"assobio")) < 0.01 and s.efeitos.tem(EfeitosEstado.MARCADO) and s.efeitos.restante(EfeitosEstado.MARCADO) > 3.5, "Assobio: o falcão bicou (%.2f de dano) e o alvo ficou Marcado (%.1f s)" % [_tirou(s), s.efeitos.restante(EfeitosEstado.MARCADO)])
	await _limpar()
	# Sem inimigo: a mana volta.
	p.teclas = [&"assobio"] as Array[StringName]
	p._recargas.clear()
	p._prontas_no_anfitriao.clear()
	p.mana = 20.0
	p.usar_habilidade_por_id(&"assobio")
	await get_tree().physics_frame
	checar(p.mana >= 20.0 - 0.01 and LogicasArqueiro.falcao_de(p) == null, "Assobio sem inimigo perto: não chama o falcão e a mana volta (%.1f)" % p.mana)

	# Laço: o falcão fica sempre e bica quem você acertar.
	p.aprender_de_graca(&"laco")
	await get_tree().physics_frame
	await get_tree().physics_frame
	falcao = LogicasArqueiro.falcao_de(p)
	checar(falcao != null and falcao.duracao == 0.0, "Laço: o falcão aparece e não some sozinho")
	s = _slime(o + Vector2(60, 0))
	await _usar(&"flecha_perfurante", s.global_position + Vector2(0, -6))
	await esperar(1.6)
	var flecha := _dano(&"flecha_perfurante")
	checar(_tirou(s) > flecha + 0.1, "Laço: depois da flecha (%.2f), o falcão bicou o alvo (total %.2f)" % [flecha, _tirou(s)])
	await _limpar()
	await get_tree().physics_frame
	falcao = LogicasArqueiro.falcao_de(p)
	checar(falcao != null, "Laço: se o falcão some, ele volta")
	p.arvore.erase(&"laco")
	if falcao:
		falcao.queue_free()
	await get_tree().physics_frame

	# Domar: animal com vida cheia não aceita; com metade, vira companheiro.
	var bicho: Animal = ANIMAL.instantiate()
	bicho.especie = &"javali"
	bicho.position = o + Vector2(40, 0)
	w.entidades.add_child(bicho, true)
	await get_tree().physics_frame
	bicho.set_physics_process(false)
	await _usar(&"domar", bicho.global_position)
	checar(is_instance_valid(bicho) and LogicasArqueiro.domado_de(p) == null and p.mana >= p.ficha.mana_maxima() - 0.01, "Domar: com a vida cheia o animal não vem e a mana volta")
	bicho.vida.atual = bicho.vida.maximo * 0.4
	await _usar(&"domar", bicho.global_position)
	await get_tree().physics_frame
	var domado := LogicasArqueiro.domado_de(p)
	checar(not is_instance_valid(bicho) and domado != null and domado.get_meta(&"especie") == &"javali" and domado.quadro_inicial == 4, "Domar: o javali com 40% da vida vira companheiro (com a arte do javali)")

	# Ataque!: o companheiro pula no alvo, bate e prende por 1,5 s.
	s = _slime(o + Vector2(100, 0))
	await _usar(&"ataque", s.global_position)
	checar(domado.global_position.distance_to(s.global_position) <= 12.0 and s.efeitos.tem(EfeitosEstado.PRESO) and _tirou(s) >= _dano(&"ataque") - 0.01, "Ataque!: o companheiro pulou no alvo (%.0f px), bateu (%.2f) e o prendeu (%.1f s)" % [domado.global_position.distance_to(s.global_position), _tirou(s), s.efeitos.restante(EfeitosEstado.PRESO)])
	await esperar(1.2)
	checar(domado.alvo_mandado == s and _tirou(s) > _dano(&"ataque") + 0.5, "Ataque!: o companheiro segue atacando o alvo mandado (%.2f)" % _tirou(s))
	s.queue_free()
	await get_tree().physics_frame

	# Matilha: com o companheiro perto, você e ele +15% de velocidade e de dano.
	domado.global_position = p.global_position + Vector2(10, 0)
	var base := domado.dano
	p.aprender_de_graca(&"matilha")
	await get_tree().physics_frame
	await get_tree().physics_frame
	checar(is_equal_approx(p.buffs.valor(Buffs.DANO), 0.15) and is_equal_approx(p.buffs.valor(Buffs.VELOCIDADE), 0.15) and is_equal_approx(domado.dano, base * 1.15), "Matilha: você ganha +15%% de dano e velocidade, e o companheiro bate %.2f (era %.2f)" % [domado.dano, base])
	domado.global_position = p.global_position + Vector2(200, 0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	checar(is_equal_approx(domado.dano, base), "Matilha: longe do companheiro, ele volta ao dano normal")
	p.arvore.erase(&"matilha")
	p.buffs.tirar(Buffs.DANO)
	p.buffs.tirar(Buffs.VELOCIDADE)
	await _limpar()

	# Estouro da boiada: a manada atravessa e derruba tudo no caminho.
	var a := _slime(o + Vector2(40, 0))
	var b := _slime(o + Vector2(120, 0))
	var fora := _slime(o + Vector2(60, 50))
	await _usar(&"estouro_da_boiada", o + Vector2(100, 0))
	var manada := get_tree().get_nodes_in_group(&"invocacoes").size()
	await esperar(0.9)
	checar(manada == 3, "Estouro da boiada: 3 javalis na manada (%d)" % manada)
	checar(a.efeitos.tem(EfeitosEstado.DERRUBADO) and b.efeitos.tem(EfeitosEstado.DERRUBADO) and absf(_tirou(a) - _dano(&"estouro_da_boiada")) < 0.01 and absf(_tirou(b) - _dano(&"estouro_da_boiada")) < 0.01, "Estouro da boiada: os 2 no caminho levam %.1f e %.1f e ficam derrubados" % [_tirou(a), _tirou(b)])
	checar(_tirou(fora) == 0.0, "Estouro da boiada: quem está fora do caminho não leva nada")
	await _limpar()

	# Espírito da fera: +50% de velocidade por 10 s e cada flecha salta para mais um.
	await _usar(&"espirito_da_fera", o)
	checar(is_equal_approx(p.buffs.valor(Buffs.VELOCIDADE), 0.5) and p.buffs.restante(Buffs.VELOCIDADE) > 9.5, "Espírito da fera: +50%% de velocidade por %.1f s" % p.buffs.restante(Buffs.VELOCIDADE))
	var primeiro := _slime(o + Vector2(50, 0))
	var segundo := _slime(o + Vector2(50, 40))
	p.teclas = [&"tiro_carregado"] as Array[StringName]
	p._recargas.clear()
	p.mira_forcada = primeiro.global_position + Vector2(0, -6)
	await get_tree().physics_frame
	p.usar_habilidade_por_id(&"tiro_carregado", 0.0)
	await esperar(1.0)
	checar(_tirou(primeiro) > 0.0 and _tirou(segundo) > 0.0, "Espírito da fera: a flecha acertou um (%.2f) e saltou para o outro (%.2f)" % [_tirou(primeiro), _tirou(segundo)])
	await _limpar()


func _duracao_falcao() -> float:
	return LogicasArqueiro.Assobio.DURACAO_FALCAO
