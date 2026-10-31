extends TesteBase
## Os 6 personagens por peças lado a lado (parado, andando e golpeando, com o item da
## classe na mão), de perto. Precisa de janela. Salva evidence/fundacao/bonecos.png.

const LISTA := [[&"humano", &"guerreiro", &"espada_ferro"], [&"humano", &"mago", &"cajado"], [&"humano", &"arqueiro", &"arco"],
	[&"ogro", &"guerreiro", &"machado_pedra"], [&"ogro", &"mago", &"tocha"], [&"ogro", &"arqueiro", &"picareta_pedra"]]


func _ready() -> void:
	var w := await criar_mundo()
	w.jogador.visible = false
	w.hud.visible = false
	var base := w.centro + Vector2(-70, 80)
	for i in LISTA.size():
		for k in 3:
			var b := Boneco.new()
			b.scale = Vector2(0.25, 0.25)
			b.position = base + Vector2(i * 26, k * 28)
			w.entidades.add_child(b)
			b.configurar(LISTA[i][0], LISTA[i][1])
			b.item = LISTA[i][2]
			b.play([&"parado_direita", &"andar_direita", &"golpe_direita"][k])
			b._tempo = i * 0.3
	var cam := Camera2D.new()
	cam.zoom = Vector2(7, 7)
	cam.position = base + Vector2(65, 18)
	w.add_child(cam)
	cam.make_current()
	await esperar(0.13)
	await salvar_print("fundacao/bonecos.png")
	terminar()
