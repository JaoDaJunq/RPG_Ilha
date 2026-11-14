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
var _arvore: ArvoreTela
var _titulo_personagem: Label
var _retrato: TextureRect
var _barra_vida: ProgressBar
var _barra_mana: ProgressBar
## Escudo da Fé (e da Égide): aparece embaixo da vida só enquanto houver escudo.
var _barra_escudo: ProgressBar
var _linha_escudo: Control
var _barra_xp: ProgressBar
## Recurso da classe: Fúria (Guerreiro) ou pontos de combo (Ladino).
const ICONE_FURIA := preload("res://assets/sprites/tiny/icones/icone_furia.png")
const ICONE_COMBO := preload("res://assets/sprites/tiny/icones/icone_golpe_furtivo.png")
const COR_FURIA := Color("d07a3a")
const COR_COMBO := Color("e0c040")
var _linha_furia: HBoxContainer
var _barra_furia: ProgressBar
var _linha_combo: HBoxContainer
var _barra_combo: ProgressBar
var _aviso: Label
var _aviso_tempo := 0.0
var _tecla_e: Control
var _tecla_progresso: ProgressBar
var _slots: Array[Dictionary] = []  # {fundo, selecionado, icone, sombra}
var _slot_esquiva: Dictionary
var _carga: ProgressBar
var _ficha: FichaTela
var _nomes: Dictionary[int, Label] = {}  # id do jogador (instância) → nome em cima dele
var _dica: PanelContainer  # janelinha da habilidade (botão direito)
var _dica_slot: Control  # o botão em que ela está aberta
var _dica_titulo: Label
var _dica_descricao: Label
var _dica_numeros: Label
var _dica_efeitos: Label
var _dica_espera := 0  # quadros até o tamanho do painel assentar (autowrap) antes de mostrar

const TECLAS_HABILIDADE: Array[String] = ["Q", "R", "T", "E"]

# --- Vinheta vermelha (vida baixa e golpes) ---------------------------------------------
const VINHETA := preload("res://shaders/vinheta_dano.gdshader")
## Abaixo desta fração da vida as bordas da tela ficam vermelhas, e mais quanto menor a vida.
const VIDA_BAIXA := 0.4
const DURACAO_FLASH := 0.35
var _vinheta: ColorRect
var _vinheta_nivel := 0.0  # vida baixa, suavizado (0 a 1)
var _flash := 0.0  # sobra do clarão do último golpe (1 a 0)
var _pulso := 0.0
var _vida_vista := -1.0


func _ready() -> void:
	layer = 10
	Events.aviso.connect(mostrar_aviso)
	_montar()
	Configuracoes.mudou.connect(_atualizar_teclas)


func configurar(p: Player) -> void:
	jogador = p
	jogador.inventario.mudou.connect(_atualizar_itens)
	_mochila.configurar(p)
	_arvore.configurar(p, _mochila.aberta)
	_ficha.configurar(p, func() -> void:
		_ficha.visible = false
		_mochila.fechar()
		_arvore.abrir())
	jogador.vida.mudou.connect(func(atual: float, maximo: float) -> void: _barra_vida.value = atual / maximo * 100.0)
	jogador.progresso_mudou.connect(_atualizar_progresso)
	jogador.progresso_mudou.connect(_atualizar_slots)  # a árvore muda o que vai em Q R T E
	_montar_missoes()
	_vida_vista = jogador.vida.atual
	jogador.vida.mudou.connect(_ao_mudar_vida)
	jogador.aspecto_mudou.connect(_atualizar_aspecto)
	_atualizar_aspecto()
	_atualizar_itens()


## Raça, classe, rosto, pele ou roupas mudaram (criação do personagem, trocar de roupa):
## retrato, título e botões de habilidade acompanham. Sem HUD enquanto cria o personagem.
func _atualizar_aspecto() -> void:
	_retrato.texture = _retrato_de(jogador)
	_atualizar_slots()
	_atualizar_progresso()
	_raiz.visible = not jogador.criando


## Os botões Q R T E mostram as habilidades nas teclas (as da classe e as da árvore).
func _atualizar_slots() -> void:
	var hab := jogador.habilidades()
	for i in _slots.size():
		var tem := i < hab.size()
		_slots[i].icone.texture = hab[i].icone if tem else null
		_slots[i].fundo.tooltip_text = "Botão direito: detalhes" if tem else ""
		_slots[i].fundo.visible = tem  # teclas ainda sem habilidade somem


func mostrar_aviso(texto: String) -> void:
	_aviso.text = texto
	_aviso.modulate.a = 1.0
	_aviso_tempo = 4.0


func texto_aviso() -> String:
	return _aviso.text


func ficha_visivel() -> bool:
	return _ficha.visible


func arvore() -> ArvoreTela:
	return _arvore


## Clicou em qualquer lugar: a janelinha da habilidade fecha. (Clicar com o botão direito no
## mesmo botão é com ele: abre ou fecha.)
func _input(event: InputEvent) -> void:
	if not _dica.visible or not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_RIGHT and _dica_slot != null and _dica_slot.get_global_rect().has_point(event.position):
		return
	if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
		fechar_descricao()


## O Brasinha e as missões: balão de fala, painel das pedras de lore, diário (J) e o
## rastreador do canto. Só lê o que o anfitrião decidiu (Missoes).
var _balao: BalaoBrasinha
var _painel_lore: PainelLore
var _diario: MissoesTela
var _rastreador: RastreadorMissao


func _montar_missoes() -> void:
	var w := get_tree().get_first_node_in_group(&"mundo") as World
	if w == null or w.missoes == null or _diario != null:
		return
	_rastreador = RastreadorMissao.new()
	_raiz.add_child(_rastreador)
	_rastreador.configurar(w.missoes)
	_balao = BalaoBrasinha.new()
	_balao.name = "BalaoBrasinha"
	add_child(_balao)
	_balao.configurar(jogador, w.missoes)
	_painel_lore = PainelLore.new()
	_painel_lore.name = "PainelLore"
	add_child(_painel_lore)
	_painel_lore.configurar(w.missoes)
	_diario = MissoesTela.new()
	_diario.name = "Diario"
	add_child(_diario)
	_diario.configurar(w.missoes)


func balao() -> BalaoBrasinha:
	return _balao


func painel_lore() -> PainelLore:
	return _painel_lore


func diario() -> MissoesTela:
	return _diario


## O mapa da ilha (M).
func mapa() -> Mapa:
	if _mapa == null:
		_mapa = Mapa.new()
		_mapa.name = "Mapa"
		add_child(_mapa)
	return _mapa


var _mapa: Mapa


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"mapa") and jogador and not jogador.criando:
		mapa().alternar()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"missoes") and jogador and not jogador.criando and _diario:
		_diario.alternar()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel") and _mapa and _mapa.visible:
		_mapa.fechar()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel") and _dica.visible:
		fechar_descricao()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"mochila") and jogador and not jogador.criando:
		_arvore.fechar()
		_mochila.alternar()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"arvore") and jogador and not jogador.criando:
		_mochila.fechar()
		_ficha.visible = false
		_arvore.alternar()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel") and _mochila.aberta():
		_mochila.fechar()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ficha") and jogador:
		_ficha.atualizar()
		_ficha.visible = not _ficha.visible


func _process(delta: float) -> void:
	_aviso_tempo -= delta
	_aviso.visible = not _mochila.aberta()  # o rodapé da mochila fica no mesmo lugar
	if _aviso_tempo < 1.0:
		_aviso.modulate.a = clampf(_aviso_tempo, 0.0, 1.0)
	if _dica.visible:
		_posicionar_dica()
		if _dica_espera > 0:
			_dica_espera -= 1
			if _dica_espera == 0:
				_dica.modulate.a = 1.0
	if jogador == null or not is_instance_valid(jogador):
		return
	_atualizar_vinheta(delta)
	_barra_mana.value = jogador.mana / jogador.ficha.mana_maxima() * 100.0
	_linha_escudo.visible = jogador.vida.escudo > 0.0
	_barra_escudo.value = jogador.vida.escudo / maxf(jogador.vida.maximo, 1.0) * 100.0
	_atualizar_recurso()
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


# --- Descrição das habilidades (botão direito) --------------------------------------

## Liga o botão direito (e o mouse saindo) de um botão de habilidade: `indice` 0-3 é Q R T E, -1 é o dash.
func _ligar_descricao(fundo: Control, indice: int) -> void:
	fundo.gui_input.connect(func(evento: InputEvent) -> void:
		var b := evento as InputEventMouseButton
		if b == null or not b.pressed or b.button_index != MOUSE_BUTTON_RIGHT:
			return
		fundo.accept_event()
		if _dica.visible and _dica_slot == fundo:
			fechar_descricao()
		else:
			mostrar_descricao(indice))
	fundo.mouse_exited.connect(func() -> void:
		if _dica_slot == fundo:
			fechar_descricao())


## Abre a janelinha ao lado do botão: `indice` 0-3 é a habilidade Q R T E; -1, o dash (Shift).
func mostrar_descricao(indice: int) -> void:
	if jogador == null:
		return
	var hab := jogador.habilidades()
	var texto: Dictionary
	if indice < 0:
		texto = TextoHabilidade.de_esquiva(jogador.ficha, Configuracoes.tecla_de(&"esquivar"))
		_dica_slot = _slot_esquiva.fundo
	elif indice < hab.size():
		texto = TextoHabilidade.de_habilidade(hab[indice], Configuracoes.tecla_de(StringName("habilidade_%d" % (indice + 1))), jogador.ficha)
		_dica_slot = _slots[indice].fundo
	else:
		return
	_dica_titulo.text = texto.titulo
	_dica_descricao.text = texto.descricao
	var numeros: Array[String] = [texto.mana, texto.recarga]
	_dica_numeros.text = "  ·  ".join(numeros) + ("\n" + texto.dano if texto.dano != "" else "")
	if texto.get("conjuracao", "") != "":
		_dica_numeros.text += "\n" + texto.conjuracao
	var linhas: Array[String] = []
	for e in texto.efeitos:
		linhas.append("• " + e)
	_dica_efeitos.text = "\n".join(linhas)
	_dica_efeitos.visible = not linhas.is_empty()
	# O texto quebra em linhas e o painel só acha o tamanho certo depois de alguns quadros:
	# fica invisível até lá, para não piscar no lugar errado.
	_dica.modulate.a = 0.0
	_dica.visible = true
	_dica.reset_size()
	_dica_espera = 3


func fechar_descricao() -> void:
	_dica.visible = false
	_dica_slot = null


## Título da janelinha aberta (vazio se está fechada).
func descricao_aberta() -> String:
	return _dica_titulo.text if _dica.visible else ""


func _posicionar_dica() -> void:
	if _dica_slot == null or not is_instance_valid(_dica_slot):
		return
	_dica.reset_size()
	var alvo := _dica_slot.get_global_rect()
	var x := alvo.position.x + alvo.size.x / 2.0 - _dica.size.x / 2.0
	x = clampf(x, 8.0, maxf(8.0, _raiz.size.x - _dica.size.x - 8.0))
	_dica.position = Vector2(x, alvo.position.y - _dica.size.y - 8.0).round()


## A teclinha E aparece em cima da árvore/pedra só quando dá para coletar.
func _atualizar_tecla_e() -> void:
	# Aliado caído perto: "segure E" em cima dele, com a barrinha de quanto falta para levantar.
	var caido := jogador.aliado_caido_perto() if not jogador.caido else null
	if caido:
		_tecla_e.visible = true
		_dica_alvo.text = "segure E"
		_tecla_progresso.visible = jogador.ajudando() != null
		_tecla_progresso.value = jogador.progresso_interacao() * 100.0
		var acima := get_viewport().get_canvas_transform() * (caido.global_position - Vector2(0, 20))
		_tecla_e.position = (acima - Vector2(_tecla_e.size.x / 2.0, _tecla_e.size.y)).round()
		return
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
	var vistos: Array[int] = []
	for p in get_tree().get_nodes_in_group(&"jogadores"):
		if p == jogador or (p as Player).ficha == null or (p as Player).criando:
			continue
		vistos.append(p.get_instance_id())
		if not _nomes.has(p.get_instance_id()):
			var l := _rotulo("", 16)
			_raiz.add_child(l)
			_nomes[p.get_instance_id()] = l
		var rotulo := _nomes[p.get_instance_id()]
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


## A ficha do personagem (C).
func ficha() -> FichaTela:
	return _ficha


func _atualizar_progresso() -> void:
	if jogador == null:
		return
	var f := jogador.ficha
	_titulo_personagem.text = "Nv %d · %s" % [jogador.nivel, f.titulo()]
	_barra_xp.value = 100.0 * jogador.xp / maxf(jogador.xp_para_subir(), 1.0)
	_barra_xp.tooltip_text = "Experiência %d / %d" % [jogador.xp, jogador.xp_para_subir()]


# --- Vinheta vermelha ---------------------------------------------------------------

## Tela cheia por trás da interface, só com efeito de shader (não pega o mouse).
func _montar_vinheta() -> void:
	_vinheta = ColorRect.new()
	_vinheta.name = "Vinheta"
	_vinheta.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vinheta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vinheta.visible = false
	var m := ShaderMaterial.new()
	m.shader = VINHETA
	_vinheta.material = m
	_raiz.add_child(_vinheta)


## Cada perda de vida dá um clarão vermelho nas bordas.
func _ao_mudar_vida(atual: float, _maximo: float) -> void:
	if _vida_vista >= 0.0 and atual < _vida_vista:
		_flash = 1.0
	_vida_vista = atual


## 0 a 1: o quanto as bordas estão vermelhas agora (vida baixa com pulso, mais o clarão do golpe).
func vinheta_intensidade() -> float:
	if _vinheta == null:
		return 0.0
	return (_vinheta.material as ShaderMaterial).get_shader_parameter("intensidade")


func vinheta_visivel() -> bool:
	return _vinheta != null and _vinheta.visible


func _atualizar_vinheta(delta: float) -> void:
	var fracao := jogador.vida.atual / maxf(jogador.vida.maximo, 1.0)
	# Sem vermelho com a vida acima de 40%; abaixo, entra aos poucos e cresce até o máximo.
	var falta := clampf((VIDA_BAIXA - fracao) / VIDA_BAIXA, 0.0, 1.0)
	var entrada := clampf((VIDA_BAIXA - fracao) / 0.05, 0.0, 1.0)
	var meta := entrada * (0.45 + 0.5 * falta)
	_vinheta_nivel = lerpf(_vinheta_nivel, meta, 1.0 - exp(-6.0 * delta))
	if _vinheta_nivel < 0.002 and meta == 0.0:
		_vinheta_nivel = 0.0
	# O pulso (batimento) fica mais rápido e mais fundo quanto menor a vida.
	_pulso += delta * (3.0 + 4.0 * falta)
	var pulsado := _vinheta_nivel * (1.0 - 0.18 * falta * (0.5 + 0.5 * sin(_pulso)) - 0.05)
	_flash = maxf(0.0, _flash - delta / DURACAO_FLASH)
	var total := clampf(pulsado + _flash * _flash * 0.65, 0.0, 1.0)
	_vinheta.visible = total > 0.01
	(_vinheta.material as ShaderMaterial).set_shader_parameter("intensidade", total)


# --- Montagem -----------------------------------------------------------------

func _montar() -> void:
	_raiz = Control.new()
	_raiz.theme = Tema.tema()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)
	_montar_vinheta()

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
	_barra_escudo = _barra(Color("f2e6a8"), 14, true)
	_linha_escudo = _linha_com_icone(preload("res://assets/sprites/tiny/icones/icone_escudo_sagrado.png"), _barra_escudo)
	_linha_escudo.visible = false
	pv.add_child(_linha_escudo)
	_barra_mana = _barra(Color("4a86d0"), 20, true)
	_barra_mana.value = 100.0
	pv.add_child(_linha_com_icone(ICONES_ATRIBUTO[&"espirito"], _barra_mana))
	# Recurso da classe (Fúria do Guerreiro ou combo do Ladino): só aparece para essas classes.
	_barra_furia = _barra(COR_FURIA, 16, true)
	_linha_furia = _linha_com_icone(ICONE_FURIA, _barra_furia)
	_linha_furia.visible = false
	pv.add_child(_linha_furia)
	_barra_combo = _barra(COR_COMBO, 16, true)
	_linha_combo = _linha_com_icone(ICONE_COMBO, _barra_combo)
	_linha_combo.visible = false
	pv.add_child(_linha_combo)
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
		var s := _slot(Configuracoes.tecla_de(StringName("barra_%d" % (k + 1))))
		s.acao = StringName("barra_%d" % (k + 1))
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
	# Dash e habilidades recebem o mouse (STOP): o botão direito abre a descrição e não vira
	# "usar item" no mundo.
	_slot_esquiva = _slot(Configuracoes.tecla_de(&"esquivar"), true)
	_slot_esquiva.acao = &"esquivar"
	_slot_esquiva.icone.texture = ICONE_ESQUIVA
	_slot_esquiva.fundo.tooltip_text = "Botão direito: detalhes"
	_ligar_descricao(_slot_esquiva.fundo, -1)
	barra.add_child(_slot_esquiva.fundo)
	for i in TECLAS_HABILIDADE.size():
		var s := _slot(Configuracoes.tecla_de(StringName("habilidade_%d" % (i + 1))), true)
		s.acao = StringName("habilidade_%d" % (i + 1))
		_ligar_descricao(s.fundo, i)
		barra.add_child(s.fundo)
		_slots.append(s)

	_mochila = Mochila.new()
	_raiz.add_child(_mochila)
	_arvore = ArvoreTela.new()
	_raiz.add_child(_arvore)

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

	# Ficha (C): ver FichaTela.
	# Fica por cima do painel do personagem (ela tem o retrato, o nível e a experiência).
	_ficha = FichaTela.new()
	_ficha.position = Vector2(12, 10)
	_ficha.visible = false
	_raiz.add_child(_ficha)

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

	# Janelinha da habilidade (botão direito no botão dela). Por último: fica por cima de tudo.
	_dica = _painel()
	_dica.visible = false
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override(&"separation", 6)
	_dica.add_child(dv)
	_dica_titulo = _rotulo("", 18, Tema.COR_DESTAQUE)
	dv.add_child(_dica_titulo)
	_dica_descricao = _rotulo("", 16)
	_dica_numeros = _rotulo("", 16, COR_TEXTO_2)
	_dica_efeitos = _rotulo("", 16, COR_TEXTO_2)
	for l in [_dica_descricao, _dica_numeros, _dica_efeitos]:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(330, 0)
		dv.add_child(l)



## Os nomes das teclas na barra de baixo seguem o que o jogador escolheu nas configurações.
func _atualizar_teclas() -> void:
	for s in _itens_barra + _slots + [_slot_esquiva]:
		if s.has("acao") and s.acao != &"":
			s.rotulo.text = Configuracoes.tecla_de(s.acao)


## Um espaço da barra (quadradinho azul do pacote): fundo, ícone, sombra de recarga e
## tecla. O selecionado (carregando) ganha uma borda dourada.
func _slot(tecla: String, parar_mouse := false) -> Dictionary:
	var fundo := Panel.new()
	fundo.add_theme_stylebox_override(&"panel", Tema.espaco())
	fundo.custom_minimum_size = Vector2(64, 64)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP if parar_mouse else Control.MOUSE_FILTER_PASS
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
	return {fundo = fundo, selecionado = selecionado, icone = icone, sombra = sombra, rotulo = num, acao = &""}


## Fúria (0 a 100) ou combo (0 a 5) do jogador, na barra embaixo da mana.
func _atualizar_recurso() -> void:
	var r := jogador.recursos
	_linha_furia.visible = r != null and r.usa_furia()
	_linha_combo.visible = r != null and r.usa_combo()
	if _linha_furia.visible:
		_barra_furia.value = r.furia / RecursosClasse.FURIA_MAXIMA * 100.0
		_barra_furia.tooltip_text = "Fúria %d / %d" % [roundi(r.furia), roundi(RecursosClasse.FURIA_MAXIMA)]
	if _linha_combo.visible:
		_barra_combo.value = 100.0 * r.combo / RecursosClasse.COMBO_MAXIMO
		_barra_combo.tooltip_text = "Pontos de combo %d / %d" % [r.combo, RecursosClasse.COMBO_MAXIMO]


## A barra visível do recurso da classe (Fúria ou combo; nula para as outras classes), para
## os testes. Valor de 0 a 100.
func barra_recurso() -> ProgressBar:
	if _linha_furia.visible:
		return _barra_furia
	return _barra_combo if _linha_combo.visible else null


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


## Barra de valor. Com `moldura`, usa a barra de vida do pacote: a moldura é desenhada
## inteira e a cor preenche só o miolo escuro dela.
func _barra(cor: Color, altura: int, moldura := false) -> ProgressBar:
	if moldura:
		return Tema.barra_com_moldura(cor, altura)
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(0, altura)
	b.show_percentage = false
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color("2a2a22")
	fundo.border_color = Color("0e100d")
	fundo.set_border_width_all(1)
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = cor
	b.add_theme_stylebox_override(&"background", fundo)
	b.add_theme_stylebox_override(&"fill", cheio)
	return b


## Retrato: a cabeça do boneco, com a raça, o rosto e as roupas que ele veste agora.
func _retrato_de(p: Player) -> Texture2D:
	return Boneco.retrato(p.aparencia_completa(), p.equipado)


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
