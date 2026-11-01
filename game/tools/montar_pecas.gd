extends SceneTree
## Personagem por peças (L19): a folha da IA tem o personagem MONTADO na célula 0 e as peças
## soltas nas células 1-4 (cabeça, tronco, pé, mão). A IA não respeita o tamanho das peças,
## então esta ferramenta ACHA cada peça dentro do personagem montado (compara a peça em
## várias escalas e posições com a célula 0, em tamanho reduzido) e assim descobre a escala
## certa e o lugar de cada uma. O pé e a mão aparecem duas vezes (frente e trás).
## Depois transforma tudo em pixel art na densidade do Tiny Swords (como pixelizar.gd:
## paleta do pacote, contorno #161c2e) e grava:
##   <saida>/<nome>/cabeca.png, tronco.png, pe.png, mao.png, inteiro.png (com sombra)
##   <saida>/<nome>/pecas.json: canto de cima à esquerda de cada peça em pixels da arte,
##     com a origem nos pés (meio da largura, base do personagem montado).
##
## Uso (da raiz):
##   godot --headless --path game --script res://tools/montar_pecas.gd -- \
##     --entrada=../art/sprites/tiny/candidatos/pecas_humano_mago.png --nome=humano_mago \
##     --saida=res://assets/sprites/tiny/bonecos [--altura=80] [--previa=../evidence/x.png]

const CELULA := 512
const REDUZ := 8  # a busca é feita com a imagem 8x menor
const CONTORNO := Color("161c2e")
const PALETA := "res://assets/tiny_swords/paleta.png"
const PECAS := ["cabeca", "tronco", "pe", "mao"]

var _args := {}
var _paleta: Array[Color] = []


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			_args[a.substr(2).get_slice("=", 0)] = a.get_slice("=", 1)
	var folha := Image.load_from_file(_caminho(_args["entrada"]))
	folha.convert(Image.FORMAT_RGBA8)
	var pal := Image.load_from_file(ProjectSettings.globalize_path(PALETA))
	pal.convert(Image.FORMAT_RGBA8)
	for x in pal.get_width():
		_paleta.append(pal.get_pixel(x, 0))
	var alvo_altura := float(_args.get("altura", "80"))
	if _args.has("rosto"):
		_montar_rosto(folha)
		return

	# Vista de frente ou de costas (L21): a folha tem o montado e só a cabeça e o tronco;
	# o pé e a mão vêm da folha de perfil (--extras), que é a mesma peça.
	var vista: String = _args.get("vista", "")
	var extras := folha
	if _args.has("extras"):
		extras = Image.load_from_file(_caminho(_args["extras"]))
		extras.convert(Image.FORMAT_RGBA8)
	var celulas := {"cabeca": [folha, int(_args.get("cabeca", "1"))], "tronco": [folha, int(_args.get("tronco", "2"))],
		"pe": [extras, int(_args.get("pe", "3"))], "mao": [extras, int(_args.get("mao", "4"))]}
	var montado := _celula(folha, int(_args.get("montado", "0")))
	var caixa := _caixa_principal(montado)
	var fator := alvo_altura / caixa.size.y
	if _args.has("fator"):
		fator = float(_args["fator"])
	print("fator: %.4f (montado %dx%d)" % [fator, caixa.size.x, caixa.size.y])
	var ref := Vector2(caixa.position.x + caixa.size.x / 2.0, caixa.end.y)  # pés
	var pequeno := _reduzir(montado.get_region(caixa))
	var pasta := _caminho(_args["saida"]).path_join(_args["nome"])
	DirAccess.make_dir_recursive_absolute(pasta)

	# 1ª passada: acha cada peça no montado (escala e lugar).
	var achados := {}
	for nome in PECAS:
		var peca := _celula(celulas[nome][0], celulas[nome][1])
		peca = peca.get_region(_caixa_principal(peca))
		# Permite corrigir a escala de uma peça quando a busca automática encontra só uma
		# parte parecida (ex.: um colete tem faixas de cor repetidas). Em geral deixe automático.
		var escala_manual := float(_args.get("escala_" + nome, "0"))
		var achado := _achar(peca, pequeno, nome, escala_manual, Vector2.INF)
		var lugares: Array = [achado.pos]
		if nome == "pe" or nome == "mao":
			# A segunda (a de trás): mesma escala, longe da primeira.
			var segundo := _achar(peca, pequeno, nome, achado.escala, achado.pos)
			lugares.append(segundo.pos if segundo.custo < 0.3 else Vector2.INF)
		achados[nome] = {peca = peca, achado = achado, lugares = lugares}
	# Roupa (L24): o montado com elmo ou chapéu é mais alto que o boneco base, então o fator
	# não sai da altura: sai do pé, que tem de ficar com a mesma largura do pé do boneco base.
	if _args.has("fator_de"):
		# --fator_por=mao: quando a roupa comprida cobre os pés (manto do mago), mede pela mão.
		var ref_peca: String = _args.get("fator_por", "pe")
		var pe_base := Image.load_from_file(_caminho(_args["fator_de"]).path_join(ref_peca + ".png"))
		var ap: Dictionary = achados[ref_peca]
		fator = pe_base.get_width() / ((ap.peca as Image).get_width() * float(ap.achado.escala))
		print("fator pelo %s do boneco base: %.4f" % [ref_peca, fator])

	# Chapéu pelo rosto (L24b): acha o rosto do boneco base dentro do montado com roupa; assim o
	# tamanho e o lugar do chapéu saem em relação à cabeça base (e não aos pés).
	var pelo_rosto := _rosto_no_montado(pequeno, vista) if _args.has("rosto_base_folha") else {}

	# 2ª passada: cada peça em pixel art e o lugar dela (pixels da arte, origem nos pés).
	var posicoes := {}
	for nome in PECAS:
		var peca: Image = achados[nome].peca
		var achado: Dictionary = achados[nome].achado
		var escala: float = achado.escala
		var lugares: Array = achados[nome].lugares
		# Peça em pixel art: escala achada x fator do personagem.
		var w := maxi(1, roundi(peca.get_width() * escala * fator))
		var h := maxi(1, roundi(peca.get_height() * escala * fator))
		# Chapéu de frente e de costas (L24): o cabelo do boneco base é mais cheio que a cabeça
		# do montado com chapéu; se o chapéu sair mais estreito que a cabeça base, aumenta até
		# cobri-la, com a base do chapéu no mesmo lugar.
		var cresce := Vector2.ZERO
		var chapeu_rel := Vector2.INF
		if nome == "cabeca" and not pelo_rosto.is_empty():
			var k: float = pelo_rosto.k
			w = maxi(1, roundi(peca.get_width() * escala * k))
			h = maxi(1, roundi(peca.get_height() * escala * k))
			var p0: Vector2 = pelo_rosto.p0
			var pt: Vector2 = pelo_rosto.tamanho
			if pelo_rosto.has("cabeca_bruta"):
				chapeu_rel = p0 + (lugares[0] * REDUZ - (pelo_rosto.cabeca_bruta as Vector2)) * k
				chapeu_rel.y += float(_args.get("ajuste_y", "0"))  # acerto fino, em pixels da arte
				print("chapéu: k %.4f dy %d" % [k, roundi(chapeu_rel.y + h - p0.y - pt.y)])
			else:
				# De costas não há rosto: centralizado na cabeça, com a base do chapéu na mesma
				# altura que de frente (--dy).
				chapeu_rel = Vector2(p0.x + (pt.x - w) / 2.0, p0.y + pt.y + float(_args.get("dy", "0")) - h)
		elif nome == "cabeca" and vista != "" and _args.has("fator_de"):
			var cab := Image.load_from_file(_caminho(_args["fator_de"]).path_join("cabeca" + vista + ".png"))
			if w < cab.get_width() + 2:
				var k := (cab.get_width() + 2.0) / w
				cresce = Vector2(roundi(w * k) - w, roundi(h * k) - h)
				w += int(cresce.x)
				h += int(cresce.y)
		var px := peca.duplicate() as Image
		px.resize(w, h, Image.INTERPOLATE_LANCZOS)
		_quantizar(px)
		_contorno(px)
		if vista == "" or nome == "cabeca" or nome == "tronco":
			px.save_png(pasta.path_join(nome + vista + ".png"))
		var rels := []
		for p in lugares:
			if p == Vector2.INF:
				rels.append(null)
			else:
				var no_montado: Vector2 = Vector2(caixa.position) + p * REDUZ
				var rel := (no_montado - ref) * fator
				rel -= Vector2(cresce.x / 2.0, cresce.y)
				if chapeu_rel != Vector2.INF:
					rel = chapeu_rel
				rels.append([roundi(rel.x), roundi(rel.y)])
		posicoes[nome] = rels
		print("%s: escala %.2f, %dx%d, lugar %s (custo %.2f)" % [nome, escala, w, h, rels, achado.custo])

	# De frente e de costas, as mãozinhas ficam sempre dos dois lados do tronco, na altura do
	# peito (a busca às vezes acha a mão dentro do tronco, que tem a mesma cor de luva).
	if vista != "":
		var tr := Image.load_from_file(pasta.path_join("tronco" + vista + ".png"))
		var mw := Image.load_from_file(pasta.path_join("mao.png")).get_width()
		var t0: Array = posicoes["tronco"][0]
		var y := roundi(t0[1] + tr.get_height() * 0.3)
		posicoes["mao"] = [[t0[0] + tr.get_width() - 3, y], [t0[0] - mw + 3, y]]
	# Duas peças iguais: a da frente é a mais à direita (o personagem olha para a direita).
	for nome in ["pe", "mao"]:
		var r: Array = posicoes[nome]
		if r[1] == null:
			# Não achou a de trás: espelha a da frente em volta do meio do tronco.
			var meio_tronco: float = posicoes["tronco"][0][0] + Image.load_from_file(pasta.path_join("tronco" + vista + ".png")).get_width() / 2.0
			var largura := Image.load_from_file(pasta.path_join(nome + ".png")).get_width()
			r[1] = [roundi(2.0 * meio_tronco - r[0][0] - largura), r[0][1]]
		if r[1][0] > r[0][0]:
			r.reverse()
	# Mangas compridas: encosta os punhos na borda das mangas antes de gravar as posições.
	var aproximar_maos := maxi(0, int(_args.get("aproximar_maos", "0")))
	if aproximar_maos > 0:
		var mao_frente: Array = posicoes["mao"][0]
		var mao_tras: Array = posicoes["mao"][1]
		mao_frente[0] -= aproximar_maos
		mao_tras[0] += aproximar_maos
		posicoes["mao"][0] = mao_frente
		posicoes["mao"][1] = mao_tras
	var json := {"cabeca": posicoes["cabeca"][0], "tronco": posicoes["tronco"][0],
		"pe_frente": posicoes["pe"][0], "pe_tras": posicoes["pe"][1],
		"mao_frente": posicoes["mao"][0], "mao_tras": posicoes["mao"][1]}
	var f := FileAccess.open(pasta.path_join("pecas" + vista + ".json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(json, "  "))
	f.close()
	if vista != "":
		print("Salvo: ", pasta, " (vista ", vista, ")")
		quit()
		return

	# O personagem montado inteiro, em pixel art com sombra (retrato e conferência).
	var inteiro := montado.get_region(caixa)
	inteiro.resize(roundi(caixa.size.x * fator), roundi(caixa.size.y * fator), Image.INTERPOLATE_LANCZOS)
	_quantizar(inteiro)
	_contorno(inteiro)
	var quadro := Image.create(inteiro.get_width() + 16, inteiro.get_height() + 8, false, Image.FORMAT_RGBA8)
	quadro.blit_rect(inteiro, Rect2i(Vector2i.ZERO, inteiro.get_size()), Vector2i(8, 2))
	SombraTiny.por(quadro, Rect2i(Vector2i(8, 2), inteiro.get_size()))
	quadro.save_png(pasta.path_join("inteiro.png"))
	# Só a sombra (o boneco do jogo é montado por peças em cima dela).
	var sombra := Image.create(quadro.get_width(), quadro.get_height(), false, Image.FORMAT_RGBA8)
	for y in quadro.get_height():
		for x in quadro.get_width():
			var k := quadro.get_pixel(x, y)
			if k.a > 0.0 and k.a < 0.5:
				sombra.set_pixel(x, y, k)
	sombra = sombra.get_region(sombra.get_used_rect())
	sombra.save_png(pasta.path_join("sombra.png"))
	print("Salvo: ", pasta)
	quit()


## A célula `c` com folga em volta (a IA às vezes passa da linha da célula): fica só o que é
## desta célula, ou seja, as manchas cujo meio cai dentro dela. Na célula 0 (personagem
## montado) ficam todas as manchas dela (as mãozinhas soltas são manchas separadas); nas
## peças, só a maior.
func _celula(folha: Image, c: int) -> Image:
	const FOLGA := 112
	var dentro := Rect2i((c % 3) * CELULA, (c / 3) * CELULA, CELULA, CELULA)
	var area := dentro.grow(FOLGA).intersection(Rect2i(Vector2i.ZERO, folha.get_size()))
	var img := folha.get_region(area)
	var w := img.get_width()
	var h := img.get_height()
	var cheio := PackedByteArray()
	cheio.resize(w * h)
	for y in h:
		for x in w:
			var k := img.get_pixel(x, y)
			if k.a < 0.5 or minf(k.r, k.b) - k.g > 0.45:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				cheio[y * w + x] = 1
	# Manchas (vizinhos de 4), com o meio de cada uma.
	var marca := PackedInt32Array()
	marca.resize(w * h)
	marca.fill(-1)
	var manchas: Array = []  # [tamanho, meio]
	for i in w * h:
		if cheio[i] == 0 or marca[i] >= 0:
			continue
		var id := manchas.size()
		var fila := PackedInt32Array([i])
		marca[i] = id
		var soma := Vector2.ZERO
		var n := 0
		while n < fila.size():
			var p := fila[n]
			n += 1
			var px := p % w
			var py := p / w
			soma += Vector2(px, py)
			for v in [p - 1 if px > 0 else -1, p + 1 if px < w - 1 else -1, p - w, p + w]:
				if v >= 0 and v < w * h and cheio[v] == 1 and marca[v] < 0:
					marca[v] = id
					fila.append(v)
		manchas.append([fila.size(), soma / fila.size()])
	var meio_dentro := Rect2(dentro.position - area.position, dentro.size)
	var ficam := {}
	var maior := -1
	for id in manchas.size():
		if manchas[id][0] < 60 or not meio_dentro.has_point(manchas[id][1]):
			continue
		if c == 0:
			ficam[id] = true
		elif maior < 0 or manchas[id][0] > manchas[maior][0]:
			maior = id
	if maior >= 0:
		ficam[maior] = true
	for i in w * h:
		if cheio[i] == 1 and not ficam.has(marca[i]):
			img.set_pixel(i % w, i / w, Color(0, 0, 0, 0))
	return img


func _reduzir(img: Image) -> Image:
	var r := img.duplicate() as Image
	r.resize(maxi(1, img.get_width() / REDUZ), maxi(1, img.get_height() / REDUZ), Image.INTERPOLATE_BILINEAR)
	return r


## Melhor (escala, posição no montado reduzido) para a peça. Custo: diferença média de cor
## nos pixels da peça (fundo do montado conta como diferença máxima).
func _achar(peca: Image, montado: Image, nome: String, escala_fixa := 0.0, evitar := Vector2.INF) -> Dictionary:
	var melhor := {custo = INF, escala = 1.0, pos = Vector2.ZERO}
	# A cabeça sempre sai entre 80% e 105% (a busca solta às vezes acha uma cabeça pequena demais).
	var faixa := [80, 110] if nome == "cabeca" else ([80, 125] if nome == "rosto" else [40, 165])
	var escalas: Array = [escala_fixa] if escala_fixa > 0.0 else range(faixa[0], faixa[1], 5).map(func(n: int) -> float: return n / 100.0)
	var mw := montado.get_width()
	var mh := montado.get_height()
	var md := montado.get_data()
	for s in escalas:
		var tw := roundi(peca.get_width() * s / REDUZ)
		var th := roundi(peca.get_height() * s / REDUZ)
		if tw < 2 or th < 2 or tw > mw or th > mh:
			continue
		var t := peca.duplicate() as Image
		t.resize(tw, th, Image.INTERPOLATE_BILINEAR)
		var td := t.get_data()
		var pontos: Array = []
		for y in th:
			for x in tw:
				var k := (y * tw + x) * 4
				if td[k + 3] > 160:
					pontos.append([x, y, td[k], td[k + 1], td[k + 2]])
		if pontos.size() < 3:
			continue
		for oy in range(0, mh - th + 1):
			for ox in range(0, mw - tw + 1):
				if not _lugar_possivel(nome, ox, oy, tw, th, mw, mh, evitar):
					continue
				var soma := 0.0
				for p in pontos:
					var k: int = ((oy + p[1]) * mw + ox + p[0]) * 4
					if md[k + 3] < 128:
						soma += 1.0
					else:
						soma += (absi(md[k] - p[2]) + absi(md[k + 1] - p[3]) + absi(md[k + 2] - p[4])) / 765.0
				var custo := soma / pontos.size()
				if custo < melhor.custo:
					melhor = {custo = custo, escala = s, pos = Vector2(ox, oy)}
	return melhor


func _quantizar(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(0, 0, 0, 0) if c.a < 0.5 else _mais_proxima(c))


func _mais_proxima(c: Color) -> Color:
	var melhor := _paleta[0]
	var dist := 99.0
	for p in _paleta:
		var d := (c.r - p.r) * (c.r - p.r) * 0.3 + (c.g - p.g) * (c.g - p.g) * 0.59 + (c.b - p.b) * (c.b - p.b) * 0.11
		if d < dist:
			dist = d
			melhor = p
	return melhor


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


## Bom senso na busca: a cabeça fica em cima, os pés embaixo; a segunda mão (ou pé) fica na
## mesma altura da primeira, do outro lado.
func _lugar_possivel(nome: String, ox: int, oy: int, tw: int, th: int, mw: int, mh: int, primeiro: Vector2) -> bool:
	match nome:
		"cabeca":
			if oy > mh * 0.2:
				return false
		"tronco":
			if oy < mh * 0.2 or oy + th < mh * 0.6:
				return false
		"pe":
			if oy + th < mh - 2:
				return false
		"mao":
			if oy < mh * 0.3 or oy + th > mh - 2:
				return false
	if primeiro != Vector2.INF:
		if absf(oy - primeiro.y) > th * 0.6 or absf(ox - primeiro.x) < tw * 0.8:
			return false
	return true


## Caixa do desenho ignorando pontinhos soltos (a IA deixa sujeira longe da peça): só conta
## blocos de 8x8 que estão quase cheios, e depois ajusta a borda pelos pixels de verdade.
func _caixa_principal(img: Image) -> Rect2i:
	var r := Rect2i()
	var primeiro := true
	for by in range(0, img.get_height(), 8):
		for bx in range(0, img.get_width(), 8):
			var cheios := 0
			for y in range(by, mini(by + 8, img.get_height())):
				for x in range(bx, mini(bx + 8, img.get_width())):
					if img.get_pixel(x, y).a > 0.5:
						cheios += 1
			if cheios >= 40:
				var b := Rect2i(bx, by, 8, 8)
				r = b if primeiro else r.merge(b)
				primeiro = false
	r = r.grow(8).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	return _justo(img, r)


func _justo(img: Image, r: Rect2i) -> Rect2i:
	var u := img.get_region(r).get_used_rect()
	return Rect2i(r.position + u.position, u.size)


## Outra cabeça (rosto) do boneco base (L24). A folha de rostos só tem cabeças, desenhadas
## no mesmo tamanho da cabeça do boneco base: a cabeça nova sai com o mesmo pixel (a razão
## entre a cabeça em pixel art e a ilustração dela, na folha base) e fica com o queixo na
## mesma altura; de perfil, com a frente do rosto no mesmo lugar; de frente e de costas,
## centralizada. Grava <saida>/<nome>/cabeca<vista>.png e pecas<vista>.json ({cabeca}).
##   --rosto=<célula da cabeça nova> --base=<pasta do boneco base> --base_folha=<folha base>
##   --base_celula=<célula da cabeça na folha base> [--vista=_frente]
func _montar_rosto(folha: Image) -> void:
	var vista: String = _args.get("vista", "")
	var base := _caminho(_args["base"])
	var folha_base := Image.load_from_file(_caminho(_args["base_folha"]))
	folha_base.convert(Image.FORMAT_RGBA8)
	var cab_base := _celula(folha_base, int(_args["base_celula"]))
	cab_base = cab_base.get_region(_caixa_principal(cab_base))
	var px_base := Image.load_from_file(base.path_join("cabeca" + vista + ".png"))
	var razao := px_base.get_width() / float(cab_base.get_width())
	var nova := _celula(folha, int(_args["rosto"]))
	nova = nova.get_region(_caixa_principal(nova))
	var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base.path_join("pecas" + vista + ".json")))
	var p0 := Vector2(j["cabeca"][0], j["cabeca"][1])
	# A IA não desenha as cabeças da folha de rostos no tamanho da cabeça base: acha o ROSTO
	# (metade de baixo da cabeça base, do lado do rosto) dentro da cabeça nova para saber a
	# escala e o lugar. De costas não há rosto: usa a escala achada de frente (--escala).
	var escala := float(_args.get("escala", "0"))
	var x: float
	var y: float
	if escala > 0.0:
		# Escala já conhecida: queixo na mesma altura; de perfil, a frente do rosto no mesmo lugar.
		var r := razao / escala
		x = p0.x + px_base.get_width() - nova.get_width() * r if vista == "" else p0.x + (px_base.get_width() - nova.get_width() * r) / 2.0
		y = p0.y + px_base.get_height() - nova.get_height() * r
	else:
		var cw := cab_base.get_width()
		var ch := cab_base.get_height()
		var recorte := Rect2i(roundi(cw * 0.45), roundi(ch * 0.5), roundi(cw * 0.55), ch - roundi(ch * 0.5)) if vista == "" \
				else Rect2i(roundi(cw * 0.2), roundi(ch * 0.5), roundi(cw * 0.6), ch - roundi(ch * 0.5))
		var achado := _achar(cab_base.get_region(recorte), _reduzir(nova), "rosto")
		escala = achado.escala
		var r := razao / escala
		var no_novo: Vector2 = achado.pos * REDUZ * r
		x = p0.x + recorte.position.x * razao - no_novo.x
		y = p0.y + recorte.position.y * razao - no_novo.y
		print("rosto achado: escala %.2f (custo %.2f)" % [escala, achado.custo])
	var rr := razao / escala
	nova.resize(maxi(1, roundi(nova.get_width() * rr)), maxi(1, roundi(nova.get_height() * rr)), Image.INTERPOLATE_LANCZOS)
	_quantizar(nova)
	_contorno(nova)
	if vista == "_costas" or _args.get("alinhar", "") == "topo":
		# De costas: o alto do crânio (primeira linha larga, sem o moicano nem a barba) no
		# mesmo lugar do da cabeça base.
		y = p0.y + _topo_cranio(px_base) - _topo_cranio(nova)
	var pasta := _caminho(_args["saida"]).path_join(_args["nome"])
	DirAccess.make_dir_recursive_absolute(pasta)
	nova.save_png(pasta.path_join("cabeca" + vista + ".png"))
	var f := FileAccess.open(pasta.path_join("pecas" + vista + ".json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"cabeca": [roundi(x), roundi(y)]}, "  "))
	f.close()
	print("rosto %s: %dx%d em (%d, %d), razão %.4f" % [vista, nova.get_width(), nova.get_height(), roundi(x), roundi(y), razao])
	quit()


## Primeira linha em que o desenho ocupa ao menos 60% da largura (o alto do crânio, sem o
## topete ou o moicano por cima).
func _topo_cranio(img: Image) -> int:
	var w := img.get_width()
	for y in img.get_height():
		var n := 0
		for x in w:
			if img.get_pixel(x, y).a > 0.5:
				n += 1
		if n >= w * 0.6:
			return y
	return 0


## O rosto do boneco base (--rosto_base_folha, --rosto_base_celula: a folha base e a célula
## da cabeça nesta vista; a pasta base vem de --fator_de) dentro do montado reduzido. Devolve
## k (pixels da arte por pixel da ilustração do montado), p0 e tamanho (lugar e tamanho da
## cabeça base em pixels da arte) e cabeca_bruta (canto da cabeça no montado, em pixels da
## ilustração, a partir da caixa do montado). De costas, k vem de --k (o achado de frente).
func _rosto_no_montado(pequeno: Image, vista: String) -> Dictionary:
	var base := _caminho(_args["fator_de"])
	var folha_base := Image.load_from_file(_caminho(_args["rosto_base_folha"]))
	folha_base.convert(Image.FORMAT_RGBA8)
	var cab_base := _celula(folha_base, int(_args["rosto_base_celula"]))
	cab_base = cab_base.get_region(_caixa_principal(cab_base))
	var px_base := Image.load_from_file(base.path_join("cabeca" + vista + ".png"))
	var razao := px_base.get_width() / float(cab_base.get_width())
	var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base.path_join("pecas" + vista + ".json")))
	var r := {p0 = Vector2(j["cabeca"][0], j["cabeca"][1]), tamanho = Vector2(px_base.get_size())}
	if vista == "_costas":
		r.k = float(_args["k"])
		return r
	var cw := cab_base.get_width()
	var ch := cab_base.get_height()
	var recorte := Rect2i(roundi(cw * 0.45), roundi(ch * 0.5), roundi(cw * 0.55), ch - roundi(ch * 0.5)) if vista == "" \
			else Rect2i(roundi(cw * 0.2), roundi(ch * 0.5), roundi(cw * 0.6), ch - roundi(ch * 0.5))
	var achado := _achar(cab_base.get_region(recorte), pequeno, "rosto")
	var escala: float = achado.escala
	r.k = razao / escala
	r.cabeca_bruta = achado.pos * REDUZ - Vector2(recorte.position) * escala
	print("rosto no montado: escala %.2f (custo %.2f)" % [escala, achado.custo])
	return r
