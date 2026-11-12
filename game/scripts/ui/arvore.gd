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
const COR_LINHA_APAGADA := Color(0.32, 0.3, 0.28, 0.9)
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
		_ligacoes.size = _colunas.size)

	corpo.add_child(_montar_detalhes())

	var legenda := RichTextLabel.new()
	legenda.bbcode_enabled = true
	legenda.fit_content = true
	legenda.scroll_active = false
	legenda.autowrap_mode = TextServer.AUTOWRAP_OFF
	legenda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	legenda.add_theme_font_size_override(&"normal_font_size", 14)
	legenda.add_theme_color_override(&"default_color", Tema.COR_TEXTO_2)
	legenda.text = "[color=#%s]Dourado: aprendido[/color]   [color=#%s]Verde: dá para aprender[/color]   Apagado: bloqueado   ·   Redondo: passiva   Quadrado: habilidade   ·   [color=#%s]![/color] efeito ainda pendente" % [
		COR_APRENDIDO.to_html(false), COR_DISPONIVEL.to_html(false), Tema.COR_AVISO.to_html(false)]
	v.add_child(legenda)


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
	_classe_montada = jogador.classe
	var ordem: Array[StringName] = [NoArvore.RAMO_CLASSE, NoArvore.RAMO_INICIAIS]
	for r in ArvoreData.ramos(jogador.classe):
		ordem.append(r[0])
	for ramo in ordem:
		var col := VBoxContainer.new()
		col.add_theme_constant_override(&"separation", 10)  # espaço para a linha entre os passos
		col.custom_minimum_size = Vector2(LARGURA_COLUNA, 0)
		var cab := _rotulo(ArvoreData.nome_ramo(jogador.classe, ramo), 16)
		cab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cab.set_meta(&"ramo", ramo)
		col.add_child(cab)
		for n in ArvoreData.nos(jogador.classe):
			if n.ramo == ramo:
				col.add_child(_espaco_do_no(n))
		_colunas.add_child(col)
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


## Linhas entre um passo do ramo e o seguinte (interface, não arte do jogo).
func _desenhar_ligacoes() -> void:
	if jogador == null:
		return
	var inverso := _ligacoes.get_global_transform().affine_inverse()
	for id in _espacos:
		var n: NoArvore = _espacos[id].no
		for req in n.requisitos:
			if not _espacos.has(req):
				continue
			var de: Rect2 = _espacos[req].fundo.get_global_rect()
			var para: Rect2 = _espacos[id].fundo.get_global_rect()
			var embaixo: float = _espacos[req].nome.get_global_rect().end.y  # depois do nome
			var a := inverso * Vector2(de.get_center().x, embaixo)
			var b := inverso * Vector2(para.get_center().x, para.position.y - 2.0)
			var cor := COR_LINHA_APAGADA
			if jogador.tem(id):
				cor = COR_APRENDIDO
			elif jogador.tem(req):
				cor = COR_DISPONIVEL if estado_de(id) == &"disponivel" else Color(0.6, 0.58, 0.5)
			_ligacoes.draw_line(a, b, cor, 4.0)


func _rotulo(texto: String, tamanho: int, cor := Tema.COR_TEXTO) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override(&"font_size", tamanho)
	l.add_theme_color_override(&"font_color", cor)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
