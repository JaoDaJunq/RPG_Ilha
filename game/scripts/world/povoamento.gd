class_name Povoamento
extends Node
## Faz nascer os bichos e inimigos de cada região (só no anfitrião; o MultiplayerSpawner copia
## para os outros). Cada região tem a sua tabela de dia e de noite (Regioes.DADOS).
##
## Regras (design/proposta_mundo.md, seção 3):
##   - limite de vivos por região, que cresce com o número de jogadores;
##   - nasce fora da tela de todos os jogadores, e nunca perto da fogueira, de luzes ou de
##     construções (zona segura);
##   - um bicho que morre deixa a vaga fechada por TEMPO_VOLTA segundos (reaparece com o tempo);
##   - à noite entram também as criaturas da noite da região, perto de quem está jogando
##     (somem ao amanhecer, como sempre);
##   - a dificuldade vem do lugar: quem nasce longe do centro tem mais vida e bate mais
##     (World.mult_dificuldade e World.nivel_extra).
##
## Bicho novo (etapa 2): uma entrada em CRIATURAS e uma linha nas tabelas das regiões.

const SLIME := preload("res://scenes/enemies/slime.tscn")
const ATIRADOR := preload("res://scenes/enemies/atirador.tscn")
const ANIMAL := preload("res://scenes/animals/animal.tscn")
const BANDIDO := preload("res://scenes/enemies/bandido.tscn")
const COGUMELO := preload("res://scenes/enemies/cogumelo.tscn")
const MORCEGO := preload("res://scenes/enemies/morcego.tscn")
const ESQUELETO := preload("res://scenes/enemies/esqueleto.tscn")
const GOLEM := preload("res://scenes/enemies/golem.tscn")

## tipo → [cena, espécie (animais e bandidos) ou "", noturno, {propriedade: valor} (opcional)]
const CRIATURAS := {
	"slime": [SLIME, "", false],
	"slime_noite": [SLIME, "", true],
	"slime_fogo": [SLIME, "", false, {elemento = &"fogo"}],
	"slime_gelo": [SLIME, "", false, {elemento = &"gelo"}],
	"slime_veneno": [SLIME, "", false, {elemento = &"veneno"}],
	"slime_veneno_noite": [SLIME, "", true, {elemento = &"veneno"}],
	"atirador": [ATIRADOR, "", false],
	"atirador_noite": [ATIRADOR, "", true],
	"galinha": [ANIMAL, "galinha", false],
	"coelho": [ANIMAL, "coelho", false],
	"javali": [ANIMAL, "javali", false],
	"ovelha": [ANIMAL, "ovelha", false],
	# Etapa 2 (L39)
	"cervo": [ANIMAL, "cervo", false],
	"caranguejo": [ANIMAL, "caranguejo", false],
	"sapo": [ANIMAL, "sapo", false],
	"cabra": [ANIMAL, "cabra", false],
	"bandido_guerreiro": [BANDIDO, "guerreiro", false],
	"bandido_lanceiro": [BANDIDO, "lanceiro", false],
	"bandido_lanceiro_noite": [BANDIDO, "lanceiro", true],
	"cogumelo": [COGUMELO, "", false],
	"morcego_noite": [MORCEGO, "", true],
	"esqueleto": [ESQUELETO, "", false],
	"esqueleto_noite": [ESQUELETO, "", true],
	"golem": [GOLEM, "", false],
}

## A cada quanto tempo tenta fazer nascer (um por região por vez).
const INTERVALO := 2.0
## Uma vaga fica fechada esse tempo depois que o bicho morre.
const TEMPO_VOLTA := 120.0
## Fora da tela: a tela mostra 320 x 180 px do mundo (zoom 4), metade da diagonal ~184 px.
const LONGE_DA_TELA := 240.0
## A criatura da noite nasce entre essas distâncias de um jogador.
const NOITE_PERTO := Vector2(240.0, 520.0)
## Zona segura: a fogueira do acampamento e qualquer construção ou luz.
const RAIO_SEGURO := 200.0

var w: World
var _celulas: Dictionary = {}  # região → Array[Vector2i]
var _vagas_fechadas: Dictionary = {}  # região → Array[float] (segundos que faltam)
var _tempo := 0.0
var _contador := 0
var _rng := RandomNumberGenerator.new()


func _init(mundo: World) -> void:
	w = mundo
	name = "Povoamento"
	_rng.seed = mundo.semente + 77
	for r in Regioes.TODAS:
		_celulas[r] = mundo.celulas_da_regiao(r)
		_vagas_fechadas[r] = []


## Nasceu pelo Povoamento? (o nome tem "_", como "Slime_12"; vale também nos outros
## jogadores, que recebem o nome pela rede). Só esses ficam mais fortes longe do centro.
static func nasceu_aqui(n: Node) -> bool:
	return n.is_in_group(&"povoamento") or String(n.name).contains("_")


## Enche todas as regiões até o limite de dia (ao abrir o mundo).
func encher() -> void:
	for r in Regioes.TODAS:
		var tentativas := 0
		while _vivos(r, false) < Regioes.limite(r, _jogadores().size(), false) and tentativas < 200:
			tentativas += 1
			nascer(r, false)


func _process(delta: float) -> void:
	for r in _vagas_fechadas:
		var lista: Array = _vagas_fechadas[r]
		for k in range(lista.size() - 1, -1, -1):
			lista[k] -= delta
			if lista[k] <= 0.0:
				lista.remove_at(k)
	_tempo += delta
	if _tempo < INTERVALO:
		return
	_tempo = 0.0
	var jogadores := _jogadores().size()
	for r in Regioes.TODAS:
		var dia_ocupado: int = _vivos(r, false) + (_vagas_fechadas[r] as Array).size()
		if dia_ocupado < Regioes.limite(r, jogadores, false):
			nascer(r, false)
		if w.noite and _vivos(r, true) < Regioes.limite(r, jogadores, true) - Regioes.limite(r, jogadores, false):
			nascer(r, true)


func _jogadores() -> Array[Node]:
	return w.get_tree().get_nodes_in_group(&"jogadores")


## Quantos vivos desta região (de dia ou da noite) nasceram por aqui.
func _vivos(r: int, da_noite: bool) -> int:
	var n := 0
	for c in w.get_tree().get_nodes_in_group(&"povoamento"):
		if int(c.get_meta(&"regiao", -1)) == r and bool(c.get_meta(&"da_noite", false)) == da_noite and not c.is_queued_for_deletion():
			n += 1
	return n


## Faz nascer UMA criatura da tabela da região. Retorna quem nasceu (ou null).
func nascer(r: int, da_noite: bool) -> Node2D:
	var tabela: Array = Regioes.dados(r)["noite" if da_noite else "dia"]
	var tipo := _sortear(tabela)
	if tipo == "" or not CRIATURAS.has(tipo):
		return null
	var pos := _lugar(r, da_noite)
	if pos == Vector2.INF:
		return null
	return criar(tipo, pos, r, da_noite)


func criar(tipo: String, pos: Vector2, r: int, da_noite := false) -> Node2D:
	var d: Array = CRIATURAS[tipo]
	var n: Node2D = (d[0] as PackedScene).instantiate()
	_contador += 1
	n.name = "%s_%d" % [tipo.capitalize().replace(" ", ""), _contador]
	if d[1] != "":
		n.set(&"especie", StringName(d[1]))
	if d[2]:
		n.set(&"noturno", true)
	if d.size() > 3:
		for prop in d[3]:
			n.set(prop, d[3][prop])
	n.set_meta(&"tipo", tipo)
	n.position = pos
	n.set_meta(&"regiao", r)
	n.set_meta(&"da_noite", da_noite)
	n.add_to_group(&"povoamento")
	if not da_noite:
		n.tree_exiting.connect(_ao_sair.bind(r))
	w.entidades.add_child(n, true)
	return n


## O bicho do dia morreu (ou saiu): a vaga reabre depois de TEMPO_VOLTA.
func _ao_sair(r: int) -> void:
	if is_inside_tree() and not w.is_queued_for_deletion():
		(_vagas_fechadas[r] as Array).append(TEMPO_VOLTA)


func _sortear(tabela: Array) -> String:
	var total := 0.0
	for e in tabela:
		total += float(e[1])
	var s := _rng.randf() * total
	for e in tabela:
		s -= float(e[1])
		if s <= 0.0:
			return String(e[0])
	return ""


## Um lugar para nascer: na região, em terra, fora da tela de todos e fora da zona segura.
func _lugar(r: int, da_noite: bool) -> Vector2:
	var celulas: Array = _celulas[r]
	if celulas.is_empty():
		return Vector2.INF
	var jogadores := _jogadores()
	for tentativa in 30:
		var p: Vector2
		if da_noite:
			p = w.ponto_perto_de_jogador(jogadores, NOITE_PERTO.x, NOITE_PERTO.y)
			if p == Vector2.INF or w.regiao_em(p) != r:
				continue
		else:
			var cel: Vector2i = celulas[_rng.randi() % celulas.size()]
			p = Vector2(cel * World.T) + Vector2(_rng.randf_range(3, 13), _rng.randf_range(4, 14))
		if pode_nascer_em(p):
			return p
	return Vector2.INF


## Fora da tela de todos os jogadores, em terra firme e longe da zona segura.
func pode_nascer_em(p: Vector2) -> bool:
	if not w.pode_pisar(p) or p.distance_to(w.centro) < RAIO_SEGURO:
		return false
	for j in _jogadores():
		if (j as Node2D).global_position.distance_to(p) < LONGE_DA_TELA:
			return false
	if World.luz_que_protege(w, p) != Vector2.INF:
		return false
	for c in w.get_tree().get_nodes_in_group(&"construcoes"):
		if (c as Node2D).global_position.distance_to(p) < 120.0:
			return false
	return true
