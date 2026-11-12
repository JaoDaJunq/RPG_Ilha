extends TesteBase
## Efeitos de estado (components/efeitos_estado.gd): cada estado nos slimes, animais e no
## jogador, com duração, dano por segundo, cor, e o caminho que os outros jogadores recebem.

const SLIME := preload("res://scenes/enemies/slime.tscn")
const ANIMAL := preload("res://scenes/animals/animal.tscn")
const E := preload("res://scripts/components/efeitos_estado.gd")


func _ready() -> void:
	var w := await criar_mundo(0, true, &"mago")
	var p := w.jogador
	p.global_position = w.centro + Vector2(0, 60)
	await get_tree().physics_frame
	await _dano_por_segundo(w, p)
	await _movimento(w, p)
	await _ataque(w, p)
	await _marcado_e_limpar(w, p)
	await _animais(w, p)
	await _jogador(w, p)
	_rede()
	terminar()


func _slime(w: World, pos: Vector2, pensa := true, cego_ao_jogador := true) -> Slime:
	var s: Slime = colocar(w, SLIME, pos)
	s.set_physics_process(pensa)
	if cego_ao_jogador:
		s.raio_visao = 0.0  # não persegue o jogador (só os estados mexem nele)
	s.vida.maximo = 100.0
	s.vida.atual = 100.0
	return s


func _dano_por_segundo(w: World, p: Player) -> void:
	var s := _slime(w, p.global_position + Vector2(150, 0))
	await get_tree().physics_frame
	checar(EfeitosEstado.de(s) == s.efeitos, "o slime tem o componente EfeitosEstado")
	E.aplicar_em(s, E.QUEIMADURA, 3.0, 2.0, p)
	await get_tree().physics_frame
	checar(s.efeitos.tem(E.QUEIMADURA) and s.visual.modulate.is_equal_approx(E.COR[E.QUEIMADURA]), "Queimadura pega e deixa o slime alaranjado")
	await esperar(1.15)
	checar(is_equal_approx(s.vida.atual, 98.0), "Queimadura: 2 de dano depois de 1 s (vida %.1f)" % s.vida.atual)
	await esperar(2.2)
	checar(is_equal_approx(s.vida.atual, 94.0) and not s.efeitos.tem(E.QUEIMADURA), "Queimadura: 3 tiques e acaba (vida %.1f)" % s.vida.atual)
	# Veneno acumula até o máximo pedido; cada tique dá força x acúmulos.
	for k in 4:
		s.efeitos.aplicar(E.VENENO, 2.0, 1.0, p, 3)
	checar(s.efeitos.acumulos(E.VENENO) == 3, "Veneno acumula até 3 (%d)" % s.efeitos.acumulos(E.VENENO))
	checar(is_equal_approx(s.efeitos.dano_restante(E.VENENO), 6.0), "dano que o veneno ainda vai dar: 6 (%.1f)" % s.efeitos.dano_restante(E.VENENO))
	var antes := s.vida.atual
	await esperar(1.15)
	checar(is_equal_approx(antes - s.vida.atual, 3.0), "Veneno com 3 acúmulos tira 3 por tique (%.1f)" % (antes - s.vida.atual))
	await esperar(1.1)
	checar(not s.efeitos.tem(E.VENENO), "o Veneno acaba")
	# O envenenar antigo (Lâmina) continua: 1 acúmulo.
	s.envenenar(2.0, 0.5)
	checar(s.envenenado and s.efeitos.acumulos(E.VENENO) == 1, "envenenar() do slime usa o componente")
	# Queimadura que derruba: quem aplicou fica sabendo (vale para Contágio, Sede...).
	s.vida.atual = 1.0
	s.efeitos.remover(E.VENENO)
	E.aplicar_em(s, E.QUEIMADURA, 2.0, 5.0, p)
	await esperar(1.2)
	checar(not is_instance_valid(s) or s.is_queued_for_deletion(), "a Queimadura derrota o slime")


func _movimento(w: World, p: Player) -> void:
	# Medo: o slime foge de quem assustou. Com Lentidão de 50%, anda a metade.
	var s := _slime(w, p.global_position + Vector2(40, 0))
	s.raio_visao = 0.0  # sem perseguir: só o Medo move
	await get_tree().physics_frame
	E.aplicar_em(s, E.MEDO, 5.0, 0.0, p)
	await get_tree().physics_frame
	var a := s.global_position
	await esperar(0.5)
	var livre := s.global_position.distance_to(a)
	checar(livre > 5.0 and s.global_position.x > a.x, "Medo: foge de quem assustou (%.1f px)" % livre)
	E.aplicar_em(s, E.LENTIDAO, 5.0, 0.5, p)
	await get_tree().physics_frame
	a = s.global_position
	await esperar(0.5)
	var lento := s.global_position.distance_to(a)
	checar(absf(lento / livre - 0.5) < 0.12, "Lentidão de 50%%: anda a metade (%.1f de %.1f px)" % [lento, livre])
	for estado in [E.CONGELADO, E.ATORDOADO, E.PRESO, E.DERRUBADO]:
		E.aplicar_em(s, estado, 0.4)
		await get_tree().physics_frame
		a = s.global_position
		await esperar(0.25)
		checar(s.global_position.distance_to(a) < 0.5 and s.parado, "%s: não anda" % estado)
		await esperar(0.3)
		checar(not s.efeitos.tem(estado), "%s acaba sozinho" % estado)
	s.queue_free()
	# Provocado: persegue quem provocou (aqui uma invocação), não o jogador.
	var t := _slime(w, p.global_position + Vector2(30, 0))
	var isca := Invocacao.criar(p, p.global_position + Vector2(100, 0))
	isca.dano = 0.0
	isca.iniciar()
	await get_tree().physics_frame
	E.aplicar_em(t, E.PROVOCADO, 3.0, 0.0, isca)
	var d0 := t.global_position.distance_to(isca.global_position)
	await esperar(0.8)
	checar(t._alvo_atual == isca and t.global_position.distance_to(isca.global_position) < d0, "Provocado: vai atrás de quem provocou (%.0f → %.0f px)" % [d0, t.global_position.distance_to(isca.global_position)])
	t.queue_free()
	isca.queue_free()


func _ataque(w: World, p: Player) -> void:
	# Cego (força 1): o slime erra todas as cabeçadas.
	var s := _slime(w, p.global_position + Vector2(20, 0), true, false)
	E.aplicar_em(s, E.CEGO, 4.0, 1.0)
	var vida := p.vida.atual
	await esperar(2.5)
	checar(s.efeitos.erra_ataque() and is_equal_approx(p.vida.atual, vida), "Cego: o slime erra os ataques (vida %.0f → %.0f)" % [vida, p.vida.atual])
	# Atordoado: nem prepara o pulo.
	s.efeitos.remover(E.CEGO)
	E.aplicar_em(s, E.ATORDOADO, 1.5)
	await esperar(1.0)
	checar(not s.efeitos.pode_atacar() and s._estado != Slime.Estado.PULANDO and is_equal_approx(p.vida.atual, vida), "Atordoado: não ataca")
	s.queue_free()
	p.vida.curar_tudo()


func _marcado_e_limpar(w: World, p: Player) -> void:
	var s := _slime(w, p.global_position + Vector2(150, 0))
	await get_tree().physics_frame
	E.aplicar_em(s, E.MARCADO, 3.0)
	s.hurtbox.receber(10.0, &"veneno", null)
	checar(is_equal_approx(s.vida.atual, 88.0), "Marcado: toma +20%% de dano de todo mundo (vida %.1f)" % s.vida.atual)
	E.aplicar_em(s, E.LENTIDAO, 3.0, 0.3)
	E.aplicar_em(s, E.CONGELADO, 3.0)
	await get_tree().physics_frame
	checar(s.visual.modulate.is_equal_approx(E.COR[E.CONGELADO]), "com vários estados, a cor é a do mais importante (congelado)")
	s.efeitos.limpar_ruins()
	await get_tree().physics_frame
	checar(s.efeitos.ativos().is_empty() and s.visual.modulate.is_equal_approx(Color.WHITE), "limpar_ruins tira tudo e a cor volta")
	# O gelo congela e o golpe físico estilhaça (regras antigas, agora pelo componente).
	s.hurtbox.receber(1.0, &"gelo", p)
	checar(s.congelado() and s.parado, "gelo congela pelo componente")
	await esperar(0.2)
	s.hurtbox.receber(1.0, &"fisico", null)
	checar(not s.congelado(), "golpe físico estilhaça e descongela")
	s.queue_free()


func _animais(w: World, p: Player) -> void:
	var ovelha: Animal = ANIMAL.instantiate()
	ovelha.especie = &"ovelha"
	ovelha.position = p.global_position + Vector2(-40, 0)
	w.entidades.add_child(ovelha, true)
	await get_tree().physics_frame
	ovelha.prender(0.6)
	await get_tree().physics_frame
	var a := ovelha.global_position
	await esperar(0.4)
	checar(ovelha.preso() and ovelha.global_position.distance_to(a) < 0.5, "animal preso não anda")
	await esperar(0.4)
	E.aplicar_em(ovelha, E.MEDO, 2.0, 0.0, p)
	await get_tree().physics_frame
	a = ovelha.global_position
	await esperar(0.4)
	checar(ovelha.global_position.x < a.x - 3.0, "animal com Medo foge de quem assustou")
	E.aplicar_em(ovelha, E.VENENO, 2.0, 0.5, p)
	await esperar(0.05)
	checar(ovelha.envenenado and ovelha.visual.modulate.is_equal_approx(E.COR[E.VENENO]), "animal envenenado fica verde")
	ovelha.queue_free()


func _jogador(w: World, p: Player) -> void:
	checar(p.efeitos != null and p.buffs != null and p.recursos != null, "o jogador tem estados, buffs e recursos")
	var normal := p.multiplicador_velocidade()
	E.aplicar_em(p, E.LENTIDAO, 1.0, 0.4)
	checar(absf(p.multiplicador_velocidade() - normal * 0.6) < 0.01, "Lentidão no jogador: anda 40%% mais devagar")
	E.aplicar_em(p, E.PRESO, 1.0)
	checar(p.multiplicador_velocidade() == 0.0, "jogador preso não anda")
	p.efeitos.limpar_ruins()
	# Invisível: o slime perde o jogador de vista; o jogador fica meio transparente.
	var s := _slime(w, p.global_position + Vector2(40, 0), true, false)
	await esperar(0.3)
	checar(s.persegue(p), "antes, o slime persegue")
	E.aplicar_em(p, E.INVISIVEL, 1.0)
	await esperar(0.2)
	checar(p.escondido() and p.modulate.a < 0.6 and s._alvo_atual == null, "Invisível: os inimigos não veem o jogador")
	p.efeitos.limpar_ruins()
	checar(p.efeitos.invisivel(), "limpar_ruins não tira o Invisível")
	await esperar(1.0)
	checar(not p.escondido(), "o Invisível acaba")
	s.queue_free()


## O que os outros jogadores recebem (RPC _receber): estados com tempo, que acabam sozinhos.
func _rede() -> void:
	var dono := Node2D.new()
	var e := EfeitosEstado.new()
	e.name = "EfeitosEstado"
	dono.add_child(e)
	add_child(dono)
	e._receber({&"lentidao": [0.2, 0.5, 1], &"marcado": [5.0, 0.3, 1]})
	checar(absf(e.mult_velocidade() - 0.5) < 0.001 and absf(e.mult_dano_recebido() - 1.3) < 0.001, "o cliente recebe estado, força e tempo")
	checar(e.cor().is_equal_approx(E.COR[E.MARCADO]), "o cliente pinta pelo estado recebido")
	dono.queue_free()
