extends TesteBase
## Print do saque no chão (precisa de janela): um javali e uma galinha derrotados perto do
## jogador. Salva em evidence/novidades/.

const ANIMAL := preload("res://scenes/animals/animal.tscn")


func _ready() -> void:
	var w := await criar_mundo(0, true, &"guerreiro", &"humano")
	var p := w.jogador
	p.global_position = w.centro + Vector2(-30, 70)
	p.get_node("Camera2D").reset_smoothing()
	var onde := [[&"javali", Vector2(36, -4)], [&"galinha", Vector2(34, 22)]]
	var bichos: Array[Animal] = []
	for e in onde:
		var a: Animal = ANIMAL.instantiate()
		a.especie = e[0]
		a.position = p.global_position + (e[1] as Vector2)
		w.entidades.add_child(a, true)
		bichos.append(a)
	await esperar(0.3)
	# Um pouco de tudo no chão para comparar o tamanho com o resto do mundo.
	for a in bichos:
		a.hurtbox.receber(99.0, &"fisico", p)
	await esperar(0.15)
	await salvar_print("novidades/saque_saltando.png")
	await esperar(0.8)
	checar(get_tree().get_nodes_in_group(&"itens_chao").size() >= 4, "o saque está no chão (%d pilhas)" % get_tree().get_nodes_in_group(&"itens_chao").size())
	await salvar_print("novidades/saque_no_chao.png")
	terminar()
