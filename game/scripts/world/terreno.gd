class_name Terreno
extends RefCounted
## As camadas de chão da ilha (L41), por cima da água: areia, lama, piso de pedra, trilha e
## as 5 gramas, de baixo para cima. Substitui o desenho antigo, que escolhia 1 de 16 tiles pelos
## 4 vizinhos (cantos de dentro quadrados, contorno de penhasco entre duas gramas, uma linha
## de areia entre elas e o miolo da lama repetido a cada bloco).
##
## Como fica agora:
##   - Cada bloco é desenhado em 4 QUARTOS (32 px da arte). Cada quarto olha 3 vizinhos (o do
##     lado, o de cima/baixo e o da diagonal) e escolhe: miolo, borda de cima/baixo, borda do
##     lado, canto de fora ou canto de DENTRO. Os pedaços vêm do próprio tileset do chão, no
##     formato do Tiny Swords; o canto de dentro é a união das duas bordas (as bolinhas da borda
##     se encontram, sem degrau quadrado).
##   - Onde o vizinho é ÁGUA, a borda é a do pacote (contorno azul-escuro e o brilho claro).
##     Onde é OUTRO CHÃO, o contorno fica da cor escura do próprio chão e o brilho vira uma
##     sombrinha em cima do chão de baixo (sem cara de penhasco).
##   - O chão de baixo continua por baixo da borda do de cima (não sobra buraco de areia).
##   - O miolo da areia, da lama, da trilha e do piso vem de uma TEXTURA GRANDE presa ao mundo
##     (shader terreno_preenchimento), em espelho: a lama não se repete mais a cada bloco.
##   - Antes de desenhar, as pontas soltas de 1 bloco viram o chão em volta (só no desenho; a
##     região e o piso do jogo não mudam).

const Q := 32  # um quarto de bloco, em pixels da arte
const MOLDE := preload("res://assets/tiny_swords/terreno/grama.png")
const SHADER := preload("res://shaders/terreno_preenchimento.gdshader")
## Sombrinha do chão de cima sobre o de baixo: a cor da sombra do pacote, mais fraca.
const SOMBRA := Color(0.086, 0.11, 0.18, 0.22)
## Luz do verde de base da grama do pacote (#9bb94e): o sombreado da borda é relativo a ela.
const LUZ_MIOLO_MOLDE := 0.67
## Até quantos pixels da borda o desenho é o do tileset (as bolinhas); dali para dentro, a
## textura grande.
const FAIXA_BORDA := 11

enum Classe { NADA, BRILHO, CONTORNO, MIOLO }
## O pedaço que cada quarto usa.
enum Tipo { MEIO, FORA, HORIZ, VERT, DENTRO }

## Os chãos (nível de desenho): 0 areia, 1 lama, 2 pedra, 3 trilha, 4 + região a grama.
const NIVEL_GRAMA := 4

## [tileset, textura do miolo ("" = usa o próprio tileset)]
const CHAOS := {
	0: ["res://assets/sprites/tiny/areia.png", "res://assets/sprites/tiny/mundo/textura_areia.png"],
	1: ["res://assets/sprites/tiny/mundo/lama.png", "res://assets/sprites/tiny/mundo/textura_lama.png"],
	2: ["res://assets/sprites/tiny/mundo/piso.png", "res://assets/sprites/tiny/mundo/textura_piso.png"],
	3: ["res://assets/sprites/tiny/mundo/trilha.png", "res://assets/sprites/tiny/mundo/textura_trilha.png"],
}
## A grama de cada região: os 5 tons do pacote (a Praia é só areia).
const GRAMAS := {
	Regioes.Id.CLAREIRA: "res://assets/tiny_swords/terreno/grama.png",
	Regioes.Id.BOSQUE: "res://assets/tiny_swords/terreno/grama2.png",
	Regioes.Id.RUINAS: "res://assets/tiny_swords/terreno/grama3.png",
	Regioes.Id.COLINAS: "res://assets/tiny_swords/terreno/grama4.png",
	Regioes.Id.PANTANO: "res://assets/tiny_swords/terreno/grama5.png",
}

var largura := 0
var altura := 0
var terra := PackedByteArray()  # 1 = chão firme
var nivel := PackedByteArray()  # o chão de cima de cada bloco
static var _classes: Array = []  # [quarto][tipo] -> Image de classes (cache do molde)


## Monta o nível de cada bloco a partir do gerador (`areia_extra`: blocos de grama que são
## desenhados como areia, a clareira da fogueira).
func preparar(g: GeradorIlha, areia_extra: Dictionary) -> void:
	largura = GeradorIlha.LARGURA
	altura = GeradorIlha.ALTURA
	var n := largura * altura
	terra.resize(n)
	nivel.resize(n)
	for y in altura:
		for x in largura:
			var i := y * largura + x
			if g.tipo[i] == World.Chao.AGUA:
				continue
			terra[i] = 1
			if areia_extra.has(Vector2i(x, y)):
				continue  # areia
			if g.piso[i] != GeradorIlha.Piso.NADA:
				nivel[i] = g.piso[i]
			elif g.tipo[i] == World.Chao.GRAMA:
				nivel[i] = NIVEL_GRAMA + g.regiao[i]
	_suavizar()


func eh_terra(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < largura and y < altura and terra[y * largura + x] == 1


func nivel_em(x: int, y: int) -> int:
	return nivel[y * largura + x] if eh_terra(x, y) else -1


## Tira do desenho as pontas e os buracos de 1 bloco (fora da trilha, que é fininha): o bloco
## que tem só 0 ou 1 vizinho igual (dos 4) vira o chão mais comum em volta.
func _suavizar() -> void:
	for passada in 2:
		var novo := nivel.duplicate()
		for y in altura:
			for x in largura:
				var i := y * largura + x
				if terra[i] == 0 or nivel[i] == GeradorIlha.Piso.TRILHA:
					continue
				var iguais := 0
				for v in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
					if nivel_em(x + v.x, y + v.y) == nivel[i]:
						iguais += 1
				if iguais >= 2:
					continue
				var conta := {}
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var m := nivel_em(x + dx, y + dy)
						if (dx != 0 or dy != 0) and m >= 0 and m != GeradorIlha.Piso.TRILHA:
							conta[m] = conta.get(m, 0) + 1
				var melhor := int(nivel[i])
				var mais := 0
				for m in conta:
					if conta[m] > mais or (conta[m] == mais and m < melhor):
						mais = conta[m]
						melhor = m
				novo[i] = melhor
		nivel = novo


## As camadas, de baixo para cima, prontas para pôr no nó do terreno (escala 0,25).
func camadas() -> Array[TileMapLayer]:
	# Em cada bloco: o chão dele e, por baixo da borda, os chãos mais baixos dos 8 vizinhos.
	var por_nivel := {}
	for y in altura:
		for x in largura:
			var meu := nivel_em(x, y)
			if meu < 0:
				continue
			_marcar(por_nivel, meu, x, y)
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var m := nivel_em(x + dx, y + dy)
					if m >= 0 and m < meu:
						_marcar(por_nivel, m, x, y)
	var niveis := por_nivel.keys()
	niveis.sort()
	var saida: Array[TileMapLayer] = []
	for nv in niveis:
		var camada := _camada(nv, por_nivel[nv])
		if camada:
			saida.append(camada)
	return saida


func _marcar(por_nivel: Dictionary, nv: int, x: int, y: int) -> void:
	if not por_nivel.has(nv):
		por_nivel[nv] = {}
	por_nivel[nv][Vector2i(x, y)] = true


func _camada(nv: int, celulas: Dictionary) -> TileMapLayer:
	var caminho_ts: String
	var caminho_tex := ""
	if nv >= NIVEL_GRAMA:
		caminho_ts = GRAMAS.get(nv - NIVEL_GRAMA, "")
	else:
		caminho_ts = CHAOS[nv][0]
		caminho_tex = CHAOS[nv][1]
	if caminho_ts == "" or not ResourceLoader.exists(caminho_ts):
		return null
	var tileset_img := (load(caminho_ts) as Texture2D).get_image()
	tileset_img.convert(Image.FORMAT_RGBA8)
	var textura: Texture2D = null
	if caminho_tex != "":
		if ResourceLoader.exists(caminho_tex):
			textura = load(caminho_tex)
		else:
			# Sem a textura grande ainda: o miolo do próprio tileset (o espelho tira a emenda).
			textura = ImageTexture.create_from_image(tileset_img.get_region(Rect2i(16, 16, 160, 160)))
	var ts := TileSet.new()
	ts.tile_size = Vector2i(Q, Q)
	var src := TileSetAtlasSource.new()
	src.texture = ImageTexture.create_from_image(atlas(tileset_img, textura != null))
	src.texture_region_size = Vector2i(Q, Q)
	ts.add_source(src, 0)
	for y in 5:
		for x in 8:
			src.create_tile(Vector2i(x, y))
	var camada := TileMapLayer.new()
	camada.name = "Chao%d" % nv
	camada.tile_set = ts
	if textura:
		var mat := ShaderMaterial.new()
		mat.shader = SHADER
		mat.set_shader_parameter(&"preenchimento", textura)
		camada.material = mat
	for c: Vector2i in celulas:
		for q in 4:
			var qx := q % 2
			var qy := q / 2
			var sx := 1 if qx == 1 else -1
			var sy := 1 if qy == 1 else -1
			var h := _cheio(c.x + sx, c.y, nv)
			var v := _cheio(c.x, c.y + sy, nv)
			var d := _cheio(c.x + sx, c.y + sy, nv)
			var tipo: int
			var faltam: Array[Vector2i] = []
			if h and v and d:
				tipo = Tipo.MEIO
			elif h and v:
				tipo = Tipo.DENTRO
				faltam = [Vector2i(c.x + sx, c.y + sy)]
			elif h:
				tipo = Tipo.HORIZ
				faltam = [Vector2i(c.x, c.y + sy)]
			elif v:
				tipo = Tipo.VERT
				faltam = [Vector2i(c.x + sx, c.y)]
			else:
				tipo = Tipo.FORA
				faltam = [Vector2i(c.x + sx, c.y), Vector2i(c.x, c.y + sy)]
			var costa := false
			for f in faltam:
				if not eh_terra(f.x, f.y):
					costa = true
			camada.set_cell(c * 2 + Vector2i(qx, qy), 0, Vector2i(q + (4 if costa else 0), tipo))
	return camada


## O vizinho conta como "do mesmo chão" para a camada `nv` (é terra e o chão dele é este ou
## um que fica por cima).
func _cheio(x: int, y: int, nv: int) -> bool:
	return nivel_em(x, y) >= nv


# --- Atlas das bordas ------------------------------------------------------------------
## Atlas de 8 x 5 quartos: coluna = quarto (0 cima-esq., 1 cima-dir., 2 baixo-esq.,
## 3 baixo-dir.) + 4 se a borda dá para a água; linha = Tipo. Os pixels de miolo saem em magenta
## puro quando `com_textura` (o shader troca pela textura grande).
static func atlas(tileset: Image, com_textura: bool) -> Image:
	var molde := MOLDE.get_image()
	molde.convert(Image.FORMAT_RGBA8)
	var miolo := _cor_media(tileset)
	var aro := miolo.darkened(0.42)
	var aro_escuro := miolo.darkened(0.6)
	var faixa := _distancia_da_borda(molde) if com_textura else PackedByteArray()
	var img := Image.create_empty(8 * Q, 5 * Q, false, Image.FORMAT_RGBA8)
	for q in 4:
		for tipo in 5:
			for costa in 2:
				for y in Q:
					for x in Q:
						var origem := _origem(molde, q, tipo, x, y)
						var classe := _classe(molde.get_pixelv(origem))
						var cor := Color(0, 0, 0, 0)
						match classe:
							Classe.MIOLO:
								if not com_textura:
									cor = tileset.get_pixelv(origem)
								elif faixa[origem.y * 192 + origem.x] > FAIXA_BORDA:
									cor = Color(1, 0.25, 1, 1)  # miolo: a textura sem sombra
								else:
									# As bolinhas da borda: a textura com o sombreado da grama do
									# pacote (as linhas escuras entre as bolinhas).
									var tom := clampf(molde.get_pixelv(origem).get_luminance() / LUZ_MIOLO_MOLDE, 0.45, 1.2)
									cor = Color(1, tom / 4.0, 1, 1)
							Classe.CONTORNO:
								var m := molde.get_pixelv(origem)
								if costa == 1:
									cor = m
								else:
									cor = aro_escuro if m.get_luminance() < 0.12 else aro
							Classe.BRILHO:
								cor = molde.get_pixelv(origem) if costa == 1 else SOMBRA
						img.set_pixel((q + 4 * costa) * Q + x, tipo * Q + y, cor)
	return img


## De onde vem o pixel (x, y) do quarto `q` do pedaço `tipo` (no formato do tileset do
## pacote: o bloco 3x3 nos tiles (0..2, 0..2)). O canto de dentro é a união das duas bordas:
## fica o pixel de classe mais alta (miolo > contorno > brilho > nada).
static func _origem(molde: Image, q: int, tipo: int, x: int, y: int) -> Vector2i:
	var qx := q % 2
	var qy := q / 2
	var lado := 0 if qx == 0 else 2  # coluna do tile da borda do lado
	var topo := 0 if qy == 0 else 2  # linha do tile da borda de cima/baixo
	var dentro := Vector2i(qx * Q + x, qy * Q + y)
	match tipo:
		Tipo.MEIO:
			return Vector2i(64, 64) + dentro
		Tipo.FORA:
			return Vector2i(lado * 64, topo * 64) + dentro
		Tipo.HORIZ:
			return Vector2i(64, topo * 64) + dentro
		Tipo.VERT:
			return Vector2i(lado * 64, 64) + dentro
	var a := Vector2i(64, topo * 64) + dentro
	var b := Vector2i(lado * 64, 64) + dentro
	return a if _classe(molde.get_pixelv(a)) >= _classe(molde.get_pixelv(b)) else b


## Distância (em pixels, de quadrado) de cada pixel do bloco 3x3 do molde até o pixel mais perto
## que não é miolo (contorno, brilho ou vazio). Índice = y * 192 + x.
static func _distancia_da_borda(molde: Image) -> PackedByteArray:
	var d := PackedByteArray()
	d.resize(192 * 192)
	d.fill(255)
	var fila: Array[Vector2i] = []
	for y in 192:
		for x in 192:
			if _classe(molde.get_pixel(x, y)) != Classe.MIOLO:
				d[y * 192 + x] = 0
				fila.append(Vector2i(x, y))
	var k := 0
	while k < fila.size():
		var p := fila[k]
		k += 1
		var v := d[p.y * 192 + p.x]
		if v >= FAIXA_BORDA + 1:
			continue
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var o := p + Vector2i(dx, dy)
				if o.x >= 0 and o.y >= 0 and o.x < 192 and o.y < 192 and d[o.y * 192 + o.x] > v + 1:
					d[o.y * 192 + o.x] = v + 1
					fila.append(o)
	return d


static func _classe(m: Color) -> int:
	if m.a < 0.05:
		return Classe.NADA
	if m.get_luminance() < 0.22:
		return Classe.CONTORNO
	if m.r > 0.6 and m.b > 0.7:
		return Classe.BRILHO  # o brilho claro da beira da água
	return Classe.MIOLO


## A cor média do miolo do chão (tile do meio): base do contorno de dentro da ilha.
static func _cor_media(tileset: Image) -> Color:
	var soma := Color(0, 0, 0, 0)
	var n := 0
	for y in range(64, 128, 2):
		for x in range(64, 128, 2):
			var c := tileset.get_pixel(x, y)
			if c.a > 0.5:
				soma += c
				n += 1
	return Color(soma.r / n, soma.g / n, soma.b / n, 1.0) if n > 0 else Color(0.3, 0.3, 0.3)


# --- Peças nas emendas ------------------------------------------------------------------
## Tufos de grama (L41 folha D1, um por tom: a ordem é a de GRAMAS) e pedacinhos (folha D2:
## torrões, lajes soltas, laje afundada, lodo, pedrinhas de praia, folhinhas) espalhados em
## cima da linha onde dois chãos se encontram, para disfarçar a emenda.
const TUFOS := preload("res://assets/sprites/tiny/mundo/emendas_tufos.png")
const PEDACOS := preload("res://assets/sprites/tiny/mundo/emendas_pedacos.png")
const TOM_TUFO := {
	Regioes.Id.CLAREIRA: 0, Regioes.Id.BOSQUE: 1, Regioes.Id.RUINAS: 2, Regioes.Id.COLINAS: 3, Regioes.Id.PANTANO: 4,
}
enum Pedaco { TORROES, LAJES, LAJE_AFUNDADA, LODO, PEDRINHAS, FOLHINHAS }


## As peças das emendas: [textura, quadro, posição em pixels da arte (os pés)]. Sorteio fixo
## por bloco (hash), sem mexer no sorteio do resto do mundo; no máximo 1 peça por bloco.
func emendas() -> Array:
	var saida: Array = []
	for y in altura:
		for x in largura:
			var meu := nivel_em(x, y)
			if meu < 0:
				continue
			for v: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var outro := nivel_em(x + v.x, y + v.y)
				if outro < 0 or outro >= meu:
					continue
				var sorte := absi(hash(Vector3i(x, y, v.x * 3 + v.y))) % 1000
				var peca := _peca(meu, outro, sorte)
				if peca.is_empty():
					continue
				# Do lado de cima (o tufo, em cima da borda) ou do lado de baixo (o pedacinho).
				var passo := 0.3 if peca[2] else 0.62
				var mexe := Vector2((sorte % 13) - 6, (sorte / 13 % 9) - 4) * 2.0
				var pos := (Vector2(x, y) + Vector2(0.5, 0.5) + Vector2(v) * passo) * 64.0 + mexe
				pos.y += 14.0  # os pés da peça um pouco abaixo do meio
				saida.append([peca[0], peca[1], pos])
				break
	return saida


## [textura, quadro, fica do lado de cima?] da peça para a emenda do chão `meu` sobre o
## `outro`, ou [] (nada) conforme a sorte (0 a 999).
func _peca(meu: int, outro: int, sorte: int) -> Array:
	var grama := meu >= NIVEL_GRAMA
	if grama:
		var regiao := meu - NIVEL_GRAMA
		match outro:
			GeradorIlha.Piso.PEDRA:
				if sorte < 160:
					return [PEDACOS, Pedaco.LAJES, false]
				if sorte < 260:
					return [PEDACOS, Pedaco.LAJE_AFUNDADA, true]
			GeradorIlha.Piso.LAMA:
				if sorte < 180:
					return [PEDACOS, Pedaco.LODO, false]
			GeradorIlha.Piso.TRILHA:
				if sorte < 110:
					return [PEDACOS, Pedaco.TORROES, false]
			0:
				if sorte < 130:
					return [PEDACOS, Pedaco.PEDRINHAS, false]
		if sorte >= 420 and sorte < 880:
			return [TUFOS, TOM_TUFO.get(regiao, 0), true]
		if sorte >= 880 and sorte < 940 and regiao in [Regioes.Id.CLAREIRA, Regioes.Id.BOSQUE]:
			return [TUFOS, 5, true]  # tufinho com flores
		if sorte >= 940 and regiao == Regioes.Id.BOSQUE:
			return [PEDACOS, Pedaco.FOLHINHAS, true]
		return []
	if meu == GeradorIlha.Piso.TRILHA and sorte < 200:
		return [PEDACOS, Pedaco.TORROES, true]
	return []
