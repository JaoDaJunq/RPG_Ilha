extends TesteBase
## Slime machuca no contato, o golpe derrota o slime e o jogador cai ao desmaiar e revive no acampamento.

const SLIME := preload("res://scenes/enemies/slime.tscn")


func _ready() -> void:
	var w := await criar_mundo(0, true, &"guerreiro")
	var p := w.jogador

	var slime: Slime = colocar(w, SLIME, p.position + Vector2(30, 0))
	await esperar(1.5)
	checar(p.vida.atual < p.vida.maximo, "slime persegue e machuca no contato (vida %d de %d)" % [p.vida.atual, p.vida.maximo])

	slime.set_physics_process(false)
	var golpes := 0
	for i in 3:
		if not is_instance_valid(slime):
			break
		p.mira_forcada = slime.global_position
		p.golpear()
		golpes += 1
		await esperar(0.4)
	checar(not is_instance_valid(slime), "até 3 golpes derrotam o slime (com a espada de ferro: %d)" % golpes)

	p.global_position += Vector2(40, 40)
	var onde := p.global_position
	p.vida.tomar_dano(500.0)
	await get_tree().physics_frame
	checar(p.caido and p.global_position == onde, "ao desmaiar cai no lugar (a tela de morte conta até voltar)")
	p.reviver_no_acampamento()
	await get_tree().physics_frame
	checar(p.global_position == p.ponto_de_retorno, "ao reviver volta ao acampamento")
	checar(p.vida.atual == p.vida.maximo, "volta com a vida cheia")

	terminar()
