extends TesteBase
## Print da tela inicial (precisa de janela). Salva evidence/fundacao/menu.png.


func _ready() -> void:
	Sfx.ligado = false
	var menu: Node = load("res://scenes/ui/menu.tscn").instantiate()
	add_child(menu)
	await esperar(0.5)
	await salvar_print("fundacao/menu.png")
	terminar()
