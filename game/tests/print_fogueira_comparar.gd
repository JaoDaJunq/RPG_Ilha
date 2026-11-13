extends TesteBase
## Compara, dentro do jogo e lado a lado, as fogueiras (precisa de janela):
##   à esquerda, a ANTIGA do L37 (pedras do L12 sem as chamas + chamas do Codex + faíscas do
##   Pixelbolt), remontada com os arquivos guardados em art/sprites/tiny/fogueira_l37/;
##   no meio, a NOVA do jogo (L41, pixel art 4x, um desenho só);
##   à direita, a outra versão nova (L41, ilustração convertida com pixelizar.gd), se a tira
##   estiver em art/sprites/tiny/candidatos/ (fora do git).
## Salva evidence/comparacao/fogueira_nova_<dia|noite>_<n>.png.

const ANTIGA := "res://../art/sprites/tiny/fogueira_l37/"
const ILUSTRACAO := "res://../art/sprites/tiny/candidatos/l41_fogueira_ilus_final.png"


func _ready() -> void:
	var w := await criar_mundo(0, true, &"guerreiro", &"humano", true, 0)
	var p := w.jogador
	p.visible = false
	w.hud.visible = false
	var centro := p.position + Vector2(0, 60)
	p.position = centro
	_antiga(w, centro + Vector2(-34, -8))
	var nova := Construcao.new()
	nova.tipo = &"fogueira"
	nova.fixa = true
	nova.position = centro + Vector2(0, -8)
	w.entidades.add_child(nova)
	var ilus := _textura(ILUSTRACAO)
	if ilus:
		_animada(w, ilus, Vector2i(128, 128), 6, 8.0, centro + Vector2(34, -8), Vector2(-64, -120))
	p.camera.position_smoothing_enabled = false
	p.camera.zoom *= 4.0
	await esperar(0.5)
	for periodo in ["dia", "noite"]:
		if periodo == "noite":
			w._aplicar_ciclo(true, true)
			await esperar(0.3)
		for i in 3:
			await esperar(0.15)
			await salvar_print("comparacao/fogueira_nova_%s_%d.png" % [periodo, i + 1])
	terminar()


## A fogueira do L37 como era: pedras paradas, chamas e faíscas por cima, com a luz dela.
func _antiga(w: World, pos: Vector2) -> void:
	var base := Sprite2D.new()
	base.texture = _textura(ANTIGA + "fogueira_base.png")
	base.centered = false
	base.scale = Vector2.ONE * 0.25
	base.offset = Vector2(-64, -120)
	base.position = pos
	w.entidades.add_child(base)
	_animada(w, _textura(ANTIGA + "fogueira_chamas.png"), Vector2i(40, 40), 6, 8.0, pos, Vector2(-20, -56))
	_animada(w, _textura(ANTIGA + "fogueira_faiscas.png"), Vector2i(40, 72), 24, 9.0, pos, Vector2(-20, -93))
	var luz := PointLight2D.new()
	luz.texture = Construcao.LUZ
	luz.color = Color(1, 0.6, 0.3)
	luz.energy = 0.8
	luz.texture_scale = 3.6
	luz.position = pos + Vector2(0, -12)
	luz.add_to_group(&"luzes_noturnas")
	luz.enabled = false
	w.entidades.add_child(luz)


func _animada(w: World, tex: Texture2D, quadro: Vector2i, n: int, fps: float, pos: Vector2, canto: Vector2) -> void:
	var quadros := SpriteFrames.new()
	quadros.remove_animation(&"default")
	SpriteSheets.adicionar_tira(quadros, tex, &"fogo", quadro, n, fps)
	var a := AnimatedSprite2D.new()
	a.sprite_frames = quadros
	a.centered = false
	a.scale = Vector2.ONE * 0.25
	a.offset = canto
	a.position = pos
	w.entidades.add_child(a)
	a.play(&"fogo")


func _textura(caminho: String) -> Texture2D:
	var img := Image.load_from_file(ProjectSettings.globalize_path(caminho))
	return ImageTexture.create_from_image(img) if img else null
