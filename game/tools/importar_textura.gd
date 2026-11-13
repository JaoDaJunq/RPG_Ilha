extends SceneTree
## Converte uma TEXTURA DE CHÃO do Codex (imagem inteira em pixel art 4x, sem fundo) na textura
## do jogo (L41): o miolo da areia, da lama, da trilha e do piso, que o shader
## terreno_preenchimento repete presa ao mundo.
##   1. reduz cada bloco de `pixel` x `pixel` para 1 pixel, com a cor mais comum do bloco
##      (procura antes onde a grade começa, testando os deslocamentos);
##   2. junta as cores parecidas em `cores` tons (corte pela mediana), como os chãos do pacote,
##      que têm 3 ou 4 tons.
##
## Uso (da raiz):
##   godot --headless --path game --script res://tools/importar_textura.gd -- \
##     --entrada=../art/sprites/tiny/candidatos/l41_textura_lama.png \
##     --saida=res://assets/sprites/tiny/mundo/textura_lama.png [--pixel=4] [--cores=6]

var _args := {}


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			_args[a.substr(2).get_slice("=", 0)] = a.get_slice("=", 1)
	var img := Image.load_from_file(_caminho(_args["entrada"]))
	if img == null or img.is_empty():
		push_error("Não abriu a textura: " + String(_args["entrada"]))
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)
	var px := int(_args.get("pixel", "4"))
	var desl := _deslocamento(img, px)
	var w := (img.get_width() - desl.x) / px
	var h := (img.get_height() - desl.y) / px
	var saida := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var conta := {}
			for dy in px:
				for dx in px:
					var k := img.get_pixel(desl.x + x * px + dx, desl.y + y * px + dy).to_rgba32()
					conta[k] = conta.get(k, 0) + 1
			var melhor: int = conta.keys()[0]
			for k in conta:
				if conta[k] > conta[melhor]:
					melhor = k
			saida.set_pixel(x, y, Color.hex(melhor))
	_reduzir(saida, int(_args.get("cores", "6")))
	var destino := _caminho(_args["saida"])
	DirAccess.make_dir_recursive_absolute(destino.get_base_dir())
	print("grade começa em %s; textura %dx%d; salvo: %s (%s)" % [desl, w, h, destino, error_string(saida.save_png(destino))])
	quit()


## Onde começa a grade: o deslocamento em que menos pixels mudam de cor DENTRO dos blocos.
func _deslocamento(img: Image, px: int) -> Vector2i:
	var melhor := Vector2i.ZERO
	var menor := INF
	for o in px:
		var trocas_x := 0
		var trocas_y := 0
		for y in range(0, img.get_height(), 7):
			for x in range(1, img.get_width()):
				if (x - o) % px != 0 and img.get_pixel(x, y) != img.get_pixel(x - 1, y):
					trocas_x += 1
		for x in range(0, img.get_width(), 7):
			for y in range(1, img.get_height()):
				if (y - o) % px != 0 and img.get_pixel(x, y) != img.get_pixel(x, y - 1):
					trocas_y += 1
		if trocas_x + trocas_y < menor:
			menor = trocas_x + trocas_y
			melhor = Vector2i(o, o)
	return melhor


## Corte pela mediana: divide as cores pela maior faixa até ter `n` grupos; cada pixel vira a
## média do grupo dele.
func _reduzir(img: Image, n: int) -> void:
	var pixels: Array = []
	for y in img.get_height():
		for x in img.get_width():
			pixels.append(img.get_pixel(x, y))
	var grupos: Array = [pixels]
	while grupos.size() < n:
		var maior := 0
		var faixa_maior := -1.0
		var eixo_maior := 0
		for gi in grupos.size():
			var f := _faixa(grupos[gi])
			if f.x > faixa_maior and (grupos[gi] as Array).size() > 1:
				faixa_maior = f.x
				maior = gi
				eixo_maior = int(f.y)
		if faixa_maior <= 0.0:
			break
		var g: Array = grupos[maior]
		g.sort_custom(func(a: Color, b: Color) -> bool: return a[eixo_maior] < b[eixo_maior])
		grupos.remove_at(maior)
		grupos.append(g.slice(0, g.size() / 2))
		grupos.append(g.slice(g.size() / 2))
	var mapa := {}
	for g in grupos:
		var soma := Vector3.ZERO
		for c: Color in g:
			soma += Vector3(c.r, c.g, c.b)
		soma /= (g as Array).size()
		var media := Color(soma.x, soma.y, soma.z)
		for c: Color in g:
			mapa[c.to_rgba32()] = media
	for y in img.get_height():
		for x in img.get_width():
			img.set_pixel(x, y, mapa[img.get_pixel(x, y).to_rgba32()])


func _faixa(cores: Array) -> Vector2:
	var mn := Vector3(1, 1, 1)
	var mx := Vector3.ZERO
	for c: Color in cores:
		mn = Vector3(minf(mn.x, c.r), minf(mn.y, c.g), minf(mn.z, c.b))
		mx = Vector3(maxf(mx.x, c.r), maxf(mx.y, c.g), maxf(mx.z, c.b))
	var d := mx - mn
	if d.x >= d.y and d.x >= d.z:
		return Vector2(d.x, 0)
	if d.y >= d.z:
		return Vector2(d.y, 1)
	return Vector2(d.z, 2)


func _caminho(p: String) -> String:
	if p.begins_with("res://"):
		return ProjectSettings.globalize_path(p)
	if p.is_absolute_path():
		return p
	return ProjectSettings.globalize_path("res://").path_join(p).simplify_path()
