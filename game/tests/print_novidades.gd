extends TesteBase
## Prints das novidades do L21/L22 (precisa de janela): animais, parede e porta giradas,
## personagem de frente, de costas e com a Fúria. Salva em evidence/novidades/.

const ANIMAL := preload("res://scenes/animals/animal.tscn")


func _ready() -> void:
	var w := await criar_mundo(0, true, &"guerreiro", &"ogro")
	var p := w.jogador
	var o := Vector2i((w.centro / World.T).floor()) + Vector2i(4, 2)
	# Um cercadinho com a parede de lado (girada) e uma porta girada.
	for y in range(0, 4):
		w._criar_peca(&"parede_madeira", o + Vector2i(0, y), 1)
	w._criar_peca(&"porta_madeira", o + Vector2i(0, 4), 1)
	for y in range(5, 7):
		w._criar_peca(&"parede_madeira", o + Vector2i(0, y), 1)
	var bichos := [&"galinha", &"coelho", &"ovelha", &"javali", &"galinha", &"coelho"]
	for i in bichos.size():
		var a: Animal = ANIMAL.instantiate()
		a.especie = bichos[i]
		a.position = Vector2((o + Vector2i(3 + (i % 3) * 3, 1 + (i / 3) * 3)) * World.T)
		w.entidades.add_child(a, true)
	p.global_position = Vector2((o + Vector2i(-3, 3)) * World.T)
	p.get_node("Camera2D").reset_smoothing()
	await esperar(0.6)
	await salvar_print("novidades/animais_parede_girada.png")

	Input.action_press(&"mover_baixo")
	await esperar(0.35)
	await salvar_print("novidades/andando_de_frente.png")
	Input.action_release(&"mover_baixo")
	Input.action_press(&"mover_cima")
	await esperar(0.35)
	await salvar_print("novidades/andando_de_costas.png")
	Input.action_release(&"mover_cima")
	await esperar(0.2)
	p.mira_forcada = p.global_position + Vector2(40, 0)
	checar(p.usar_habilidade_por_id(&"furia"), "Fúria usada")
	await esperar(0.3)
	await salvar_print("novidades/furia.png")
	terminar()
