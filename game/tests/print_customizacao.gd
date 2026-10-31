extends TesteBase
## O boneco por camadas (L24) lado a lado: cada coluna é uma combinação de rosto, pele e
## roupa; as linhas são de frente, de perfil e de costas. Precisa de janela.
## Salva evidence/novidades/customizacao.png.

const COMBOS := [
	[{raca = &"humano", rosto = 0, pele = 0}, {cabeca = &"elmo_guerreiro", corpo = &"roupa_guerreiro"}],
	[{raca = &"humano", rosto = 1, pele = 0}, {cabeca = &"chapeu_mago", corpo = &"roupa_mago"}],
	[{raca = &"humano", rosto = 2, pele = 1}, {cabeca = &"capuz_arqueiro", corpo = &"roupa_arqueiro"}],
	[{raca = &"ogro", rosto = 0, pele = 0}, {}],
	[{raca = &"ogro", rosto = 1, pele = 1}, {}],
	[{raca = &"ogro", rosto = 2, pele = 2}, {}],
	[{raca = &"ogro", rosto = 0, pele = 0}, {cabeca = &"elmo_guerreiro", corpo = &"roupa_guerreiro"}],
	[{raca = &"ogro", rosto = 1, pele = 0}, {cabeca = &"chapeu_mago", corpo = &"roupa_mago"}],
	[{raca = &"ogro", rosto = 2, pele = 1}, {cabeca = &"capuz_arqueiro", corpo = &"roupa_arqueiro"}],
]


func _ready() -> void:
	var w := await criar_mundo()
	w.jogador.visible = false
	w.hud.visible = false
	var base := w.centro + Vector2(-80, 80)
	for i in COMBOS.size():
		for k in 3:
			var b := Boneco.new()
			b.scale = Vector2(0.25, 0.25)
			b.position = base + Vector2(i * 24, k * 30)
			w.entidades.add_child(b)
			b.vestir(COMBOS[i][0], COMBOS[i][1])
			b.play([&"parado_baixo", &"parado_direita", &"parado_cima"][k])
	var cam := Camera2D.new()
	cam.zoom = Vector2(5.5, 5.5)
	cam.position = base + Vector2(96, 22)
	w.add_child(cam)
	cam.make_current()
	await esperar(0.2)
	await salvar_print("novidades/customizacao.png")
	terminar()
