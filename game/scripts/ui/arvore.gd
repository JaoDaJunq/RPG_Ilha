class_name ArvoreTela
extends Control
## Tela da árvore de habilidades (K, ou o botão na ficha). Uma coluna para as passivas da
## classe, uma para as 5 iniciais e uma para cada ramo. Cada nó é um espaço com o ícone:
## redondo é passiva, quadrado é habilidade. Dourado = aprendido, verde = dá para aprender
## agora, apagado = bloqueado. Clicar num nó mostra os detalhes ao lado, com o botão
## Aprender (um PEDIDO ao anfitrião, que confere tudo de novo).

const TAM := 64  # lado de um espaço (o quadradinho e a bolinha do pacote têm 64 px)
const LARGURA_COLUNA := 118
const LARGURA_DETALHES := 300
const COR_APRENDIDO := Tema.COR_DESTAQUE
const COR_DISPONIVEL := Color("7ed36a")
const COR_BLOQUEADO := Color(0.55, 0.55, 0.6)
## Caminhos entre os nós: dourado (os dois aprendidos), verde (o de cima aprendido e o de
## baixo dá para aprender) e cinza apagado (bloqueado). Contorno escuro, como o resto da
## interface do pacote.
const COR_LINHA_APAGADA := Color(0.42, 0.42, 0.46)
const COR_CONTORNO_LINHA := Color(0.09, 0.09, 0.13, 0.9)
const LARGURA_LINHA := 4.0
## Vão entre um passo do ramo e o seguinte (o caminho passa nele).
const SEPARACAO_PASSOS := 16
## Pistas dos caminhos que saem das iniciais para a entrada de cada ramo: uma por ramo,
## no corredor ao lado das iniciais e na faixa em cima da primeira fileira.
const PISTA := 8
const TECLAS_NOMES: Array[String] = ["Q", "R", "T", "E"]

var jogador: Player
## O HUD diz se a mochila também está aberta (para o menu_aberto do jogador ficar certo).
var outro_menu_aberto: Callable

var _classe_montada: StringName = &""
var _selecionado: StringName = &""
var _espacos: Dictionary = {}  # id → {fundo, icone, borda, canto, nome}
var _titulo: Label
var _pontos: Label
var _fechar: Button
var _dica_ramo: Label
var _colunas: HBoxContainer
var _ligacoes: Control
var _corredor: Control  # vão entre as iniciais e o primeiro ramo (pistas verticais)
var _faixas: Dictionary = {}  # ramo → faixa em cima da 1ª fileira (pistas horizontais)
var _legenda: RichTextLabel
var _det_icone: TextureRect
var _det_nome: Label
var _det_tipo: Label
var _det_estado: Label
var _det_descricao: Label
var _det_extra: Label
var _det_pendente: Label
var _botao_aprender: Button
var _linha_teclas: HBoxContainer
var _botoes_tecla: Array[Button] = []
var _teclas_atuais: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP  # aberta, o clique não vira golpe no mundo
	visible = false
	_montar()


func configurar(p: Player, outro: Callable = Callable()) -> void:
	jogador = p
	outro_menu_aberto = outro
	p.progresso_mudou.connect(_atualizar)
	# Aberta, o jogador não esquiva nem lança habilidades.
	visibility_changed.connect(func() -> void:
		p.menu_aberto = visible or (outro_menu_aberto.is_valid() and outro_menu_aberto.call()))


func aberta() -> bool:
	return visible


func alternar() -> void:
	if visible:
		fechar()
	else:
		abrir()


func abrir() -> void:
	if jogador == null or jogador.ficha == null:
		return
	get_parent().move_child(self, -1)  # por cima do resto do HUD
	visible = true
	_atualizar()


func fechar() -> void:
	visible = false


## Ids dos nós mostrados na tela (para os testes).
func nos_mostrados() -> Array[StringName]:
	var l: Array[StringName] = []
	for id in _espacos:
		l.append(id)
	return l


## "aprendido", "disponivel" ou "bloqueado".
func estado_de(no_id: StringName) -> StringName:
	var n := ArvoreData.no(jogador.classe, no_id)
	if n == null:
		return &""
	if jogador.tem(no_id):
		return &"aprendido"
	return &"disponivel" if jogador.motivo_bloqueio(n) == "" else &"bloqueado"


func texto_pontos() -> String:
	return _pontos.text


func selecionar(no_id: StringName) -> void:
	_selecionado = no_id
	_atualizar()


func selecionado() -> StringName:
	return _selecionado


func botao_aprender() -> Button:
	return _botao_aprender


## Caminhos desenhados agora (para os testes): [{de, para, estado, pontos}], com o estado
## "aprendido", "disponivel" ou "bloqueado" (dourado, verde ou cinza).
func caminhos() -> Array[Dictionary]:
	return _calcular_caminhos()


## Estado do caminho de `de` até `para` (&"" se esse caminho não existe).
func estado_caminho(de: StringName, para: StringName) -> StringName:
	for c in _calcular_caminhos():
		if c.de == de and c.para == para:
			return c.estado
	return &""


static func cor_caminho(estado: StringName) -> Color:
	match estado:
		&"aprendido":
			return COR_APRENDIDO
		&"disponivel":
			return COR_DISPONIVEL
	return COR_LINHA_APAGADA


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		fechar()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if visible:
		_ligacoes.queue_redraw()  # as posições só assentam depois do layout


# --- Montagem -------------------------------------------------------------------------

func _montar() -> void:
	var escuro := ColorRect.new()
	escuro.color = Color(0.05, 0.05, 0.08, 0.6)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(escuro)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override(&"panel", Tema.painel())
	centro.add_child(painel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 6)
	painel.add_child(v)

	# Cabeçalho: título, os pontos (bem grandes) e o Fechar.
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override(&"separation", 16)
	v.add_child(topo)
	_titulo = _rotulo("", 24)
	_titulo.theme_type_variation = &"RotuloTitulo"
	topo.add_child(_titulo)
	var folga := Control.new()
	folga.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(folga)
	_pontos = _rotulo("", 30, COR_APRENDIDO)
	_pontos.theme_type_variation = &"RotuloTitulo"
	topo.add_child(_pontos)
	_fechar = Button.new()
	_fechar.pressed.connect(fechar)
	topo.add_child(_fechar)

	var corpo := HBoxContainer.new()
	corpo.add_theme_constant_override(&"separation", 16)
	v.add_child(corpo)
	var area := Control.new()
	corpo.add_child(area)
	_ligacoes = Control.new()
	_ligacoes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ligacoes.draw.connect(_desenhar_ligacoes)
	area.add_child(_ligacoes)
	_colunas = HBoxContainer.new()
	_colunas.add_theme_constant_override(&"separation", 6)
	area.add_child(_colunas)
	_colunas.resized.connect(func() -> void:
		area.custom_minimum_size = _colunas.size
		_ligacoes.size = _colunas.size
		_ligacoes.queue_redraw())
	_colunas.sort_children.connect(_ligacoes.queue_redraw)

	corpo.add_child(_montar_detalhes())


func _montar_detalhes() -> Control:
	var caixa := PanelContainer.new()
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.09, 0.09, 0.13, 0.55)
	fundo.set_corner_radius_all(6)
	fundo.set_content_margin_all(12)
	caixa.add_theme_stylebox_override(&"panel", fundo)
	caixa.custom_minimum_size = Vector2(LARGURA_DETALHES, 0)
	var d := VBoxContainer.new()
	d.add_theme_constant_override(&"separation", 8)
	caixa.add_child(d)
	_dica_ramo = _rotulo("", 14, Tema.COR_TEXTO_2)
	_dica_ramo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dica_ramo.custom_minimum_size = Vector2(LARGURA_DETALHES - 24, 0)
	d.add_child(_dica_ramo)
	d.add_child(HSeparator.new())
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override(&"separation", 10)
	d.add_child(cab)
	_det_icone = TextureRect.new()
	_det_icone.custom_minimum_size = Vector2(52, 52)
	_det_icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_det_icone.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_det_icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cab.add_child(_det_icone)
	var nomes := VBoxContainer.new()
	nomes.add_theme_constant_override(&"separation", 0)
	cab.add_child(nomes)
	_det_nome = _rotulo("", 20, COR_APRENDIDO)
	nomes.add_child(_det_nome)
	_det_tipo = _rotulo("", 14, Tema.COR_TEXTO_2)
	nomes.add_child(_det_tipo)
	_det_estado = _rotulo("", 16)
	_det_descricao = _rotulo("", 16)
	_det_extra = _rotulo("", 14, Tema.COR_TEXTO_2)
	_det_pendente = _rotulo("", 14, Tema.COR_AVISO)
	for l in [_det_estado, _det_descricao, _det_extra, _det_pendente]:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(LARGURA_DETALHES - 24, 0)
		d.add_child(l)
	_botao_aprender = Button.new()
	_botao_aprender.theme_type_variation = &"BotaoPequeno"
	_botao_aprender.custom_minimum_size = Vector2(0, 44)
	_botao_aprender.pressed.connect(func() -> void:
		if jogador and _selecionado != &"":
			jogador.pedir_aprender(_selecionado))
	d.add_child(_botao_aprender)
	_linha_teclas = HBoxContainer.new()
	_linha_teclas.add_theme_constant_override(&"separation", 6)
	d.add_child(_linha_teclas)
	_linha_teclas.add_child(_rotulo("Pôr na tecla:", 14, Tema.COR_TEXTO_2))
	for k in TECLAS_NOMES.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(40, 32)
		b.pressed.connect(func() -> void:
			if jogador and _selecionado != &"":
				jogador.pedir_tecla(_selecionado, k))
		_linha_teclas.add_child(b)
		_botoes_tecla.append(b)
	var folga := Control.new()
	folga.size_flags_vertical = Control.SIZE_EXPAND_FILL
	d.add_child(folga)
	# Legenda curta no pé dos detalhes (a árvore precisa da altura toda).
	_legenda = RichTextLabel.new()
	_legenda.bbcode_enabled = true
	_legenda.fit_content = true
	_legenda.scroll_active = false
	_legenda.custom_minimum_size = Vector2(LARGURA_DETALHES - 24, 0)
	_legenda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_legenda.add_theme_font_size_override(&"normal_font_size", 13)
	_legenda.add_theme_color_override(&"default_color", Tema.COR_TEXTO_2)
	_legenda.text = "[color=#%s]Dourado: aprendido[/color] · Cinza: bloqueado\n[color=#%s]Verde: dá para aprender agora[/color]\nRedondo: passiva · Quadrado: habilidade\n[color=#%s]![/color] efeito ainda pendente" % [
		COR_APRENDIDO.to_html(false), COR_DISPONIVEL.to_html(false), Tema.COR_AVISO.to_html(false)]
	d.add_child(_legenda)
	d.add_child(HSeparator.new())
	_teclas_atuais = _rotulo("", 14, Tema.COR_TEXTO_2)
	_teclas_atuais.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_teclas_atuais.custom_minimum_size = Vector2(LARGURA_DETALHES - 24, 0)
	d.add_child(_teclas_atuais)
	return caixa


## Uma coluna por ramo (e as duas da classe). Refeita quando a classe muda.
func _montar_colunas() -> void:
	for c in _colunas.get_children():
		c.free()
	_espacos.clear()
	_faixas.clear()
	_classe_montada = jogador.classe
	var ramos := ArvoreData.ramos(jogador.classe)
	var ordem: Array[StringName] = [NoArvore.RAMO_CLASSE, NoArvore.RAMO_INICIAIS]
	for r in ramos:
		ordem.append(r[0])
	# Faixa em cima da 1ª fileira, com uma pista por ramo (em todas as colunas, para as
	# fileiras ficarem alinhadas).
	var altura_faixa := PISTA * ramos.size() + 6
	for ramo in ordem:
		var col := VBoxContainer.new()
		col.add_theme_constant_override(&"separation", 0)
		col.custom_minimum_size = Vector2(LARGURA_COLUNA, 0)
		var cab := _rotulo(ArvoreData.nome_ramo(jogador.classe, ramo), 16)
		cab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cab.set_meta(&"ramo", ramo)
		col.add_child(cab)
		_faixas[ramo] = _vao(altura_faixa)
		col.add_child(_faixas[ramo])
		var primeiro := true
		for n in ArvoreData.nos(jogador.classe):
			if n.ramo == ramo:
				if not primeiro:
					col.add_child(_vao(SEPARACAO_PASSOS))  # o caminho entre os passos passa aqui
				col.add_child(_espaco_do_no(n))
				primeiro = false
		_colunas.add_child(col)
		if ramo == NoArvore.RAMO_INICIAIS:
			_corredor = Control.new()
			_corredor.custom_minimum_size = Vector2(PISTA * ramos.size() + 4, 0)
			_corredor.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_colunas.add_child(_corredor)
	if _selecionado == &"" or ArvoreData.no(jogador.classe, _selecionado) == null:
		_selecionado = ArvoreData.nos(jogador.classe)[0].id


func _espaco_do_no(n: NoArvore) -> Control:
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override(&"separation", 0)
	var linha := CenterContainer.new()
	caixa.add_child(linha)
	var fundo := Panel.new()
	fundo.custom_minimum_size = Vector2(TAM, TAM)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	fundo.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	fundo.tooltip_text = n.nome
	fundo.add_theme_stylebox_override(&"panel", _fundo_espaco(n.ativa()))
	fundo.gui_input.connect(func(evento: InputEvent) -> void:
		var b := evento as InputEventMouseButton
		if b and b.pressed and b.button_index == MOUSE_BUTTON_LEFT:
			fundo.accept_event()
			if b.double_click and jogador.motivo_bloqueio(n) == "":
				jogador.pedir_aprender(n.id)
			selecionar(n.id))
	linha.add_child(fundo)
	var icone := TextureRect.new()
	icone.texture = n.icone
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED  # tamanho real: pixel nítido
	icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icone.position = Vector2(8, 8)
	icone.size = Vector2(TAM - 16, TAM - 16)
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.add_child(icone)
	var borda := Panel.new()
	borda.position = Vector2(-3, -3)
	borda.size = Vector2(TAM + 6, TAM + 6)
	borda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.add_child(borda)
	var canto := _rotulo("", 13)
	canto.position = Vector2(TAM - 34, TAM - 20)
	canto.size = Vector2(32, 18)
	canto.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fundo.add_child(canto)
	if n.pendente:
		var aviso := _rotulo("!", 18, Tema.COR_AVISO)
		aviso.position = Vector2(TAM - 14, -2)
		fundo.add_child(aviso)
	var nome := _rotulo(n.nome, 13)
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.custom_minimum_size = Vector2(LARGURA_COLUNA, 0)
	nome.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nome.clip_text = true
	caixa.add_child(nome)
	_espacos[n.id] = {fundo = fundo, icone = icone, borda = borda, canto = canto, nome = nome, no = n}
	return caixa


func _fundo_espaco(quadrado: bool) -> StyleBoxTexture:
	if quadrado:
		return Tema.espaco()
	var s := StyleBoxTexture.new()
	s.texture = load(Tema.PASTA + "Buttons/TinyRoundBlueButton.png")
	return s


func _borda(cor: Color, largura: int, redonda: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.draw_center = false
	s.border_color = cor
	s.set_border_width_all(largura)
	s.set_corner_radius_all(int((TAM + 6) / 2.0) if redonda else 8)
	s.anti_aliasing = true
	return s


# --- Atualização ----------------------------------------------------------------------

func _atualizar() -> void:
	if jogador == null or jogador.ficha == null:
		return
	if _classe_montada != jogador.classe:
		_montar_colunas()
	_titulo.text = "Árvore de habilidades · %s" % jogador.ficha.classe.nome
	_pontos.text = "Pontos: %d" % jogador.pontos_habilidade
	_fechar.text = "Fechar (%s)" % Configuracoes.tecla_de(&"arvore")
	var escolhido := jogador.ramo_escolhido()
	if escolhido != &"":
		_dica_ramo.text = "Nível %d · Ramo escolhido: %s. Pontos que sobram melhoram habilidades (até 3 vezes)." % [jogador.nivel, ArvoreData.nome_ramo(jogador.classe, escolhido)]
	else:
		_dica_ramo.text = "Nível %d · Níveis 2 a 4: libere as iniciais. No nível 5, escolha UM ramo. Clique num nó para ver os detalhes." % jogador.nivel
	for col in _colunas.get_children():
		if col == _corredor:
			continue
		var cab := col.get_child(0) as Label
		var ramo: StringName = cab.get_meta(&"ramo")
		var outro_ramo := escolhido != &"" and ramo != escolhido and ramo != NoArvore.RAMO_CLASSE and ramo != NoArvore.RAMO_INICIAIS
		cab.add_theme_color_override(&"font_color", COR_APRENDIDO if ramo == escolhido else (COR_BLOQUEADO if outro_ramo else Tema.COR_TEXTO))
	for id in _espacos:
		_pintar(_espacos[id])
	_mostrar_detalhes()
	_ligacoes.queue_redraw()


func _pintar(e: Dictionary) -> void:
	var n: NoArvore = e.no
	var r := jogador.rank(n.id)
	var estado := estado_de(n.id)
	var redonda := not n.ativa()
	var cor: Color = COR_APRENDIDO if estado == &"aprendido" else (COR_DISPONIVEL if estado == &"disponivel" else Color(0, 0, 0, 0))
	var b := _borda(cor, 3, redonda)
	if n.id == _selecionado:
		b.border_color = Color.WHITE if estado == &"bloqueado" else cor.lightened(0.35)
		b.set_border_width_all(5)
	e.borda.add_theme_stylebox_override(&"panel", b)
	var apagado := estado == &"bloqueado"
	e.fundo.self_modulate = Color(0.45, 0.45, 0.5) if apagado else Color.WHITE
	e.icone.modulate = Color(0.4, 0.4, 0.45, 0.85) if apagado else Color.WHITE
	e.nome.add_theme_color_override(&"font_color", Tema.COR_TEXTO if not apagado else COR_BLOQUEADO)
	if r > 0 and n.rank_maximo() > 1:
		e.canto.text = "%d/%d" % [r - 1, NoArvore.MELHORIAS] if r > 1 else ""
	elif r == 0 and jogador.nivel < n.nivel:
		e.canto.text = "Nv %d" % n.nivel
	else:
		e.canto.text = ""


func _mostrar_detalhes() -> void:
	var n := ArvoreData.no(jogador.classe, _selecionado)
	if n == null:
		return
	var r := jogador.rank(n.id)
	_det_icone.texture = n.icone
	_det_nome.text = n.nome
	var tipo := "Habilidade" if n.ativa() else "Passiva"
	_det_tipo.text = "%s · %s · nível %d" % [tipo, ArvoreData.nome_ramo(jogador.classe, n.ramo), n.nivel]
	var motivo := jogador.motivo_bloqueio(n)
	if r > 0:
		_det_estado.text = "Aprendido" + (" (vem com a classe)" if n.padrao else "")
		_det_estado.add_theme_color_override(&"font_color", COR_APRENDIDO)
	elif motivo == "":
		_det_estado.text = "Dá para aprender agora."
		_det_estado.add_theme_color_override(&"font_color", COR_DISPONIVEL)
	else:
		_det_estado.text = motivo
		_det_estado.add_theme_color_override(&"font_color", Tema.COR_AVISO)
	_det_descricao.text = n.descricao
	var extras: Array[String] = []
	if n.padrao:
		extras.append("Custo: nenhum (vem com a classe)")
	elif r == 0:
		extras.append("Custo: %d ponto" % n.custo)
	if n.usavel():
		extras.append("Melhorias: %d de %d (cada uma: +15%% de dano e 10%% menos recarga; custa 1 ponto)" % [maxi(0, r - 1), NoArvore.MELHORIAS])
	if not n.algum_de.is_empty():
		var nomes: Array[String] = []
		for id in n.algum_de:
			nomes.append(ArvoreData.no(jogador.classe, id).nome)
		extras.append("Abre com: " + " ou ".join(nomes))
	_det_extra.text = "\n".join(extras)
	_det_pendente.text = n.texto_estado_efeito()
	_det_pendente.visible = _det_pendente.text != ""
	# Botão: aprender, melhorar ou só dizer que já tem.
	if r == 0:
		_botao_aprender.text = "Aprender (1 ponto)" if n.custo > 0 else "Aprender"
	elif r < n.rank_maximo():
		_botao_aprender.text = "Melhorar (1 ponto)"
	else:
		_botao_aprender.text = "Aprendido"
	_botao_aprender.disabled = motivo != ""
	_botao_aprender.tooltip_text = motivo
	# Teclas: só para habilidade aprendida que já funciona.
	var nas_teclas := jogador.ids_nas_teclas()
	_linha_teclas.visible = n.usavel() and r > 0
	for k in _botoes_tecla.size():
		var b := _botoes_tecla[k]
		b.text = Configuracoes.tecla_de(StringName("habilidade_%d" % (k + 1)))
		b.disabled = k > nas_teclas.size() or (k == nas_teclas.size() and n.id in nas_teclas)
		b.modulate = COR_APRENDIDO if k < nas_teclas.size() and nas_teclas[k] == n.id else Color.WHITE
	var partes: Array[String] = []
	for k in TECLAS_NOMES.size():
		var tecla := Configuracoes.tecla_de(StringName("habilidade_%d" % (k + 1)))
		var nome := "—"
		if k < nas_teclas.size():
			var h := ArvoreData.no(jogador.classe, nas_teclas[k])
			nome = h.nome if h else "—"
		partes.append("%s %s" % [tecla, nome])
	_teclas_atuais.text = "Nas teclas: " + " · ".join(partes)


func _vao(altura: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, altura)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## Os caminhos: cada passo do ramo liga ao anterior (reto, do pé do nome até a borda de cima
## do nó), e a entrada de cada ramo liga às iniciais que o abrem, pelo corredor ao lado das
## iniciais e pela faixa em cima da 1ª fileira (uma pista por ramo).
func _calcular_caminhos() -> Array[Dictionary]:
	var l: Array[Dictionary] = []
	if jogador == null or _espacos.is_empty() or _corredor == null:
		return l
	var inverso := _ligacoes.get_global_transform().affine_inverse()
	var ramos := ArvoreData.ramos(jogador.classe)
	var corredor: Rect2 = inverso * _corredor.get_global_rect()
	for id in _espacos:
		var n: NoArvore = _espacos[id].no
		var para: Rect2 = inverso * (_espacos[id].fundo as Control).get_global_rect()
		var topo := Vector2(para.get_center().x, para.position.y - 3.0)  # a borda sai 3 px
		for req in n.requisitos:
			if not _espacos.has(req):
				continue
			var nome: Label = _espacos[req].nome
			var embaixo: float = (inverso * nome.get_global_rect()).end.y - 2.0
			l.append(_caminho(req, id, PackedVector2Array([Vector2(topo.x, embaixo), topo])))
		if n.algum_de.is_empty():
			continue
		var k := 0
		for r in ramos.size():
			if ramos[r][0] == n.ramo:
				k = r
		# O ramo mais perto fica com a pista mais à direita no corredor e a mais baixa na
		# faixa: assim os caminhos não se cruzam na faixa.
		var x_pista := corredor.end.x - 4.0 - PISTA * k
		var faixa: Rect2 = inverso * (_faixas[n.ramo] as Control).get_global_rect()
		var y_pista := faixa.end.y - 6.0 - PISTA * k
		for ini in n.algum_de:
			if not _espacos.has(ini):
				continue
			var de: Rect2 = inverso * (_espacos[ini].fundo as Control).get_global_rect()
			var saida := Vector2(de.end.x + 3.0, de.get_center().y)
			l.append(_caminho(ini, id, PackedVector2Array([
				saida, Vector2(x_pista, saida.y), Vector2(x_pista, y_pista),
				Vector2(topo.x, y_pista), topo])))
	return l


func _caminho(de: StringName, para: StringName, pontos: PackedVector2Array) -> Dictionary:
	var estado := &"bloqueado"
	if jogador.tem(de) and jogador.tem(para):
		estado = &"aprendido"
	elif jogador.tem(de) and estado_de(para) == &"disponivel":
		estado = &"disponivel"
	return {de = de, para = para, estado = estado, pontos = pontos}


## Linhas de interface (não é arte do jogo): trechos retos com contorno escuro; os cinzas
## primeiro e os dourados por cima, porque as pistas dividem trechos.
func _desenhar_ligacoes() -> void:
	var todos := _calcular_caminhos()
	for camada: StringName in [&"bloqueado", &"disponivel", &"aprendido"]:
		var desses := todos.filter(func(c: Dictionary) -> bool: return c.estado == camada)
		for c in desses:
			_tracar(c.pontos, LARGURA_LINHA + 4.0, COR_CONTORNO_LINHA)
		for c in desses:
			_tracar(c.pontos, LARGURA_LINHA, cor_caminho(camada))


## Trechos retos (horizontais ou verticais) com pontas quadradas, para as curvas fecharem
## sem falha.
func _tracar(pontos: PackedVector2Array, largura: float, cor: Color) -> void:
	for i in pontos.size() - 1:
		var r := Rect2(pontos[i].round(), Vector2.ZERO).expand(pontos[i + 1].round()).grow(largura / 2.0)
		_ligacoes.draw_rect(r, cor)


func _rotulo(texto: String, tamanho: int, cor := Tema.COR_TEXTO) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override(&"font_size", tamanho)
	l.add_theme_color_override(&"font_color", cor)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
