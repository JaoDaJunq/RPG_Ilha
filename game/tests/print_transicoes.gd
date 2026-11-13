extends TesteBase
## Prints das emendas entre os chãos (L41; precisa de janela, não roda com --headless).
## Acha sozinho, no mapa do gerador, o lugar com mais emenda de cada tipo (o mesmo lugar
## sempre, porque a ilha é a mesma) e salva evidence/novidades/transicoes_<tipo>_<sufixo>.png.
## Uso (da raiz):  <godot> --path game res://tests/print_transicoes.tscn -- --sufixo=depois
##   --perto: também um print 2x mais perto de cada lugar (_perto).

const TIPOS := ["grama_tons", "grama_areia", "trilha", "lama", "piso", "lagoa", "costa", "clareira"]

var w: World
var g: GeradorIlha


func _ready() -> void:
	var sufixo := "depois"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--sufixo="):
			sufixo = a.get_slice("=", 1)
	w = await criar_mundo(0, false, &"guerreiro", &"humano")
	g = w.gerador
	w.hud.visible = false
	var p := w.jogador
	await esperar(1.0)
	for tipo in TIPOS:
		var cel := GeradorIlha.CENTRO + Vector2i(0, 3) if tipo == "clareira" else _achar(tipo)
		print("transição %s em %s" % [tipo, cel])
		p.global_position = Vector2(cel * World.T) + Vector2(8, 8)
		p.camera.reset_smoothing()
		await esperar(1.0)
		await salvar_print("novidades/transicoes_%s_%s.png" % [tipo, sufixo])
		if "--perto" in OS.get_cmdline_user_args():
			p.camera.zoom *= 2.0
			await esperar(0.4)
			await salvar_print("novidades/transicoes_%s_%s_perto.png" % [tipo, sufixo])
			p.camera.zoom /= 2.0
	terminar()


func _chao(c: Vector2i) -> bool:
	return g.dentro(c) and g.tipo_em(c) != World.Chao.AGUA


func _grama(c: Vector2i) -> bool:
	return _chao(c) and g.tipo_em(c) == World.Chao.GRAMA and g.piso_em(c) == GeradorIlha.Piso.NADA


## Esta célula é emenda do tipo pedido (olhando os 4 vizinhos)?
func _emenda(tipo: String, c: Vector2i) -> bool:
	for v in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var n: Vector2i = c + v
		if not g.dentro(n):
			continue
		match tipo:
			"grama_tons":
				if _grama(c) and _grama(n) and g.regiao_em(c) != g.regiao_em(n):
					return true
			"grama_areia":
				if _grama(c) and _chao(n) and g.tipo_em(n) == World.Chao.AREIA and g.piso_em(n) == GeradorIlha.Piso.NADA:
					return true
			"trilha":
				if g.piso_em(c) == GeradorIlha.Piso.TRILHA and _grama(n):
					return true
			"lama":
				if g.piso_em(c) == GeradorIlha.Piso.LAMA and _grama(n):
					return true
			"piso":
				if g.piso_em(c) == GeradorIlha.Piso.PEDRA and _grama(n):
					return true
			"lagoa":
				if _chao(c) and g.regiao_em(c) == Regioes.Id.PANTANO and g.tipo_em(n) == World.Chao.AGUA and g.distancia[g.indice(n)] < 0.95:
					return true
			"costa":
				if _chao(c) and g.regiao_em(c) == Regioes.Id.BOSQUE and g.tipo_em(n) == World.Chao.AGUA:
					return true
	return false


## O centro (de 3 em 3 blocos) com mais emendas do tipo num raio de 6 blocos.
func _achar(tipo: String) -> Vector2i:
	var marcas := {}
	for y in GeradorIlha.ALTURA:
		for x in GeradorIlha.LARGURA:
			if _emenda(tipo, Vector2i(x, y)):
				marcas[Vector2i(x, y)] = true
	var melhor := GeradorIlha.CENTRO
	var mais := -1
	for y in range(10, GeradorIlha.ALTURA - 10, 3):
		for x in range(14, GeradorIlha.LARGURA - 14, 3):
			var n := 0
			for dy in range(-6, 7):
				for dx in range(-9, 10):
					if marcas.has(Vector2i(x + dx, y + dy)):
						n += 1
			if n > mais:
				mais = n
				melhor = Vector2i(x, y)
	return melhor
