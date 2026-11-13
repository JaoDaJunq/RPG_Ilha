extends TesteBase
## O mapa (M): mostra a ilha com as regiões, o que não foi visto fica escondido e vai
## aparecendo ao andar, mostra os jogadores e o acampamento, e o que foi visto fica salvo.

const ARQUIVO := "user://teste_mapa.save"


func _ready() -> void:
	Salvamento.apagar(ARQUIVO)
	var w := await criar_mundo()
	w.arquivo_salvo = ARQUIVO
	var p := w.jogador
	await esperar(0.6)
	checar(w.revelado(_cel_mapa(p.global_position)), "em volta do jogador já aparece no mapa")
	var praia := Vector2(GeradorIlha.SEMENTES[Regioes.Id.PRAIA][0] * World.T)
	checar(not w.revelado(_cel_mapa(praia)), "a Praia (longe) ainda está escondida")
	var antes := w.fracao_revelada()
	checar(antes > 0.0 and antes < 0.1, "só um pedacinho foi visto (%.1f%%)" % (antes * 100.0))

	# Abre com M.
	var ev := InputEventAction.new()
	ev.action = &"mapa"
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	await get_tree().process_frame
	var m := w.hud.mapa()
	checar(m.visible, "M abre o mapa")
	checar(m._fogueira.visible, "o acampamento aparece no mapa")
	checar(m._jogadores.has(p) and m._jogadores[p].visible, "o jogador aparece no mapa")
	var icone: TextureRect = m._jogadores[p]
	var esperado := p.global_position * Mapa.ESCALA
	checar((icone.position + icone.size / 2.0).distance_to(esperado) < 12.0, "no lugar certo do mapa")
	var rotulos := {}
	for r in m._rotulos:
		rotulos[(r[0] as Label).text] = (r[0] as Label).visible
	checar(rotulos.size() == 6, "o mapa tem o nome das 6 regiões")
	checar(rotulos.get("Clareira", false) and not rotulos.get("Praia das Conchas", true), "só aparece o nome das regiões já vistas")

	# Andar revela.
	p.global_position = praia
	await esperar(0.6)
	checar(w.revelado(_cel_mapa(praia)), "foi até a Praia: ela aparece no mapa")
	checar(w.fracao_revelada() > antes, "o mapa revelado cresceu (%.1f%%)" % (w.fracao_revelada() * 100.0))
	await get_tree().process_frame
	rotulos.clear()
	for r in m._rotulos:
		rotulos[(r[0] as Label).text] = (r[0] as Label).visible
	checar(rotulos.get("Praia das Conchas", false), "e o nome da Praia aparece")
	Input.parse_input_event(ev)
	await get_tree().process_frame
	checar(not m.visible, "M de novo fecha")

	# Salva e carrega: o que foi visto continua visto.
	var visto := w.mapa_revelado.duplicate()
	checar(w.salvar(), "salvou o mundo")
	w.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	Net.pular_criacao = true
	var w2: World = MUNDO.instantiate()
	w2.arquivo_salvo = ARQUIVO
	w2.gerar_recursos = false
	add_child(w2)
	await get_tree().physics_frame
	checar(w2.revelado(_cel_mapa(praia)), "carregado: a Praia continua no mapa")
	var iguais := 0
	for i in visto.size():
		if visto[i] != 0 and w2.mapa_revelado[i] != 0:
			iguais += 1
	checar(iguais == visto.count(1), "tudo o que foi visto voltou (%d células)" % iguais)
	w2.queue_free()
	await get_tree().process_frame
	Salvamento.apagar(ARQUIVO)

	# Mundo salvo da ilha antiga (outra semente): começa uma ilha nova, com aviso.
	Salvamento.gravar({"semente": 22117, "noite": true, "nome": "Velho", "dificuldade": 1, "jogadores": {}}, ARQUIVO)
	var w3: World = MUNDO.instantiate()
	w3.arquivo_salvo = ARQUIVO
	w3.gerar_recursos = false
	add_child(w3)
	await get_tree().physics_frame
	await get_tree().process_frame
	checar(not w3.noite and w3.fracao_revelada() < 0.05, "o mundo da ilha antiga começa de novo")
	checar(w3.hud.texto_aviso().contains("ilha antiga"), "e avisa o jogador (\"%s\")" % w3.hud.texto_aviso())
	w3.queue_free()
	await get_tree().process_frame
	Salvamento.apagar(ARQUIVO)
	terminar()


func _cel_mapa(pos: Vector2) -> Vector2i:
	return Vector2i((pos / (World.T * World.MAPA_BLOCO)).floor())
