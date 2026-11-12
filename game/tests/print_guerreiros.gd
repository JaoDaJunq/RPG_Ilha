extends TesteBase
## Print dos guerreiros em sprite completo (L30) dentro do jogo (precisa de janela): o
## jogador (Humano Guerreiro, de espada) e os outros 3 ao lado, em vistas e poses diferentes.
## Salva evidence/novidades/guerreiros_no_jogo.png e guerreiros_golpe.png.


func _ready() -> void:
	var w := await criar_mundo(0, true, &"guerreiro", &"humano")
	var p := w.jogador
	w.hud.mostrar_aviso("")
	var outros := []
	var poses := [[&"ogro", &"parado_baixo", Vector2(-40, 0)], [&"elfo", &"andar_esquerda", Vector2(40, 0)], [&"anao", &"andar_cima", Vector2(0, 30)]]
	for pose in poses:
		var b := Boneco.new()
		b.scale = Vector2.ONE * 0.25
		b.position = p.position + pose[2]
		w.entidades.add_child(b)
		b.vestir({"raca": pose[0], "pele": 0, "classe": &"guerreiro"}, {})
		b.item = &"espada_ferro"
		b.play(pose[1])
		outros.append(b)
	await esperar(0.6)
	await salvar_print("novidades/guerreiros_no_jogo.png")
	for b in outros:
		b.play(&"golpe_direita")
	p.visual.play(&"golpe_direita")
	await esperar(0.2)
	await salvar_print("novidades/guerreiros_golpe.png")
	terminar()
