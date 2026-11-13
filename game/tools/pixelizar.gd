extends SceneTree
## Transforma uma ILUSTRAÇÃO da IA (desenho liso de alta resolução, fundo magenta) em pixel
## art na densidade exata do Tiny Swords. A IA não consegue desenhar pixel art com ~88 pixels
## de altura (ela sempre engrossa o pixel); mas desenha bem uma ilustração limpa. Então:
##   1. tira o magenta e recorta o desenho;
##   2. reduz para a altura pedida em pixels do jogo (filtro de qualidade);
##   3. corta a transparência em 50% (sem borda meio transparente) e tira pontos soltos;
##   4. troca cada cor pela mais próxima da paleta do pacote;
##   5. pinta a borda de fora com o contorno do pacote (#161c2e, 1 pixel);
##   6. põe a sombra do pacote embaixo (ver SombraTiny).
## Saída: tira de quadros `quadro` x `quadro`, base `base` px acima do fundo.
##
## Uso (da raiz):
##   godot --headless --path game --script res://tools/pixelizar.gd -- \
##     --entrada=../art/sprites/desenho_hd/candidatos/hd_v1.png --celulas=0,1 --altura=88 \
##     --saida=../art/sprites/tiny/convertido/teste.png [--quadro=128] [--base=8] [--celula=512x512]

const MAGENTA := Color(1, 0, 1)
const CONTORNO := Color("161c2e")
const PALETA := "res://assets/tiny_swords/paleta.png"

var _args := {}
var _paleta: Array[Color] = []


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and not a.contains("="):
			_args[a.substr(2)] = ""  # opção sem valor (ex.: --animacao)
		elif a.begins_with("--"):
			_args[a.substr(2).get_slice("=", 0)] = a.get_slice("=", 1)
	var folha := Image.load_from_file(_caminho(_args["entrada"]))
	folha.convert(Image.FORMAT_RGBA8)
	var celulas := Array(String(_args.get("celulas", "0")).split(",")).map(func(s: String) -> int: return s.to_int())
	var alturas := Array(String(_args.get("altura", "88")).split(",")).map(func(s: String) -> int: return s.to_int())
	var quadro := int(_args.get("quadro", "128"))
	var base := int(_args.get("base", "8"))
	var cel := Vector2i(512, 512)
	if _args.has("celula"):
		cel = Vector2i(String(_args["celula"]).get_slice("x", 0).to_int(), String(_args["celula"]).get_slice("x", 1).to_int())
	var colunas := folha.get_width() / cel.x
	var pal := Image.load_from_file(ProjectSettings.globalize_path(PALETA))
	pal.convert(Image.FORMAT_RGBA8)
	for x in pal.get_width():
		_paleta.append(pal.get_pixel(x, 0))

	# --animacao: quadros de uma animação. Todos usam a escala do 1º quadro (o personagem não
	# cresce nem encolhe) e ficam no mesmo lugar da célula original (os pés não pulam): o
	# ponto de referência é o centro da célula na linha dos pés do 1º quadro.
	var animacao := _args.has("animacao")
	var ref := Vector2.ZERO
	var fator := 0.0
	var tira := Image.create(quadro * celulas.size(), quadro, false, Image.FORMAT_RGBA8)
	for i in celulas.size():
		var c: int = celulas[i]
		var parte := folha.get_region(Rect2i((c % colunas) * cel.x, (c / colunas) * cel.y, cel.x, cel.y))
		_tirar_magenta(parte)
		var usado := parte.get_used_rect()
		parte = parte.get_region(usado)
		if not animacao or fator == 0.0:
			fator = alturas[mini(i, alturas.size() - 1)] / float(usado.size.y)
			ref = Vector2(cel.x / 2.0, usado.end.y)
		var w := maxi(1, roundi(usado.size.x * fator))
		var h := maxi(1, roundi(usado.size.y * fator))
		parte.resize(w, h, Image.INTERPOLATE_LANCZOS)
		_quantizar(parte)
		_contorno(parte)
		var destino := Vector2i(i * quadro + (quadro - w) / 2, quadro - base - h)
		if animacao:
			var rel := (Vector2(usado.position) - ref) * fator
			destino = Vector2i(i * quadro + quadro / 2 + roundi(rel.x), quadro - base + roundi(rel.y))
		var dentro := Rect2i(destino, Vector2i(w, h)).intersection(Rect2i(i * quadro, 0, quadro, quadro))
		tira.blit_rect(parte, Rect2i(dentro.position - destino, dentro.size), dentro.position)
		SombraTiny.por(tira, dentro)
		print("célula %d: %dx%d%s" % [c, w, h, "" if dentro.size == Vector2i(w, h) else " (CORTADO: não coube no quadro)"])
	var saida := _caminho(_args["saida"])
	DirAccess.make_dir_recursive_absolute(saida.get_base_dir())
	print("Salvo: ", saida, " (", error_string(tira.save_png(saida)), ")")
	quit()


func _tirar_magenta(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.5 or (minf(c.r, c.b) - c.g > 0.45):
				img.set_pixel(x, y, Color(0, 0, 0, 0))


## Transparência em 0 ou 1, ponto solto fora, cor da paleta.
func _quantizar(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				img.set_pixel(x, y, _mais_proxima(c))
	var copia := img.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			if copia.get_pixel(x, y).a == 0.0:
				continue
			var vizinhos := 0
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var p: Vector2i = Vector2i(x, y) + d
				if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height() and copia.get_pixelv(p).a > 0.0:
					vizinhos += 1
			if vizinhos <= 1:
				img.set_pixel(x, y, Color(0, 0, 0, 0))


func _mais_proxima(c: Color) -> Color:
	var melhor := _paleta[0]
	var dist := 99.0
	for p in _paleta:
		var d := (c.r - p.r) * (c.r - p.r) * 0.3 + (c.g - p.g) * (c.g - p.g) * 0.59 + (c.b - p.b) * (c.b - p.b) * 0.11
		if d < dist:
			dist = d
			melhor = p
	return melhor


## O pixel do desenho que encosta no transparente vira o contorno do pacote.
func _contorno(img: Image) -> void:
	var copia := img.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			if copia.get_pixel(x, y).a == 0.0:
				continue
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var p: Vector2i = Vector2i(x, y) + d
				if p.x < 0 or p.y < 0 or p.x >= img.get_width() or p.y >= img.get_height() or copia.get_pixelv(p).a == 0.0:
					img.set_pixel(x, y, CONTORNO)
					break


func _caminho(p: String) -> String:
	if p.begins_with("res://"):
		return ProjectSettings.globalize_path(p)
	if p.is_absolute_path():
		return p
	return ProjectSettings.globalize_path("res://").path_join(p).simplify_path()
