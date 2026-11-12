extends TesteBase
## Árvore de habilidades: os dados das 5 classes, aprender só com ponto, nível e
## pré-requisito, um ramo só, a passiva aprendida mudando o dano de verdade, melhorias,
## teclas, salvar e restaurar, e a tela (K) com os nós e o botão Aprender.

const SLIME := preload("res://scenes/enemies/slime.tscn")


func _ready() -> void:
	_dados()
	var w := await criar_mundo(0, true, &"arqueiro", &"humano")
	var p := w.jogador
	await _aprender(w, p)
	await _passiva_muda_o_dano(w, p)
	await _teclas_e_salvar(w, p)
	await _tela(w, p)
	terminar()


func _dados() -> void:
	for c in ClasseData.TODAS:
		var nos := ArvoreData.nos(c)
		var ramos := ArvoreData.ramos(c)
		checar(nos.size() == 3 + 5 + 6 * ramos.size(), "%s: 3 passivas, 5 iniciais e %d ramos de 6 passos (%d nós)" % [c, ramos.size(), nos.size()])
		var padrao := ArvoreData.padrao(c)
		checar(padrao.size() == 2 and padrao[0] == ClasseData.carregar(c).habilidades[0].id, "%s: as 2 habilidades padrão são as primeiras da classe" % c)
		var ruins: Array[String] = []
		for n in nos:
			if n.icone == null or (n.ativa() and not n.pendente and n.habilidade == null):
				ruins.append(String(n.id))
		checar(ruins.is_empty(), "%s: todo nó tem ícone e toda ativa que funciona tem a habilidade (%s)" % [c, ", ".join(ruins)])
	checar(ArvoreData.no(&"arqueiro", &"assobio").pendente and not ArvoreData.no(&"arqueiro", &"assobio").usavel(), "Assobio fica marcado como efeito pendente")
	checar(ArvoreData.no(&"mago", &"piscar").usavel() and ArvoreData.no(&"ladino", &"cambalhota").usavel(), "Piscar e Cambalhota (novas) já funcionam")


func _aprender(_w: World, p: Player) -> void:
	checar(p.nivel == 1 and p.pontos_habilidade == 0, "começa no nível 1, sem pontos")
	checar(p.habilidades().size() == 2 and p.tem(&"mao_leve") and p.tem(&"olho_de_aguia"), "nível 1: as 2 habilidades padrão e as passivas da classe")
	checar(not p.usar_habilidade_por_id(&"chuva_flechas"), "Chuva de flechas ainda não está nas teclas")

	p.pedir_aprender(&"chuva_flechas")
	await get_tree().physics_frame
	checar(not p.tem(&"chuva_flechas"), "nível 1: não aprende inicial (precisa do nível 2)")
	checar(p.motivo_bloqueio(ArvoreData.no(&"arqueiro", &"chuva_flechas")).contains("nível 2"), "o motivo diz o nível")

	p.ganhar_xp(Ficha.xp_para_subir(1))
	await get_tree().physics_frame
	checar(p.nivel == 2 and p.pontos_habilidade == 1, "nível 2: 1 ponto de habilidade")
	p.pedir_aprender(&"chuva_flechas")
	await get_tree().physics_frame
	checar(p.tem(&"chuva_flechas") and p.pontos_habilidade == 0, "aprender gasta o ponto (pontos: %d)" % p.pontos_habilidade)
	checar(p.habilidades().size() == 3 and p.habilidades()[2].id == &"chuva_flechas", "a habilidade aprendida vai para a próxima tecla (T)")

	p.pedir_aprender(&"bomba")
	await get_tree().physics_frame
	checar(not p.tem(&"bomba") and p.pontos_habilidade == 0, "sem pontos não aprende")
	checar(p.motivo_bloqueio(ArvoreData.no(&"arqueiro", &"bomba")).contains("Sem pontos"), "o motivo diz que faltam pontos")

	# Nível 6, com pontos sobrando: o ramo pede o passo anterior.
	while p.nivel < 6:
		p.ganhar_xp(Ficha.xp_para_subir(p.nivel))
	await get_tree().physics_frame
	var pontos := p.pontos_habilidade
	checar(p.nivel == 6 and pontos == 4, "nível 6 com 4 pontos (%d, %d)" % [p.nivel, pontos])
	p.pedir_aprender(&"flecha_perfurante")
	await get_tree().physics_frame
	checar(not p.tem(&"flecha_perfurante") and p.pontos_habilidade == pontos, "sem o pré-requisito (Ponto fraco) não aprende e não gasta ponto")
	checar(p.motivo_bloqueio(ArvoreData.no(&"arqueiro", &"flecha_perfurante")).contains("Ponto fraco"), "o motivo diz o pré-requisito")


func _passiva_muda_o_dano(w: World, p: Player) -> void:
	# Tiro rápido num slime a 7,5 blocos (mais de 6): antes e depois do Ponto fraco.
	var antes := await _dano_tiro_longe(w, p)
	p.pedir_aprender(&"ponto_fraco")
	await get_tree().physics_frame
	checar(p.tem(&"ponto_fraco") and p.ramo_escolhido() == &"atirador", "aprendeu Ponto fraco: o ramo Atirador foi escolhido")
	var depois := await _dano_tiro_longe(w, p)
	checar(antes > 0.0 and is_equal_approx(depois, antes * Passivas.PONTO_FRACO), "Ponto fraco: tiro de longe passa de %.3f para %.3f de dano (+25%%)" % [antes, depois])

	p.pedir_aprender(&"engenhoso")
	await get_tree().physics_frame
	checar(not p.tem(&"engenhoso"), "só um ramo: com o Atirador escolhido, não entra no Engenhoqueiro")
	checar(p.motivo_bloqueio(ArvoreData.no(&"arqueiro", &"engenhoso")).contains("Atirador"), "o motivo diz o ramo escolhido")

	# Melhoria: +15% de dano e 10% menos recarga.
	var hab := ArvoreData.no(&"arqueiro", &"tiro_carregado").habilidade
	var pontos := p.pontos_habilidade
	p.pedir_aprender(&"tiro_carregado")
	await get_tree().physics_frame
	checar(p.rank(&"tiro_carregado") == 2 and p.pontos_habilidade == pontos - 1, "melhorar o Tiro carregado gasta 1 ponto (nível %d)" % p.rank(&"tiro_carregado"))
	checar(is_equal_approx(p.recarga_de(hab), hab.recarga * 0.9) and is_equal_approx(p.mult_habilidade(hab), 1.15), "melhoria: recarga %.3f s (era %.2f) e dano x%.2f" % [p.recarga_de(hab), hab.recarga, p.mult_habilidade(hab)])

	# Passivas da classe (desde o nível 1): Mão leve e Olho de águia.
	checar(is_equal_approx(Passivas.carga_maxima(p), Player.CARGA_MAXIMA / 1.3), "Mão leve: o arco carrega em %.2f s (era %.2f)" % [Passivas.carga_maxima(p), Player.CARGA_MAXIMA])
	p.mira_forcada = p.global_position + Vector2(100, -10)
	await esperar(0.6)
	p.usar_habilidade_por_id(&"tiro_carregado", 0.0)
	await get_tree().physics_frame
	var flechas := get_tree().get_nodes_in_group(&"projeteis")
	checar(flechas.size() == 1 and is_equal_approx(flechas[0].duracao * flechas[0].velocidade, 0.7 * 200.0 * 1.2), "Olho de águia: a flecha vai 20%% mais longe (%.0f px)" % (flechas[0].duracao * flechas[0].velocidade if flechas.size() > 0 else 0.0))
	await esperar(1.0)


## Dano de um tiro rápido num slime parado a 120 px (vida alta para não morrer).
func _dano_tiro_longe(w: World, p: Player) -> float:
	var s: Slime = colocar(w, SLIME, p.global_position + Vector2(120, 0))
	s.set_physics_process(false)
	await get_tree().physics_frame
	s.vida.maximo = 100.0
	s.vida.atual = 100.0
	p.mira_forcada = s.global_position + Vector2(0, -6)
	await esperar(0.6)  # recarga do tiro
	p.usar_habilidade_por_id(&"tiro_carregado", 0.0)
	await esperar(1.0)
	var dano := 100.0 - s.vida.atual
	s.queue_free()
	await get_tree().physics_frame
	return dano


func _teclas_e_salvar(_w: World, p: Player) -> void:
	p.pedir_tecla(&"chuva_flechas", 0)
	await get_tree().physics_frame
	checar(p.ids_nas_teclas()[0] == &"chuva_flechas" and p.ids_nas_teclas()[2] == &"tiro_carregado", "trocar a tecla: Chuva vai para o Q e o Tiro vai para onde ela estava")
	var reg := p.registro()
	checar(reg.arvore.has("ponto_fraco") and reg.teclas[0] == "chuva_flechas", "o registro salvo guarda a árvore e as teclas")
	var json: Variant = JSON.parse_string(JSON.stringify(reg))  # como o arquivo do mundo
	p.arvore.clear()
	p.teclas.clear()
	p.restaurar(json)
	await get_tree().physics_frame
	checar(p.tem(&"ponto_fraco") and p.rank(&"tiro_carregado") == 2 and p.ids_nas_teclas()[0] == &"chuva_flechas", "restaurar devolve a árvore, as melhorias e as teclas")


func _tela(w: World, p: Player) -> void:
	var hud := w.hud
	var tela := hud.arvore()
	checar(not tela.aberta(), "a tela da árvore começa fechada")
	checar(hud._ficha_botao_arvore.text.contains("Árvore de habilidades") and not hud._rodape_ficha().contains("em breve"), "a ficha tem o botão da árvore (%s)" % hud._ficha_botao_arvore.text)
	var k := InputEventAction.new()
	k.action = &"arvore"
	k.pressed = true
	Input.parse_input_event(k)
	await get_tree().process_frame
	await get_tree().process_frame
	checar(tela.aberta() and p.menu_aberto, "K abre a árvore e o clique não vira golpe (menu aberto)")
	checar(tela.nos_mostrados().size() == ArvoreData.nos(&"arqueiro").size(), "a tela lista os %d nós do Arqueiro" % tela.nos_mostrados().size())
	checar(tela.texto_pontos() == "Pontos: %d" % p.pontos_habilidade, "o contador mostra os pontos (%s)" % tela.texto_pontos())
	checar(tela.estado_de(&"ponto_fraco") == &"aprendido" and tela.estado_de(&"marca_do_cacador") == &"bloqueado" and tela.estado_de(&"flecha_perfurante") == &"disponivel",
		"estados: aprendido, bloqueado e disponível")
	tela.selecionar(&"flecha_perfurante")
	checar(not tela.botao_aprender().disabled, "nó disponível: o botão Aprender fica ligado")
	var pontos := p.pontos_habilidade
	tela.botao_aprender().pressed.emit()
	await get_tree().physics_frame
	checar(p.tem(&"flecha_perfurante") and p.pontos_habilidade == pontos - 1 and tela.texto_pontos() == "Pontos: %d" % p.pontos_habilidade, "o botão Aprender aprende e o contador acompanha")
	checar(not &"flecha_perfurante" in p.ids_nas_teclas(), "habilidade com efeito pendente não vai para as teclas")
	tela.selecionar(&"rede")
	checar(tela.botao_aprender().disabled, "nó de outro ramo: o botão fica desligado")
	Input.parse_input_event(k)
	await get_tree().process_frame
	await get_tree().process_frame
	checar(not tela.aberta() and not p.menu_aberto, "K de novo fecha a árvore")
	hud._ficha_botao_arvore.pressed.emit()
	await get_tree().process_frame
	checar(tela.aberta(), "o botão da ficha abre a árvore")
	tela.fechar()
