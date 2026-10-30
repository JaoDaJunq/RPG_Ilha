extends TesteBase
## Piloto de estilo DENTRO do jogo, antes de integrar. Mesmo lugar e mesma arrumação para
## os dois estilos em teste, para comparar lado a lado:
##   --estilo=pixel  processo v2 (L09): pixel art com personagem 64x64 e árvore 96x96
##   --estilo=hd     desenho de alta resolução (L10), reduzido com filtro suave
## Câmera em zoom 2, chão calmo do L08. Lê de art/sprites/<...>/convertido/ (fora de game/
## até o João aprovar). Salva evidence/piloto_<estilo>/acampamento.png e praia.png.

const ZOOM := 2
## Altura no mundo de cada desenho HD (o pixel usa o tamanho do próprio sprite).
const ALTURA_HD := {&"mago": 44.0, &"ogro": 44.0, &"arvore": 88.0, &"arvore_rosa": 88.0, &"pedra": 30.0, &"arbusto": 28.0}
## Onde está cada coisa no estilo pixel: [folha, tamanho do quadro, índice].
const PIXEL := {
	&"mago_frente": ["personagens", 64, 0], &"mago_costas": ["personagens", 64, 1], &"mago_perfil": ["personagens", 64, 2],
	&"ogro_frente": ["personagens", 64, 3], &"ogro_costas": ["personagens", 64, 4], &"ogro_perfil": ["personagens", 64, 5],
	&"arvore": ["natureza2", 96, 0], &"arvore_rosa": ["natureza2", 96, 1], &"pedra": ["natureza2", 96, 2],
	&"arbusto": ["natureza2", 96, 3], &"toco": ["natureza", 128, 2], &"fogueira": ["natureza", 128, 5],
}

var estilo := "pixel"
var raiz := ProjectSettings.globalize_path("res://").path_join("../art/sprites")


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--estilo="):
			estilo = a.get_slice("=", 1)
	var w := await criar_mundo(0, true, &"mago")
	w.jogador.visible = false
	w.hud.visible = false
	for n in w.entidades.get_children():
		if n is Sprite2D or n is StaticBody2D:
			n.queue_free()
	_trocar_chao(w)
	var cam := Camera2D.new()
	cam.zoom = Vector2(ZOOM, ZOOM)
	w.add_child(cam)
	cam.make_current()

	var c := w.centro
	_objeto(&"fogueira", c + Vector2(0, 12), w)
	var lados := [&"frente", &"costas", &"perfil"]
	for i in 3:
		_objeto(StringName("mago_" + lados[i]), c + Vector2(-90 + i * 34, 64), w)
		_objeto(StringName("ogro_" + lados[i]), c + Vector2(40 + i * 34, 64), w)
	for p in [Vector2(-250, -60), Vector2(-190, 150), Vector2(230, -80), Vector2(280, 90), Vector2(-120, -120)]:
		_objeto(&"arvore", c + p, w)
	for p in [Vector2(150, -130), Vector2(-280, 60)]:
		_objeto(&"arvore_rosa", c + p, w)
	_objeto(&"toco", c + Vector2(110, 140), w)
	_objeto(&"pedra", c + Vector2(-150, 30), w)
	_objeto(&"pedra", c + Vector2(180, 30), w)
	_objeto(&"arbusto", c + Vector2(-60, 150), w)
	_objeto(&"arbusto", c + Vector2(60, -80), w)
	cam.position = c + Vector2(0, 20)
	await esperar(0.4)
	await salvar_print("piloto_%s/acampamento.png" % estilo)

	var x := 0
	while w.tipo_do_chao(Vector2i(x, w.altura / 2)) != World.Chao.GRAMA:
		x += 1
	var b := Vector2(x * World.T, c.y)
	for p in [Vector2(120, -110), Vector2(220, 40), Vector2(330, -60)]:
		_objeto(&"arvore", b + p, w)
	_objeto(&"arvore_rosa", b + Vector2(110, 150), w)
	_objeto(&"pedra", b + Vector2(10, -60), w)
	_objeto(&"arbusto", b + Vector2(160, 70), w)
	_objeto(&"mago_frente", b + Vector2(-20, 40), w)
	_objeto(&"ogro_perfil", b + Vector2(30, 36), w)
	cam.position = b + Vector2(120, 20)
	await esperar(0.4)
	await salvar_print("piloto_%s/praia.png" % estilo)
	terminar()


var _cache := {}


func _textura(arquivo: String, suave: bool) -> Texture2D:
	if not _cache.has(arquivo):
		var img := Image.load_from_file(arquivo)
		if suave:
			img.generate_mipmaps()
		_cache[arquivo] = ImageTexture.create_from_image(img)
	return _cache[arquivo]


## Põe o desenho com a base em `pos`. No HD, o que não tem arte ainda (costas, perfil,
## toco, fogueira) usa a frente do personagem ou fica de fora.
func _objeto(nome: StringName, pos: Vector2, w: World) -> void:
	var s := Sprite2D.new()
	s.centered = false
	if estilo == "hd":
		var base := StringName(String(nome).get_slice("_", 0)) if String(nome).begins_with("mago") or String(nome).begins_with("ogro") else nome
		if not ALTURA_HD.has(base):
			return
		s.texture = _textura(raiz.path_join("desenho_hd/convertido/%s.png" % base), true)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var k: float = ALTURA_HD[base] / s.texture.get_height()
		s.scale = Vector2(k, k)
		s.offset = Vector2(-s.texture.get_width() / 2.0, -s.texture.get_height())
	else:
		var p: Array = PIXEL[nome]
		var q: int = p[1]
		s.texture = _textura(raiz.path_join("processo_v2/convertido/%s.png" % p[0]), false)
		s.region_enabled = true
		s.region_rect = Rect2(int(p[2]) * q, 0, q, q)
		s.offset = Vector2(-q / 2.0, -q)
	s.position = pos.round()
	w.entidades.add_child(s)


## Chão calmo do piloto L08 (grama, areia e água quase lisas), para os sprites se destacarem.
## A terra ainda não tem arte nova: fica a cor principal da terra antiga, sem detalhe.
func _trocar_chao(w: World) -> void:
	var novo := Image.load_from_file(raiz.path_join("piloto_simples/convertido/chao.png"))
	novo.convert(Image.FORMAT_RGBA8)
	var velho := World.TEX_CHAO.get_image()
	velho.convert(Image.FORMAT_RGBA8)
	var img := Image.create(192, 32, false, Image.FORMAT_RGBA8)
	for i in 6:
		var bloco: int = [0, 0, -1, 1, 2, -1][i]
		if bloco >= 0:
			img.blit_rect(novo, Rect2i(bloco * 32, 0, 32, 32), Vector2i(i * 32, 0))
	img.fill_rect(Rect2i(2 * 32, 0, 32, 32), _cor_principal(velho, 2))
	img.fill_rect(Rect2i(5 * 32, 0, 32, 32), _cor_principal(novo, 0))
	(w.chao_suave.material as ShaderMaterial).set_shader_parameter(&"chao_tex", ImageTexture.create_from_image(img))


func _cor_principal(img: Image, bloco: int) -> Color:
	var conta := {}
	for y in 32:
		for x in 32:
			var c := img.get_pixel(bloco * 32 + x, y).to_rgba32()
			conta[c] = conta.get(c, 0) + 1
	var melhor: int = conta.keys()[0]
	for c in conta:
		if conta[c] > conta[melhor]:
			melhor = c
	return Color.hex(melhor)


func _objeto(folha: String, quadro: int, i: int, pos: Vector2, w: World) -> void:
	if not _cache.has(folha):
		_cache[folha] = ImageTexture.create_from_image(Image.load_from_file(pasta.path_join(folha + ".png")))
	var s := Sprite2D.new()
	s.texture = _cache[folha]
	s.region_enabled = true
	s.region_rect = Rect2(i * quadro, 0, quadro, quadro)
	s.centered = false
	s.offset = Vector2(-quadro / 2.0, -quadro)
	s.position = pos.round()
	w.entidades.add_child(s)
