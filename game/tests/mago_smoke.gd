extends TesteBase
## Mago: lança de gelo congela (e o golpe estilhaça); sobre a água vira caminho de gelo que derrete.

const SLIME := preload("res://scenes/enemies/slime.tscn")


func _ready() -> void:
	var w := await criar_mundo(0, true, &"mago")
	w.duracao_gelo = 2.0
	var p := w.jogador

	var slime: Slime = colocar(w, SLIME, p.global_position + Vector2(50, 0))
	await get_tree().physics_frame
	p.mira_forcada = slime.global_position + Vector2(0, -6)
	p.usar_habilidade_por_id(&"lanca_gelo")
	await esperar(0.5)
	checar(slime.congelado() and slime.parado, "lança de gelo congela o slime")
	var pos := slime.global_position
	await esperar(0.5)
	checar(slime.global_position.distance_to(pos) < 0.5, "slime congelado não anda")
	var vida_antes := slime.vida.atual
	p.global_position = slime.global_position + Vector2(-14, 4)
	p.mira_forcada = slime.global_position
	await get_tree().physics_frame
	p.golpear()
	await get_tree().physics_frame
	var normal := p.dano_do_golpe(0)
	var tirou := vida_antes - (slime.vida.atual if is_instance_valid(slime) else 0.0)
	checar(tirou >= normal * 2.0 - 0.01, "golpe no congelado estilhaça: dano dobrado (%.2f, normal %.2f)" % [tirou, normal])
	checar(not is_instance_valid(slime) or not slime.congelado(), "estilhaçar descongela")

	# Ponte de gelo: da areia, lança para a água.
	var y := w.altura / 2
	var areia := -1
	for x in w.largura:
		if w.tipo_do_chao(Vector2i(x, y)) == World.Chao.AREIA:
			areia = x
			break
	p.global_position = w.chao.map_to_local(Vector2i(areia, y)) + Vector2(0, 6)
	await get_tree().physics_frame
	p.mira_forcada = p.global_position + Vector2(-200, -10)
	await esperar(1.3)
	p.usar_habilidade_por_id(&"lanca_gelo")
	await esperar(0.8)
	var gelos := 0
	for x in range(0, areia):
		if w.eh_gelo(Vector2i(x, y)):
			gelos += 1
	checar(gelos >= 2, "lança sobre a água deixa caminho de gelo (%d células)" % gelos)
	Input.action_press(&"mover_esquerda")
	await esperar(0.6)
	Input.action_release(&"mover_esquerda")
	var cel := w.chao.local_to_map(p.global_position)
	checar(w.eh_gelo(cel), "dá para andar em cima do gelo (coluna %d)" % cel.x)
	p.global_position = w.chao.map_to_local(Vector2i(areia + 2, y))
	await esperar(2.8)
	var restantes := 0
	for x in range(0, areia):
		if w.eh_gelo(Vector2i(x, y)):
			restantes += 1
	checar(restantes == 0, "o gelo derrete depois de um tempo (%d sobrando)" % restantes)

	terminar()
