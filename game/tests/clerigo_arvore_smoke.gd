extends TesteBase
## Árvore do Clérigo: cada nó novo aprendido e usado (ou a passiva medida), com números.
## As ativas passam pelo caminho de verdade (tecla → pedido → anfitrião → lógica).

const SLIME := preload("res://scenes/enemies/slime.tscn")
const JOGADOR := preload("res://scenes/player/player.tscn")
const VIDA_SLIME := 500.0
const ATIVAS: Array[StringName] = [&"martelo_da_justica", &"circulo_de_cura", &"elo_vital", &"levantar",
	&"fonte_da_vida", &"barreira", &"santuario", &"intervencao", &"muralha_da_fe", &"coluna_de_luz",
	&"martelo_giratorio", &"aurora", &"amanhecer"]

var w: World
var p: Player
var aliado: Player


func _ready() -> void:
	w = await criar_mundo(0, true, &"clerigo")
	p = w.jogador
	p._aura = -1000.0  # a Aura serena fica fora das contas
	p.global_position = w.centro + Vector2(0, 80)
	aliado = JOGADOR.instantiate()
	aliado.name = "2"
	aliado.classe = &"mago"
	aliado.position = p.global_position + Vector2(30, 0)
	w.entidades.add_child(aliado)
	await get_tree().physics_frame

	_tabela()
	await _teclas()
	await _martelo()
	await _circulo()
	await _elo()
	await _levantar()
	await _fonte()
	await _barreira()
	await _santuario()
	await _intervencao()
	await _muralha()
	await _coluna()
	await _martelo_giratorio()
	await _aurora()
	await _amanhecer()
	await _passivas()
	terminar()


# --- Ajudantes -------------------------------------------------------------------------------

func _slime(pos: Vector2, noturno := false, parado := true) -> Slime:
	var s: Slime = SLIME.instantiate()
	s.noturno = noturno
	s.position = pos
	w.entidades.add_child(s, true)
	s.set_physics_process(not parado)
	s.vida.maximo = VIDA_SLIME
	s.vida.atual = VIDA_SLIME
	return s


func _tirou(s: Slime) -> float:
	return VIDA_SLIME - (s.vida.atual if is_instance_valid(s) else 0.0)


## Aprende (de graça), põe só ela nas teclas, enche a mana e usa mirando em `mira`.
func _usar(id: StringName, mira: Vector2) -> void:
	p.aprender_de_graca(id)
	var t: Array[StringName] = [id]
	p.teclas = t
	p._recargas.clear()
	p._prontas_no_anfitriao.clear()
	p.mana = p.ficha.mana_maxima()
	p.mira_forcada = mira
	var mana_antes := p.mana
	var nivel := p.nivel  # derrotar um slime pode subir de nível (e encher a mana)
	checar(p.usar_habilidade_por_id(id), "%s está na tecla e foi usada" % id)
	var hab := ArvoreData.no(&"clerigo", id).habilidade
	checar((is_equal_approx(mana_antes - p.mana, hab.custo_mana) or p.nivel > nivel) and p.recarga_restante(0) > 0.0,
			"%s gastou %.0f de mana e entrou em recarga" % [id, hab.custo_mana])
	await get_tree().physics_frame


func _limpar() -> void:
	for s in get_tree().get_nodes_in_group(&"inimigos"):
		s.queue_free()
	for z in w.entidades.get_children():
		if z is Zona:
			z.queue_free()
	for j: Player in [p, aliado]:
		j.vida.curar_tudo()
		j.vida.escudo = 0.0
		j.vida._protecao = 0.0
		j.efeitos.limpar_ruins()
	p.global_position = w.centro + Vector2(0, 80)
	aliado.global_position = p.global_position + Vector2(30, 0)
	await get_tree().physics_frame
	await get_tree().physics_frame


func _mult() -> float:
	return p.ficha.multiplicador_magico()


# --- Testes ----------------------------------------------------------------------------------

func _tabela() -> void:
	var pendentes := 0
	for n in ArvoreData.nos(&"clerigo"):
		if n.pendente or n.falta != "":
			pendentes += 1
	checar(pendentes == 0, "nenhum nó do Clérigo pendente ou parcial (%d)" % pendentes)
	for id in ATIVAS:
		var n := ArvoreData.no(&"clerigo", id)
		checar(n != null and n.usavel() and n.habilidade.logica != &"" and Logicas.classe_da_logica(n.habilidade.logica) != null,
				"%s é usável e tem lógica" % id)


func _teclas() -> void:
	p.aprender_de_graca(&"martelo_da_justica")
	checar(&"martelo_da_justica" in p.ids_nas_teclas(), "aprendida, o Martelo da justiça vai para uma tecla livre")


func _martelo() -> void:
	await _limpar()
	var s := _slime(p.global_position + Vector2(34, -4))
	await get_tree().physics_frame
	await _usar(&"martelo_da_justica", p.global_position + Vector2(100, 0))
	var dano := 1.5 * _mult()
	await esperar(0.3)
	checar(absf(_tirou(s) - dano) < 0.01, "Martelo: acerta na ida (%.2f de %.2f)" % [_tirou(s), dano])
	checar(EfeitosEstado.de(s).tem(EfeitosEstado.ATORDOADO), "Martelo: Atordoa")
	await esperar(1.2)
	checar(absf(_tirou(s) - 2.0 * dano) < 0.01, "Martelo: volta e acerta de novo (%.2f)" % _tirou(s))
	checar(get_tree().get_nodes_in_group(&"projeteis").is_empty(), "Martelo: voltou para a mão e sumiu")
	# Melhoria: +15% de dano.
	p.arvore[&"martelo_da_justica"] = 2
	var s2 := _slime(p.global_position + Vector2(0, 34))
	await _usar(&"martelo_da_justica", p.global_position + Vector2(0, 100))
	await esperar(0.3)
	checar(absf(_tirou(s2) - dano * 1.15) < 0.01, "Martelo com 1 melhoria: +15%% (%.2f)" % _tirou(s2))
	await esperar(1.2)


func _circulo() -> void:
	await _limpar()
	p.vida.atual = p.vida.maximo - 60.0
	var hab := ArvoreData.no(&"clerigo", &"circulo_de_cura").habilidade
	var q := LogicasClerigo.CirculoDeCura.por_tique(p, hab)
	await _usar(&"circulo_de_cura", p.global_position + Vector2(20, 0))
	await esperar(2.5)  # tiques em 0, 1 e 2 s
	var ganho := p.vida.atual - (p.vida.maximo - 60.0)
	checar(absf(ganho - 3.0 * q) < 0.01, "Círculo de cura: 3 tiques de %.1f em 2,5 s (+%.1f)" % [q, ganho])
	checar(absf(aliado.vida.atual - aliado.vida.maximo) < 0.01, "Círculo de cura: o aliado dentro já estava cheio")
	await esperar(4.0)
	var depois := p.vida.atual
	await esperar(1.2)
	checar(is_equal_approx(depois, p.vida.atual), "Círculo de cura acaba depois de 6 s")


func _elo() -> void:
	await _limpar()
	await _usar(&"elo_vital", aliado.global_position)
	checar(PassivasClerigo.elo_de(p) == aliado and PassivasClerigo.elo_de(aliado) == p, "Elo vital liga o Clérigo ao aliado")
	p.vida.tomar_dano(10.0, &"fisico")
	checar(absf(p.vida.maximo - p.vida.atual - 5.0) < 0.01 and absf(aliado.vida.maximo - aliado.vida.atual - 5.0) < 0.01,
			"Elo vital: 10 de dano viram 5 em cada (%.1f e %.1f)" % [p.vida.maximo - p.vida.atual, aliado.vida.maximo - aliado.vida.atual])
	var antes := p.vida.atual
	aliado.receber_cura(null, 4.0)
	checar(absf(p.vida.atual - antes - 4.0) < 0.01, "Elo vital: a cura do aliado também cura o Clérigo (+%.1f)" % (p.vida.atual - antes))
	for j: Player in [p, aliado]:
		j.remove_meta(&"elo_com")


func _levantar() -> void:
	await _limpar()
	aliado.vida.tomar_dano(100000.0)  # desmaia: acorda no acampamento (cheio)
	await get_tree().physics_frame
	aliado.global_position = p.global_position + Vector2(400, 0)
	checar(PassivasClerigo.ultimo_caido(p) == aliado, "Levantar sabe quem desmaiou no último minuto")
	await _usar(&"levantar", p.global_position)
	checar(aliado.global_position.distance_to(p.global_position) < 20.0, "Levantar traz o aliado para o lado do Clérigo (%.0f px)" % aliado.global_position.distance_to(p.global_position))
	checar(aliado.vida.protegido(), "Levantar: o aliado chega protegido")
	checar(PassivasClerigo.ultimo_caido(p) == null, "Levantar: não traz o mesmo duas vezes")


func _fonte() -> void:
	await _limpar()
	for j: Player in [p, aliado]:
		j.vida.atual = j.vida.maximo - 60.0
	EfeitosEstado.aplicar_em(aliado, EfeitosEstado.VENENO, 5.0, 1.0)
	var hab := ArvoreData.no(&"clerigo", &"fonte_da_vida").habilidade
	var q := LogicasClerigo.FonteDaVida.por_tique(p, hab)
	await _usar(&"fonte_da_vida", p.global_position)
	await esperar(0.1)
	checar(absf(aliado.vida.atual - (aliado.vida.maximo - 60.0 + q)) < 0.01, "Fonte da vida cura o aliado (+%.1f)" % q)
	checar(not aliado.efeitos.tem(EfeitosEstado.VENENO), "Fonte da vida limpa o Veneno")
	await esperar(1.0)
	checar(absf(p.vida.atual - (p.vida.maximo - 60.0 + 2.0 * q)) < 0.01, "Fonte da vida: um tique por segundo (+%.1f)" % (p.vida.atual - p.vida.maximo + 60.0))


func _barreira() -> void:
	await _limpar()
	aliado.global_position = p.global_position + Vector2(0, 200)
	var parede_x := p.global_position.x + LogicasClerigo.Barreira.DISTANCIA
	var s := _slime(Vector2(parede_x, p.global_position.y), false, false)
	await get_tree().physics_frame
	await _usar(&"barreira", p.global_position + Vector2(100, 0))
	var flecha: Projetil = Logicas.FLECHA.instantiate()
	flecha.lancador = s
	flecha.do_inimigo = true  # flecha de inimigo (como a do Atirador)
	flecha.direcao = Vector2.LEFT
	flecha.position = Vector2(parede_x + 30, p.global_position.y + 10)
	w.entidades.add_child(flecha, true)
	var menor := INF
	for k in 36:  # 0,6 s
		await get_tree().physics_frame
		menor = minf(menor, s.global_position.x - parede_x)
	checar(menor > 0.0, "Barreira: o slime que tenta chegar no Clérigo não atravessa (no mínimo %.1f px do lado de lá)" % menor)
	checar(not is_instance_valid(flecha), "Barreira: o projétil inimigo some nela")


func _santuario() -> void:
	await _limpar()
	aliado.global_position = p.global_position + Vector2(0, 200)
	var s := _slime(p.global_position + Vector2(18, 0), false, false)
	await get_tree().physics_frame
	await _usar(&"santuario", p.global_position)
	await esperar(0.6)
	var d := s.global_position.distance_to(p.global_position)
	checar(d >= LogicasClerigo.Santuario.RAIO - 6.0, "Santuário: o slime fica fora (%.0f px, raio %.0f)" % [d, LogicasClerigo.Santuario.RAIO])


func _intervencao() -> void:
	await _limpar()
	await _usar(&"intervencao", aliado.global_position)
	aliado.vida.tomar_dano(10.0)
	checar(is_equal_approx(aliado.vida.atual, aliado.vida.maximo), "Intervenção: o aliado na mira não toma dano")
	p.vida.tomar_dano(10.0)
	checar(p.vida.atual < p.vida.maximo, "Intervenção: o Clérigo (fora da mira) toma")
	await esperar(2.2)
	aliado.vida.tomar_dano(10.0)
	checar(aliado.vida.atual < aliado.vida.maximo, "Intervenção acaba depois de 2 s")


func _muralha() -> void:
	await _limpar()
	await _usar(&"muralha_da_fe", p.global_position)
	await esperar(0.15)
	for j: Player in [p, aliado]:
		j.vida.tomar_dano(10.0)
	checar(is_equal_approx(p.vida.atual, p.vida.maximo) and is_equal_approx(aliado.vida.atual, aliado.vida.maximo),
			"Muralha da fé: ninguém dentro toma dano")
	await esperar(4.3)
	for j: Player in [p, aliado]:
		j.vida._protecao = 0.0
		j.vida.tomar_dano(10.0)
	checar(p.vida.atual < p.vida.maximo and aliado.vida.atual < aliado.vida.maximo, "Muralha da fé acaba depois de 4 s")


func _coluna() -> void:
	await _limpar()
	var ponto := p.global_position + Vector2(70, 0)
	var s := _slime(ponto)
	var longe := _slime(ponto + Vector2(40, 0))
	await get_tree().physics_frame
	await _usar(&"coluna_de_luz", ponto)
	checar(_tirou(s) == 0.0, "Coluna de luz: ainda não caiu")
	await esperar(0.5)
	checar(absf(_tirou(s) - 3.0 * _mult()) < 0.01, "Coluna de luz: cai no ponto (%.2f)" % _tirou(s))
	checar(_tirou(longe) == 0.0, "Coluna de luz: não acerta quem está longe do ponto")


func _martelo_giratorio() -> void:
	await _limpar()
	var s := _slime(p.global_position + Vector2(16, 0))
	await get_tree().physics_frame
	await _usar(&"martelo_giratorio", p.global_position)
	await esperar(1.2)  # tiques em 0; 0,5 e 1 s
	checar(absf(_tirou(s) - 3.0 * 0.8 * _mult()) < 0.01, "Martelo giratório: 3 acertos em 1,2 s (%.2f)" % _tirou(s))
	p.global_position += Vector2(0, 100)  # gira junto do Clérigo
	await esperar(0.6)
	checar(absf(_tirou(s) - 3.0 * 0.8 * _mult()) < 0.01, "Martelo giratório anda com o Clérigo (o slime longe não leva)")
	await esperar(3.5)


func _aurora() -> void:
	await _limpar()
	var dia := _slime(p.global_position + Vector2(30, 0))
	var noite := _slime(p.global_position + Vector2(40, 6), true)
	var atras := _slime(p.global_position + Vector2(-30, 0))
	await get_tree().physics_frame
	await _usar(&"aurora", p.global_position + Vector2(100, 0))
	checar(absf(_tirou(dia) - 1.5 * _mult()) < 0.01 and EfeitosEstado.de(dia).tem(EfeitosEstado.CEGO), "Aurora: machuca e Cega o slime do dia (%.2f)" % _tirou(dia))
	checar(not is_instance_valid(noite) or not noite.vida.esta_vivo(), "Aurora: derrete o slime da noite")
	checar(_tirou(atras) == 0.0, "Aurora: não acerta quem está fora do cone")


func _amanhecer() -> void:
	await _limpar()
	var escala := p.luz.texture_scale
	var noite := _slime(p.global_position + Vector2(70, 0), true)
	await get_tree().physics_frame
	await _usar(&"amanhecer", p.global_position)
	await esperar(0.1)
	checar(not is_instance_valid(noite) or not noite.vida.esta_vivo(), "Amanhecer: derrete o slime da noite na área")
	checar(World.luz_que_protege(p, p.global_position + Vector2(90, 0)) != Vector2.INF, "Amanhecer: a área vira luz que protege (como a fogueira)")
	checar(p.luz.texture_scale > escala * 3.0, "Amanhecer: a luz do Clérigo cresce (%.1f → %.1f)" % [escala, p.luz.texture_scale])
	await esperar(10.3)
	checar(World.luz_que_protege(p, p.global_position + Vector2(90, 0)) == Vector2.INF and is_equal_approx(p.luz.texture_scale, escala),
			"Amanhecer acaba depois de 10 s")


func _passivas() -> void:
	await _limpar()
	# Luz própria (da classe): a comida que o Clérigo DÁ cura +50% (dar: vida cheia, aliado ferido perto).
	p.inventario.adicionar(&"carne_assada", 1)
	var espaco := -1
	for k in Inventory.BARRA:
		if p.inventario.item_em(k) == &"carne_assada":
			espaco = k
	var cura := ItemData.carregar(&"carne_assada").cura
	p.vida.curar_tudo()
	aliado.global_position = p.global_position + Vector2(20, 0)
	aliado.vida.atual = aliado.vida.maximo - 60.0
	p._pedir_usar(espaco)
	checar(absf(aliado.vida.atual - (aliado.vida.maximo - 60.0 + cura * 1.5)) < 0.01, "Luz própria: a carne dada ao aliado cura %.1f (era %.1f)" % [cura * 1.5, cura])
	aliado.vida.curar_tudo()

	# Mãos que curam: a cura tira Veneno e Queimadura.
	p.aprender_de_graca(&"maos_que_curam")
	EfeitosEstado.aplicar_em(p, EfeitosEstado.VENENO, 5.0, 1.0)
	EfeitosEstado.aplicar_em(p, EfeitosEstado.QUEIMADURA, 5.0, 1.0)
	EfeitosEstado.aplicar_em(p, EfeitosEstado.LENTIDAO, 5.0, 0.3)
	p.receber_cura(p, 2.0)
	checar(not p.efeitos.tem(EfeitosEstado.VENENO) and not p.efeitos.tem(EfeitosEstado.QUEIMADURA), "Mãos que curam: a cura tira Veneno e Queimadura")
	checar(p.efeitos.tem(EfeitosEstado.LENTIDAO), "Mãos que curam: os outros estados ficam")

	# Fogo sagrado: a luz queima.
	p.aprender_de_graca(&"fogo_sagrado")
	var s := _slime(p.global_position + Vector2(30, 0))
	await get_tree().physics_frame
	(s.get_node("Hurtbox") as Hurtbox).receber(4.0, &"luz", p)
	var e := EfeitosEstado.de(s)
	checar(e.tem(EfeitosEstado.QUEIMADURA) and is_equal_approx(e.forca(EfeitosEstado.QUEIMADURA), 1.0), "Fogo sagrado: 4 de luz deixam Queimadura de 1 por segundo")
	var antes := _tirou(s)
	await esperar(1.2)
	checar(_tirou(s) - antes >= 0.99, "Fogo sagrado: a Queimadura tira vida (%.2f em 1 s)" % (_tirou(s) - antes))

	# Fé: o escudo aparece no HUD.
	p.vida.dar_escudo(20.0, 5.0)
	await get_tree().process_frame
	await get_tree().process_frame
	checar(w.hud._linha_escudo.visible and w.hud._barra_escudo.value > 0.0, "Fé: o escudo aparece no HUD (%.0f%%)" % w.hud._barra_escudo.value)
