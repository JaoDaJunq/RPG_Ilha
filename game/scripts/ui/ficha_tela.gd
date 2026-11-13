class_name FichaTela
extends PanelContainer
## Ficha do personagem (C). Em cima: retrato, nome, raça e classe, nível e a barra de
## experiência. Embaixo, duas abas, cada uma com um selo dourado dizendo quantos pontos dá
## para gastar ali:
##   - Atributos: um ladrilho por atributo (ícone, valor grande e um "+" bem visível quando
##     há ponto). Com o mouse no "+", a prévia mostra o que sobe (em verde). Logo abaixo, os
##     status em caixinhas (ícone e número).
##   - Habilidades: as habilidades das teclas, com o nível, e o botão que abre a árvore.
## Colocar ponto continua sendo um PEDIDO ao anfitrião (Player.pedir_atributo).

const PASTA_ICONES := "res://assets/sprites/tiny/icones/"
const ICONES_ATRIBUTO := {
	&"forca": preload("res://assets/sprites/tiny/icones/icone_forca.png"),
	&"vitalidade": preload("res://assets/sprites/tiny/icones/icone_vitalidade.png"),
	&"agilidade": preload("res://assets/sprites/tiny/icones/icone_agilidade.png"),
	&"intelecto": preload("res://assets/sprites/tiny/icones/icone_intelecto.png"),
	&"espirito": preload("res://assets/sprites/tiny/icones/icone_espirito.png"),
}
## O que cada atributo melhora (dica do ladrilho).
const DICAS_ATRIBUTO := {
	&"forca": "Mais dano físico e coleta mais rápida",
	&"vitalidade": "Mais vida",
	&"agilidade": "Anda mais rápido e o dash volta antes",
	&"intelecto": "Mais mana e mais dano mágico",
	&"espirito": "A mana volta mais rápido",
}
## Status mostrados em caixinhas: [id, ícone, nome, legenda curta].
const STATUS := [
	[&"vida", "icone_vitalidade", "Vida", "vida"],
	[&"mana", "icone_espirito", "Mana", "mana"],
	[&"mana_s", "icone_espirito", "Mana por segundo", "mana/s"],
	[&"velocidade", "icone_agilidade", "Velocidade", "andar"],
	[&"fisico", "item_espada_ferro", "Dano físico", "físico"],
	[&"magico", "item_cajado", "Dano mágico", "mágico"],
	[&"coleta", "item_machado_pedra", "Velocidade de coleta", "coleta"],
	[&"dash", "icone_esquiva", "Recarga do dash", "dash"],
	[&"conj_magia", "icone_intelecto", "Conjuração (-3% por Intelecto acima de 5, até -40%)", "conjurar"],
	[&"conj_arco", "icone_tiro", "Puxar o arco (-3% por Agilidade acima de 5, até -40%)", "puxar arco"],
]
## Status em que um número MENOR é melhor.
const MENOR_MELHOR: Array[StringName] = [&"dash"]
const COR_SOBE := Color("7ed36a")
const COR_CAIXA := Color(0.09, 0.09, 0.13, 0.55)
const LARGURA := 460  # 5 ladrilhos de uns 88 px
const ABA_ATRIBUTOS := 0
const ABA_HABILIDADES := 1

var jogador: Player
## Chamado pelo botão "Abrir árvore" (o HUD fecha a mochila e abre a árvore).
var ao_abrir_arvore: Callable

var _retrato: TextureRect
var _nome: Label
var _subtitulo: Label
var _nivel: Label
var _barra_xp: ProgressBar
var _xp_texto: Label
var _abas: Array[Button] = []
var _selos: Array[PanelContainer] = []
var _selos_texto: Array[Label] = []
var _paginas: Array[Control] = []
var _aba := ABA_ATRIBUTOS
var _aviso_pontos: Label
var _ladrilhos: Dictionary = {}  # atributo → {caixa, valor, mais}
var _chips: Dictionary = {}  # status → {caixa, valor}
var _previa: RichTextLabel
var _previa_de: StringName = &""
var _lista_habilidades: VBoxContainer
var _raca: Label
var _aviso_arvore: Label
var _botao_arvore: Button


func _ready() -> void:
	add_theme_stylebox_override(&"panel", Tema.painel())
	mouse_filter = Control.MOUSE_FILTER_STOP  # os botões "+" recebem o clique
	_montar()
	Configuracoes.mudou.connect(atualizar)


func configurar(p: Player, abrir_arvore: Callable) -> void:
	jogador = p
	ao_abrir_arvore = abrir_arvore
	p.progresso_mudou.connect(atualizar)
	p.aspecto_mudou.connect(atualizar)
	atualizar()


# --- Para os testes e para o HUD --------------------------------------------------------

func abrir_aba(i: int) -> void:
	_aba = i
	atualizar()


func aba() -> int:
	return _aba


## Texto do selo da aba (vazio quando ele está escondido: nenhum ponto ali).
func texto_selo(i: int) -> String:
	return _selos_texto[i].text if _selos[i].visible else ""


func botao_mais(atributo: StringName) -> Button:
	return _ladrilhos[atributo].mais


func botao_arvore() -> Button:
	return _botao_arvore


func valor_mostrado(atributo: StringName) -> String:
	return _ladrilhos[atributo].valor.text


func valor_status(status: StringName) -> String:
	return _chips[status].valor.text


## Mostra o que muda com +1 no atributo (o que o mouse em cima do "+" faz).
func mostrar_previa(atributo: StringName) -> void:
	_previa_de = atributo
	_pintar_previa()


func esconder_previa() -> void:
	_previa_de = &""
	_pintar_previa()


## A prévia em texto simples (sem as cores).
func texto_previa() -> String:
	return _previa.get_parsed_text() if _previa_de != &"" else ""


func nomes_habilidades() -> Array[String]:
	var l: Array[String] = []
	for linha in _lista_habilidades.get_children():
		if linha.has_meta(&"nome"):
			l.append(linha.get_meta(&"nome"))
	return l


# --- Atualização ------------------------------------------------------------------------

func atualizar() -> void:
	if jogador == null or jogador.ficha == null or _nome == null:
		return
	var f := jogador.ficha
	_retrato.texture = Boneco.retrato(jogador.aparencia_completa(), jogador.equipado)
	_nome.text = f.classe.nome
	_subtitulo.text = "%s · %s" % [f.raca.nome, f.classe.familia]
	_nivel.text = "Nível %d" % jogador.nivel
	var precisa := maxi(jogador.xp_para_subir(), 1)
	var no_maximo := jogador.nivel >= Ficha.NIVEL_MAXIMO
	_barra_xp.value = 100.0 if no_maximo else 100.0 * jogador.xp / precisa
	_xp_texto.text = "nível máximo" if no_maximo else "%d / %d" % [jogador.xp, precisa]
	# Abas e selos.
	var pontos: Array[int] = [jogador.pontos_atributo, jogador.pontos_habilidade]
	for i in _abas.size():
		var ativa := i == _aba
		_abas[i].self_modulate = Color.WHITE if ativa else Color(0.6, 0.6, 0.68)
		for cor in [&"font_color", &"font_hover_color", &"font_focus_color"]:
			_abas[i].add_theme_color_override(cor, Tema.COR_DESTAQUE if ativa else Tema.COR_TEXTO_2)
		_paginas[i].visible = ativa
		_selos[i].visible = pontos[i] > 0
		_selos_texto[i].text = str(pontos[i])
	var pa := jogador.pontos_atributo
	_aviso_pontos.visible = pa > 0
	_aviso_pontos.text = "%d %s: clique no +" % [pa, "ponto" if pa == 1 else "pontos"]
	for a in Ficha.ATRIBUTOS:
		var l: Dictionary = _ladrilhos[a]
		l.valor.text = str(f.valor(a))
		var colocados: int = jogador.distribuidos.get(a, 0)
		var bonus: int = f.raca.bonus.get(a, 0)
		var partes: Array[String] = ["%s: %s." % [Ficha.NOMES[a], DICAS_ATRIBUTO[a]], "Classe %d" % f.classe.atributos.get(a, 5)]
		if bonus != 0:
			partes.append("raça %+d" % bonus)
		if colocados > 0:
			partes.append("seus pontos +%d" % colocados)
		l.caixa.tooltip_text = partes[0] + "\n" + ", ".join(partes.slice(1))
		l.colocados.text = "+%d" % colocados if colocados > 0 else ""
		var tem_ponto := pa > 0
		l.mais.disabled = not tem_ponto
		l.mais.modulate.a = 1.0 if tem_ponto else 0.0
		l.mais.mouse_filter = Control.MOUSE_FILTER_STOP if tem_ponto else Control.MOUSE_FILTER_IGNORE
	if pa <= 0:
		_previa_de = &""
	_pintar_previa()
	var ph := jogador.pontos_habilidade
	_aviso_arvore.visible = ph > 0
	_aviso_arvore.text = "%d %s para gastar na árvore" % [ph, "ponto" if ph == 1 else "pontos"]
	_raca.text = "%s (raça): %s" % [f.raca.habilidade_nome, f.raca.habilidade_descricao]
	_botao_arvore.text = "Abrir árvore (%s)" % Configuracoes.tecla_de(&"arvore")
	_montar_habilidades()


## Valores atuais (ou com +1 em `extra`) de cada status.
func _status_de(f: Ficha) -> Dictionary:
	return {
		&"vida": f.vida_maxima(),
		&"mana": f.mana_maxima(),
		&"mana_s": f.regeneracao_mana(),
		&"velocidade": f.velocidade(),
		&"fisico": f.multiplicador_fisico() * 100.0,
		&"magico": f.multiplicador_magico() * 100.0,
		&"coleta": 100.0 / f.tempo_coleta(),
		&"dash": f.recarga_esquiva(),
		&"conj_magia": Conjuracao.reducao(f, &"intelecto") * 100.0,
		&"conj_arco": Conjuracao.reducao(f, &"agilidade") * 100.0,
	}


func _formatar(status: StringName, v: float) -> String:
	match status:
		&"mana_s":
			return "+%s/s" % _decimal(v)
		&"dash":
			return "%s s" % _decimal(v)
		&"conj_magia", &"conj_arco":
			return "-%d%%" % roundi(v)
		&"fisico", &"magico", &"coleta":
			return "%d%%" % roundi(v)
	return str(roundi(v))


static func _decimal(v: float) -> String:
	return ("%.1f" % v).replace(".", ",")


func _pintar_previa() -> void:
	if jogador == null or jogador.ficha == null:
		return
	# Borda dos ladrilhos: dourada com ponto para gastar; verde no que está na prévia.
	for a in Ficha.ATRIBUTOS:
		var borda := Color(0, 0, 0, 0)
		if a == _previa_de:
			borda = COR_SOBE
		elif jogador.pontos_atributo > 0:
			borda = Tema.COR_DESTAQUE
		(_ladrilhos[a].caixa as PanelContainer).add_theme_stylebox_override(&"panel", _caixa(borda, 3 if a == _previa_de else 2))
	var agora := _status_de(jogador.ficha)
	var depois := agora
	if _previa_de != &"":
		var dist := jogador.distribuidos.duplicate()
		dist[_previa_de] = int(dist.get(_previa_de, 0)) + 1
		depois = _status_de(Ficha.criar(jogador.raca, jogador.classe, dist))
	var mudancas: Array[String] = []
	for s in STATUS:
		var id: StringName = s[0]
		var c: Dictionary = _chips[id]
		var antes_txt := _formatar(id, agora[id])
		var depois_txt := _formatar(id, depois[id])
		var muda := antes_txt != depois_txt
		c.valor.text = depois_txt
		c.valor.add_theme_color_override(&"font_color", COR_SOBE if muda else Tema.COR_TEXTO)
		(c.caixa as PanelContainer).add_theme_stylebox_override(&"panel", _caixa(COR_SOBE if muda else Color(0, 0, 0, 0), 2))
		if muda:
			mudancas.append("%s %s → [color=#%s]%s[/color]" % [s[2], antes_txt, COR_SOBE.to_html(false), depois_txt])
	if _previa_de == &"":
		_previa.text = "[color=#%s]Passe o mouse no + para ver o que muda.[/color]" % Tema.COR_TEXTO_2.to_html(false) if jogador.pontos_atributo > 0 else ""
		_previa.visible = jogador.pontos_atributo > 0
		return
	var a_valor := jogador.ficha.valor(_previa_de)
	_previa.visible = true
	_previa.text = "%s %d → [color=#%s]%d[/color]:  %s" % [Ficha.NOMES[_previa_de], a_valor, COR_SOBE.to_html(false), a_valor + 1, "  ·  ".join(mudancas)]


func _montar_habilidades() -> void:
	for c in _lista_habilidades.get_children():
		c.free()
	var ids := jogador.ids_nas_teclas()
	var k := 0
	for id in ids:
		var n := ArvoreData.no(jogador.classe, id)
		if n == null or not n.usavel() or not jogador.tem(id):
			continue
		var linha := PanelContainer.new()
		linha.add_theme_stylebox_override(&"panel", _caixa(Color(0, 0, 0, 0), 0, 6))
		linha.set_meta(&"nome", n.nome)
		linha.tooltip_text = n.descricao
		var h := HBoxContainer.new()
		h.add_theme_constant_override(&"separation", 10)
		linha.add_child(h)
		var espaco := Panel.new()
		espaco.add_theme_stylebox_override(&"panel", Tema.espaco())
		espaco.custom_minimum_size = Vector2(56, 56)
		espaco.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icone := _icone(n.icone, Vector2(48, 48))
		icone.position = Vector2(4, 4)
		icone.size = Vector2(48, 48)
		espaco.add_child(icone)
		var tecla := _rotulo(Configuracoes.tecla_de(StringName("habilidade_%d" % (k + 1))), 13, Tema.COR_TEXTO_2)
		tecla.position = Vector2(5, 1)
		espaco.add_child(tecla)
		h.add_child(espaco)
		var nome := _rotulo(n.nome, 18)
		nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nome.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(nome)
		var r := jogador.rank(id)
		var nv := _rotulo("Nv %d" % r, 20, Tema.COR_DESTAQUE if r > 1 else Tema.COR_TEXTO)
		nv.add_theme_font_override(&"font", Tema.fonte_negrito())
		nv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		nv.tooltip_text = "Melhorias: %d de %d" % [r - 1, NoArvore.MELHORIAS]
		h.add_child(nv)
		var de := _rotulo("/%d" % n.rank_maximo(), 14, Tema.COR_TEXTO_2)
		de.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(de)
		_lista_habilidades.add_child(linha)
		k += 1


# --- Montagem ---------------------------------------------------------------------------

func _montar() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 10)
	v.custom_minimum_size = Vector2(LARGURA, 0)
	add_child(v)

	# Cabeçalho: retrato, nome, raça e família, nível e experiência.
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override(&"separation", 12)
	v.add_child(topo)
	var moldura := Panel.new()
	moldura.add_theme_stylebox_override(&"panel", Tema.espaco())
	moldura.custom_minimum_size = Vector2(80, 80)
	moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	topo.add_child(moldura)
	_retrato = TextureRect.new()
	_retrato.position = Vector2(6, 6)
	_retrato.size = Vector2(68, 68)
	_retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_retrato.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # retrato de 256 px reduzido
	_retrato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moldura.add_child(_retrato)
	var nomes := VBoxContainer.new()
	nomes.add_theme_constant_override(&"separation", 0)
	nomes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(nomes)
	var linha_nome := HBoxContainer.new()
	nomes.add_child(linha_nome)
	_nome = _rotulo("", 26, Tema.COR_DESTAQUE)
	_nome.theme_type_variation = &"RotuloTitulo"
	_nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha_nome.add_child(_nome)
	_nivel = _rotulo("", 20)
	_nivel.add_theme_font_override(&"font", Tema.fonte_negrito())
	_nivel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha_nome.add_child(_nivel)
	_subtitulo = _rotulo("", 16, Tema.COR_TEXTO_2)
	nomes.add_child(_subtitulo)
	var linha_xp := HBoxContainer.new()
	linha_xp.add_theme_constant_override(&"separation", 6)
	nomes.add_child(linha_xp)
	linha_xp.add_child(_icone(load(PASTA_ICONES + "icone_experiencia.png"), Vector2(32, 30)))
	_barra_xp = Tema.barra_com_moldura(Color("e7c46e"), 20)
	_barra_xp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_barra_xp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha_xp.add_child(_barra_xp)
	_xp_texto = _rotulo("", 14, Tema.COR_TEXTO_2)
	_xp_texto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha_xp.add_child(_xp_texto)

	# Abas, cada uma com o seu selo de pontos.
	var abas := HBoxContainer.new()
	abas.add_theme_constant_override(&"separation", 14)
	v.add_child(abas)
	for i in 2:
		var b := Button.new()
		b.text = "Atributos" if i == ABA_ATRIBUTOS else "Habilidades"
		b.theme_type_variation = &"BotaoPequeno"
		b.custom_minimum_size = Vector2(0, 44)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override(&"font_size", 20)
		b.pressed.connect(abrir_aba.bind(i))
		abas.add_child(b)
		_abas.append(b)
		var selo := _selo()
		b.add_child(selo)
		_selos.append(selo)
		_selos_texto.append(selo.get_child(0) as Label)

	# As duas páginas; só a da aba escolhida fica visível.
	_paginas.append(_montar_atributos())
	_paginas.append(_montar_aba_habilidades())
	for p in _paginas:
		v.add_child(p)


func _montar_atributos() -> Control:
	var pag := VBoxContainer.new()
	pag.add_theme_constant_override(&"separation", 8)
	_aviso_pontos = _rotulo("", 18, Tema.COR_DESTAQUE)
	_aviso_pontos.add_theme_font_override(&"font", Tema.fonte_negrito())
	_aviso_pontos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pag.add_child(_aviso_pontos)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override(&"separation", 6)
	pag.add_child(linha)
	for a in Ficha.ATRIBUTOS:
		linha.add_child(_ladrilho(a))
	_previa = RichTextLabel.new()
	_previa.bbcode_enabled = true
	_previa.fit_content = true
	_previa.scroll_active = false
	_previa.custom_minimum_size = Vector2(LARGURA, 0)
	_previa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_previa.add_theme_font_size_override(&"normal_font_size", 16)
	_previa.add_theme_color_override(&"default_color", Tema.COR_TEXTO)
	_previa.add_theme_constant_override(&"outline_size", 4)
	_previa.add_theme_color_override(&"font_outline_color", Tema.COR_CONTORNO)
	pag.add_child(_previa)
	var grade := GridContainer.new()
	grade.columns = 4
	grade.add_theme_constant_override(&"h_separation", 6)
	grade.add_theme_constant_override(&"v_separation", 6)
	pag.add_child(grade)
	for s in STATUS:
		grade.add_child(_chip(s[0], load(PASTA_ICONES + s[1] + ".png"), s[2], s[3]))
	return pag


## Ladrilho de um atributo: ícone, nome, valor grande e o "+".
func _ladrilho(a: StringName) -> Control:
	var caixa := PanelContainer.new()
	caixa.custom_minimum_size = Vector2(86, 0)
	caixa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caixa.mouse_filter = Control.MOUSE_FILTER_PASS  # a dica aparece com o mouse em cima
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 2)
	caixa.add_child(v)
	v.add_child(_icone(ICONES_ATRIBUTO[a], Vector2(0, 34)))
	var nome := _rotulo(Ficha.NOMES[a], 13, Tema.COR_TEXTO_2)
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nome)
	var valor := _rotulo("", 30)
	valor.add_theme_font_override(&"font", Tema.fonte_negrito())
	valor.add_theme_constant_override(&"outline_size", 6)
	valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(valor)
	# Pontos que o jogador já pôs aqui, pequeno no canto de cima.
	var canto := Control.new()  # o PanelContainer esticaria o rótulo: fica num Control solto
	canto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_child(canto)
	var colocados := _rotulo("", 13, COR_SOBE)
	colocados.position = Vector2(50, -4)
	colocados.size = Vector2(26, 18)
	colocados.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	canto.add_child(colocados)
	var mais := Button.new()
	mais.text = "+"
	mais.theme_type_variation = &"BotaoPequeno"
	mais.custom_minimum_size = Vector2(0, 38)
	mais.add_theme_font_size_override(&"font_size", 26)
	mais.tooltip_text = "Colocar 1 ponto em " + Ficha.NOMES[a]
	mais.pressed.connect(func() -> void:
		if jogador:
			jogador.pedir_atributo(a))
	mais.mouse_entered.connect(mostrar_previa.bind(a))
	mais.focus_entered.connect(mostrar_previa.bind(a))
	mais.mouse_exited.connect(func() -> void:
		if _previa_de == a:
			esconder_previa())
	v.add_child(mais)
	_ladrilhos[a] = {caixa = caixa, valor = valor, mais = mais, colocados = colocados}
	return caixa


## Caixinha de um status: ícone, número e uma palavra (o nome inteiro fica na dica).
func _chip(id: StringName, icone: Texture2D, nome: String, curto: String) -> Control:
	var caixa := PanelContainer.new()
	caixa.tooltip_text = nome
	caixa.mouse_filter = Control.MOUSE_FILTER_PASS
	caixa.custom_minimum_size = Vector2(108, 0)
	caixa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.add_theme_constant_override(&"separation", 4)
	caixa.add_child(h)
	h.add_child(_icone(icone, Vector2(46, 46)))
	var textos := VBoxContainer.new()
	textos.add_theme_constant_override(&"separation", -4)
	textos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(textos)
	var valor := _rotulo("", 18)
	valor.add_theme_font_override(&"font", Tema.fonte_negrito())
	textos.add_child(valor)
	textos.add_child(_rotulo(curto, 12, Tema.COR_TEXTO_2))
	_chips[id] = {caixa = caixa, valor = valor}
	return caixa


func _montar_aba_habilidades() -> Control:
	var pag := VBoxContainer.new()
	pag.add_theme_constant_override(&"separation", 8)
	_lista_habilidades = VBoxContainer.new()
	_lista_habilidades.add_theme_constant_override(&"separation", 6)
	pag.add_child(_lista_habilidades)
	_raca = _rotulo("", 14, Tema.COR_TEXTO_2)
	_raca.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_raca.custom_minimum_size = Vector2(LARGURA, 0)
	pag.add_child(_raca)
	_aviso_arvore = _rotulo("", 18, Tema.COR_DESTAQUE)
	_aviso_arvore.add_theme_font_override(&"font", Tema.fonte_negrito())
	_aviso_arvore.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pag.add_child(_aviso_arvore)
	_botao_arvore = Button.new()
	_botao_arvore.theme_type_variation = &"BotaoPequeno"
	_botao_arvore.custom_minimum_size = Vector2(0, 52)
	_botao_arvore.add_theme_font_size_override(&"font_size", 22)
	_botao_arvore.pressed.connect(func() -> void:
		if ao_abrir_arvore.is_valid():
			ao_abrir_arvore.call())
	pag.add_child(_botao_arvore)
	return pag


## Selo redondo e dourado no canto da aba, com os pontos que dá para gastar ali.
func _selo() -> PanelContainer:
	var selo := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Tema.COR_DESTAQUE
	s.border_color = Tema.COR_CONTORNO
	s.set_border_width_all(3)
	s.set_corner_radius_all(16)
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.anti_aliasing = true
	selo.add_theme_stylebox_override(&"panel", s)
	selo.custom_minimum_size = Vector2(32, 32)
	selo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selo.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	selo.offset_left = -22
	selo.offset_right = 10
	selo.offset_top = -16
	selo.offset_bottom = 16
	var n := _rotulo("", 18, Tema.COR_TINTA)
	n.add_theme_font_override(&"font", Tema.fonte_negrito())
	n.add_theme_constant_override(&"outline_size", 0)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	selo.add_child(n)
	return selo


func _caixa(borda: Color, largura: int, margem := 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = COR_CAIXA
	s.border_color = borda
	s.set_border_width_all(largura)
	s.set_corner_radius_all(6)
	s.set_content_margin_all(margem)
	s.anti_aliasing = true
	return s


func _icone(textura: Texture2D, tamanho: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = textura
	t.custom_minimum_size = tamanho
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED  # tamanho real do pixel do pacote
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _rotulo(texto: String, tamanho: int, cor := Tema.COR_TEXTO) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override(&"font_size", tamanho)
	l.add_theme_color_override(&"font_color", cor)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
