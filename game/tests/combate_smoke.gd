extends TesteBase
## Slime machuca no contato, o golpe derrota o slime e o jogador volta ao acampamento ao desmaiar.

const SLIME := preload("res://scenes/enemies/slime.tscn")


func _ready() -> void:
	var w := await criar_mundo()
	var p := w.jogador

	var slime: Slime = colocar(w, SLIME, p.position + Vector2(30, 0))
	await esperar(1.5)
	checar(p.vida.atual < 100.0, "slime persegue e machuca no contato (vida %d)" % p.vida.atual)

	slime.set_physics_process(false)
	for i in 3:
		p.mira_forcada = slime.global_position
		p.golpear()
		await esperar(0.4)
	checar(not is_instance_valid(slime), "3 golpes derrotam o slime")

	p.global_position += Vector2(40, 40)
	p.vida.tomar_dano(500.0)
	await get_tree().physics_frame
	checar(p.global_position == p.ponto_de_retorno, "ao desmaiar volta ao acampamento")
	checar(p.vida.atual == p.vida.maximo, "volta com a vida cheia")

	terminar()
