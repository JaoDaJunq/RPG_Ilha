extends SceneTree
## Roupa pelo gabarito (L26, opção A da pesquisa em design/pesquisa_roupas.md): a folha do
## gabarito tem o boneco base nas 3 vistas (uma por coluna de 512 px: perfil, frente, costas)
## e a folha "vestida" é a MESMA imagem com o boneco vestido pelo Codex. Para cada vista:
##   1. acha quanto a imagem vestida andou em relação ao gabarito (a IA às vezes desloca);
##   2. passa as duas para pixel art com a mesma escala do boneco base (paleta e contorno);
##   3. o que mudou é a roupa: acima do pescoço vai para o chapéu, abaixo para o corpo;
##   4. o contorno de tudo o que se vê da cabeça vestida vira a máscara da cabeça (o cabelo
##      fora dela some quando o chapéu está na cabeça, em qualquer rosto).
## Grava em <saida>/: roupa_corpo<v>.png, roupa_cabeca<v>.png, mascara<v>.png e roupa<v>.json
## (canto de cima à esquerda de cada um, em pixels da arte, com a origem nos pés), e uma folha
## de conferência em <conferir> (gabarito | vestido | o que foi recortado).
##
## Uso (da raiz):
##   godot --headless --path game --script res://tools/vestir_gabarito.gd -- \
##     --gabarito=../art/sprites/tiny/gabarito/gabarito_humano.png \
##     --vestido=../art/sprites/tiny/gabarito/gabarito_humano_mago.png \
##     --base=res://assets/sprites/tiny/bonecos/humano/base \
##     --saida=res://assets/sprites/tiny/bonecos/humano/mago [--altura=80] \
##     [--conferir=../evidence/comparacao/gabarito_mago.png]

const COLUNA := 512
const VISTAS := ["", "_frente", "_costas"]
const CONTORNO := Color("161c2e")
const PALETA := "res://assets/tiny_swords/paleta.png"
const REDUZ := 4  # o alinhamento é procurado com a imagem 4x menor
const BUSCA := 16  # até 16 x 4 = 64 px de deslocamento
## Cores de pele (as mesmas de boneco.gd): o chapéu nunca leva pele; ela vem sempre da cabeça
## do boneco, no tom escolhido. --pele=f4d296,... troca a lista (o ogro é verde).
const PELE_HUMANO := "f4d296,f8d4a6,ffbc88,f8cb93,f4a47b,f2e7a0,ea9461,db9c68"

var _args := {}
var _paleta: Array[Color] = []


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			_args[a.substr(2).get_slice("=", 0)] = a.get_slice("=", 1)
	var pal := Image.load_from_file(ProjectSettings.globalize_path(PALETA))
	pal.convert(Image.FORMAT_RGBA8)
	for x in pal.get_width():
		_paleta.append(pal.get_pixel(x, 0))
	var gab := _abrir(_args["gabarito"])
	var vest := _abrir(_args["vestido"])
	if vest.get_size() != gab.get_size():
		vest.resize(gab.get_width(), gab.get_height(), Image.INTERPOLATE_LANCZOS)
	var altura := float(_args.get("altura", "80"))
	var base := _caminho(_args["base"])
	var saida := _caminho(_args["saida"])
	DirAccess.make_dir_recursive_absolute(saida)
	var conferir: Array[Image] = []
	for i in VISTAS.size():
		var v: String = VISTAS[i]
		var cg := _limpar(gab.get_region(Rect2i(i * COLUNA, 0, COLUNA, gab.get_height())))
		var cv := _limpar(vest.get_region(Rect2i(i * COLUNA, 0, COLUNA, vest.get_height())))
		var caixa := cg.get_used_rect()
		var fator := altura / caixa.size.y
		var ref := Vector2(caixa.position.x + caixa.size.x / 2.0, caixa.end.y) * fator  # pés, em pixels da arte
		var alinhado := _alinhar(cg, cv)
		var desl: Vector2i = alinhado.desl
		print("vista '%s': deslocamento %s, %.0f%% do corpo igual" % [v, desl, alinhado.igual * 100.0])
		var pg := _pixelizar(cg, fator)
		var pv := _pixelizar(_deslocar(cv, -desl), fator)
		# O pescoço: a base da cabeça do boneco base (abaixo dela é o corpo).
		var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base.path_join("pecas" + v + ".json")))
		var cab := Image.load_from_file(base.path_join("cabeca" + v + ".png"))
		var pescoco := roundi(j["cabeca"][1] + cab.get_height() + ref.y) - 2
		# Os pés e as mãos são peças que se mexem sozinhas: o que a IA redesenhou neles não é roupa.
		var fora := Image.create(pg.get_width(), pg.get_height(), false, Image.FORMAT_RGBA8)
		for peca in [["pe_frente", "pe"], ["pe_tras", "pe"], ["mao_frente", "mao"], ["mao_tras", "mao"]]:
			var t := Image.load_from_file(base.path_join(peca[1] + ".png"))
			var canto := Vector2i(roundi(j[peca[0]][0] + ref.x), roundi(j[peca[0]][1] + ref.y))
			for y in range(-2, t.get_height() + 2):
				for x in range(-2, t.get_width() + 2):
					var p := canto + Vector2i(x, y)
					if p.x >= 0 and p.y >= 0 and p.x < fora.get_width() and p.y < fora.get_height():
						fora.set_pixelv(p, Color.WHITE)
		var camadas := _recortar(pg, pv, pescoco, fora)
		var pos := {}
		for nome in ["roupa_cabeca", "roupa_corpo", "mascara"]:
			var img: Image = camadas[nome]
			var u := img.get_used_rect()
			if u.size == Vector2i.ZERO:
				continue
			img.get_region(u).save_png(saida.path_join(nome + v + ".png"))
			pos[nome.trim_prefix("roupa_")] = [roundi(u.position.x - ref.x), roundi(u.position.y - ref.y)]
		var f := FileAccess.open(saida.path_join("roupa" + v + ".json"), FileAccess.WRITE)
		f.store_string(JSON.stringify(pos, "  "))
		f.close()
		print("  salvo: %s" % pos)
		conferir.append(_folha_conferir(pg, pv, camadas))
	if _args.has("conferir"):
		var w := 0
		var h := 0
		for c in conferir:
			w = maxi(w, c.get_width())
			h += c.get_height()
		var folha := Image.create(w, h, false, Image.FORMAT_RGBA8)
		folha.fill(Color(0.3, 0.42, 0.33))
		var y := 0
		for c in conferir:
			folha.blend_rect(c, Rect2i(Vector2i.ZERO, c.get_size()), Vector2i(0, y))
			y += c.get_height()
		folha.resize(w * 4, h * 4, Image.INTERPOLATE_NEAREST)
		var destino := _caminho(_args["conferir"])
		DirAccess.make_dir_recursive_absolute(destino.get_base_dir())
		folha.save_png(destino)
	quit()


## Separa o que mudou (a roupa) e o contorno da cabeça vestida.
func _recortar(pg: Image, pv: Image, pescoco: int, fora: Image) -> Dictionary:
	var w := pg.get_width()
	var h := pg.get_height()
	var mudou := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var b := pv.get_pixel(x, y)
			if b.a < 0.5:
				continue
			var a := pg.get_pixel(x, y)
			# Nos pés e nas mãos, só o que cobre a peça (a barra do manto por cima do pé) é roupa;
			# a peça redesenhada parecida, ou o fundo em volta dela, não.
			if fora.get_pixel(x, y).a > 0.5 and (a.a < 0.5 or Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length() < 0.35):
				continue
			if a.a < 0.5 or Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length() > 0.2:
				mudou.set_pixel(x, y, b)
	_tirar_pontinhos(mudou, 16)
	var rosto := _rosto(pg, pescoco)
	var cabeca := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var corpo := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var mascara := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var c := mudou.get_pixel(x, y)
			if c.a > 0.5:
				if y >= pescoco:
					corpo.set_pixel(x, y, c)
				elif not _eh_pele(c) and rosto.get_pixel(x, y).a < 0.5:
					cabeca.set_pixel(x, y, c)
			if y < pescoco and pv.get_pixel(x, y).a > 0.5:
				mascara.set_pixel(x, y, Color.WHITE)
	return {roupa_cabeca = cabeca, roupa_corpo = corpo, mascara = mascara}


## Some com as manchinhas de menos de `minimo` pixels (a IA redesenha o corpo com pequenas
## diferenças de cor que não são roupa).
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
			for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1)]:
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


## Quanto a imagem vestida andou: o deslocamento em que mais pixels do boneco do gabarito
## batem com a vestida (o rosto, as mãos e os pés não mudam com a roupa).
func _alinhar(cg: Image, cv: Image) -> Dictionary:
	var g := cg.duplicate() as Image
	var v := cv.duplicate() as Image
	g.resize(cg.get_width() / REDUZ, cg.get_height() / REDUZ, Image.INTERPOLATE_BILINEAR)
	v.resize(cv.get_width() / REDUZ, cv.get_height() / REDUZ, Image.INTERPOLATE_BILINEAR)
	var w := g.get_width()
	var h := g.get_height()
	var pontos: Array = []
	for y in h:
		for x in w:
			var c := g.get_pixel(x, y)
			if c.a > 0.9:
				pontos.append([x, y, c])
	var vd := v.get_data()
	var melhor := {desl = Vector2i.ZERO, igual = -1.0}
	for dy in range(-BUSCA, BUSCA + 1):
		for dx in range(-BUSCA, BUSCA + 1):
			var iguais := 0
			for p in pontos:
				var x: int = p[0] + dx
				var y: int = p[1] + dy
				if x < 0 or y < 0 or x >= w or y >= h:
					continue
				var k := (y * w + x) * 4
				if vd[k + 3] < 230:
					continue
				var c: Color = p[2]
				if absf(vd[k] / 255.0 - c.r) + absf(vd[k + 1] / 255.0 - c.g) + absf(vd[k + 2] / 255.0 - c.b) < 0.18:
					iguais += 1
			var fr := float(iguais) / pontos.size()
			if fr > melhor.igual:
				melhor = {desl = Vector2i(dx, dy) * REDUZ, igual = fr}
	return melhor


func _deslocar(img: Image, d: Vector2i) -> Image:
	var r := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	r.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), d)
	return r


## A coluna inteira em pixel art: reduz pela escala do boneco base, paleta do pacote e
## contorno #161c2e (igual às peças do boneco, em montar_pecas.gd).
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


## Fundo magenta (e a franja rosada) vira transparente.
func _limpar(img: Image) -> Image:
	var r := img.duplicate() as Image
	r.convert(Image.FORMAT_RGBA8)
	for y in r.get_height():
		for x in r.get_width():
			var k := r.get_pixel(x, y)
			if k.a < 0.5 or minf(k.r, k.b) - k.g > 0.45:
				r.set_pixel(x, y, Color(0, 0, 0, 0))
	return r


func _folha_conferir(pg: Image, pv: Image, camadas: Dictionary) -> Image:
	var u := pg.get_used_rect().merge(pv.get_used_rect()).grow(2).intersection(Rect2i(Vector2i.ZERO, pg.get_size()))
	var folha := Image.create(u.size.x * 3 + 8, u.size.y, false, Image.FORMAT_RGBA8)
	folha.blend_rect(pg, u, Vector2i.ZERO)
	folha.blend_rect(pv, u, Vector2i(u.size.x + 4, 0))
	folha.blend_rect(camadas.roupa_corpo, u, Vector2i(u.size.x * 2 + 8, 0))
	folha.blend_rect(camadas.roupa_cabeca, u, Vector2i(u.size.x * 2 + 8, 0))
	return folha


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


var _pele: Array[Color] = []


func _eh_pele(c: Color) -> bool:
	if _pele.is_empty():
		for h in String(_args.get("pele", PELE_HUMANO)).split(","):
			_pele.append(Color(h))
	for p in _pele:
		if Vector3(c.r - p.r, c.g - p.g, c.b - p.b).length() < 0.12:
			return true
	return false


## O rosto do boneco base (a pele da cabeça, com os olhos e a boca que ficam dentro dela, e
## mais 1 pixel em volta): o chapéu nunca cobre o rosto; o que a IA redesenhou ali (o contorno
## do rosto um pixel ao lado, por exemplo) não entra no chapéu.
func _rosto(pg: Image, pescoco: int) -> Image:
	var w := pg.get_width()
	var r := Image.create(w, pg.get_height(), false, Image.FORMAT_RGBA8)
	for y in pescoco:
		var esq := -1
		var dir := -1
		for x in w:
			var c := pg.get_pixel(x, y)
			if c.a > 0.5 and _eh_pele(c):
				if esq < 0:
					esq = x
				dir = x
		# Na mesma linha, o que fica entre a pele (olhos, sobrancelha) também é rosto.
		if esq >= 0:
			for x in range(maxi(0, esq - 1), mini(w, dir + 2)):
				r.set_pixel(x, y, Color.WHITE)
	return r
