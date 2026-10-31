class_name Pausa
extends CanvasLayer
## Menu de pausa do mundo (Esc): continuar, configurações e sair para a Home.
## Sair salva o mundo antes (World.sair_para_o_menu). Jogando sozinho o jogo congela; no
## multijogador ele segue rodando, porque os amigos continuam na ilha.

var _mundo: World
var _raiz: Control
var _principal: Control
var _config: TelaConfiguracoes
var _continuar: Button
var _sair: Button
var _confirmando := false


func _init(mundo: World = null) -> void:
	_mundo = mundo


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_raiz = Control.new()
	_raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.theme = Tema.tema()
	add_child(_raiz)
	var escuro := ColorRect.new()
	escuro.color = Color(0.02, 0.04, 0.08, 0.6)
	escuro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(escuro)
	_principal = CenterContainer.new()
	_principal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(_principal)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override(&"separation", -14)
	_principal.add_child(coluna)
	var fita := Pecas.fita("Pausa")
	fita.custom_minimum_size.x = 360
	fita.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	fita.z_index = 1
	coluna.add_child(fita)
	var painel := Pecas.painel(460)
	coluna.add_child(painel)
	var p := Pecas.coluna_de(painel)
	p.add_theme_constant_override(&"separation", 14)
	var solo := Net.modo == Net.Modo.SOLO
	p.add_child(Pecas.rotulo("O jogo está pausado." if solo else "Os amigos continuam jogando.", 18, Tema.COR_TEXTO_2, true))
	_continuar = Pecas.botao("Continuar", &"BotaoGrande", 0.0)
	_continuar.pressed.connect(fechar)
	p.add_child(_continuar)
	var config := Pecas.botao("Configurações", &"BotaoGrande", 0.0)
	config.pressed.connect(_abrir_config)
	p.add_child(config)
	_sair = Pecas.botao("Sair para o menu", &"BotaoVermelho", 0.0)
	_sair.pressed.connect(_sair_pressionado)
	p.add_child(_sair)
	if Net.modo != Net.Modo.ENTRAR:
		p.add_child(Pecas.rotulo("O mundo é salvo ao sair.", 15, Tema.COR_TEXTO_2, true))


func aberta() -> bool:
	return visible


func abrir() -> void:
	_fechar_config()
	_confirmando = false
	_sair.text = "Sair para o menu"
	visible = true
	if Net.modo == Net.Modo.SOLO:
		get_tree().paused = true
	_continuar.grab_focus()


func fechar() -> void:
	_fechar_config()
	visible = false
	get_tree().paused = false


func _exit_tree() -> void:
	if is_inside_tree():
		get_tree().paused = false


func _sair_pressionado() -> void:
	if not _confirmando:
		_confirmando = true
		_sair.text = "Salvar e sair?"
		get_tree().create_timer(3.0, true, false, true).timeout.connect(func() -> void:
			if is_instance_valid(_sair) and _confirmando:
				_confirmando = false
				_sair.text = "Sair para o menu")
		return
	get_tree().paused = false
	visible = false
	if _mundo:
		_mundo.sair_para_o_menu()


func _abrir_config() -> void:
	_principal.visible = false
	_config = TelaConfiguracoes.new()
	_config.fechar.connect(_fechar_config)
	_raiz.add_child(_config)
	_config.focar()


func _fechar_config() -> void:
	if _config == null:
		return
	_config.queue_free()
	_config = null
	_principal.visible = true
	if is_inside_tree() and visible:
		_continuar.grab_focus.call_deferred()


## Esc: abre a pausa, ou volta um passo (configurações → pausa → jogo). O HUD, que está
## na frente, já usa o Esc para fechar a mochila e a janelinha das habilidades.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if _config != null:
		_fechar_config()
	elif visible:
		fechar()
	else:
		abrir()
