class_name Boneco
extends Node2D
## O personagem por peças, no estilo do Forager (L19): cabeça, tronco, dois pezinhos e duas
## mãozinhas soltas; o item da mão vai na mão da frente. As peças e o lugar de cada uma vêm
## de res://assets/sprites/tiny/bonecos/<raca>_<classe>/ (montar_pecas.gd). A animação é
## feita movendo as peças, sempre em pixels inteiros da arte (o pixel continua nítido):
##   parado   o corpo respira e as mãos flutuam
##   andar    os pés alternam, o corpo balança e as mãos vão e voltam
##   golpe    a mão da frente bate com o item (ele gira)
## O nó tem escala 0,25 (a arte é a do pacote) e a origem nos pés. Olhando para a esquerda, o
## boneco inteiro é espelhado. Mantém `animation` e `play()` como o AnimatedSprite2D de antes.

const PASTA := "res://assets/sprites/tiny/bonecos/"
## Sprite completo (L30): personagens/<raca>_<classe>/{perfil,frente,costas}.png, tiras de 6
## quadros de 128 (parado, respirando, passo A, passo B, golpe preparação, golpe ataque), os
## pés em (64, 120) e a mão da frente marcada em maos.json (game/tools/marcar_maos.gd).
const PASTA_COMPLETO := "res://assets/sprites/tiny/personagens/"
const QUADRO_COMPLETO := 128
const PES_COMPLETO := Vector2(64, 120)
const PASSO_ANDAR := 0.13  # segundos por quadro andando (passo A, parado, passo B, parado)
const TEMPO_RESPIRA := 0.55
const TEMPO_GOLPE := 0.32
## O arco vai em pé na mão (L23): 4 quadros da corda (repouso e 3 de puxada) e a flecha.
const ARCO := preload("res://assets/sprites/tiny/itens/arco_puxando.png")
const FLECHA := preload("res://assets/sprites/tiny/itens/flecha_deitada.png")
## Uma adaga por mão. O ícone do golpe furtivo já contém uma lâmina só.
const ADAGA_MAO := preload("res://assets/sprites/tiny/icones/icone_golpe_furtivo.png")
const QUADRO_ARCO := 64

var animation: StringName = &"parado_direita"
## Item da mão (id), definido pelo Player a cada quadro.
var item: StringName = &""
## A tela de criação usa uma arma menor para ela caber junto do personagem.
var escala_item := 1.0
## Quanto a corda do arco está puxada (0 a 1; -1 sem puxar), definido pelo Player.
var carga := -1.0

## Pose de dor (Player.reagir_ao_golpe): o corpo é empurrado alguns pixels da arte para longe
## do golpe por TEMPO_DOR segundos e volta.
const TEMPO_DOR := 0.18
var _dor := 0.0
var _dor_desvio := Vector2.ZERO

var _base := {}  # peça -> posição de descanso (pixels da arte)
var _pecas := {}  # peça -> Sprite2D
var _item: Sprite2D
var _item_tras: Sprite2D
var _flecha: Sprite2D
var _tempo := 0.0
var _golpe := -1.0  # segundos desde o começo do golpe (-1 = sem golpe)
## As três vistas: "" (perfil), "_frente" (andando para baixo), "_costas" (para cima). Cada
## uma tem as texturas e o lugar de cada peça (os pés e as mãos são as mesmas peças).
var _vistas := {}
var _vista := ""


## Aparência = {raca, classe, pele}. O personagem tem a arte COMPLETA de cada raça e classe
## (decisão de 01/11/2026: sem roupas, cabelos ou chapéus trocáveis), em bonecos/<raca>_<classe>/.
## A classe é a da roupa do corpo equipada (roupa_<classe>) ou, sem ela, a do personagem.
## Raça ou classe sem arte: a roupinha branca da raça (bonecos/<raca>/base/), ou a do humano.
func vestir(aparencia: Dictionary, equipado: Dictionary) -> void:
	var raca := String(aparencia.get("raca", &"humano"))
	if not FileAccess.file_exists(PASTA + raca + "/base/pecas.json"):
		raca = "humano"  # raça sem arte ainda
	var classe := _classe_da_roupa(String(equipado.get("corpo", &"")), String(aparencia.get("classe", "")))
	# Sprite completo (L30): raça e classe desenhadas inteiras em cada quadro. Quem ainda não
	# tem essa arte continua com as peças.
	var completo := PASTA_COMPLETO + raca + "_" + classe + "/"
	if classe != "" and ResourceLoader.exists(completo + "perfil.png") and FileAccess.file_exists(completo + "maos.json"):
		_montar_completo(completo)
		return
	_completo = null
	var pasta := PASTA + raca + "_" + classe + "/"
	if classe == "" or not FileAccess.file_exists(pasta + "pecas.json"):
		pasta = PASTA + raca + "/base/"
	var vistas := {}
	for v in ["", "_frente", "_costas"]:
		var pos := _ler_pecas(pasta + "pecas" + v + ".json")
		if not pos.is_empty():
			vistas[v] = {base = pos, cabeca = load(pasta + "cabeca" + v + ".png"), tronco = load(pasta + "tronco" + v + ".png")}
	var pele := int(aparencia.get("pele", 0))
	for v in vistas:
		vistas[v].cabeca = _tingir(vistas[v].cabeca, pele, StringName(raca))
	_montar(vistas, load(pasta + "pe.png"), _tingir(load(pasta + "mao.png"), pele, StringName(raca)), load(pasta + "sombra.png"))


## Retrato para o HUD: a cabeça de perfil.
static func retrato(aparencia: Dictionary, equipado: Dictionary) -> Texture2D:
	var b := Boneco.new()
	b.vestir(aparencia, equipado)
	if b._completo != null:
		# A cabeça do 1º quadro de perfil (a parte de cima do desenho).
		var tex: Texture2D = b._tiras[""]
		var usado := tex.get_image().get_region(Rect2i(0, 0, QUADRO_COMPLETO, QUADRO_COMPLETO)).get_used_rect()
		var cabeca := AtlasTexture.new()
		cabeca.atlas = tex
		cabeca.region = Rect2(usado.position.x, usado.position.y, usado.size.x, roundf(usado.size.y * 0.55))
		b.free()
		return cabeca
	var d: Dictionary = b._vistas.get("", {})
	var tex: Texture2D = d.get("cabeca")
	b.free()
	return tex


static func _classe_da_roupa(id: String, padrao: String) -> String:
	return id.get_slice("_", 1) if id.contains("_") else padrao


static func _ler_pecas(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {}
	var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	var pos := {}
	for k in j:
		pos[k] = Vector2(j[k][0], j[k][1])
	return pos


## Monta os sprites das peças. `vistas`: "" (perfil), "_frente", "_costas" -> {base (lugar de
## cada peça), cabeca, tronco}. Os pés e as mãos são os mesmos nas três.
func _montar(vistas: Dictionary, pe: Texture2D, mao: Texture2D, sombra_tex: Texture2D) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_pecas.clear()
	_vistas = vistas
	var sombra := _sprite(sombra_tex)
	if sombra_tex:
		sombra.position = Vector2(-sombra_tex.get_width() / 2.0, -sombra_tex.get_height() / 2.0 - 1.0)
	# Ordem de desenho: o que fica atrás primeiro.
	var base: Dictionary = vistas[""].base
	for parte in [["mao_tras", mao], ["pe_tras", pe], ["tronco", null], ["pe_frente", pe], ["cabeca", null]]:
		_pecas[parte[0]] = _sprite(parte[1])
	_item_tras = _sprite(null)
	_item = _sprite(null)
	_flecha = _sprite(FLECHA)
	_flecha.visible = false
	_pecas["mao_frente"] = _sprite(mao)
	_base = base.duplicate()
	_pecas["mao_tras"].self_modulate = Color(0.82, 0.82, 0.86)  # a de trás um pouco na sombra
	_pecas["pe_tras"].self_modulate = Color(0.82, 0.82, 0.86)
	_vista = "?"
	_usar_vista("")
	_posar(0.0, 0.0, 0.0)


## Troca para a vista de perfil, frente ou costas (texturas e lugares das peças).
func _usar_vista(v: String) -> void:
	if not _vistas.has(v):
		v = ""
	if v == _vista:
		return
	_vista = v
	var d: Dictionary = _vistas[v]
	_base = d.base.duplicate()
	(_pecas["cabeca"] as Sprite2D).texture = d.cabeca
	(_pecas["tronco"] as Sprite2D).texture = d.tronco
	# A arma acompanha a mão correspondente; as duas ficam atrás do corpo de perfil/de costas.
	if v == "":
		move_child(_item_tras, 1)
		move_child(_item, get_child_count() - 4)
	elif v == "_costas":
		move_child(_item, 1)
		move_child(_item_tras, 2)
	else:
		move_child(_item_tras, get_child_count() - 4)
		move_child(_item, get_child_count() - 3)
	move_child(_flecha, get_child_count() - 2)


## --- Sprite completo (L30) -------------------------------------------------------------
var _completo: Sprite2D
var _tiras := {}  # vista ("", "_frente", "_costas") -> textura da tira de 6 quadros
var _maos := {}  # vista -> Array de Vector2 (mão da frente em cada quadro)
var _quadro := 0


func _montar_completo(pasta: String) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_pecas.clear()
	_vistas.clear()
	var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(pasta + "maos.json"))
	for par in [["", "perfil"], ["_frente", "frente"], ["_costas", "costas"]]:
		_tiras[par[0]] = load(pasta + par[1] + ".png")
		var pontos: Array[Vector2] = []
		for p in j[par[1]]:
			pontos.append(Vector2(p[0], p[1]))
		_maos[par[0]] = pontos
	_item_tras = _sprite(null)
	_completo = _sprite(_tiras[""])
	_completo.region_enabled = true
	_completo.offset = -PES_COMPLETO
	_item = _sprite(null)
	_flecha = _sprite(FLECHA)
	_flecha.visible = false
	_vista = "?"
	_quadro = 0
	_animar_completo(0.0)


## Escolhe a vista e o quadro pela animação pedida e põe o item na mão marcada.
func _animar_completo(delta: float) -> void:
	_tempo += delta
	var nome := String(animation)
	var v := "_frente" if nome.ends_with("baixo") else ("_costas" if nome.ends_with("cima") else "")
	if v != _vista:
		_vista = v
		_completo.texture = _tiras[v]
		# De costas, a arma fica atrás do corpo; nas outras vistas, na frente.
		move_child(_item, 0 if v == "_costas" else get_child_count() - 2)
	scale.x = -absf(scale.x) if nome.ends_with("esquerda") else absf(scale.x)
	_dor = maxf(0.0, _dor - delta)
	var giro := 0.0
	if _golpe >= 0.0:
		_golpe += delta
		if _golpe > TEMPO_GOLPE:
			_golpe = -1.0
	if _golpe >= 0.0:
		var t := _golpe / TEMPO_GOLPE
		_quadro = 4 if t < 0.45 else 5
		giro = -1.1 if _quadro == 4 else lerpf(0.6, 1.4, clampf((t - 0.45) / 0.3, 0.0, 1.0))
	elif nome.begins_with("andar"):
		_quadro = [2, 0, 3, 0][int(_tempo / PASSO_ANDAR) % 4]
	else:
		_quadro = 1 if int(_tempo / TEMPO_RESPIRA) % 2 == 1 else 0
	if item == &"arco" and carga >= 0.0:
		_quadro = 0
	_completo.region_rect = Rect2(_quadro * QUADRO_COMPLETO, 0, QUADRO_COMPLETO, QUADRO_COMPLETO)
	var desvio := _desvio_dor()
	_completo.position = desvio
	var mao: Vector2 = _maos[_vista][_quadro] - PES_COMPLETO + desvio
	_por_item_em(mao, mao, giro)


## Quadro mostrado agora (0 a 5) no sprite completo; -1 com o boneco por peças. Para os testes.
func quadro_atual() -> int:
	return _quadro if _completo != null else -1


## O personagem apanhou: `dir` é para onde o golpe empurra (mundo). Encolhe o corpo para longe dele.
func dor(dir: Vector2) -> void:
	_dor = TEMPO_DOR
	_dor_desvio = Vector2(roundf(dir.x * 3.0) * signf(scale.x), roundf(dir.y * 2.0))


## Metade do tempo no desvio inteiro, o resto na metade (sempre em pixels da arte).
func _desvio_dor() -> Vector2:
	if _dor <= 0.0:
		return Vector2.ZERO
	return (_dor_desvio * (1.0 if _dor > TEMPO_DOR * 0.5 else 0.5)).round()


func play(nome: StringName = &"") -> void:
	if nome == &"" or nome == animation:
		return
	if String(nome).begins_with("golpe") and not String(animation).begins_with("golpe"):
		_golpe = 0.0
	animation = nome


func _sprite(tex: Texture2D) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	add_child(s)
	return s


func _process(delta: float) -> void:
	if _completo != null:
		_animar_completo(delta)
		return
	if _pecas.is_empty():
		return
	_tempo += delta
	var nome := String(animation)
	_usar_vista("_frente" if nome.ends_with("baixo") else ("_costas" if nome.ends_with("cima") else ""))
	scale.x = -absf(scale.x) if nome.ends_with("esquerda") else absf(scale.x)
	var andando := String(animation).begins_with("andar")
	var passo := sin(_tempo * 11.0) if andando else 0.0
	var respira := sin(_tempo * 2.4)
	_dor = maxf(0.0, _dor - delta)
	if _golpe >= 0.0:
		_golpe += delta
		if _golpe > 0.32:
			_golpe = -1.0
	_posar(passo, respira, _golpe)


## Põe cada peça no lugar, com os desvios da animação (arredondados em pixels da arte).
func _posar(passo: float, respira: float, golpe: float) -> void:
	var corpo := Vector2(0, roundf(-absf(passo) * 2.0) if passo != 0.0 else roundf(respira * 0.6 - 0.4)) + _desvio_dor()
	_por("tronco", corpo)
	var cabeca := corpo + Vector2(0, roundf(respira * 0.5)) if passo == 0.0 else corpo
	_por("cabeca", cabeca)
	# De perfil os pés vão para a frente e para trás; de frente e de costas, só sobem e descem.
	var ida := 0.0 if _vista != "" else 4.0
	_por("pe_frente", Vector2(roundf(passo * ida), minf(0.0, roundf(-passo * 3.0))))
	_por("pe_tras", Vector2(roundf(-passo * ida), minf(0.0, roundf(passo * 3.0))))
	var flutua := roundf(sin(_tempo * 2.4 + 1.2) * 1.2)
	var mao_tras := corpo + Vector2(roundf(-passo * 3.0), flutua)
	var mao := corpo + Vector2(roundf(passo * 3.0), -flutua)
	var giro := 0.0
	if golpe >= 0.0:
		# Golpe: a mão sobe para trás e desce batendo à frente.
		var t := golpe / 0.32
		var arco := sin(t * PI)
		mao += Vector2(roundf(lerpf(-4.0, 10.0, t)), roundf(-arco * 8.0 + t * 6.0))
		giro = lerpf(-1.1, 1.4, ease(t, 0.6))
	if item == &"arco" and carga >= 0.0 and _vista == "":
		# Puxando o arco: a mão da frente sobe até o ombro e estica para a frente.
		mao = corpo + Vector2(6, -14)
		giro = 0.0
	_por("mao_tras", mao_tras)
	_por("mao_frente", mao)
	_por_item(mao, mao_tras, giro)


func _por(nome: String, desvio: Vector2) -> void:
	(_pecas[nome] as Sprite2D).position = _base[nome] + desvio


## O item vai na mão da frente: o ícone é desenhado na diagonal com o cabo embaixo à
## esquerda; o cabo (20% da largura, 80% da altura) fica no meio da mão.
func _por_item(mao: Vector2, mao_tras: Vector2, giro: float) -> void:
	var m := _pecas["mao_frente"] as Sprite2D
	var centro_mao: Vector2 = _base["mao_frente"] + mao + m.texture.get_size() / 2.0
	var mt := _pecas["mao_tras"] as Sprite2D
	var centro_mao_tras: Vector2 = _base["mao_tras"] + mao_tras + mt.texture.get_size() / 2.0
	_por_item_em(centro_mao, centro_mao_tras, giro)


## O item com o meio da mão da frente (e da de trás, para a 2ª adaga) já calculado.
func _por_item_em(centro_mao: Vector2, centro_mao_tras: Vector2, giro: float) -> void:
	var dados := ItemData.carregar(item) if ItemData.existe(item) else null
	_item.visible = dados != null
	_item_tras.visible = item == &"adagas" and dados != null
	_flecha.visible = false
	if dados == null:
		return
	_item.scale = Vector2.ONE * escala_item
	_item_tras.scale = Vector2.ONE * escala_item
	_flecha.scale = Vector2.ONE * escala_item
	if item == &"adagas":
		_item.texture = ADAGA_MAO
		_item.region_enabled = false
		var tam_adaga := ADAGA_MAO.get_size()
		_item.offset = -Vector2(tam_adaga.x * 0.2, tam_adaga.y * 0.8).round()
		_item.position = centro_mao
		_item.rotation = giro
		_item_tras.texture = ADAGA_MAO
		_item_tras.region_enabled = false
		_item_tras.flip_h = true
		_item_tras.offset = -Vector2(tam_adaga.x * 0.8, tam_adaga.y * 0.8).round()
		_item_tras.position = centro_mao_tras
		_item_tras.rotation = -giro
		return
	if item == &"arco":
		_por_arco(centro_mao, giro)
		return
	_item.region_enabled = false
	if _item.texture != dados.icone:
		_item.texture = dados.icone
	var tam := dados.icone.get_size()
	_item.offset = -Vector2(tam.x * 0.2, tam.y * 0.8).round()
	_item.position = centro_mao
	_item.rotation = giro


## O arco fica em pé na mão da frente (barriga para a frente, corda para trás), com a
## empunhadura (lado da barriga, meia altura) no meio da mão. Puxando (carga de 0 a 1), a
## corda vai para trás em 3 quadros, a flecha aparece encaixada nela e a mão de trás segura
## a corda. De frente e de costas, só o arco.
func _por_arco(centro_mao: Vector2, giro: float) -> void:
	var q := 0 if carga < 0.0 else (1 if carga < 0.34 else (2 if carga < 0.67 else 3))
	var caixa := _caixa(ARCO, q)
	_item.texture = ARCO
	_item.region_enabled = true
	_item.region_rect = Rect2(q * QUADRO_ARCO, 0, QUADRO_ARCO, QUADRO_ARCO)
	var pega := Vector2(caixa.end.x - 3, caixa.position.y + caixa.size.y / 2.0).round()
	_item.offset = -pega
	_item.position = centro_mao
	_item.rotation = giro * 0.4
	if carga < 0.0 or _vista != "":
		return
	var corda := centro_mao + Vector2(caixa.position.x + 1, pega.y) - pega
	var f := _caixa(FLECHA, 0)
	_flecha.visible = true
	_flecha.offset = -Vector2(f.position.x, f.position.y + f.size.y / 2.0).round()
	_flecha.position = corda
	if _completo != null:
		return  # a mão de trás é do desenho
	var mt := _pecas["mao_tras"] as Sprite2D
	mt.position = (corda - mt.texture.get_size() / 2.0).round()


## Caixa do desenho (sem o transparente) do quadro `q` de uma tira de quadros de 64.
static var _caixas := {}


static func _caixa(tex: Texture2D, q: int) -> Rect2i:
	var chave := "%s|%d" % [tex.resource_path, q]
	if not _caixas.has(chave):
		var img := tex.get_image()
		_caixas[chave] = img.get_region(Rect2i(q * QUADRO_ARCO, 0, QUADRO_ARCO, img.get_height())).get_used_rect()
	return _caixas[chave]


## Cores de pele (L24): todo pixel de pele (as cores de pele da arte da raça) vira um de três
## tons fixos, claro, base ou sombra, pela luz dele. Assim a pele fica lisa (a conversão para
## pixel art deixava manchas de várias cores de pele) e cada tom de pele é só outra trinca.
## A cópia é feita uma vez por textura e tom (pixel a pixel, sem shader).
const PELE := {
	&"humano": [Color("f4d296"), Color("f8d4a6"), Color("ffbc88"), Color("f8cb93"), Color("f4a47b"), Color("f2e7a0"), Color("ea9461"), Color("db9c68")],
	&"ogro": [Color("a1b74c"), Color("9acc50"), Color("7da147"), Color("6e7e53"), Color("91bc4c"), Color("699157"), Color("c7cc67"), Color("49655c")],
	&"elfo": [Color("f4d296"), Color("f8d4a6"), Color("ffbc88"), Color("f8cb93"), Color("f4a47b"), Color("f2e7a0"), Color("ea9461"), Color("db9c68")],
	&"anao": [Color("f4d296"), Color("f8d4a6"), Color("ffbc88"), Color("f8cb93"), Color("f4a47b"), Color("f2e7a0"), Color("ea9461"), Color("db9c68")],
}
## Luz acima da qual é "claro" e abaixo da qual é "sombra".
const LIMITES_PELE := {&"humano": [0.87, 0.80], &"ogro": [0.74, 0.62], &"elfo": [0.87, 0.80], &"anao": [0.84, 0.70]}
## [claro, base, sombra] de cada tom.
const TONS_PELE := {
	&"humano": [[Color("fadcb2"), Color("f2c391"), Color("d99a68")], [Color("dcaa7c"), Color("c18758"), Color("9b6340")], [Color("9e6c4c"), Color("7c4e35"), Color("5b3525")]],
	&"ogro": [[Color("b8cc5c"), Color("9db64b"), Color("76943e")], [Color("c8b45c"), Color("a99044"), Color("7f6b31")], [Color("a3b79d"), Color("829a84"), Color("617765")]],
	&"elfo": [[Color("fde6c8"), Color("f5d3b0"), Color("dcae8a")], [Color("e3c09d"), Color("c99f7c"), Color("a37a5c")], [Color("a9846c"), Color("86634f"), Color("634636")]],
	&"anao": [[Color("f8cfa0"), Color("eaa877"), Color("c27c50")], [Color("d6a072"), Color("b57f52"), Color("8c5a38")], [Color("9e6c4c"), Color("7c4e35"), Color("5b3525")]],
}
static var _tingidas := {}


static func _tingir(tex: Texture2D, tom: int, raca: StringName) -> Texture2D:
	if tex == null:
		return tex
	var chave := "%s|%d|%s" % [tex.resource_path, tom, raca]
	if not _tingidas.has(chave):
		var img := tex.get_image()
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		var tons: Array = TONS_PELE.get(raca, TONS_PELE[&"humano"])
		var trinca: Array = tons[clampi(tom, 0, tons.size() - 1)]
		var limites: Array = LIMITES_PELE.get(raca, LIMITES_PELE[&"humano"])
		var pele: Array = PELE.get(raca, PELE[&"humano"])
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.0 and _eh_pele(c, pele):
					var luz := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
					var novo: Color = trinca[0] if luz > limites[0] else (trinca[1] if luz > limites[1] else trinca[2])
					img.set_pixel(x, y, Color(novo, c.a))
		_tingidas[chave] = ImageTexture.create_from_image(img)
	return _tingidas[chave]


static func _eh_pele(c: Color, pele: Array) -> bool:
	# Também os tons claros e quentes que a conversão para pixel art deixa na beira da pele.
	var luz := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
	if pele == PELE[&"humano"] and luz > 0.72 and c.r >= c.g and c.g >= c.b and c.r - c.b > 0.12:
		return true
	for p: Color in pele:
		if Vector3(c.r - p.r, c.g - p.g, c.b - p.b).length() < 0.05:
			return true
	return false



