class_name Hud
extends CanvasLayer
## Interface: recursos, vida e mana, barra de habilidades, avisos, ficha do personagem (C),
## nomes dos outros jogadores e o aviso de interação em cima do objeto sob o mouse.

const ITENS: Array[StringName] = [&"madeira", &"pedra", &"carvao"]
const ICONE_ESQUIVA := preload("res://assets/placeholder/ninja/ui/icone_esquiva.png")
const COR_FUNDO := Color(0.07, 0.13, 0.13, 0.9)
const COR_BORDA := Color("947c50")
const COR_TEXTO := Color("f2e7c6")
const COR_TEXTO_2 := Color("b6ccaf")

var jogador: Player
var _contagens: Dictionary[StringName, Label] = {}
var _barra_vida: ProgressBar
var _barra_mana: ProgressBar
var _titulo_personagem: Label
var _aviso: Label
var _aviso_tempo := 0.0
var _dica: PanelContainer
var _dica_texto: Label
var _dica_progresso: ProgressBar
var _slots_icone: Array[TextureRect] = []
var _slots_sombra: Array[ColorRect] = []
var _sombra_esquiva: ColorRect
var _carga: ProgressBar
var _ficha: PanelContainer
var _ficha_texto: Label
var _ficha_rodape: Label
var _ficha_atributos: Dictionary[StringName, Label] = {}
var _ficha_botoes: Dictionary[StringName, Button] = {}
var _barra_xp: ProgressBar
var _nomes: Dictionary[Node, Label] = {}
var _raiz: Control


func _ready() -> void:
	layer = 10
	Events.aviso.connect(mostrar_aviso)
	_montar()


func configurar(p: Player) -> void:
	jogador = p
	jogador.inventario.mudou.connect(_atualizar_itens)
	jogador.vida.mudou.connect(func(atual: float, maximo: float) -> void: _barra_vida.value = atual / maximo * 100.0)
	jogador.progresso_mudou.connect(_atualizar_progresso)
	var hab := jogador.habilidades()
	for i in _slots_icone.size():
		_slots_icone[i].texture = hab[i].icone if i < hab.size() else null
		_slots_icone[i].get_parent().tooltip_text = ("%s (%d de mana)\n%s" % [hab[i].nome, hab[i].custo_mana, hab[i].descricao]) if i < hab.size() else ""
	_atualizar_progresso()
	_atualizar_itens()


func mostrar_aviso(texto: String) -> void:
	_aviso.text = texto
	_aviso.modulate.a = 1.0
	_aviso_tempo = 4.0


func texto_aviso() -> String:
	return _aviso.text


func ficha_visivel() -> bool:
	return _ficha.visible


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ficha") and jogador:
		_atualizar_progresso()
		_ficha.visible = not _ficha.visible


func _process(delta: float) -> void:
	_aviso_tempo -= delta
	if _aviso_tempo < 1.0:
		_aviso.modulate.a = clampf(_aviso_tempo, 0.0, 1.0)
	if jogador == null or not is_instance_valid(jogador):
		return
	_barra_mana.value = jogador.mana / jogador.ficha.mana_maxima() * 100.0
	for i in _slots_sombra.size():
		_slots_sombra[i].anchor_top = 1.0 - jogador.recarga_restante(i)
	_sombra_esquiva.anchor_top = 1.0 - jogador.recarga_esquiva_restante()
	var carga := jogador.carga_atual()
	_carga.visible = carga >= 0.0
	_carga.value = carga * 100.0
	_atualizar_dica()
	_atualizar_nomes()


func _atualizar_dica() -> void:
	var alvo := jogador.alvo
	if alvo == null or not is_instance_valid(alvo):
		_dica.visible = false
		return
	_dica.visible = true
	if jogador.alvo_ao_alcance():
		_dica_texto.text = "SEGURE E  ·  " + alvo.dono().texto_acao().to_upper()
		_dica_progresso.visible = jogador.progresso_interacao() > 0.0
		_dica_progresso.value = jogador.progresso_interacao() * 100.0
	else:
		_dica_texto.text = "CHEGUE MAIS PERTO"
		_dica_progresso.visible = false
	var tela := get_viewport().get_canvas_transform() * (alvo.global_position + Vector2(0, -60))
	_dica.position = (tela - Vector2(_dica.size.x / 2.0, _dica.size.y)).round()


## Nome (raça e classe) em cima dos outros jogadores.
func _atualizar_nomes() -> void:
	var vistos: Array[Node] = []
	for p in get_tree().get_nodes_in_group(&"jogadores"):
		if p == jogador or (p as Player).ficha == null:
			continue
		vistos.append(p)
		if not _nomes.has(p):
			var l := _rotulo("", 13, COR_TEXTO)
			l.add_theme_color_override(&"font_outline_color", Color(0.05, 0.08, 0.08))
			l.add_theme_constant_override(&"outline_size", 4)
			_raiz.add_child(l)
			_nomes[p] = l
		var rotulo := _nomes[p]
		rotulo.text = "Nv %d · %s" % [(p as Player).nivel, (p as Player).ficha.titulo()]
		var tela := get_viewport().get_canvas_transform() * ((p as Node2D).global_position + Vector2(0, -32))
		rotulo.position = (tela - Vector2(rotulo.size.x / 2.0, rotulo.size.y)).round()
	for p in _nomes.keys():
		if not p in vistos:
			_nomes[p].queue_free()
			_nomes.erase(p)


func _atualizar_itens() -> void:
	for id in _contagens:
		_contagens[id].text = str(jogador.inventario.quantidade_de(id))


func _texto_ficha() -> String:
	var f := jogador.ficha
	return "%s · NÍVEL %d\n%s · ramos: %s e %s\nExperiência %d / %d" % [
		f.titulo().to_upper(), jogador.nivel, f.classe.familia, f.classe.ramo_a, f.classe.ramo_b,
		jogador.xp, jogador.xp_para_subir()]


func _rodape_ficha() -> String:
	var f := jogador.ficha
	var linhas: Array[String] = [
		"Pontos de atributo para distribuir: %d" % jogador.pontos_atributo,
		"Pontos de habilidade guardados: %d (a árvore vem na próxima etapa)" % jogador.pontos_habilidade,
		"",
		"Vida %d · Mana %d · Velocidade %d" % [f.vida_maxima(), f.mana_maxima(), f.velocidade()],
		"Dano físico x%.1f · mágico x%.1f · coleta x%.2f" % [f.multiplicador_fisico(), f.multiplicador_magico(), f.tempo_coleta()],
		"",
		"%s: %s" % [f.raca.habilidade_nome, f.raca.habilidade_descricao],
	]
	return "\n".join(linhas)


func _atualizar_progresso() -> void:
	if jogador == null:
		return
	var f := jogador.ficha
	_titulo_personagem.text = "Nv %d · %s" % [jogador.nivel, f.titulo()]
	_barra_xp.value = 100.0 * jogador.xp / maxf(jogador.xp_para_subir(), 1.0)
	_ficha_texto.text = _texto_ficha()
	_ficha_rodape.text = _rodape_ficha()
	for a in Ficha.ATRIBUTOS:
		var bonus: int = f.raca.bonus.get(a, 0)
		var pontos: int = jogador.distribuidos.get(a, 0)
		var extras: Array[String] = []
		if bonus != 0:
			extras.append("raça %+d" % bonus)
		if pontos > 0:
			extras.append("pontos +%d" % pontos)
		_ficha_atributos[a].text = "%s  %d   %s" % [Ficha.NOMES[a], f.valor(a), ("(" + ", ".join(extras) + ")") if not extras.is_empty() else ""]
		_ficha_botoes[a].visible = jogador.pontos_atributo > 0


# --- Montagem da interface -------------------------------------------------------

func _montar() -> void:
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)

	# Título e personagem (cima-esquerda)
	var titulo := _painel(_raiz)
	titulo.position = Vector2(16, 14)
	var tv := VBoxContainer.new()
	titulo.add_child(tv)
	tv.add_child(_rotulo("ILHA VIVA", 20, COR_TEXTO))
	_titulo_personagem = _rotulo("", 13, COR_TEXTO_2)
	tv.add_child(_titulo_personagem)
	tv.add_child(_rotulo("C: ficha do personagem", 11, COR_TEXTO_2))

	# Recursos, vida e mana (cima-direita)
	var recursos := _painel(_raiz)
	recursos.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	recursos.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	var rv := VBoxContainer.new()
	recursos.add_child(rv)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override(&"separation", 14)
	rv.add_child(linha)
	for id in ITENS:
		var dados := ItemData.carregar(id)
		var icone := TextureRect.new()
		icone.texture = dados.icone
		icone.modulate = dados.cor_icone
		icone.custom_minimum_size = Vector2(32, 32)
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.tooltip_text = dados.nome
		linha.add_child(icone)
		var n := _rotulo("0", 20, COR_TEXTO)
		linha.add_child(n)
		_contagens[id] = n
	_barra_vida = _barra(Color("d0564a"), 12)
	_barra_vida.value = 100.0
	rv.add_child(_barra_vida)
	_barra_mana = _barra(Color("4a86d0"), 8)
	_barra_mana.value = 100.0
	rv.add_child(_barra_mana)
	_barra_xp = _barra(Color("e7c46e"), 4)
	_barra_xp.tooltip_text = "Experiência"
	rv.add_child(_barra_xp)

	# Barra de baixo: avisos, controles e habilidades
	var base := PanelContainer.new()
	base.add_theme_stylebox_override(&"panel", _caixa(Color("172b29"), Color("b49b66"), 0, 3))
	base.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	base.grow_vertical = Control.GROW_DIRECTION_BEGIN
	base.custom_minimum_size = Vector2(0, 84)
	_raiz.add_child(base)
	var bh := HBoxContainer.new()
	base.add_child(bh)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	bh.add_child(textos)
	_aviso = _rotulo("", 17, COR_TEXTO)
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	textos.add_child(_aviso)
	textos.add_child(_rotulo("WASD mover · E coletar · clique golpear · Espaço esquivar · 1–4 habilidades · N dia/noite · M som", 13, COR_TEXTO_2))
	var barra := HBoxContainer.new()
	barra.alignment = BoxContainer.ALIGNMENT_CENTER
	barra.add_theme_constant_override(&"separation", 8)
	bh.add_child(barra)
	var esquiva := _slot("Espaço")
	(esquiva.get_child(0) as TextureRect).texture = ICONE_ESQUIVA
	_sombra_esquiva = esquiva.get_meta(&"sombra")
	barra.add_child(esquiva)
	var separador := Control.new()
	separador.custom_minimum_size = Vector2(6, 0)
	barra.add_child(separador)
	for i in 6:
		var s := _slot(str(i + 1))
		barra.add_child(s)
		_slots_icone.append(s.get_child(0))
		_slots_sombra.append(s.get_meta(&"sombra"))
	var folga := Control.new()
	folga.custom_minimum_size = Vector2(8, 0)
	bh.add_child(folga)

	# Barra de carga (tiro carregado), logo acima da barra de baixo
	_carga = _barra(Color("e7b36e"), 8)
	_carga.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_carga.custom_minimum_size = Vector2(160, 8)
	_carga.position = Vector2(-80, -110)
	_carga.visible = false
	_raiz.add_child(_carga)

	# Ficha do personagem (C)
	_ficha = _painel(_raiz)
	_ficha.position = Vector2(16, 110)
	_ficha.visible = false
	_ficha.mouse_filter = Control.MOUSE_FILTER_STOP  # os botões "+" recebem o clique
	var fv := VBoxContainer.new()
	_ficha.add_child(fv)
	_ficha_texto = _rotulo("", 14, COR_TEXTO)
	fv.add_child(_ficha_texto)
	for a in Ficha.ATRIBUTOS:
		var linha_attr := HBoxContainer.new()
		fv.add_child(linha_attr)
		var botao := Button.new()
		botao.text = "+"
		botao.custom_minimum_size = Vector2(28, 24)
		botao.tooltip_text = "Colocar 1 ponto em " + Ficha.NOMES[a]
		botao.pressed.connect(func() -> void: jogador.pedir_atributo(a))
		linha_attr.add_child(botao)
		_ficha_botoes[a] = botao
		var rotulo_attr := _rotulo("", 14, COR_TEXTO)
		linha_attr.add_child(rotulo_attr)
		_ficha_atributos[a] = rotulo_attr
	_ficha_rodape = _rotulo("", 13, COR_TEXTO_2)
	fv.add_child(_ficha_rodape)

	# Dica de interação (segue o objeto sob o mouse)
	_dica = PanelContainer.new()
	_dica.add_theme_stylebox_override(&"panel", _caixa(Color("223b35"), Color("d1b67d"), 2))
	_dica.visible = false
	_dica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_dica)
	var dv := VBoxContainer.new()
	_dica.add_child(dv)
	_dica_texto = _rotulo("", 14, COR_TEXTO)
	_dica_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dv.add_child(_dica_texto)
	_dica_progresso = _barra(Color("e7b36e"), 5)
	dv.add_child(_dica_progresso)


## Um espaço da barra: ícone, sombra de recarga e o número da tecla.
func _slot(tecla: String) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(52, 52)
	slot.add_theme_stylebox_override(&"panel", _caixa(Color("354640"), Color("9c885e"), 2))
	var ic := TextureRect.new()
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.add_child(ic)
	var sombra_pai := Control.new()
	sombra_pai.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(sombra_pai)
	var sombra := ColorRect.new()
	sombra.color = Color(0, 0, 0, 0.6)
	sombra.set_anchors_preset(Control.PRESET_FULL_RECT)
	sombra.anchor_top = 1.0
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sombra_pai.add_child(sombra)
	slot.set_meta(&"sombra", sombra)
	var num := _rotulo(tecla, 11, COR_TEXTO_2)
	num.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	num.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	slot.add_child(num)
	return slot


func _barra(cor: Color, altura: int) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(0, altura)
	b.show_percentage = false
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_theme_stylebox_override(&"background", _caixa(Color("473e36"), Color.TRANSPARENT, 0))
	b.add_theme_stylebox_override(&"fill", _caixa(cor, Color.TRANSPARENT, 0))
	return b


func _painel(pai: Control) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override(&"panel", _caixa(COR_FUNDO, COR_BORDA, 2))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(p)
	return p


func _rotulo(texto: String, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override(&"font_size", tamanho)
	l.add_theme_color_override(&"font_color", cor)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _caixa(fundo: Color, borda: Color, largura_borda: int, borda_cima := -1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.border_color = borda
	s.set_border_width_all(largura_borda)
	if borda_cima >= 0:
		s.border_width_top = borda_cima
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s
