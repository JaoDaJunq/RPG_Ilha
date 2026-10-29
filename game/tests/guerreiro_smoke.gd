extends TesteBase
## Guerreiro: Investida avança e acerta quem está no caminho; Giro acerta em volta.

const SLIME := preload("res://scenes/enemies/slime.tscn")


func _ready() -> void:
	var w := await criar_mundo(0, true, &"guerreiro")
	var p := w.jogador

	var no_caminho: Slime = colocar(w, SLIME, p.global_position + Vector2(36, 0))
	no_caminho.set_physics_process(false)
	await get_tree().physics_frame
	p.mira_forcada = p.global_position + Vector2(200, -10)
	var x0 := p.global_position.x
	p.usar_habilidade_por_id(&"investida")
	await esperar(0.4)
	var andou := p.global_position.x - x0
	checar(andou > 40.0, "investida avança o guerreiro (%.0f px)" % andou)
	checar(not is_instance_valid(no_caminho) or no_caminho.vida.atual < 3.0, "investida acerta o slime no caminho")

	var a: Slime = colocar(w, SLIME, p.global_position + Vector2(-18, 0))
	var b: Slime = colocar(w, SLIME, p.global_position + Vector2(18, 0))
	a.set_physics_process(false)
	b.set_physics_process(false)
	await get_tree().physics_frame
	p.usar_habilidade_por_id(&"giro")
	await get_tree().physics_frame
	checar(a.vida.atual < 3.0 and b.vida.atual < 3.0, "giro acerta os dois lados (%.1f e %.1f)" % [a.vida.atual, b.vida.atual])

	terminar()
