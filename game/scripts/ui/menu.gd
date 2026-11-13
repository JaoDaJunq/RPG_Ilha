extends Node
## Home do jogo: a ilha viva ao fundo, o título numa fita e os botões do pacote.
## Caminho: Home → Jogar → (Sozinho | Multijogador → Hospedar | Entrar) → mundos → criar mundo.
## Raça e classe não se escolhem aqui: isso é depois de entrar no mundo.

const MUNDO := "res://scenes/world/world.tscn"
const LARGURA_BOTAO := 380.0

var _cenario: World
var _camera: Camera2D
var _raiz: Control
var _conteudo: Control
var _tela: Control
var _voltar := Callable()
var _campo_ip: LineEdit
var _aviso: Label


func _ready() -> void:
	# Atalho de teste: --solo, --hospedar ou --entrar=IP pulam o menu.
	if Net.modo_pela_linha_de_comando():
		_ir_para_o_mundo.call_deferred()
		return
	_montar_cenario()
	_montar_interface()
	Sfx.tocar_musica()
	# Caiu a conexão com o anfitrião: volta direto para a tela de entrar, com o motivo.
	if Net.ultimo_erro != "" and Net.modo == Net.Modo.ENTRAR:
		_tela_entrar()
	else:
		_tela_inicio()
		if Net.ultimo_erro != "":
			_dizer(Net.ultimo_erro)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and _voltar.is_valid():
		get_viewport().set_input_as_handled()
		_voltar.call()


# --- Fundo vivo -----------------------------------------------------------------------

## A ilha de verdade (só o cenário, de dia) e uma câmera que passeia devagar por ela.
func _montar_cenario() -> void:
	_cenario = (load(MUNDO) as PackedScene).instantiate()
	_cenario.somente_cenario = true
	_cenario.slimes = 0
	add_child(_cenario)
	_camera = Camera2D.new()
	_camera.zoom = Vector2(3, 3)
	add_child(_camera)
	_camera.make_current()
	# Do Bosque Florido (árvores rosas) até o acampamento e de volta, devagar.
	var a := Vector2(GeradorIlha.SEMENTES[Regioes.Id.BOSQUE][0] * World.T) + Vector2(-60, 0)
	var b := _cenario.centro + Vector2(30, 20)
	_camera.position = a
	var t := create_tween().set_loops()
	t.tween_property(_camera, "position", b, 40.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_camera, "position", a, 40.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _montar_interface() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 5
	add_child(camada)
	_raiz = Control.new()
	_raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.theme = Tema.tema()
	camada.add_child(_raiz)
	# Escurece as bordas, para o título e os botões aparecerem sobre qualquer pedaço da ilha.
	var degrade := Gradient.new()
	degrade.set_color(0, Color(0.02, 0.05, 0.1, 0.22))
	degrade.set_color(1, Color(0.02, 0.05, 0.1, 0.7))
	degrade.set_offset(0, 0.3)
	var textura := GradientTexture2D.new()
	textura.gradient = degrade
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(1.0, 0.85)
	textura.width = 256
	textura.height = 256
	var vinheta := TextureRect.new()
	vinheta.texture = textura
	vinheta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vinheta.stretch_mode = TextureRect.STRETCH_SCALE
	vinheta.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vinheta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(vinheta)
	_conteudo = Control.new()
	_conteudo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(_conteudo)
	var rodape := Pecas.rotulo("Ilha Viva · protótipo", 15, Tema.COR_TEXTO_2)
	rodape.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 14)
	rodape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(rodape)
	var credito := Pecas.rotulo("Arte: Tiny Swords, de Pixel Frog", 15, Tema.COR_TEXTO_2)
	credito.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 14)
	credito.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(credito)


# --- Estrutura das telas --------------------------------------------------------------

## Troca a tela atual por uma nova (centralizada, aparece de mansinho). `voltar` é o que o Esc faz.
func _mostrar(voltar: Callable, no: Control = null) -> Control:
	if _tela:
		_tela.queue_free()
		_conteudo.remove_child(_tela)
	if no == null:
		var c := CenterContainer.new()
		c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		no = c
	_tela = no
	_voltar = voltar
	_aviso = null
	_conteudo.add_child(_tela)
	_tela.modulate.a = 0.0
	_tela.create_tween().tween_property(_tela, "modulate:a", 1.0, 0.18)
	return _tela


## Fita com o título e, embaixo, um painel (devolve a coluna do painel).
func _cartao(titulo: String, largura: float, voltar: Callable) -> VBoxContainer:
	var c := _mostrar(voltar)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override(&"separation", -14)
	c.add_child(coluna)
	var fita := Pecas.fita(titulo)
	fita.z_index = 1  # a fita fica por cima da borda do painel
	fita.custom_minimum_size.x = maxf(420.0, largura * 0.8)
	fita.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	coluna.add_child(fita)
	var painel := Pecas.painel(largura)
	coluna.add_child(painel)
	var p := Pecas.coluna_de(painel)
	var topo := Control.new()  # respiro: a fita cobre a borda de cima do painel
	topo.custom_minimum_size.y = 8
	p.add_child(topo)
	return p


## Botão grande com uma frase embaixo.
func _opcao(coluna: Container, texto: String, frase: String, acao: Callable, variacao := &"BotaoGrande") -> Button:
	var b := Pecas.botao(texto, variacao, 0.0)
	b.pressed.connect(acao)
	coluna.add_child(b)
	if frase != "":
		var l := Pecas.rotulo(frase, 16, Tema.COR_TEXTO_2, true)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		coluna.add_child(l)
	return b


func _dizer(texto: String) -> void:
	if _aviso == null:
		_aviso = Pecas.rotulo("", 18, Tema.COR_AVISO, true)
		_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_aviso.add_theme_constant_override(&"outline_size", 4)
		_aviso.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 56)
		_aviso.custom_minimum_size.x = 700
		_aviso.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_aviso.grow_vertical = Control.GROW_DIRECTION_BEGIN
		_tela.add_child(_aviso)
	_aviso.text = texto


# --- Home -----------------------------------------------------------------------------

func _tela_inicio() -> void:
	var c := _mostrar(Callable())
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override(&"separation", 14)
	c.add_child(coluna)
	var titulo := Pecas.fita("Ilha Viva", 2, 1.0, 84)
	titulo.custom_minimum_size.x = 640
	titulo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	coluna.add_child(titulo)
	var sub := Pecas.rotulo("Sobrevivência e exploração em co-op", 24, Tema.COR_TEXTO, true)
	sub.add_theme_constant_override(&"outline_size", 6)
	coluna.add_child(sub)
	var folga := Control.new()
	folga.custom_minimum_size.y = 26
	coluna.add_child(folga)
	var botoes := VBoxContainer.new()
	botoes.add_theme_constant_override(&"separation", 18)
	botoes.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	coluna.add_child(botoes)
	var jogar := Pecas.botao("Jogar", &"BotaoGrande", LARGURA_BOTAO)
	jogar.pressed.connect(_tela_jogar)
	botoes.add_child(jogar)
	var config := Pecas.botao("Configurações", &"BotaoGrande", LARGURA_BOTAO)
	config.pressed.connect(_tela_configuracoes)
	botoes.add_child(config)
	var sair := Pecas.botao("Sair", &"BotaoVermelho", LARGURA_BOTAO)
	sair.pressed.connect(func() -> void: get_tree().quit())
	botoes.add_child(sair)
	jogar.grab_focus()


# --- Jogar ----------------------------------------------------------------------------

func _tela_jogar() -> void:
	var p := _cartao("Jogar", 520, _tela_inicio)
	var primeiro := _opcao(p, "Sozinho", "Só você na ilha. O jogo salva sozinho.", _escolher_modo.bind(Net.Modo.SOLO))
	_opcao(p, "Multijogador", "Jogue com até 3 amigos, pela rede.", _tela_multijogador)
	var voltar := Pecas.botao("Voltar", &"BotaoPequeno", 160)
	voltar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	voltar.pressed.connect(_tela_inicio)
	p.add_child(voltar)
	primeiro.grab_focus()


func _tela_multijogador() -> void:
	var p := _cartao("Multijogador", 520, _tela_jogar)
	var primeiro := _opcao(p, "Hospedar", "Criar ou abrir um mundo e chamar os amigos.", _escolher_modo.bind(Net.Modo.HOSPEDAR))
	_opcao(p, "Entrar no jogo de um amigo", "Você só precisa do IP de quem está hospedando.", _tela_entrar)
	var voltar := Pecas.botao("Voltar", &"BotaoPequeno", 160)
	voltar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	voltar.pressed.connect(_tela_jogar)
	p.add_child(voltar)
	primeiro.grab_focus()


func _escolher_modo(modo: Net.Modo) -> void:
	Net.modo = modo
	_tela_mundos()


func _tela_entrar() -> void:
	Net.modo = Net.Modo.ENTRAR
	var p := _cartao("Entrar no jogo de um amigo", 560, _tela_multijogador)
	p.add_child(Pecas.rotulo("IP de quem está hospedando", 18, Tema.COR_TEXTO_2, true))
	_campo_ip = LineEdit.new()
	_campo_ip.custom_minimum_size = Vector2(0, 50)
	_campo_ip.placeholder_text = "ex.: 192.168.0.10"
	_campo_ip.text = Net.endereco
	_campo_ip.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_campo_ip.add_theme_font_size_override(&"font_size", 24)
	_campo_ip.text_submitted.connect(func(_t: String) -> void: _entrar())
	p.add_child(_campo_ip)
	var ips := Net.enderecos_locais()
	p.add_child(Pecas.rotulo("Seu IP nesta rede: " + (", ".join(ips) if not ips.is_empty() else "não encontrado"), 16, Tema.COR_TEXTO_2, true))
	var entrar := Pecas.botao("Entrar", &"BotaoGrande", 360.0)
	entrar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	entrar.pressed.connect(_entrar)
	p.add_child(entrar)
	var voltar := Pecas.botao("Voltar", &"BotaoPequeno", 160)
	voltar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	voltar.pressed.connect(_tela_multijogador)
	p.add_child(voltar)
	if Net.ultimo_erro != "":
		_dizer(Net.ultimo_erro)
		Net.ultimo_erro = ""
	_campo_ip.grab_focus()
	_campo_ip.caret_column = _campo_ip.text.length()


func _entrar() -> void:
	var ip := _campo_ip.text.strip_edges()
	if not ip.is_valid_ip_address():
		_dizer("Digite o IP de quem está hospedando (ex.: 192.168.0.10).")
		return
	Net.modo = Net.Modo.ENTRAR
	Net.endereco = ip
	Net.mundo_arquivo = ""
	_ir_para_o_mundo()


# --- Mundos ---------------------------------------------------------------------------

func _tela_mundos() -> void:
	var titulo := "Hospedar um mundo" if Net.modo == Net.Modo.HOSPEDAR else "Seus mundos"
	var voltar_para := _tela_multijogador if Net.modo == Net.Modo.HOSPEDAR else _tela_jogar
	var p := _cartao(titulo, 720, voltar_para)
	if Net.modo == Net.Modo.HOSPEDAR:
		var ips := Net.enderecos_locais()
		p.add_child(Pecas.rotulo("Seus amigos entram pelo IP: " + (", ".join(ips) if not ips.is_empty() else "não encontrado"), 17, Tema.COR_TEXTO_2, true))
	var mundos := Salvamento.listar()
	var rolagem := ScrollContainer.new()
	rolagem.custom_minimum_size = Vector2(0, 300)
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(rolagem)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override(&"separation", 8)
	rolagem.add_child(lista)
	if mundos.is_empty():
		lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var vazio := Pecas.rotulo("Você ainda não tem nenhum mundo.\nCrie o primeiro e comece a explorar!", 22, Tema.COR_TEXTO_2, true)
		vazio.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vazio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lista.add_child(vazio)
	for m in mundos:
		lista.add_child(_linha_do_mundo(m))
	var rodape := HBoxContainer.new()
	rodape.add_theme_constant_override(&"separation", 14)
	rodape.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(rodape)
	var novo := Pecas.botao("Criar mundo novo", &"BotaoGrande", 340)
	novo.pressed.connect(_tela_criar)
	rodape.add_child(novo)
	var voltar := Pecas.botao("Voltar", &"BotaoPequeno", 150)
	voltar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	voltar.pressed.connect(voltar_para)
	rodape.add_child(voltar)
	# O primeiro mundo da lista já vem pronto para jogar; sem mundos, o foco vai para "criar".
	if not mundos.is_empty():
		_primeiro_botao(lista.get_child(0)).grab_focus()
	else:
		novo.grab_focus()


func _primeiro_botao(no: Node) -> Button:
	for c in no.find_children("*", "Button", true, false):
		return c as Button
	return null


func _linha_do_mundo(m: Dictionary) -> PanelContainer:
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override(&"panel", Tema.papel_claro())
	var h := HBoxContainer.new()
	h.add_theme_constant_override(&"separation", 10)
	painel.add_child(h)
	var info := VBoxContainer.new()
	info.add_theme_constant_override(&"separation", 0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(info)
	var nome := Pecas.tinta(String(m.nome), 24, true)
	nome.clip_text = true
	nome.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info.add_child(nome)
	var detalhes := HBoxContainer.new()
	detalhes.add_theme_constant_override(&"separation", 6)
	info.add_child(detalhes)
	var dif: int = m.dificuldade
	var cor_dif: Color = [Tema.COR_FACIL, Tema.COR_NORMAL, Tema.COR_DIFICIL][dif]
	var rotulo_dif := Pecas.tinta(String(Salvamento.DIFICULDADES[dif].nome), 17, true)
	rotulo_dif.add_theme_color_override(&"font_color", cor_dif)
	detalhes.add_child(rotulo_dif)
	var resto := " ·  jogado " + Salvamento.texto_data(int(m.salvo_em))
	if int(m.nivel) > 0:
		resto += "  ·  nível %d" % int(m.nivel)
	detalhes.add_child(Pecas.tinta(resto, 17))
	var jogar := Pecas.botao("Jogar", &"BotaoPequeno", 120)
	jogar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	jogar.pressed.connect(_jogar_mundo.bind(String(m.caminho), String(m.nome), dif))
	h.add_child(jogar)
	var apagar := Pecas.botao("Apagar", &"BotaoPequenoVermelho", 120)
	apagar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	apagar.pressed.connect(_apagar_mundo.bind(apagar, String(m.caminho)))
	h.add_child(apagar)
	return painel


## Dois cliques para não apagar sem querer (o segundo tem 3 segundos para acontecer).
func _apagar_mundo(botao: Button, caminho: String) -> void:
	if botao.text != "Apagar":
		Salvamento.apagar(caminho)
		_tela_mundos()
		return
	botao.text = "Certeza?"
	get_tree().create_timer(3.0).timeout.connect(func() -> void:
		if is_instance_valid(botao) and botao.text != "Apagar":
			botao.text = "Apagar")


func _jogar_mundo(caminho: String, nome: String, dificuldade: int) -> void:
	Net.mundo_arquivo = caminho
	Net.mundo_nome = nome
	Net.mundo_dificuldade = dificuldade
	_ir_para_o_mundo()


# --- Criar mundo ----------------------------------------------------------------------

func _tela_criar() -> void:
	var p := _cartao("Criar mundo novo", 620, _tela_mundos)
	p.add_child(Pecas.rotulo("Nome do mundo", 18, Tema.COR_TEXTO_2, true))
	var campo := LineEdit.new()
	campo.custom_minimum_size = Vector2(0, 50)
	campo.max_length = 28
	campo.alignment = HORIZONTAL_ALIGNMENT_CENTER
	campo.add_theme_font_size_override(&"font_size", 24)
	campo.text = _nome_livre("Meu mundo")
	p.add_child(campo)
	var sep := Control.new()
	sep.custom_minimum_size.y = 4
	p.add_child(sep)
	p.add_child(Pecas.rotulo("Dificuldade", 18, Tema.COR_TEXTO_2, true))
	var grupo := ButtonGroup.new()
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override(&"separation", 10)
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(linha)
	var descricao := Pecas.rotulo("", 18, Tema.COR_TEXTO, true)
	descricao.custom_minimum_size.y = 52
	descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	descricao.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var escolhida := [Net.mundo_dificuldade if Net.mundo_dificuldade in [0, 1, 2] else 1]
	for i in Salvamento.DIFICULDADES.size():
		var b := Pecas.botao(String(Salvamento.DIFICULDADES[i].nome), &"BotaoPequeno", 150)
		b.toggle_mode = true
		b.button_group = grupo
		b.button_pressed = i == escolhida[0]
		b.pressed.connect(func() -> void:
			escolhida[0] = i
			descricao.text = String(Salvamento.DIFICULDADES[i].descricao))
		linha.add_child(b)
	descricao.text = String(Salvamento.DIFICULDADES[escolhida[0]].descricao)
	p.add_child(descricao)
	var criar := Pecas.botao("Criar mundo", &"BotaoGrande", 360.0)
	criar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	criar.pressed.connect(func() -> void: _criar_mundo(campo.text, escolhida[0]))
	campo.text_submitted.connect(func(_t: String) -> void: _criar_mundo(campo.text, escolhida[0]))
	p.add_child(criar)
	var voltar := Pecas.botao("Voltar", &"BotaoPequeno", 160)
	voltar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	voltar.pressed.connect(_tela_mundos)
	p.add_child(voltar)
	campo.grab_focus()
	campo.select_all()


func _nome_livre(base: String) -> String:
	var existentes: Array[String] = []
	for m in Salvamento.listar():
		existentes.append(String(m.nome).to_lower())
	var nome := base
	var n := 2
	while nome.to_lower() in existentes:
		nome = "%s %d" % [base, n]
		n += 1
	return nome


func _criar_mundo(nome: String, dificuldade: int) -> void:
	nome = nome.strip_edges()
	if nome == "":
		_dizer("Dê um nome ao seu mundo.")
		return
	var caminho := Salvamento.criar_mundo(nome, dificuldade)
	if caminho == "":
		_dizer("Não deu para criar o mundo (não consegui gravar o arquivo).")
		return
	_jogar_mundo(caminho, nome, dificuldade)


# --- Configurações --------------------------------------------------------------------

func _tela_configuracoes() -> void:
	var tela := TelaConfiguracoes.new()
	tela.fechar.connect(_tela_inicio)
	_mostrar(_tela_inicio, tela)
	tela.focar()


# --- Entrar no mundo ------------------------------------------------------------------

func _ir_para_o_mundo() -> void:
	get_tree().change_scene_to_file(MUNDO)
