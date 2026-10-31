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
## O arco vai em pé na mão (L23): 4 quadros da corda (repouso e 3 de puxada) e a flecha.
const ARCO := preload("res://assets/sprites/tiny/itens/arco_puxando.png")
const FLECHA := preload("res://assets/sprites/tiny/itens/flecha_deitada.png")
const QUADRO_ARCO := 64

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


func configurar(raca: StringName, classe: StringName) -> void:
	for c in get_children():
		c.queue_free()
	var pasta := PASTA + "%s_%s/" % [raca, classe]
	_vistas.clear()
	for v in ["", "_frente", "_costas"]:
		if not FileAccess.file_exists(pasta + "pecas" + v + ".json"):
			continue
		var jv: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(pasta + "pecas" + v + ".json"))
		var base := {}
		for k in jv:
			base[k] = Vector2(jv[k][0], jv[k][1])
		_vistas[v] = {base = base, cabeca = load(pasta + "cabeca" + v + ".png"), tronco = load(pasta + "tronco" + v + ".png")}
	var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(pasta + "pecas.json"))
	var sombra := _sprite(load(pasta + "sombra.png") if ResourceLoader.exists(pasta + "sombra.png") else null)
	if sombra.texture:
		sombra.position = Vector2(-sombra.texture.get_width() / 2.0, -sombra.texture.get_height() / 2.0 - 1.0)
	# Ordem de desenho: o que fica atrás primeiro.
	for parte in [["mao_tras", "mao"], ["pe_tras", "pe"], ["tronco", "tronco"], ["cabeca", "cabeca"], ["pe_frente", "pe"]]:
		_pecas[parte[0]] = _sprite(load(pasta + parte[1] + ".png"))
		_base[parte[0]] = Vector2(j[parte[0]][0], j[parte[0]][1])
	_item = _sprite(null)
	_flecha = _sprite(FLECHA)
	_flecha.visible = false
	_pecas["mao_frente"] = _sprite(load(pasta + "mao.png"))
	_base["mao_frente"] = Vector2(j["mao_frente"][0], j["mao_frente"][1])
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
	_por("cabeca", corpo + Vector2(0, roundf(respira * 0.5)) if passo == 0.0 else corpo)
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
