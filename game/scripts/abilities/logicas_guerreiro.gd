class_name LogicasGuerreiro
extends RefCounted
## Lógicas das habilidades novas do Guerreiro (árvore de habilidades).
## Cada `class Nome extends HabilidadeLogica` escrita aqui já fica registrada em
## Logicas.criar: basta pôr `logica = &"Nome"` no .tres da habilidade (o nome não pode
## repetir o de outro arquivo). Peças prontas (zona, invocação, projéteis especiais,
## corrente, avanço, buffs, estados): ver design/habilidades_base.md.
##
## Tudo roda no ANFITRIÃO. As melhorias valem pelo `dano_de` (dano) e pela recarga; nas
## habilidades sem dano, a força do efeito também cresce com `quem.mult_habilidade(hab)`.

const ESCUDO := preload("res://scenes/abilities/adaga.tscn")  # placeholder: falta a arte do escudo
const CORRENTE := preload("res://scenes/abilities/adaga.tscn")  # placeholder: falta a arte da corrente


## Ponto da mira limitado ao alcance da habilidade.
static func ponto_no_alcance(quem: Player, alvo: Vector2, alcance: float) -> Vector2:
	var de := quem.global_position
	return de + (alvo - de).limit_length(alcance)


## Iniciais: Medo nos inimigos em volta e +10% de dano nos aliados por 6 s.
class GritoDeGuerra extends HabilidadeLogica:
	const RAIO_MEDO := 48.0
	const MEDO := 1.5
	const RAIO_ALIADOS := 80.0
	const BONUS := 0.10
	const DURACAO := 6.0

	func linhas_efeito(_hab: HabilidadeData) -> Array[String]:
		return ["Medo por %s s nos inimigos num raio de %s" % [TextoHabilidade.numero(MEDO), TextoHabilidade.blocos(RAIO_MEDO)],
				"Dano: +%s%% para você e aliados num raio de %s" % [TextoHabilidade.numero(BONUS * 100.0), TextoHabilidade.blocos(RAIO_ALIADOS)],
				"O bônus dura %s s" % TextoHabilidade.numero(DURACAO)]

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		Golpes.estado_em_volta(quem, quem.global_position, RAIO_MEDO, EfeitosEstado.MEDO, MEDO)
		Golpes.buff_em_volta(quem, RAIO_ALIADOS, Buffs.DANO, BONUS * quem.mult_habilidade(hab), DURACAO)
		World.efeito_todos(quem, &"furia", quem.global_position)


## Guardião: o escudo voa, quica em até 3 inimigos e atordoa cada um por 0,5 s.
class EscudoArremessado extends HabilidadeLogica:
	const QUIQUES := 2  # acerta o primeiro e quica em mais 2
	const RAIO_QUIQUE := 64.0
	const ATORDOAR := 0.5

	func linhas_efeito(_hab: HabilidadeData) -> Array[String]:
		return ["Quica em até %d inimigos (até %s entre um e outro)" % [QUIQUES + 1, TextoHabilidade.blocos(RAIO_QUIQUE)],
				"Atordoa cada um por %s s" % TextoHabilidade.numero(ATORDOAR)]

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var p := Logicas.lancar(LogicasGuerreiro.ESCUDO, quem, dir, dano_de(quem, hab))
		p.quiques = QUIQUES
		p.raio_quique = RAIO_QUIQUE
		p.estado = EfeitosEstado.ATORDOADO
		p.estado_segundos = ATORDOAR
		p.acertou.connect(func(_a: Node, pos: Vector2) -> void:
			if is_instance_valid(quem):
				World.efeito_todos(quem, &"poeira", pos))


## Guardião: todos os inimigos em volta perseguem só o guerreiro por 4 s.
class Provocar extends HabilidadeLogica:
	const RAIO := 64.0
	const DURACAO := 4.0

	func linhas_efeito(_hab: HabilidadeData) -> Array[String]:
		return ["Inimigos num raio de %s perseguem só você" % TextoHabilidade.blocos(RAIO), "Dura %s s" % TextoHabilidade.numero(DURACAO)]

	func executar(quem: Player, _hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		Golpes.estado_em_volta(quem, quem.global_position, RAIO, EfeitosEstado.PROVOCADO, DURACAO)
		World.efeito_todos(quem, &"furia", quem.global_position)


## Guardião: cúpula no chão por 5 s. Os aliados dentro tomam 50% menos dano e os inimigos
## que entram são empurrados para fora.
class Bastiao extends HabilidadeLogica:
	const RAIO := 40.0
	const DURACAO := 5.0
	const REDUCAO := 0.5
	const REDUCAO_MAXIMA := 0.8
	const EMPURRAO := 24.0

	func linhas_efeito(_hab: HabilidadeData) -> Array[String]:
		return ["Cúpula com raio de %s por %s s" % [TextoHabilidade.blocos(RAIO), TextoHabilidade.numero(DURACAO)],
				"Dentro: dano recebido -%s%%" % TextoHabilidade.numero(REDUCAO * 100.0),
				"Empurra os inimigos para fora"]

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var z := Zona.criar(quem, quem.global_position, RAIO, DURACAO, 0.25)
		z.buff = Buffs.REDUCAO
		z.buff_valor = minf(REDUCAO_MAXIMA, REDUCAO * quem.mult_habilidade(hab))
		z.buff_segundos = 0.4
		z.efeito_visual = &"escudo"
		z.escala_visual = 3.0
		z.ao_tique = func(zona: Zona, inimigos: Array[Node2D], _j: Array[Player]) -> void:
			for e in inimigos:
				if is_instance_valid(e):
					Golpes.puxar(e, zona.global_position, -EMPURRAO, 0.15)
		z.iniciar()


## Guardião (suprema): por 8 s, metade do dano dos aliados perto vem para o guerreiro, e ele
## não cai abaixo de 1 de vida. Quem faz a conta é PassivasGuerreiro.dano_recebido.
class Juramento extends HabilidadeLogica:
	const DURACAO := 8.0

	func linhas_efeito(_hab: HabilidadeData) -> Array[String]:
		return ["%s%% do dano dos aliados num raio de %s vem para você" % [TextoHabilidade.numero(PassivasGuerreiro.JURAMENTO_PARTE * 100.0), TextoHabilidade.blocos(PassivasGuerreiro.RAIO_JURAMENTO)],
				"Você não cai abaixo de 1 de vida", "Dura %s s" % TextoHabilidade.numero(DURACAO)]

	func executar(quem: Player, _hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		quem.set_meta(PassivasGuerreiro.META_JURAMENTO, Time.get_ticks_msec() + int(DURACAO * 1000.0))
		World.efeito_preso_todos(quem, &"escudo", DURACAO, Vector2(0, -9))
		for j in Golpes.jogadores_em_volta(quem, quem.global_position, PassivasGuerreiro.RAIO_JURAMENTO):
			World.efeito_todos(j, &"subir_nivel", j.global_position + Vector2(0, -14))


## Berserker: golpe pesado na frente. Acerta os inimigos ali e derruba de uma vez as árvores
## e as pedras (o que elas rendem vai para a mochila, como se tivesse coletado).
class Machadada extends HabilidadeLogica:
	const DISTANCIA := 16.0
	const RAIO := 24.0

	func linhas_efeito(_hab: HabilidadeData) -> Array[String]:
		return ["Área na frente: raio de %s" % TextoHabilidade.blocos(RAIO), "Derruba árvore e quebra pedra num golpe só"]

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var centro := quem.global_position + dir * DISTANCIA
		var dano := dano_de(quem, hab)
		for e in Golpes.inimigos_em_volta(quem, centro, RAIO):
			Golpes.acertar(quem, e, dano, &"fisico")
		for n in quem.get_tree().get_nodes_in_group(&"recursos"):
			var r := n as ResourceNode
			if r == null or r.is_queued_for_deletion() or r.global_position.distance_to(centro) > RAIO:
				continue
			var vezes := 0
			while is_instance_valid(r) and not r.is_queued_for_deletion() and r.pode_interagir() and vezes <= r.golpes:
				r.interagir(quem)
				vezes += 1
		World.efeito_todos(quem, &"giro", centro + Vector2(0, -8))
		World.efeito_todos(quem, &"poeira", centro)


## Berserker: pula até a mira; ao cair, a onda de choque machuca e derruba os inimigos em volta.
class SaltoEsmagador extends HabilidadeLogica:
	const DURACAO_PULO := 0.3
	const RAIO := 36.0
	const DERRUBAR := 1.0

	func linhas_efeito(hab: HabilidadeData) -> Array[String]:
		return ["Pula até %s" % TextoHabilidade.blocos(hab.alcance), "Na queda: área de raio %s" % TextoHabilidade.blocos(RAIO),
				"Derruba os inimigos por %s s" % TextoHabilidade.numero(DERRUBAR)]

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var destino := LogicasGuerreiro.ponto_no_alcance(quem, alvo, hab.alcance)
		var dano := dano_de(quem, hab)
		World.efeito_todos(quem, &"poeira", quem.global_position)
		quem.vida.proteger(DURACAO_PULO + 0.1)
		quem.mover_por_habilidade(destino - quem.global_position, DURACAO_PULO)
		quem.get_tree().create_timer(DURACAO_PULO + 0.05, false, true).timeout.connect(func() -> void:
			if not is_instance_valid(quem):
				return
			var onde := quem.global_position
			for e in Golpes.inimigos_em_volta(quem, onde, RAIO):
				Golpes.acertar(quem, e, dano, &"fisico", EfeitosEstado.DERRUBADO, DERRUBAR)
			World.efeito_todos(quem, &"poeira", onde)
			World.efeito_todos(quem, &"giro", onde + Vector2(0, -8)))


## Berserker: gira por 3 s enquanto anda, acertando tudo em volta a cada 0,5 s.
class Redemoinho extends HabilidadeLogica:
	const RAIO := 26.0
	const DURACAO := 3.0
	const INTERVALO := 0.5

	func linhas_efeito(_hab: HabilidadeData) -> Array[String]:
		return ["Área em volta: raio de %s" % TextoHabilidade.blocos(RAIO), "Acerta a cada %s s por %s s, andando" % [TextoHabilidade.numero(INTERVALO), TextoHabilidade.numero(DURACAO)]]

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		# Folga de um quadro: o tique dos 3 s não se perde no arredondamento do relógio.
		var z := Zona.criar(quem, quem.global_position, RAIO, DURACAO + 0.05, INTERVALO)
		z.seguir = quem
		z.dano = dano_de(quem, hab)
		z.elemento = &"fisico"
		z.efeito_tique = &"giro"
		z.iniciar()


## Berserker (suprema): por 10 s o guerreiro cresce, não é empurrado e todo golpe físico
## também acerta quem está em volta do alvo (PassivasGuerreiro.acertou).
class FuriaTitanica extends HabilidadeLogica:
	const DURACAO := 10.0
	const TAMANHO := 1.35

	func linhas_efeito(_hab: HabilidadeData) -> Array[String]:
		return ["Não é empurrado", "Golpe físico: %s%% do dano em quem está a até %s do alvo" % [TextoHabilidade.numero(PassivasGuerreiro.TITANICA_DANO * 100.0), TextoHabilidade.blocos(PassivasGuerreiro.TITANICA_RAIO)],
				"Dura %s s" % TextoHabilidade.numero(DURACAO)]

	func executar(quem: Player, _hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		quem.set_meta(PassivasGuerreiro.META_TITANICA, Time.get_ticks_msec() + int(DURACAO * 1000.0))
		quem.crescer(TAMANHO, DURACAO)
		World.efeito_todos(quem, &"furia", quem.global_position)
		World.efeito_preso_todos(quem, &"furia", DURACAO)


## Senhor da Guerra: bandeira na mira por 8 s. Os aliados na área dão +15% de dano e
## recuperam 2 de vida por segundo.
class Estandarte extends HabilidadeLogica:
	const RAIO := 48.0
	const DURACAO := 8.0
	const BONUS := 0.15
	const CURA := 2.0

	func linhas_efeito(hab: HabilidadeData) -> Array[String]:
		return ["Alcance: %s; área de raio %s por %s s" % [TextoHabilidade.blocos(hab.alcance), TextoHabilidade.blocos(RAIO), TextoHabilidade.numero(DURACAO)],
				"Aliados na área: dano +%s%%" % TextoHabilidade.numero(BONUS * 100.0), "Recuperam %s de vida por segundo" % TextoHabilidade.numero(CURA)]

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var ponto := LogicasGuerreiro.ponto_no_alcance(quem, alvo, hab.alcance)
		var m := quem.mult_habilidade(hab)
		var z := Zona.criar(quem, ponto, RAIO, DURACAO)
		z.buff = Buffs.DANO
		z.buff_valor = BONUS * m
		z.buff_segundos = 1.2
		z.cura = CURA * m
		z.efeito_visual = &"subir_nivel"  # placeholder: falta a arte da bandeira
		z.escala_visual = 1.2
		z.iniciar()


## Senhor da Guerra: lança uma corrente; o primeiro inimigo que ela pega é puxado até você.
class Corrente extends HabilidadeLogica:
	const PUXA := 120.0
	const DURACAO := 0.7

	func linhas_efeito(_hab: HabilidadeData) -> Array[String]:
		return ["Puxa o primeiro inimigo até você (até %s)" % TextoHabilidade.blocos(PUXA)]

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var p := Logicas.lancar(LogicasGuerreiro.CORRENTE, quem, dir, dano_de(quem, hab))
		p.duracao = DURACAO
		p.puxa = PUXA
		p.acertou.connect(func(_a: Node, pos: Vector2) -> void:
			if is_instance_valid(quem):
				World.efeito_todos(quem, &"poeira", pos))


## Senhor da Guerra: marca o inimigo na mira por 8 s; todo mundo dá +30% de dano nele.
class OrdemDeAtaque extends HabilidadeLogica:
	const RAIO_MIRA := 40.0
	const DURACAO := 8.0
	const BONUS := 0.30

	func linhas_efeito(hab: HabilidadeData) -> Array[String]:
		return ["Alcance: %s" % TextoHabilidade.blocos(hab.alcance), "Todos dão +%s%% de dano no marcado" % TextoHabilidade.numero(BONUS * 100.0), "Dura %s s" % TextoHabilidade.numero(DURACAO)]

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var e := Logicas.inimigo_na_mira(quem, alvo, hab.alcance, RAIO_MIRA)
		if e == null:
			quem.avisar("Nenhum inimigo na mira.")
			return
		EfeitosEstado.aplicar_em(e, EfeitosEstado.MARCADO, DURACAO, BONUS * quem.mult_habilidade(hab), quem)
		World.efeito_todos(quem, &"subir_nivel", e.global_position + Vector2(0, -10))


## Senhor da Guerra (suprema): você e os aliados perto avançam juntos na direção da mira,
## atravessando (e machucando) os inimigos no caminho.
class Avancar extends HabilidadeLogica:
	const RAIO_ALIADOS := 80.0
	const LARGURA := 14.0

	func linhas_efeito(hab: HabilidadeData) -> Array[String]:
		return ["Avança %s com os aliados num raio de %s" % [TextoHabilidade.blocos(hab.alcance), TextoHabilidade.blocos(RAIO_ALIADOS)], "Acerta tudo no caminho de cada um"]

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var dano := dano_de(quem, hab)
		for j in Golpes.jogadores_em_volta(quem, quem.global_position, RAIO_ALIADOS):
			if not j.vida.esta_vivo():
				continue
			j.vida.proteger(0.4)
			Golpes.avancar(j, j.global_position + dir * hab.alcance, hab.alcance, dano, &"fisico", LARGURA)
		World.efeito_todos(quem, &"furia", quem.global_position)
