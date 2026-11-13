extends SceneTree
## Monta um tileset novo a partir de uma versão redesenhada pela IA de um tileset pronto
## (ex.: a areia feita em cima da grama do Tiny Swords). A IA acerta o layout mas erra o
## fundo e borra a borda; então:
##   1. reduz a imagem da IA para o tamanho do molde (vizinho mais próximo);
##   2. a transparência vem do molde (onde o molde é transparente, fica transparente);
##   3. o contorno escuro vem do molde (pixel escuro no molde = pixel do molde), para a
##      borda ficar igual à dos outros terrenos.
##
## Uso (da raiz):
##   godot --headless --path game --script res://tools/mascara_tileset.gd -- \
##     --entrada=../art/sprites/tiny/candidatos/areia_tilemap_v1.png \
##     --molde=res://assets/tiny_swords/terreno/grama.png --saida=res://assets/sprites/tiny/areia.png

var _args := {}


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			_args[a.substr(2).get_slice("=", 0)] = a.get_slice("=", 1)
	var molde := Image.load_from_file(_caminho(_args["molde"]))
	var ia := Image.load_from_file(_caminho(_args["entrada"]))
	molde.convert(Image.FORMAT_RGBA8)
	ia.convert(Image.FORMAT_RGBA8)
	ia.resize(molde.get_width(), molde.get_height(), Image.INTERPOLATE_NEAREST)
	var saida := Image.create(molde.get_width(), molde.get_height(), false, Image.FORMAT_RGBA8)
	for y in molde.get_height():
		for x in molde.get_width():
			var m := molde.get_pixel(x, y)
			if m.a == 0.0:
				continue
			if m.get_luminance() < 0.22:
				saida.set_pixel(x, y, m)  # contorno igual ao do terreno original
			else:
				var c := ia.get_pixel(x, y)
				saida.set_pixel(x, y, Color(c.r, c.g, c.b, m.a))
	_tirar_magenta(saida)
	if _args.has("liso"):
		_alisar(saida, molde)
	var destino := _caminho(_args["saida"])
	DirAccess.make_dir_recursive_absolute(destino.get_base_dir())
	print("Salvo: ", destino, " (", error_string(saida.save_png(destino)), ")")
	quit()


## --liso=1: tira os pontinhos (conchas, pedrinhas) do miolo do terreno, que se repetem em
## grade quando o mesmo tile cobre uma área grande. Só mexe onde o molde é "chão" (verde),
## não no penhasco: cor muito diferente da cor mais comum vira a cor mais comum.
func _alisar(img: Image, molde: Image) -> void:
	var conta := {}
	for y in img.get_height():
		for x in img.get_width():
			if _eh_chao(molde.get_pixel(x, y)):
				var k := img.get_pixel(x, y).to_rgba32()
				conta[k] = conta.get(k, 0) + 1
	var comum: int = conta.keys()[0]
	for k in conta:
		if conta[k] > conta[comum]:
			comum = k
	var base := Color.hex(comum)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if _eh_chao(molde.get_pixel(x, y)) and absf(c.r - base.r) + absf(c.g - base.g) + absf(c.b - base.b) > 0.22:
				img.set_pixel(x, y, Color(base.r, base.g, base.b, c.a))


## O fundo magenta da IA entra onde a borda dela não bate com a do molde: cada pixel
## magenta (ou rosado de franja) pega a cor do pixel bom mais perto.
func _tirar_magenta(img: Image) -> void:
	var ruins: Array[Vector2i] = []
	for y in img.get_height():
		for x in img.get_width():
			if _magenta(img.get_pixel(x, y)):
				ruins.append(Vector2i(x, y))
	var original := img.duplicate() as Image
	for p in ruins:
		var achou := false
		for r in range(1, 12):
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					if achou or maxi(absi(dx), absi(dy)) != r:
						continue
					var q := p + Vector2i(dx, dy)
					if q.x < 0 or q.y < 0 or q.x >= img.get_width() or q.y >= img.get_height():
						continue
					var c := original.get_pixel(q.x, q.y)
					if c.a > 0.0 and not _magenta(c):
						img.set_pixel(p.x, p.y, Color(c.r, c.g, c.b, img.get_pixel(p.x, p.y).a))
						achou = true
			if achou:
				break
	print("pixels magenta trocados: ", ruins.size())


static func _magenta(c: Color) -> bool:
	return c.a > 0.0 and c.r - c.g > 0.3 and c.b - c.g > 0.3


func _eh_chao(m: Color) -> bool:
	return m.a > 0.0 and m.get_luminance() >= 0.22 and m.g > m.b + 0.12 and m.r > m.b  # grama amarelada, não o penhasco azulado


func _caminho(p: String) -> String:
	if p.begins_with("res://"):
		return ProjectSettings.globalize_path(p)
	if p.is_absolute_path():
		return p
	return ProjectSettings.globalize_path("res://").path_join(p).simplify_path()
