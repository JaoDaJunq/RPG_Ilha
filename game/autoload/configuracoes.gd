extends Node
## Configurações do jogador: teclas, volume e tela cheia. Ficam em user://configuracoes.cfg
## e são aplicadas assim que o jogo abre (por isso valem no menu e no mundo).
##
## O arquivo só guarda o que o jogador mudou nas teclas. As teclas "de fábrica" são as do
## project.godot, lidas aqui antes de aplicar qualquer mudança.

signal mudou  ## alguma tecla (ou o jogador restaurou o padrão): a interface refaz os nomes

const CAMINHO_PADRAO := "user://configuracoes.cfg"

## Cada entrada é uma linha da tela de controles. Uma entrada pode mexer em mais de uma
## ação do jogo (atacar e interagir são o mesmo clique).
const GRUPOS: Array[Dictionary] = [
	{"titulo": "Movimento", "entradas": [
		{"nome": "Andar para cima", "acoes": [&"mover_cima"]},
		{"nome": "Andar para baixo", "acoes": [&"mover_baixo"]},
		{"nome": "Andar para a esquerda", "acoes": [&"mover_esquerda"]},
		{"nome": "Andar para a direita", "acoes": [&"mover_direita"]},
		{"nome": "Dash (esquiva)", "acoes": [&"esquivar"]},
	]},
	{"titulo": "Ações", "entradas": [
		{"nome": "Golpear, coletar e abrir", "acoes": [&"atacar", &"interagir"]},
		{"nome": "Usar o item da mão", "acoes": [&"usar"]},
		{"nome": "Habilidade 1", "acoes": [&"habilidade_1"]},
		{"nome": "Habilidade 2", "acoes": [&"habilidade_2"]},
		{"nome": "Habilidade 3", "acoes": [&"habilidade_3"]},
		{"nome": "Habilidade 4", "acoes": [&"habilidade_4"]},
	]},
	{"titulo": "Barra de itens", "entradas": [
		{"nome": "Item 1", "acoes": [&"barra_1"]},
		{"nome": "Item 2", "acoes": [&"barra_2"]},
		{"nome": "Item 3", "acoes": [&"barra_3"]},
		{"nome": "Item 4", "acoes": [&"barra_4"]},
		{"nome": "Item 5", "acoes": [&"barra_5"]},
		{"nome": "Item 6", "acoes": [&"barra_6"]},
		{"nome": "Item 7", "acoes": [&"barra_7"]},
		{"nome": "Item 8", "acoes": [&"barra_8"]},
		{"nome": "Item 9", "acoes": [&"barra_9"]},
	]},
	{"titulo": "Telas e outros", "entradas": [
		{"nome": "Mochila", "acoes": [&"mochila"]},
		{"nome": "Ficha do personagem", "acoes": [&"ficha"]},
		{"nome": "Árvore de habilidades", "acoes": [&"arvore"]},
		{"nome": "Mapa da ilha", "acoes": [&"mapa"]},
		{"nome": "Missões do Brasinha", "acoes": [&"missoes"]},
		{"nome": "Alternar dia e noite", "acoes": [&"alternar_noite"]},
		{"nome": "Ligar e desligar o som", "acoes": [&"alternar_som"]},
	]},
]

## Quantas teclas cada ação aceita (a principal e uma alternativa).
const ESPACOS := 2

const NOMES_TECLAS := {
	KEY_SHIFT: "Shift", KEY_CTRL: "Ctrl", KEY_ALT: "Alt", KEY_SPACE: "Espaço", KEY_TAB: "Tab",
	KEY_ENTER: "Enter", KEY_BACKSPACE: "Apagar", KEY_ESCAPE: "Esc", KEY_CAPSLOCK: "Caps Lock",
	KEY_UP: "↑", KEY_DOWN: "↓", KEY_LEFT: "←", KEY_RIGHT: "→",
	KEY_INSERT: "Insert", KEY_HOME: "Home", KEY_END: "End", KEY_PAGEUP: "Pg Up", KEY_PAGEDOWN: "Pg Down",
}
const NOMES_MOUSE := {
	MOUSE_BUTTON_LEFT: "Clique esq.", MOUSE_BUTTON_RIGHT: "Clique dir.", MOUSE_BUTTON_MIDDLE: "Clique do meio",
	MOUSE_BUTTON_XBUTTON1: "Lateral 1", MOUSE_BUTTON_XBUTTON2: "Lateral 2",
}

## Arquivo das configurações (os testes trocam por um temporário).
var caminho := CAMINHO_PADRAO
var volume := 0.8  ## 0 a 1
var tela_cheia := false

var _padrao: Dictionary = {}  # ação → eventos de fábrica


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for acao in todas_as_acoes():
		_padrao[acao] = InputMap.action_get_events(acao).duplicate()
	carregar()


## Todas as ações de jogo que aparecem na tela de controles.
func todas_as_acoes() -> Array[StringName]:
	var lista: Array[StringName] = []
	for g in GRUPOS:
		for e in g.entradas:
			for a in e.acoes:
				lista.append(a)
	return lista


# --- Teclas -----------------------------------------------------------------------

## Os eventos (teclas e botões do mouse) ligados a uma ação, no máximo ESPACOS.
func eventos_de(acao: StringName) -> Array[InputEvent]:
	var lista: Array[InputEvent] = []
	for e in InputMap.action_get_events(acao):
		if (e is InputEventKey or e is InputEventMouseButton) and lista.size() < ESPACOS:
			lista.append(e)
	return lista


## Troca a tecla do espaço `espaco` (0 ou 1) de uma entrada (todas as suas ações).
## `evento` null limpa o espaço. Grava o arquivo.
func religar(acoes: Array, espaco: int, evento: InputEvent) -> void:
	for a in acoes:
		var eventos := eventos_de(a)
		while eventos.size() <= espaco:
			eventos.append(null)
		eventos[espaco] = evento
		_definir(a, eventos)
	salvar()
	mudou.emit()


## Põe de volta as teclas de fábrica (de uma lista de ações, ou de todas).
func restaurar_padrao(acoes: Array = []) -> void:
	for a in (acoes if not acoes.is_empty() else todas_as_acoes()):
		_definir(a, _padrao.get(a, []))
	salvar()
	mudou.emit()


## Movimento: "wasd", "setas" ou "ambos" (o padrão do jogo: as duas coisas).
func predefinir_movimento(qual: String) -> void:
	var teclas := {
		&"mover_cima": [KEY_W, KEY_UP], &"mover_baixo": [KEY_S, KEY_DOWN],
		&"mover_esquerda": [KEY_A, KEY_LEFT], &"mover_direita": [KEY_D, KEY_RIGHT],
	}
	for a in teclas:
		var par: Array = teclas[a]
		var escolhidas: Array[InputEvent] = []
		match qual:
			"wasd":
				escolhidas.append(_tecla(par[0]))
			"setas":
				escolhidas.append(_tecla(par[1]))
			_:
				escolhidas.append(_tecla(par[0]))
				escolhidas.append(_tecla(par[1]))
		_definir(a, escolhidas)
	salvar()
	mudou.emit()


## Qual predefinição de movimento está valendo ("wasd", "setas", "ambos" ou "" se for outra).
func movimento_atual() -> String:
	var wasd := [KEY_W, KEY_S, KEY_A, KEY_D]
	var setas := [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]
	var acoes: Array[StringName] = [&"mover_cima", &"mover_baixo", &"mover_esquerda", &"mover_direita"]
	var tem_wasd := true
	var tem_setas := true
	var so_wasd := true
	var so_setas := true
	for i in 4:
		var teclas: Array[int] = []
		for e in eventos_de(acoes[i]):
			if e is InputEventKey:
				teclas.append(e.physical_keycode)
		var w: bool = wasd[i] in teclas
		var s: bool = setas[i] in teclas
		tem_wasd = tem_wasd and w
		tem_setas = tem_setas and s
		so_wasd = so_wasd and w and teclas.size() == 1
		so_setas = so_setas and s and teclas.size() == 1
	if tem_wasd and tem_setas:
		return "ambos"
	if so_wasd:
		return "wasd"
	if so_setas:
		return "setas"
	return ""


## Outras entradas (de ações diferentes) que já usam este mesmo evento. Só para avisar.
func conflitos(acoes: Array, evento: InputEvent) -> Array[String]:
	var nomes: Array[String] = []
	for g in GRUPOS:
		for e in g.entradas:
			if e.acoes == acoes:
				continue
			for a in e.acoes:
				for ev in eventos_de(a):
					if _mesmo_evento(ev, evento) and not e.nome in nomes:
						nomes.append(e.nome)
	return nomes


## Nome amigável (em português) da tecla ou do botão do mouse. "—" se estiver vazio.
func nome_do_evento(evento: InputEvent) -> String:
	if evento is InputEventKey:
		var k := evento as InputEventKey
		var codigo: int = k.physical_keycode if k.physical_keycode != 0 else k.keycode
		if NOMES_TECLAS.has(codigo):
			return NOMES_TECLAS[codigo]
		# O nome segue o teclado do jogador (num AZERTY a tecla do W mostra Z). Sem janela (testes) não há isso.
		var tecla := ""
		if DisplayServer.get_name() != "headless":
			tecla = OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(codigo as Key))
		if tecla == "":
			tecla = OS.get_keycode_string(codigo as Key)
		return tecla if tecla != "" else "Tecla %d" % codigo
	if evento is InputEventMouseButton:
		var b := (evento as InputEventMouseButton).button_index
		return NOMES_MOUSE.get(b, "Mouse %d" % b)
	return "—"


## A tecla principal de uma ação, para os rótulos da interface (a barra de habilidades etc.).
func tecla_de(acao: StringName) -> String:
	var eventos := eventos_de(acao)
	return nome_do_evento(eventos[0]) if not eventos.is_empty() else "—"


# --- Volume e tela ------------------------------------------------------------------

func definir_volume(v: float, gravar := true) -> void:
	volume = clampf(v, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(volume) if volume > 0.001 else -80.0)
	if gravar:
		salvar()


func definir_tela_cheia(ligada: bool, gravar := true) -> void:
	tela_cheia = ligada
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if ligada else DisplayServer.WINDOW_MODE_WINDOWED)
	if gravar:
		salvar()


# --- Arquivo --------------------------------------------------------------------------

## Lê o arquivo e aplica (teclas, volume e tela). Sem arquivo, fica tudo de fábrica.
func carregar() -> void:
	for a in _padrao:
		_definir(a, _padrao[a])
	volume = 0.8
	tela_cheia = false
	var cfg := ConfigFile.new()
	if cfg.load(caminho) == OK:
		for a in _padrao:
			if cfg.has_section_key("controles", String(a)):
				var eventos: Array[InputEvent] = []
				for texto in cfg.get_value("controles", String(a), []):
					var e := _de_texto(String(texto))
					if e != null:
						eventos.append(e)
				_definir(a, eventos)
		volume = float(cfg.get_value("som", "volume", 0.8))
		tela_cheia = bool(cfg.get_value("tela", "cheia", false))
	definir_volume(volume, false)
	definir_tela_cheia(tela_cheia, false)
	mudou.emit()


## Grava só o que difere do padrão nas teclas.
func salvar() -> void:
	var cfg := ConfigFile.new()
	for a in _padrao:
		var agora: Array[String] = []
		for e in eventos_de(a):
			agora.append(_para_texto(e))
		var fabrica: Array[String] = []
		for e in _padrao[a]:
			if e is InputEventKey or e is InputEventMouseButton:
				fabrica.append(_para_texto(e))
		if agora != fabrica:
			cfg.set_value("controles", String(a), agora)
	cfg.set_value("som", "volume", volume)
	cfg.set_value("tela", "cheia", tela_cheia)
	cfg.save(caminho)


func _definir(acao: StringName, eventos: Array) -> void:
	InputMap.action_erase_events(acao)
	for e in eventos:
		if e != null:
			InputMap.action_add_event(acao, e)


func _tecla(codigo: int) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = codigo as Key
	return e


## "k:87" (tecla, pelo código físico, que não muda com o idioma do teclado) ou "m:1" (mouse).
func _para_texto(e: InputEvent) -> String:
	if e is InputEventKey:
		return "k:%d" % (e as InputEventKey).physical_keycode
	return "m:%d" % (e as InputEventMouseButton).button_index


func _de_texto(t: String) -> InputEvent:
	var partes := t.split(":")
	if partes.size() != 2 or not partes[1].is_valid_int():
		return null
	if partes[0] == "k":
		return _tecla(partes[1].to_int())
	if partes[0] == "m":
		var e := InputEventMouseButton.new()
		e.button_index = partes[1].to_int() as MouseButton
		return e
	return null


func _mesmo_evento(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		return (a as InputEventKey).physical_keycode == (b as InputEventKey).physical_keycode
	if a is InputEventMouseButton and b is InputEventMouseButton:
		return (a as InputEventMouseButton).button_index == (b as InputEventMouseButton).button_index
	return false
