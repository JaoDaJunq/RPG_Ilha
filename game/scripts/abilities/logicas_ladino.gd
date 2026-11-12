class_name LogicasLadino
extends RefCounted
## Lógicas das habilidades novas do Ladino (árvore de habilidades).
## Cada `class Nome extends HabilidadeLogica` escrita aqui já fica registrada em
## Logicas.criar: basta pôr `logica = &"Nome"` no .tres da habilidade (o nome não pode
## repetir o de outro arquivo). Peças prontas (zona, invocação, projéteis especiais,
## corrente, avanço, buffs, estados): ver design/habilidades_base.md.
## Tudo aqui roda no ANFITRIÃO.

const RAIO_MIRA := 32.0


## Ponto no chão onde o mouse está, limitado ao alcance da habilidade.
static func ponto_na_mira(quem: Player, hab: HabilidadeData, alvo: Vector2) -> Vector2:
	var de := quem.global_position
	return de + (alvo - de).limit_length(hab.alcance)


## Para onde o alvo olha (o mesmo jeito de Passivas.pelas_costas: anda → direção do passo;
## parado → o lado do desenho).
static func frente_de(alvo: Node2D) -> Vector2:
	var corpo := alvo as CharacterBody2D
	if corpo and corpo.velocity.length() > 2.0:
		return corpo.velocity.normalized()
	var desenho := alvo.get_node_or_null("Visual") as AnimatedSprite2D
	if desenho:
		return Vector2.LEFT if desenho.flip_h else Vector2.RIGHT
	return Vector2.RIGHT


# --- Sombra ---------------------------------------------------------------------------

## Sumir: Invisível por 4 s; o primeiro acerto do ladino quebra (PassivasLadino.acertou).
class Sumir extends HabilidadeLogica:
	const DURACAO := 4.0

	func textos(_hab: HabilidadeData) -> Array[String]:
		return ["Invisível por %s s: os inimigos perdem você de vista" % TextoHabilidade.numero(DURACAO), "Acertar um golpe quebra o efeito"]

	func executar(quem: Player, _hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		quem.efeitos.aplicar(EfeitosEstado.INVISIVEL, DURACAO, 0.0, quem)
		quem.set_meta(&"sumindo", true)
		World.efeito_todos(quem, &"poeira", quem.global_position)


## Passo das sombras: teleporta para as costas do inimigo na mira e golpeia (vale o
## Pelas costas).
class PassoDasSombras extends HabilidadeLogica:
	const ATRAS := 12.0  # px atrás do alvo

	func textos(hab: HabilidadeData) -> Array[String]:
		return ["Teleporta para as costas do inimigo (alcance: %s)" % TextoHabilidade.blocos(hab.alcance), "O golpe vale o Pelas costas (+%s%%)" % TextoHabilidade.numero((Passivas.PELAS_COSTAS - 1.0) * 100.0)]

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var inimigo := Logicas.inimigo_na_mira(quem, alvo, hab.alcance, LogicasLadino.RAIO_MIRA)
		if inimigo == null:
			quem.avisar("Nenhum inimigo na mira.")
			return
		var destino := inimigo.global_position - LogicasLadino.frente_de(inimigo) * ATRAS
		World.efeito_todos(quem, &"poeira", quem.global_position)
		quem.vida.proteger(0.2)
		var antes := quem.global_position
		if not quem.eh_local():
			quem.mover_por_habilidade(destino - antes, 0.05)  # quem anda é o dono
		# O golpe sai já das costas: a posição do teleporte é a que vale para o Pelas costas.
		quem.global_position = destino
		Golpes.acertar(quem, inimigo, dano_de(quem, hab), &"fisico", &"", 0.0, 0.0, &"giro")
		if is_instance_valid(inimigo):
			quem.envenenar_atingido(inimigo.get_node_or_null("Hurtbox") as Hurtbox)
		if not quem.eh_local():
			quem.global_position = antes  # a posição de verdade vem do dono
		World.efeito_todos(quem, &"poeira", destino)


## Marca da morte (finalizador): marca o inimigo por 4 s; no fim, explode com uma parte do
## dano que ele levou nesse tempo (20% + 10% por ponto de combo) mais o dano da habilidade.
class MarcaDaMorte extends HabilidadeLogica:
	const DURACAO := 4.0
	const BASE := 0.2
	const POR_PONTO := 0.1

	static func fracao(pontos: int) -> float:
		return BASE + POR_PONTO * pontos

	func textos(hab: HabilidadeData) -> Array[String]:
		return ["Finalizador: gasta os pontos de combo", "Marcado por %s s (+20%% de dano)" % TextoHabilidade.numero(DURACAO),
				"Explode com %s%% do dano levado, +%s%% por ponto (alcance: %s)" % [TextoHabilidade.numero(BASE * 100.0), TextoHabilidade.numero(POR_PONTO * 100.0), TextoHabilidade.blocos(hab.alcance)]]

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var inimigo := Logicas.inimigo_na_mira(quem, alvo, hab.alcance, LogicasLadino.RAIO_MIRA)
		if inimigo == null:
			quem.avisar("Nenhum inimigo na mira.")
			return
		var vida := inimigo.get_node_or_null("HealthComponent") as HealthComponent
		if vida == null:
			return
		var pontos := quem.recursos.gastar_combo()
		var parte := fracao(pontos)
		var base := dano_de(quem, hab)
		var levou := [0.0]
		var contar := func(qtd: float, _t: StringName) -> void: levou[0] += qtd
		vida.dano_recebido.connect(contar)
		EfeitosEstado.aplicar_em(inimigo, EfeitosEstado.MARCADO, DURACAO, 0.0, quem)
		World.efeito_todos(quem, &"giro", inimigo.global_position + Vector2(0, -8))
		quem.avisar("Marca da morte (%d pontos): explode em %d s." % [pontos, roundi(DURACAO)])
		quem.get_tree().create_timer(DURACAO, false).timeout.connect(func() -> void:
			if not is_instance_valid(inimigo) or not is_instance_valid(vida):
				return
			vida.dano_recebido.disconnect(contar)
			if not vida.esta_vivo():
				return
			var dono: Node = quem if is_instance_valid(quem) else null
			Golpes.acertar(dono, inimigo, base + levou[0] * parte, &"sombra")
			if is_instance_valid(quem):
				World.efeito_todos(quem, &"explosao", inimigo.global_position if is_instance_valid(inimigo) else Vector2.ZERO))


## Mil cortes (suprema): intocável enquanto golpeia 8 vezes todos os inimigos em volta.
class MilCortes extends HabilidadeLogica:
	const GOLPES := 8
	const INTERVALO := 0.2
	const RAIO := 44.0

	func textos(hab: HabilidadeData) -> Array[String]:
		return ["%d golpes em %s s, em tudo num raio de %s" % [GOLPES, TextoHabilidade.numero(GOLPES * INTERVALO), TextoHabilidade.blocos(RAIO)],
				"Intocável por %s s" % TextoHabilidade.numero(GOLPES * INTERVALO + 0.2), "Dano por golpe: %s" % TextoHabilidade.numero(hab.dano)]

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var dano := dano_de(quem, hab)
		quem.vida.proteger(GOLPES * INTERVALO + 0.2)
		var relogio := Timer.new()
		relogio.wait_time = INTERVALO
		var feitos := [0]
		var golpe := func() -> void:
			if not quem.vida.esta_vivo() or feitos[0] >= GOLPES:
				relogio.queue_free()
				return
			feitos[0] += 1
			for e in Golpes.inimigos_em_volta(quem, quem.global_position, RAIO):
				# Cada corte conta (sem a proteção de 0,15 s que o inimigo ganha a cada golpe).
				var v := e.get_node_or_null("HealthComponent") as HealthComponent
				if v:
					v.tirar_protecao()
				Golpes.acertar(quem, e, dano, &"fisico")
			World.efeito_todos(quem, &"giro", quem.global_position + Vector2(0, -8))
		relogio.timeout.connect(golpe)
		quem.add_child(relogio)
		relogio.start()
		golpe.call()


# --- Venenos --------------------------------------------------------------------------

## Frasco de ácido: uma poça por 5 s no ponto da mira. Corrói (dano químico por segundo) e
## deixa quem está dentro Marcado (+20% de dano de todo mundo).
class FrascoDeAcido extends HabilidadeLogica:
	const RAIO := 28.0
	const DURACAO := 5.0
	const MARCA := 0.2

	func textos(hab: HabilidadeData) -> Array[String]:
		return ["Poça por %s s, raio de %s (alcance: %s)" % [TextoHabilidade.numero(DURACAO), TextoHabilidade.blocos(RAIO), TextoHabilidade.blocos(hab.alcance)],
				"Quem está dentro toma +%s%% de dano" % TextoHabilidade.numero(MARCA * 100.0)]

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var z := Zona.criar(quem, LogicasLadino.ponto_na_mira(quem, hab, alvo), RAIO, DURACAO)
		z.dano = dano_de(quem, hab)
		z.elemento = &"quimico"
		z.estado = EfeitosEstado.MARCADO
		z.estado_forca = MARCA
		z.estado_segundos = 1.2
		z.efeito_visual = &"poeira"
		z.escala_visual = 3.0  # a poeira (16 px) do tamanho da poça
		z.iniciar()


## Nuvem tóxica: 6 s envenenando quem está dentro. Inflamável: se fogo chegar nela (projétil
## de fogo ou inimigo queimando dentro), explode com dano de fogo em volta e some.
class NuvemToxica extends HabilidadeLogica:
	const RAIO := 32.0
	const DURACAO := 6.0
	const EXPLOSAO := 4.0  # vezes o dano do veneno
	const RAIO_EXPLOSAO := 44.0

	func textos(hab: HabilidadeData) -> Array[String]:
		return ["Nuvem por %s s, raio de %s (alcance: %s)" % [TextoHabilidade.numero(DURACAO), TextoHabilidade.blocos(RAIO), TextoHabilidade.blocos(hab.alcance)],
				"Envenena quem está dentro", "Inflamável: com fogo, explode (%sx o veneno, em fogo)" % TextoHabilidade.numero(EXPLOSAO)]

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var z := Zona.criar(quem, LogicasLadino.ponto_na_mira(quem, hab, alvo), RAIO, DURACAO)
		var veneno := dano_de(quem, hab)
		z.estado = EfeitosEstado.VENENO
		z.estado_forca = veneno
		z.estado_segundos = Player.TEMPO_VENENO
		z.efeito_visual = &"poeira"
		z.escala_visual = 3.6  # a poeira (16 px) do tamanho da nuvem
		z.set_meta(&"nuvem_toxica", true)
		z.iniciar()
		# Confere o fogo a cada 0,1 s (um projétil passa rápido; o tique da zona é de 1 s).
		var relogio := Timer.new()
		relogio.wait_time = 0.1
		relogio.autostart = true
		z.add_child(relogio)
		relogio.timeout.connect(func() -> void:
			if LogicasLadino.fogo_perto(z):
				LogicasLadino.explodir_nuvem(z, quem, veneno * EXPLOSAO))


## Veneno paralisante (finalizador): golpe no inimigo da mira que fica Atordoado 1 s por
## acúmulo de Veneno (até 5 s); o dano cresce com os pontos de combo.
class VenenoParalisante extends HabilidadeLogica:
	const POR_PONTO := 0.5  # +50% de dano por ponto de combo

	func textos(hab: HabilidadeData) -> Array[String]:
		return ["Finalizador: +%s%% de dano por ponto de combo" % TextoHabilidade.numero(POR_PONTO * 100.0),
				"Envenenado: Atordoado 1 s por acúmulo", "Alcance: %s" % TextoHabilidade.blocos(hab.alcance)]

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var inimigo := Logicas.inimigo_na_mira(quem, alvo, hab.alcance, LogicasLadino.RAIO_MIRA)
		if inimigo == null:
			quem.avisar("Nenhum inimigo na mira.")
			return
		var pontos := quem.recursos.gastar_combo()
		var e := EfeitosEstado.de(inimigo)
		var acumulos := e.acumulos(EfeitosEstado.VENENO) if e else 0
		Golpes.acertar(quem, inimigo, dano_de(quem, hab) * (1.0 + POR_PONTO * pontos), &"quimico", &"", 0.0, 0.0, &"giro")
		if acumulos > 0 and is_instance_valid(inimigo):
			EfeitosEstado.aplicar_em(inimigo, EfeitosEstado.ATORDOADO, float(acumulos), 0.0, quem)
			quem.avisar("Paralisado por %d s!" % acumulos)
		elif acumulos == 0:
			quem.avisar("O alvo não estava envenenado: sem paralisia.")


## Praga (suprema): todo inimigo envenenado perto (até a borda da tela) toma de uma vez o
## veneno que ainda faltava (mais as melhorias), e o veneno acaba.
class Praga extends HabilidadeLogica:
	const RAIO := 220.0

	func textos(_hab: HabilidadeData) -> Array[String]:
		return ["Todo inimigo envenenado num raio de %s" % TextoHabilidade.blocos(RAIO), "Toma de uma vez o veneno que faltava"]

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var n := 0
		for alvo in Golpes.inimigos_em_volta(quem, quem.global_position, RAIO):
			var e := EfeitosEstado.de(alvo)
			if e == null or not e.tem(EfeitosEstado.VENENO):
				continue
			var resto := e.dano_restante(EfeitosEstado.VENENO) * quem.mult_habilidade(hab)
			e.remover(EfeitosEstado.VENENO)
			Golpes.acertar(quem, alvo, resto, &"veneno", &"", 0.0, 0.0, &"poeira")
			n += 1
		World.efeito_todos(quem, &"explosao", quem.global_position)
		quem.avisar("Praga: %d inimigos envenenados." % n if n > 0 else "Praga: ninguém envenenado por perto.")


# --- Acrobata -------------------------------------------------------------------------

## Dança das lâminas: salta entre até 4 inimigos (começando pelo da mira) e acerta cada um;
## o ladino termina ao lado do último.
class DancaDasLaminas extends HabilidadeLogica:
	const ALVOS := 4
	const SALTO := 64.0
	const COLADO := 10.0

	func textos(hab: HabilidadeData) -> Array[String]:
		return ["Salta entre até %d inimigos (alcance: %s)" % [ALVOS, TextoHabilidade.blocos(hab.alcance)], "Você termina ao lado do último"]

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var primeiro := Logicas.inimigo_na_mira(quem, alvo, hab.alcance, LogicasLadino.RAIO_MIRA)
		if primeiro == null:
			primeiro = Golpes.mais_perto(quem, quem.global_position, hab.alcance)
		if primeiro == null:
			quem.avisar("Nenhum inimigo por perto.")
			return
		World.efeito_todos(quem, &"poeira", quem.global_position)
		var feitos := Golpes.corrente(quem, primeiro, ALVOS, SALTO, dano_de(quem, hab), &"fisico", &"giro")
		var ultimo := feitos[-1]
		if is_instance_valid(ultimo):
			var para := ultimo.global_position - quem.global_position
			quem.vida.proteger(0.3)
			quem.mover_por_habilidade(para.normalized() * maxf(0.0, para.length() - COLADO), 0.08)


## Bumerangue de adaga: a adaga vai, volta para o ladino e acerta na ida e na volta.
class BumerangueDeAdaga extends HabilidadeLogica:
	func textos(_hab: HabilidadeData) -> Array[String]:
		return ["Vai e volta para você", "Acerta na ida e na volta"]

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var p := Logicas.lancar(Logicas.ADAGA, quem, dir, dano_de(quem, hab))
		p.volta = true
		p.duracao *= 0.6  # a ida é mais curta: o caminho todo fica perto do alcance da adaga
		p.girar = 18.0


## Leque giratório (finalizador): 3 adagas por ponto de combo, em círculo (mínimo 3).
class LequeGiratorio extends HabilidadeLogica:
	const POR_PONTO := 3

	static func adagas(pontos: int) -> int:
		return POR_PONTO * maxi(1, pontos)

	func textos(_hab: HabilidadeData) -> Array[String]:
		return ["Finalizador: %d adagas por ponto de combo (mínimo %d)" % [POR_PONTO, POR_PONTO], "Em círculo, em volta de você"]

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var n := adagas(quem.recursos.gastar_combo())
		var dano := dano_de(quem, hab)
		for k in n:
			Logicas.lancar(Logicas.ADAGA, quem, Vector2.RIGHT.rotated(TAU * k / n), dano)
		World.efeito_todos(quem, &"giro", quem.global_position + Vector2(0, -8))


## Tempestade de aço (suprema): por 6 s, cada dash (Shift) solta 8 adagas em volta
## (PassivasLadino.esquivou).
class TempestadeDeAco extends HabilidadeLogica:
	const DURACAO := 6.0

	func textos(_hab: HabilidadeData) -> Array[String]:
		return ["Dura %s s" % TextoHabilidade.numero(DURACAO), "Cada dash (Shift) solta %d adagas em volta" % PassivasLadino.TEMPESTADE_ADAGAS, "O dash fica pronto na hora"]

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		quem.set_meta(&"tempestade_ate_ms", Time.get_ticks_msec() + int(DURACAO * 1000.0))
		quem.set_meta(&"tempestade_dano", dano_de(quem, hab))
		quem.liberar_esquiva()  # já pode dar o primeiro dash
		World.efeito_preso_todos(quem, &"furia", DURACAO, Vector2.ZERO)
		quem.avisar("Tempestade de aço: cada dash solta adagas!")


## Solta `n` adagas em círculo em volta de `quem`.
static func adagas_em_volta(quem: Player, n: int, dano: float) -> void:
	for k in n:
		Logicas.lancar(Logicas.ADAGA, quem, Vector2.RIGHT.rotated(TAU * k / n + 0.2), dano)


## Tem fogo dentro da nuvem? Projétil de fogo (bola de fogo, bomba) ou inimigo queimando.
static func fogo_perto(z: Zona) -> bool:
	if not is_instance_valid(z) or z.is_queued_for_deletion():
		return false
	for n in z.get_tree().get_nodes_in_group(&"projeteis"):
		var pr := n as Projetil
		if pr and pr.elemento == &"fogo" and not pr.is_queued_for_deletion() and pr.global_position.distance_to(z.global_position) <= z.raio:
			return true
	for e in z.inimigos_dentro():
		var est := EfeitosEstado.de(e)
		if est and est.tem(EfeitosEstado.QUEIMADURA):
			return true
	return false


## A nuvem pega fogo: explode (dano de fogo em volta) e some.
static func explodir_nuvem(z: Zona, quem: Player, dano: float) -> void:
	if not is_instance_valid(z) or z.is_queued_for_deletion():
		return
	var dono: Node = quem if is_instance_valid(quem) else null
	for e in Golpes.inimigos_em_volta(z, z.global_position, NuvemToxica.RAIO_EXPLOSAO):
		Golpes.acertar(dono, e, dano, &"fogo")
	World.efeito_todos(z, &"explosao", z.global_position)
	z.set_meta(&"explodiu", true)
	z.queue_free()
