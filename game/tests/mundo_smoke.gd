extends TesteBase
## A ilha nasce completa, a água bloqueia o jogador e N alterna dia e noite.


func _ready() -> void:
	var w := await criar_mundo(5, false)
	var arvores := 0
	var pedras := 0
	var slimes := 0
	for n in w.entidades.get_children():
		if n is ResourceNode:
			if n.acao == "Cortar":
				arvores += 1
			else:
				pedras += 1
		elif n is Slime:
			slimes += 1
	checar(arvores >= 70, "ilha tem árvores suficientes (%d)" % arvores)
	checar(pedras >= 12, "ilha tem pedras (%d)" % pedras)
	checar(slimes == 5, "ilha tem 5 slimes (%d)" % slimes)
	var p := w.jogador
	var cel := w.chao.local_to_map(p.position)
	checar(w.tipo_do_chao(cel) != World.Chao.AGUA, "jogador nasce em terra firme")

	# Água bloqueia: anda para a esquerda a partir da areia por 4 s.
	for n in w.entidades.get_children():
		if n is Slime:
			n.queue_free()
	var y := w.altura / 2
	var areia := -1
	for x in w.largura:
		if w.tipo_do_chao(Vector2i(x, y)) == World.Chao.AREIA:
			areia = x
			break
	p.global_position = w.chao.map_to_local(Vector2i(areia, y))
	Input.action_press(&"mover_esquerda")
	await esperar(4.0)
	Input.action_release(&"mover_esquerda")
	var celula_final := w.chao.local_to_map(p.global_position + Vector2(-4, 0))
	checar(w.tipo_do_chao(w.chao.local_to_map(p.global_position)) != World.Chao.AGUA, "a água bloqueia o jogador")
	checar(celula_final.x <= areia, "jogador andou até a beira (coluna %d, areia em %d)" % [celula_final.x, areia])

	# Dia e noite.
	checar(not w.noite, "começa de dia")
	w.alternar_noite()
	await esperar(1.5)
	checar(w.noite and w.ambiente.color.is_equal_approx(World.COR_NOITE), "N escurece a ilha")
	var luzes := get_tree().get_nodes_in_group(&"luzes_noturnas")
	checar(luzes.size() > 0 and luzes.all(func(l: PointLight2D) -> bool: return l.enabled), "à noite as luzes acendem (%d)" % luzes.size())
	checar(w.hud.texto_aviso().contains("noite"), "HUD avisa que a noite caiu")
	w.alternar_noite()
	await esperar(1.5)
	checar(not w.noite and w.ambiente.color.is_equal_approx(World.COR_DIA), "N de novo amanhece")

	terminar()
