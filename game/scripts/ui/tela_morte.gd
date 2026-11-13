class_name TelaMorte
extends CanvasLayer
## Tela de morte: só na máquina de quem caiu (Player._caido_sync abre e fecha). Escurece a
## tela, mostra "Você caiu!", a contagem até voltar sozinho no acampamento e o botão
## "Reviver agora", que só fica clicável depois de Player.TEMPO_BOTAO segundos. Quem decide
## é o anfitrião: o botão só pede (Player.pedir_reviver). Os outros veem só o boneco caído.

const ESCURO := Color(0.02, 0.03, 0.06, 0.62)
const TEMPO_ESCURECER := 0.6

var _jogador: Player
var _escuro: ColorRect
var _contagem: Label
var _botao: Button


func _init(jogador: Player = null) -> void:
	_jogador = jogador


func _ready() -> void:
	layer = 15  # em cima do HUD, embaixo da pausa
	var raiz := Control.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.theme = Tema.tema()
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)
	_escuro = ColorRect.new()
	_escuro.color = ESCURO
	_escuro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_escuro.mouse_filter = Control.MOUSE_FILTER_STOP  # o clique não vira golpe no mundo
	raiz.add_child(_escuro)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(centro)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override(&"separation", -14)
	centro.add_child(coluna)
	var fita := Pecas.fita("Você caiu!", 1, 1.0, 54)  # fita vermelha, grande
	fita.custom_minimum_size.x = 480
	fita.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	fita.z_index = 1
	coluna.add_child(fita)
	var painel := Pecas.painel(440)
	painel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	coluna.add_child(painel)
	var p := Pecas.coluna_de(painel)
	p.add_theme_constant_override(&"separation", 12)
	p.add_child(Pecas.rotulo("Você volta no acampamento em", 18, Tema.COR_TEXTO_2, true))
	_contagem = Pecas.rotulo("8", 64, Tema.COR_DESTAQUE, true)
	p.add_child(_contagem)
	_botao = Pecas.botao("Reviver agora", &"BotaoGrande", 0.0)
	_botao.pressed.connect(_reviver_agora)
	p.add_child(_botao)
	p.add_child(Pecas.rotulo("Um aliado pode te levantar aqui: segurando E perto de você.", 15, Tema.COR_TEXTO_2, true))
	# Entra escurecendo devagar.
	raiz.modulate.a = 0.0
	create_tween().tween_property(raiz, "modulate:a", 1.0, TEMPO_ESCURECER)
	_atualizar()


func _process(_delta: float) -> void:
	_atualizar()


func _atualizar() -> void:
	if _jogador == null or not is_instance_valid(_jogador):
		return
	_contagem.text = str(segundos_na_tela())
	var liberado := _jogador.pode_reviver_agora()
	_botao.disabled = not liberado
	var falta := ceili(maxf(0.0, Player.TEMPO_BOTAO - _jogador.tempo_caido))
	_botao.text = "Reviver agora" if liberado else "Reviver agora (%d)" % falta


## O número grande da contagem (segundos inteiros que faltam, arredondados para cima).
func segundos_na_tela() -> int:
	return ceili(_jogador.falta_reviver()) if _jogador else 0


func botao_liberado() -> bool:
	return not _botao.disabled


func texto_contagem() -> String:
	return _contagem.text


## Aperta o botão (os testes usam; o clique chama o mesmo).
func apertar_reviver() -> void:
	if botao_liberado():
		_botao.pressed.emit()


func _reviver_agora() -> void:
	if _jogador:
		_jogador.pedir_reviver()
