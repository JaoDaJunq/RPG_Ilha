extends TesteBase
## Conjuração (design/conjuracao.md): segurar a tecla conjura, soltar cedo cancela sem gastar,
## soltar no verde lança; o anel vai de vermelho a amarelo e verde; anda mais devagar; o
## Intelecto acelera (até -40%); apanhar só atrasa; o anfitrião não deixa sair antes da hora;
## o arqueiro puxa o arco (Tiro carregado) e a carga continua depois do verde.

var w: World
var p: Player


func _ready() -> void:
	await _mago()
	await _arqueiro()
	terminar()


## Aperta ou solta a tecla da habilidade `i` como o jogador faria (evento de entrada).
func _tecla(i: int, apertada: bool) -> void:
	var e := InputEventAction.new()
	e.action = StringName("habilidade_%d" % (i + 1))
	e.pressed = apertada
	Input.parse_input_event(e)
	await get_tree().process_frame
	await get_tree().physics_frame


func _indice(id: StringName) -> int:
	var hab := p.habilidades()
	for i in hab.size():
		if hab[i].id == id:
			return i
	return -1


func _cheio() -> void:
	p.mana = p.ficha.mana_maxima()
	p._recargas.clear()
	p._prontas_no_anfitriao.clear()


func _mago() -> void:
	w = await criar_mundo(0, true, &"mago")
	p = w.jogador
	p.teclas = ArvoreData.padrao(&"mago").duplicate()
	p.aprender_de_graca(&"tornado_de_fogo")
	var i := _indice(&"tornado_de_fogo")
	checar(i >= 0, "Tornado de fogo nas teclas (%d)" % i)
	var hab := p.habilidades()[i]
	p.mira_forcada = p.global_position + Vector2(80, 0)
	await get_tree().physics_frame

	# Fórmula: Intelecto 9 (mago humano) → -12%.
	var t := Conjuracao.tempo(p, hab)
	checar(absf(t - 1.0 * 0.88) < 0.001, "Tornado: 1 s de base, %.2f s com Intelecto %d (-12%%)" % [t, p.ficha.valor(&"intelecto")])
	checar(TextoHabilidade.de_habilidade(hab, "T", p.ficha).conjuracao.contains("0,88 s"), "a janelinha mostra o tempo: " + TextoHabilidade.de_habilidade(hab, "T", p.ficha).conjuracao)

	# Soltar cedo: cancela sem gastar mana nem entrar em recarga.
	_cheio()
	var mana0 := p.mana
	await _tecla(i, true)
	checar(p.conjuracao.ativa(), "segurar a tecla começa a conjurar")
	await esperar(0.3)
	checar(p.animacao.begins_with("conjurar"), "o boneco fica na pose de conjurar (%s)" % p.animacao)
	checar(p.conjuracao.anel.visible and p.conjuracao.anel.cor() == AnelConjuracao.COR_VERMELHO, "o anel aparece vermelho no começo")
	await _tecla(i, false)
	await esperar(0.1)
	checar(not p.conjuracao.ativa(), "soltar cedo cancela")
	checar(absf(p.mana - mana0) < 0.5, "soltar cedo não gasta mana (%.1f → %.1f)" % [mana0, p.mana])
	checar(p.recarga_restante(i) <= 0.0, "soltar cedo não entra em recarga")
	checar(p.conjuracao._host_id == &"", "o anfitrião também parou de contar")

	# Andar mais devagar conjurando (Tornado: metade).
	var x0 := p.global_position.x
	Input.action_press(&"mover_direita")
	await esperar(0.4)
	var livre := p.global_position.x - x0
	await _tecla(i, true)
	x0 = p.global_position.x
	await esperar(0.4)
	var conjurando := p.global_position.x - x0
	Input.action_release(&"mover_direita")
	checar(livre > 1.0 and absf(conjurando / livre - hab.velocidade_conjurando) < 0.1, "conjurando anda %.0f%% (%.1f px contra %.1f)" % [conjurando / livre * 100.0, conjurando, livre])
	await _tecla(i, false)
	await esperar(0.1)

	# Segurar até o verde: vermelho → amarelo → verde, e a bola sai ao soltar.
	_cheio()
	p.global_position = w.centro
	await get_tree().physics_frame
	mana0 = p.mana
	await _tecla(i, true)
	await esperar(t * 0.82)
	checar(p.conjuracao.anel.cor() == AnelConjuracao.COR_AMARELO and not p.conjuracao.pronta(), "perto do fim o anel fica amarelo (%.0f%%)" % (p.conjuracao.progresso() * 100.0))
	await esperar(t * 0.18 + 0.1)
	checar(p.conjuracao.pronta() and p.conjuracao.anel.cor() == AnelConjuracao.COR_VERDE, "pronto: o anel fica verde")
	checar(p.conjuracao.anel._piscar > 0.0 or p.conjuracao.anel.scale.x > 1.0, "verde com uma piscadinha")
	await _tecla(i, false)
	await esperar(0.1)
	checar(p.mana < mana0 - 1.0, "soltar no verde lança (mana %.1f → %.1f)" % [mana0, p.mana])
	checar(p.recarga_restante(i) > 0.0, "e entra em recarga")
	checar(not p.conjuracao.anel.visible or p.conjuracao.anel.modulate.a < 1.0, "o anel some ao lançar")

	# O anfitrião confere: "soltar" sem conjurar (cliente trapaceando) é recusado e a recarga
	# que o dono já tinha contado volta.
	_cheio()
	mana0 = p.mana
	p.usar_habilidade(i, 0.0)
	await esperar(0.1)
	checar(absf(p.mana - mana0) < 0.5, "o anfitrião recusa lançar sem conjurar")
	checar(p.recarga_restante(i) <= 0.0, "recusado: a recarga do dono volta a zero")
	# Soltar muito cedo (cliente adiantado): recusado também.
	p.conjuracao.comecar(i, hab)
	await esperar(0.2)
	p.conjuracao.terminar()
	p.usar_habilidade(i, 0.0)
	await esperar(0.1)
	checar(absf(p.mana - mana0) < 0.5, "o anfitrião recusa o soltar 0,7 s adiantado")
	# Um pouco cedo (rede): o anfitrião espera a hora e só então lança.
	_cheio()
	mana0 = p.mana
	p.conjuracao.comecar(i, hab)
	await esperar(t - 0.12)
	p.conjuracao.terminar()
	p.usar_habilidade(i, 0.0)
	await get_tree().physics_frame
	checar(absf(p.mana - mana0) < 0.5, "soltar 0,1 s adiantado: nada sai antes da hora")
	await esperar(0.2)
	checar(p.mana < mana0 - 1.0, "e sai quando dá a hora no relógio do anfitrião")

	# Apanhar no meio não cancela, só atrasa 0,15 s.
	_cheio()
	await _tecla(i, true)
	await esperar(0.2)
	var antes := p.conjuracao.decorrido()
	p.reagir_ao_golpe(p.global_position + Vector2(10, 0))
	await get_tree().physics_frame
	checar(p.conjuracao.ativa(), "apanhar não cancela a conjuração")
	checar(p.conjuracao.decorrido() < antes, "apanhar atrasa (%.2f s → %.2f s)" % [antes, p.conjuracao.decorrido()])
	checar(absf(p.conjuracao._host_atraso - Conjuracao.ATRASO_GOLPE) < 0.001, "o anfitrião conta o mesmo atraso")
	for k in 5:
		p.reagir_ao_golpe(p.global_position + Vector2(10, 0))
	await get_tree().physics_frame
	checar(absf(p.conjuracao._host_atraso - Conjuracao.ATRASO_MAXIMO) < 0.001, "o atraso tem limite (%.2f s)" % p.conjuracao._host_atraso)
	await _tecla(i, false)
	await esperar(0.1)

	# O dash cancela.
	_cheio()
	await _tecla(i, true)
	p.esquivar()
	await get_tree().physics_frame
	checar(not p.conjuracao.ativa(), "o dash cancela a conjuração")

	# Intelecto acelera, com limite de -40%.
	p.distribuidos[&"intelecto"] = 6
	p._recalcular_ficha()
	var t2 := Conjuracao.tempo(p, hab)
	checar(t2 < t - 0.1, "mais Intelecto, conjuração mais rápida (%d: %.2f s)" % [p.ficha.valor(&"intelecto"), t2])
	p.distribuidos[&"intelecto"] = 30
	p._recalcular_ficha()
	checar(absf(Conjuracao.tempo(p, hab) - 0.6) < 0.001, "no máximo -40%% (Intelecto %d: %.2f s)" % [p.ficha.valor(&"intelecto"), Conjuracao.tempo(p, hab)])
	p.distribuidos.erase(&"intelecto")
	p._recalcular_ficha()

	# Golpe rápido, dash e movimento não conjuram.
	for id: StringName in [&"piscar"]:
		checar(not Conjuracao.conjura(ArvoreData.no(&"mago", id).habilidade), "%s sai na hora" % id)
	w.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame


func _arqueiro() -> void:
	w = await criar_mundo(0, true, &"arqueiro")
	p = w.jogador
	var i := _indice(&"tiro_carregado")
	var hab := p.habilidades()[i]
	p.mira_forcada = p.global_position + Vector2(80, 0)
	_cheio()
	await get_tree().physics_frame
	var t := Conjuracao.tempo(p, hab)
	var mao_leve := Passivas.MAO_LEVE_CARGA if p.tem(&"mao_leve") else 1.0
	checar(absf(t - 0.4 * (1.0 - Conjuracao.reducao(p.ficha, &"agilidade")) / mao_leve) < 0.001, "Tiro carregado: puxar %.2f s (Agilidade %d, Mão leve: %s)" % [t, p.ficha.valor(&"agilidade"), p.tem(&"mao_leve")])
	var mana0 := p.mana
	await _tecla(i, true)
	await get_tree().process_frame
	await esperar(0.1)
	checar(p.carga_arco > 0.0 and p.carga_arco < 1.0, "o arco está sendo puxado (corda %.2f)" % p.carga_arco)
	checar(p.conjuracao.velocidade() < 1.0, "puxando o arco anda mais devagar (%.0f%%)" % (p.conjuracao.velocidade() * 100.0))
	await _tecla(i, false)
	await esperar(0.1)
	checar(absf(p.mana - mana0) < 0.3, "soltar a corda cedo não atira")
	await _tecla(i, true)
	await esperar(t + 0.05)
	checar(p.conjuracao.pronta() and p.carga_atual() < 0.5, "pronto para atirar; a carga continua (%.2f)" % p.carga_atual())
	await esperar(1.0)
	checar(p.carga_atual() >= 1.0, "segurando mais, a carga enche")
	await _tecla(i, false)
	await esperar(0.1)
	checar(p.mana < mana0 - 1.0, "soltar atira a flecha")
	checar(p.carga_arco < 0.0, "a corda volta")
	checar(TextoHabilidade.de_habilidade(hab, "Q", p.ficha).conjuracao.begins_with("Puxar o arco"), "a janelinha fala em puxar o arco")
