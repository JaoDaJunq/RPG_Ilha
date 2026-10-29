extends TesteBase
## Arqueiro: tiro carregado bate mais que o rápido; armadilha prende e machuca.

const SLIME := preload("res://scenes/enemies/slime.tscn")


func _ready() -> void:
	var w := await criar_mundo(0, true, &"arqueiro")
	var p := w.jogador

	var a: Slime = colocar(w, SLIME, p.global_position + Vector2(60, -30))
	var b: Slime = colocar(w, SLIME, p.global_position + Vector2(60, 30))
	a.set_physics_process(false)
	b.set_physics_process(false)
	await get_tree().physics_frame
	p.mira_forcada = a.global_position + Vector2(0, -6)
	p.usar_habilidade_por_id(&"tiro_carregado", 0.0)
	await esperar(0.7)
	p.mira_forcada = b.global_position + Vector2(0, -6)
	p.usar_habilidade_por_id(&"tiro_carregado", 1.0)
	await esperar(0.5)
	var dano_a := 3.0 - (a.vida.atual if is_instance_valid(a) else 0.0)
	var dano_b := 3.0 - (b.vida.atual if is_instance_valid(b) else 0.0)
	checar(dano_a > 0.0, "tiro rápido acerta (%.1f)" % dano_a)
	checar(dano_b > dano_a * 2.0, "tiro carregado bate bem mais (%.1f contra %.1f)" % [dano_b, dano_a])

	var slime: Slime = colocar(w, SLIME, p.global_position + Vector2(0, 70))
	slime.set_physics_process(false)
	await get_tree().physics_frame
	p.mira_forcada = slime.global_position
	p.usar_habilidade_por_id(&"armadilha")
	await get_tree().physics_frame
	var armadas := get_tree().get_nodes_in_group(&"armadilhas")
	checar(armadas.size() == 1, "armadilha fica no chão")
	checar(armadas.size() == 1 and armadas[0].global_position.distance_to(p.global_position) <= 57.0, "armadilha respeita o alcance")
	# O slime anda até a armadilha.
	slime.global_position = armadas[0].global_position + Vector2(0, 12)
	slime.set_physics_process(true)
	slime.global_position = armadas[0].global_position
	await esperar(0.3)
	checar(slime.preso() and slime.vida.atual < 3.0, "armadilha prende e machuca o slime (vida %.1f)" % slime.vida.atual)

	terminar()
