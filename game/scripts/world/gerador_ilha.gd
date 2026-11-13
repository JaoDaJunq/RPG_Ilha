class_name GeradorIlha
extends RefCounted
## Desenha a ilha grande (etapa 1 do mundo maior, design/proposta_mundo.md) a partir de uma
## semente fixa: sempre a mesma ilha, igual em todos os jogadores.
##
## O que sai daqui (tudo por bloco de 16 px, índice = y * largura + x):
##   - tipo: água, areia (beira do mar e praia) ou grama;
##   - regiao: a região de cada bloco (Regioes.Id);
##   - piso: chão especial por cima da areia (trilha, lama do pântano, piso das ruínas);
##   - o rio que separa o norte (Colinas e Ruínas) do resto, com duas passagens:
##     a ponte (Pântano → Colinas) e o vau das raízes (Bosque → Ruínas);
##   - os caminhos que ligam a Clareira a todas as regiões.
## As regiões e os pontos importantes são colocados à mão (coordenadas abaixo); o ruído só
## deixa as bordas orgânicas.

## Na ordem em que são desenhados (de baixo para cima; a trilha passa por cima dos outros).
enum Piso { NADA, LAMA, PEDRA, TRILHA }

const LARGURA := 190
const ALTURA := 130
## O centro da Clareira (o acampamento).
const CENTRO := Vector2i(95, 65)
## Raios da Clareira (em blocos): mais ou menos o tamanho da ilha antiga.
const CLAREIRA_RAIO := Vector2(24, 17)

## O rio: desce da costa norte, contorna o norte da Clareira e sobe de novo para a costa.
const RIO: Array[Vector2] = [
	Vector2(60, -4), Vector2(59, 12), Vector2(61, 22), Vector2(61, 34), Vector2(68, 42),
	Vector2(84, 45), Vector2(104, 45), Vector2(124, 43), Vector2(140, 40), Vector2(147, 30),
	Vector2(150, 16), Vector2(152, -4),
]
const RIO_LARGURA := 2.3  # meia largura, em blocos
## A ponte atravessa o trecho do rio que corre de cima para baixo (a oeste).
const PONTE := Vector2i(61, 28)
## O vau: uma faixa de terra no rio, fechada pela muralha de raízes.
const VAU := Vector2i(118, 44)
const VAU_RAIO := 2

## Sementes das regiões (blocos). A região de um bloco é a da semente mais perto (com as
## coordenadas tortas pelo ruído); a Clareira é a elipse do centro.
const SEMENTES := {
	Regioes.Id.BOSQUE: [Vector2(150, 70), Vector2(138, 88), Vector2(160, 55)],
	Regioes.Id.PRAIA: [Vector2(95, 112), Vector2(62, 106), Vector2(128, 108)],
	Regioes.Id.PANTANO: [Vector2(32, 68), Vector2(42, 92), Vector2(40, 48)],
	Regioes.Id.COLINAS: [Vector2(78, 20), Vector2(96, 26), Vector2(68, 8)],
	Regioes.Id.RUINAS: [Vector2(140, 18), Vector2(124, 30)],
}
## Praças das ruínas (piso de pedra antiga em volta).
const PRACAS: Array[Vector2] = [Vector2(140, 18), Vector2(126, 30), Vector2(152, 30)]

## Caminhos (trilhas de terra), de ponto a ponto.
const CAMINHOS: Array = [
	[Vector2(95, 65), Vector2(122, 68), Vector2(148, 70), Vector2(158, 58)],  # Bosque
	[Vector2(95, 65), Vector2(98, 88), Vector2(95, 110)],  # Praia
	[Vector2(98, 88), Vector2(70, 100), Vector2(55, 104)],  # Praia oeste
	[Vector2(95, 65), Vector2(68, 67), Vector2(36, 68)],  # Pântano
	[Vector2(36, 68), Vector2(48, 52), Vector2(54, 34), Vector2(57, 28)],  # até a ponte
	[Vector2(66, 28), Vector2(80, 22), Vector2(96, 26), Vector2(112, 22), Vector2(140, 18)],  # Colinas → Ruínas
	[Vector2(95, 65), Vector2(108, 54), Vector2(118, 47)],  # até o vau
	[Vector2(118, 40), Vector2(124, 32), Vector2(140, 18)],  # do vau às Ruínas
]

var semente := 0
var tipo := PackedByteArray()  # World.Chao
var regiao := PackedByteArray()  # Regioes.Id
var piso := PackedByteArray()  # Piso
var distancia := PackedFloat32Array()  # 0 no centro, 1 na beira do mar
## Blocos de água cobertos pela ponte e de terra fechados pelas raízes.
var celulas_ponte: Array[Vector2i] = []
var celulas_vau: Array[Vector2i] = []
var _ruido := FastNoiseLite.new()
var _ruido_fino := FastNoiseLite.new()
var _ruido_regiao := FastNoiseLite.new()
var _ruido_lama := FastNoiseLite.new()


func gerar(semente_ilha: int) -> void:
	semente = semente_ilha
	_ruido.seed = semente
	_ruido.frequency = 0.022
	_ruido_fino.seed = semente + 1
	_ruido_fino.frequency = 0.09
	_ruido_regiao.seed = semente + 2
	_ruido_regiao.frequency = 0.04
	_ruido_lama.seed = semente + 4
	_ruido_lama.frequency = 0.045
	var n := LARGURA * ALTURA
	tipo.resize(n)
	regiao.resize(n)
	piso.resize(n)
	distancia.resize(n)
	_formato()
	_rio()
	_regioes()
	_caminhos()
	_pisos_das_regioes()


func indice(c: Vector2i) -> int:
	return c.y * LARGURA + c.x


func dentro(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < LARGURA and c.y < ALTURA


func tipo_em(c: Vector2i) -> int:
	return tipo[indice(c)] if dentro(c) else World.Chao.AGUA


func regiao_em(c: Vector2i) -> int:
	return regiao[indice(c)] if dentro(c) else Regioes.Id.PRAIA


func piso_em(c: Vector2i) -> int:
	return piso[indice(c)] if dentro(c) else Piso.NADA


# --- Formato ---------------------------------------------------------------------

func _formato() -> void:
	for y in ALTURA:
		for x in LARGURA:
			var nx := (x - CENTRO.x) / (LARGURA * 0.455)
			var ny := (y - CENTRO.y) / (ALTURA * 0.43)
			var d := sqrt(nx * nx + ny * ny) + _ruido.get_noise_2d(x, y) * 0.24 + _ruido_fino.get_noise_2d(x, y) * 0.05
			var i := y * LARGURA + x
			distancia[i] = d
			var borda := mini(mini(x, y), mini(LARGURA - 1 - x, ALTURA - 1 - y))
			if d > 1.0 or borda < 3:
				tipo[i] = World.Chao.AGUA
			elif d > 0.9:
				tipo[i] = World.Chao.AREIA
			else:
				tipo[i] = World.Chao.GRAMA


func _rio() -> void:
	for y in ALTURA:
		for x in LARGURA:
			var c := Vector2i(x, y)
			var i := indice(c)
			if tipo[i] == World.Chao.AGUA:
				continue
			var p := Vector2(x, y)
			var largura := RIO_LARGURA + _ruido_fino.get_noise_2d(x * 2, y * 2) * 0.5
			if _dist_linha(p, RIO) > largura:
				continue
			if p.distance_to(Vector2(VAU)) <= VAU_RAIO + 0.5:
				celulas_vau.append(c)  # o vau continua terra
				continue
			tipo[i] = World.Chao.AGUA
			if (y == PONTE.y or y == PONTE.y + 1) and absi(x - PONTE.x) <= 4:
				celulas_ponte.append(c)


## Distância de um ponto até a linha quebrada.
static func _dist_linha(p: Vector2, linha: Array) -> float:
	var melhor := INF
	for k in linha.size() - 1:
		var a: Vector2 = linha[k]
		var b: Vector2 = linha[k + 1]
		var t := clampf((p - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
		melhor = minf(melhor, p.distance_to(a + (b - a) * t))
	return melhor


# --- Regiões ---------------------------------------------------------------------

func _regioes() -> void:
	# O sul é o que se alcança a pé da Clareira sem a ponte e sem o vau; o resto é o norte.
	var sul := {}
	var fila: Array[Vector2i] = [CENTRO]
	sul[CENTRO] = true
	var fechado := {}
	for c in celulas_vau:
		fechado[c] = true
	while not fila.is_empty():
		var c: Vector2i = fila.pop_back()
		for v in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var o: Vector2i = c + v
			if dentro(o) and not sul.has(o) and not fechado.has(o) and tipo[indice(o)] != World.Chao.AGUA:
				sul[o] = true
				fila.append(o)
	for y in ALTURA:
		for x in LARGURA:
			var c := Vector2i(x, y)
			var i := indice(c)
			if sul.has(c):
				var e := Vector2((x - CENTRO.x) / CLAREIRA_RAIO.x, (y - CENTRO.y) / CLAREIRA_RAIO.y)
				if e.length() + _ruido_regiao.get_noise_2d(x, y) * 0.25 < 1.0:
					regiao[i] = Regioes.Id.CLAREIRA
				else:
					regiao[i] = _mais_perto(x, y, [Regioes.Id.BOSQUE, Regioes.Id.PRAIA, Regioes.Id.PANTANO])
			else:
				regiao[i] = _mais_perto(x, y, [Regioes.Id.COLINAS, Regioes.Id.RUINAS])
			# A praia é de areia.
			if regiao[i] == Regioes.Id.PRAIA and tipo[i] == World.Chao.GRAMA:
				tipo[i] = World.Chao.AREIA
	for c in celulas_vau:
		regiao[indice(c)] = Regioes.Id.RUINAS


func _mais_perto(x: int, y: int, quais: Array) -> int:
	var p := Vector2(x, y) + Vector2(_ruido_regiao.get_noise_2d(x, y + 300), _ruido_regiao.get_noise_2d(x + 300, y)) * 14.0
	var melhor := int(quais[0])
	var menor := INF
	for r in quais:
		for s in SEMENTES[r]:
			var d := p.distance_squared_to(s)
			if d < menor:
				menor = d
				melhor = r
	return melhor


# --- Caminhos e chãos especiais ------------------------------------------------------------

func _caminhos() -> void:
	for linha in CAMINHOS:
		var pontos: Array = linha
		for k in pontos.size() - 1:
			var a: Vector2 = pontos[k]
			var b: Vector2 = pontos[k + 1]
			var passos := int(a.distance_to(b) * 2.0)
			for s in passos + 1:
				var t := float(s) / passos
				var p := a.lerp(b, t)
				# Um pouco de curva (ruído perpendicular), menos nas pontas.
				var normal := (b - a).normalized().orthogonal()
				p += normal * _ruido.get_noise_2d(p.x * 3.0, p.y * 3.0) * 3.0 * sin(t * PI)
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var c := Vector2i(roundi(p.x) + dx, roundi(p.y) + dy)
						if dentro(c) and tipo[indice(c)] != World.Chao.AGUA and Vector2(c).distance_to(p) <= 1.3:
							piso[indice(c)] = Piso.TRILHA
	# Em volta da fogueira o chão é de areia batida (a clareira do acampamento).
	for y in range(CENTRO.y - 3, CENTRO.y + 4):
		for x in range(CENTRO.x - 3, CENTRO.x + 4):
			if Vector2(x - CENTRO.x, y - CENTRO.y).length() <= 2.6:
				piso[indice(Vector2i(x, y))] = Piso.NADA


func _pisos_das_regioes() -> void:
	for y in ALTURA:
		for x in LARGURA:
			var c := Vector2i(x, y)
			var i := indice(c)
			if tipo[i] == World.Chao.AGUA or piso[i] == Piso.TRILHA:
				continue
			match regiao[i]:
				Regioes.Id.PANTANO:
					var n := _ruido_lama.get_noise_2d(x, y)
					if n > 0.38 and distancia[i] < 0.86 and not _perto_de_trilha(c, 2):
						tipo[i] = World.Chao.AGUA  # lagoinhas
					elif n > -0.05:
						piso[i] = Piso.LAMA
				Regioes.Id.RUINAS:
					for pr in PRACAS:
						if Vector2(x, y).distance_to(pr) + _ruido_fino.get_noise_2d(x, y) * 3.0 < 6.5:
							piso[i] = Piso.PEDRA


func _perto_de_trilha(c: Vector2i, raio: int) -> bool:
	for dy in range(-raio, raio + 1):
		for dx in range(-raio, raio + 1):
			if piso_em(c + Vector2i(dx, dy)) == Piso.TRILHA:
				return true
	return false
