class_name Conjuracao
extends Node
## Conjuração (design/conjuracao.md): o jogador SEGURA a tecla enquanto o feitiço se forma
## (ou a corda do arco é puxada) e SOLTA quando o anel fica verde. Um sistema só, para as
## magias e para o arco (o antigo modo CARREGAR virou "conjuração + carga extra").
##
##   - Soltar antes do verde: cancela, sem gastar mana nem entrar em recarga.
##   - Enquanto conjura, anda mais devagar (HabilidadeData.velocidade_conjurando).
##   - Apanhar não cancela: cada golpe atrasa ATRASO_GOLPE s (no máximo ATRASO_MAXIMO).
##   - Dash ou cair cancela.
##
## Fica como filho do Player com o nome "Conjuracao" (o Player cria). Rede: o DONO conta o
## tempo dele (para o anel ficar liso); o ANFITRIÃO conta o próprio tempo, desde o pedido de
## começar, e só deixa a habilidade sair depois dele (um "soltar" adiantado até FOLGA_MS
## espera no anfitrião; mais que isso é recusado). O anfitrião avisa todos para mostrar o anel.

## Intelecto (magias) e Agilidade (arco): cada ponto acima de 5 tira 3% do tempo, até 40%.
const PONTO_NEUTRO := 5
const REDUCAO_POR_PONTO := 0.03
const REDUCAO_MAXIMA := 0.40
## O anel fica amarelo nos últimos 25% do tempo.
const AMARELO_A_PARTIR := 0.75
## Apanhar no meio: atrasa 0,15 s por golpe, no máximo 0,45 s por conjuração.
const ATRASO_GOLPE := 0.15
const ATRASO_MAXIMO := 0.45
## O "soltar" que chega ao anfitrião até 0,2 s antes da hora espera até a hora (rede lenta
## ou o atraso do golpe ainda a caminho); mais adiantado que isso, é recusado.
const FOLGA_MS := 200
## Carga extra (modo CARREGAR): a carga também chega se o cliente disser um pouco mais que o
## relógio do anfitrião (atraso da rede), mas não muito.
const FOLGA_CARGA := 0.15

var p: Player

# --- Dono (quem segura a tecla) ---
var hab: HabilidadeData = null  ## a habilidade sendo conjurada (nulo = nenhuma)
var indice := -1  ## a tecla (0 a 3)
var _inicio_ms := 0
var _total := 0.0  # segundos até ficar pronta
var _cheia := 0.0  # segundos até a carga encher (modo CARREGAR)
var _avisou_pronta := false
var _avisou_cheia := false

# --- Anfitrião ---
var _host_id: StringName = &""
var _host_inicio_ms := 0
var _host_atraso := 0.0

# --- O que os outros jogadores veem (o anfitrião manda) ---
var _visto_ativo := false
var _visto_inicio_ms := 0
var _visto_total := 0.0
var _visto_cheia := 0.0

var anel: AnelConjuracao


func _ready() -> void:
	p = get_parent() as Player
	anel = AnelConjuracao.new()
	anel.name = "AnelConjuracao"
	p.add_child.call_deferred(anel)


# --- Fórmulas (iguais em todas as máquinas) ------------------------------------------

## Se a habilidade é segurada (tem conjuração ou carga).
static func conjura(h: HabilidadeData) -> bool:
	return h != null and (h.conjuracao > 0.0 or h.modo == HabilidadeData.Modo.CARREGAR)


## Fração do tempo que o atributo tira (0 a 0,4).
static func reducao(ficha: Ficha, atributo: StringName) -> float:
	if ficha == null or atributo == &"":
		return 0.0
	return clampf((ficha.valor(atributo) - PONTO_NEUTRO) * REDUCAO_POR_PONTO, 0.0, REDUCAO_MAXIMA)


## Segundos segurando até poder soltar, com o atributo (e Mão leve, no arco).
static func tempo(quem: Player, h: HabilidadeData) -> float:
	if h == null or h.conjuracao <= 0.0:
		return 0.0
	var t := h.conjuracao * (1.0 - reducao(quem.ficha if quem else null, h.atributo_conjuracao))
	if quem and h.atributo_conjuracao == &"agilidade" and quem.tem(&"mao_leve"):
		t /= Passivas.MAO_LEVE_CARGA
	return t


## Modo CARREGAR: segundos segurando até a carga encher (a carga cheia antiga, com o atributo).
static func tempo_carga_cheia(quem: Player, h: HabilidadeData) -> float:
	if h == null or h.modo != HabilidadeData.Modo.CARREGAR:
		return 0.0
	var cheia := Passivas.carga_maxima(quem) * (1.0 - reducao(quem.ficha, h.atributo_conjuracao))
	return maxf(cheia, tempo(quem, h) + 0.1)


## Carga 0 a 1 depois de `segurou` segundos (0 até ficar pronta; enche até a carga cheia).
static func carga_de(quem: Player, h: HabilidadeData, segurou: float) -> float:
	if h == null or h.modo != HabilidadeData.Modo.CARREGAR:
		return 0.0
	var t := tempo(quem, h)
	return clampf((segurou - t) / maxf(tempo_carga_cheia(quem, h) - t, 0.01), 0.0, 1.0)


# --- Dono -------------------------------------------------------------------------

func ativa() -> bool:
	return hab != null


func comecar(i: int, h: HabilidadeData) -> void:
	hab = h
	indice = i
	_inicio_ms = Time.get_ticks_msec()
	_total = tempo(p, h)
	_cheia = tempo_carga_cheia(p, h)
	_avisou_pronta = _total <= 0.0
	_avisou_cheia = false
	_pedir_comecar.rpc_id(1, h.id)


func decorrido() -> float:
	return maxf(0.0, (Time.get_ticks_msec() - _inicio_ms) / 1000.0) if hab else 0.0


## 0 a 1 do tempo de conjuração (1 = pronta).
func progresso() -> float:
	if hab == null:
		return -1.0
	return 1.0 if _total <= 0.0 else clampf(decorrido() / _total, 0.0, 1.0)


func pronta() -> bool:
	return hab != null and decorrido() >= _total


## Carga extra (modo CARREGAR): 0 a 1; -1 se não está segurando uma habilidade de carga.
func carga() -> float:
	if hab == null or hab.modo != HabilidadeData.Modo.CARREGAR:
		return -1.0
	return carga_de(p, hab, decorrido())


## Quanto a corda está puxada (0 a 1, até a carga cheia): o boneco desenha o arco por isso.
func puxada() -> float:
	if hab == null:
		return -1.0
	var fim := _cheia if _cheia > 0.0 else _total
	return 1.0 if fim <= 0.0 else clampf(decorrido() / fim, 0.0, 1.0)


## Velocidade de andar (multiplicador) enquanto conjura.
func velocidade() -> float:
	return hab.velocidade_conjurando if hab else 1.0


## Soltou antes da hora, deu dash ou caiu: para, sem gastar nada.
func cancelar() -> void:
	if hab == null:
		return
	hab = null
	indice = -1
	_pedir_cancelar.rpc_id(1)


## Soltou na hora: para de conjurar aqui (o anfitrião para quando receber o pedido).
func terminar() -> void:
	hab = null
	indice = -1


@rpc("any_peer", "reliable")
func _atrasar(segundos: float) -> void:
	if not Net.veio_do_anfitriao():
		return
	if hab:
		_inicio_ms += int(segundos * 1000.0)
		if not pronta():
			_avisou_pronta = false


## O anfitrião recusou o lançamento: a recarga que o dono já contou volta a zero.
@rpc("any_peer", "reliable")
func _recusada(hab_id: StringName) -> void:
	if Net.veio_do_anfitriao():
		p._recargas[hab_id] = 0.0


# --- Anfitrião --------------------------------------------------------------------

@rpc("any_peer", "call_local", "reliable")
func _pedir_comecar(hab_id: StringName) -> void:
	if not multiplayer.is_server() or not p._pedido_do_dono() or p.caido:
		return
	var h := _hab_nas_teclas(hab_id)
	if h == null:
		return
	_host_id = hab_id
	_host_inicio_ms = Time.get_ticks_msec()
	_host_atraso = 0.0
	_anel_sync.rpc(true, tempo(p, h), tempo_carga_cheia(p, h))


@rpc("any_peer", "call_local", "reliable")
func _pedir_cancelar() -> void:
	if not multiplayer.is_server() or not p._pedido_do_dono():
		return
	terminar_no_anfitriao()


## O anfitrião recebeu o "soltar" de `h`: -1 = recusa (cedo demais ou sem conjurar); 0 = sai
## agora; mais que 0 = sai depois desses segundos. `atalho`: o atalho dos testes
## (Player.usar_habilidade_por_id), que só vale para o jogador do próprio anfitrião.
func liberar_no_anfitriao(h: HabilidadeData, atalho: bool) -> float:
	if not conjura(h):
		return 0.0
	if atalho and p.eh_local():
		return 0.0
	if _host_id != h.id:
		return -1.0
	var falta := _host_inicio_ms + int((tempo(p, h) + _host_atraso) * 1000.0) - Time.get_ticks_msec()
	if falta <= 0:
		return 0.0
	return falta / 1000.0 if falta <= FOLGA_MS else -1.0


## Carga pelo relógio do anfitrião (daqui a `espera` segundos), com uma folga para a rede.
func carga_no_anfitriao(h: HabilidadeData, carga_cliente: float, espera: float) -> float:
	var segurou := (Time.get_ticks_msec() - _host_inicio_ms) / 1000.0 + espera - _host_atraso
	return clampf(minf(carga_cliente, carga_de(p, h, segurou) + FOLGA_CARGA), 0.0, 1.0)


func terminar_no_anfitriao() -> void:
	if _host_id == &"":
		return
	_host_id = &""
	_anel_sync.rpc(false, 0.0, 0.0)


func recusar_no_anfitriao(h: HabilidadeData) -> void:
	terminar_no_anfitriao()
	if p.eh_local():
		_recusada(h.id)
	else:
		_recusada.rpc_id(p.id_rede(), h.id)


## Só o anfitrião chama (Player.reagir_ao_golpe): apanhar atrasa um pouco, sem cancelar.
func apanhou() -> void:
	if _host_id == &"" or _host_atraso >= ATRASO_MAXIMO - 0.001:
		return
	var s := minf(ATRASO_GOLPE, ATRASO_MAXIMO - _host_atraso)
	_host_atraso += s
	if p.eh_local():
		_atrasar(s)
	else:
		_atrasar.rpc_id(p.id_rede(), s)
	_anel_atraso.rpc(s)


func _hab_nas_teclas(hab_id: StringName) -> HabilidadeData:
	for h in p.habilidades():
		if h.id == hab_id:
			return h
	return null


# --- Anel (todas as máquinas) ---------------------------------------------------------

@rpc("any_peer", "call_local", "reliable")
func _anel_sync(ativo: bool, total: float, cheia: float) -> void:
	if not Net.veio_do_anfitriao():
		return
	_visto_ativo = ativo
	_visto_inicio_ms = Time.get_ticks_msec()
	_visto_total = total
	_visto_cheia = cheia


@rpc("any_peer", "call_local", "reliable")
func _anel_atraso(segundos: float) -> void:
	if Net.veio_do_anfitriao():
		_visto_inicio_ms += int(segundos * 1000.0)


func _process(_delta: float) -> void:
	if anel == null or not is_instance_valid(anel):
		return
	if p.eh_local():
		if hab == null:
			anel.esconder()
			return
		var c := carga()
		anel.mostrar(progresso(), c)
		if not _avisou_pronta and pronta():
			_avisou_pronta = true
			anel.piscar()
			Sfx.tocar(&"item", -14.0)
		if c >= 1.0 and not _avisou_cheia:
			_avisou_cheia = true
			anel.piscar()
		return
	# Os outros jogadores: o relógio que o anfitrião mandou.
	if not _visto_ativo:
		anel.esconder()
		return
	var seg := maxf(0.0, (Time.get_ticks_msec() - _visto_inicio_ms) / 1000.0)
	var prog := 1.0 if _visto_total <= 0.0 else clampf(seg / _visto_total, 0.0, 1.0)
	var c2 := -1.0
	if _visto_cheia > 0.0:
		c2 = clampf((seg - _visto_total) / maxf(_visto_cheia - _visto_total, 0.01), 0.0, 1.0)
	var estava_pronta := anel.pronta
	anel.mostrar(prog, c2)
	if not estava_pronta and anel.pronta:
		anel.piscar()
