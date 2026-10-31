class_name Hud
extends CanvasLayer
## Interface do jogo (estilo Tiny Swords, ver Tema): painel do personagem (nível, vida, mana, experiência),
## recursos, barra de habilidades, avisos, ficha (C), nomes dos outros jogadores e a
## teclinha E em cima do que dá para coletar quando o jogador está perto.

const ICONE_ESQUIVA := preload("res://assets/sprites/tiny/icones/icone_esquiva.png")
const ICONES_ATRIBUTO := {
	&"forca": preload("res://assets/sprites/tiny/icones/icone_forca.png"),
	&"vitalidade": preload("res://assets/sprites/tiny/icones/icone_vitalidade.png"),
	&"agilidade": preload("res://assets/sprites/tiny/icones/icone_agilidade.png"),
	&"intelecto": preload("res://assets/sprites/tiny/icones/icone_intelecto.png"),
	&"espirito": preload("res://assets/sprites/tiny/icones/icone_espirito.png"),
}
const ICONE_XP := preload("res://assets/sprites/tiny/icones/icone_experiencia.png")
var _dica_alvo: Label
const COR_TEXTO := Tema.COR_TEXTO
const COR_TEXTO_2 := Tema.COR_TEXTO_2

var jogador: Player
var _raiz: Control
var _itens_barra: Array[Dictionary] = []  # {fundo, selecionado, icone, sombra, qtd}
var _mochila: Mochila
var _titulo_personagem: Label
var _retrato: TextureRect
var _barra_vida: ProgressBar
var _barra_mana: ProgressBar
var _barra_xp: ProgressBar
var _aviso: Label
var _aviso_tempo := 0.0
var _tecla_e: Control
var _tecla_progresso: ProgressBar
var _slots: Array[Dictionary] = []  # {fundo, selecionado, icone, sombra}
var _slot_esquiva: Dictionary
var _carga: ProgressBar
var _ficha: PanelContainer
var _ficha_texto: Label
var _ficha_rodape: Label
var _ficha_atributos: Dictionary[StringName, Label] = {}
var _ficha_botoes: Dictionary[StringName, Button] = {}
var _nomes: Dictionary[Node, Label] = {}


func _ready() -> void:
	layer = 10
	Events.aviso.connect(mostrar_aviso)
	_montar()


func configurar(p: Player) -> void:
	jogador = p
	jogador.inventario.mudou.connect(_atualizar_itens)
	_mochila.configurar(p)
	jogador.vida.mudou.connect(func(atual: float, maximo: float) -> void: _barra_vida.value = atual / maximo * 100.0)
	jogador.progresso_mudou.connect(_atualizar_progresso)
	_retrato.texture = _retrato_de(p)
	var hab := jogador.habilidades()
	for i in _slots.size():
		var tem := i < hab.size()
		_slots[i].icone.texture = hab[i].icone if tem else null
		_slots[i].fundo.tooltip_text = ("%s · %d de mana\n%s" % [hab[i].nome, hab[i].custo_mana, hab[i].descricao]) if tem else ""
		_slots[i].fundo.visible = tem  # classe com 2 habilidades: F e G somem
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
	if event.is_action_pressed(&"mochila") and jogador:
		_mochila.alternar()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel") and _mochila.aberta():
		_mochila.fechar()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ficha") and jogador:
		_atualizar_progresso()
		_ficha.visible = not _ficha.visible


func _process(delta: float) -> void:
	_aviso_tempo -= delta
	if _aviso_tempo < 1.0:
		_aviso.modulate.a = clampf(_aviso_tempo, 0.0, 1.0)
	if jogador == null or not is_instance_valid(jogador):
		return
	_barra_mana.value = jogador.mana / jogador.ficha.mana_maxima() * 100.0
	var carga := jogador.carga_atual()
	for i in _slots.size():
		_slots[i].sombra.anchor_top = 1.0 - jogador.recarga_restante(i)
		_slots[i].selecionado.visible = jogador._carregando == i
	_slot_esquiva.sombra.anchor_top = 1.0 - jogador.recarga_esquiva_restante()
	for k in _itens_barra.size():
		_itens_barra[k].selecionado.visible = k == jogador.barra_escolhida
	_carga.visible = carga >= 0.0
	_carga.value = carga * 100.0
	_atualizar_tecla_e()
	_atualizar_nomes()


## A teclinha E aparece em cima da árvore/pedra só quando dá para coletar.
func _atualizar_tecla_e() -> void:
	var alvo := jogador.alvo
	if alvo == null or not is_instance_valid(alvo) or not jogador.alvo_ao_alcance():
		_tecla_e.visible = false
		return
	_tecla_e.visible = true
	_dica_alvo.text = "segure" if alvo.dono() is ResourceNode else "clique"
	_tecla_progresso.visible = jogador.progresso_interacao() > 0.0
	_tecla_progresso.value = jogador.progresso_interacao() * 100.0
	var dono := alvo.dono()
	var altura: float = dono.altura_visivel() if dono.has_method(&"altura_visivel") else 48.0
	var tela := get_viewport().get_canvas_transform() * (alvo.global_position - Vector2(0, altura + 4.0))
	_tecla_e.position = (tela - Vector2(_tecla_e.size.x / 2.0, _tecla_e.size.y)).round()


## Nome (nível, raça e classe) em cima dos outros jogadores.
func _atualizar_nomes() -> void:
	var vistos: Array[Node] = []
	for p in get_tree().get_nodes_in_group(&"jogadores"):
		if p == jogador or (p as Player).ficha == null:
			continue
		vistos.append(p)
		if not _nomes.has(p):
			var l := _rotulo("", 16)
			_raiz.add_child(l)
			_nomes[p] = l
		var rotulo := _nomes[p]
		rotulo.text = "Nv %d · %s" % [(p as Player).nivel, (p as Player).ficha.titulo()]
		var tela := get_viewport().get_canvas_transform() * ((p as Node2D).global_position + Vector2(0, -40))
		rotulo.position = (tela - Vector2(rotulo.size.x / 2.0, rotulo.size.y)).round()
	for p in _nomes.keys():
		if not p in vistos:
			_nomes[p].queue_free()
			_nomes.erase(p)


## A barra de itens mostra os espaços 0-8 do inventário.
func _atualizar_itens() -> void:
	var inv := jogador.inventario
	for k in _itens_barra.size():
		var id := inv.item_em(k)
		var dados := ItemData.carregar(id) if ItemData.existe(id) else null
		_itens_barra[k].icone.texture = dados.icone if dados else null
		_itens_barra[k].qtd.text = str(inv.qtd_em(k)) if inv.qtd_em(k) > 1 else ""
		_itens_barra[k].fundo.tooltip_text = dados.nome if dados else ""


func _texto_ficha() -> String:
	var f := jogador.ficha
	return "%s\nNível %d · %s\nRamos: %s e %s" % [
		f.titulo().to_upper(), jogador.nivel, f.classe.familia, f.classe.ramo_a, f.classe.ramo_b]


func _rodape_ficha() -> String:
	var f := jogador.ficha
	return "\n".join([
		"Pontos para distribuir: %d" % jogador.pontos_atributo,
		"Pontos de habilidade: %d (árvore em breve)" % jogador.pontos_habilidade,
		"Vida %d · Mana %d · Velocidade %d" % [f.vida_maxima(), f.mana_maxima(), f.velocidade()],
		"Dano físico x%.1f · mágico x%.1f" % [f.multiplicador_fisico(), f.multiplicador_magico()],
		"%s: %s" % [f.raca.habilidade_nome, f.raca.habilidade_descricao],
		"",
		"WASD andar · clique abre, segurar coleta e golpeia · Shift dash",
		"Q R T E habilidades · 1-9 itens · I mochila · C ficha · N dia/noite",
	])


func _atualizar_progresso() -> void:
	if jogador == null:
		return
	var f := jogador.ficha
	_titulo_personagem.text = "Nv %d · %s" % [jogador.nivel, f.titulo()]
	_barra_xp.value = 100.0 * jogador.xp / maxf(jogador.xp_para_subir(), 1.0)
	_barra_xp.tooltip_text = "Experiência %d / %d" % [jogador.xp, jogador.xp_para_subir()]
	_ficha_texto.text = _texto_ficha()
	_ficha_rodape.text = _rodape_ficha()
	for a in Ficha.ATRIBUTOS:
		var bonus: int = f.raca.bonus.get(a, 0)
		var pontos: int = jogador.distribuidos.get(a, 0)
		var extras: Array[String] = []
		if bonus != 0:
			extras.append("raça %+d" % bonus)
		if pontos > 0:
			extras.append("+%d" % pontos)
		_ficha_atributos[a].text = "%s %d %s" % [Ficha.NOMES[a], f.valor(a), ("(" + ", ".join(extras) + ")") if not extras.is_empty() else ""]
		_ficha_botoes[a].visible = jogador.pontos_atributo > 0


# --- Montagem -----------------------------------------------------------------

func _montar() -> void:
	_raiz = Control.new()
	_raiz.theme = Tema.tema()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)

	# Personagem: retrato, nível, vida, mana e experiência (cima-esquerda).
	var pers := _painel()
	pers.position = Vector2(12, 10)
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override(&"separation", 8)
	pers.add_child(ph)
	_retrato = TextureRect.new()
	_retrato.custom_minimum_size = Vector2(64, 64)
	_retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_retrato.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_retrato.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # retrato de 256 px reduzido a 64
	ph.add_child(_retrato)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override(&"separation", 2)
	ph.add_child(pv)
	_titulo_personagem = _rotulo("", 16)
	pv.add_child(_titulo_personagem)
	_barra_vida = _barra(Color("d0564a"), 22, true)
	_barra_vida.value = 100.0
	pv.add_child(_linha_com_icone(ICONES_ATRIBUTO[&"vitalidade"], _barra_vida))
	_barra_mana = _barra(Color("4a86d0"), 20, true)
	_barra_mana.value = 100.0
	pv.add_child(_linha_com_icone(ICONES_ATRIBUTO[&"espirito"], _barra_mana))
	_barra_xp = _barra(Color("e7c46e"), 18, true)
	pv.add_child(_linha_com_icone(ICONE_XP, _barra_xp))
	pv.add_child(_rotulo("C · ficha", 16, COR_TEXTO_2))

	# Barra de baixo, no centro: os 9 itens (teclas 1-9, como no Minecraft) e, ao lado,
	# o dash (Shift) e as habilidades da classe (Q, R, T, E).
	var barra := HBoxContainer.new()
	barra.add_theme_constant_override(&"separation", 4)
	barra.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 10)
	barra.grow_horizontal = Control.GROW_DIRECTION_BOTH
	barra.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_raiz.add_child(barra)
	for k in Inventory.BARRA:
		var s := _slot(str(k + 1))
		var qtd := _rotulo("", 14)
		qtd.set_anchors_preset(Control.PRESET_FULL_RECT)
		qtd.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		qtd.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		qtd.offset_right = -6
		qtd.offset_bottom = -3
		s.fundo.add_child(qtd)
		s.qtd = qtd
		barra.add_child(s.fundo)
		_itens_barra.append(s)
	var folga := Control.new()
	folga.custom_minimum_size = Vector2(14, 0)
	barra.add_child(folga)
	_slot_esquiva = _slot("Shift")
	_slot_esquiva.icone.texture = ICONE_ESQUIVA
	barra.add_child(_slot_esquiva.fundo)
	for tecla in ["Q", "R", "T", "E"]:
		var s := _slot(tecla)
		barra.add_child(s.fundo)
		_slots.append(s)

	_mochila = Mochila.new()
	_raiz.add_child(_mochila)

	# Aviso e carga, logo acima da barra.
	_aviso = _rotulo("", 16)
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_aviso.offset_left = -420
	_aviso.offset_right = 420
	_aviso.offset_top = -136
	_aviso.offset_bottom = -110
	_raiz.add_child(_aviso)
	_carga = _barra(Color("f0c860"), 8)
	_carga.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_carga.offset_left = -90
	_carga.offset_right = 90
	_carga.offset_top = -102
	_carga.offset_bottom = -94
	_carga.visible = false
	_raiz.add_child(_carga)

	# Ficha (C).
	_ficha = _painel()
	_ficha.position = Vector2(12, 168)
	_ficha.visible = false
	_ficha.mouse_filter = Control.MOUSE_FILTER_STOP  # os botões "+" recebem o clique
	var fv := VBoxContainer.new()
	fv.add_theme_constant_override(&"separation", 4)
	_ficha.add_child(fv)
	_ficha_texto = _rotulo("", 16)
	fv.add_child(_ficha_texto)
	for a in Ficha.ATRIBUTOS:
		var la := HBoxContainer.new()
		la.add_theme_constant_override(&"separation", 8)
		fv.add_child(la)
		la.add_child(_icone(ICONES_ATRIBUTO[a], Vector2(40, 36)))
		var r := _rotulo("", 16)
		r.custom_minimum_size = Vector2(230, 0)
		la.add_child(r)
		_ficha_atributos[a] = r
		var botao := Button.new()
		botao.text = "+"
		botao.custom_minimum_size = Vector2(28, 26)
		for estado in [&"normal", &"hover", &"pressed"]:
			botao.add_theme_stylebox_override(estado, _caixinha(estado != &"normal"))
		botao.tooltip_text = "Colocar 1 ponto em " + Ficha.NOMES[a]
		botao.pressed.connect(func() -> void: jogador.pedir_atributo(a))
		la.add_child(botao)
		_ficha_botoes[a] = botao
	_ficha_rodape = _rotulo("", 16, COR_TEXTO_2)
	_ficha_rodape.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ficha_rodape.custom_minimum_size = Vector2(330, 0)
	fv.add_child(_ficha_rodape)

	# Teclinha E (segue o objeto quando dá para coletar).
	_tecla_e = VBoxContainer.new()
	_tecla_e.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tecla_e.visible = false
	_raiz.add_child(_tecla_e)
	# Em cima do alvo: "segure" (árvore, pedra) ou "clique" (baú, bancada); o E virou habilidade.
	_dica_alvo = _rotulo("", 14)
	_dica_alvo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dica_alvo.custom_minimum_size = Vector2(60, 0)
	_tecla_e.add_child(_dica_alvo)
	_tecla_progresso = _barra(Color("f0c860"), 4)
	_tecla_progresso.custom_minimum_size = Vector2(60, 4)
	_tecla_e.add_child(_tecla_progresso)


## Um espaço da barra (quadradinho azul do pacote): fundo, ícone, sombra de recarga e
## tecla. O selecionado (carregando) ganha uma borda dourada.
func _slot(tecla: String) -> Dictionary:
	var fundo := Panel.new()
	fundo.add_theme_stylebox_override(&"panel", Tema.espaco())
	fundo.custom_minimum_size = Vector2(64, 64)
	fundo.mouse_filter = Control.MOUSE_FILTER_PASS
	var selecionado := Panel.new()
	var borda := StyleBoxFlat.new()
	borda.draw_center = false
	borda.border_color = Tema.COR_DESTAQUE
	borda.set_border_width_all(3)
	borda.set_corner_radius_all(6)
	selecionado.add_theme_stylebox_override(&"panel", borda)
	selecionado.position = Vector2(-3, -3)
	selecionado.size = Vector2(70, 70)
	selecionado.visible = false
	selecionado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.add_child(selecionado)
	var icone := TextureRect.new()
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED  # tamanho real: pixel nítido
	icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icone.position = Vector2(8, 8)
	icone.size = Vector2(48, 48)
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.add_child(icone)
	var area := Control.new()
	area.position = Vector2(6, 6)
	area.size = Vector2(52, 52)
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.add_child(area)
	var sombra := ColorRect.new()
	sombra.color = Color(0, 0, 0, 0.6)
	sombra.set_anchors_preset(Control.PRESET_FULL_RECT)
	sombra.anchor_top = 1.0
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(sombra)
	var num := _rotulo(tecla, 14, COR_TEXTO_2)
	num.position = Vector2(7, 2)
	fundo.add_child(num)
	return {fundo = fundo, selecionado = selecionado, icone = icone, sombra = sombra}


func _linha_com_icone(icone: Texture2D, barra: ProgressBar) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override(&"separation", 6)
	h.add_child(_icone(icone, Vector2(36, 30)))
	barra.custom_minimum_size.x = 200
	barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(barra)
	return h


func _icone(textura: Texture2D, tamanho: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = textura
	t.custom_minimum_size = tamanho
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED  # ícones no tamanho real (pixel do pacote), sem esticar
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## Botãozinho "+" da ficha: quadradinho com borda dourada.
func _caixinha(destaque: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("6b4a2a") if destaque else Color("4a3220")
	s.border_color = Color("f0c860") if destaque else Color("b48a3a")
	s.set_border_width_all(2)
	return s


## Barra de valor. Com `moldura`, usa a barra de vida do pacote: a moldura é desenhada
## inteira e a cor preenche só o miolo escuro dela.
func _barra(cor: Color, altura: int, moldura := false) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(0, altura)
	b.show_percentage = false
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	if moldura:
		var vazio := StyleBoxEmpty.new()
		b.add_theme_stylebox_override(&"background", vazio)
		b.add_theme_stylebox_override(&"fill", vazio)
		var caixa := Tema.moldura_barra()
		b.draw.connect(func() -> void:
			b.draw_style_box(caixa, Rect2(Vector2.ZERO, b.size))
			var cima := roundf(b.size.y * 0.24)
			var baixo := roundf(b.size.y * 0.32)
			var miolo := Rect2(7, cima, (b.size.x - 14) * b.ratio, b.size.y - cima - baixo)
			if miolo.size.x > 0.0:
				b.draw_rect(miolo, cor))
		return b
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color("2a2a22")
	fundo.border_color = Color("0e100d")
	fundo.set_border_width_all(1)
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = cor
	b.add_theme_stylebox_override(&"background", fundo)
	b.add_theme_stylebox_override(&"fill", cheio)
	return b


## Retrato: a cabeça do boneco (L19).
func _retrato_de(p: Player) -> Texture2D:
	return load(Boneco.PASTA + "%s_%s/cabeca.png" % [p.raca, p.classe])


func _painel() -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(p)
	return p


func _rotulo(texto: String, tamanho: int, cor := COR_TEXTO) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override(&"font_size", tamanho)
	l.add_theme_color_override(&"font_color", cor)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
