class_name Criacao
extends CanvasLayer
## Tela de criação do personagem, a primeira vez que o jogador entra num mundo.
## Passo 1: raça (Humano ou Ogro), rosto e pele. O bonequinho ao lado aparece "pelado" (só a
## roupinha branca) e muda na hora a cada escolha. Passo 2: a classe; o boneco veste as roupas
## base dela e pega a arma. "Entrar no mundo" manda a escolha ao anfitrião (Player).
## Tudo é local até confirmar: quem cria o personagem de verdade é o anfitrião.

## O jogador confirmou: raça, classe e aparência ({raca, rosto, pele}).
signal confirmado(raca: StringName, classe: StringName, aparencia: Dictionary)

const FUNDO := "res://assets/sprites/menu_fundo.png"
## Quanto o boneco (escala 0,25 no jogo) cresce aqui. Inteiro: o pixel da arte continua nítido.
const ESCALA_BONECO := 3.0
const COR_TEXTO := Tema.COR_TEXTO
const COR_TEXTO_2 := Tema.COR_TEXTO_2

var raca: StringName = RacaData.TODAS[0]
var classe: StringName = ClasseData.TODAS[0]
var rosto := 0
var pele := 0
## 0 = raça e aparência, 1 = classe.
var passo := 0

var _boneco: Boneco
var _titulo_passo: Label
var _nome_boneco: Label
var _pagina: Array[Control] = []
var _botoes_raca: Dictionary[StringName, Button] = {}
var _botoes_classe: Dictionary[StringName, Button] = {}
var _texto_raca: Label
var _texto_bonus: Label
var _texto_raca_hab: Label
var _valor_rosto: Label
var _valor_pele: Label
var _texto_classe: Label
var _texto_atributos: Label
var _texto_vida_mana: Label
var _linha_habilidades: HBoxContainer
var _texto_hab_raca: Label
var _voltar: Button
var _avancar: Button


func _ready() -> void:
	layer = 30  # por cima do HUD
	_montar()
	_atualizar()


# --- Escolhas (os botões e os testes usam estas funções) ---------------------------------

func escolher_raca(id: StringName) -> void:
	if id in RacaData.TODAS:
		raca = id
		_atualizar()


func definir_rosto(i: int) -> void:
	rosto = posmod(i, Player.OPCOES_ROSTO)
	_atualizar()


func definir_pele(i: int) -> void:
	pele = posmod(i, Player.OPCOES_PELE)
	_atualizar()


func escolher_classe(id: StringName) -> void:
	if id in ClasseData.TODAS:
		classe = id
		_atualizar()


func avancar() -> void:
	if passo == 0:
		passo = 1
		_atualizar()
	else:
		confirmar()


func voltar() -> void:
	if passo == 1:
		passo = 0
		_atualizar()


## "Entrar no mundo": só vale no passo da classe.
func confirmar() -> void:
	if passo == 1:
		confirmado.emit(raca, classe, aparencia())


func aparencia() -> Dictionary:
	return {"raca": raca, "rosto": rosto, "pele": pele}


## As roupas que o boneco veste agora: nenhuma (branca) até escolher a classe.
func roupas() -> Dictionary:
	if passo == 0:
		return {&"cabeca": &"", &"corpo": &""}
	var base: Array = Player.ROUPAS_BASE[classe]
	return {&"cabeca": base[0], &"corpo": base[1]}


func boneco() -> Boneco:
	return _boneco


# --- Montagem ------------------------------------------------------------------------

func _montar() -> void:
	var raiz := Control.new()
	raiz.theme = Tema.tema()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_STOP  # o clique não vaza para o mundo
	add_child(raiz)
	if ResourceLoader.exists(FUNDO):
		var fundo := TextureRect.new()
		fundo.texture = load(FUNDO)
		fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fundo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		raiz.add_child(fundo)
	var escuro := ColorRect.new()
	escuro.color = Color(0.03, 0.04, 0.1, 0.62)
	escuro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(escuro)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(centro)
	var painel := PanelContainer.new()
	centro.add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override(&"separation", 10)
	painel.add_child(coluna)

	var titulo := _rotulo("Crie o seu personagem", 30, Tema.COR_DESTAQUE)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(titulo)
	_titulo_passo = _rotulo("", 18, COR_TEXTO_2)
	_titulo_passo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(_titulo_passo)

	var meio := HBoxContainer.new()
	meio.add_theme_constant_override(&"separation", 28)
	coluna.add_child(meio)
	meio.add_child(_montar_previa())
	var direita := VBoxContainer.new()
	direita.custom_minimum_size = Vector2(520, 424)
	meio.add_child(direita)
	_pagina.append(_montar_raca())
	_pagina.append(_montar_classe())
	for p in _pagina:
		direita.add_child(p)

	var rodape := HBoxContainer.new()
	rodape.alignment = BoxContainer.ALIGNMENT_END
	rodape.add_theme_constant_override(&"separation", 14)
	coluna.add_child(rodape)
	_voltar = Button.new()
	_voltar.text = "Voltar"
	_voltar.custom_minimum_size = Vector2(150, 48)
	_voltar.pressed.connect(voltar)
	rodape.add_child(_voltar)
	_avancar = Button.new()
	_avancar.custom_minimum_size = Vector2(230, 48)
	_avancar.pressed.connect(avancar)
	rodape.add_child(_avancar)


## O quadro do bonequinho (cresce por um fator inteiro) e o nome embaixo.
func _montar_previa() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 8)
	var quadro := Panel.new()
	quadro.custom_minimum_size = Vector2(250, 330)
	var caixa := StyleBoxFlat.new()
	caixa.bg_color = Tema.COR_FUNDO.darkened(0.35)
	caixa.border_color = Tema.COR_BORDA
	caixa.set_border_width_all(3)
	caixa.set_corner_radius_all(4)
	quadro.add_theme_stylebox_override(&"panel", caixa)
	quadro.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	v.add_child(quadro)
	_boneco = Boneco.new()
	_boneco.scale = Vector2.ONE * ESCALA_BONECO
	_boneco.position = Vector2(125, 292)  # os pés, no meio e perto do chão do quadro
	_boneco.play(&"parado_baixo")
	quadro.add_child(_boneco)
	_nome_boneco = _rotulo("", 20)
	_nome_boneco.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_nome_boneco)
	return v


func _montar_raca() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 10)
	v.add_child(_rotulo("Raça", 22, Tema.COR_DESTAQUE))
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override(&"separation", 12)
	v.add_child(linha)
	var grupo := ButtonGroup.new()
	for id in RacaData.TODAS:
		var b := _botao_escolha(RacaData.carregar(id).nome, grupo)
		b.pressed.connect(escolher_raca.bind(id))
		linha.add_child(b)
		_botoes_raca[id] = b
	_texto_raca = _rotulo("", 17)
	_texto_raca.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_texto_raca)
	_texto_bonus = _rotulo("", 17)
	_texto_bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_texto_bonus)
	_texto_raca_hab = _rotulo("", 17, COR_TEXTO_2)
	_texto_raca_hab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_texto_raca_hab)
	var espaco := Control.new()
	espaco.custom_minimum_size = Vector2(0, 4)
	v.add_child(espaco)
	v.add_child(_rotulo("Aparência", 22, Tema.COR_DESTAQUE))
	_valor_rosto = _linha_opcao(v, "Rosto", func(d: int) -> void: definir_rosto(rosto + d))
	_valor_pele = _linha_opcao(v, "Pele", func(d: int) -> void: definir_pele(pele + d))
	return v


## "Rosto  ‹  2 / 3  ›": as setas chamam `mudar` com -1 ou +1. Retorna o rótulo do meio.
func _linha_opcao(pai: Control, nome: String, mudar: Callable) -> Label:
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override(&"separation", 8)
	pai.add_child(linha)
	var n := _rotulo(nome, 18)
	n.custom_minimum_size = Vector2(90, 0)
	linha.add_child(n)
	var esq := _botao_seta("‹")
	esq.pressed.connect(mudar.bind(-1))
	linha.add_child(esq)
	var valor := _rotulo("", 18)
	valor.custom_minimum_size = Vector2(110, 0)
	valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	linha.add_child(valor)
	var dir := _botao_seta("›")
	dir.pressed.connect(mudar.bind(1))
	linha.add_child(dir)
	return valor


func _montar_classe() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 10)
	v.add_child(_rotulo("Classe", 22, Tema.COR_DESTAQUE))
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override(&"separation", 12)
	v.add_child(linha)
	var grupo := ButtonGroup.new()
	for id in ClasseData.TODAS:
		var b := _botao_escolha(ClasseData.carregar(id).nome, grupo)
		b.pressed.connect(escolher_classe.bind(id))
		linha.add_child(b)
		_botoes_classe[id] = b
	_texto_classe = _rotulo("", 17)
	_texto_classe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_texto_classe)
	_texto_atributos = _rotulo("", 17)
	_texto_atributos.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_texto_atributos)
	_texto_vida_mana = _rotulo("", 17)
	v.add_child(_texto_vida_mana)
	v.add_child(_rotulo("Habilidades", 22, Tema.COR_DESTAQUE))
	_linha_habilidades = HBoxContainer.new()
	_linha_habilidades.add_theme_constant_override(&"separation", 12)
	v.add_child(_linha_habilidades)
	_texto_hab_raca = _rotulo("", 17, COR_TEXTO_2)
	_texto_hab_raca.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_texto_hab_raca)
	return v


func _botao_escolha(texto: String, grupo: ButtonGroup) -> Button:
	var b := Button.new()
	b.text = texto
	b.toggle_mode = true
	b.button_group = grupo
	b.custom_minimum_size = Vector2(150, 46)
	return b


func _botao_seta(texto: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(52, 44)
	b.add_theme_font_size_override(&"font_size", 26)
	return b


func _rotulo(texto: String, tamanho: int, cor := COR_TEXTO) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override(&"font_size", tamanho)
	l.add_theme_color_override(&"font_color", cor)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# --- Atualização ----------------------------------------------------------------------

func _atualizar() -> void:
	_pagina[0].visible = passo == 0
	_pagina[1].visible = passo == 1
	_titulo_passo.text = "Passo 1 de 2 · Raça e aparência" if passo == 0 else "Passo 2 de 2 · Classe"
	_voltar.visible = passo == 1
	_avancar.text = "Próximo: classe" if passo == 0 else "Entrar no mundo"
	for id in _botoes_raca:
		_botoes_raca[id].set_pressed_no_signal(id == raca)
	for id in _botoes_classe:
		_botoes_classe[id].set_pressed_no_signal(id == classe)
	_valor_rosto.text = "%d / %d" % [rosto + 1, Player.OPCOES_ROSTO]
	_valor_pele.text = "%d / %d" % [pele + 1, Player.OPCOES_PELE]

	var dados_raca := RacaData.carregar(raca)
	_texto_raca.text = dados_raca.descricao
	_texto_bonus.text = "Bônus: " + _texto_bonus_da_raca(dados_raca)
	_texto_raca_hab.text = "%s: %s" % [dados_raca.habilidade_nome, dados_raca.habilidade_descricao]

	var f := Ficha.criar(raca, classe)
	_texto_classe.text = f.classe.descricao
	var atributos: Array[String] = []
	for a in Ficha.ATRIBUTOS:
		atributos.append("%s %d" % [Ficha.NOMES[a], f.valor(a)])
	_texto_atributos.text = " · ".join(atributos)
	_texto_vida_mana.text = "Vida %d · Mana %d" % [f.vida_maxima(), f.mana_maxima()]
	for c in _linha_habilidades.get_children():
		c.free()
	for h in f.classe.habilidades:
		_linha_habilidades.add_child(_chip_habilidade(h))
	_texto_hab_raca.text = "%s (%s): %s" % [f.raca.habilidade_nome, f.raca.nome, f.raca.habilidade_descricao]

	_nome_boneco.text = dados_raca.nome if passo == 0 else f.titulo()
	_boneco.item = Player.KIT.get(classe, &"") if passo == 1 else &""
	_boneco.vestir(aparencia(), roupas())
	_boneco.play(&"parado_baixo")


func _texto_bonus_da_raca(dados: RacaData) -> String:
	var partes: Array[String] = []
	for a in Ficha.ATRIBUTOS:
		var b: int = dados.bonus.get(a, 0)
		if b != 0:
			partes.append("%s %s%d" % [Ficha.NOMES[a], "+" if b > 0 else "−", absi(b)])
	return " · ".join(partes) if not partes.is_empty() else "nenhum"


## Ícone da habilidade com o nome embaixo.
func _chip_habilidade(h: HabilidadeData) -> Control:
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(110, 0)
	v.tooltip_text = h.descricao
	var icone := TextureRect.new()
	icone.texture = h.icone
	icone.custom_minimum_size = Vector2(48, 48)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(icone)
	var nome := _rotulo(h.nome, 15)
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nome)
	return v
