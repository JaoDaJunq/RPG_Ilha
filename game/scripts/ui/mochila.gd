class_name Mochila
extends Control
## Tela da mochila (I ou Tab) e da bancada, como o inventário do Minecraft: grade de
## fabricação (2x2; 3x3 na bancada) com a seta e o resultado, os 27 espaços da mochila e
## a barra (1-9) embaixo. Clique esquerdo pega ou larga a pilha, clique direito pega metade
## ou põe 1, Shift + clique manda para o outro lado. Cada clique é um PEDIDO ao anfitrião
## (Inventory); a tela só mostra o que ele devolve.

const TAM := 52  # lado de um espaço na tela (os ícones têm até ~49 px, no tamanho real)
const SETA := "res://assets/sprites/tiny/icones/seta.png"
## Quanto o boneco (escala 0,25 no jogo) cresce na miniatura. Inteiro: pixel nítido.
const ESCALA_BONECO := 2.0

var jogador: Player
var _espacos: Array = []  # [índice no inventário, {fundo, icone, qtd}]
var _resultado: Dictionary
var _grade_2x2: GridContainer
var _grade_3x3: GridContainer
var _titulo: Label
var _fabricacao: HBoxContainer
var _caixa_personagem: Control
var _boneco: Boneco
var _grade_bau: GridContainer
var _cursor: Control
var _cursor_icone: TextureRect
var _cursor_qtd: Label
var _livro: PanelContainer
var _lista_receitas: GridContainer
var _filtro_receitas: CheckButton
var _detalhe_nome: Label
var _detalhe_ingredientes: HBoxContainer
var _detalhe_dica: Label
var _modo_atual: StringName = &"mochila"
var _botoes_receitas: Array[Dictionary] = []  # {botao (Panel), icone, marca, receita, pode}
var _receita_escolhida: StringName = &""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP  # aberta, o clique não vira golpe no mundo
	visible = false
	_montar()
	Events.abrir_mochila.connect(abrir)


func configurar(p: Player) -> void:
	jogador = p
	p.inventario.mudou.connect(_atualizar)
	p.aspecto_mudou.connect(_vestir_miniatura)
	_vestir_miniatura()
	# Aberta, o jogador não esquiva nem lança habilidades (o Shift é do Shift + clique).
	visibility_changed.connect(func() -> void: p.menu_aberto = visible)


func aberta() -> bool:
	return visible


func alternar() -> void:
	if visible:
		fechar()
	else:
		abrir(&"mochila")


## `modo`: &"mochila" (fabricação 2x2), &"bancada" (3x3) ou &"bau" (o baú em cima).
func abrir(modo: StringName) -> void:
	if jogador == null:
		return
	visible = true
	_modo_atual = modo
	_titulo.text = {&"mochila": "Mochila", &"bancada": "Bancada de trabalho", &"bau": "Baú"}.get(modo, "Mochila")
	_fabricacao.visible = modo != &"bau"
	_caixa_personagem.visible = modo == &"mochila"
	_vestir_miniatura()
	_grade_bau.visible = modo == &"bau"
	_grade_2x2.visible = modo == &"mochila"
	_grade_3x3.visible = modo == &"bancada"
	_atualizar()


func fechar() -> void:
	if not visible:
		return
	visible = false
	jogador.inventario.pedir_fechar()


func _process(_delta: float) -> void:
	if visible:
		_cursor.position = get_local_mouse_position() + Vector2(-TAM / 2.0, -TAM / 2.0)


# --- Montagem ----------------------------------------------------------------------

func _montar() -> void:
	var escuro := ColorRect.new()
	escuro.color = Color(0.05, 0.06, 0.1, 0.45)
	escuro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(escuro)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	# Como no Minecraft: o livro de receitas fica do lado de fora da janela, à esquerda.
	var lado_a_lado := HBoxContainer.new()
	lado_a_lado.add_theme_constant_override(&"separation", 10)
	centro.add_child(lado_a_lado)
	lado_a_lado.add_child(_montar_livro())
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override(&"panel", Tema.painel())
	lado_a_lado.add_child(painel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 8)
	painel.add_child(v)

	_titulo = _rotulo("Mochila", 20)
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_titulo)

	# Em cima: o bonequinho com as roupas (só na mochila) e a fabricação (grade, seta, resultado).
	var topo := HBoxContainer.new()
	topo.alignment = BoxContainer.ALIGNMENT_CENTER
	topo.add_theme_constant_override(&"separation", 40)
	v.add_child(topo)
	topo.add_child(_montar_personagem())
	var fab := HBoxContainer.new()
	_fabricacao = fab
	fab.alignment = BoxContainer.ALIGNMENT_CENTER
	fab.add_theme_constant_override(&"separation", 12)
	topo.add_child(fab)
	_grade_2x2 = _grade(2, Inventory.GRADE_2X2)
	fab.add_child(_grade_2x2)
	var nove: Array[int] = []
	for k in 9:
		nove.append(Inventory.GRADE + k)
	_grade_3x3 = _grade(3, nove)
	fab.add_child(_grade_3x3)
	var seta := TextureRect.new()
	seta.texture = load(SETA) if ResourceLoader.exists(SETA) else null
	seta.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	seta.custom_minimum_size = Vector2(44, TAM)
	seta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fab.add_child(seta)
	_resultado = _espaco(-1)
	_resultado.fundo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_resultado.fundo.custom_minimum_size = Vector2(TAM + 12, TAM + 12)
	fab.add_child(_resultado.fundo)

	# Baú (27), só quando um baú está aberto.
	var do_bau: Array[int] = []
	for k in Inventory.BAU_N:
		do_bau.append(Inventory.BAU + k)
	_grade_bau = _grade(9, do_bau)
	v.add_child(_grade_bau)
	var separador := HSeparator.new()
	separador.add_theme_constant_override(&"separation", 6)
	v.add_child(separador)
	# Mochila (27) e barra (9).
	var faixa: Array[int] = []
	for i in range(Inventory.BARRA, Inventory.GUARDAR):
		faixa.append(i)
	v.add_child(_grade(9, faixa))
	var barra: Array[int] = []
	for i in Inventory.BARRA:
		barra.append(i)
	var g := _grade(9, barra)
	v.add_child(g)
	var dica := _rotulo("Esquerdo: pega/larga · Direito: metade/1 · Shift: manda para o outro lado", 13)
	dica.add_theme_color_override(&"font_color", Tema.COR_TEXTO_2)
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(dica)

	# Item preso no mouse.
	_cursor = Control.new()
	_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor.size = Vector2(TAM, TAM)
	_cursor.z_index = 10
	add_child(_cursor)
	_cursor_icone = _icone()
	_cursor.add_child(_cursor_icone)
	_cursor_qtd = _qtd()
	_cursor.add_child(_cursor_qtd)


## O personagem em miniatura (como no Minecraft) e o espaço da roupa completa da classe.
## Tirar a roupa deixa o boneco com a roupinha branca. Chapéus e cabelos já fazem parte
## da arte completa do traje. O boneco cresce por um fator inteiro (escala 0,25 no jogo).
func _montar_personagem() -> Control:
	var h := HBoxContainer.new()
	_caixa_personagem = h
	h.add_theme_constant_override(&"separation", 10)
	var roupas := VBoxContainer.new()
	roupas.add_theme_constant_override(&"separation", 4)
	roupas.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(roupas)
	for par in [[Inventory.EQUIP_CORPO, "Roupa"]]:
		var e := _espaco(par[0])
		_espacos.append([par[0], e])
		e.fundo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		roupas.add_child(e.fundo)
		var nome := _rotulo(par[1], 14)
		nome.add_theme_color_override(&"font_color", Tema.COR_TEXTO_2)
		nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		roupas.add_child(nome)
	var quadro := Panel.new()
	quadro.custom_minimum_size = Vector2(150, 184)
	var caixa := StyleBoxFlat.new()
	caixa.bg_color = Tema.COR_FUNDO.darkened(0.35)
	caixa.border_color = Tema.COR_BORDA
	caixa.set_border_width_all(2)
	caixa.set_corner_radius_all(3)
	quadro.add_theme_stylebox_override(&"panel", caixa)
	quadro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(quadro)
	_boneco = Boneco.new()
	_boneco.scale = Vector2.ONE * ESCALA_BONECO
	_boneco.position = Vector2(75, 174)  # os pés
	_boneco.play(&"parado_baixo")
	quadro.add_child(_boneco)
	return h


## Veste o boneco da mochila com a aparência e as roupas atuais do jogador.
func _vestir_miniatura() -> void:
	if jogador != null and _boneco != null:
		_boneco.vestir(jogador.aparencia_completa(), jogador.equipado)


func _grade(colunas: int, indices: Array[int]) -> GridContainer:
	var g := GridContainer.new()
	g.columns = colunas
	g.add_theme_constant_override(&"h_separation", 4)
	g.add_theme_constant_override(&"v_separation", 4)
	g.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for i in indices:
		var e := _espaco(i)
		g.add_child(e.fundo)
		_espacos.append([i, e])
	return g


## Um espaço: fundo azul do pacote, ícone no tamanho real e a quantidade no canto.
func _espaco(indice: int) -> Dictionary:
	var fundo := Panel.new()
	fundo.add_theme_stylebox_override(&"panel", Tema.espaco())
	fundo.custom_minimum_size = Vector2(TAM, TAM)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	fundo.gui_input.connect(_clique.bind(indice))
	var icone := _icone()
	fundo.add_child(icone)
	var sombra := _icone()
	sombra.modulate = Color(0.12, 0.13, 0.17, 0.72)
	sombra.visible = false
	fundo.add_child(sombra)
	var qtd := _qtd()
	fundo.add_child(qtd)
	return {fundo = fundo, icone = icone, sombra = sombra, qtd = qtd}


func _icone() -> TextureRect:
	var t := TextureRect.new()
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED  # tamanho real: pixel nítido
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _qtd() -> Label:
	var l := _rotulo("", 14)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	l.offset_right = -3
	return l


func _rotulo(texto: String, tamanho: int) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override(&"font_size", tamanho)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# --- Cliques e atualização --------------------------------------------------------

func _clique(evento: InputEvent, indice: int) -> void:
	var b := evento as InputEventMouseButton
	if b == null or not b.pressed or not (b.button_index == MOUSE_BUTTON_LEFT or b.button_index == MOUSE_BUTTON_RIGHT):
		return
	accept_event()
	if indice < 0:
		jogador.inventario.pedir_resultado(b.shift_pressed)
	else:
		jogador.inventario.pedir_clique(indice, b.button_index == MOUSE_BUTTON_RIGHT, b.shift_pressed)


func _atualizar() -> void:
	if jogador == null:
		return
	var inv := jogador.inventario
	for par in _espacos:
		_mostrar(par[1], inv.item_em(par[0]), inv.qtd_em(par[0]))
		par[1].sombra.texture = _textura(inv.sombras_receita.get(par[0], &""))
		par[1].sombra.visible = inv.item_em(par[0]) == &"" and inv.sombras_receita.has(par[0])
		if par[1].sombra.visible and ItemData.existe(inv.sombras_receita[par[0]]):
			par[1].fundo.tooltip_text = "Falta: " + ItemData.carregar(inv.sombras_receita[par[0]]).nome
	var r := inv.receita_atual()
	_mostrar(_resultado, r.resultado if r else &"", r.quantidade if r else 0)
	_cursor_icone.texture = _textura(inv.item_em(Inventory.MAO))
	_cursor_qtd.text = str(inv.qtd_em(Inventory.MAO)) if inv.qtd_em(Inventory.MAO) > 1 else ""
	_atualizar_receitas()


func _mostrar(e: Dictionary, id: StringName, qtd: int) -> void:
	e.icone.texture = _textura(id)
	e.sombra.visible = false
	e.qtd.text = str(qtd) if qtd > 1 else ""
	e.fundo.tooltip_text = ItemData.carregar(id).nome if ItemData.existe(id) else ""


func _textura(id: StringName) -> Texture2D:
	return ItemData.carregar(id).icone if ItemData.existe(id) else null


# --- Livro de receitas (como o do Minecraft) -----------------------------------------
# Fica fora da janela, à esquerda. Cada receita é um quadradinho com o ícone do que ela
# faz. Clicar numa receita PEDE ao anfitrião para montar os ingredientes na grade: o
# resultado aparece pronto na saída e só falta clicar nele. O que falta fica como sombra.

const LIVRO_COLUNAS := 5
const COR_PODE := Color.WHITE
const COR_NAO_PODE := Color(0.42, 0.44, 0.5, 0.85)


func _montar_livro() -> PanelContainer:
	_livro = PanelContainer.new()
	_livro.add_theme_stylebox_override(&"panel", Tema.painel())
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 8)
	_livro.add_child(v)
	var titulo := _rotulo("Receitas", 20)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(titulo)
	_filtro_receitas = CheckButton.new()
	_filtro_receitas.text = "Só as que dá para fazer"
	_filtro_receitas.add_theme_font_size_override(&"font_size", 14)
	_filtro_receitas.toggled.connect(func(_ligado: bool) -> void: _atualizar_receitas())
	v.add_child(_filtro_receitas)
	var rolagem := ScrollContainer.new()
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rolagem.custom_minimum_size = Vector2(LIVRO_COLUNAS * (TAM + 4) + 8, 0)
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(rolagem)
	_lista_receitas = GridContainer.new()
	_lista_receitas.columns = LIVRO_COLUNAS
	_lista_receitas.add_theme_constant_override(&"h_separation", 4)
	_lista_receitas.add_theme_constant_override(&"v_separation", 4)
	rolagem.add_child(_lista_receitas)
	for receita in ReceitaData.todas():
		_lista_receitas.add_child(_quadro_receita(receita))
	v.add_child(HSeparator.new())
	# Embaixo: o nome e os ingredientes da receita apontada (ou escolhida).
	_detalhe_nome = _rotulo("", 16)
	_detalhe_nome.add_theme_color_override(&"font_color", Tema.COR_DESTAQUE)
	_detalhe_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_detalhe_nome)
	_detalhe_ingredientes = HBoxContainer.new()
	_detalhe_ingredientes.alignment = BoxContainer.ALIGNMENT_CENTER
	_detalhe_ingredientes.add_theme_constant_override(&"separation", 6)
	_detalhe_ingredientes.custom_minimum_size = Vector2(0, 40)
	v.add_child(_detalhe_ingredientes)
	_detalhe_dica = _rotulo("Clique numa receita para montar", 13)
	_detalhe_dica.add_theme_color_override(&"font_color", Tema.COR_TEXTO_2)
	_detalhe_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detalhe_dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detalhe_dica.custom_minimum_size = Vector2(LIVRO_COLUNAS * (TAM + 4), 0)
	v.add_child(_detalhe_dica)
	return _livro


func _quadro_receita(receita: ReceitaData) -> Panel:
	var fundo := Panel.new()
	fundo.add_theme_stylebox_override(&"panel", Tema.espaco())
	fundo.custom_minimum_size = Vector2(TAM, TAM)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	fundo.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var icone := _icone()
	icone.texture = _textura(receita.resultado)
	fundo.add_child(icone)
	if receita.quantidade > 1:
		var qtd := _qtd()
		qtd.text = str(receita.quantidade)
		fundo.add_child(qtd)
	# Moldura dourada da receita escolhida (só interface).
	var marca := Panel.new()
	var borda := StyleBoxFlat.new()
	borda.bg_color = Color(0, 0, 0, 0)
	borda.border_color = Tema.COR_DESTAQUE
	borda.set_border_width_all(3)
	borda.set_corner_radius_all(4)
	marca.add_theme_stylebox_override(&"panel", borda)
	marca.set_anchors_preset(Control.PRESET_FULL_RECT)
	marca.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marca.visible = false
	fundo.add_child(marca)
	var dados := {botao = fundo, icone = icone, marca = marca, receita = receita, pode = false}
	fundo.gui_input.connect(_clique_receita.bind(dados))
	fundo.mouse_entered.connect(_mostrar_detalhe.bind(receita))
	fundo.mouse_exited.connect(func() -> void: _mostrar_detalhe(_receita_por_resultado(_receita_escolhida)))
	_botoes_receitas.append(dados)
	return fundo


func _clique_receita(evento: InputEvent, dados: Dictionary) -> void:
	var b := evento as InputEventMouseButton
	if b == null or not b.pressed or b.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	_selecionar_receita(dados.receita.resultado)


## Quantos de cada item a receita usa.
func _necessarios(receita: ReceitaData) -> Dictionary[StringName, int]:
	var faltas: Dictionary[StringName, int] = {}
	if receita.sem_forma:
		for item in receita.ingredientes:
			faltas[item] = faltas.get(item, 0) + 1
	else:
		for linha in receita.padrao:
			for x in linha.length():
				if linha[x] != " ":
					var item: StringName = receita.chave.get(linha[x], &"")
					faltas[item] = faltas.get(item, 0) + 1
	return faltas


func _cabe_na_grade(receita: ReceitaData, lado: int) -> bool:
	if receita.sem_forma:
		return receita.ingredientes.size() <= lado * lado
	return not receita.padrao.is_empty() and receita.padrao.size() <= lado and receita.padrao[0].length() <= lado


## O que o jogador tem para fabricar: a mochila mais o que já está na grade.
func _itens_disponiveis() -> Dictionary[StringName, int]:
	var itens: Dictionary[StringName, int] = {}
	if jogador == null:
		return itens
	itens = jogador.inventario.itens()
	for k in 9:
		var id: StringName = jogador.inventario.item_em(Inventory.GRADE + k)
		if id != &"":
			itens[id] = itens.get(id, 0) + jogador.inventario.qtd_em(Inventory.GRADE + k)
	return itens


func _atualizar_receitas() -> void:
	if _lista_receitas == null or jogador == null:
		return
	_livro.visible = _modo_atual != &"bau"
	var lado: int = 3 if _modo_atual == &"bancada" else 2
	var itens := _itens_disponiveis()
	for dados in _botoes_receitas:
		var receita: ReceitaData = dados.receita
		var cabe := _cabe_na_grade(receita, lado)
		var pode := cabe
		var faltas := _necessarios(receita)
		for item in faltas:
			if itens.get(item, 0) < faltas[item]:
				pode = false
		dados.pode = pode
		dados.botao.modulate = COR_PODE if pode else COR_NAO_PODE
		dados.botao.visible = cabe and (not _filtro_receitas.button_pressed or pode)
		dados.marca.visible = receita.resultado == _receita_escolhida
		dados.botao.tooltip_text = _nome(receita.resultado)
	_mostrar_detalhe(_receita_por_resultado(_receita_escolhida))


func _mostrar_detalhe(receita: ReceitaData) -> void:
	if _detalhe_nome == null:
		return
	for filho in _detalhe_ingredientes.get_children():
		filho.queue_free()
	if receita == null:
		_detalhe_nome.text = ""
		_detalhe_dica.text = "Clique numa receita para montar"
		return
	_detalhe_nome.text = _nome(receita.resultado)
	if receita.quantidade > 1:
		_detalhe_nome.text += " x%d" % receita.quantidade
	var itens := _itens_disponiveis()
	var faltas := _necessarios(receita)
	var tudo := true
	for item in faltas:
		var caixa := HBoxContainer.new()
		caixa.add_theme_constant_override(&"separation", 2)
		var icone := TextureRect.new()
		icone.texture = _textura(item)
		icone.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icone.custom_minimum_size = Vector2(36, 36)
		icone.tooltip_text = _nome(item)
		caixa.add_child(icone)
		var tem: int = itens.get(item, 0)
		var conta := _rotulo("%d/%d" % [mini(tem, faltas[item]), faltas[item]], 14)
		conta.add_theme_color_override(&"font_color", Tema.COR_TEXTO if tem >= faltas[item] else Color("ff8a7a"))
		caixa.add_child(conta)
		_detalhe_ingredientes.add_child(caixa)
		tudo = tudo and tem >= faltas[item]
	var lado: int = 3 if _modo_atual == &"bancada" else 2
	if not _cabe_na_grade(receita, lado):
		_detalhe_dica.text = "Só na bancada de trabalho"
	elif tudo:
		_detalhe_dica.text = "Clique para montar e depois pegue o resultado"
	else:
		_detalhe_dica.text = "Faltam ingredientes (aparecem apagados na grade)"


func _receita_por_resultado(resultado: StringName) -> ReceitaData:
	if resultado == &"":
		return null
	for receita in ReceitaData.todas():
		if receita.resultado == resultado:
			return receita
	return null


func _nome(id: StringName) -> String:
	return ItemData.carregar(id).nome if ItemData.existe(id) else String(id)


func _selecionar_receita(resultado: StringName) -> void:
	if jogador == null:
		return
	_receita_escolhida = resultado
	jogador.inventario.pedir_receita(resultado)
	_atualizar_receitas()
