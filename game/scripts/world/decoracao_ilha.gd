class_name DecoracaoIlha
extends RefCounted
## Espalha o que fica parado no mundo, por região (L36): árvores e pedras (recursos), e a
## decoração (flores, conchas, cogumelos que brilham, colunas, névoa do pântano...).
##
## Tudo nasce igual em todos os jogadores: a mesma semente, a mesma ordem e os mesmos nomes
## (Arvore1, Pedra1...). Cada bloco de terra sorteia UM número e a tabela da região diz o que
## sai dele; por isso a densidade da decoração (World.plantas) não muda onde ficam as árvores.

const ARVORE := preload("res://scenes/world/arvore.tscn")
const PEDRA := preload("res://scenes/world/pedra.tscn")
const T := 16
const ESCALA := 0.25

const NAT := "res://assets/tiny_swords/natureza/"
const MUNDO := "res://assets/sprites/tiny/mundo/"
const TEX_NATUREZA := preload("res://assets/sprites/tiny/pedras_slime.png")
const LUZ := preload("res://assets/luz/luz_radial.tres")

## Árvores. [textura, quadro, tamanho do quadro, pe, quadros animados, toco, região do toco,
## pe do toco, desvio_x]
const ARVORES := {
	&"pinheiro1": [NAT + "arvore1.png", 0, Vector2(192, 256), 15, 8, NAT + "toco1.png", Rect2(0, 0, 192, 256), -1, 0.0],
	&"pinheiro2": [NAT + "arvore2.png", 0, Vector2(192, 256), 15, 8, NAT + "toco2.png", Rect2(0, 0, 192, 256), -1, 0.0],
	&"copa1": [NAT + "arvore3.png", 0, Vector2(192, 192), 22, 8, NAT + "toco3.png", Rect2(0, 0, 192, 192), -1, 0.0],
	&"copa2": [NAT + "arvore4.png", 0, Vector2(192, 192), 22, 8, NAT + "toco4.png", Rect2(0, 0, 192, 192), -1, 0.0],
	&"cerejeira": [MUNDO + "arvores.png", 0, Vector2(256, 256), 14, 1, NAT + "toco3.png", Rect2(0, 0, 192, 192), 22, 0.0],
	&"morta": [MUNDO + "arvores.png", 1, Vector2(256, 256), 14, 1, NAT + "toco4.png", Rect2(0, 0, 192, 192), 22, 0.0],
	&"coqueiro1": [MUNDO + "coqueiros.png", 0, Vector2(256, 256), 14, 1, MUNDO + "praia.png", Rect2(5 * 128, 0, 128, 128), 8, 26.0],
	&"coqueiro2": [MUNDO + "coqueiros.png", 1, Vector2(256, 256), 14, 1, MUNDO + "praia.png", Rect2(5 * 128, 0, 128, 128), 8, -8.0],
}

## Decoração. [textura, quadro, tamanho do quadro, pe, jeito, raio da colisão, cor da luz]
## jeito: "alto" (entra na ordem de quem está na frente), "chao" (embaixo de todos),
## "agua" (em cima da água), "arbusto" (animado ao vento).
const PECAS := {
	&"arbusto": ["", 0, Vector2(128, 128), 49, "arbusto", 0.0, null],
	&"pedrinha": [NAT + "pedrinha%d.png", 0, Vector2(64, 64), 14, "chao", 0.0, null],
	&"cogumelo_azul": ["natureza", 3, Vector2(128, 128), 8, "alto", 0.0, Color(0.3, 0.95, 0.9)],
	# Bosque Florido (L36 folha 05)
	&"flores_rosa": [MUNDO + "bosque.png", 0, Vector2(128, 128), 8, "chao", 0.0, null],
	&"flores_amarelas": [MUNDO + "bosque.png", 1, Vector2(128, 128), 8, "chao", 0.0, null],
	&"flores_azuis": [MUNDO + "bosque.png", 2, Vector2(128, 128), 8, "alto", 0.0, null],
	&"frutinhas": [MUNDO + "bosque.png", 3, Vector2(128, 128), 8, "alto", 6.0, null],
	&"tronco": [MUNDO + "bosque.png", 4, Vector2(128, 128), 8, "alto", 7.0, null],
	&"cogumelo_vermelho": [MUNDO + "bosque.png", 5, Vector2(128, 128), 8, "alto", 0.0, null],
	# Praia das Conchas (folha 04)
	&"conchas": [MUNDO + "praia.png", 0, Vector2(128, 128), 8, "chao", 0.0, null],
	&"estrela": [MUNDO + "praia.png", 1, Vector2(128, 128), 8, "chao", 0.0, null],
	&"poca": [MUNDO + "praia.png", 2, Vector2(128, 128), 8, "chao", 0.0, null],
	&"tronco_mar": [MUNDO + "praia.png", 3, Vector2(128, 128), 8, "alto", 6.0, null],
	&"pedras_algas": [MUNDO + "praia.png", 4, Vector2(128, 128), 8, "alto", 7.0, null],
	# Pântano dos Cogumelos (folha 06)
	&"cogumelo_gigante": [MUNDO + "pantano.png", 0, Vector2(128, 128), 8, "alto", 5.0, Color(0.35, 0.95, 0.95)],
	&"cogumelos_roxos": [MUNDO + "pantano.png", 1, Vector2(128, 128), 8, "alto", 0.0, Color(0.8, 0.5, 1.0)],
	&"vitoria_regia": [MUNDO + "pantano.png", 2, Vector2(128, 128), 20, "agua", 0.0, null],
	&"taboa": [MUNDO + "pantano.png", 3, Vector2(128, 128), 8, "alto", 0.0, null],
	&"toco_podre": [MUNDO + "pantano.png", 4, Vector2(128, 128), 8, "alto", 6.0, null],
	&"raiz": [MUNDO + "pantano.png", 5, Vector2(128, 128), 8, "alto", 0.0, null],
	# Colinas e Ruínas (folhas 03 e 07)
	&"rochedo": [MUNDO + "colinas_ruinas.png", 0, Vector2(128, 128), 8, "alto", 10.0, null],
	&"pedras_empilhadas": [MUNDO + "colinas_ruinas.png", 1, Vector2(128, 128), 8, "alto", 5.0, null],
	&"ossada": [MUNDO + "colinas_ruinas.png", 2, Vector2(128, 128), 8, "chao", 0.0, null],
	&"coluna_quebrada": [MUNDO + "colinas_ruinas.png", 3, Vector2(128, 128), 8, "alto", 7.0, null],
	&"muro": [MUNDO + "colinas_ruinas.png", 4, Vector2(128, 128), 8, "alto", 10.0, null],
	&"laje": [MUNDO + "colinas_ruinas.png", 5, Vector2(128, 128), 8, "chao", 0.0, null],
	&"coluna": [MUNDO + "ruinas_altas.png", 0, Vector2(256, 256), 8, "alto", 6.0, null],
	&"estatua": [MUNDO + "ruinas_altas.png", 1, Vector2(256, 256), 8, "alto", 10.0, null],
	&"obelisco": [MUNDO + "ruinas_altas.png", 2, Vector2(256, 256), 8, "alto", 6.0, Color(0.4, 1.0, 0.8)],
}

## O que sai de cada bloco, por região: [o quê, chance por bloco]. "arvore:<tipo>" é árvore,
## "pedra" é pedra (recursos); o resto é decoração (PECAS). As chances se somam na ordem.
const TABELA := {
	Regioes.Id.CLAREIRA: [
		["arvore:pinheiro1", 0.010], ["arvore:pinheiro2", 0.008], ["arvore:copa1", 0.008], ["arvore:copa2", 0.006],
		["pedra", 0.007], ["arbusto", 0.02], ["pedrinha", 0.012], ["flores_amarelas", 0.012],
		["cogumelo_azul", 0.003], ["cogumelo_vermelho", 0.002],
	],
	Regioes.Id.BOSQUE: [
		["arvore:cerejeira", 0.035], ["arvore:copa1", 0.008], ["arvore:copa2", 0.006],
		["pedra", 0.005], ["flores_rosa", 0.05], ["flores_amarelas", 0.03], ["flores_azuis", 0.02],
		["frutinhas", 0.008], ["tronco", 0.004], ["cogumelo_vermelho", 0.008], ["arbusto", 0.015],
	],
	Regioes.Id.PRAIA: [
		["arvore:coqueiro1", 0.009], ["arvore:coqueiro2", 0.009],
		["conchas", 0.03], ["estrela", 0.01], ["poca", 0.005], ["tronco_mar", 0.004],
		["pedras_algas", 0.007], ["pedrinha", 0.008], ["arbusto", 0.004],
	],
	Regioes.Id.PANTANO: [
		["arvore:morta", 0.022], ["arvore:copa2", 0.004],
		["cogumelo_gigante", 0.006], ["cogumelos_roxos", 0.016], ["cogumelo_azul", 0.012],
		["taboa", 0.02], ["pedra", 0.004], ["toco_podre", 0.006], ["raiz", 0.007], ["arbusto", 0.005],
	],
	Regioes.Id.COLINAS: [
		["arvore:pinheiro1", 0.010], ["arvore:pinheiro2", 0.008], ["pedra", 0.055],
		["rochedo", 0.006], ["pedras_empilhadas", 0.005], ["ossada", 0.002], ["pedrinha", 0.03],
		["arbusto", 0.008],
	],
	Regioes.Id.RUINAS: [
		["arvore:copa1", 0.012], ["arvore:copa2", 0.008], ["arvore:cerejeira", 0.004], ["pedra", 0.018],
		["coluna", 0.007], ["estatua", 0.0015], ["obelisco", 0.002], ["coluna_quebrada", 0.007],
		["muro", 0.005], ["arbusto", 0.012], ["flores_azuis", 0.008], ["pedrinha", 0.01],
	],
}
## No piso de pedra das ruínas sai laje; na lama, mais taboas; nas lagoas do pântano,
## vitórias-régias; no mar perto da praia, pedras na água.
const CHANCE_LAJE := 0.05
## Ajuste geral das chances das árvores (as matas mais cheias).
const MAIS_ARVORES := 2.2
const CHANCE_VITORIA := 0.12
const CHANCE_PEDRA_AGUA := 0.02
const CHANCE_NEVOA := 0.008

var w: World
var rng: RandomNumberGenerator
var _texturas := {}
var _arbustos: Array[SpriteFrames] = []
var _pedras_agua: Array[SpriteFrames] = []
var _chao: Node2D  # decoração rente ao chão, embaixo de todos
var _nevoa: Node2D
var _arvores := 0
var _pedras := 0


func _init(mundo: World, gerador_numeros: RandomNumberGenerator) -> void:
	w = mundo
	rng = gerador_numeros


func espalhar() -> void:
	_chao = Node2D.new()
	_chao.name = "DecoracaoChao"
	w.add_child(_chao)
	w.move_child(_chao, w.entidades.get_index())
	_nevoa = Nevoa.new()
	_nevoa.name = "Nevoa"
	_nevoa.z_index = 5
	w.add_child(_nevoa)
	for k in 4:
		var f := SpriteFrames.new()
		f.remove_animation(&"default")
		SpriteSheets.adicionar_tira(f, load(NAT + "arbusto%d.png" % (k + 1)), &"vento", Vector2i(128, 128), 8, 8.0)
		_arbustos.append(f)
		var a := SpriteFrames.new()
		a.remove_animation(&"default")
		SpriteSheets.adicionar_tira(a, load(NAT + "pedra_agua%d.png" % (k + 1)), &"onda", Vector2i(64, 64), 16, 8.0)
		_pedras_agua.append(a)
	var bosque := FastNoiseLite.new()
	bosque.seed = w.semente + 3
	bosque.frequency = 0.07
	var g := w.gerador
	var densidade := w.plantas / 100.0
	for y in w.altura:
		for x in w.largura:
			var cel := Vector2i(x, y)
			var i := y * w.largura + x
			var sorteio := rng.randf()
			var p := Vector2(cel * T) + Vector2(rng.randf_range(2, 14), rng.randf_range(6, 15))
			var regiao := g.regiao[i]
			if g.tipo[i] == World.Chao.AGUA:
				_na_agua(cel, p, sorteio, regiao, densidade)
				continue
			if rng.randf() < CHANCE_NEVOA and regiao == Regioes.Id.PANTANO:
				_por_nevoa(p)
			if g.piso[i] == GeradorIlha.Piso.TRILHA or not _longe_das_passagens(cel):
				continue
			if g.piso[i] == GeradorIlha.Piso.PEDRA and sorteio < CHANCE_LAJE:
				if sorteio < CHANCE_LAJE * densidade:
					_peca(&"laje", p)
				continue
			var o_que := _sortear(TABELA[regiao], sorteio, g.piso[i] == GeradorIlha.Piso.LAMA)
			if o_que == "":
				continue
			var longe_centro := p.distance_to(w.centro)
			if o_que.begins_with("arvore:"):
				var mata := bosque.get_noise_2d(x, y) > -0.1 or regiao != Regioes.Id.CLAREIRA
				if mata and longe_centro > World.RAIO_CLAREIRA and g.distancia[i] < 0.9 and w._livre(p, 26.0):
					_arvore(StringName(o_que.substr(7)), p)
			elif o_que == "pedra":
				if longe_centro > 80.0 and g.distancia[i] < 0.9 and w._livre(p, 24.0):
					_pedra(p)
			elif rng.randf() < densidade and longe_centro > 70.0:
				var peca: Array = PECAS[StringName(o_que)]
				var raio := 30.0 if peca[5] > 0.0 else 12.0
				if w._livre(p, raio):
					_peca(StringName(o_que), p)


func _sortear(tabela: Array, sorteio: float, na_lama: bool) -> String:
	var soma := 0.0
	for e in tabela:
		var peso := float(e[1]) * (2.0 if na_lama and e[0] == "taboa" else 1.0)
		if String(e[0]).begins_with("arvore:"):
			peso *= MAIS_ARVORES
		soma += peso
		if sorteio < soma:
			return String(e[0])
	return ""


func _longe_das_passagens(cel: Vector2i) -> bool:
	for c in [GeradorIlha.PONTE, GeradorIlha.VAU]:
		if absi(cel.x - c.x) <= GeradorIlha.VAU_RAIO + 4 and absi(cel.y - c.y) <= 4:
			return false
	return true


func _na_agua(cel: Vector2i, p: Vector2, sorteio: float, regiao: int, densidade: float) -> void:
	var g := w.gerador
	var i := cel.y * w.largura + cel.x
	var lagoa := regiao == Regioes.Id.PANTANO and g.distancia[i] < 0.95 and not cel in g.celulas_ponte
	if lagoa and sorteio < CHANCE_VITORIA * densidade:
		_peca(&"vitoria_regia", p)
	elif not lagoa and g.distancia[i] < 1.12 and sorteio < CHANCE_PEDRA_AGUA * densidade and _perto_da_terra(cel):
		var a := AnimatedSprite2D.new()
		a.sprite_frames = _pedras_agua[rng.randi() % 4]
		a.play(&"onda")
		a.frame = rng.randi() % 16
		a.scale = Vector2(ESCALA, ESCALA)
		a.position = p
		_chao.add_child(a)


func _perto_da_terra(cel: Vector2i) -> bool:
	for v in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
		if w.gerador.tipo_em(cel + v) != World.Chao.AGUA:
			return true
	return false


func _textura(caminho: String) -> Texture2D:
	if caminho == "natureza":
		return TEX_NATUREZA
	if not _texturas.has(caminho):
		_texturas[caminho] = load(caminho) if ResourceLoader.exists(caminho) else null
	return _texturas[caminho]


func _arvore(tipo: StringName, p: Vector2) -> void:
	var d: Array = ARVORES[tipo]
	var tex := _textura(d[0])
	if tex == null:
		return
	w._ocupar(p)
	_arvores += 1
	if not w.gerar_recursos:
		return
	var a: ResourceNode = ARVORE.instantiate()
	a.name = "Arvore%d" % _arvores
	var quadro: Vector2 = d[2]
	a.textura_inteiro = tex
	a.textura_esgotado = _textura(d[5])
	a.regiao_inteiro = Rect2(Vector2(int(d[1]) * quadro.x, 0), quadro)
	a.regiao_queimado = a.regiao_inteiro
	a.regiao_esgotado = d[6]
	a.pe = d[3]
	a.quadros = d[4]
	a.pe_esgotado = d[7]
	a.desvio_x = d[8]
	a.position = p
	w.entidades.add_child(a)


func _pedra(p: Vector2) -> void:
	w._ocupar(p)
	_pedras += 1
	var nome := "Pedra%d" % _pedras
	w.pedras_pos[nome] = p
	if not w.gerar_recursos:
		return
	var pd: ResourceNode = PEDRA.instantiate()
	pd.name = nome
	pd.position = p
	w.entidades.add_child(pd)


func _peca(nome: StringName, p: Vector2) -> void:
	var d: Array = PECAS[nome]
	var jeito: String = d[4]
	var quadro: Vector2 = d[2]
	w._ocupar(p)
	if jeito == "arbusto":
		var a := AnimatedSprite2D.new()
		a.sprite_frames = _arbustos[rng.randi() % _arbustos.size()]
		a.play(&"vento")
		a.frame = rng.randi() % 8
		a.centered = false
		a.offset = Vector2(-64, -128 + int(d[3]))
		a.scale = Vector2(ESCALA, ESCALA)
		a.position = p
		w.entidades.add_child(a)
		return
	var caminho: String = d[0]
	if nome == &"pedrinha":
		caminho = caminho % (rng.randi() % 4 + 1)
	var tex := _textura(caminho)
	if tex == null:
		return  # a arte ainda não chegou
	var s := Sprite2D.new()
	s.texture = tex
	s.region_enabled = true
	s.region_rect = Rect2(Vector2(int(d[1]) * quadro.x, 0), quadro)
	s.centered = false
	s.offset = Vector2(-quadro.x / 2.0, -quadro.y + int(d[3]))
	s.scale = Vector2(ESCALA, ESCALA)
	s.flip_h = rng.randf() < 0.5 and float(d[5]) == 0.0
	var pai: Node2D = w.entidades if jeito == "alto" else _chao
	if float(d[5]) > 0.0:
		var corpo := StaticBody2D.new()
		corpo.position = p
		var forma := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = float(d[5])
		forma.shape = c
		forma.position = Vector2(0, -3)
		corpo.add_child(forma)
		corpo.add_child(s)
		pai.add_child(corpo)
	else:
		s.position = p
		pai.add_child(s)
	if d[6] != null:
		var luz := PointLight2D.new()
		luz.texture = LUZ
		luz.color = d[6]
		luz.energy = 0.7
		luz.texture_scale = 1.4 if quadro.x <= 128 else 2.0
		luz.position = Vector2(0, -24)
		luz.enabled = false
		luz.add_to_group(&"luzes_noturnas")
		s.add_child(luz)


func _por_nevoa(p: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = _textura(NAT + "nuvem%d.png" % (rng.randi() % 8 + 1))
	s.scale = Vector2(ESCALA, ESCALA)
	s.modulate = Color(0.85, 1.0, 0.95, 0.32)
	s.position = p
	_nevoa.add_child(s)
