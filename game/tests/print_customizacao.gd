extends TesteBase
## Os cinco personagens completos de uma raça lado a lado. As linhas são frente, perfil e
## costas. Precisa de janela. Aceita --raca=ogro|elfo|anao (padrão humano).

const CLASSES := [&"guerreiro", &"mago", &"arqueiro", &"ladino", &"clerigo"]


func _ready() -> void:
	var raca := &"humano"
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--raca="):
			raca = StringName(argumento.trim_prefix("--raca="))
	var w := await criar_mundo(0, true, &"mago", raca, true, 0)
	w.jogador.visible = false
	w.hud.visible = false
	# Plantas são belas no mapa, mas podem ficar na frente dos personagens nesta comparação.
	for filho in w.entidades.get_children():
		if filho is AnimatedSprite2D:
			filho.visible = false
	var base := w.centro + Vector2(-80, 80)
	for i in CLASSES.size():
		for k in 3:
			var b := Boneco.new()
			b.scale = Vector2(0.25, 0.25)
			b.position = base + Vector2(i * 26, k * 30)
			w.entidades.add_child(b)
			b.vestir({raca = raca, rosto = 0, pele = 0}, {corpo = StringName("roupa_" + String(CLASSES[i]))})
			b.play([&"parado_baixo", &"parado_direita", &"parado_cima"][k])
	var cam := Camera2D.new()
	cam.zoom = Vector2(5.5, 5.5)
	cam.position = base + Vector2(52, 30)
	w.add_child(cam)
	cam.make_current()
	await esperar(0.2)
	var nome_print := "novidades/customizacao.png" if raca == &"humano" else "novidades/customizacao_%s.png" % raca
	await salvar_print(nome_print)
	terminar()
