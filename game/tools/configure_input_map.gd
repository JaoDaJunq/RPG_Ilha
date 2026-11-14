extends SceneTree
## Grava o mapa de controles no project.godot.
## Uso (da raiz do repositório):
##   godot --headless --path game --script res://tools/configure_input_map.gd

const TECLAS := {
	"mover_cima": [KEY_W, KEY_UP],
	"mover_baixo": [KEY_S, KEY_DOWN],
	"mover_esquerda": [KEY_A, KEY_LEFT],
	"mover_direita": [KEY_D, KEY_RIGHT],
	# Habilidades da classe em Q, R, T e E; os números são da barra de itens (Minecraft).
	"habilidade_1": [KEY_Q],
	"habilidade_2": [KEY_R],
	"habilidade_3": [KEY_T],
	"habilidade_4": [KEY_E],
	"barra_1": [KEY_1],
	"barra_2": [KEY_2],
	"barra_3": [KEY_3],
	"barra_4": [KEY_4],
	"barra_5": [KEY_5],
	"barra_6": [KEY_6],
	"barra_7": [KEY_7],
	"barra_8": [KEY_8],
	"barra_9": [KEY_9],
	"mochila": [KEY_I, KEY_TAB],
	"esquivar": [KEY_SHIFT],  # o dash
	"ficha": [KEY_C],
	"alternar_noite": [KEY_N],
	"alternar_som": [KEY_P],
	"mapa": [KEY_M],
	"missoes": [KEY_J],
}

const MOUSE := {
	# Clique esquerdo: um clique abre baú e bancada; segurar corta, minera, quebra e golpeia.
	"atacar": [MOUSE_BUTTON_LEFT],
	"interagir": [MOUSE_BUTTON_LEFT],
	"usar": [MOUSE_BUTTON_RIGHT],  # comer, beber, usar o item da mão
}


func _init() -> void:
	for acao in TECLAS:
		var eventos: Array[InputEvent] = []
		for tecla in TECLAS[acao]:
			var ev := InputEventKey.new()
			ev.physical_keycode = tecla
			eventos.append(ev)
		_gravar(acao, eventos)
	for acao in MOUSE:
		var eventos: Array[InputEvent] = []
		for botao in MOUSE[acao]:
			var ev := InputEventMouseButton.new()
			ev.button_index = botao
			eventos.append(ev)
		_gravar(acao, eventos)
	var erro := ProjectSettings.save()
	print("Mapa de controles gravado: ", error_string(erro))
	quit(0 if erro == OK else 1)


func _gravar(acao: String, eventos: Array[InputEvent]) -> void:
	ProjectSettings.set_setting("input/" + acao, {"deadzone": 0.2, "events": eventos})
