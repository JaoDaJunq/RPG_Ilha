extends TesteBase
## Etapa 2 (L39): os bichos e inimigos novos nascem na região certa, cada um faz o que é dele
## (o cervo foge de longe, o caranguejo belisca, o sapo pula, a cabra dá cabeçada, o bandido
## bate e se defende, o lanceiro avança, o cogumelo deixa Lento, o morcego mergulha, o
## esqueleto levanta se não for queimado, o golem quebra com a picareta, os slimes dos
## elementos são imunes ao próprio elemento) e deixam o saque e a experiência.

const NOVOS := ["cervo", "caranguejo", "sapo", "cabra", "slime_fogo", "slime_gelo", "slime_veneno",
		"bandido_guerreiro", "bandido_lanceiro", "cogumelo", "esqueleto", "golem"]

var w: World
var p: Player


func _ready() -> void:
	w = await criar_mundo(0, false, &"guerreiro")
	p = w.jogador
	var pv := w.povoamento

	# Cada bicho novo está na tabela de alguma região, e quem nasceu ficou dentro dela.
	for tipo in NOVOS:
		var regioes := []
		for r in Regioes.TODAS:
			for e in Regioes.dados(r)["dia"]:
				if e[0] == tipo:
					regioes.append(r)
		checar(not regioes.is_empty(), "%s está na tabela de dia de %s" % [tipo, ", ".join(regioes.map(func(r: int) -> String: return Regioes.nome(r)))])
	checar(_na_tabela("morcego_noite", true), "o morcego aparece à noite")
	checar(_na_tabela("cervo", false, Regioes.Id.BOSQUE) and _na_tabela("caranguejo", false, Regioes.Id.PRAIA) \
			and _na_tabela("sapo", false, Regioes.Id.PANTANO) and _na_tabela("cabra", false, Regioes.Id.COLINAS) \
			and _na_tabela("cogumelo", false, Regioes.Id.PANTANO) and _na_tabela("esqueleto", false, Regioes.Id.RUINAS) \
			and _na_tabela("golem", false, Regioes.Id.COLINAS), "cada um na região dele (cervo no Bosque, caranguejo na Praia...)")
	var nascidos := get_tree().get_nodes_in_group(&"povoamento")
	var novos_vivos := nascidos.filter(func(n: Node) -> bool: return String(n.get_meta(&"tipo", "")) in NOVOS)
	checar(novos_vivos.size() >= 10, "os novos já estão pela ilha (%d)" % novos_vivos.size())
	checar(novos_vivos.all(func(n: Node2D) -> bool: return w.regiao_em(n.global_position) == int(n.get_meta(&"regiao"))), "cada um nasceu dentro da região dele")
	# Longe é mais forte: o mesmo bandido nas Ruínas tem mais vida que no Bosque.
	var b_perto := pv.criar("bandido_guerreiro", Vector2(GeradorIlha.SEMENTES[Regioes.Id.BOSQUE][0] * World.T), Regioes.Id.BOSQUE) as Criatura
	var b_longe := pv.criar("bandido_guerreiro", Vector2(GeradorIlha.SEMENTES[Regioes.Id.RUINAS][0] * World.T), Regioes.Id.RUINAS) as Criatura
	await get_tree().process_frame
	checar(b_longe.vida.maximo > b_perto.vida.maximo and b_longe.barra.nivel > b_perto.barra.nivel, "nas Ruínas o bandido tem mais vida e nível (%.0f x %.0f)" % [b_longe.vida.maximo, b_perto.vida.maximo])
	b_perto.queue_free()
	b_longe.queue_free()

	var base := w.centro + Vector2(0, 70)
	p.global_position = base
	await _animais(pv, base)
	await _inimigos(pv, base)
	terminar()


func _na_tabela(tipo: String, noite: bool, regiao := -1) -> bool:
	for r in Regioes.TODAS:
		if regiao >= 0 and r != regiao:
			continue
		for e in Regioes.dados(r)["noite" if noite else "dia"]:
			if e[0] == tipo:
				return true
	return false


func _criar(pv: Povoamento, tipo: String, pos: Vector2) -> Node2D:
	var n := pv.criar(tipo, pos, Regioes.Id.CLAREIRA)
	n.set_meta(&"regiao", -1)  # não conta na vaga da Clareira
	await get_tree().physics_frame
	return n


func _limpar_chao() -> void:
	for i in get_tree().get_nodes_in_group(&"itens_chao"):
		i.queue_free()
	await get_tree().process_frame


func _saque_tem(ids: Array) -> bool:
	var no_chao := {}
	for i in get_tree().get_nodes_in_group(&"itens_chao"):
		if not i.is_queued_for_deletion():
			no_chao[(i as ItemChao).item] = true
	return ids.all(func(id: StringName) -> bool: return no_chao.has(id))


func _animais(pv: Povoamento, base: Vector2) -> void:
	# Cervo: foge de quem chega perto, sem precisar apanhar, e corre muito.
	var c: Animal = await _criar(pv, "cervo", base + Vector2(40, 0))
	await esperar(0.9)
	checar(c.global_position.distance_to(p.global_position) > 70.0, "o cervo foge de longe (%.0f px)" % c.global_position.distance_to(p.global_position))
	await _limpar_chao()
	c.hurtbox.receber(99.0, &"fisico", p)
	await esperar(0.2)
	checar(_saque_tem([&"carne_crua", &"couro"]), "o cervo deixa carne e couro")

	# Caranguejo: apanha e belisca de volta.
	p.vida.curar_tudo()
	var k: Animal = await _criar(pv, "caranguejo", base + Vector2(20, 0))
	var vida := p.vida.atual
	k.hurtbox.receber(0.5, &"fisico", p)
	await esperar(1.5)
	checar(p.vida.atual < vida, "o caranguejo belisca quem mexe com ele (%.0f -> %.0f)" % [vida, p.vida.atual])
	await _limpar_chao()
	k.hurtbox.receber(99.0, &"fisico", p)
	await esperar(0.2)
	checar(_saque_tem([&"pinca_caranguejo"]), "o caranguejo deixa a pinça")

	# Sapo: anda pulando (agacha, salta, descansa) e foge.
	var s: Animal = await _criar(pv, "sapo", base + Vector2(20, 0))
	s.hurtbox.receber(0.3, &"fisico", p)
	var viu := {}
	var parado_no_meio := false
	var antes := s.global_position
	for q in 120:
		await get_tree().physics_frame
		viu[s.animacao] = true
		if s.animacao == &"agachado" and s.velocity.length() < 1.0:
			parado_no_meio = true
	checar(viu.has(&"no_ar") and viu.has(&"agachado") and parado_no_meio, "o sapo pula: agacha parado e salta (%s)" % ", ".join(viu.keys()))
	checar(s.global_position.distance_to(antes) > 6.0, "e foge pulando")
	await _limpar_chao()
	s.hurtbox.receber(99.0, &"fisico", p)
	await esperar(0.2)
	checar(_saque_tem([&"carne_sapo"]), "o sapo deixa carne de sapo")

	# Cabra: dá cabeçada em quem bate.
	p.vida.curar_tudo()
	var g: Animal = await _criar(pv, "cabra", base + Vector2(30, 0))
	vida = p.vida.atual
	g.hurtbox.receber(0.5, &"fisico", p)
	await esperar(1.5)
	checar(p.vida.atual < vida, "a cabra dá cabeçada (%.0f -> %.0f)" % [vida, p.vida.atual])
	await _limpar_chao()
	g.hurtbox.receber(99.0, &"fisico", p)
	await esperar(0.2)
	checar(_saque_tem([&"la"]), "a cabra deixa lã")


func _inimigos(pv: Povoamento, base: Vector2) -> void:
	# Bandido guerreiro: vem, prepara e bate.
	p.vida.curar_tudo()
	var b: Bandido = await _criar(pv, "bandido_guerreiro", base + Vector2(50, 0))
	var vida := p.vida.atual
	var viu_preparo := false
	for q in 150:
		await get_tree().physics_frame
		viu_preparo = viu_preparo or b.animacao == &"preparo"
		if p.vida.atual < vida:
			break
	checar(viu_preparo and p.vida.atual < vida, "o bandido guerreiro prepara (o aviso) e bate (%.0f -> %.0f)" % [vida, p.vida.atual])
	# Congelado não anda nem bate.
	b.efeitos.aplicar(EfeitosEstado.CONGELADO, 2.0)
	var pos := b.global_position
	await esperar(0.5)
	checar(b.global_position.distance_to(pos) < 1.0 and b.parado, "congelado, o bandido fica parado")
	b.efeitos.remover(EfeitosEstado.CONGELADO)
	# A guarda: com ela erguida o golpe físico tira bem menos.
	b._guarda = 1.0
	var v0 := b.vida.atual
	b.hurtbox.receber(2.0, &"fisico", p)
	checar(b.vida.atual > v0 - 1.0, "com a guarda erguida o golpe tira pouco (%.1f)" % (v0 - b.vida.atual))
	b._guarda = 0.0
	await esperar(0.2)
	var xp := p.xp
	var nivel0 := p.nivel
	await _limpar_chao()
	b.hurtbox.receber(999.0, &"fogo", p)
	await esperar(0.2)
	checar(p.xp != xp or p.nivel > nivel0, "derrotado, o bandido dá experiência (xp %d -> %d, nível %d -> %d)" % [xp, p.xp, nivel0, p.nivel])
	checar(get_tree().get_nodes_in_group(&"itens_chao").size() > 0, "e deixa saque no chão")

	# Lanceiro: de meia distância, avança em linha reta.
	p.vida.curar_tudo()
	var l: Bandido = await _criar(pv, "bandido_lanceiro", base + Vector2(60, 0))
	vida = p.vida.atual
	var avancou := false
	for q in 200:
		await get_tree().physics_frame
		avancou = avancou or l._golpe == Criatura.Golpe.BATENDO
		if p.vida.atual < vida:
			break
	checar(avancou and p.vida.atual < vida, "o lanceiro avança e acerta (%.0f -> %.0f)" % [vida, p.vida.atual])
	l.queue_free()

	# Cogumelo andante: os esporos deixam Lento.
	p.vida.curar_tudo()
	var cg: Criatura = await _criar(pv, "cogumelo", base + Vector2(16, 0))
	var lento := false
	for q in 150:
		await get_tree().physics_frame
		if p.efeitos.tem(EfeitosEstado.LENTIDAO):
			lento = true
			break
	checar(lento, "os esporos do cogumelo deixam Lento")
	await _limpar_chao()
	cg.hurtbox.receber(999.0, &"fogo", p)
	await esperar(0.2)
	checar(_saque_tem([&"cogumelo"]), "o cogumelo andante deixa cogumelos")
	p.efeitos.remover(EfeitosEstado.LENTIDAO)

	# Morcego: voa em volta e mergulha para morder.
	p.vida.curar_tudo()
	var m: Morcego = colocar(w, Povoamento.MORCEGO, base + Vector2(50, -20)) as Morcego
	await get_tree().physics_frame
	vida = p.vida.atual
	for q in 300:
		await get_tree().physics_frame
		if p.vida.atual < vida:
			break
	checar(p.vida.atual < vida, "o morcego mergulha e morde (%.0f -> %.0f)" % [vida, p.vida.atual])
	checar(m.collision_mask == 0, "o morcego voa (passa por cima da água)")
	m.queue_free()
	var mn := colocar(w, Povoamento.MORCEGO, base + Vector2(200, 0))
	mn.set(&"noturno", true)
	w.noite = false
	await esperar(0.2)
	checar(not is_instance_valid(mn) or mn.is_queued_for_deletion(), "o morcego da noite vai embora de dia")

	# Esqueleto: sem fogo desmonta e levanta; com fogo acaba de vez.
	var e: Esqueleto = await _criar(pv, "esqueleto", base + Vector2(80, 0))
	e.hurtbox.receber(999.0, &"fisico", p)
	await get_tree().physics_frame
	checar(is_instance_valid(e) and e.desmontado, "sem fogo, o esqueleto só desmonta")
	e.hurtbox.receber(999.0, &"fisico", p)
	await get_tree().physics_frame
	checar(is_instance_valid(e) and e.desmontado, "bater nos ossos sem fogo não adianta")
	e._tempo_desmontado = Esqueleto.TEMPO_LEVANTAR
	await esperar(0.1)
	checar(not e.desmontado and e.vida.atual > 0.0, "depois de um tempo ele levanta (vida %.1f)" % e.vida.atual)
	e.hurtbox.receber(999.0, &"fisico", p)
	await get_tree().physics_frame
	await _limpar_chao()
	e.hurtbox.receber(1.0, &"fogo", p)
	await esperar(0.2)
	checar(not is_instance_valid(e) or e.is_queued_for_deletion(), "com fogo nos ossos ele acaba de vez")
	checar(_saque_tem([&"osso"]), "e deixa ossos")
	# A tocha na mão também queima os ossos.
	var e2: Esqueleto = await _criar(pv, "esqueleto", base + Vector2(80, 30))
	e2.hurtbox.receber(999.0, &"fisico", p)
	await get_tree().physics_frame
	p.inventario.adicionar(&"tocha", 1)
	_na_mao(&"tocha")
	e2.hurtbox.receber(1.0, &"fisico", p)
	await get_tree().physics_frame
	checar(not is_instance_valid(e2) or e2.is_queued_for_deletion(), "bater nos ossos com a tocha na mão também queima")

	# Golem: o físico tira pouco, a picareta quebra rápido.
	var gl: Golem = await _criar(pv, "golem", base + Vector2(-80, 0))
	_na_mao(&"espada_ferro")
	var v1 := gl.vida.atual
	gl.hurtbox.receber(4.0, &"fisico", p)
	var com_espada := v1 - gl.vida.atual
	await esperar(0.3)
	_na_mao(&"picareta_pedra")
	var v2 := gl.vida.atual
	gl.hurtbox.receber(4.0, &"fisico", p)
	var com_picareta := v2 - gl.vida.atual
	checar(com_picareta > com_espada * 2.0, "a picareta quebra o golem bem mais rápido (%.1f x %.1f)" % [com_picareta, com_espada])
	await _limpar_chao()
	await esperar(0.2)
	gl.hurtbox.receber(999.0, &"luz", p)
	await esperar(0.2)
	checar(_saque_tem([&"pedra"]), "o golem deixa pedras (e às vezes minério)")

	# Slimes dos elementos: imunes ao próprio elemento, fracos ao contrário.
	var sf: Slime = await _criar(pv, "slime_fogo", base + Vector2(-60, 40))
	var sg: Slime = await _criar(pv, "slime_gelo", base + Vector2(-90, 40))
	var sv: Slime = await _criar(pv, "slime_veneno", base + Vector2(-120, 40))
	var vf := sf.vida.atual
	sf.hurtbox.receber(3.0, &"fogo", p)
	checar(sf.vida.atual == vf, "o slime de fogo não sente fogo")
	await esperar(0.2)
	sf.hurtbox.receber(1.0, &"gelo", p)
	checar(vf - sf.vida.atual >= 2.9 and not sf.congelado(), "o gelo apaga o slime de fogo: o triplo, sem congelar (%.1f)" % (vf - sf.vida.atual))
	var vg := sg.vida.atual
	sg.hurtbox.receber(3.0, &"gelo", p)
	checar(sg.vida.atual == vg and not sg.congelado(), "o slime de gelo não congela nem sente gelo")
	await esperar(0.2)
	sg.hurtbox.receber(1.0, &"fogo", p)
	checar(vg - sg.vida.atual >= 2.9, "o fogo derrete o slime de gelo: o triplo (%.1f)" % (vg - sg.vida.atual))
	var vv := sv.vida.atual
	sv.hurtbox.receber(3.0, &"veneno", p)
	checar(sv.vida.atual == vv, "o slime venenoso não sente veneno")
	# O contato do slime de gelo deixa Lento.
	p.efeitos.remover(EfeitosEstado.LENTIDAO)
	sg._cabecada(p)
	checar(p.efeitos.tem(EfeitosEstado.LENTIDAO), "o pulo do slime de gelo deixa Lento")


func _na_mao(id: StringName) -> void:
	if p.inventario.quantidade_de(id) == 0:
		p.inventario.adicionar(id, 1)
	for k in Inventory.BARRA:
		if p.inventario.item_em(k) == id:
			p.barra_escolhida = k
			return
