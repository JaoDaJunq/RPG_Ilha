class_name TelaConfiguracoes
extends Control
## Tela de configurações (Home e menu de pausa): trocar as teclas, volume e tela cheia.
## Tudo vale na hora e fica gravado em user://configuracoes.cfg (ver autoload Configuracoes).
## Para trocar uma tecla: clicar nela e apertar a nova (Esc cancela, Delete limpa).

signal fechar

var _abas: Array[Button] = []
var _conteudo: VBoxContainer
var _aba := 0
var _botoes: Array[Dictionary] = []  # {entrada, espaco, botao}
var _ouvindo: Dictionary = {}  # a troca em andamento: {entrada, espaco}
var _sobreposicao: Control
var _sobreposicao_acao: Label
var _predefinicoes: Dictionary[String, Button] = {}
var _voltar: Button


func _ready() -> void:
	theme = Tema.tema()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override(&"separation", 2)
	centro.add_child(coluna)
	var fita := Pecas.fita("Configurações")
	fita.custom_minimum_size.x = 420
	fita.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	coluna.add_child(fita)
	var painel := Pecas.painel(760)
	coluna.add_child(painel)
	var p := Pecas.coluna_de(painel)
	var abas := HBoxContainer.new()
	abas.add_theme_constant_override(&"separation", 10)
	abas.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(abas)
	for i in 2:
		var b := Pecas.botao(["Controles", "Som e tela"][i], &"BotaoPequeno", 170)
		b.toggle_mode = true
		b.pressed.connect(_abrir_aba.bind(i))
		abas.add_child(b)
		_abas.append(b)
	_conteudo = VBoxContainer.new()
	_conteudo.add_theme_constant_override(&"separation", 10)
	_conteudo.custom_minimum_size.y = 440  # as duas abas têm o mesmo tamanho: o painel não pula
	p.add_child(_conteudo)
	_voltar = Pecas.botao("Voltar", &"BotaoPequeno", 200)
	_voltar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_voltar.pressed.connect(func() -> void: fechar.emit())
	p.add_child(_voltar)
	_montar_sobreposicao()
	Configuracoes.mudou.connect(_atualizar_botoes)
	_abrir_aba(0)


func _exit_tree() -> void:
	if Configuracoes.mudou.is_connected(_atualizar_botoes):
		Configuracoes.mudou.disconnect(_atualizar_botoes)


## Foca o primeiro botão (o teclado e o controle já começam funcionando).
func focar() -> void:
	_voltar.grab_focus()


func _abrir_aba(i: int) -> void:
	_aba = i
	for k in _abas.size():
		_abas[k].set_pressed_no_signal(k == i)
	for c in _conteudo.get_children():
		_conteudo.remove_child(c)
		c.queue_free()
	_botoes.clear()
	_predefinicoes.clear()
	if i == 0:
		_montar_controles()
	else:
		_montar_som_e_tela()


# --- Controles ----------------------------------------------------------------------

func _montar_controles() -> void:
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override(&"separation", 8)
	_conteudo.add_child(linha)
	var titulo := Pecas.rotulo("Andar com:", 18, Tema.COR_TEXTO_2)
	titulo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(titulo)
	for par in [["WASD", "wasd"], ["Setas", "setas"], ["WASD e setas", "ambos"]]:
		var b := Pecas.botao(par[0], &"BotaoPequeno", 130)
		b.toggle_mode = true
		b.pressed.connect(func() -> void: Configuracoes.predefinir_movimento(par[1]))
		linha.add_child(b)
		_predefinicoes[par[1]] = b
	var folga := Control.new()
	folga.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(folga)
	var restaurar := Pecas.botao("Restaurar tudo", &"BotaoPequenoVermelho", 150)
	restaurar.pressed.connect(func() -> void: Configuracoes.restaurar_padrao())
	linha.add_child(restaurar)

	var rolagem := ScrollContainer.new()
	rolagem.custom_minimum_size = Vector2(0, 310)
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_conteudo.add_child(rolagem)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override(&"separation", 6)
	rolagem.add_child(lista)
	var cab := HBoxContainer.new()
	var vazio := Control.new()
	vazio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(vazio)
	for texto in ["Tecla", "Outra tecla"]:
		var l := Pecas.rotulo(texto, 15, Tema.COR_TEXTO_2, true)
		l.custom_minimum_size.x = 150
		cab.add_child(l)
	lista.add_child(cab)
	for g in Configuracoes.GRUPOS:
		var gl := Pecas.rotulo(String(g.titulo).to_upper(), 15, Tema.COR_DESTAQUE)
		gl.add_theme_constant_override(&"outline_size", 3)
		lista.add_child(gl)
		for entrada in g.entradas:
			lista.add_child(_linha_de(entrada))
	var dica := Pecas.rotulo("Clique numa tecla e aperte a nova.  Esc cancela · Delete limpa.", 15, Tema.COR_TEXTO_2, true)
	_conteudo.add_child(dica)
	_atualizar_botoes()


func _linha_de(entrada: Dictionary) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override(&"separation", 6)
	var nome := Pecas.rotulo(entrada.nome, 18)
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nome.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(nome)
	for espaco in Configuracoes.ESPACOS:
		var b := Pecas.botao("", &"BotaoPequeno", 150)
		b.add_theme_font_size_override(&"font_size", 17)
		b.pressed.connect(comecar_troca.bind(entrada, espaco))
		h.add_child(b)
		_botoes.append({"entrada": entrada, "espaco": espaco, "botao": b})
	return h


## Escreve em cada botão a tecla de agora (em laranja se outra ação usa a mesma).
func _atualizar_botoes() -> void:
	for item in _botoes:
		var b: Button = item.botao
		if not is_instance_valid(b):
			continue
		var eventos: Array[InputEvent] = Configuracoes.eventos_de(item.entrada.acoes[0])
		var espaco: int = item.espaco
		if espaco >= eventos.size():
			b.text = "—"
			b.tooltip_text = ""
			b.remove_theme_color_override(&"font_color")
			continue
		b.text = Configuracoes.nome_do_evento(eventos[espaco])
		var iguais := Configuracoes.conflitos(item.entrada.acoes, eventos[espaco])
		if iguais.is_empty():
			b.remove_theme_color_override(&"font_color")
			b.tooltip_text = ""
		else:
			b.add_theme_color_override(&"font_color", Tema.COR_AVISO)
			b.tooltip_text = "Esta tecla também é usada em: " + ", ".join(iguais)
	var atual := Configuracoes.movimento_atual()
	for chave in _predefinicoes:
		_predefinicoes[chave].set_pressed_no_signal(chave == atual)


## Abre a janelinha "aperte a nova tecla" para o espaço (0 principal, 1 outra) da entrada.
func comecar_troca(entrada: Dictionary, espaco: int) -> void:
	_ouvindo = {"entrada": entrada, "espaco": espaco}
	_sobreposicao_acao.text = String(entrada.nome)
	_sobreposicao.visible = true


func esta_ouvindo() -> bool:
	return not _ouvindo.is_empty()


## Uma tecla ou botão de mouse chegou durante a troca. null limpa o espaço.
func aplicar_evento(evento: InputEvent) -> void:
	if _ouvindo.is_empty():
		return
	Configuracoes.religar(_ouvindo.entrada.acoes, _ouvindo.espaco, evento)
	cancelar_troca()


func cancelar_troca() -> void:
	_ouvindo = {}
	_sobreposicao.visible = false


func _input(event: InputEvent) -> void:
	if _ouvindo.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		var k := event as InputEventKey
		var codigo: int = k.physical_keycode if k.physical_keycode != 0 else k.keycode
		if codigo == KEY_ESCAPE:
			cancelar_troca()
		elif codigo == KEY_DELETE:
			aplicar_evento(null)
		else:
			var novo := InputEventKey.new()
			novo.physical_keycode = codigo as Key
			aplicar_evento(novo)
	elif event is InputEventMouseButton and event.pressed:
		var b := event as InputEventMouseButton
		if b.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_XBUTTON1, MOUSE_BUTTON_XBUTTON2]:
			get_viewport().set_input_as_handled()
			var novo := InputEventMouseButton.new()
			novo.button_index = b.button_index
			aplicar_evento(novo)


func _montar_sobreposicao() -> void:
	_sobreposicao = Control.new()
	_sobreposicao.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sobreposicao.visible = false
	_sobreposicao.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_sobreposicao)
	var escuro := ColorRect.new()
	escuro.color = Color(0.03, 0.04, 0.08, 0.72)
	escuro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sobreposicao.add_child(escuro)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sobreposicao.add_child(centro)
	var painel := Pecas.painel(460)
	centro.add_child(painel)
	var c := Pecas.coluna_de(painel)
	c.add_theme_constant_override(&"separation", 8)
	c.add_child(Pecas.rotulo("Aperte a nova tecla para", 20, Tema.COR_TEXTO_2, true))
	_sobreposicao_acao = Pecas.rotulo("", 32, Tema.COR_DESTAQUE, true)
	_sobreposicao_acao.add_theme_font_override(&"font", Tema.fonte_negrito())
	c.add_child(_sobreposicao_acao)
	c.add_child(Pecas.rotulo("(também vale um botão do mouse)", 16, Tema.COR_TEXTO_2, true))
	c.add_child(Pecas.rotulo("Esc cancela  ·  Delete limpa", 16, Tema.COR_TEXTO_2, true))


# --- Som e tela ---------------------------------------------------------------------

func _montar_som_e_tela() -> void:
	var espaco_topo := Control.new()
	espaco_topo.custom_minimum_size.y = 20
	_conteudo.add_child(espaco_topo)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override(&"separation", 14)
	_conteudo.add_child(linha)
	var nome := Pecas.rotulo("Volume", 24)
	nome.custom_minimum_size.x = 200
	linha.add_child(nome)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = roundi(Configuracoes.volume * 100.0)
	slider.custom_minimum_size = Vector2(340, 40)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_ALL
	linha.add_child(slider)
	var valor := Pecas.rotulo("%d%%" % slider.value, 24, Tema.COR_DESTAQUE)
	valor.custom_minimum_size.x = 70
	valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	linha.add_child(valor)
	slider.value_changed.connect(func(v: float) -> void:
		valor.text = "%d%%" % v
		Configuracoes.definir_volume(v / 100.0, false))
	slider.drag_ended.connect(func(_mudou: bool) -> void: Configuracoes.salvar())
	slider.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventKey and not e.pressed:  # setas do teclado também gravam
			Configuracoes.salvar())

	var linha2 := HBoxContainer.new()
	linha2.add_theme_constant_override(&"separation", 14)
	_conteudo.add_child(linha2)
	var nome2 := Pecas.rotulo("Tela cheia", 24)
	nome2.custom_minimum_size.x = 200
	linha2.add_child(nome2)
	var cheia := Pecas.botao("", &"BotaoPequeno", 160)
	cheia.toggle_mode = true
	cheia.set_pressed_no_signal(Configuracoes.tela_cheia)
	cheia.text = "Ligada" if Configuracoes.tela_cheia else "Desligada"
	cheia.pressed.connect(func() -> void:
		Configuracoes.definir_tela_cheia(cheia.button_pressed)
		cheia.text = "Ligada" if cheia.button_pressed else "Desligada")
	linha2.add_child(cheia)
	var folga := Control.new()
	folga.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_conteudo.add_child(folga)
	_conteudo.add_child(Pecas.rotulo("M liga e desliga o som no jogo.", 16, Tema.COR_TEXTO_2, true))
