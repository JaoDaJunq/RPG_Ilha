class_name LogicasClerigo
extends RefCounted
## Lógicas das habilidades novas do Clérigo (árvore de habilidades).
## Cada `class Nome extends HabilidadeLogica` escrita aqui já fica registrada em
## Logicas.criar: basta pôr `logica = &"Nome"` no .tres da habilidade (o nome não pode
## repetir o de outro arquivo). Peças prontas (zona, invocação, projéteis especiais,
## corrente, avanço, buffs, estados): ver design/habilidades_base.md.
##
## Tudo roda no ANFITRIÃO. As melhorias da árvore entram por `dano_de` (dano) e por
## `quem.mult_habilidade(hab)` (cura e duração das proteções); a recarga já diminui sozinha.

const MARTELO := preload("res://scenes/abilities/martelo.tscn")
## "Aliado na mira": até esta distância do Clérigo e deste raio em volta do mouse.
const ALCANCE_ALIADO := 120.0
const RAIO_MIRA_ALIADO := 40.0


## O ponto da mira, limitado ao alcance da habilidade.
static func ponto_na_mira(quem: Player, alvo: Vector2, alcance: float) -> Vector2:
	var de := quem.global_position
	return de + (alvo - de).limit_length(alcance * Passivas.alcance(quem))


## O aliado (outro jogador, de pé) mais perto da mira, a até ALCANCE_ALIADO do Clérigo. Se ninguém
## estiver perto da mira, o aliado mais perto do Clérigo. Nulo se não houver aliado.
static func aliado_na_mira(quem: Player, mira: Vector2) -> Player:
	var melhor: Player = null
	var menor := INF
	for o in Passivas.outros_jogadores(quem, ALCANCE_ALIADO):
		if o.caido:
			continue  # caído só volta pelo Levantar (caido_na_mira)
		var d := o.global_position.distance_to(mira)
		if d > RAIO_MIRA_ALIADO:
			d = 1000.0 + o.global_position.distance_to(quem.global_position)
		if d < menor:
			menor = d
			melhor = o
	return melhor


## O aliado CAÍDO mais perto da mira, a até ALCANCE_ALIADO do Clérigo (se nenhum estiver
## perto da mira, o caído mais perto do Clérigo). Nulo se não houver.
static func caido_na_mira(quem: Player, mira: Vector2) -> Player:
	var melhor: Player = null
	var menor := INF
	for o in Passivas.outros_jogadores(quem, ALCANCE_ALIADO):
		if not o.caido:
			continue
		var d := o.global_position.distance_to(mira)
		if d > RAIO_MIRA_ALIADO:
			d = 1000.0 + o.global_position.distance_to(quem.global_position)
		if d < menor:
			menor = d
			melhor = o
	return melhor


## Slime da noite (o sol e a luz forte derretem).
static func noturno(e: Node) -> bool:
	return e != null and e.is_in_group(&"inimigos") and e.get(&"noturno") == true


## Derrete o slime da noite com luz: um golpe de luz do tamanho da vida dele (assim quem
## lançou ganha a experiência e o gel, como em qualquer vitória).
static func derreter(quem: Player, e: Node2D) -> void:
	var v := e.get_node_or_null("HealthComponent") as HealthComponent
	if v and v.esta_vivo():
		v._protecao = 0.0
		Golpes.acertar(quem, e, v.atual + 1.0, &"luz", &"", 0.0, 0.0, &"subir_nivel")


# --- Iniciais --------------------------------------------------------------------------

## Martelo da justiça: um martelo de luz que Atordoa e volta para a mão (acerta na ida e na volta).
class MarteloDaJustica extends HabilidadeLogica:
	## Linhas de efeito da janelinha da habilidade (TextoHabilidade).
	func textos(hab: HabilidadeData, ficha: Ficha) -> Array[String]:
		var l: Array[String] = ["Atordoa por %s s" % TextoHabilidade.numero(ATORDOAR), "Volta para a mão e acerta de novo na volta"]
		return l

	const ATORDOAR := 1.0

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var p := Logicas.lancar(LogicasClerigo.MARTELO, quem, dir, dano_de(quem, hab))
		p.volta = true
		p.estado = EfeitosEstado.ATORDOADO
		p.estado_segundos = ATORDOAR


# --- Curandeiro ------------------------------------------------------------------------

## Círculo de cura: uma área no ponto da mira que cura os jogadores dentro por 6 s.
class CirculoDeCura extends HabilidadeLogica:
	## Linhas de efeito da janelinha da habilidade (TextoHabilidade).
	func textos(hab: HabilidadeData, ficha: Ficha) -> Array[String]:
		var l: Array[String] = ["Cura %s por segundo (%s + %s por ponto de Espírito)" % [TextoHabilidade.numero(BASE + POR_ESPIRITO * (ficha.valor(&"espirito") if ficha else 5)), TextoHabilidade.numero(BASE), TextoHabilidade.numero(POR_ESPIRITO)], "Dura %s s" % TextoHabilidade.numero(DURACAO), "Área: raio de %s, até %s de você" % [TextoHabilidade.blocos(RAIO), TextoHabilidade.blocos(hab.alcance)]]
		return l

	const RAIO := 36.0
	const DURACAO := 6.0
	const BASE := 3.0
	const POR_ESPIRITO := 0.5

	static func por_tique(quem: Player, hab: HabilidadeData) -> float:
		return (BASE + POR_ESPIRITO * quem.ficha.valor(&"espirito")) * quem.mult_habilidade(hab)

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var z := Zona.criar(quem, LogicasClerigo.ponto_na_mira(quem, alvo, hab.alcance), RAIO, DURACAO)
		z.cura = por_tique(quem, hab)
		z.efeito_visual = &"subir_nivel"
		z.escala_visual = 1.4
		z.iniciar()


## Elo vital: liga o Clérigo ao aliado na mira; os dois dividem o dano e toda cura vale
## para os dois (PassivasClerigo.dano_recebido e .curou).
class EloVital extends HabilidadeLogica:
	## Linhas de efeito da janelinha da habilidade (TextoHabilidade).
	func textos(hab: HabilidadeData, ficha: Ficha) -> Array[String]:
		var l: Array[String] = ["Cada um toma %s%% do dano" % TextoHabilidade.numero(PassivasClerigo.ELO_FRACAO * 100.0), "A cura de um vale para os dois", "Dura %s s; aliado a até %s" % [TextoHabilidade.numero(DURACAO), TextoHabilidade.blocos(LogicasClerigo.ALCANCE_ALIADO)]]
		return l

	const DURACAO := 12.0

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var aliado := LogicasClerigo.aliado_na_mira(quem, alvo)
		if aliado == null:
			quem.avisar("Nenhum aliado perto para ligar o Elo vital.")
			return
		PassivasClerigo.ligar_elo(quem, aliado, DURACAO * quem.mult_habilidade(hab))
		for j in [quem, aliado]:
			World.efeito_todos(j, &"subir_nivel", j.global_position + Vector2(0, -14))
		quem.avisar("Elo vital com outro jogador: vocês dividem o dano.")


## Levantar: levanta ali mesmo o aliado CAÍDO perto (o mais perto da mira), com parte da
## vida e protegido por um tempo; a tela de morte dele fecha (Player.levantar).
class Levantar extends HabilidadeLogica:
	## Linhas de efeito da janelinha da habilidade (TextoHabilidade).
	func textos(hab: HabilidadeData, ficha: Ficha) -> Array[String]:
		var l: Array[String] = ["Aliado caído a até %s" % TextoHabilidade.blocos(ALCANCE_ALIADO),
			"Volta com %d%% da vida" % roundi(VIDA * 100.0), "Fica protegido por %s s" % TextoHabilidade.numero(PROTECAO)]
		return l

	const PROTECAO := 2.0
	const VIDA := 0.5

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var caido := LogicasClerigo.caido_na_mira(quem, alvo)
		if caido == null:
			quem.avisar("Nenhum aliado caído perto.")
			return
		if caido.levantar(caido.global_position, VIDA, PROTECAO * quem.mult_habilidade(hab)):
			World.efeito_todos(caido, &"subir_nivel", caido.global_position + Vector2(0, -14))
			caido.avisar("Um Clérigo levantou você!", &"subir_nivel")


## Fonte da vida (suprema): área grande em volta do Clérigo que cura todos e limpa os
## efeitos ruins a cada segundo, por 8 s.
class FonteDaVida extends HabilidadeLogica:
	## Linhas de efeito da janelinha da habilidade (TextoHabilidade).
	func textos(hab: HabilidadeData, ficha: Ficha) -> Array[String]:
		var l: Array[String] = ["Cura %s por segundo (%s + %s por ponto de Espírito)" % [TextoHabilidade.numero(BASE + POR_ESPIRITO * (ficha.valor(&"espirito") if ficha else 5)), TextoHabilidade.numero(BASE), TextoHabilidade.numero(POR_ESPIRITO)], "Limpa os efeitos ruins", "Dura %s s; raio de %s" % [TextoHabilidade.numero(DURACAO), TextoHabilidade.blocos(RAIO)]]
		return l

	const RAIO := 72.0
	const DURACAO := 8.0
	const BASE := 5.0
	const POR_ESPIRITO := 0.5

	static func por_tique(quem: Player, hab: HabilidadeData) -> float:
		return (BASE + POR_ESPIRITO * quem.ficha.valor(&"espirito")) * quem.mult_habilidade(hab)

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var z := Zona.criar(quem, quem.global_position, RAIO, DURACAO)
		z.cura = por_tique(quem, hab)
		z.efeito_visual = &"subir_nivel"
		z.escala_visual = 2.6
		z.ao_tique = func(_z: Zona, _i: Array[Node2D], jogadores: Array[Player]) -> void:
			for j in jogadores:
				j.efeitos.limpar_ruins()
		z.iniciar()


# --- Protetor --------------------------------------------------------------------------

## Barreira: uma parede de luz na frente do Clérigo, de lado para a mira, por 6 s. Os
## inimigos não passam (são empurrados para o lado de onde vieram) e os projéteis que não
## são de jogadores somem nela.
class Barreira extends HabilidadeLogica:
	## Linhas de efeito da janelinha da habilidade (TextoHabilidade).
	func textos(hab: HabilidadeData, ficha: Ficha) -> Array[String]:
		var l: Array[String] = ["Parede de %s na sua frente" % TextoHabilidade.blocos(COMPRIMENTO), "Inimigos e projéteis inimigos não passam", "Dura %s s" % TextoHabilidade.numero(DURACAO)]
		return l

	const DURACAO := 6.0
	const DISTANCIA := 28.0  # da parede até o Clérigo
	const COMPRIMENTO := 64.0
	const GROSSURA := 10.0
	const PEDACOS := 5  # escudos de luz ao longo da parede

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var centro := quem.global_position + dir * DISTANCIA
		var lado := dir.orthogonal()
		var a := centro - lado * COMPRIMENTO / 2.0
		var b := centro + lado * COMPRIMENTO / 2.0
		var segundos := DURACAO * quem.mult_habilidade(hab)
		var z := Zona.criar(quem, centro, COMPRIMENTO / 2.0 + GROSSURA, segundos, 0.05)
		z.ao_tique = func(zona: Zona, inimigos: Array[Node2D], _j: Array[Player]) -> void:
			for e in inimigos:
				var ponto := Geometry2D.get_closest_point_to_segment(e.global_position, a, b)
				var fora := e.global_position - ponto
				if fora.length() < GROSSURA:
					# Volta para o lado da parede em que estava (o lado da frente, se em cima).
					var sentido := fora.normalized() if fora.length() > 0.5 else dir
					var e2 := EfeitosEstado.de(e)
					if e2:
						e2.empurrar(sentido * (GROSSURA + 2.0 - fora.length()), 0.05)
		# Os projéteis inimigos param na parede (Projetil.bloqueado).
		z.add_to_group(&"bloqueia_projeteis")
		z.set_meta(&"bloqueio_segmento", [a, b, GROSSURA])
		z.iniciar()
		for k in PEDACOS:
			World.efeito_laco_todos(quem, &"escudo", a.lerp(b, k / float(PEDACOS - 1)), segundos)


## Santuário: área em volta do Clérigo onde os inimigos não conseguem entrar por 4 s (quem
## está dentro é empurrado para a borda).
class Santuario extends HabilidadeLogica:
	## Linhas de efeito da janelinha da habilidade (TextoHabilidade).
	func textos(hab: HabilidadeData, ficha: Ficha) -> Array[String]:
		var l: Array[String] = ["Inimigos não entram num raio de %s" % TextoHabilidade.blocos(RAIO), "Dura %s s" % TextoHabilidade.numero(DURACAO)]
		return l

	const RAIO := 48.0
	const DURACAO := 4.0

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var z := Zona.criar(quem, quem.global_position, RAIO, DURACAO * quem.mult_habilidade(hab), 0.05)
		z.efeito_visual = &"escudo"
		z.escala_visual = 3.2
		z.ao_tique = func(zona: Zona, inimigos: Array[Node2D], _j: Array[Player]) -> void:
			for e in inimigos:
				var v := e.global_position - zona.global_position
				var sentido := v.normalized() if v.length() > 0.5 else Vector2.RIGHT
				var e2 := EfeitosEstado.de(e)
				if e2:
					e2.empurrar(sentido * (RAIO + 4.0 - v.length()), 0.05)
		z.iniciar()


## Intervenção: o aliado na mira (ou o próprio Clérigo, sem aliado perto) fica intocável por 2 s.
class Intervencao extends HabilidadeLogica:
	## Linhas de efeito da janelinha da habilidade (TextoHabilidade).
	func textos(hab: HabilidadeData, ficha: Ficha) -> Array[String]:
		var l: Array[String] = ["Não toma dano por %s s" % TextoHabilidade.numero(DURACAO), "Aliado na mira, a até %s (sem aliado: você)" % TextoHabilidade.blocos(LogicasClerigo.ALCANCE_ALIADO)]
		return l

	const DURACAO := 2.0

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var aliado := LogicasClerigo.aliado_na_mira(quem, alvo)
		if aliado == null:
			aliado = quem
		var segundos := DURACAO * quem.mult_habilidade(hab)
		aliado.vida.proteger(segundos)
		World.efeito_preso_todos(aliado, &"escudo", segundos, Vector2(0, -9))


## Muralha da fé (suprema): uma cúpula grande em volta do Clérigo; quem está dentro não
## toma dano por 4 s.
class MuralhaDaFe extends HabilidadeLogica:
	## Linhas de efeito da janelinha da habilidade (TextoHabilidade).
	func textos(hab: HabilidadeData, ficha: Ficha) -> Array[String]:
		var l: Array[String] = ["Ninguém dentro toma dano", "Dura %s s; raio de %s" % [TextoHabilidade.numero(DURACAO), TextoHabilidade.blocos(RAIO)]]
		return l

	const RAIO := 64.0
	const DURACAO := 4.0

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var z := Zona.criar(quem, quem.global_position, RAIO, DURACAO * quem.mult_habilidade(hab), 0.1)
		z.efeito_visual = &"escudo"
		z.escala_visual = 4.4
		z.ao_tique = func(_z: Zona, _i: Array[Node2D], jogadores: Array[Player]) -> void:
			for j in jogadores:
				j.vida.proteger(0.2)  # renovada a cada tique enquanto estiver dentro
		z.iniciar()


# --- Inquisidor ------------------------------------------------------------------------

## Coluna de luz: depois de um instante, um raio de luz cai do céu no ponto da mira.
class ColunaDeLuz extends HabilidadeLogica:
	## Linhas de efeito da janelinha da habilidade (TextoHabilidade).
	func textos(hab: HabilidadeData, ficha: Ficha) -> Array[String]:
		var l: Array[String] = ["Cai após %s s no ponto do mouse (até %s)" % [TextoHabilidade.numero(ATRASO), TextoHabilidade.blocos(hab.alcance)], "Área: raio de %s" % TextoHabilidade.blocos(RAIO)]
		return l

	const ATRASO := 0.35
	const RAIO := 20.0

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var ponto := LogicasClerigo.ponto_na_mira(quem, alvo, hab.alcance)
		var dano := dano_de(quem, hab)
		World.efeito_todos(quem, &"subir_nivel", ponto)
		quem.get_tree().create_timer(ATRASO).timeout.connect(func() -> void:
			if not is_instance_valid(quem):
				return
			World.efeito_todos(quem, &"raio", ponto)
			for e in Golpes.inimigos_em_volta(quem, ponto, RAIO):
				Golpes.acertar(quem, e, dano, &"luz"))


## Martelo giratório: um martelo de luz gira em volta do Clérigo por 5 s, acertando quem
## estiver perto a cada meio segundo.
class MarteloGiratorio extends HabilidadeLogica:
	## Linhas de efeito da janelinha da habilidade (TextoHabilidade).
	func textos(hab: HabilidadeData, ficha: Ficha) -> Array[String]:
		var l: Array[String] = ["Acerta a cada %s s num raio de %s" % [TextoHabilidade.numero(INTERVALO), TextoHabilidade.blocos(RAIO)], "Dura %s s" % TextoHabilidade.numero(DURACAO)]
		return l

	const RAIO := 28.0
	const DURACAO := 5.0
	const INTERVALO := 0.5

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var z := Zona.criar(quem, quem.global_position, RAIO, DURACAO, INTERVALO)
		z.seguir = quem
		z.dano = dano_de(quem, hab)
		z.elemento = &"luz"
		z.efeito_tique = &"giro"
		z.iniciar()


## Aurora: um cone de luz na direção da mira. Derrete os slimes da noite e Cega os outros.
class Aurora extends HabilidadeLogica:
	## Linhas de efeito da janelinha da habilidade (TextoHabilidade).
	func textos(hab: HabilidadeData, ficha: Ficha) -> Array[String]:
		var l: Array[String] = ["Cone de %s na sua frente" % TextoHabilidade.blocos(ALCANCE), "Slimes da noite derretem", "Cega os outros por %s s" % TextoHabilidade.numero(CEGO)]
		return l

	const ALCANCE := 72.0
	const ABERTURA := deg_to_rad(35.0)  # para cada lado
	const CEGO := 3.0

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var de := quem.global_position
		var dano := dano_de(quem, hab)
		for e in Golpes.inimigos_em_volta(quem, de, ALCANCE * Passivas.alcance(quem)):
			var v := e.global_position - de
			if v.length() > 4.0 and absf(dir.angle_to(v)) > ABERTURA:
				continue
			if LogicasClerigo.noturno(e):
				LogicasClerigo.derreter(quem, e)
			else:
				Golpes.acertar(quem, e, dano, &"luz", EfeitosEstado.CEGO, CEGO)
		for k in 3:
			World.efeito_todos(quem, &"subir_nivel", de + dir * (20.0 + 22.0 * k) + Vector2(0, -6))


## Amanhecer (suprema): por 10 s, a área em volta do Clérigo vira dia. A luz dele cresce
## (vale como a da fogueira: os slimes da noite fogem dela) e os slimes da noite que
## ficarem dentro derretem.
class Amanhecer extends HabilidadeLogica:
	## Linhas de efeito da janelinha da habilidade (TextoHabilidade).
	func textos(hab: HabilidadeData, ficha: Ficha) -> Array[String]:
		var l: Array[String] = ["Vira dia num raio de %s em volta de você" % TextoHabilidade.blocos(RAIO), "Slimes da noite fogem da luz e derretem nela", "Aliados dentro recuperam %s de vida por segundo" % TextoHabilidade.numero(CURA), "Dura %s s" % TextoHabilidade.numero(DURACAO)]
		return l

	const RAIO := 96.0
	const DURACAO := 10.0
	const CURA := 1.0  # por segundo, nos jogadores dentro

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var segundos := DURACAO * quem.mult_habilidade(hab)
		var z := Zona.criar(quem, quem.global_position, RAIO, segundos)
		z.seguir = quem
		z.cura = CURA  # os aliados se curam na luz
		z.set_meta(&"raio_luz", RAIO)
		z.add_to_group(&"luz_protege")  # World.luz_que_protege: igual à fogueira
		z.ao_tique = func(_z: Zona, inimigos: Array[Node2D], _j: Array[Player]) -> void:
			for e in inimigos:
				if LogicasClerigo.noturno(e):
					LogicasClerigo.derreter(quem, e)
		z.iniciar()
		quem.clarear(segundos, RAIO)
		World.efeito_todos(quem, &"subir_nivel", quem.global_position + Vector2(0, -14))
