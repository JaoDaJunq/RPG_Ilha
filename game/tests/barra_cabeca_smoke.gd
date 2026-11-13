extends TesteBase
## Nível e barra de vida em cima da cabeça (slime, slime da noite e animais), a janelinha das
## habilidades (botão direito) e o Shift sem dash com a mochila aberta.

const SLIME := preload("res://scenes/enemies/slime.tscn")
const ANIMAL := preload("res://scenes/animals/animal.tscn")


func _ready() -> void:
	var w := await criar_mundo(0, true, &"mago")
	var p := w.jogador
	await _barras(w, p)
	await _mochila_sem_dash(w, p)
	await _descricao(w, p)
	terminar()


# --- Nível e barra de vida -----------------------------------------------------------

func _barras(w: World, p: Player) -> void:
	var s: Slime = colocar(w, SLIME, p.global_position + Vector2(60, 0))
	var n: Slime = SLIME.instantiate()
	n.noturno = true
	n.position = p.global_position + Vector2(60, 40)
	w.entidades.add_child(n, true)
	await esperar(0.1)
	checar(s.barra.texto_nivel() == "1", "slime é nível 1 (%s)" % s.barra.texto_nivel())
	checar(n.barra.texto_nivel() == "3", "slime da noite é nível 3 (%s)" % n.barra.texto_nivel())
	checar(not s.barra.barra_visivel(), "a barra de vida fica escondida antes do dano")
	checar(s.barra.altura > 8.0 and s.barra.altura < 40.0, "a barra fica na altura da cabeça do slime (%.0f px)" % s.barra.altura)
	checar(is_equal_approx(s.barra.tempo_visivel, 4.0), "a barra fica 4 s depois do último golpe")

	s.hurtbox.receber(1.0, &"fisico", p)
	await esperar(0.1)
	checar(s.barra.barra_visivel(), "depois do golpe a barra aparece")
	checar(absf(s.barra._barra.value - (1.0 - 1.0 / s.vida.maximo) * 100.0) < 0.5, "a barra mostra a vida que sobrou (%.0f%%)" % s.barra._barra.value)
	await esperar(1.0)
	checar(s.barra.barra_visivel(), "1 s depois a barra ainda está lá")
	# Encurta o tempo para o teste não esperar 4 s: outro golpe reinicia a contagem.
	s.barra.tempo_visivel = 0.3
	s.barra.sumir_em = 0.2
	s.hurtbox.receber(1.0, &"fisico", p)
	await esperar(0.1)
	checar(s.barra.barra_visivel(), "outro golpe mantém a barra")
	await esperar(0.6)
	checar(not s.barra.barra_visivel(), "sem golpes, a barra some de novo")
	checar(s.barra.texto_nivel() == "1", "o nível continua à vista")

	# Animais: nível por espécie; barra só depois do dano.
	var esperado := {&"galinha": "1", &"coelho": "1", &"ovelha": "1", &"javali": "2"}
	var bichos := {}
	var k := 0
	for e in esperado:
		var a: Animal = ANIMAL.instantiate()
		a.especie = e
		a.position = p.global_position + Vector2(-40, -60 + k * 30)
		w.entidades.add_child(a, true)
		bichos[e] = a
		k += 1
	await esperar(0.1)
	for e in esperado:
		var a: Animal = bichos[e]
		checar(a.barra.texto_nivel() == esperado[e], "%s é nível %s (%s)" % [e, esperado[e], a.barra.texto_nivel()])
		checar(not a.barra.barra_visivel() and a.barra.altura > 6.0, "%s: barra escondida e na altura da cabeça (%.0f px)" % [e, a.barra.altura])
	var j: Animal = bichos[&"javali"]
	j.hurtbox.receber(1.0, &"fisico", p)
	await esperar(0.1)
	checar(j.barra.barra_visivel() and absf(j.barra._barra.value - 100.0 * 6.0 / 7.0) < 0.5, "o javali mostra a barra depois de apanhar (%.0f%%)" % j.barra._barra.value)
	checar(not bichos[&"coelho"].barra.barra_visivel(), "quem não apanhou continua sem barra")
	for a in bichos.values():
		a.queue_free()
	s.queue_free()
	n.queue_free()


# --- Shift e Q R T E com a mochila aberta ---------------------------------------------

func _mochila_sem_dash(w: World, p: Player) -> void:
	p.mira_forcada = p.global_position + Vector2(100, 0)
	p.inventario.definir([])
	p.inventario.adicionar(&"madeira", 5)  # espaço 0 da barra
	await esperar(0.1)
	w.hud._mochila.abrir(&"mochila")
	checar(p.menu_aberto, "com a mochila aberta o jogador sabe que há menu aberto")
	_apertar(&"esquivar")
	_apertar(&"habilidade_1")
	await esperar(0.1)
	checar(p.recarga_esquiva_restante() == 0.0 and not p.vida.protegido(), "Shift com a mochila aberta não dá dash")
	checar(p.recarga_restante(0) == 0.0 and p.mana >= p.ficha.mana_maxima() - 1.0, "Q com a mochila aberta não lança habilidade")
	# O Shift + clique continua mandando a pilha para o outro lado (barra -> mochila).
	p.inventario.pedir_clique(0, false, true)
	checar(p.inventario.item_em(0) == &"" and p.inventario.quantidade_de(&"madeira") == 5, "Shift + clique manda a pilha da barra para a mochila")
	w.hud._mochila.fechar()
	checar(not p.menu_aberto, "fechada a mochila, o jogador volta ao normal")
	_apertar(&"esquivar")
	await esperar(0.1)
	# Bola de fogo conjura (design/conjuracao.md): segura até o verde e solta.
	_apertar(&"habilidade_1")
	await esperar(0.5)
	var solta := InputEventAction.new()
	solta.action = &"habilidade_1"
	solta.pressed = false
	Input.parse_input_event(solta)
	await esperar(0.1)
	checar(p.recarga_esquiva_restante() > 0.0, "fechada a mochila, o Shift volta a dar dash")
	checar(p.recarga_restante(0) > 0.0, "e a habilidade volta a sair")


func _apertar(acao: StringName) -> void:
	var ev := InputEventAction.new()
	ev.action = acao
	ev.pressed = true
	Input.parse_input_event(ev)


# --- Janelinha das habilidades ---------------------------------------------------------

func _descricao(w: World, p: Player) -> void:
	await esperar(0.2)
	var hud := w.hud
	checar(hud.descricao_aberta() == "", "a janelinha começa fechada")
	var hab := p.habilidades()
	var slot: Control = hud._slots[0].fundo
	checar(slot.mouse_filter == Control.MOUSE_FILTER_STOP and hud._slot_esquiva.fundo.mouse_filter == Control.MOUSE_FILTER_STOP,
		"os botões de habilidade e do dash recebem o mouse (o clique não vira ação no mundo)")
	_clicar_direito(slot)
	checar(hud.descricao_aberta().contains(hab[0].nome), "botão direito na habilidade abre a janelinha com o nome (%s)" % hud.descricao_aberta())
	for _i in 5:
		await get_tree().process_frame
	var texto: String = hud._dica_numeros.text
	checar(texto.contains("Mana: 6") and texto.contains("Recarga: 0,6 s") and texto.contains("Dano:"), "mostra mana, recarga e dano (%s)" % texto.replace("\n", " | "))
	checar(hud._dica_efeitos.text.contains("dobro"), "mostra os efeitos (%s)" % hud._dica_efeitos.text.replace("\n", " | "))
	var caixa: Rect2 = hud._dica.get_global_rect()
	checar(hud._dica.modulate.a == 1.0 and caixa.end.y <= slot.get_global_rect().position.y and Rect2(Vector2.ZERO, hud._raiz.size).encloses(caixa),
		"a janelinha fica em cima do botão e dentro da tela")
	_clicar_direito(slot)
	checar(hud.descricao_aberta() == "", "outro clique direito no mesmo botão fecha")
	_clicar_direito(hud._slot_esquiva.fundo)
	checar(hud.descricao_aberta().contains("Dash"), "botão direito no Shift mostra o dash (%s)" % hud.descricao_aberta())
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	hud._unhandled_input(esc)
	checar(hud.descricao_aberta() == "", "Esc fecha a janelinha")
	hud.mostrar_descricao(1)
	hud._slots[1].fundo.mouse_exited.emit()
	checar(hud.descricao_aberta() == "", "o mouse saindo do botão fecha")
	hud.mostrar_descricao(1)
	var esquerdo := InputEventMouseButton.new()
	esquerdo.button_index = MOUSE_BUTTON_LEFT
	esquerdo.pressed = true
	esquerdo.position = Vector2(5, 5)
	hud._input(esquerdo)
	checar(hud.descricao_aberta() == "", "um clique fora fecha")

	# Todas as habilidades do jogo têm texto, números e efeitos.
	var vazias: Array[String] = []
	var dir := DirAccess.open("res://data/habilidades")
	for arquivo in dir.get_files():
		if not arquivo.ends_with(".tres"):
			continue
		var h := load("res://data/habilidades/" + arquivo) as HabilidadeData
		var d := TextoHabilidade.de_habilidade(h, "Q", p.ficha)
		if h.descricao == "" or d.efeitos.is_empty() or str(d).contains("nan"):
			vazias.append(h.id)
		if h.dano > 0.0 and d.dano == "":
			vazias.append(h.id + " (sem dano)")
	checar(vazias.is_empty(), "as 20 habilidades têm descrição, números e efeitos (faltam: %s)" % ", ".join(vazias))


func _clicar_direito(fundo: Control) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_RIGHT
	ev.pressed = true
	ev.position = fundo.get_global_rect().get_center()
	fundo.gui_input.emit(ev)
