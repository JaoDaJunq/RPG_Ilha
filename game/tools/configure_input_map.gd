extends SceneTree
## Grava o mapa de controles no project.godot.
## Uso (da raiz do repositório):
##   godot --headless --path game --script res://tools/configure_input_map.gd

const TECLAS := {
	"mover_cima": [KEY_W, KEY_UP],
	"mover_baixo": [KEY_S, KEY_DOWN],
	"mover_esquerda": [KEY_A, KEY_LEFT],
	"mover_direita": [KEY_D, KEY_RIGHT],
	"interagir": [KEY_E],
	"habilidade_1": [KEY_1],
	"habilidade_2": [KEY_2],
	"habilidade_3": [KEY_3],
	"habilidade_4": [KEY_4],
	"habilidade_5": [KEY_5],
	"habilidade_6": [KEY_6],
	"alternar_noite": [KEY_N],
	"alternar_som": [KEY_M],
}

const MOUSE := {
	"atacar": [MOUSE_BUTTON_LEFT],
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
