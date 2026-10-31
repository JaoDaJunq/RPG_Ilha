extends TesteBase
## Slime mais esperto: passeia sem ninguém por perto, persegue, achata antes de pular
## (aviso) e o pulo machuca; a esquiva no momento certo evita o dano.


func _ready() -> void:
	var w := await criar_mundo(0)
	var p := w.jogador
	p.global_position = w.centro + Vector2(0, 80)
	var s: Slime = preload("res://scenes/enemies/slime.tscn").instantiate()
	s.position = p.global_position + Vector2(200, 0)
	w.entidades.add_child(s)
	var inicio := s.global_position
	await esperar(3.5)
	checar(s._estado == Slime.Estado.PASSEANDO, "longe do jogador, ele passeia")
	checar(s.global_position.distance_to(inicio) > 4.0, "passeando, ele sai do lugar (%.0f px)" % s.global_position.distance_to(inicio))

	s.global_position = p.global_position + Vector2(60, 0)
	s._recarga = 0.0
	await esperar(0.5)
	checar(s._estado in [Slime.Estado.PERSEGUINDO, Slime.Estado.PREPARANDO], "viu o jogador e persegue")
	var vida_antes := p.vida.atual
	var achatou := false
	for k in 40:
		await esperar(0.05)
		if s._estado == Slime.Estado.PREPARANDO:
			achatou = true
		if p.vida.atual < vida_antes:
			break
	checar(achatou, "achata antes de pular (aviso para esquivar)")
	checar(p.vida.atual < vida_antes, "o pulo machucou (%.0f -> %.0f)" % [vida_antes, p.vida.atual])
	terminar()
