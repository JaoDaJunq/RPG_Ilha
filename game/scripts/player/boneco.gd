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
## Cobertura antiga para aparências salvas ou sem traje completo disponível.
const COBERTURA_BASE := {
	"guerreiro": "elmo_guerreiro",
	"mago": "chapeu_mago",
	"arqueiro": "capuz_arqueiro",
	"ladino": "bandana_ladino",
	"clerigo": "touca_clerigo",
}
## O arco vai em pé na mão (L23): 4 quadros da corda (repouso e 3 de puxada) e a flecha.
const ARCO := preload("res://assets/sprites/tiny/itens/arco_puxando.png")
const FLECHA := preload("res://assets/sprites/tiny/itens/flecha_deitada.png")
const QUADRO_ARCO := 64
## Raças que vestem as roupas de outra (mesmo corpo).
const ROUPA_DE := {"elfo": "humano", "anao": "ogro"}

var animation: StringName = &"parado_direita"
## Item da mão (id), definido pelo Player a cada quadro.
var item: StringName = &""
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
var _flecha: Sprite2D
var _tempo := 0.0
var _golpe := -1.0  # segundos desde o começo do golpe (-1 = sem golpe)
## As três vistas: "" (perfil), "_frente" (andando para baixo), "_costas" (para cima). Cada
## uma tem as texturas e o lugar de cada peça (os pés e as mãos são as mesmas peças).
var _vistas := {}
var _vista := ""


## Aparência = {raca, rosto (0 a 2), pele (0 a 2)}. Se a roupa do corpo for roupa_<classe>
## e existir bonecos/<raca>_<classe>/, usa o personagem completo dessa pasta. A roupa da
## classe traz cabelo/cobertura e traje juntos; rosto e chapéu separados não entram. Sem
## roupa, mantém a roupinha branca da pasta da raça. Raça sem base própria usa a do humano.
func vestir(aparencia: Dictionary, equipado: Dictionary) -> void:
	var raca := String(aparencia.get("raca", &"humano"))
	var pasta := PASTA + raca + "/"
	var corpo := String(equipado.get("corpo", &""))
	if not FileAccess.file_exists(pasta + "base/pecas.json"):
		raca = "humano"  # raça sem arte ainda
		pasta = PASTA + "humano/"
	var classe_completa := _classe_da_roupa(corpo, "")
	var pasta_completa := PASTA + raca + "_" + classe_completa + "/"
	if classe_completa != "" and FileAccess.file_exists(pasta_completa + "pecas.json"):
		_vestir_completo(aparencia, raca, pasta_completa)
		return
	var rosto := pasta + "rosto_%d/" % (int(aparencia.get("rosto", 0)) + 1)
	# Elfo veste as roupas do humano e anão as do ogro (mesmo corpo, L25).
	var doadora: String = ROUPA_DE.get(raca, raca)
	var roupa := PASTA + doadora + "/" + _classe_da_roupa(corpo, "") + "/"
	var cobertura := String(equipado.get("cabeca", &""))
	if cobertura == "" and corpo != "":
		cobertura = COBERTURA_BASE.get(classe_completa, "")
	var chapeu := PASTA + doadora + "/" + _classe_da_roupa(cobertura, "") + "/"
	var vistas := {}
	for v in ["", "_frente", "_costas"]:
		var pos := _ler_pecas(pasta + "base/pecas" + v + ".json")
		if pos.is_empty():
			continue
		var d := {base = pos, cabeca = load(pasta + "base/cabeca" + v + ".png"), tronco = load(pasta + "base/tronco" + v + ".png"), chapeu = null, roupa = null, mascara = null, cabelo = null}
		# Peças separadas (L27): cabeça careca + cabelo + roupa + chapéu, cada um desenhado
		# sozinho em cima do mesmo boneco; o jogo só junta.
		var pp := pasta + "pecas/"
		var pcab := _ler_pecas(pp + "cabelo_%d" % (int(aparencia.get("rosto", 0)) + 1) + v + ".json")
		var pcar := _ler_pecas(pp + "careca" + v + ".json")
		if pcab.size() > 0 and pcar.size() > 0:
			d.cabeca = load(pp + "careca" + v + ".png")
			pos["cabeca"] = pcar["careca"]
			var n := "cabelo_%d" % (int(aparencia.get("rosto", 0)) + 1)
			d.cabelo = load(pp + n + v + ".png")
			pos["cabelo"] = pcab[n]
		var pd := PASTA + doadora + "/pecas/"
		var roupa_p := "roupa_" + _classe_da_roupa(corpo, "")
		var pro := _ler_pecas(pd + roupa_p + v + ".json") if corpo != "" else {}
		if pro.has(roupa_p):
			d.roupa = load(pd + roupa_p + v + ".png")
			pos["roupa"] = pro[roupa_p]
		var chapeu_p := cobertura
		var pch := _ler_pecas(pd + chapeu_p + v + ".json") if chapeu_p != "" else {}
		if pch.has(chapeu_p):
			d.chapeu = load(pd + chapeu_p + v + ".png")
			pos["chapeu"] = pch[chapeu_p]
		var pr := _ler_pecas(rosto + "pecas" + v + ".json") if d.cabelo == null else {}
		if pr.has("cabeca"):
			d.cabeca = load(rosto + "cabeca" + v + ".png")
			pos["cabeca"] = pr["cabeca"]
		# Roupa pelo gabarito (L26): uma camada por cima do corpo e outra por cima da cabeça,
		# desenhadas sobre o próprio boneco base, e a máscara do que se vê da cabeça com o chapéu.
		var gc := _ler_pecas(roupa.trim_suffix("/") + "_g/roupa" + v + ".json") if corpo != "" and d.roupa == null else {}
		if gc.has("corpo"):
			d.roupa = load(roupa.trim_suffix("/") + "_g/roupa_corpo" + v + ".png")
			pos["roupa"] = gc["corpo"]
		var gh := _ler_pecas(chapeu.trim_suffix("/") + "_g/roupa" + v + ".json") if cobertura != "" and d.chapeu == null else {}
		if gh.has("cabeca"):
			d.chapeu = load(chapeu.trim_suffix("/") + "_g/roupa_cabeca" + v + ".png")
			d.mascara = load(chapeu.trim_suffix("/") + "_g/mascara" + v + ".png")
			pos["chapeu"] = gh["cabeca"]
			pos["mascara"] = gh["mascara"]
		var pt := _ler_pecas(roupa + "pecas" + v + ".json") if corpo != "" and d.roupa == null else {}
		if pt.has("tronco"):
			# A roupa começa no pescoço da túnica branca, centralizada nela (a roupa é desenhada
			# em outro montado, então o lugar dela lá não vale aqui).
			var branca: Texture2D = d.tronco
			d.tronco = load(roupa + "tronco" + v + ".png")
			pos["tronco"] = (pos["tronco"] + Vector2((branca.get_width() - (d.tronco as Texture2D).get_width()) / 2.0, 0)).round()
		var pc := _ler_pecas(chapeu + "pecas" + v + ".json") if cobertura != "" and d.chapeu == null else {}
		if pc.has("cabeca"):
			d.chapeu = load(chapeu + "cabeca" + v + ".png")
			# O chapéu acompanha a cabeça: guarda o lugar dele em relação à cabeça base.
			pos["chapeu"] = pc["cabeca"]
		if d.chapeu != null:
			if doadora != raca:
				# Chapéu de outra raça: vai junto com a cabeça (base) desta raça.
				var cab_doadora := _ler_pecas(PASTA + doadora + "/base/pecas" + v + ".json")
				var cab_esta := _ler_pecas(pasta + "base/pecas" + v + ".json")
				if cab_doadora.has("cabeca"):
					var delta: Vector2 = (cab_esta["cabeca"] as Vector2) - (cab_doadora["cabeca"] as Vector2)
					pos["chapeu"] += delta
					if pos.has("mascara"):
						pos["mascara"] += delta
		vistas[v] = d
	var pele := int(aparencia.get("pele", 0))
	for v in vistas:
		vistas[v].cabeca = _tingir(vistas[v].cabeca, pele, StringName(raca))
		if vistas[v].cabelo != null and vistas[v].chapeu != null:
			vistas[v].cabelo = _recortar_cabelo(vistas[v].cabelo, vistas[v].base["cabelo"], vistas[v].chapeu, vistas[v].base["chapeu"])
		elif vistas[v].mascara != null:
			vistas[v].cabeca = _mascarar(vistas[v].cabeca, vistas[v].base["cabeca"], vistas[v].mascara, vistas[v].base["mascara"])
		elif vistas[v].chapeu != null:
			vistas[v].cabeca = _recortar_cabelo(vistas[v].cabeca, vistas[v].base["cabeca"], vistas[v].chapeu, vistas[v].base["chapeu"])
	_montar(vistas, load(pasta + "base/pe.png"), _tingir(load(pasta + "base/mao.png"), pele, StringName(raca)), load(pasta + "base/sombra.png"))


## Veste cabeça, tronco, mãos e pés já desenhados para uma classe completa.
func _vestir_completo(aparencia: Dictionary, raca: String, pasta: String) -> void:
	var vistas := {}
	for v in ["", "_frente", "_costas"]:
		var pos := _ler_pecas(pasta + "pecas" + v + ".json")
		if pos.is_empty():
			continue
		vistas[v] = {base = pos, cabeca = load(pasta + "cabeca" + v + ".png"), tronco = load(pasta + "tronco" + v + ".png"), chapeu = null, roupa = null, mascara = null, cabelo = null}
	var pele := int(aparencia.get("pele", 0))
	for v in vistas:
		vistas[v].cabeca = _tingir(vistas[v].cabeca, pele, StringName(raca))
	_montar(vistas, load(pasta + "pe.png"), _tingir(load(pasta + "mao.png"), pele, StringName(raca)), load(pasta + "sombra.png"))


## Retrato para o HUD: a cabeça de perfil, com o chapéu se tiver.
static func retrato(aparencia: Dictionary, equipado: Dictionary) -> Texture2D:
	var b := Boneco.new()
	b.vestir(aparencia, equipado)
	var d: Dictionary = b._vistas.get("", {})
	var tex: Texture2D = d.get("cabeca")
	if d.get("chapeu") != null:
		var cab: Image = (d.cabeca as Texture2D).get_image()
		var cha: Image = (d.chapeu as Texture2D).get_image()
		var pc: Vector2 = d.base["cabeca"]
		var ph: Vector2 = d.base["chapeu"]
		var r := Rect2i(Vector2i(pc), cab.get_size()).merge(Rect2i(Vector2i(ph), cha.get_size()))
		var img := Image.create(r.size.x, r.size.y, false, Image.FORMAT_RGBA8)
		img.blend_rect(cab, Rect2i(Vector2i.ZERO, cab.get_size()), Vector2i(pc) - r.position)
		img.blend_rect(cha, Rect2i(Vector2i.ZERO, cha.get_size()), Vector2i(ph) - r.position)
		tex = ImageTexture.create_from_image(img)
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
## cada peça), cabeca, tronco, chapeu (ou null)}. Os pés e as mãos são os mesmos nas três.
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
	for parte in [["mao_tras", mao], ["pe_tras", pe], ["tronco", null], ["pe_frente", pe], ["roupa", null], ["cabeca", null], ["cabelo", null], ["chapeu", null]]:
		_pecas[parte[0]] = _sprite(parte[1])
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
	var chapeu := _pecas["chapeu"] as Sprite2D
	chapeu.texture = d.chapeu
	chapeu.visible = d.chapeu != null
	var cabelo := _pecas["cabelo"] as Sprite2D
	cabelo.texture = d.get("cabelo")
	cabelo.visible = d.get("cabelo") != null
	var roupa := _pecas["roupa"] as Sprite2D
	roupa.texture = d.get("roupa")
	roupa.visible = d.get("roupa") != null
	# De costas, o item fica atrás do corpo; nas outras vistas, na frente.
	move_child(_item, 1 if v == "_costas" else get_child_count() - 3)
	move_child(_flecha, get_child_count() - 2)


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
	if _base.has("roupa"):
		_por("roupa", corpo)
	var cabeca := corpo + Vector2(0, roundf(respira * 0.5)) if passo == 0.0 else corpo
	_por("cabeca", cabeca)
	if _base.has("chapeu"):
		_por("chapeu", cabeca)
	if _base.has("cabelo"):
		_por("cabelo", cabeca)
	# De perfil os pés vão para a frente e para trás; de frente e de costas, só sobem e descem.
	var ida := 0.0 if _vista != "" else 4.0
	_por("pe_frente", Vector2(roundf(passo * ida), minf(0.0, roundf(-passo * 3.0))))
	_por("pe_tras", Vector2(roundf(-passo * ida), minf(0.0, roundf(passo * 3.0))))
	var flutua := roundf(sin(_tempo * 2.4 + 1.2) * 1.2)
	_por("mao_tras", corpo + Vector2(roundf(-passo * 3.0), flutua))
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
	_por("mao_frente", mao)
	_por_item(mao, giro)


func _por(nome: String, desvio: Vector2) -> void:
	(_pecas[nome] as Sprite2D).position = _base[nome] + desvio


## O item vai na mão da frente: o ícone é desenhado na diagonal com o cabo embaixo à
## esquerda; o cabo (20% da largura, 80% da altura) fica no meio da mão.
func _por_item(mao: Vector2, giro: float) -> void:
	var dados := ItemData.carregar(item) if ItemData.existe(item) else null
	_item.visible = dados != null
	_flecha.visible = false
	if dados == null:
		return
	var m := _pecas["mao_frente"] as Sprite2D
	var centro_mao: Vector2 = _base["mao_frente"] + mao + m.texture.get_size() / 2.0
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


## Cabelo debaixo do chapéu (L24b): como em muitos jogos, o cabelo que ficaria para fora do
## chapéu, do capuz ou do elmo some. Nas colunas que o chapéu cobre, some o que está ACIMA do
## topo do chapéu; dos lados do chapéu, some o que está acima da borda de baixo da ponta dele
## (a aba ou a gola). O rosto, que fica debaixo ou dentro do chapéu, continua.
static var _recortadas := {}


static func _recortar_cabelo(cab: Texture2D, pos_cab: Vector2, chapeu: Texture2D, pos_chapeu: Vector2) -> Texture2D:
	var chave := "%d|%s|%s|%s" % [cab.get_instance_id(), chapeu.resource_path, pos_cab, pos_chapeu]
	if _recortadas.has(chave):
		return _recortadas[chave]
	var img := cab.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var ch := chapeu.get_image()
	if ch.is_compressed():
		ch.decompress()
	var d := Vector2i(pos_chapeu - pos_cab)  # canto do chapéu na cabeça
	# Topo e base do chapéu em cada coluna dele (-1 = coluna vazia).
	var topos: Array[int] = []
	var bases: Array[int] = []
	for cx in ch.get_width():
		var t := -1
		var b := -1
		for cy in ch.get_height():
			if ch.get_pixel(cx, cy).a > 0.5:
				if t < 0:
					t = cy
				b = cy
		topos.append(t)
		bases.append(b)
	var primeira := 0
	while primeira < bases.size() and bases[primeira] < 0:
		primeira += 1
	if primeira == bases.size():
		return cab
	var ultima := bases.size() - 1
	while bases[ultima] < 0:
		ultima -= 1
	for x in img.get_width():
		var cx := x - d.x
		var limite: int  # linha da cabeça acima da qual o cabelo some
		if cx >= primeira and cx <= ultima:
			if topos[cx] < 0:
				continue
			limite = topos[cx] + d.y
		else:
			limite = bases[primeira if cx < primeira else ultima] + d.y
		for y in clampi(limite, 0, img.get_height()):
			img.set_pixel(x, y, Color(0, 0, 0, 0))
	var tex := ImageTexture.create_from_image(img)
	_recortadas[chave] = tex
	return tex



## Cabeça com chapéu do gabarito (L26): só fica o que aparece na máscara (o contorno da cabeça
## vestida); o resto, como o cabelo que sairia para fora do chapéu, some. Vale para qualquer
## rosto, porque a máscara está nas coordenadas dos pés, iguais para todas as cabeças.
static func _mascarar(cab: Texture2D, pos_cab: Vector2, mascara: Texture2D, pos_mascara: Vector2) -> Texture2D:
	var chave := "m|%d|%s|%s|%s" % [cab.get_instance_id(), mascara.resource_path, pos_cab, pos_mascara]
	if _recortadas.has(chave):
		return _recortadas[chave]
	var img := cab.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var m := mascara.get_image()
	if m.is_compressed():
		m.decompress()
	var d := Vector2i(pos_cab - pos_mascara)
	for y in img.get_height():
		for x in img.get_width():
			var p := Vector2i(x, y) + d
			if p.x < 0 or p.y < 0 or p.x >= m.get_width() or p.y >= m.get_height() or m.get_pixelv(p).a < 0.5:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	var tex := ImageTexture.create_from_image(img)
	_recortadas[chave] = tex
	return tex
