extends SceneTree
## Converte uma folha gerada pelo Codex (3x2 células de 512 px, fundo magenta) em uma
## tira de quadros do tamanho real do jogo, com fundo transparente.
##
## Para cada célula:
##   1. descobre sozinho o tamanho do "pixel" desenhado (a IA nem sempre acerta 8x/16x)
##      e onde a grade começa, olhando onde as cores mudam;
##   2. reduz cada bloco para 1 pixel usando a cor mais comum do bloco;
##   3. troca o magenta (e a franja rosada em volta) por transparente e apaga pontinhos soltos;
##   4. alinha: base do desenho a `base` px do fundo do quadro e centralizado na horizontal.
##
## Uso (da raiz):
##   godot --headless --path game --script res://tools/importar_folha.gd -- \
##     --entrada=../art/sprites/natureza/arvore_v1.png --saida=res://assets/sprites/natureza/arvore.png \
##     --quadro=64 --celulas=0,1,2,3,4 [--base=2] [--previa=../evidence/importacao/arvore.png]

const CELULA := 512

var _args := {}


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			_args[a.substr(2).get_slice("=", 0)] = a.get_slice("=", 1)
	var entrada := _caminho(_args.get("entrada", ""))
	var saida: String = _args.get("saida", "")
	var quadro := int(_args.get("quadro", "32"))
	var base := int(_args.get("base", "2"))
	var celulas := Array(String(_args.get("celulas", "0")).split(",")).map(func(s: String) -> int: return s.to_int())

	var folha := Image.load_from_file(entrada)
	if folha == null or folha.is_empty():
		push_error("Não abriu a folha: " + entrada)
		quit(1)
		return
	folha.convert(Image.FORMAT_RGBA8)
	# A grade vale para a folha toda (a IA desenha a folha de uma vez).
	var grade := _detectar_grade(folha)
	if _args.has("pixel"):
		# Força o tamanho (ex.: a IA desenhou fino demais e queremos metade da resolução).
		var forcado := float(_args["pixel"])
		grade = Vector3(forcado, fmod(grade.y, forcado), fmod(grade.z, forcado))
	var s := grade.x
	var gx := Vector2(s, grade.y)
	var gy := Vector2(s, grade.z)
	print("pixel desenhado: %.2f px, início (%.1f, %.1f)" % [s, gx.y, gy.y])
	var pequeno_folha := _reduzir(folha, s, Vector2(gx.y, gy.y))
	_tirar_fundo(pequeno_folha)

	var tira := Image.create_empty(quadro * celulas.size(), quadro, false, Image.FORMAT_RGBA8)
	var colunas := folha.get_width() / CELULA
	for i in celulas.size():
		var c: int = celulas[i]
		var x0 := ceili(((c % colunas) * CELULA - gx.y) / s)
		var y0 := ceili(((c / colunas) * CELULA - gy.y) / s)
		var x1 := floori(((c % colunas + 1) * CELULA - gx.y) / s)
		var y1 := floori(((c / colunas + 1) * CELULA - gy.y) / s)
		var pequeno := pequeno_folha.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))
		_apagar_soltos(pequeno, 3)
		var caixa := pequeno.get_used_rect()
		if caixa.size.x > quadro - 2 or caixa.size.y > quadro - base:
			push_warning("célula %d: desenho %dx%d não cabe no quadro de %d" % [c, caixa.size.x, caixa.size.y, quadro])
		var destino := Vector2i(i * quadro + (quadro - caixa.size.x) / 2, quadro - base - caixa.size.y)
		tira.blit_rect(pequeno, caixa, destino)
		print("célula %d: desenho %dx%d" % [c, caixa.size.x, caixa.size.y])

	var erro := tira.save_png(_caminho(saida))
	print("Salvo: ", saida, " (", error_string(erro), ")")
	if _args.has("previa"):
		_salvar_previa(tira, _caminho(_args["previa"]))
	quit(0 if erro == OK else 1)


func _caminho(p: String) -> String:
	if p.begins_with("res://"):
		return ProjectSettings.globalize_path(p)
	if p.is_absolute_path():
		return p
	return ProjectSettings.globalize_path("res://").path_join(p).simplify_path()


func _diferente(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.12


## (tamanho do pixel, início x, início y). O tamanho é o mesmo nos dois eixos e pode ser
## fracionado, porque a IA às vezes desenha "pixels" de 9,7 px em vez de 10.
func _detectar_grade(img: Image) -> Vector3:
	var tx := _mudancas(img, true)
	var ty := _mudancas(img, false)
	var notas: Array[Vector4] = []  # (tamanho, início x, início y, nota)
	var maior := 0.0
	var s := 6.0
	while s <= 24.0:
		var fx := _melhor_fase(tx, s)
		var fy := _melhor_fase(ty, s)
		var nt := Vector4(s, fx.x, fy.x, fx.y + fy.y)
		notas.append(nt)
		maior = maxf(maior, nt.w)
		s += 0.05
	# O menor tamanho que explica quase tudo (os múltiplos dele explicam igual).
	for nt in notas:
		if nt.w >= maior * 0.9:
			return Vector3(nt.x, nt.y, nt.z)
	return Vector3(notas[0].x, notas[0].y, notas[0].z)


## Quantas vezes a cor muda em cada coluna (horizontal) ou linha (vertical).
func _mudancas(img: Image, horizontal: bool) -> PackedFloat32Array:
	var n := img.get_width() if horizontal else img.get_height()
	var outro := img.get_height() if horizontal else img.get_width()
	var t := PackedFloat32Array()
	t.resize(n)
	for j in range(0, outro, 2):
		for i in range(1, n):
			var a := img.get_pixel(i, j) if horizontal else img.get_pixel(j, i)
			var b := img.get_pixel(i - 1, j) if horizontal else img.get_pixel(j, i - 1)
			if _diferente(a, b):
				t[i] += 1.0
	return t


## Para um tamanho s: (melhor início, média de mudanças nas linhas da grade ÷ média geral).
func _melhor_fase(t: PackedFloat32Array, s: float) -> Vector2:
	var media := 0.0
	for v in t:
		media += v
	media = maxf(media / t.size(), 0.001)
	var melhor := Vector2.ZERO
	var fase := 0.0
	while fase < s:
		var soma := 0.0
		var k := 0
		var pos := fase
		while pos < t.size() - 0.5:
			soma += t[int(round(pos)) % t.size()]
			k += 1
			pos += s
		var nota := soma / maxf(k, 1) / media
		if nota > melhor.y:
			melhor = Vector2(fase, nota)
		fase += 0.5
	return melhor


func _reduzir(img: Image, s: float, inicio: Vector2) -> Image:
	var cols := int((img.get_width() - inicio.x) / s)
	var lins := int((img.get_height() - inicio.y) / s)
	var out := Image.create_empty(cols, lins, false, Image.FORMAT_RGBA8)
	# Reduzindo mais de um pixel desenhado por bloco (--pixel), contorno e olhos somem se
	# vencer só a cor mais comum; com --escuro, um tom escuro que ocupe 1/4 do bloco ganha.
	var escuro := _args.has("escuro")
	var margem := 1.0 if escuro else maxf(1.0, s / 4.0)  # ignora a borda, onde a IA mistura cores
	for by in lins:
		for bx in cols:
			var contagem := {}
			var total := 0
			var ox := inicio.x + bx * s
			var oy := inicio.y + by * s
			for y in range(int(oy + margem), int(oy + s - margem)):
				for x in range(int(ox + margem), int(ox + s - margem)):
					var c := img.get_pixel(x, y)
					var chave := Color8(int(c.r8 / 8) * 8, int(c.g8 / 8) * 8, int(c.b8 / 8) * 8).to_rgba32()
					contagem[chave] = contagem.get(chave, 0) + 1
					total += 1
			var escolhida := 0
			var mais := -1
			var escolhida_escura := 0
			var mais_escura := 0
			var soma_escura := 0
			for k in contagem:
				if contagem[k] > mais:
					mais = contagem[k]
					escolhida = k
				var cor := Color.hex(k)
				if escuro and cor.get_luminance() < 0.2 and not _eh_magenta(cor):
					soma_escura += contagem[k]
					if contagem[k] > mais_escura:
						mais_escura = contagem[k]
						escolhida_escura = k
			if escuro and soma_escura * 4 >= total and not _eh_magenta(Color.hex(escolhida)):
				escolhida = escolhida_escura
			out.set_pixel(bx, by, Color.hex(escolhida))
	return out


func _eh_magenta(c: Color) -> bool:
	return c.r8 - c.g8 > 90 and c.b8 - c.g8 > 90 and absi(c.r8 - c.b8) < 100


func _tirar_fundo(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			if _eh_magenta(img.get_pixel(x, y)):
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	# Franja: pixel arroxeado/rosado bem saturado encostado no fundo é mistura com o magenta.
	var franja: Array[Vector2i] = []
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a == 0.0 or c.s < 0.45 or (c.h > 0.05 and c.h < 0.75):
				continue
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var n: Vector2i = Vector2i(x, y) + d
				if n.x < 0 or n.y < 0 or n.x >= img.get_width() or n.y >= img.get_height() or img.get_pixelv(n).a == 0.0:
					franja.append(Vector2i(x, y))
					break
	for p in franja:
		img.set_pixelv(p, Color(0, 0, 0, 0))


## Apaga grupos de pixels opacos com menos de `minimo` pixels (sujeira da IA).
func _apagar_soltos(img: Image, minimo: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var visto := {}
	for y in h:
		for x in w:
			var p := Vector2i(x, y)
			if visto.has(p) or img.get_pixelv(p).a == 0.0:
				continue
			var grupo: Array[Vector2i] = [p]
			visto[p] = true
			var i := 0
			while i < grupo.size():
				var q := grupo[i]
				i += 1
				for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var n: Vector2i = q + d
					if n.x >= 0 and n.y >= 0 and n.x < w and n.y < h and not visto.has(n) and img.get_pixelv(n).a > 0.0:
						visto[n] = true
						grupo.append(n)
			if grupo.size() < minimo:
				for q in grupo:
					img.set_pixelv(q, Color(0, 0, 0, 0))


## Prévia ampliada 8x sobre fundo cinza, para conferir.
func _salvar_previa(tira: Image, caminho: String) -> void:
	DirAccess.make_dir_recursive_absolute(caminho.get_base_dir())
	var prev := Image.create_empty(tira.get_width(), tira.get_height(), false, Image.FORMAT_RGBA8)
	prev.fill(Color(0.35, 0.38, 0.36))
	prev.blend_rect(tira, Rect2i(Vector2i.ZERO, tira.get_size()), Vector2i.ZERO)
	prev.resize(prev.get_width() * 8, prev.get_height() * 8, Image.INTERPOLATE_NEAREST)
	prev.save_png(caminho)
