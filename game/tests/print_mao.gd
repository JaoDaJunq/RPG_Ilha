extends TesteBase
## Print do personagem com o machado na mão, no meio do golpe numa árvore.
## Precisa de janela. Salva evidence/fundacao/mao.png.


func _ready() -> void:
	var w := await criar_mundo(0, false, &"guerreiro", &"ogro")
	var p := w.jogador
	p.inventario.adicionar(&"machado_pedra", 1)
	p.inventario.adicionar(&"tocha", 5)
	p.barra_escolhida = 0
	var arvores: Array = w.entidades.get_children().filter(func(n: Node) -> bool: return n is ResourceNode and n.acao == "Cortar")
	arvores.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.global_position.distance_to(w.centro) < b.global_position.distance_to(w.centro))
	var alvo: ResourceNode = arvores[0]
	p.global_position = alvo.global_position + Vector2(-20, 6)
	p.get_node("Camera2D").reset_smoothing()
	p.mira_forcada = alvo.global_position + Vector2(0, -20)
	Input.action_press(&"interagir")
	await esperar(0.62)
	await salvar_print("fundacao/mao.png")
	Input.action_release(&"interagir")
	terminar()
