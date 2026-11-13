class_name Missoes
extends Node
## O Brasinha e as missões (etapa 3, design/proposta_brasinha.md). TODO o estado é do
## anfitrião: capítulo e passo, entregas, fome de lenha, pedido do dia, pedras lidas e
## regiões visitadas. Qualquer jogador entrega e o progresso e a recompensa são do grupo.
## O anfitrião salva isso no arquivo do mundo (para_salvar / carregar) e manda uma cópia
## do estado para os outros a cada mudança (_sincronizar); a interface só lê.
##
## Quem fala com o Brasinha: Construcao (a fogueira do acampamento) chama `interagir`. O
## anfitrião decide o que ele diz e manda as linhas só para quem falou (`fala_recebida`).
## O Brasinha fala de novo sobre o que mudou desde a última conversa (os "pendentes").

signal mudou
## As linhas que o Brasinha diz agora a quem falou (só nesta máquina).
signal fala_recebida(linhas: Array, humor: int, escolha: bool)
## Pedra de lore lida por quem está aqui: abre o painel com a imagem.
signal lore_aberta(regiao: int)

const LENHA_PARA_ACORDAR := 10
## Segundos de "contente" ao comer uma madeira depois de acordado, e a cura de quem está
## por perto (vida por segundo): bônus leve, nunca punição.
const TEMPO_CONTENTE := 180.0
const CURA_CONTENTE := 1.5
const RAIO_CURA := 80.0
const PEDIDOS_POR_PONTO := 5
## Os pedidos do dia a dia começam depois do passo "Mãos à obra" (índice 2) do capítulo 1.
const PASSO_LIBERA_PEDIDOS := 3
const RAIO_TOCHA := 48.0
## Meio segundo depois de acabar uma fala o Brasinha ignora cliques (o mesmo clique que
## fechou o balão não abre outro).
const FOLGA_FALA_MS := 400

var w: World
var capitulo := 1
var passo := 0
## Entregas do passo atual (item → quantidade; "matar" conta os slimes).
var entregue: Dictionary = {}
var lenha := 0
var acordado := false
var contente := 0.0
## {item, qtd, texto, rec: [item, qtd], estado: "oferecido" ou "aceito"} ou vazio.
var pedido: Dictionary = {}
var pedidos_feitos := 0
var pedras: Array[int] = []
var visitadas: Array[int] = [Regioes.Id.CLAREIRA]
var semente_entregue := false

var _pendentes: Array = []  # blocos de linhas que ele ainda vai contar
var _novidade := false
var _rng := RandomNumberGenerator.new()
var _em_fala: Dictionary = {}  # peer → até quando (ms) ignora novos cliques
var _tempo_visita := 0.0


func _init(mundo: World = null) -> void:
	w = mundo
	name = "Missoes"
	_rng.randomize()


func _ready() -> void:
	if w == null:
		w = get_tree().get_first_node_in_group(&"mundo") as World
	if w and w.brasinha:
		mudou.connect(w.brasinha.atualizar.bind(self))
		w.brasinha.atualizar(self)
	_atualizar_mundo()


func _servidor() -> bool:
	return multiplayer.is_server()


# --- Leitura (vale em qualquer máquina) -------------------------------------------------------

func passos() -> Array[Dictionary]:
	return FalasBrasinha.CAP1 if capitulo == 1 else FalasBrasinha.CAP2


func passo_atual() -> Dictionary:
	var lista := passos()
	return lista[clampi(passo, 0, lista.size() - 1)]


## O Brasinha ainda está fraquinho (só no começo, até as 10 madeiras)?
func fraquinho() -> bool:
	return not acordado


## 0 a 1: o quanto ele já acordou. Define o tamanho dele, da luz e da zona segura.
func forca() -> float:
	return 1.0 if acordado else clampf(float(lenha) / LENHA_PARA_ACORDAR, 0.0, 1.0)


## "!" quando há o que ouvir; "?" quando falta entregar algo; "" quando não há nada.
func marcador() -> String:
	if _novidade or pedido.get("estado", "") == "oferecido" or passo_atual().get("tipo", "") == "falar":
		return "!"
	if passo_atual().get("tipo", "") == "entregar" or pedido.get("estado", "") == "aceito":
		return "?"
	return ""


## Humor de fundo do Brasinha (qual desenho aparece quando ele não está falando).
func humor_atual() -> int:
	if fraquinho():
		return ArteBrasinha.Humor.FRAQUINHO
	if w and w.noite:
		return ArteBrasinha.Humor.ASSUSTADO
	if contente > 0.0:
		return ArteBrasinha.Humor.COMENDO
	return ArteBrasinha.Humor.FALANDO_A


## Quanto falta do passo atual, em texto: "Madeira: 3/10".
func progresso_texto() -> String:
	var p := passo_atual()
	match String(p.get("tipo", "")):
		"entregar":
			var partes: Array[String] = []
			for item in p["itens"]:
				var feito := mini(int(entregue.get(item, 0)), int(p["itens"][item]))
				partes.append("%s: %d/%d" % [_nome_item(StringName(item)), feito, int(p["itens"][item])])
			return ", ".join(partes)
		"matar":
			return "Slimes derrotados: %d/%d" % [mini(int(entregue.get("matar", 0)), int(p["qtd"])), int(p["qtd"])]
	return ""


## Texto do objetivo atual para o rastreador e o painel (J).
func objetivo_texto() -> String:
	var p := passo_atual()
	var t := String(p.get("objetivo", ""))
	var prog := progresso_texto()
	return t if prog == "" else "%s\n%s" % [t, prog]


func titulo_atual() -> String:
	return String(passo_atual().get("titulo", ""))


func titulo_capitulo() -> String:
	return "Capítulo 1: O fogo que fala" if capitulo == 1 else "Capítulo 2: Raízes teimosas"


## A região do objetivo (para o alfinete do mapa), ou -1 se não há lugar certo.
func regiao_do_objetivo() -> int:
	var p := passo_atual()
	match String(p.get("tipo", "")):
		"matar", "pedra":
			return int(p.get("regiao", Regioes.Id.PANTANO))
		"entregar":
			return Regioes.Id.PANTANO if p["itens"].has("gel_slime") else Regioes.Id.CLAREIRA
		"levar":
			return Regioes.Id.BOSQUE  # o vau fica no caminho do Bosque para as Ruínas
		"boss":
			return Regioes.Id.PANTANO if capitulo == 1 else Regioes.Id.COLINAS
	return Regioes.Id.CLAREIRA


## Posição no mundo do alfinete do mapa: a pedra, o vau, ou o centro da região do objetivo.
func posicao_do_objetivo() -> Vector2:
	var p := passo_atual()
	var tipo := String(p.get("tipo", ""))
	if tipo == "levar":
		return Vector2(GeradorIlha.VAU * World.T)
	if tipo == "pedra" and w and w.pedra_lore(int(p["regiao"])):
		return w.pedra_lore(int(p["regiao"])).position
	var r := regiao_do_objetivo()
	if r == Regioes.Id.CLAREIRA or not GeradorIlha.SEMENTES.has(r):
		return w.centro if w else Vector2.ZERO
	return GeradorIlha.SEMENTES[r][0] * World.T


func pedras_lidas() -> Array[int]:
	return pedras


func pedido_aberto() -> bool:
	return not pedido.is_empty()


## O que o Brasinha tem para dizer sem ninguém perguntar (para o "!" e os testes).
func tem_novidade() -> bool:
	return _novidade


## Põe as linhas de `origem` (lista de textos) no fim de `destino`.
func _juntar(destino: Array[String], origem: Array) -> void:
	for l in origem:
		destino.append(String(l))


func _nome_item(id: StringName) -> String:
	return ItemData.carregar(id).nome if ItemData.existe(id) else String(id)


# --- Estado: salvar, carregar e mandar para os outros -------------------------------------------

func estado() -> Dictionary:
	return {
		"capitulo": capitulo, "passo": passo, "entregue": entregue.duplicate(), "lenha": lenha,
		"acordado": acordado, "pedido": pedido.duplicate(true), "feitos": pedidos_feitos,
		"pedras": pedras.duplicate(), "visitadas": visitadas.duplicate(), "semente": semente_entregue,
		"novidade": _novidade, "contente": contente > 0.0,
	}


func para_salvar() -> Dictionary:
	var d := estado()
	d["pendentes"] = _pendentes.duplicate(true)
	return d


## Lê o que foi salvo (anfitrião) ou o que o anfitrião mandou (os outros). Os números
## voltam como float do JSON: tudo é refeito com os tipos certos.
func carregar(d: Dictionary) -> void:
	capitulo = clampi(int(d.get("capitulo", 1)), 1, 2)
	passo = maxi(int(d.get("passo", 0)), 0)
	entregue = {}
	var e: Dictionary = d.get("entregue", {})
	for k in e:
		entregue[String(k)] = int(e[k])
	lenha = int(d.get("lenha", 0))
	acordado = bool(d.get("acordado", false))
	if not _servidor():
		contente = 1.0 if bool(d.get("contente", false)) else 0.0
	pedido = {}
	var pd: Dictionary = d.get("pedido", {})
	if not pd.is_empty():
		pedido = {
			"item": String(pd.get("item", "")), "qtd": int(pd.get("qtd", 1)), "texto": String(pd.get("texto", "")),
			"rec": [String(pd["rec"][0]), int(pd["rec"][1])] if pd.has("rec") else [], "estado": String(pd.get("estado", "oferecido")),
		}
	pedidos_feitos = int(d.get("feitos", 0))
	pedras = []
	for r in d.get("pedras", []):
		pedras.append(int(r))
	visitadas = [Regioes.Id.CLAREIRA]
	for r in d.get("visitadas", []):
		if int(r) not in visitadas:
			visitadas.append(int(r))
	semente_entregue = bool(d.get("semente", false))
	_pendentes = []
	for bloco in d.get("pendentes", []):
		var linhas: Array = []
		for l in bloco:
			linhas.append(String(l))
		_pendentes.append(linhas)
	_novidade = bool(d.get("novidade", false)) if not d.has("pendentes") else not _pendentes.is_empty()
	passo = clampi(passo, 0, passos().size() - 1)
	_atualizar_mundo()
	mudou.emit()


## Só o anfitrião: reconta, atualiza o que se vê no mundo e avisa todos.
func _emitir() -> void:
	_novidade = not _pendentes.is_empty()
	_atualizar_mundo()
	mudou.emit()
	if _servidor() and multiplayer.has_multiplayer_peer():
		_sincronizar.rpc(estado())


func enviar_para(peer: int) -> void:
	if _servidor():
		_sincronizar.rpc_id(peer, estado())


@rpc("authority", "call_remote", "reliable")
func _sincronizar(d: Dictionary) -> void:
	if Net.veio_do_anfitriao():
		carregar(d)


## A fogueira do acampamento (luz e zona segura) e as pedras de lore mostram o estado.
func _atualizar_mundo() -> void:
	if w == null:
		return
	var f := w.entidades.get_node_or_null("FogueiraAcampamento") as Construcao
	if f:
		f.definir_forca(forca(), World.RAIO_FOGUEIRA)
	for r in Regioes.TODAS:
		var pedra := w.pedra_lore(r)
		if pedra:
			pedra.definir_lida(r in pedras)


# --- Conversa com o Brasinha (anfitrião) --------------------------------------------------------

## O jogador clicou no Brasinha. Decide o que ele diz e manda só para quem clicou.
func interagir(quem: Player) -> void:
	if not _servidor() or quem == null:
		return
	var peer := quem.id_rede()
	var agora := Time.get_ticks_msec()
	if int(_em_fala.get(peer, 0)) > agora:
		return
	_em_fala[peer] = agora + 60000
	var r := conversar(quem)
	if quem.eh_local():
		fala_recebida.emit(r["linhas"], r["humor"], r["escolha"])
	else:
		_mostrar_fala.rpc_id(peer, r["linhas"], r["humor"], r["escolha"])


@rpc("authority", "call_remote", "reliable")
func _mostrar_fala(linhas: Array, humor: int, escolha: bool) -> void:
	if Net.veio_do_anfitriao():
		fala_recebida.emit(linhas, humor, escolha)


## A conversa em si: o que ele diz a `quem` agora. Entrega o que o passo atual e o pedido
## pedem (da mochila inteira), avança o passo se completou, e conta o que ficou pendente.
## Devolve {linhas, humor, escolha}.
func conversar(quem: Player) -> Dictionary:
	var linhas: Array[String] = []
	var humor := ArteBrasinha.Humor.FALANDO_A
	var escolha := false
	var fez_algo := false
	var p := passo_atual()
	var tipo := String(p.get("tipo", ""))
	if tipo == "falar":
		_concluir_passo(quem)
		fez_algo = true
	elif tipo == "entregar":
		var levou := _receber_do_passo(quem, p)
		if levou:
			linhas.append(String(FalasBrasinha.escolher(FalasBrasinha.RECEBIDO, _rng)))
			fez_algo = true
			if _passo_completo(p):
				_concluir_passo(quem)
				humor = ArteBrasinha.Humor.COMEMORANDO
	elif tipo == "levar" and quem.inventario.quantidade_de(StringName(p["item"])) > 0:
		linhas.append("Segura a tocha firme e vai até a muralha, no vau!")
	# O que mudou desde a última conversa.
	for bloco in _pendentes:
		for l in bloco:
			linhas.append(String(l))
		fez_algo = true
	_pendentes.clear()
	# O pedido do dia.
	var estado_pedido := String(pedido.get("estado", ""))
	if estado_pedido == "oferecido":
		linhas.append(FalasBrasinha.OFERTA % String(pedido["texto"]))
		escolha = true
		fez_algo = true
	elif estado_pedido == "aceito":
		_juntar(linhas, _tentar_pedido(quem))
		fez_algo = true
	# Petisco: depois de acordar, madeira na mão é só um agrado.
	if not fez_algo and acordado and quem.inventario.item_em(quem.barra_escolhida) == &"madeira":
		quem.inventario.gastar(quem.barra_escolhida, 1)
		contente = TEMPO_CONTENTE
		_juntar(linhas, FalasBrasinha.escolher(FalasBrasinha.PETISCO, _rng))
		humor = ArteBrasinha.Humor.COMENDO
		fez_algo = true
	if not fez_algo or linhas.is_empty():
		_juntar(linhas, FalasBrasinha.escolher(FalasBrasinha.CONVERSA, _rng))
	# Lembrete do que fazer agora (só se o objetivo ainda não foi dado nesta conversa).
	if String(passo_atual().get("tipo", "")) not in ["falar", "boss"]:
		linhas.append("(%s)" % objetivo_texto().replace("\n", " - "))
	if fraquinho():
		humor = ArteBrasinha.Humor.FRAQUINHO if humor == ArteBrasinha.Humor.FALANDO_A else humor
	_emitir()
	return {"linhas": linhas, "humor": humor, "escolha": escolha}


## Leva da mochila de quem falou o que o passo pede (até completar). Devolve se levou algo.
func _receber_do_passo(quem: Player, p: Dictionary) -> bool:
	var levou := false
	for item in p["itens"]:
		var falta := int(p["itens"][item]) - int(entregue.get(item, 0))
		var tem := quem.inventario.quantidade_de(StringName(item))
		var n := mini(falta, tem)
		if n <= 0:
			continue
		quem.inventario.remover(StringName(item), n)
		entregue[item] = int(entregue.get(item, 0)) + n
		if item == "madeira":
			lenha += n
		quem.avisar("-%d %s" % [n, _nome_item(StringName(item)).to_lower()], &"item")
		levou = true
	return levou


func _passo_completo(p: Dictionary) -> bool:
	for item in p["itens"]:
		if int(entregue.get(item, 0)) < int(p["itens"][item]):
			return false
	return true


## O passo atual acabou: o Brasinha guarda o que vai dizer, o próximo começa.
func _concluir_passo(quem: Player = null) -> void:
	var p := passo_atual()
	var fim: Array = p.get("fim", [])
	if not fim.is_empty():
		_pendentes.append(fim)
	if p.has("dar") and quem:
		for item in p["dar"]:
			quem.inventario.adicionar(StringName(item), int(p["dar"][item]))
			quem.avisar("+%d %s" % [int(p["dar"][item]), _nome_item(StringName(item)).to_lower()], &"item")
	if String(p["id"]) == "lanche":
		acordado = true
	entregue = {}
	if passo < passos().size() - 1:
		passo += 1
	_auto_avancar()
	_emitir()


## Passos que já estavam cumpridos quando começam (leu a pedra antes da hora).
func _auto_avancar() -> void:
	var p := passo_atual()
	if String(p.get("tipo", "")) == "pedra" and int(p["regiao"]) in pedras and passo < passos().size() - 1:
		var fim: Array = p.get("fim", [])
		if not fim.is_empty():
			_pendentes.append(fim)
		passo += 1
		_auto_avancar()


# --- Acontecimentos do mundo (anfitrião) --------------------------------------------------------

func notificar_construiu(item: StringName) -> void:
	if not _servidor():
		return
	var p := passo_atual()
	if String(p.get("tipo", "")) == "construir" and StringName(p["item"]) == item:
		_concluir_passo()


## Um slime (de qualquer tipo) morreu.
func notificar_slime_morto() -> void:
	if not _servidor():
		return
	var p := passo_atual()
	if String(p.get("tipo", "")) != "matar":
		return
	entregue["matar"] = int(entregue.get("matar", 0)) + 1
	if int(entregue["matar"]) >= int(p["qtd"]):
		_concluir_passo()
	else:
		_emitir()


## Alguém leu a pedra de lore desta região (interagiu com ela).
func ler_pedra(quem: Player, regiao: int) -> void:
	if not _servidor() or quem == null:
		return
	if regiao not in pedras:
		pedras.append(regiao)
		var p := passo_atual()
		if String(p.get("tipo", "")) == "pedra" and int(p["regiao"]) == regiao:
			_concluir_passo(quem)
		else:
			var fala: Array = FalasBrasinha.FALA_PEDRA.get(regiao, [])
			if not fala.is_empty():
				_pendentes.append(fala)
			_emitir()
	if quem.eh_local():
		lore_aberta.emit(regiao)
	else:
		_abrir_lore.rpc_id(quem.id_rede(), regiao)


@rpc("authority", "call_remote", "reliable")
func _abrir_lore(regiao: int) -> void:
	if Net.veio_do_anfitriao():
		lore_aberta.emit(regiao)


## Gancho para a Mãe Gosma (etapa 4): a Semente voltou. Fecha o capítulo 1, conserta a ponte
## das Colinas e dá 1 ponto de árvore a cada jogador. Devolve false se já tinha voltado.
func entregar_semente() -> bool:
	if not _servidor() or semente_entregue:
		return false
	semente_entregue = true
	acordado = true
	_pendentes.append(FalasBrasinha.SEMENTE_VOLTOU)
	capitulo = 2
	passo = 0
	entregue = {}
	w.abrir_passagem(World.PONTE)
	for j in get_tree().get_nodes_in_group(&"jogadores"):
		_dar_ponto_arvore(j as Player)
	World.avisar_todos(self, "A Semente voltou ao Brasinha! A ponte das Colinas foi consertada.")
	_emitir()
	return true


func _dar_ponto_arvore(p: Player) -> void:
	if p == null or p.criando:
		return
	p.pontos_habilidade += 1
	p._enviar_progresso()
	p.avisar("+1 ponto de árvore!", &"subir_nivel")


## Capítulo 2: a Tocha do Brasinha perto das raízes do vau as queima e abre as Ruínas.
func verificar_tocha() -> void:
	if not _servidor() or capitulo != 2 or String(passo_atual().get("id", "")) != "raizes":
		return
	var raizes := w.passagem(World.RAIZES)
	if raizes == null:
		return
	for j in get_tree().get_nodes_in_group(&"jogadores"):
		var p := j as Player
		if p.inventario.quantidade_de(&"tocha_brasinha") > 0 and p.global_position.distance_to(raizes.global_position) <= RAIO_TOCHA:
			w.abrir_passagem(World.RAIZES)
			_concluir_passo(p)
			return


# --- Pedidos do dia a dia ---------------------------------------------------------------------------

func pedidos_liberados() -> bool:
	return capitulo >= 2 or passo >= PASSO_LIBERA_PEDIDOS


## O sol nasceu (anfitrião): se não há pedido aberto, o Brasinha tem um novo.
func ao_amanhecer() -> void:
	if not _servidor() or not pedidos_liberados() or not pedido.is_empty():
		return
	var candidatos: Array[Dictionary] = []
	for e in FalasBrasinha.PEDIDOS:
		if int(e["regiao"]) in visitadas:
			candidatos.append(e)
	if candidatos.is_empty():
		return
	var e: Dictionary = candidatos[_rng.randi() % candidatos.size()]
	var qtd := _rng.randi_range(int(e["qtd"][0]), int(e["qtd"][1]))
	var rec: Array = FalasBrasinha.escolher(FalasBrasinha.RECOMPENSAS, _rng)
	pedido = {"item": String(e["item"]), "qtd": qtd, "texto": String(e["texto"]) % qtd, "rec": [String(rec[0]), int(rec[1])], "estado": "oferecido"}
	_emitir()
	Events.aviso.emit("O Brasinha tem um pedido para você. Fale com ele na fogueira.")


## Aceitar ou recusar o pedido oferecido (quem está falando decide por todos).
func responder_pedido(quem: Player, aceitar: bool) -> Array[String]:
	if not _servidor() or String(pedido.get("estado", "")) != "oferecido":
		return []
	var linhas: Array[String] = []
	if aceitar:
		pedido["estado"] = "aceito"
		_juntar(linhas, FalasBrasinha.ACEITOU)
	else:
		pedido = {}
		_juntar(linhas, FalasBrasinha.RECUSOU)
	_emitir()
	if quem:
		if quem.eh_local():
			fala_recebida.emit(linhas, ArteBrasinha.Humor.FALANDO_B, false)
		else:
			_mostrar_fala.rpc_id(quem.id_rede(), linhas, ArteBrasinha.Humor.FALANDO_B, false)
	return linhas


## Tudo ou nada: se `quem` tem a quantidade pedida, entrega, ganha a recompensa e o pedido fecha.
func _tentar_pedido(quem: Player) -> Array[String]:
	var item := StringName(pedido["item"])
	var qtd := int(pedido["qtd"])
	var tem := quem.inventario.quantidade_de(item)
	if tem < qtd:
		return [FalasBrasinha.PEDIDO_FALTA % [("%d %s" % [qtd, _nome_item(item).to_lower()]), tem]]
	quem.inventario.remover(item, qtd)
	var rec: Array = pedido["rec"]
	quem.inventario.adicionar(StringName(rec[0]), int(rec[1]))
	quem.avisar("+%d %s" % [int(rec[1]), _nome_item(StringName(rec[0])).to_lower()], &"item")
	pedido = {}
	pedidos_feitos += 1
	var linhas: Array[String] = []
	_juntar(linhas, FalasBrasinha.PEDIDO_ENTREGUE)
	if pedidos_feitos % PEDIDOS_POR_PONTO == 0:
		for j in get_tree().get_nodes_in_group(&"jogadores"):
			_dar_ponto_arvore(j as Player)
		_juntar(linhas, FalasBrasinha.PONTO_DE_PEDIDOS)
	return linhas


# --- Para quem está jogando aqui: responder e fechar a fala ---------------------------------------

## Os botões "Aceito" e "Agora não" do balão.
func responder(aceitar: bool) -> void:
	if _servidor():
		responder_pedido(w.jogador, aceitar)
	else:
		_pedir_resposta.rpc_id(1, aceitar)


@rpc("any_peer", "reliable")
func _pedir_resposta(aceitar: bool) -> void:
	if not _servidor():
		return
	var quem := w.entidades.get_node_or_null(str(multiplayer.get_remote_sender_id())) as Player
	if quem:
		responder_pedido(quem, aceitar)


## O balão fechou: o Brasinha volta a ouvir cliques (com uma folguinha).
func fim_fala() -> void:
	if _servidor():
		_em_fala[1] = Time.get_ticks_msec() + FOLGA_FALA_MS
	else:
		_pedir_fim_fala.rpc_id(1)


@rpc("any_peer", "reliable")
func _pedir_fim_fala() -> void:
	if _servidor():
		_em_fala[multiplayer.get_remote_sender_id()] = Time.get_ticks_msec() + FOLGA_FALA_MS


# --- Passar do tempo (anfitrião) --------------------------------------------------------------------

func _process(delta: float) -> void:
	if w == null or not _servidor():
		return
	_tempo_visita += delta
	if _tempo_visita >= 0.5:
		_tempo_visita = 0.0
		atualizar_visitadas()
		verificar_tocha()
	if contente > 0.0:
		contente = maxf(contente - delta, 0.0)
		var f := w.entidades.get_node_or_null("FogueiraAcampamento") as Node2D
		if f:
			for j in get_tree().get_nodes_in_group(&"jogadores"):
				var p := j as Player
				if not p.caido and p.global_position.distance_to(f.global_position) <= RAIO_CURA:
					p.vida.curar(CURA_CONTENTE * delta)
		if contente <= 0.0:
			_emitir()


## Anota as regiões onde há jogadores (os pedidos só falam de lugares já visitados).
func atualizar_visitadas() -> void:
	var mudou_algo := false
	for j in get_tree().get_nodes_in_group(&"jogadores"):
		var r := w.regiao_em((j as Node2D).global_position)
		if r not in visitadas:
			visitadas.append(r)
			mudou_algo = true
	if mudou_algo:
		_emitir()
