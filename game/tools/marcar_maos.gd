extends SceneTree
## Acha a MÃO DA FRENTE em cada quadro das tiras de sprite completo (L30) e grava
## `maos.json` na pasta do personagem: {"perfil": [[x, y], ...6], "frente": [...], "costas": [...]},
## em pixels do quadro de 128 (origem no canto de cima, à esquerda).
## Como: os pixels de pele formam ilhas (o contorno separa uma da outra). A mão da frente é a
## ilha PEQUENA de pele mais à direita (o rosto é grande; a mão de trás fica à esquerda).
## O automático erra (o ogro tem a mão grande; no anão a barba esconde): conferir a imagem
## e corrigir o json à mão. Com o json já existente, a ferramenta só redesenha as marcas.
## Também salva evidence/maos/<nome>_<vista>.png (ampliada 4x, com a mão marcada) para conferir.
## MÃO DE TRÁS (L37, para a 2ª adaga do Ladino): o campo "tras" = {"perfil": [...6], "frente": [...],
## "costas": [...]}. É a ilha de pele do tamanho de uma mão MAIS LONGE da mão da frente, na faixa do corpo
## (a mais longe da mão da frente). Se o json já existe sem "tras", só esse campo é acrescentado.
## Na imagem de conferência, a mão da frente é magenta e a de trás, ciano.
## Uso: godot --headless --path game --script res://tools/marcar_maos.gd -- res://assets/sprites/tiny/personagens/humano_guerreiro
const QUADRO := 128
const VISTAS := ["perfil", "frente", "costas"]
const AREA_MAX := 140  # acima disso é o rosto ou o braço inteiro
const AREA_MIN := 6


func _init() -> void:
	for pasta in OS.get_cmdline_user_args():
		_marcar(pasta)
	quit()


func _marcar(pasta: String) -> void:
	# Se já existe maos.json (conferido e corrigido à mão), só desenha as marcas dele.
	var existente := {}
	if FileAccess.file_exists(pasta + "/maos.json"):
		existente = JSON.parse_string(FileAccess.get_file_as_string(pasta + "/maos.json"))
	var saida := {}
	var tras := {}
	# Outras classes (L31): as poses copiam as do guerreiro da mesma raça. Parte da mão dele e
	# procura a mão desenhada (ilha de pele) mais perto; a pele também vem do guerreiro.
	var guia := {}
	var raca := pasta.get_file().get_slice("_", 0)
	var guerreiro := pasta.get_base_dir() + "/" + raca + "_guerreiro"
	if not pasta.ends_with("_guerreiro") and FileAccess.file_exists(guerreiro + "/maos.json"):
		guia = JSON.parse_string(FileAccess.get_file_as_string(guerreiro + "/maos.json"))
	var pele_de := (guerreiro if not guia.is_empty() else pasta) + "/frente.png"
	for v in VISTAS:
		var img := Image.load_from_file(ProjectSettings.globalize_path(pasta + "/" + v + ".png"))
		img.convert(Image.FORMAT_RGBA8)
		# A pele vem da vista de frente (de costas não aparece o rosto).
		var pele := _cores_de_pele(_abrir(pele_de))
		var pontos := []
		var pontos_tras := []
		var conferir := Image.create(img.get_width() * 4, img.get_height() * 4, false, Image.FORMAT_RGBA8)
		conferir.fill(Color(0.85, 0.85, 0.85))
		for y in img.get_height():
			for x in img.get_width():
				if img.get_pixel(x, y).a > 0:
					conferir.fill_rect(Rect2i(x * 4, y * 4, 4, 4), img.get_pixel(x, y))
		for q in img.get_width() / QUADRO:
			var p := _mao(img, q, pele) if guia.is_empty() else _mao_perto(img, q, pele, Vector2i(int(guia[v][q][0]), int(guia[v][q][1])))
			if existente.has(v):
				p = Vector2i(int(existente[v][q][0]), int(existente[v][q][1]))
			pontos.append([p.x, p.y])
			var pt := _mao_tras(img, q, pele, p)
			if existente.has("tras"):
				pt = Vector2i(int(existente["tras"][v][q][0]), int(existente["tras"][v][q][1]))
			pontos_tras.append([pt.x, pt.y])
			conferir.fill_rect(Rect2i((q * QUADRO + p.x) * 4 - 6, p.y * 4 - 6, 12, 12), Color(1, 0, 1))
			conferir.fill_rect(Rect2i((q * QUADRO + pt.x) * 4 - 6, pt.y * 4 - 6, 12, 12), Color(0, 1, 1))
			print("%s %s quadro %d: mão em %s, mão de trás em %s" % [pasta.get_file(), v, q, p, pt])
		saida[v] = pontos
		tras[v] = pontos_tras
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../evidence/maos"))
		conferir.save_png(ProjectSettings.globalize_path("res://../evidence/maos/%s_%s.png" % [pasta.get_file(), v]))
	if existente.is_empty() or not existente.has("tras"):
		var gravar := saida if existente.is_empty() else existente
		gravar["tras"] = tras
		var f := FileAccess.open(pasta + "/maos.json", FileAccess.WRITE)
		f.store_string(JSON.stringify(gravar))


## As cores de pele: as do pixel no meio do rosto do 1º quadro e parecidas (a pele usa 2-3 tons).
## O rosto fica abaixo do meio da cabeça; pega a cor mais comum quente/verde numa faixa.
func _cores_de_pele(img: Image) -> Array[Color]:
	var conta := {}
	var usado := img.get_region(Rect2i(0, 0, QUADRO, QUADRO)).get_used_rect()
	# Faixa do rosto: de 45% a 60% da altura do desenho, no meio.
	var y0 := usado.position.y + int(usado.size.y * 0.42)
	var y1 := usado.position.y + int(usado.size.y * 0.58)
	for y in range(y0, y1):
		for x in range(usado.position.x + usado.size.x / 4, usado.end.x - usado.size.x / 4):
			var c := img.get_pixel(x, y)
			if c.a > 0 and c.get_luminance() > 0.35:
				conta[c.to_html()] = conta.get(c.to_html(), 0) + 1
	var cores: Array[Color] = []
	var ordem := conta.keys()
	ordem.sort_custom(func(a, b): return conta[a] > conta[b])
	var base := Color(ordem[0]) if not ordem.is_empty() else Color("f2c391")
	for k in conta:
		var c := Color(k)
		if absf(c.h - base.h) < 0.06 and absf(c.s - base.s) < 0.25:
			cores.append(c)
	return cores


func _eh_pele(c: Color, pele: Array[Color]) -> bool:
	if c.a == 0:
		return false
	for p in pele:
		if Vector3(c.r - p.r, c.g - p.g, c.b - p.b).length() < 0.06:
			return true
	return false


func _mao(img: Image, q: int, pele: Array[Color]) -> Vector2i:
	var visto := {}
	# Só a faixa do corpo: abaixo da cabeça (45% do desenho) e acima dos pés (12 px).
	var usado := img.get_region(Rect2i(q * QUADRO, 0, QUADRO, QUADRO)).get_used_rect()
	var y_min := usado.position.y + usado.size.y * 0.45
	var y_max := usado.end.y - 14.0
	var melhor := Vector2i(QUADRO / 2 + 16, 90)
	var melhor_x := -1.0
	for y in QUADRO:
		for x in QUADRO:
			var p := Vector2i(q * QUADRO + x, y)
			if visto.has(p) or not _eh_pele(img.get_pixelv(p), pele):
				continue
			# Ilha de pele (vizinhos de 4).
			var fila: Array[Vector2i] = [p]
			visto[p] = true
			var soma := Vector2.ZERO
			var n := 0
			var max_x := 0
			while not fila.is_empty():
				var a: Vector2i = fila.pop_back()
				soma += Vector2(a)
				n += 1
				max_x = maxi(max_x, a.x)
				for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var b: Vector2i = a + d
					if b.x < q * QUADRO or b.x >= (q + 1) * QUADRO or b.y < 0 or b.y >= QUADRO:
						continue
					if not visto.has(b) and _eh_pele(img.get_pixelv(b), pele):
						visto[b] = true
						fila.append(b)
			if n < AREA_MIN or n > AREA_MAX:
				continue
			var centro := soma / n
			if centro.y < y_min or centro.y > y_max:
				continue
			if centro.x > melhor_x:
				melhor_x = centro.x
				melhor = Vector2i(roundi(centro.x) - q * QUADRO, roundi(centro.y))
	return melhor


func _abrir(caminho: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(caminho))
	img.convert(Image.FORMAT_RGBA8)
	return img


## A ilha de pele (do tamanho de uma mão) mais perto de `alvo`, até 12 px; senão, o próprio alvo.
func _mao_perto(img: Image, q: int, pele: Array[Color], alvo: Vector2i) -> Vector2i:
	var visto := {}
	var melhor := alvo
	var dist := 12.0
	for y in range(maxi(0, alvo.y - 20), mini(QUADRO, alvo.y + 20)):
		for x in range(maxi(0, alvo.x - 20), mini(QUADRO, alvo.x + 20)):
			var p := Vector2i(q * QUADRO + x, y)
			if visto.has(p) or not _eh_pele(img.get_pixelv(p), pele):
				continue
			var fila: Array[Vector2i] = [p]
			visto[p] = true
			var soma := Vector2.ZERO
			var n := 0
			while not fila.is_empty():
				var a: Vector2i = fila.pop_back()
				soma += Vector2(a)
				n += 1
				for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var b: Vector2i = a + d
					if b.x < q * QUADRO or b.x >= (q + 1) * QUADRO or b.y < 0 or b.y >= QUADRO:
						continue
					if not visto.has(b) and _eh_pele(img.get_pixelv(b), pele):
						visto[b] = true
						fila.append(b)
			if n < 20 or n > 260:  # mão tem pelo menos ~20 pixels (pedacinhos do cinto não)
				continue
			var c := soma / n - Vector2(q * QUADRO, 0)
			if c.distance_to(Vector2(alvo)) < dist:
				dist = c.distance_to(Vector2(alvo))
				melhor = Vector2i(c.round())
	return melhor


## A mão de trás: a ilha de pele do tamanho de uma mão mais LONGE da mão da frente, na faixa
## do corpo (abaixo do pescoço, acima dos pés). No golpe o braço da frente vai para trás e a
## mão de trás pode ficar à direita, por isso a distância e não "a mais à esquerda".
func _mao_tras(img: Image, q: int, pele: Array[Color], frente: Vector2i) -> Vector2i:
	var usado := img.get_region(Rect2i(q * QUADRO, 0, QUADRO, QUADRO)).get_used_rect()
	var y_min := usado.position.y + usado.size.y * 0.42
	var y_max := 104.0  # os pés (sapatos claros, parecidos com pele) ficam em y 108 a 120
	var visto := {}
	var melhor := Vector2i(frente.x - 24, frente.y)
	var melhor_d := 10.0
	for y in range(int(y_min), int(y_max)):
		for x in QUADRO:
			var p := Vector2i(q * QUADRO + x, y)
			if visto.has(p) or not _eh_pele(img.get_pixelv(p), pele):
				continue
			var fila: Array[Vector2i] = [p]
			visto[p] = true
			var soma := Vector2.ZERO
			var n := 0
			while not fila.is_empty():
				var a: Vector2i = fila.pop_back()
				soma += Vector2(a)
				n += 1
				for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var b: Vector2i = a + d
					if b.x < q * QUADRO or b.x >= (q + 1) * QUADRO or b.y < 0 or b.y >= QUADRO:
						continue
					if not visto.has(b) and _eh_pele(img.get_pixelv(b), pele):
						visto[b] = true
						fila.append(b)
			if n < 12 or n > 260:
				continue
			var c := soma / n - Vector2(q * QUADRO, 0)
			if c.y < y_min or c.y > y_max:
				continue
			if c.distance_to(Vector2(frente)) > melhor_d:
				melhor_d = c.distance_to(Vector2(frente))
				melhor = Vector2i(c.round())
	return melhor
