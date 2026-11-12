extends TesteBase
## Árvore do Mago: cada nó aprende e usa (ou mede a passiva) e confere o efeito com números.
## Ativas: vão para as teclas, gastam mana, entram em recarga e aceitam melhorias.

const SLIME := preload("res://scenes/enemies/slime.tscn")

var w: World
var p: Player
var P := Vector2.ZERO  # onde o mago fica em cada teste
var mm := 1.0  # multiplicador mágico do mago


func _ready() -> void:
	w = await criar_mundo(0, true, &"mago")
	p = w.jogador
	P = w.centro + Vector2(0, 60)
	p.global_position = P
	mm = p.ficha.multiplicador_magico()
	await get_tree().physics_frame
	_todos_funcionam()
	await _faisca()
	await _pedra_viva()
	await _combustao()
	await _rastro_de_chamas()
	await _mini_explosao()
	await _cinzas()
	await _tornado_de_fogo()
	await _chuva_de_meteoros()
	await _frio_que_morde()
	await _muralha_de_gelo()
	await _prisao_de_gelo()
	await _nevasca()
	await _conducao()
	await _corrente_eletrica()
	await _totem_tesla()
	await _forma_de_relampago()
	await _tempestade()
	await _espinhos()
	await _golem_de_pedra()
	await _fenda()
	await _despertar_da_ilha()
	await _tremor()
	terminar()


# --- Ajudantes --------------------------------------------------------------------------

## Slime parado (sem pensar), com 100 de vida.
func _slime(pos: Vector2) -> Slime:
	var s: Slime = colocar(w, SLIME, pos)
	s.set_physics_process(false)
	s.vida.maximo = 100.0
	s.vida.atual = 100.0
	return s


func _tirou(s: Slime) -> float:
	return 100.0 - (s.vida.atual if is_instance_valid(s) else 0.0)


## Some com slimes, zonas, invocações e projéteis; o mago volta para o lugar.
func _limpar() -> void:
	for n in w.entidades.get_children():
		if n is Slime or n is Zona or n is Invocacao or n is Projetil:
			n.queue_free()
	p.global_position = P
	await get_tree().physics_frame
	await get_tree().physics_frame


## Aprende (se precisar) e usa a ativa `id` mirando em `mira`; confere teclas, mana e recarga.
func _usar(id: StringName, mira: Vector2) -> HabilidadeData:
	var hab := ArvoreData.no(&"mago", id).habilidade
	if not p.tem(id):
		p.teclas = ArvoreData.padrao(&"mago").duplicate()
		p.aprender_de_graca(id)
		checar(id in p.ids_nas_teclas(), "%s: aprendida, vai para as teclas Q R T E" % hab.nome)
	elif not id in p.teclas:
		p.teclas = ArvoreData.padrao(&"mago").duplicate()
		p.teclas.append(id)
	p.mana = p.ficha.mana_maxima()
	p._recargas.clear()
	p._prontas_no_anfitriao.clear()
	p._ultimo_elemento = hab.elemento  # sem Ressonância, para os números ficarem exatos
	p.mira_forcada = mira
	var antes := p.mana
	var usou := p.usar_habilidade_por_id(id)
	await get_tree().physics_frame
	checar(usou and absf(antes - p.mana - hab.custo_mana) < 0.5 and float(p._recargas.get(id, 0.0)) > 0.0,
			"%s: gastou %.0f de mana e entrou em recarga (%.1f s)" % [hab.nome, antes - p.mana, float(p._recargas.get(id, 0.0))])
	return hab


## Espera até `segundos` olhando o empurrão de `s`; devolve o primeiro que aparecer.
func _empurrao_de(s: Slime, segundos: float) -> Vector2:
	var fim := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < fim:
		if is_instance_valid(s) and s.efeitos.impulso() != Vector2.ZERO:
			return s.efeitos.impulso()
		await get_tree().physics_frame
	return Vector2.ZERO


func _perto(a: float, b: float, folga := 0.02) -> bool:
	return absf(a - b) <= folga


# --- Testes -----------------------------------------------------------------------------

func _todos_funcionam() -> void:
	var pendentes: Array[String] = []
	var ativas_ok := true
	for n in ArvoreData.nos(&"mago"):
		if n.pendente or n.falta != "":
			pendentes.append(String(n.id))
		if n.ativa() and not (n.usavel() and n.rank_maximo() == 1 + NoArvore.MELHORIAS and Logicas.classe_da_logica(n.habilidade.logica) != null):
			ativas_ok = false
	checar(pendentes.is_empty(), "nenhum nó do Mago pendente ou parcial (%s)" % ", ".join(pendentes))
	checar(ativas_ok, "toda ativa do Mago tem .tres, lógica registrada e aceita 3 melhorias")


func _faisca() -> void:
	checar(p.tem(&"faisca") and is_equal_approx(p.luz.energy, PassivasMago.FAISCA_ENERGIA) and is_equal_approx(p.luz.texture_scale, PassivasMago.FAISCA_TAMANHO),
			"Faísca: a luz do mago fica maior (força %.2f, tamanho %.1f)" % [p.luz.energy, p.luz.texture_scale])
	checar(p.is_in_group(&"luz_protege") and is_equal_approx(float(p.get_meta(&"raio_luz", 0.0)), PassivasMago.FAISCA_RAIO),
			"Faísca: a luz do mago protege da noite a até 1,5 bloco (%.0f px)" % float(p.get_meta(&"raio_luz", 0.0)))


func _pedra_viva() -> void:
	var s := _slime(P + Vector2(48, 0))
	var fora := _slime(P + Vector2(48, 30))
	await get_tree().physics_frame
	var hab := await _usar(&"pedra_viva", P + Vector2(96, 0))
	await esperar(0.8)
	checar(_perto(_tirou(s), hab.dano * mm) and s.efeitos.tem(EfeitosEstado.CEGO) and _perto(s.efeitos.forca(EfeitosEstado.CEGO), 0.3),
			"Pedra viva: %.2f de dano (esperado %.2f) e Desequilíbrio de 30%%" % [_tirou(s), hab.dano * mm])
	checar(_tirou(fora) == 0.0, "Pedra viva: quem está fora do caminho não leva")
	await _limpar()


func _combustao() -> void:
	p.aprender_de_graca(&"combustao")
	var a := _slime(P + Vector2(40, 0))
	var colado := _slime(P + Vector2(56, 0))
	await get_tree().physics_frame
	await _usar(&"bola_de_fogo", a.global_position)
	await esperar(0.4)
	var ea := a.efeitos
	checar(_tirou(a) > 0.0 and ea.tem(EfeitosEstado.QUEIMADURA) and ea.restante(EfeitosEstado.QUEIMADURA) > 5.0,
			"Combustão: a Bola de fogo deixa Queimadura de 6 s (faltam %.1f s)" % ea.restante(EfeitosEstado.QUEIMADURA))
	checar(_tirou(colado) == 0.0 and colado.efeitos.tem(EfeitosEstado.QUEIMADURA), "Combustão: a Queimadura passou para o inimigo colado")
	await _limpar()


func _rastro_de_chamas() -> void:
	var s := _slime(P + Vector2(40, 0))
	await get_tree().physics_frame
	await _usar(&"rastro_de_chamas", P + Vector2(40, 0))
	await esperar(0.6)
	checar(get_tree().get_nodes_in_group(&"brasas").size() == 1, "Rastro de chamas: parado, fica uma brasa só")
	for k in 4:
		p.global_position += Vector2(12, 0)
		await esperar(0.3)
	var brasas := get_tree().get_nodes_in_group(&"brasas").size()
	await esperar(0.6)
	checar(brasas >= 4, "Rastro de chamas: andando, o chão pega fogo atrás (%d brasas)" % brasas)
	checar(_tirou(s) > 0.0 and s.efeitos.tem(EfeitosEstado.QUEIMADURA), "Rastro de chamas: o slime no caminho levou %.2f e está queimando" % _tirou(s))
	await _limpar()


func _mini_explosao() -> void:
	var s := _slime(P + Vector2(60, 0))
	var vizinho := _slime(P + Vector2(60, 20))
	await get_tree().physics_frame
	var hab := await _usar(&"mini_explosao", s.global_position)
	var emp := await _empurrao_de(vizinho, 1.5)
	var esperado := hab.dano * mm * 2.0  # slime leva o dobro de fogo
	checar(_perto(_tirou(vizinho), esperado) and vizinho.efeitos.tem(EfeitosEstado.QUEIMADURA),
			"Mini explosão: dano em área %.2f (esperado %.2f) e Queimadura" % [_tirou(vizinho), esperado])
	checar(emp.y > 0.0, "Mini explosão: empurra para longe (%.0f, %.0f)" % [emp.x, emp.y])
	await _limpar()


func _cinzas() -> void:
	p.aprender_de_graca(&"cinzas")
	var a := _slime(P + Vector2(60, 0))
	var b := _slime(P + Vector2(76, 0))
	a.vida.atual = 0.2
	await get_tree().physics_frame
	EfeitosEstado.aplicar_em(a, EfeitosEstado.QUEIMADURA, 4.0, 0.25, p)
	await esperar(1.2)
	var esperado := PassivasMago.CINZAS_DANO * mm * 2.0
	checar(not is_instance_valid(a) or not a.vida.esta_vivo(), "Cinzas: o slime morreu queimando")
	checar(_perto(_tirou(b), esperado) and b.efeitos.tem(EfeitosEstado.QUEIMADURA),
			"Cinzas: ele explodiu no vizinho (%.2f de dano, esperado %.2f)" % [_tirou(b), esperado])
	await _limpar()


func _tornado_de_fogo() -> void:
	var s := _slime(P + Vector2(60, 0))
	var lado := _slime(P + Vector2(60, 34))
	await get_tree().physics_frame
	await _usar(&"tornado_de_fogo", P + Vector2(100, 0))
	var emp := await _empurrao_de(lado, 2.0)
	checar(emp.y < 0.0, "Tornado de fogo: puxa o inimigo do lado para dentro (%.0f, %.0f)" % [emp.x, emp.y])
	await esperar(0.3)
	checar(_tirou(s) > 0.0 and s.efeitos.tem(EfeitosEstado.QUEIMADURA), "Tornado de fogo: queimou quem estava no caminho (%.2f)" % _tirou(s))
	await _limpar()


func _chuva_de_meteoros() -> void:
	var s := _slime(P + Vector2(80, 0))
	var fora := _slime(P + Vector2(80, 70))
	await get_tree().physics_frame
	var hab := await _usar(&"chuva_de_meteoros", s.global_position)
	await esperar(1.0)
	var minimo := 3.0 * hab.dano * mm * 2.0  # tiques em 0, 0,4 e 0,8 s: um meteoro em cada inimigo dentro
	checar(_tirou(s) >= minimo - 0.01 and s.efeitos.tem(EfeitosEstado.QUEIMADURA),
			"Chuva de meteoros: %.2f de dano em 1 s (pelo menos %.2f)" % [_tirou(s), minimo])
	checar(_tirou(fora) == 0.0, "Chuva de meteoros: fora da área ninguém leva")
	await _limpar()


func _frio_que_morde() -> void:
	p.aprender_de_graca(&"frio_que_morde")
	var s := _slime(P + Vector2(50, 0))
	var outro := _slime(P + Vector2(-60, 0))
	await get_tree().physics_frame
	await _usar(&"lanca_gelo", s.global_position)
	await esperar(0.4)
	var normal := Passivas.ataque_inimigo(outro, p, 10.0)
	var lento := Passivas.ataque_inimigo(s, p, 10.0)
	checar(s.efeitos.tem(EfeitosEstado.LENTIDAO) and _perto(lento / normal, 0.85, 0.001),
			"Frio que morde: o gelo deixa Lentidão e o inimigo lento bate %.0f%% (esperado 85%%)" % (100.0 * lento / normal))
	await _limpar()


func _muralha_de_gelo() -> void:
	var s := _slime(P + Vector2(50, 0))
	await get_tree().physics_frame
	await _usar(&"muralha_de_gelo", P + Vector2(48, 0))
	checar(get_tree().get_nodes_in_group(&"muralha_gelo").size() == 5, "Muralha de gelo: 5 blocos de gelo")
	var emp := await _empurrao_de(s, 0.5)
	checar(emp.x > 0.0, "Muralha de gelo: quem encosta é empurrado de volta (%.0f, %.0f)" % [emp.x, emp.y])
	await _limpar()
	# Na água: vira ponte. Acha a beira da ilha à direita.
	var beira := Vector2.INF
	var d := 0.0
	while d < 3000.0:
		var pt := P + Vector2(d, 0)
		if w.tipo_do_chao(w.chao.local_to_map(pt)) == World.Chao.AGUA:
			beira = pt
			break
		d += 4.0
	p.global_position = beira - Vector2(20, 0)
	await get_tree().physics_frame
	await _usar(&"muralha_de_gelo", beira + Vector2(24, 0))
	var cel := w.chao.local_to_map(beira + Vector2(16, 0))
	checar(beira != Vector2.INF and w.eh_gelo(cel), "Muralha de gelo: mirando na água, congela o caminho (ponte)")
	await _limpar()


func _prisao_de_gelo() -> void:
	var s := _slime(P + Vector2(60, 0))
	await get_tree().physics_frame
	var hab := await _usar(&"prisao_de_gelo", s.global_position)
	checar(s.efeitos.restante(EfeitosEstado.CONGELADO) > 3.8 and _perto(_tirou(s), hab.dano * mm),
			"Prisão de gelo: congelado por %.1f s, %.2f de dano" % [s.efeitos.restante(EfeitosEstado.CONGELADO), _tirou(s)])
	await _limpar()


func _nevasca() -> void:
	var s := _slime(P + Vector2(80, 0))
	await get_tree().physics_frame
	var hab := await _usar(&"nevasca", s.global_position)
	await esperar(0.1)
	checar(s.efeitos.tem(EfeitosEstado.LENTIDAO) and not s.efeitos.tem(EfeitosEstado.CONGELADO), "Nevasca: primeiro segundo, só lento")
	await esperar(2.1)
	checar(s.efeitos.tem(EfeitosEstado.CONGELADO) and _perto(_tirou(s), 3.0 * hab.dano * mm),
			"Nevasca: no terceiro segundo dentro, congela (%.2f de dano em 3 tiques)" % _tirou(s))
	await _limpar()


func _conducao() -> void:
	p.aprender_de_graca(&"conducao")
	# Em terra: salta para 1.
	var alvo := _slime(P + Vector2(60, 0))
	var v: Array[Slime] = [_slime(P + Vector2(60, 30)), _slime(P + Vector2(60, 60)), _slime(P + Vector2(60, 90))]
	await get_tree().physics_frame
	await _usar(&"raio", alvo.global_position)
	await esperar(0.1)
	checar(_tirou(v[0]) > 0.0 and _tirou(v[1]) == 0.0, "Condução: em terra, o raio salta para 1 vizinho")
	await _limpar()
	# Molhado (em cima do gelo): salta para mais 2.
	var beira := Vector2.INF
	var d := 0.0
	while d < 3000.0:
		if w.tipo_do_chao(w.chao.local_to_map(P + Vector2(d, 0))) == World.Chao.AGUA:
			beira = P + Vector2(d, 0)
			break
		d += 4.0
	var no_gelo := beira + Vector2(16, 0)
	World.congelar_agua_em(p, no_gelo)
	p.global_position = beira - Vector2(40, 0)
	alvo = _slime(no_gelo)
	v = [_slime(no_gelo + Vector2(0, -30)), _slime(no_gelo + Vector2(0, -60)), _slime(no_gelo + Vector2(0, -90))]
	await get_tree().physics_frame
	checar(LogicasMago.molhado(alvo), "Condução: o slime em cima do gelo está molhado")
	await _usar(&"raio", alvo.global_position)
	await esperar(0.1)
	checar(_tirou(v[0]) > 0.0 and _tirou(v[1]) > 0.0 and _tirou(v[2]) > 0.0, "Condução: no alvo molhado, o raio salta para mais 2 (3 vizinhos)")
	await _limpar()


func _corrente_eletrica() -> void:
	var l: Array[Slime] = []
	for k in 6:
		l.append(_slime(P + Vector2(40 + 40 * k, 0)))
	await get_tree().physics_frame
	var hab := await _usar(&"corrente_eletrica", l[0].global_position)
	var acertados := l.filter(func(s: Slime) -> bool: return _perto(_tirou(s), hab.dano * mm)).size()
	checar(acertados == 5 and _tirou(l[5]) == 0.0 and l[0].efeitos.tem(EfeitosEstado.ATORDOADO),
			"Corrente elétrica: pulou entre 5 inimigos (%d com %.2f de dano), o 6º ficou de fora" % [acertados, hab.dano * mm])
	await _limpar()


func _totem_tesla() -> void:
	var s := _slime(P + Vector2(64, 30))
	await get_tree().physics_frame
	var hab := await _usar(&"totem_tesla", P + Vector2(64, 0))
	var totens := get_tree().get_nodes_in_group(&"totem_tesla")
	await esperar(1.0)
	checar(totens.size() == 1 and _tirou(s) >= hab.dano * mm - 0.01, "Totem tesla: a torre deu choque no slime perto (%.2f)" % _tirou(s))
	checar(totens.size() == 1 and is_instance_valid(totens[0]) and _perto((totens[0] as Invocacao).restante(), 7.0, 0.2), "Totem tesla: dura 8 s")
	await _limpar()


func _forma_de_relampago() -> void:
	var s := _slime(P + Vector2(48, 0))
	await get_tree().physics_frame
	var hab := await _usar(&"forma_de_relampago", P + Vector2(96, 0))
	await esperar(0.2)
	checar(p.global_position.x - P.x > 80.0 and _perto(_tirou(s), hab.dano * mm) and s.efeitos.tem(EfeitosEstado.ATORDOADO),
			"Forma de relâmpago: atravessou %.0f px e feriu quem estava no caminho (%.2f)" % [p.global_position.x - P.x, _tirou(s)])
	await _limpar()


func _tempestade() -> void:
	var a := _slime(P + Vector2(50, 0))
	var b := _slime(P + Vector2(-50, 30))
	await get_tree().physics_frame
	var hab := await _usar(&"tempestade", P)
	await esperar(1.1)
	checar(_perto(_tirou(a), 2.0 * hab.dano * mm) and _perto(_tirou(b), 2.0 * hab.dano * mm),
			"Tempestade: raios caíram nos 2 inimigos perto a cada segundo (%.2f e %.2f)" % [_tirou(a), _tirou(b)])
	await _limpar()


func _espinhos() -> void:
	var s := _slime(P + Vector2(60, 0))
	var fora := _slime(P + Vector2(60, 40))
	await get_tree().physics_frame
	var hab := await _usar(&"espinhos", s.global_position)
	checar(_perto(_tirou(s), hab.dano * mm) and s.efeitos.tem(EfeitosEstado.PRESO) and _tirou(fora) == 0.0,
			"Espinhos: %.2f de dano e Preso por %.1f s; fora da área nada" % [_tirou(s), s.efeitos.restante(EfeitosEstado.PRESO)])
	# Melhoria: +15% de dano.
	p.arvore[&"espinhos"] = 2
	var s2 := _slime(P + Vector2(-60, 0))
	await get_tree().physics_frame
	await _usar(&"espinhos", s2.global_position)
	checar(_perto(_tirou(s2), hab.dano * mm * 1.15), "Espinhos com 1 melhoria: %.2f de dano (+15%%)" % _tirou(s2))
	await _limpar()


func _golem_de_pedra() -> void:
	var s := _slime(P + Vector2(80, 0))
	await get_tree().physics_frame
	await _usar(&"golem_de_pedra", P + Vector2(48, 0))
	var golens := get_tree().get_nodes_in_group(&"golem_pedra")
	await esperar(0.2)
	checar(golens.size() == 1 and s.efeitos.tem(EfeitosEstado.PROVOCADO), "Golem de pedra: invocado, chama os inimigos perto")
	await esperar(2.0)
	checar(_tirou(s) > 0.0, "Golem de pedra: deu soco no slime (%.2f)" % _tirou(s))
	await _limpar()


func _fenda() -> void:
	var s := _slime(P + Vector2(80, 0))
	var fora := _slime(P + Vector2(80, 30))
	await get_tree().physics_frame
	var hab := await _usar(&"fenda", P + Vector2(200, 0))
	checar(_perto(_tirou(s), hab.dano * mm) and s.efeitos.tem(EfeitosEstado.DERRUBADO) and _perto(s.efeitos.forca(EfeitosEstado.CEGO), 0.3) and _tirou(fora) == 0.0,
			"Fenda: %.2f de dano, Derrubado e em Desequilíbrio; fora da linha nada" % _tirou(s))
	await _limpar()


func _despertar_da_ilha() -> void:
	var s := _slime(P + Vector2(60, 0))
	await get_tree().physics_frame
	await _usar(&"despertar_da_ilha", P)
	await esperar(0.1)
	checar(_perto(s.efeitos.forca(EfeitosEstado.CEGO), 0.5) and _perto(s.efeitos.forca(EfeitosEstado.LENTIDAO), 0.4),
			"Despertar da ilha: erra metade dos ataques e fica 40% mais lento")
	await _limpar()


func _tremor() -> void:
	p.aprender_de_graca(&"tremor")
	var s := _slime(P + Vector2(60, 0))
	await get_tree().physics_frame
	seed(7)
	var derrubou := 0
	for k in 200:
		s.vida.atual = 100.0
		Golpes.acertar(p, s, 0.01, &"terra")
		if s.efeitos.tem(EfeitosEstado.DERRUBADO):
			derrubou += 1
			s.efeitos.remover(EfeitosEstado.DERRUBADO)
	checar(derrubou >= 25 and derrubou <= 55, "Tremor: %d de 200 feitiços de terra derrubaram (perto de 20%%)" % derrubou)
	await _limpar()
