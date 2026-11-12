extends TesteBase
## Árvore do Guerreiro: cada nó que era pendente agora funciona. Para cada um, aprende,
## usa (ou mede a passiva) e confere o efeito com números.

const SLIME := preload("res://scenes/enemies/slime.tscn")
const ARVORE := preload("res://scenes/world/arvore.tscn")
const PEDRA := preload("res://scenes/world/pedra.tscn")
const JOGADOR := preload("res://scenes/player/player.tscn")

const NOVAS: Array[StringName] = [&"grito_de_guerra", &"escudo_arremessado", &"provocar", &"bastiao", &"juramento",
		&"machadada", &"salto_esmagador", &"redemoinho", &"furia_titanica", &"estandarte", &"corrente",
		&"ordem_de_ataque", &"avancar"]

var _criados: Array[Node] = []


func _ready() -> void:
	var w := await criar_mundo(0, true, &"guerreiro")
	var p := w.jogador
	p.global_position = w.centro + Vector2(0, 60)
	await get_tree().physics_frame
	_tabela(p)
	await _teclas_e_melhorias(p)
	await _grito(w, p)
	await _escudo(w, p)
	await _provocar(w, p)
	await _bastiao(w, p)
	await _juramento(w, p)
	await _machadada(w, p)
	await _salto(w, p)
	await _redemoinho(w, p)
	await _titanica(w, p)
	await _estandarte(w, p)
	await _corrente(w, p)
	await _ordem(w, p)
	await _avancar(w, p)
	await _folego(w, p)
	_lenhador(p)
	await _contra_golpe(w, p)
	terminar()


# --- Ajudas ------------------------------------------------------------------------------

## Slime com 100 de vida. `parado`: sem pensar; senão pensa, mas sem andar (velocidade 0),
## para os empurrões e puxões aparecerem limpos.
func _slime(w: World, pos: Vector2, parado := true) -> Slime:
	var s: Slime = colocar(w, SLIME, pos)
	if parado:
		s.set_physics_process(false)
	else:
		s.velocidade = 0.0
	s.vida.maximo = 100.0
	s.vida.atual = 100.0
	_criados.append(s)
	return s


func _tirou(s: Slime) -> float:
	return 100.0 - (s.vida.atual if is_instance_valid(s) else 0.0)


## Um aliado só para o teste todo (o HUD guarda o nome de cada jogador: apagar um no meio
## do teste quebra o HUD). Entre um teste e outro ele vai para longe.
var _o_aliado: Player


func _aliado(w: World, pos: Vector2) -> Player:
	if _o_aliado == null:
		_o_aliado = JOGADOR.instantiate()
		_o_aliado.name = "2"
		_o_aliado.classe = &"mago"
		_o_aliado.position = pos
		w.entidades.add_child(_o_aliado)
	_o_aliado.global_position = pos
	_o_aliado.vida.curar_tudo()
	return _o_aliado


## Limpa o que o teste anterior deixou (slimes, aliados, buffs, vida) e volta ao ponto.
func _limpar(w: World, p: Player) -> void:
	for n in _criados:
		if is_instance_valid(n):
			n.queue_free()
	_criados.clear()
	if _o_aliado:
		_o_aliado.global_position = w.centro + Vector2(2000, 2000)
	for t in Buffs.TIPOS:
		p.buffs.tirar(t)
	p.vida.curar_tudo()
	p.efeitos.limpar_ruins()
	p.global_position = w.centro + Vector2(0, 60)
	await get_tree().physics_frame
	await get_tree().physics_frame


## Aprende `id`, põe na tecla Q, enche a mana e usa mirando em `mira`.
func _usar(p: Player, id: StringName, mira: Vector2) -> bool:
	p.aprender_de_graca(id)
	var t: Array[StringName] = [id]
	p.teclas = t
	p._recargas.clear()
	p._prontas_no_anfitriao.clear()
	p.mana = p.ficha.mana_maxima()
	p.mira_forcada = mira
	await get_tree().physics_frame
	return p.usar_habilidade_por_id(id)


func _hab(id: StringName) -> HabilidadeData:
	return ArvoreData.no(&"guerreiro", id).habilidade


## Dano de um acerto no slime já com as passivas do jogador (o mesmo que a Hurtbox faz).
func _no_slime(p: Player, s: Slime, base: float, tipo: StringName = &"fisico") -> float:
	return Passivas.dano_causado(p, base, tipo, s)


# --- Tabela, teclas e melhorias -----------------------------------------------------------

func _tabela(p: Player) -> void:
	var pendentes: Array[String] = []
	for n in ArvoreData.nos(&"guerreiro"):
		if n.pendente or n.falta != "":
			pendentes.append(String(n.id))
		if n.ativa() and not n.usavel():
			pendentes.append(String(n.id) + " (sem .tres)")
	checar(pendentes.is_empty(), "nenhum nó do Guerreiro pendente ou parcial (%s)" % ", ".join(pendentes))
	var lim := 15.0
	var caras: Array[String] = []
	for id in NOVAS:
		var h := _hab(id)
		if h == null or h.custo_mana > lim or h.recarga <= 0.0 or not Logicas.classe_da_logica(h.logica):
			caras.append(String(id))
	checar(caras.is_empty(), "as 13 ativas novas têm .tres com lógica, recarga e custo até 15 de mana (cabe no ogro) (%s)" % ", ".join(caras))
	checar(p.ficha.mana_maxima() >= lim, "a mana do guerreiro (%.0f) paga a suprema" % p.ficha.mana_maxima())


func _teclas_e_melhorias(p: Player) -> void:
	var antes := p.ids_nas_teclas().size()
	p.aprender_de_graca(&"grito_de_guerra")
	checar(&"grito_de_guerra" in p.ids_nas_teclas() and p.ids_nas_teclas().size() == antes + 1, "aprender o Grito põe ele numa tecla livre")
	var maquina := _hab(&"machadada")
	p.aprender_de_graca(&"machadada")
	var dano1 := HabilidadeLogica.dano_de(p, maquina)
	var rec1 := p.recarga_de(maquina)
	p.arvore[&"machadada"] = 3  # 2 melhorias
	var dano3 := HabilidadeLogica.dano_de(p, maquina)
	var rec3 := p.recarga_de(maquina)
	checar(ArvoreData.no(&"guerreiro", &"machadada").rank_maximo() == 4 and is_equal_approx(dano3 / dano1, 1.3) and is_equal_approx(rec3 / rec1, 0.8),
			"melhorias valem nas novas: Machadada com 2 melhorias dá %.2fx o dano e %.2fx a recarga" % [dano3 / dano1, rec3 / rec1])
	p.arvore[&"machadada"] = 1
	var t: Array[StringName] = []
	p.teclas = t
	await get_tree().physics_frame


# --- Iniciais e Guardião ------------------------------------------------------------------

func _grito(w: World, p: Player) -> void:
	var s := _slime(w, p.global_position + Vector2(30, 0))
	var longe := _slime(w, p.global_position + Vector2(0, 70))
	var mana0 := p.ficha.mana_maxima()
	checar(await _usar(p, &"grito_de_guerra", p.global_position + Vector2(50, -10)), "Grito de guerra vai para a tecla e é usado")
	await get_tree().physics_frame
	checar(s.efeitos.tem(EfeitosEstado.MEDO) and s.efeitos.restante(EfeitosEstado.MEDO) > 1.3 and s.efeitos.restante(EfeitosEstado.MEDO) <= 1.5,
			"Grito: o slime perto sente Medo (%.2f s)" % s.efeitos.restante(EfeitosEstado.MEDO))
	checar(not longe.efeitos.tem(EfeitosEstado.MEDO), "Grito: o slime longe (70 px) não sente")
	checar(is_equal_approx(p.buffs.valor(Buffs.DANO), 0.10) and p.buffs.restante(Buffs.DANO) > 5.8, "Grito: +10%% de dano por 6 s (%.2f por %.1f s)" % [p.buffs.valor(Buffs.DANO), p.buffs.restante(Buffs.DANO)])
	checar(mana0 - p.mana > 7.5 and mana0 - p.mana <= 8.0, "Grito gasta 8 de mana (%.2f)" % (mana0 - p.mana))
	await _limpar(w, p)


func _escudo(w: World, p: Player) -> void:
	var o := p.global_position
	var slimes: Array[Slime] = [_slime(w, o + Vector2(40, 0)), _slime(w, o + Vector2(40, 40)), _slime(w, o + Vector2(40, 80)), _slime(w, o + Vector2(40, 120))]
	await get_tree().physics_frame
	await _usar(p, &"escudo_arremessado", o + Vector2(100, -10))
	var tonto := [false, false, false, false]
	for k in 90:
		await get_tree().physics_frame
		for i in 4:
			if is_instance_valid(slimes[i]) and slimes[i].efeitos.tem(EfeitosEstado.ATORDOADO):
				tonto[i] = true
	var esperado := _no_slime(p, slimes[0], HabilidadeLogica.dano_de(p, _hab(&"escudo_arremessado")))
	checar(absf(_tirou(slimes[0]) - esperado) < 0.01 and _tirou(slimes[1]) > 0.0 and _tirou(slimes[2]) > 0.0,
			"Escudo arremessado acerta 3 inimigos (%.2f, %.2f, %.2f; esperado %.2f)" % [_tirou(slimes[0]), _tirou(slimes[1]), _tirou(slimes[2]), esperado])
	checar(_tirou(slimes[3]) == 0.0, "Escudo: o 4º não é acertado (quica só até 3)")
	checar(tonto[0] and tonto[1] and tonto[2] and not tonto[3], "Escudo atordoa cada um dos 3 (%s)" % [tonto])
	await _limpar(w, p)


func _provocar(w: World, p: Player) -> void:
	var a := _slime(w, p.global_position + Vector2(40, 0))
	var b := _slime(w, p.global_position + Vector2(-40, 0))
	var longe := _slime(w, p.global_position + Vector2(0, 90))
	await _usar(p, &"provocar", p.global_position)
	await get_tree().physics_frame
	checar(a.efeitos.alvo_provocado() == p and b.efeitos.alvo_provocado() == p and a.efeitos.restante(EfeitosEstado.PROVOCADO) > 3.8,
			"Provocar: os dois slimes perto perseguem o guerreiro por 4 s (%.2f s)" % a.efeitos.restante(EfeitosEstado.PROVOCADO))
	checar(not longe.efeitos.tem(EfeitosEstado.PROVOCADO), "Provocar: o slime a 90 px não é provocado")
	await _limpar(w, p)


func _bastiao(w: World, p: Player) -> void:
	var s := _slime(w, p.global_position + Vector2(20, 0), false)
	await get_tree().physics_frame
	await _usar(p, &"bastiao", p.global_position)
	await esperar(0.1)
	checar(is_equal_approx(p.buffs.valor(Buffs.REDUCAO), 0.5), "Bastião: quem está na cúpula ganha 50%% de redução (%.2f)" % p.buffs.valor(Buffs.REDUCAO))
	var antes := p.vida.atual
	p.vida.tomar_dano(10.0, &"fogo")
	checar(is_equal_approx(antes - p.vida.atual, 5.0), "Bastião: 10 de dano viram %.1f" % (antes - p.vida.atual))
	await esperar(0.6)
	var d := s.global_position.distance_to(p.global_position) if is_instance_valid(s) else 0.0
	checar(d > 40.0,"Bastião: o slime que estava dentro (20 px) foi empurrado para fora (%.0f px)" % d)
	await esperar(5.0)
	checar(not p.buffs.tem(Buffs.REDUCAO), "Bastião acaba depois de 5 s")
	await _limpar(w, p)


func _juramento(w: World, p: Player) -> void:
	var a := _aliado(w, p.global_position + Vector2(30, 0))
	await get_tree().physics_frame
	await _usar(p, &"juramento", p.global_position)
	await get_tree().physics_frame
	checar(PassivasGuerreiro.juramento_ativo(p), "Juramento fica ativo")
	var va := a.vida.atual
	var vp := p.vida.atual
	a.vida.tomar_dano(20.0, &"fogo")
	checar(is_equal_approx(va - a.vida.atual, 10.0) and is_equal_approx(vp - p.vida.atual, 10.0),
			"Juramento: o aliado tomou %.1f e o guerreiro %.1f (de 20)" % [va - a.vida.atual, vp - p.vida.atual])
	await esperar(0.6)  # passa a proteção depois do golpe
	p.vida.atual = 5.0
	p.vida.tomar_dano(50.0, &"fogo")
	checar(is_equal_approx(p.vida.atual, 1.0), "Juramento: o guerreiro não cai abaixo de 1 de vida (%.1f)" % p.vida.atual)
	p.remove_meta(PassivasGuerreiro.META_JURAMENTO)
	checar(PassivasGuerreiro.dano_recebido(p, 50.0, &"fogo") == 1.0 and PassivasGuerreiro.dano_recebido(a, 20.0, &"fogo") == 1.0,
			"sem o Juramento, nada é repassado nem segurado")
	await _limpar(w, p)


# --- Berserker ------------------------------------------------------------------------------

func _machadada(w: World, p: Player) -> void:
	var o := p.global_position
	var arvore: ResourceNode = colocar(w, ARVORE, o + Vector2(16, 0))
	var pedra: ResourceNode = colocar(w, PEDRA, o + Vector2(24, 8))
	_criados.append(arvore)
	var s := _slime(w, o + Vector2(20, -6))
	await get_tree().physics_frame
	var madeira0 := p.inventario.quantidade_de(&"madeira")
	var pedra0 := p.inventario.quantidade_de(&"pedra")
	await _usar(p, &"machadada", o + Vector2(100, -10))
	await get_tree().physics_frame
	var esperado := _no_slime(p, s, HabilidadeLogica.dano_de(p, _hab(&"machadada")))
	checar(absf(_tirou(s) - esperado) < 0.01, "Machadada machuca o slime na frente (%.2f; esperado %.2f)" % [_tirou(s), esperado])
	checar(arvore.estado == ResourceNode.Estado.ESGOTADO and p.inventario.quantidade_de(&"madeira") - madeira0 == 4,
			"Machadada derruba a árvore num golpe só (+%d madeira, com o Braço de lenhador)" % (p.inventario.quantidade_de(&"madeira") - madeira0))
	checar((not is_instance_valid(pedra) or pedra.is_queued_for_deletion()) and p.inventario.quantidade_de(&"pedra") > pedra0,
			"Machadada quebra a pedra num golpe só (+%d pedra)" % (p.inventario.quantidade_de(&"pedra") - pedra0))
	await _limpar(w, p)


func _salto(w: World, p: Player) -> void:
	var o := p.global_position
	var perto := _slime(w, o + Vector2(70, 0))
	var longe := _slime(w, o + Vector2(140, 0))
	await get_tree().physics_frame
	await _usar(p, &"salto_esmagador", o + Vector2(60, 0))
	await esperar(0.5)
	var andou := p.global_position.x - o.x
	checar(andou > 50.0, "Salto esmagador leva o guerreiro até a mira (%.0f px)" % andou)
	checar(_tirou(perto) > 0.0 and perto.efeitos.tem(EfeitosEstado.DERRUBADO), "Salto: o slime perto da queda é machucado e derrubado (%.2f)" % _tirou(perto))
	checar(_tirou(longe) == 0.0, "Salto: o slime longe da queda não")
	await _limpar(w, p)


func _redemoinho(w: World, p: Player) -> void:
	var o := p.global_position
	var a := _slime(w, o + Vector2(15, 0))
	var b := _slime(w, o + Vector2(80, 0))
	await get_tree().physics_frame
	var por_tique := _no_slime(p, a, HabilidadeLogica.dano_de(p, _hab(&"redemoinho")))
	await _usar(p, &"redemoinho", o + Vector2(50, -10))
	await esperar(1.6)
	p.global_position = o + Vector2(70, 0)  # anda com o redemoinho
	await esperar(1.8)
	var tiques := roundi(_tirou(a) / por_tique) + roundi(_tirou(b) / por_tique)
	checar(tiques == 7, "Redemoinho: 7 acertos em 3 s, um a cada 0,5 s (%d)" % tiques)
	checar(_tirou(a) > 0.0 and _tirou(b) > 0.0, "Redemoinho anda junto: acertou o slime do começo e o do fim do caminho (%.2f e %.2f)" % [_tirou(a), _tirou(b)])
	await _limpar(w, p)


func _titanica(w: World, p: Player) -> void:
	var o := p.global_position
	var alvo := _slime(w, o + Vector2(30, 0))
	var vizinho := _slime(w, o + Vector2(30, 20))
	var longe := _slime(w, o + Vector2(30, 70))
	await get_tree().physics_frame
	var escala0 := absf(p.visual.scale.y)
	await _usar(p, &"furia_titanica", o)
	await get_tree().physics_frame
	checar(PassivasGuerreiro.titanica_ativa(p) and is_equal_approx(absf(p.visual.scale.y) / escala0, 1.35), "Fúria titânica: o guerreiro cresce (%.2fx)" % (absf(p.visual.scale.y) / escala0))
	checar(Passivas.empurrao(p) == 0.0, "Fúria titânica: empurrão vira 0 (%.2f)" % Passivas.empurrao(p))
	Golpes.acertar(p, alvo, 4.0, &"fisico")
	checar(_tirou(vizinho) > 0.0 and absf(_tirou(vizinho) - _no_slime(p, vizinho, _tirou(alvo) * 0.5)) < 0.01 and _tirou(longe) == 0.0,
			"Fúria titânica: o golpe também acerta o vizinho com metade (%.2f de %.2f); o longe nada" % [_tirou(vizinho), _tirou(alvo)])
	p.remove_meta(PassivasGuerreiro.META_TITANICA)
	checar(Passivas.empurrao(p) == Passivas.PELE_EMPURRAO, "sem a Fúria titânica, o empurrão volta ao da Pele de ferro")
	await _limpar(w, p)


# --- Senhor da Guerra -----------------------------------------------------------------------

func _estandarte(w: World, p: Player) -> void:
	var o := p.global_position
	p.vida.atual = p.vida.maximo - 10.0
	await _usar(p, &"estandarte", o + Vector2(30, 0))
	await esperar(0.1)
	checar(is_equal_approx(p.buffs.valor(Buffs.DANO), 0.15), "Estandarte: +15%% de dano na área (%.2f)" % p.buffs.valor(Buffs.DANO))
	await esperar(1.0)
	var curou := p.vida.atual - (p.vida.maximo - 10.0)
	checar(is_equal_approx(curou, 4.0), "Estandarte: 2 de vida por segundo (2 tiques: +%.1f)" % curou)
	p.global_position = o + Vector2(0, 120)  # sai da área
	await esperar(1.5)
	checar(not p.buffs.tem(Buffs.DANO), "fora da bandeira o bônus acaba")
	await _limpar(w, p)


func _corrente(w: World, p: Player) -> void:
	var o := p.global_position
	var s := _slime(w, o + Vector2(80, 0), false)
	await get_tree().physics_frame
	var d0 := s.global_position.distance_to(o)
	await _usar(p, &"corrente", o + Vector2(100, -10))
	await esperar(0.9)
	var d1 := s.global_position.distance_to(p.global_position) if is_instance_valid(s) else 999.0
	checar(d1 < 30.0 and _tirou(s) > 0.0, "Corrente puxa o slime até o guerreiro (%.0f → %.0f px)" % [d0, d1])
	await _limpar(w, p)


func _ordem(w: World, p: Player) -> void:
	var o := p.global_position
	var marcado := _slime(w, o + Vector2(60, 0))
	var outro := _slime(w, o + Vector2(60, 50))
	await get_tree().physics_frame
	await _usar(p, &"ordem_de_ataque", marcado.global_position)
	await get_tree().physics_frame
	checar(marcado.efeitos.tem(EfeitosEstado.MARCADO) and not outro.efeitos.tem(EfeitosEstado.MARCADO), "Ordem de ataque marca só o inimigo na mira")
	(marcado.get_node("Hurtbox") as Hurtbox).receber(10.0, &"fisico", null)
	(outro.get_node("Hurtbox") as Hurtbox).receber(10.0, &"fisico", null)
	checar(is_equal_approx(_tirou(marcado), 13.0) and is_equal_approx(_tirou(outro), 10.0), "Ordem de ataque: todos dão +30%% no marcado (%.1f contra %.1f)" % [_tirou(marcado), _tirou(outro)])
	await _limpar(w, p)


func _avancar(w: World, p: Player) -> void:
	var o := p.global_position
	var a := _aliado(w, o + Vector2(0, 40))
	var no_meu := _slime(w, o + Vector2(35, 0))
	var no_dele := _slime(w, o + Vector2(35, 40))
	var fora := _slime(w, o + Vector2(35, 120))
	await get_tree().physics_frame
	await _usar(p, &"avancar", o + Vector2(100, -10))
	await esperar(0.4)
	checar(p.global_position.x - o.x > 50.0, "Avançar!: o guerreiro avança (%.0f px)" % (p.global_position.x - o.x))
	checar(_tirou(no_meu) > 0.0 and _tirou(no_dele) > 0.0 and _tirou(fora) == 0.0,
			"Avançar!: acerta o inimigo no caminho dele e no do aliado (%.2f e %.2f); o de fora não" % [_tirou(no_meu), _tirou(no_dele)])
	checar(is_instance_valid(a), "o aliado avançou junto")
	await _limpar(w, p)


# --- Passivas -------------------------------------------------------------------------------

func _folego(w: World, p: Player) -> void:
	var s := _slime(w, p.global_position + Vector2(30, 0))
	var b := _slime(w, p.global_position + Vector2(-30, 0))
	await get_tree().physics_frame
	p.recursos.ganhar_furia(RecursosClasse.FURIA_MAXIMA)
	Golpes.acertar(p, s, 1.0, &"fisico")
	checar(s.efeitos.tem(EfeitosEstado.ATORDOADO) and is_equal_approx(s.efeitos.restante(EfeitosEstado.ATORDOADO), 1.0),
			"Fôlego de batalha: com a Fúria cheia o golpe atordoa por 1 s")
	checar(is_equal_approx(p.recursos.furia, 50.0), "Fôlego gasta metade da Fúria (%.0f)" % p.recursos.furia)
	Golpes.acertar(p, b, 1.0, &"fisico")
	checar(not b.efeitos.tem(EfeitosEstado.ATORDOADO), "sem a Fúria cheia, o golpe não atordoa")
	await _limpar(w, p)


func _lenhador(p: Player) -> void:
	checar(PassivasGuerreiro.coleta(p, &"madeira", 3) == 4 and PassivasGuerreiro.coleta(p, &"pedra", 3) == 3,
			"Braço de lenhador: árvore rende 4 madeiras em vez de 3 (pedra igual)")
	checar(is_equal_approx(Passivas.coleta(p, false), 1.2), "Braço de lenhador: corta 20% mais rápido")


func _contra_golpe(w: World, p: Player) -> void:
	var s := _slime(w, p.global_position + Vector2(20, 0))
	await get_tree().physics_frame
	p.aprender_de_graca(&"bloqueio")
	p.arvore[&"contra_golpe"] = 1
	Passivas.ataque_inimigo(s, p, 10.0)
	checar(_tirou(s) == 0.0, "Contra-golpe: sem bloquear, nada volta")
	await _usar(p, &"bloqueio", p.global_position + Vector2(50, -10))
	await esperar(0.2)
	Passivas.ataque_inimigo(s, p, 10.0)
	var esperado := _no_slime(p, s, 5.0)
	checar(absf(_tirou(s) - esperado) < 0.01, "Contra-golpe: bloqueando na hora, metade do golpe volta (%.2f; esperado %.2f)" % [_tirou(s), esperado])
	await esperar(0.6)
	var antes := _tirou(s)
	Passivas.ataque_inimigo(s, p, 10.0)
	checar(is_equal_approx(_tirou(s), antes), "Contra-golpe: tarde demais (0,8 s depois de bloquear) não volta")
	await _limpar(w, p)
