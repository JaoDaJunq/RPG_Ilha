extends TesteBase
## Os cinco personagens completos do Humano lado a lado. As linhas são de frente, perfil e
## costas. Precisa de janela. Salva evidence/novidades/customizacao.png.

const COMBOS := [
	[{raca = &"humano", rosto = 0, pele = 0}, {corpo = &"roupa_guerreiro"}],
	[{raca = &"humano", rosto = 0, pele = 0}, {corpo = &"roupa_mago"}],
	[{raca = &"humano", rosto = 0, pele = 0}, {corpo = &"roupa_arqueiro"}],
	[{raca = &"humano", rosto = 0, pele = 0}, {corpo = &"roupa_ladino"}],
	[{raca = &"humano", rosto = 0, pele = 0}, {corpo = &"roupa_clerigo"}],
]


func _ready() -> void:
	var w := await criar_mundo(0, true, &"mago", &"humano", true, 0)
	w.jogador.visible = false
	w.hud.visible = false
	# Plantas são belas no mapa, mas podem ficar na frente dos personagens nesta comparação.
	for filho in w.entidades.get_children():
		if filho is AnimatedSprite2D:
			filho.visible = false
	var base := w.centro + Vector2(-80, 80)
	for i in COMBOS.size():
		for k in 3:
			var b := Boneco.new()
			b.scale = Vector2(0.25, 0.25)
			b.position = base + Vector2(i * 26, k * 30)
			w.entidades.add_child(b)
			b.vestir(COMBOS[i][0], COMBOS[i][1])
			b.play([&"parado_baixo", &"parado_direita", &"parado_cima"][k])
	var cam := Camera2D.new()
	cam.zoom = Vector2(5.5, 5.5)
	cam.position = base + Vector2(52, 30)
	w.add_child(cam)
	cam.make_current()
	await esperar(0.2)
	await salvar_print("novidades/customizacao.png")
	terminar()
