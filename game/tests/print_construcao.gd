extends TesteBase
## Print de uma casinha construída (chão, paredes, porta, tochas, bancada e baú), de dia e
## à noite, com uma parede na mão (prévia verde). Precisa de janela.
## Salva evidence/fundacao/casa_dia.png e casa_noite.png.


func _ready() -> void:
	var w := await criar_mundo()
	var p := w.jogador
	var o := Vector2i((w.centro / World.T).floor()) + Vector2i(5, 3)
	for y in range(0, 5):
		for x in range(0, 6):
			w._criar_peca(&"chao_madeira", o + Vector2i(x, y))
	for x in range(0, 6):
		w._criar_peca(&"parede_madeira", o + Vector2i(x, -1))
		if x != 2:
			w._criar_peca(&"parede_madeira", o + Vector2i(x, 5))
	w._criar_peca(&"porta_madeira", o + Vector2i(2, 5))
	for y in range(-1, 6):
		w._criar_peca(&"parede_madeira", o + Vector2i(-1, y))
		w._criar_peca(&"parede_madeira", o + Vector2i(6, y))
	w._criar_peca(&"tocha", o + Vector2i(0, 0))
	w._criar_peca(&"tocha", o + Vector2i(5, 0))
	w._criar_peca(&"bancada", o + Vector2i(2, 1))
	w._criar_peca(&"bau", o + Vector2i(4, 1))
	w._criar_peca(&"tocha", o + Vector2i(1, 7))
	p.inventario.adicionar(&"parede_madeira", 20)
	p.barra_escolhida = 0
	p.global_position = Vector2((o + Vector2i(2, 3)) * World.T) + Vector2(8, 12)
	p.get_node("Camera2D").reset_smoothing()
	p.mira_forcada = Vector2((o + Vector2i(8, 3)) * World.T) + Vector2(4, 4)
	await esperar(0.4)
	await salvar_print("fundacao/casa_dia.png")
	w.alternar_noite()
	await esperar(1.5)
	await salvar_print("fundacao/casa_noite.png")
	terminar()
