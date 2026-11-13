extends TesteBase
## Prints da fogueira animada do acampamento (L37), dentro do jogo (precisa de janela): uma
## sequência de 3 de dia e 3 à noite (as chamas mudam de quadro e a luz tremula), no zoom
## normal e 2x mais perto. Salva evidence/novidades/fogueira_<dia|noite>_<n>[_zoom].png.


func _ready() -> void:
	var w := await criar_mundo(0, true, &"guerreiro", &"humano", true, 0)
	var p := w.jogador
	w.hud.visible = false
	var fogueira := w.entidades.get_node("FogueiraAcampamento") as Construcao
	checar(fogueira != null and fogueira.chamas() != null and fogueira.chamas().is_playing(), "a fogueira do acampamento tem as chamas animadas")
	p.position = fogueira.position + Vector2(-22, 10)
	p.visual.play(&"parado_direita")
	var cam: Camera2D = p.camera
	cam.position_smoothing_enabled = false
	cam.global_position = fogueira.global_position
	cam.offset = fogueira.global_position - p.global_position + Vector2(0, -8)
	await esperar(0.5)
	for periodo in ["dia", "noite"]:
		if periodo == "noite":
			w._aplicar_ciclo(true, true)
			await esperar(0.3)
		var quadros := {}
		for i in 3:
			await esperar(0.12)
			quadros[fogueira.chamas().frame] = true
			await salvar_print("novidades/fogueira_%s_%d.png" % [periodo, i + 1])
		checar(quadros.size() >= 2, "%s: as chamas trocam de quadro (%d quadros vistos)" % [periodo, quadros.size()])
		cam.zoom *= 2.0
		for i in 3:
			await esperar(0.12)
			await salvar_print("novidades/fogueira_%s_%d_zoom.png" % [periodo, i + 1])
		cam.zoom /= 2.0
	terminar()
