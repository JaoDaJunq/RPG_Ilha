class_name Golpes
extends RefCounted
## Peças prontas para as lógicas das habilidades (todas rodam no ANFITRIÃO):
##   - quem está perto: inimigos_em_volta, jogadores_em_volta, mais_perto;
##   - corrente: dano que salta entre N alvos próximos (Corrente elétrica, Condução...);
##   - avancar: avanço ou teleporte até um ponto, com dano no caminho (Forma de relâmpago...);
##   - buff_em_volta: buff no jogador e nos aliados perto (Grito de guerra, Matilha...);
##   - estado_em_volta: um estado em todos os inimigos perto (Medo do Grito, Provocar...);
##   - acertar: dano numa coisa (com o estado e o efeito, se quiser).
## Zonas, invocações e companheiros ficam em zona.gd, invocacao.gd e companheiro.gd; as
## variações de projétil (perfura, quica, volta, puxa) em projetil.gd.


## Inimigos (e animais, se `com_animais`) a até `raio` px de `centro`, do mais perto ao mais longe.
static func inimigos_em_volta(quem: Node, centro: Vector2, raio: float, com_animais := true) -> Array[Node2D]:
	var l: Array[Node2D] = []
	var grupos := quem.get_tree().get_nodes_in_group(&"inimigos")
	if com_animais:
		grupos += quem.get_tree().get_nodes_in_group(&"animais")
	for n in grupos:
		var e := n as Node2D
		if e and not e.is_queued_for_deletion() and e.global_position.distance_to(centro) <= raio:
			var v := e.get_node_or_null("HealthComponent") as HealthComponent
			if v == null or v.esta_vivo():
				l.append(e)
	l.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.global_position.distance_to(centro) < b.global_position.distance_to(centro))
	return l


## Jogadores (já criados) a até `raio` px de `centro`.
static func jogadores_em_volta(quem: Node, centro: Vector2, raio: float) -> Array[Player]:
	var l: Array[Player] = []
	for n in quem.get_tree().get_nodes_in_group(&"jogadores"):
		var p := n as Player
		if p and not p.criando and p.global_position.distance_to(centro) <= raio:
			l.append(p)
	return l


## O inimigo (ou animal) mais perto de `centro` até `raio`, fora os de `menos`. Nulo se não houver.
static func mais_perto(quem: Node, centro: Vector2, raio: float, menos: Array = [], com_animais := true) -> Node2D:
	for e in inimigos_em_volta(quem, centro, raio, com_animais):
		if not e in menos:
			return e
	return null


## Acerta `alvo` com `dano` de `elemento` em nome de `quem` (as passivas dele valem) e,
## se pedir, aplica um estado e toca um efeito em cima dele. Devolve se acertou.
static func acertar(quem: Node, alvo: Node2D, dano: float, elemento: StringName, estado: StringName = &"", estado_segundos := 0.0, estado_forca := 0.0, efeito: StringName = &"") -> bool:
	if alvo == null or not is_instance_valid(alvo):
		return false
	var area := alvo.get_node_or_null("Hurtbox") as Hurtbox
	if area == null:
		return false
	var onde := alvo.global_position
	if dano > 0.0:
		area.receber(dano, elemento, quem if is_instance_valid(quem) else null)
	if estado != &"" and is_instance_valid(alvo):
		EfeitosEstado.aplicar_em(alvo, estado, estado_segundos, estado_forca, quem)
	if efeito != &"" and is_instance_valid(quem):
		World.efeito_todos(quem, efeito, onde)
	return true


## Corrente: acerta `primeiro` e salta para o inimigo mais perto (até `raio` px do último
## acertado) que ainda não levou, até acertar `alvos` ao todo. `efeito` toca em cada um
## (o &"raio" serve para choque). Devolve os acertados, na ordem.
##   Golpes.corrente(quem, alvo, 5, 56.0, dano_de(quem, hab), &"raio", &"raio")
static func corrente(quem: Node, primeiro: Node2D, alvos: int, raio: float, dano: float, elemento: StringName, efeito: StringName = &"", estado: StringName = &"", estado_segundos := 0.0) -> Array[Node2D]:
	var feitos: Array[Node2D] = []
	var atual := primeiro
	while atual != null and feitos.size() < alvos:
		var onde := atual.global_position
		feitos.append(atual)
		acertar(quem, atual, dano, elemento, estado, estado_segundos, 0.0, efeito)
		atual = mais_perto(quem, onde, raio, feitos)
	return feitos


## Avanço (ou teleporte, com `teleporte`) do jogador até `destino`, limitado a `alcance` px,
## acertando uma vez cada inimigo numa faixa de `largura` px no caminho. Devolve os acertados.
##   Golpes.avancar(quem, alvo, hab.alcance, dano_de(quem, hab), &"raio", 14.0, true)
static func avancar(quem: Player, destino: Vector2, alcance: float, dano: float, elemento: StringName, largura := 12.0, teleporte := false, estado: StringName = &"", estado_segundos := 0.0) -> Array[Node2D]:
	var de := quem.global_position
	var caminho := (destino - de).limit_length(alcance)
	var acertados: Array[Node2D] = []
	if caminho.length() < 1.0:
		return acertados
	for e in inimigos_em_volta(quem, de + caminho / 2.0, caminho.length() / 2.0 + largura):
		# Distância do inimigo até o segmento do caminho (no "chão" do corpo dele).
		var p := e.global_position
		var t := clampf((p - de).dot(caminho) / caminho.length_squared(), 0.0, 1.0)
		if p.distance_to(de + caminho * t) <= largura:
			acertados.append(e)
	for e in acertados:
		acertar(quem, e, dano, elemento, estado, estado_segundos)
	World.efeito_todos(quem, &"poeira", de)
	if teleporte:
		quem.vida.proteger(0.15)
		quem.mover_por_habilidade(caminho, 0.05)
		World.efeito_todos(quem, &"poeira", de + caminho)
	else:
		quem.mover_por_habilidade(caminho, clampf(caminho.length() / 300.0, 0.08, 0.3))
	return acertados


## Buff no jogador e nos aliados a até `raio` px dele (ver Buffs). Devolve quem ganhou.
##   Golpes.buff_em_volta(quem, 80.0, Buffs.DANO, 0.10, 6.0)
static func buff_em_volta(quem: Player, raio: float, tipo: StringName, valor: float, segundos: float, efeito: StringName = &"") -> Array[Player]:
	var l := jogadores_em_volta(quem, quem.global_position, raio)
	for j in l:
		j.buffs.dar(tipo, valor, segundos, quem)
		if efeito != &"":
			World.efeito_todos(j, efeito, j.global_position + Vector2(0, -10))
	return l


## Aplica `estado` em todos os inimigos (e animais) a até `raio` px de `centro`. A origem é
## `quem` (o Medo foge dele; o Provocado persegue ele). Devolve quem pegou.
##   Golpes.estado_em_volta(quem, quem.global_position, 48.0, EfeitosEstado.MEDO, 1.5)
static func estado_em_volta(quem: Node, centro: Vector2, raio: float, estado: StringName, segundos: float, forca := 0.0, com_animais := true) -> Array[Node2D]:
	var l := inimigos_em_volta(quem, centro, raio, com_animais)
	for e in l:
		EfeitosEstado.aplicar_em(e, estado, segundos, forca, quem)
	return l


## Puxa (ou empurra, com distância negativa) `alvo` na direção de `para` por até `distancia` px.
static func puxar(alvo: Node2D, para: Vector2, distancia: float, duracao := 0.2) -> void:
	var e := EfeitosEstado.de(alvo)
	if e == null:
		return
	var v := para - alvo.global_position
	var d := minf(distancia, maxf(0.0, v.length() - 12.0)) if distancia > 0.0 else distancia
	if v.length() > 0.1:
		e.empurrar(v.normalized() * d, duracao)
