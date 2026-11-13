extends TesteBase
## Compara, dentro do jogo, as duas chamas da fogueira (L37) lado a lado sobre as mesmas
## pedras: à esquerda a simulada pelo Pixelbolt (candidata, art/fx_receitas/fogueira.fluid.json,
## convertida em art/sprites/tiny/candidatos/l37_chamas_pixelbolt_tira.png, fora do git), à
## direita a fogueira do jogo (chamas do Codex + faíscas do Pixelbolt).
## Salva evidence/comparacao/fogueira_chamas_<dia|noite>_<n>.png.

const PIXELBOLT := "res://../art/sprites/tiny/candidatos/l37_chamas_pixelbolt_tira.png"


func _ready() -> void:
	var w := await criar_mundo(0, true, &"guerreiro", &"humano", true, 0)
	var p := w.jogador
	p.visible = false
	w.hud.visible = false
	var img := Image.load_from_file(ProjectSettings.globalize_path(PIXELBOLT))
	if img == null:
		checar(false, "falta a tira do Pixelbolt: " + PIXELBOLT)
		terminar()
		return
	var quadros := SpriteFrames.new()
	quadros.remove_animation(&"default")
	SpriteSheets.adicionar_tira(quadros, ImageTexture.create_from_image(img), &"fogo", Vector2i(40, 56), 8, 9.0)
	var centro := p.position + Vector2(0, 60)
	p.position = centro
	# Esquerda: as mesmas pedras com as chamas simuladas.
	var base := Sprite2D.new()
	base.texture = Construcao.FOGUEIRA_BASE
	base.centered = false
	base.scale = Vector2.ONE * 0.25
	base.offset = Vector2(-64, -120)
	base.position = centro + Vector2(-18, -10)
	w.entidades.add_child(base)
	var ch := AnimatedSprite2D.new()
	ch.sprite_frames = quadros
	ch.centered = false
	ch.scale = Vector2.ONE * 0.25
	ch.offset = Vector2(-20, -75)
	ch.position = base.position
	w.entidades.add_child(ch)
	ch.play(&"fogo")
	# Direita: a fogueira do jogo (Construcao).
	var a := Construcao.new()
	a.tipo = &"fogueira"
	a.fixa = true
	a.position = centro + Vector2(18, -10)
	w.entidades.add_child(a)
	p.camera.position_smoothing_enabled = false
	p.camera.zoom *= 5.0
	await esperar(0.5)
	for periodo in ["dia", "noite"]:
		if periodo == "noite":
			w._aplicar_ciclo(true, true)
			await esperar(0.3)
		for i in 3:
			await esperar(0.15)
			await salvar_print("comparacao/fogueira_chamas_%s_%d.png" % [periodo, i + 1])
	terminar()
