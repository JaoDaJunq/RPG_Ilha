extends TesteBase
## A Mãe Gosma (etapa 4, T41): arena e altar, a isca chama o boss, as 3 fases (pula e esmaga
## com alvo e slimes pequenos; elemento imune e frágil; divisão em 3), a vida e os filhotes
## que crescem com os jogadores, reset, recompensa, a Semente que abre a ponte e o estado
## salvo. O dano vem direto do Hurtbox, como um golpe de jogador.


func _gosmas() -> Array[MaeGosma]:
	var lista: Array[MaeGosma] = []
	for g in get_tree().get_nodes_in_group(&"boss_gosma"):
		if not g.is_queued_for_deletion():
			lista.append(g as MaeGosma)
	return lista


func _bater(g: MaeGosma, q: float, tipo: StringName = &"fisico") -> void:
	g.hurtbox.receber(q, tipo, null)


func _ready() -> void:
	var w := await criar_mundo()
	var p := w.jogador
	var m := w.missoes
	var a := w.arena_gosma
	a.atraso_chamar = 0.0

	# Arena e altar no pântano.
	checar(a != null and w.regiao_em(a.centro) == Regioes.Id.PANTANO, "a arena fica no coração do pântano")
	checar(w.regiao_em(a.position) == Regioes.Id.PANTANO and w.pode_pisar(a.position), "o altar está no pântano, em terra firme")
	checar(not w.gerador.celulas_ponte.has(Vector2i((a.centro / World.T).floor())), "a arena não pega a ponte")
	checar(w.hud.barra_boss() != null and w.hud.barra_boss().fracao() < 0.0, "a barra de boss existe e fica escondida sem boss")
	checar(m.posicao_do_objetivo() != null, "o alfinete tem posição")

	# Escala com os jogadores.
	checar(is_equal_approx(MaeGosma.vida_para(1), MaeGosma.VIDA_BASE), "1 jogador: vida base")
	checar(MaeGosma.vida_para(2) > MaeGosma.vida_para(1) and MaeGosma.vida_para(4) > MaeGosma.vida_para(2), "a vida cresce com os jogadores")
	checar(MaeGosma.filhotes_por_pulo(1) == 2 and MaeGosma.filhotes_por_pulo(3) > 2, "os slimes por pulo crescem com os jogadores")
	checar(MaeGosma.limite_slimes(4) > MaeGosma.limite_slimes(1), "o limite de slimes vivos cresce com os jogadores")

	# O altar: sem isca nada acontece; com isca ela é gasta e a Mãe Gosma aparece.
	m.passo = FalasBrasinha.CAP1.size() - 1
	checar(a.pode_interagir() and not a.luta_ativa(), "o altar está livre")
	a.interagir(p)
	await esperar(0.2)
	checar(_gosmas().is_empty() and not m.gosma_isca, "sem a isca, o altar não chama ninguém")
	p.inventario.adicionar(&"isca_gosma", 1)
	a.interagir(p)
	checar(p.inventario.quantidade_de(&"isca_gosma") == 0, "a isca foi gasta no altar")
	await esperar(0.3)
	var gs := _gosmas()
	checar(gs.size() == 1 and gs[0].fase == 1 and not gs[0].filhote, "a Mãe Gosma apareceu, na fase 1")
	var g := gs[0]
	checar(is_equal_approx(g.vida.maximo, MaeGosma.vida_para(1)), "vida da luta: %.0f" % g.vida.maximo)
	checar(not a.pode_interagir(), "durante a luta o altar fica fechado")
	checar(g.global_position.distance_to(a.centro) < 4.0, "ela nasce no meio da arena")

	# Fase 1: alvo no chão e slimes pequenos.
	p.global_position = a.centro + Vector2(40, 0)
	var viu_alvo := false
	for i in 40:
		await esperar(0.1)
		if g.em_aviso:
			viu_alvo = true
			break
	checar(viu_alvo, "o alvo aparece no chão antes do pulo")
	checar(a.dentro(g.alvo_pos), "o alvo fica dentro da arena")
	await get_tree().physics_frame
	checar(g._alvo_sprite.visible, "o alvo está desenhado")
	await esperar(MaeGosma.TEMPO_AVISO + MaeGosma.TEMPO_NO_AR + 0.4)
	var pequenos := get_tree().get_nodes_in_group(&"cria_gosma").size()
	checar(pequenos == MaeGosma.filhotes_por_pulo(1), "o pulo soltou %d slimes pequenos (esperado %d)" % [pequenos, MaeGosma.filhotes_por_pulo(1)])
	checar(not g.em_aviso and g.altura == 0.0, "depois da queda o alvo some")
	# Dano em área da queda.
	p.global_position = a.centro
	g.alvo_pos = a.centro
	var vida_antes := p.vida.atual
	g._esmagar()
	checar(p.vida.atual < vida_antes, "a queda machuca quem está no alvo (%.0f -> %.0f)" % [vida_antes, p.vida.atual])
	# Ela não sai da arena.
	g.global_position = a.centro + Vector2(400, 0)
	await esperar(0.1)
	checar(a.dentro(g.global_position, 8.0), "ela volta para a arena se for longe")

	# Fase 1 -> 2: o golpe nunca passa da metade da vida.
	_bater(g, 100000.0)
	checar(absf(g.vida.atual - g.vida.maximo * 0.5) < 0.5 and g.fase == 2, "o golpe forte para na metade da vida: fase 2 (%.1f)" % g.vida.atual)
	checar(g.elemento == &"fogo", "na fase 2 ela vira fogo")
	# Imune ao próprio elemento e frágil ao contrário.
	var v0 := g.vida.atual
	_bater(g, 4.0, &"fogo")
	checar(is_equal_approx(g.vida.atual, v0), "fogo não faz nada na gosma de fogo")
	_bater(g, 4.0, &"queimadura")
	checar(is_equal_approx(g.vida.atual, v0), "queimadura também não")
	_bater(g, 4.0, &"gelo")
	checar(absf((v0 - g.vida.atual) - 4.0 * MaeGosma.MULT_FRAGIL) < 0.01, "gelo na gosma de fogo dá %.1f vezes" % MaeGosma.MULT_FRAGIL)
	g._trocar_elemento()
	checar(g.elemento == &"gelo", "a ordem do elemento é fogo, gelo, veneno")
	v0 = g.vida.atual
	_bater(g, 4.0, &"gelo")
	checar(is_equal_approx(g.vida.atual, v0), "gelo não faz nada na gosma de gelo")
	_bater(g, 4.0, &"fogo")
	checar(absf((v0 - g.vida.atual) - 4.0 * MaeGosma.MULT_FRAGIL) < 0.01, "fogo derrete a gosma de gelo")
	g._trocar_elemento()
	checar(g.elemento == &"veneno", "terceiro elemento: veneno")
	v0 = g.vida.atual
	_bater(g, 4.0, &"veneno")
	checar(is_equal_approx(g.vida.atual, v0), "veneno não faz nada na gosma de veneno")
	_bater(g, 4.0, &"fogo")
	checar(absf((v0 - g.vida.atual) - 4.0 * MaeGosma.MULT_FRAGIL) < 0.01, "fogo queima a gosma de veneno")
	# A troca por tempo e a poça do elemento.
	g._tempo_elemento = MaeGosma.SEGUNDOS_POR_ELEMENTO
	await esperar(0.15)
	checar(g.elemento == &"fogo", "passados os segundos ela troca de elemento sozinha")
	g.alvo_pos = a.centro + Vector2(20, 0)
	g._esmagar()
	await esperar(0.1)
	checar(get_tree().get_nodes_in_group(&"pocas_gosma").size() >= 1, "a queda deixa uma poça do elemento")
	for i in MaeGosma.PULOS_POR_ELEMENTO:
		g.alvo_pos = a.centro
		g._esmagar()
	checar(g.elemento == &"gelo", "depois de %d pulos ela troca de elemento" % MaeGosma.PULOS_POR_ELEMENTO)

	# Fase 2 -> 3: divide em 3, um de cada elemento, vida restante dividida.
	var restante := g.vida.maximo * MaeGosma.FASE3_EM
	var total_ref := g.vida.maximo
	_bater(g, 100000.0, &"fogo")  # gelo: o fogo é o frágil, mas o piso da fase segura
	await esperar(0.2)
	gs = _gosmas()
	checar(gs.size() == 3, "a 1/4 da vida ela se divide em 3 (%d)" % gs.size())
	var elementos: Array[StringName] = []
	var soma := 0.0
	for f in gs:
		elementos.append(f.elemento)
		soma += f.vida.atual
		checar(f.filhote and f.fase == 3, "uma das menores")
	checar(&"fogo" in elementos and &"gelo" in elementos and &"veneno" in elementos, "uma de cada elemento")
	checar(absf(soma - restante) < 1.0, "a vida que sobrou foi dividida: %.1f de %.1f" % [soma, restante])
	checar(get_tree().get_nodes_in_group(&"cria_gosma").is_empty(), "os slimes pequenos somem na divisão")
	checar(absf(w.hud.barra_boss().fracao() - 0.25) < 0.02, "a barra mostra 1/4 da luta (%.2f)" % w.hud.barra_boss().fracao())
	checar(gs[0].visual.scale.x < ArteGosma.ESCALA_PLACEHOLDER, "as menores são menores")
	checar(absf(gs[0].pv_ref - total_ref) < 0.1, "elas sabem a vida total da luta")

	# Reset: todos longe da arena, a luta volta e a isca fica no altar.
	p.global_position = a.centro + Vector2(900, 0)
	a._sem_ninguem = ArenaGosma.TEMPO_RESET - 0.02
	await esperar(0.2)
	checar(_gosmas().is_empty() and not a.luta_ativa(), "sem ninguém na arena a luta reseta")
	checar(m.gosma_isca and a.pode_interagir() and not m.gosma_derrotada, "a isca continua no altar")
	checar(a.texto_acao().contains("Chamar"), "o altar passa a dizer 'Chamar a Mãe Gosma'")
	# Chamar de novo, sem gastar outra isca.
	p.global_position = a.centro + Vector2(30, 0)
	a.interagir(p)
	await esperar(0.3)
	gs = _gosmas()
	checar(gs.size() == 1 and gs[0].fase == 1, "chamou de novo: fase 1 do começo")
	g = gs[0]

	# Vence: leva ela até a divisão e derruba as 3.
	_bater(g, 100000.0)
	g._trocar_elemento()
	_bater(g, 100000.0, &"fisico")
	await esperar(0.2)
	gs = _gosmas()
	checar(gs.size() == 3, "dividiu de novo")
	_bater(gs[0], 100000.0)
	await esperar(0.1)
	checar(_gosmas().size() == 2 and not m.gosma_derrotada, "uma caiu, faltam 2")
	checar(w.hud.barra_boss().fracao() > 0.0, "a barra continua enquanto sobrar gosma")
	_bater(gs[1], 100000.0)
	await esperar(0.1)
	checar(_gosmas().size() == 1 and not m.gosma_derrotada, "duas caíram, falta 1")
	_bater(gs[2], 100000.0)
	await esperar(0.2)
	checar(_gosmas().is_empty() and m.gosma_derrotada, "as 3 morreram: Mãe Gosma derrotada")
	checar(w.hud.barra_boss().fracao() < 0.0, "a barra some")
	checar(not a.pode_interagir() and not m.gosma_isca, "o altar não chama de novo")
	await esperar(0.2)
	checar(a.coroa_visivel(), "a coroa caída fica no chão da arena")

	# Recompensa: Semente do Coração e 2 gosmas reais no chão.
	p.global_position = a.centro
	await pegar_do_chao(p)
	checar(p.inventario.quantidade_de(&"semente_coracao") == 1, "dropou a Semente do Coração")
	checar(p.inventario.quantidade_de(&"gosma_real") == 2, "dropou 2 gosmas reais (%d)" % p.inventario.quantidade_de(&"gosma_real"))
	checar(ItemData.existe(&"gosma_real") and ItemData.existe(&"pocao_cura_forte"), "os itens novos existem")
	checar(ItemData.carregar(&"gosma_real").icone != null, "gosma real tem ícone (placeholder até a arte)")
	var forte := ItemData.carregar(&"pocao_cura_forte")
	checar(forte.cura > ItemData.carregar(&"pocao_cura").cura, "a poção forte cura mais que a comum")
	var achou_receita := false
	for r in ReceitaData.todas():
		if r.resultado == &"pocao_cura_forte" and &"gosma_real" in r.ingredientes and &"erva" in r.ingredientes:
			achou_receita = true
	checar(achou_receita, "receita da poção de cura forte: gosma real + erva")

	# A Semente ao Brasinha: capítulo 2, ponte consertada, 1 ponto de árvore.
	var pontos := p.pontos_habilidade
	checar(not w.passagem(World.PONTE).aberta, "antes da Semente a ponte está quebrada")
	m.conversar(p)
	checar(m.semente_entregue and m.capitulo == 2, "o Brasinha recebeu a Semente: capítulo 2")
	checar(w.passagem(World.PONTE).aberta, "a ponte das Colinas foi consertada")
	checar(p.pontos_habilidade == pontos + 1, "+1 ponto de árvore")
	checar(p.inventario.quantidade_de(&"semente_coracao") == 0, "a Semente foi entregue")

	# Estado salvo no mundo.
	var salvo: Dictionary = JSON.parse_string(JSON.stringify(m.para_salvar()))
	m.gosma_derrotada = false
	m.gosma_isca = true
	m.carregar(salvo)
	checar(m.gosma_derrotada and not m.gosma_isca, "o boss derrotado volta do save")
	checar(not a.pode_interagir(), "carregado, o altar continua fechado")
	m.carregar({"gosma_isca": true})

	checar(m.gosma_isca and not m.gosma_derrotada, "a isca no altar (luta resetada) também é salva")

	terminar()
