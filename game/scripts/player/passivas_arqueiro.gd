class_name PassivasArqueiro
extends RefCounted
## Passivas novas do Arqueiro (árvore de habilidades). Passivas.gd chama estas funções em todo
## jogador, de qualquer classe: cada uma confere `p.tem(&"<nó>")` antes de agir. As
## antigas continuam em passivas.gd. Devolva 1.0 (ou não faça nada) quando não valer.
## Roda no ANFITRIÃO, menos `velocidade`, que roda no dono (quem anda).
##
##   - Rastreador (a parte das pegadas): a cada 5 s levanta poeira nos animais perto;
##   - Sangue frio: acerto crítico (de mais de 6 blocos ou num alvo Marcado) devolve mana;
##   - Reaproveitar: passar por cima de uma armadilha ou mina sua recolhe e devolve a mana;
##   - Laço: o falcão te acompanha sempre (e bica quem você acertar);
##   - Matilha: com o companheiro perto, você e ele +15% de velocidade e de dano;
##   - Espírito da fera (suprema, ativa): enquanto dura, as flechas saltam para mais 1.

const PEGADAS_INTERVALO := 5.0
const PEGADAS_RAIO := 160.0  # 10 blocos
const SANGUE_FRIO_MANA := 3.0
const SANGUE_FRIO_ESPERA_MS := 250  # no máximo um a cada 0,25 s (a chuva acerta vários)
const REAPROVEITAR_RAIO := 8.0
const REAPROVEITAR_ESPERA_MS := 1500  # armada há pelo menos 1,5 s (não recolhe na hora)
const LACO_DANO := 0.5
const MATILHA := 0.15
const MATILHA_RAIO := 80.0
const FLECHA_CENA := "res://scenes/abilities/flecha.tscn"


## Multiplicador do dano que `p` causa em `alvo` (antes de aplicar).
static func dano_causado(_p: Player, _quantidade: float, _tipo: StringName, _alvo: Node) -> float:
	return 1.0


## Acerto crítico do Arqueiro: de longe (mais de 6 blocos) ou num alvo Marcado.
static func critico(p: Player, alvo: Node) -> bool:
	var a := alvo as Node2D
	if a == null:
		return false
	if p.global_position.distance_to(a.global_position) > Passivas.PONTO_FRACO_DISTANCIA:
		return true
	var e := EfeitosEstado.de(a)
	return e != null and e.tem(EfeitosEstado.MARCADO)


## Depois que um golpe ou habilidade de `p` acertou `alvo` (o dano já foi aplicado).
static func acertou(p: Player, alvo: Node, _quantidade: float, _tipo: StringName) -> void:
	if p.tem(&"sangue_frio") and critico(p, alvo):
		var agora := Time.get_ticks_msec()
		if agora >= int(p.get_meta(&"sangue_frio_ms", 0)):
			p.set_meta(&"sangue_frio_ms", agora + SANGUE_FRIO_ESPERA_MS)
			p.mana = minf(p.ficha.mana_maxima(), p.mana + SANGUE_FRIO_MANA)
			p._enviar_mana()


## Multiplicador do dano que `p` recebe.
static func dano_recebido(_p: Player, _quantidade: float, _tipo: StringName) -> float:
	return 1.0


## Multiplicador do dano de um inimigo ou animal (`atacante`) em `alvo` (Ex.: Frio que morde).
static func ataque_inimigo(_atacante: Node, _alvo: Node, _dano: float) -> float:
	return 1.0


## `p` derrotou `alvo`.
static func derrotou(_p: Player, _alvo: Node) -> void:
	pass


## Multiplicador de velocidade (roda no DONO). A Matilha e o Espírito da fera usam Buffs.
static func velocidade(_p: Player) -> float:
	return 1.0


## Multiplicador da recarga da habilidade.
static func recarga(_p: Player, _hab: HabilidadeData) -> float:
	return 1.0


## Multiplicador do custo de mana da habilidade.
static func custo_mana(_p: Player, _hab: HabilidadeData) -> float:
	return 1.0


## Todo quadro, no anfitrião (auras, relógios).
static func processar(p: Player, delta: float) -> void:
	if p.classe != &"arqueiro" or p.ficha == null:
		return
	if p.tem(&"rastreador"):
		_pegadas(p, delta)
	if p.tem(&"reaproveitar"):
		_reaproveitar(p)
	if p.tem(&"laco") and LogicasArqueiro.falcao_de(p) == null:
		LogicasArqueiro.criar_falcao(p, LACO_DANO * p.ficha.multiplicador(&"fisico"), 0.0)
	if p.tem(&"matilha"):
		_matilha(p)
	if Time.get_ticks_msec() < int(p.get_meta(&"espirito_da_fera_ate_ms", 0)):
		_fera(p)


## Rastreador: as pegadas (poeira) dos animais a até 10 blocos, a cada 5 s.
static func _pegadas(p: Player, delta: float) -> void:
	var t: float = p.get_meta(&"pegadas_t", 0.0) - delta
	if t > 0.0:
		p.set_meta(&"pegadas_t", t)
		return
	p.set_meta(&"pegadas_t", PEGADAS_INTERVALO)
	for n in p.get_tree().get_nodes_in_group(&"animais"):
		var a := n as Node2D
		if a and not a.is_queued_for_deletion() and a.global_position.distance_to(p.global_position) <= PEGADAS_RAIO:
			World.efeito_todos(p, &"poeira", a.global_position + Vector2(0, 2))


## Reaproveitar: pisar numa armadilha ou mina sua que não disparou recolhe e devolve a mana.
static func _reaproveitar(p: Player) -> void:
	var agora := Time.get_ticks_msec()
	for n in p.get_tree().get_nodes_in_group(&"armadilhas"):
		var a := n as ArmadilhaChao
		if a == null or a.is_queued_for_deletion() or a.dono_id != p.id_rede() or a.disparou():
			continue
		if not a.has_meta(&"criada_ms"):
			a.set_meta(&"criada_ms", agora)
		var hab := ArvoreData.no(&"arqueiro", &"armadilha").habilidade
		_recolher(p, a, agora, Passivas.custo_mana(p, hab), "a armadilha")
	for n in p.get_tree().get_nodes_in_group(&"minas"):
		var m := n as Invocacao
		if m and m.dono == p and not m.is_queued_for_deletion():
			_recolher(p, m, agora, float(m.get_meta(&"custo", 0.0)), "a mina")


static func _recolher(p: Player, a: Node2D, agora: int, mana: float, nome: String) -> void:
	if agora - int(a.get_meta(&"criada_ms", agora)) < REAPROVEITAR_ESPERA_MS:
		return
	if a.global_position.distance_to(p.global_position) > REAPROVEITAR_RAIO:
		return
	a.queue_free()
	p.mana = minf(p.ficha.mana_maxima(), p.mana + mana)
	p._enviar_mana()
	World.efeito_todos(p, &"poeira", a.global_position)
	p.avisar("Recolheu %s (+%d de mana)." % [nome, roundi(mana)])


## Matilha: com um companheiro a até 5 blocos, você e ele ficam mais rápidos e fortes.
static func _matilha(p: Player) -> void:
	var perto := false
	for c in Companheiro.de(p):
		if not c.has_meta(&"base_dano"):
			c.set_meta(&"base_dano", c.dano)
			c.set_meta(&"base_vel", c.velocidade)
		var junto := c.global_position.distance_to(p.global_position) <= MATILHA_RAIO
		perto = perto or junto
		var m := 1.0 + MATILHA if junto else 1.0
		c.dano = float(c.get_meta(&"base_dano")) * m
		c.velocidade = float(c.get_meta(&"base_vel")) * m
	# Renova o buff a cada 0,4 s (dura 1 s): sem mandar aviso de rede todo quadro.
	var agora := Time.get_ticks_msec()
	if perto and agora >= int(p.get_meta(&"matilha_ms", 0)):
		p.set_meta(&"matilha_ms", agora + 400)
		p.buffs.dar(Buffs.VELOCIDADE, MATILHA, 1.0, p)
		p.buffs.dar(Buffs.DANO, MATILHA, 1.0, p)


## Espírito da fera: cada flecha nova do jogador salta para mais um inimigo.
static func _fera(p: Player) -> void:
	for n in p.get_tree().get_nodes_in_group(&"projeteis"):
		var pr := n as Projetil
		if pr and pr.lancador == p and pr.scene_file_path == FLECHA_CENA and not pr.has_meta(&"fera"):
			pr.set_meta(&"fera", true)
			pr.quiques += 1
