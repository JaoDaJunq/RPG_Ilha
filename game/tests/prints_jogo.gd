extends TesteBase
## Tira prints de dentro do jogo (precisa de janela; não roda com --headless).
## Uso (da raiz):  <godot> --path game res://tests/prints_jogo.tscn
## Salva em evidence/fundacao/: dia.png (mirando numa árvore, outra em chamas) e noite.png.


func _ready() -> void:
	var w := await criar_mundo(5, false)
	var p := w.jogador
	var pasta := ProjectSettings.globalize_path("res://").path_join("../evidence/fundacao")
	DirAccess.make_dir_recursive_absolute(pasta)

	# Leva o jogador para perto da árvore mais próxima do acampamento.
	var arvores: Array[ResourceNode] = []
	for n in w.entidades.get_children():
		if n is ResourceNode and n.acao == "Cortar":
			arvores.append(n)
	arvores.sort_custom(func(a: ResourceNode, b: ResourceNode) -> bool:
		return a.global_position.distance_to(w.centro) < b.global_position.distance_to(w.centro))
	var alvo := arvores[0]
	p.global_position = alvo.global_position + Vector2(-22, 6)
	p.get_node("Camera2D").reset_smoothing()

	# Queima a segunda árvore mais próxima, para mostrar o fogo no mundo.
	arvores[1].hurtbox.receber(1.0, &"fogo", p)
	p.mira_forcada = alvo.global_position + Vector2(0, -20)
	Input.action_press(&"interagir")
	await esperar(0.3)
	await _salvar(pasta.path_join("dia.png"))
	Input.action_release(&"interagir")

	w.alternar_noite()
	p.mira_forcada = arvores[2].global_position + Vector2(0, -6)
	await esperar(1.2)
	p.lancar_bola_de_fogo()
	await esperar(0.12)
	await _salvar(pasta.path_join("noite.png"))

	p.global_position = w.ponto_de_nascer(0)
	p.get_node("Camera2D").reset_smoothing()
	p.mira_forcada = null
	await esperar(0.3)
	await _salvar(pasta.path_join("acampamento_noite.png"))
	terminar()


func _salvar(caminho: String) -> void:
	await RenderingServer.frame_post_draw
	var erro := get_viewport().get_texture().get_image().save_png(caminho)
	checar(erro == OK, "print salvo: " + caminho.get_file())
