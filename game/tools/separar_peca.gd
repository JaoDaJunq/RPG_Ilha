extends SceneTree
## Peças separadas (L27): cada peça (cabelo, roupa, chapéu) é desenhada sozinha, em cima do
## FANTASMA (o boneco careca em cinza-claro, só como guia de tamanho e lugar). Esta ferramenta
## tira o fantasma e fica só com a peça, em pixel art na mesma escala do boneco base:
##   1. acha quanto a imagem andou em relação ao fantasma (quase tudo nela é o fantasma);
##   2. a peça é o que não é fantasma (o fantasma é cinza-claro, a peça é colorida);
##   3. reduz pela escala do boneco base, paleta do pacote e contorno #161c2e.
## Também monta o fantasma (--fazer_fantasma) e a cabeça careca (--fazer_careca).
##
## Uso (da raiz):
##   godot --headless --path game --script res://tools/separar_peca.gd -- \
##     --careca=../art/sprites/tiny/gabarito/gabarito_humano_careca.png --fazer_fantasma \
##     --fantasma=../art/sprites/tiny/gabarito/fantasma_humano.png
##   ... --careca=<folha careca> --fazer_careca --base=res://assets/sprites/tiny/bonecos/humano/base \
##     --saida=res://assets/sprites/tiny/bonecos/humano/pecas
##   ... --careca=<folha careca> --fantasma=<fantasma> --peca=../art/sprites/tiny/gabarito/peca_cabelo_1.png \
##     --nome=cabelo_1 --saida=res://assets/sprites/tiny/bonecos/humano/pecas [--conferir=<png>]
## Grava <saida>/<nome><vista>.png e <nome><vista>.json ({<nome>: [x, y]}: canto de cima à
## esquerda em pixels da arte, com a origem nos pés, como as peças do boneco).

const COLUNA := 512
const VISTAS := ["", "_frente", "_costas"]
const CONTORNO := Color("161c2e")
const PALETA := "res://assets/tiny_swords/paleta.png"
const REDUZ := 4
const BUSCA := 12

var _args := {}
var _paleta: Array[Color] = []


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			_args[a.substr(2).get_slice("=", 0)] = a.get_slice("=", 1) if a.contains("=") else "1"
	var pal := Image.load_from_file(ProjectSettings.globalize_path(PALETA))
	pal.convert(Image.FORMAT_RGBA8)
	for x in pal.get_width():
		_paleta.append(pal.get_pixel(x, 0))
	var careca := _abrir(_args["careca"])
	if _args.has("fazer_fantasma"):
		_fazer_fantasma(careca)
	elif _args.has("fazer_careca"):
		_fazer_careca(careca)
	else:
		_separar(careca)
	quit()


## O fantasma: o boneco careca em cinza-claro (entre 75% e 95% de luz), com o contorno também
## cinza. Assim nenhuma cor de peça se confunde com ele.
func _fazer_fantasma(careca: Image) -> void:
	var f := careca.duplicate() as Image
	for y in f.get_height():
		for x in f.get_width():
			var c := f.get_pixel(x, y)
			if _magenta(c):
				continue
			var g := 0.75 + 0.2 * (c.r * 0.299 + c.g * 0.587 + c.b * 0.114)
			f.set_pixel(x, y, Color(g, g, g + 0.02))
	f.save_png(_caminho(_args["fantasma"]))
	print("fantasma salvo")


## A cabeça careca de cada vista: o pedaço do boneco careca (em pixel art) que fica no lugar
## da cabeça do boneco base.
func _fazer_careca(careca: Image) -> void:
	var base := _caminho(_args["base"])
	var saida := _caminho(_args["saida"])
	DirAccess.make_dir_recursive_absolute(saida)
	for i in VISTAS.size():
		var v: String = VISTAS[i]
		var col := _limpar(careca.get_region(Rect2i(i * COLUNA, 0, COLUNA, careca.get_height())))
		var m := _medidas(col)
		var px := _pixelizar(col, m.fator)
		var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base.path_join("pecas" + v + ".json")))
		var cab := Image.load_from_file(base.path_join("cabeca" + v + ".png"))
		# A caixa da cabeça base, com folga dos lados e em cima (a careca é um pouco diferente).
		var canto := Vector2i(roundi(j["cabeca"][0] + m.ref.x), roundi(j["cabeca"][1] + m.ref.y))
		var r := Rect2i(canto - Vector2i(4, 4), cab.get_size() + Vector2i(8, 4)).intersection(Rect2i(Vector2i.ZERO, px.get_size()))
		var img := px.get_region(r)
		var u := img.get_used_rect()
		img.get_region(u).save_png(saida.path_join("careca" + v + ".png"))
		_salvar_lugar(saida, "careca" + v, "careca", Vector2(r.position + u.position) - m.ref)
		print("careca%s: %s" % [v, u.size])


func _separar(careca: Image) -> void:
	var fantasma := _abrir(_args["fantasma"])
	var peca := _abrir(_args["peca"])
	if peca.get_size() != fantasma.get_size():
		peca.resize(fantasma.get_width(), fantasma.get_height(), Image.INTERPOLATE_LANCZOS)
	var nome: String = _args["nome"]
	var saida := _caminho(_args["saida"])
	DirAccess.make_dir_recursive_absolute(saida)
	var conferir: Array[Image] = []
	for i in VISTAS.size():
		var v: String = VISTAS[i]
		var m := _medidas(_limpar(careca.get_region(Rect2i(i * COLUNA, 0, COLUNA, careca.get_height()))))
		var cf := _limpar(fantasma.get_region(Rect2i(i * COLUNA, 0, COLUNA, fantasma.get_height())))
		var cp := _limpar(peca.get_region(Rect2i(i * COLUNA, 0, COLUNA, peca.get_height())))
		var al := _alinhar(cf, cp)
		cp = _deslocar(cp, -(al.desl as Vector2i))
		# A peça: o que não é fantasma (o fantasma é cinza-claro, quase sem cor).
		var so := Image.create(cp.get_width(), cp.get_height(), false, Image.FORMAT_RGBA8)
		for y in cp.get_height():
			for x in cp.get_width():
				var c := cp.get_pixel(x, y)
				if c.a < 0.5:
					continue
				# Fora do fantasma, tudo é peça (as penas da aljava, a aba do chapéu); em cima dele, o
				# cinza-claro é o próprio fantasma.
				var no_fantasma := cf.get_pixel(x, y).a > 0.5
				if no_fantasma and _fantasma(c):
					continue
				so.set_pixel(x, y, c)
		_tirar_pontinhos(so, 300)
		var px := _pixelizar(so, m.fator)
		if _args.has("base") and nome.begins_with("roupa_"):
			_so_corpo(px, v, m.ref, _pixelizar(cf, m.fator))
		_tirar_tracos_soltos(px)
		_tirar_pontinhos(px, 6)
		var u := px.get_used_rect()
		px.get_region(u).save_png(saida.path_join(nome + v + ".png"))
		_salvar_lugar(saida, nome + v, nome, Vector2(u.position) - m.ref)
		print("%s%s: deslocamento %s, %s" % [nome, v, al.desl, u.size])
		var conf := _pixelizar(cf, m.fator)
		conf.blend_rect(px, Rect2i(Vector2i.ZERO, px.get_size()), Vector2i.ZERO)
		conferir.append(conf.get_region(conf.get_used_rect().grow(2).intersection(Rect2i(Vector2i.ZERO, conf.get_size()))))
	if _args.has("conferir"):
		var w := 0
		var h := 0
		for c in conferir:
			w += c.get_width() + 4
			h = maxi(h, c.get_height())
		var folha := Image.create(w, h, false, Image.FORMAT_RGBA8)
		folha.fill(Color(0.3, 0.42, 0.33))
		var x := 0
		for c in conferir:
			folha.blend_rect(c, Rect2i(Vector2i.ZERO, c.get_size()), Vector2i(x, 0))
			x += c.get_width() + 4
		folha.resize(w * 4, h * 4, Image.INTERPOLATE_NEAREST)
		var destino := _caminho(_args["conferir"])
		DirAccess.make_dir_recursive_absolute(destino.get_base_dir())
		folha.save_png(destino)


## Escala e pés do boneco da coluna (os mesmos do boneco base: altura de 80 pixels da arte).
func _medidas(col: Image) -> Dictionary:
	var caixa := col.get_used_rect()
	var fator := float(_args.get("altura", "80")) / caixa.size.y
	return {fator = fator, ref = Vector2(caixa.position.x + caixa.size.x / 2.0, caixa.end.y) * fator}


func _fantasma(c: Color) -> bool:
	var luz := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
	return luz > 0.68 and maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b)) < 0.08


func _salvar_lugar(saida: String, arquivo: String, chave: String, pos: Vector2) -> void:
	var f := FileAccess.open(saida.path_join(arquivo + ".json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({chave: [roundi(pos.x), roundi(pos.y)]}, "  "))
	f.close()


func _alinhar(cf: Image, cp: Image) -> Dictionary:
	var g := cf.duplicate() as Image
	var v := cp.duplicate() as Image
	g.resize(cf.get_width() / REDUZ, cf.get_height() / REDUZ, Image.INTERPOLATE_BILINEAR)
	v.resize(cp.get_width() / REDUZ, cp.get_height() / REDUZ, Image.INTERPOLATE_BILINEAR)
	var w := g.get_width()
	var h := g.get_height()
	var pontos: Array = []
	for y in h:
		for x in w:
			if g.get_pixel(x, y).a > 0.9:
				pontos.append(Vector2i(x, y))
	var melhor := {desl = Vector2i.ZERO, igual = -1}
	for dy in range(-BUSCA, BUSCA + 1):
		for dx in range(-BUSCA, BUSCA + 1):
			var iguais := 0
			for p: Vector2i in pontos:
				var q := p + Vector2i(dx, dy)
				if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and v.get_pixelv(q).a > 0.5 and _fantasma(v.get_pixelv(q)):
					iguais += 1
			if iguais > melhor.igual:
				melhor = {desl = Vector2i(dx, dy) * REDUZ, igual = iguais}
	return melhor


func _deslocar(img: Image, d: Vector2i) -> Image:
	var r := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	r.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), d)
	return r


func _tirar_pontinhos(img: Image, minimo: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var visto := PackedByteArray()
	visto.resize(w * h)
	for i in w * h:
		if visto[i] == 1 or img.get_pixel(i % w, i / w).a < 0.5:
			continue
		var fila := PackedInt32Array([i])
		visto[i] = 1
		var n := 0
		while n < fila.size():
			var p := fila[n]
			n += 1
			for d: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var q: Vector2i = Vector2i(p % w, p / w) + d
				if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
					continue
				var k := q.y * w + q.x
				if visto[k] == 0 and img.get_pixelv(q).a > 0.5:
					visto[k] = 1
					fila.append(k)
		if fila.size() < minimo:
			for p in fila:
				img.set_pixel(p % w, p / w, Color(0, 0, 0, 0))


func _pixelizar(img: Image, fator: float) -> Image:
	var r := img.duplicate() as Image
	r.resize(maxi(1, roundi(img.get_width() * fator)), maxi(1, roundi(img.get_height() * fator)), Image.INTERPOLATE_LANCZOS)
	for y in r.get_height():
		for x in r.get_width():
			var c := r.get_pixel(x, y)
			r.set_pixel(x, y, Color(0, 0, 0, 0) if c.a < 0.5 else _mais_proxima(c))
	var copia := r.duplicate() as Image
	for y in r.get_height():
		for x in r.get_width():
			if copia.get_pixel(x, y).a == 0.0:
				continue
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var p: Vector2i = Vector2i(x, y) + d
				if p.x < 0 or p.y < 0 or p.x >= r.get_width() or p.y >= r.get_height() or copia.get_pixelv(p).a == 0.0:
					r.set_pixel(x, y, CONTORNO)
					break
	return r


func _mais_proxima(c: Color) -> Color:
	var melhor := _paleta[0]
	var dist := 99.0
	for p in _paleta:
		var d := (c.r - p.r) * (c.r - p.r) * 0.3 + (c.g - p.g) * (c.g - p.g) * 0.59 + (c.b - p.b) * (c.b - p.b) * 0.11
		if d < dist:
			dist = d
			melhor = p
	return melhor


func _magenta(c: Color) -> bool:
	return c.a < 0.5 or minf(c.r, c.b) - c.g > 0.45


func _limpar(img: Image) -> Image:
	var r := img.duplicate() as Image
	r.convert(Image.FORMAT_RGBA8)
	for y in r.get_height():
		for x in r.get_width():
			if _magenta(r.get_pixel(x, y)):
				r.set_pixel(x, y, Color(0, 0, 0, 0))
	return r


func _abrir(p: String) -> Image:
	var img := Image.load_from_file(_caminho(p))
	img.convert(Image.FORMAT_RGBA8)
	return img


func _caminho(p: String) -> String:
	if p.begins_with("res://"):
		return ProjectSettings.globalize_path(p)
	if p.is_absolute_path():
		return p
	return ProjectSettings.globalize_path("res://").path_join(p).simplify_path()




## Roupa do corpo (--base): só fica o que está abaixo do pescoço, e, em cima das mãos e dos
## pés (que são peças que se mexem), só o que é colorido (a manga, a barra do manto); o traço
## escuro ali é o contorno do fantasma que a IA redesenhou. Depois refaz o contorno.
func _so_corpo(px: Image, v: String, ref: Vector2, fantasma: Image) -> void:
	var base := _caminho(_args["base"])
	var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base.path_join("pecas" + v + ".json")))
	var cab := Image.load_from_file(base.path_join("cabeca" + v + ".png"))
	var pescoco := roundi(j["cabeca"][1] + cab.get_height() + ref.y) - 3
	var caixas: Array[Rect2i] = []
	for peca in [["pe_frente", "pe"], ["pe_tras", "pe"], ["mao_frente", "mao"], ["mao_tras", "mao"]]:
		var t := Image.load_from_file(base.path_join(peca[1] + ".png"))
		caixas.append(Rect2i(Vector2i(roundi(j[peca[0]][0] + ref.x), roundi(j[peca[0]][1] + ref.y)), t.get_size()).grow(1))
	for y in px.get_height():
		for x in px.get_width():
			var c := px.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var some := y < pescoco
			# Traço escuro em cima da beira do fantasma: é o contorno dele (o da roupa é refeito
			# logo abaixo).
			if not some and c.r * 0.299 + c.g * 0.587 + c.b * 0.114 < 0.2 and _na_beira(fantasma, x, y):
				some = true
			if not some and c.r * 0.299 + c.g * 0.587 + c.b * 0.114 < 0.3:
				for r in caixas:
					if r.has_point(Vector2i(x, y)):
						some = true
						break
			if some:
				px.set_pixel(x, y, Color(0, 0, 0, 0))
	_tirar_pontinhos(px, 6)
	var copia := px.duplicate() as Image
	for y in px.get_height():
		for x in px.get_width():
			if copia.get_pixel(x, y).a == 0.0:
				continue
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var p: Vector2i = Vector2i(x, y) + d
				if p.x < 0 or p.y < 0 or p.x >= px.get_width() or p.y >= px.get_height() or copia.get_pixelv(p).a == 0.0:
					px.set_pixel(x, y, CONTORNO)
					break


## Traços soltos: manchas que são quase só contorno escuro, sem cor dentro, são o contorno do
## fantasma que a IA redesenhou (as bolinhas das mãos, a borda da cabeça). A peça de verdade
## tem cor dentro do contorno.
func _tirar_tracos_soltos(px: Image) -> void:
	var w := px.get_width()
	var h := px.get_height()
	var visto := PackedByteArray()
	visto.resize(w * h)
	for i in w * h:
		if visto[i] == 1 or px.get_pixel(i % w, i / w).a < 0.5:
			continue
		var fila := PackedInt32Array([i])
		visto[i] = 1
		var escuros := 0
		var n := 0
		while n < fila.size():
			var p := fila[n]
			n += 1
			var c := px.get_pixel(p % w, p / w)
			if c.r * 0.299 + c.g * 0.587 + c.b * 0.114 < 0.2:
				escuros += 1
			for d: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1)]:
				var q: Vector2i = Vector2i(p % w, p / w) + d
				if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
					continue
				var k := q.y * w + q.x
				if visto[k] == 0 and px.get_pixelv(q).a > 0.5:
					visto[k] = 1
					fila.append(k)
		if escuros > fila.size() * 0.6:
			for p in fila:
				px.set_pixel(p % w, p / w, Color(0, 0, 0, 0))


func _na_beira(img: Image, x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var p := Vector2i(x + dx, y + dy)
			var dentro := p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height() and img.get_pixelv(p).a > 0.5
			if not dentro:
				return img.get_pixel(clampi(x, 0, img.get_width() - 1), clampi(y, 0, img.get_height() - 1)).a > 0.5 or dx != 0 or dy != 0
	return false
