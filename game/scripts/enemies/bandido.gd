class_name Bandido
extends Criatura
## Bandidos do Tiny Swords (Black Units), a turma do arqueiro inimigo (Atirador):
##   guerreiro  corpo a corpo com a espada; quando apanha, às vezes ergue a guarda (por 1,2 s
##              o golpe físico tira só 30%: espere ou use magia);
##   lanceiro   fica a meia distância e AVANÇA: prepara a lança (o aviso), dispara em linha
##              reta e acerta o primeiro que estiver no caminho; depois fica parado, exposto.

const PASTA := "res://assets/tiny_swords/unidades/preto/"
const CHANCE_GUARDA := 0.35
const TEMPO_GUARDA := 1.2
const DEFESA_GUARDA := 0.3
## Lanceiro: distância boa e a investida.
const LANCA_PERTO := 34.0
const LANCA_LONGE := 80.0
const TEMPO_MIRA_LANCA := 0.55
const TEMPO_INVESTIDA := 0.38
const VEL_INVESTIDA := 5.5  # vezes a velocidade

var _guarda := 0.0
var _dir_investida := Vector2.ZERO
var _acertou_investida := false


func _configurar() -> void:
	if especie == &"":
		especie = &"guerreiro"
	if especie == &"lanceiro":
		nome = "Bandido lanceiro"
		vida_base = 12.0
		velocidade = 27.0
		dano = 14.0
		raio_visao = 130.0
		nivel = 3
		xp = 22
		saque = [[&"couro", 1, 1], [&"minerio_ferro", 1, 1, 0.35], [&"corda", 1, 1, 0.3], [BauTrancado.CHAVE, 1, 1, BauTrancado.CHANCE_CHAVE]]
	else:
		nome = "Bandido guerreiro"
		vida_base = 14.0
		velocidade = 29.0
		dano = 12.0
		raio_visao = 120.0
		nivel = 3
		xp = 20
		saque = [[&"couro", 0, 1], [&"carvao", 1, 2], [&"barra_cobre", 1, 1, 0.3], [BauTrancado.CHAVE, 1, 1, BauTrancado.CHANCE_CHAVE]]


func _montar_animacoes(f: SpriteFrames) -> void:
	if especie == &"lanceiro":
		var t := Vector2i(320, 320)
		Criatura.anim(f, &"parado", load(PASTA + "lanceiro_parado.png"), t, range(12), 10.0)
		Criatura.anim(f, &"andar", load(PASTA + "lanceiro_correndo.png"), t, range(6), 10.0)
		Criatura.anim(f, &"preparo", load(PASTA + "lanceiro_ataque.png"), t, [0], 1.0)
		Criatura.anim(f, &"ataque", load(PASTA + "lanceiro_ataque.png"), t, [1, 2, 2], 10.0, false)
	else:
		var t := Vector2i(192, 192)
		Criatura.anim(f, &"parado", load(PASTA + "guerreiro_parado.png"), t, range(8), 10.0)
		Criatura.anim(f, &"andar", load(PASTA + "guerreiro_correndo.png"), t, range(6), 10.0)
		Criatura.anim(f, &"preparo", load(PASTA + "guerreiro_ataque.png"), t, [0, 1], 4.0, false)
		Criatura.anim(f, &"ataque", load(PASTA + "guerreiro_ataque.png"), t, [2, 3], 10.0, false)
		Criatura.anim(f, &"defesa", load(PASTA + "guerreiro_defesa.png"), t, range(6), 10.0)


func _pensar(delta: float) -> Vector2:
	_guarda = maxf(0.0, _guarda - delta)
	if especie == &"lanceiro":
		return _pensar_lanceiro(delta)
	if _guarda > 0.0 and _golpe == Golpe.LIVRE:
		animacao = &"defesa"
		if _alvo:
			_olhar_para(_alvo.global_position)
		return Vector2.ZERO
	return _corpo_a_corpo(delta, 16.0, 0.45, 1.1)


func defendendo() -> bool:
	return _guarda > 0.0


func _ajustar_dano(q: float, tipo: StringName, _origem: Node) -> float:
	if especie != &"guerreiro" or tipo != &"fisico":
		return q
	if _guarda > 0.0:
		World.efeito_todos(self, &"escudo", global_position + Vector2(0, -8))
		return q * DEFESA_GUARDA
	if _golpe == Golpe.LIVRE and randf() < CHANCE_GUARDA:
		_guarda = TEMPO_GUARDA  # ergue a guarda para os próximos golpes
	return q


# --- Lanceiro -------------------------------------------------------------------------

func _pensar_lanceiro(delta: float) -> Vector2:
	_tempo_golpe += delta
	match _golpe:
		Golpe.PREPARANDO:
			animacao = &"preparo"
			if _alvo:
				_dir_investida = (_alvo.global_position - global_position).normalized()
				_olhar_para(_alvo.global_position)
			if _tempo_golpe >= TEMPO_MIRA_LANCA:
				_mudar_golpe(Golpe.BATENDO)
				_acertou_investida = false
				_tocar_ataque.rpc()
			return Vector2.ZERO
		Golpe.BATENDO:
			animacao = &"ataque"
			if not _acertou_investida:
				for p in jogadores_em_volta(global_position + _dir_investida * 10.0, 14.0):
					_acertou_investida = true
					golpear(p, dano)
					break
			if _tempo_golpe >= TEMPO_INVESTIDA:
				_mudar_golpe(Golpe.RECUPERANDO)
				_recarga = 1.6
			return _dir_investida * VEL_INVESTIDA
		Golpe.RECUPERANDO:
			animacao = &"parado"
			if _tempo_golpe >= 0.7:  # parado depois da investida: a hora de bater nele
				_mudar_golpe(Golpe.LIVRE)
			return Vector2.ZERO
	if _alvo == null:
		return _passear(delta)
	var para := _alvo.global_position - global_position
	var d := para.length()
	_olhar_para(_alvo.global_position)
	if _recarga <= 0.0 and d < LANCA_LONGE and efeitos.pode_atacar():
		_mudar_golpe(Golpe.PREPARANDO)
		return Vector2.ZERO
	if d < LANCA_PERTO:
		return _andar(-para / d)
	if d > LANCA_LONGE * 0.8:
		return _andar(para / d)
	animacao = &"parado"
	return Vector2.ZERO
