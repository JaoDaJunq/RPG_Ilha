class_name LogicasArqueiro
extends RefCounted
## Lógicas das habilidades novas do Arqueiro (árvore de habilidades).
## Cada `class Nome extends HabilidadeLogica` escrita aqui já fica registrada em
## Logicas.criar: basta pôr `logica = &"Nome"` no .tres da habilidade (o nome não pode
## repetir o de outro arquivo). Peças prontas (zona, invocação, projéteis especiais,
## corrente, avanço, buffs, estados): ver design/habilidades_base.md.
##
## Tudo aqui roda no ANFITRIÃO. Arte própria (pedido L33, pasta Invocacao.ARTE): o falcão
## (2 quadros batendo asa), a mina, a torre de besta e a rede (no ar e caída no alvo).

const FOLHA_ANIMAIS := "res://assets/sprites/tiny/animais/animais.png"
const OVELHA := "res://assets/tiny_swords/natureza/ovelha_parada.png"
const REDE := preload("res://scenes/abilities/rede.tscn")
## Pés no chão para as folhas de 128 px (animais, acampamento) na escala 0,25, como em Animal.
const PES := Vector2(0, -14)

## Mira: o inimigo mais perto do mouse (até este raio dele).
const RAIO_MIRA := 32.0
## Minas armadas por jogador (a mais antiga some).
const MINAS_MAXIMAS := 8


## Devolve a mana da habilidade (quando ela não achou alvo e não fez nada).
static func devolver_mana(quem: Player, hab: HabilidadeData, aviso: String) -> void:
	quem.mana = minf(quem.ficha.mana_maxima(), quem.mana + quem.custo_de(hab))
	quem._enviar_mana()
	quem.avisar(aviso)


## O alvo da mira (perto do mouse) ou, sem nada lá, o inimigo mais perto do jogador.
static func alvo_da_mira(quem: Player, mira: Vector2, alcance: float) -> Node2D:
	var a := Logicas.inimigo_na_mira(quem, mira, alcance, RAIO_MIRA)
	if a == null:
		a = Golpes.mais_perto(quem, quem.global_position, alcance)
	return a


## Ponto no chão na mira, até o alcance (com o Olho de águia).
static func ponto_no_chao(quem: Player, hab: HabilidadeData, mira: Vector2) -> Vector2:
	var de := quem.global_position
	return de + (mira - de).limit_length(hab.alcance * Passivas.alcance(quem))


## O falcão do jogador (o do Laço ou o de um Assobio), ou nulo.
static func falcao_de(quem: Player) -> Companheiro:
	for c in Companheiro.de(quem):
		if c.has_meta(&"falcao"):
			return c
	return null


## O animal domado do jogador, ou nulo.
static func domado_de(quem: Player) -> Companheiro:
	for c in Companheiro.de(quem):
		if c.has_meta(&"domado"):
			return c
	return null


## Cria um falcão (batendo asa). `segundos` 0 = fica para sempre (Laço).
static func criar_falcao(quem: Player, dano: float, segundos: float) -> Companheiro:
	var c := Companheiro.criar_companheiro(quem)
	c.set_meta(&"falcao", true)
	c.desenho(["falcao_a", "falcao_b"], 7.0, "", 12.0)  # voando, um pouco acima do chão
	c.dano = dano
	c.velocidade = 140.0
	c.alcance = 14.0
	c.intervalo = 1.0
	c.duracao = segundos
	c.distancia_dono = 16.0
	# Marca do Assobio: o próximo bico no alvo mandado deixa ele Marcado.
	c.ao_atacar = func(inv: Invocacao, alvo: Node2D) -> void:
		if inv.has_meta(&"marcar") and inv.get_meta(&"marcar") == alvo:
			inv.remove_meta(&"marcar")
			EfeitosEstado.aplicar_em(alvo, EfeitosEstado.MARCADO, Assobio.MARCA, 0.0, inv.dono)
			World.efeito_todos(inv, &"poeira", alvo.global_position)
	c.iniciar()
	c.collision_mask = 0  # voa por cima da água
	return c


## Uma mina no chão (Mina de fogo, Campo minado): explode quando um inimigo ou animal pisa,
## machuca em volta com fogo e deixa Queimadura.
static func criar_mina(quem: Player, ponto: Vector2, dano: float, custo: float) -> Invocacao:
	var minhas: Array[Node] = []
	for n in quem.get_tree().get_nodes_in_group(&"minas"):
		if (n as Invocacao).dono == quem and not n.is_queued_for_deletion():
			minhas.append(n)
	if minhas.size() >= MINAS_MAXIMAS:
		minhas[0].queue_free()
	var m := Invocacao.criar(quem, ponto)
	m.desenho(["mina"])
	m.duracao = MinaDeFogo.DURACAO
	m.dano = 0.0
	m.alcance = MinaDeFogo.GATILHO
	m.visao = MinaDeFogo.GATILHO + 4.0
	m.intervalo = 0.1
	m.ataca_animais = true
	m.set_meta(&"custo", custo)
	m.set_meta(&"criada_ms", Time.get_ticks_msec())
	m.ao_atacar = func(inv: Invocacao, _alvo: Node2D) -> void:
		MinaDeFogo.explodir(inv, dano)
	m.iniciar()
	m.collision_mask = 0
	m.add_to_group(&"minas")
	return m


## Início: o falcão bica o inimigo da mira e o deixa Marcado (+20% de dano de todos) por 5 s.
## Com o Laço, quem vai é o falcão que já te acompanha.
class Assobio extends HabilidadeLogica:
	const MARCA := 5.0
	const DURACAO_FALCAO := 6.0

	## Linhas da janelinha do HUD (TextoHabilidade).
	func efeitos(hab: HabilidadeData, _ficha: Ficha) -> Array[String]:
		return ["Alvo: o inimigo perto da mira (alcance: %s)" % TextoHabilidade.blocos(hab.alcance), "Marcado por %s s: +20%% de dano de todos" % TextoHabilidade.numero(MARCA), "Sem inimigo perto: a mana volta"]

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var inimigo := LogicasArqueiro.alvo_da_mira(quem, alvo, hab.alcance * Passivas.alcance(quem))
		if inimigo == null:
			LogicasArqueiro.devolver_mana(quem, hab, "Nenhum inimigo por perto para o falcão.")
			return
		var f := LogicasArqueiro.falcao_de(quem)
		if f == null:
			f = LogicasArqueiro.criar_falcao(quem, dano_de(quem, hab), DURACAO_FALCAO)
		f.set_meta(&"marcar", inimigo)
		f.atacar_agora(inimigo)
		World.efeito_todos(quem, &"poeira", quem.global_position + Vector2(0, -12))


## Atirador: a flecha atravessa todos os inimigos em linha.
class FlechaPerfurante extends HabilidadeLogica:
	## Linhas da janelinha do HUD (TextoHabilidade).
	func efeitos(_hab: HabilidadeData, _ficha: Ficha) -> Array[String]:
		return ["Atravessa todos os inimigos em linha", "Acerta cada um uma vez"]

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var p := Logicas.lancar(Logicas.FLECHA, quem, dir, dano_de(quem, hab), 1.2)
		p.duracao /= 1.2  # mais rápida, mesma distância
		p.perfura = true


## Atirador: flecha que deixa o alvo Marcado (+20% de dano de todo mundo) por 8 s.
class MarcaDoCacador extends HabilidadeLogica:
	const SEGUNDOS := 8.0
	const FORCA := 0.2

	## Linhas da janelinha do HUD (TextoHabilidade).
	func efeitos(_hab: HabilidadeData, _ficha: Ficha) -> Array[String]:
		return ["Marcado por %s s" % TextoHabilidade.numero(SEGUNDOS), "O alvo toma +%s%% de dano de todos" % TextoHabilidade.numero(FORCA * 100.0)]

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var p := Logicas.lancar(Logicas.FLECHA, quem, dir, dano_de(quem, hab))
		p.estado = EfeitosEstado.MARCADO
		p.estado_segundos = SEGUNDOS
		p.estado_forca = FORCA


## Atirador: 3 flechas seguidas, sem carregar.
class Rajada extends HabilidadeLogica:
	const FLECHAS := 3
	const INTERVALO := 0.2  # mais que a proteção de 0,15 s do alvo depois de um acerto

	## Linhas da janelinha do HUD (TextoHabilidade).
	func efeitos(_hab: HabilidadeData, _ficha: Ficha) -> Array[String]:
		return ["%d flechas, uma a cada %s s" % [FLECHAS, TextoHabilidade.numero(INTERVALO)], "Não precisa carregar"]

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var dano := dano_de(quem, hab)
		Logicas.lancar(Logicas.FLECHA, quem, dir, dano)
		for k in range(1, FLECHAS):
			quem.get_tree().create_timer(INTERVALO * k, false, true).timeout.connect(func() -> void:
				if is_instance_valid(quem):
					Logicas.lancar(Logicas.FLECHA, quem, dir, dano))


## Atirador (suprema): uma flecha gigante e rápida que atravessa tudo por 30 blocos.
class FlechaDoHorizonte extends HabilidadeLogica:
	const TAMANHO := 3.0
	const DISTANCIA := 480.0
	const VELOCIDADE := 360.0

	## Linhas da janelinha do HUD (TextoHabilidade).
	func efeitos(_hab: HabilidadeData, _ficha: Ficha) -> Array[String]:
		return ["Atravessa tudo por %s" % TextoHabilidade.blocos(DISTANCIA), "Flecha %dx maior" % roundi(TAMANHO)]

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var p := Logicas.lancar(Logicas.FLECHA, quem, dir, dano_de(quem, hab))
		p.velocidade = VELOCIDADE
		p.duracao = DISTANCIA / VELOCIDADE * Passivas.alcance(quem)
		p.perfura = true
		p.scale = Vector2(TAMANHO, TAMANHO)  # arte e área de acerto 3x maiores
		World.efeito_todos(quem, &"poeira", quem.global_position)


## Engenhoqueiro: uma rede que prende o alvo por 3 s (não anda).
class Rede extends HabilidadeLogica:
	const PRESO := 3.0

	## Linhas da janelinha do HUD (TextoHabilidade).
	func efeitos(_hab: HabilidadeData, _ficha: Ficha) -> Array[String]:
		return ["Prende (não anda) por %s s" % TextoHabilidade.numero(PRESO)]

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var p := Logicas.lancar(LogicasArqueiro.REDE, quem, dir, dano_de(quem, hab), 0.8)
		p.duracao /= 0.8
		p.estado = EfeitosEstado.PRESO
		p.estado_segundos = PRESO
		# A rede cai e fica enrolada no alvo enquanto ele está preso.
		p.acertou.connect(func(alvo: Node, _pos: Vector2) -> void:
			if is_instance_valid(alvo) and alvo is Node2D:
				World.efeito_preso_todos(alvo as Node2D, &"rede_chao", PRESO, Vector2(0, 1)))


## Engenhoqueiro: mina no chão da mira; explode quando alguém pisa e deixa Queimadura.
class MinaDeFogo extends HabilidadeLogica:
	const DURACAO := 40.0
	const GATILHO := 10.0
	const RAIO := 28.0
	const QUEIMADURA_SEGUNDOS := 3.0
	const QUEIMADURA_DPS := 1.0

	## Linhas da janelinha do HUD (TextoHabilidade).
	func efeitos(hab: HabilidadeData, _ficha: Ficha) -> Array[String]:
		return ["Alcance: %s" % TextoHabilidade.blocos(hab.alcance), "Explode ao pisar: área de raio %s" % TextoHabilidade.blocos(RAIO), "Queimadura: %s por segundo por %s s" % [TextoHabilidade.numero(QUEIMADURA_DPS), TextoHabilidade.numero(QUEIMADURA_SEGUNDOS)], "A mina dura %s s" % TextoHabilidade.numero(DURACAO)]

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		LogicasArqueiro.criar_mina(quem, LogicasArqueiro.ponto_no_chao(quem, hab, alvo), dano_de(quem, hab), quem.custo_de(hab))

	static func explodir(mina: Invocacao, dano: float) -> void:
		if mina.is_queued_for_deletion():
			return
		var pos := mina.global_position
		var origem: Node = mina  # o dono, se ainda estiver no jogo (as passivas dele valem)
		if is_instance_valid(mina.dono):
			origem = mina.dono
		for e in Golpes.inimigos_em_volta(mina, pos, RAIO):
			Golpes.acertar(origem, e, dano, &"fogo", EfeitosEstado.QUEIMADURA, QUEIMADURA_SEGUNDOS, QUEIMADURA_DPS)
		World.efeito_todos(mina, &"explosao", pos)
		mina.queue_free()


## Engenhoqueiro: torreta (besta) que atira sozinha no inimigo mais perto por 12 s.
class TorreDeBesta extends HabilidadeLogica:
	const DURACAO := 12.0

	## Linhas da janelinha do HUD (TextoHabilidade).
	func efeitos(hab: HabilidadeData, _ficha: Ficha) -> Array[String]:
		return ["Alcance: %s" % TextoHabilidade.blocos(hab.alcance), "Atira sozinha por %s s" % TextoHabilidade.numero(DURACAO), "Uma torre por vez"]

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		for n in quem.get_tree().get_nodes_in_group(&"torres_besta"):
			if (n as Invocacao).dono == quem:
				(n as Invocacao).sumir()  # uma torre por jogador
		var t := Invocacao.criar(quem, LogicasArqueiro.ponto_no_chao(quem, hab, alvo))
		t.desenho(["torre_besta"])
		t.duracao = DURACAO
		t.vida_maxima = 40.0
		t.dano = dano_de(quem, hab)
		t.projetil = Logicas.FLECHA
		t.alcance = 100.0
		t.visao = 110.0
		t.intervalo = 0.8
		t.velocidade = 0.0
		t.iniciar()
		t.add_to_group(&"torres_besta")
		World.efeito_todos(quem, &"poeira", t.global_position)


## Engenhoqueiro (suprema): 6 minas em volta de você de uma vez.
class CampoMinado extends HabilidadeLogica:
	const MINAS := 6
	const RAIO := 30.0

	## Linhas da janelinha do HUD (TextoHabilidade).
	func efeitos(_hab: HabilidadeData, _ficha: Ficha) -> Array[String]:
		return ["%d minas de fogo num raio de %s" % [MINAS, TextoHabilidade.blocos(RAIO)], "Cada mina explode ao pisar e deixa Queimadura"]

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var dano := dano_de(quem, hab)
		var custo := quem.custo_de(hab) / MINAS
		for k in MINAS:
			var ponto := quem.global_position + Vector2.from_angle(TAU * k / MINAS) * RAIO
			LogicasArqueiro.criar_mina(quem, ponto, dano, custo)
		World.efeito_todos(quem, &"poeira", quem.global_position)


## Domador: um animal da ilha com metade da vida ou menos vira seu companheiro (um por vez).
class Domar extends HabilidadeLogica:
	const VIDA := 0.5

	## Linhas da janelinha do HUD (TextoHabilidade).
	func efeitos(hab: HabilidadeData, _ficha: Ficha) -> Array[String]:
		return ["Alcance: %s" % TextoHabilidade.blocos(hab.alcance), "O animal precisa ter %s%% da vida ou menos" % TextoHabilidade.numero(VIDA * 100.0), "Um companheiro por vez"]

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var melhor: Animal = null
		for n in quem.get_tree().get_nodes_in_group(&"animais"):
			var a := n as Animal
			if a == null or a.is_queued_for_deletion() or a.global_position.distance_to(quem.global_position) > hab.alcance * Passivas.alcance(quem):
				continue
			if melhor == null or a.global_position.distance_to(alvo) < melhor.global_position.distance_to(alvo):
				melhor = a
		if melhor == null:
			LogicasArqueiro.devolver_mana(quem, hab, "Nenhum animal por perto para domar.")
			return
		if melhor.vida.atual > melhor.vida.maximo * VIDA:
			LogicasArqueiro.devolver_mana(quem, hab, "O animal precisa estar com metade da vida ou menos.")
			return
		var antigo := LogicasArqueiro.domado_de(quem)
		if antigo:
			antigo.sumir()
		var c := Companheiro.criar_companheiro(quem)
		c.set_meta(&"domado", true)
		c.set_meta(&"especie", melhor.especie)
		if melhor.especie == &"ovelha":
			c.textura_caminho = LogicasArqueiro.OVELHA
			c.quadro_inicial = 0
			c.quadros = 6
			c.deslocamento = Vector2(0, -6)  # os pés da ovelha do pacote (como em Animal)
		else:
			c.textura_caminho = LogicasArqueiro.FOLHA_ANIMAIS
			c.quadro_inicial = Animal.ESPECIES[melhor.especie].quadros[0]
			c.deslocamento = LogicasArqueiro.PES
			c.quadros = 1
		c.vida_maxima = 20.0 + melhor.vida.maximo * 2.0
		c.dano = (2.0 if melhor.especie == &"javali" else 1.0) * quem.ficha.multiplicador(&"fisico")
		c.velocidade = maxf(50.0, float(Animal.ESPECIES[melhor.especie].vel) * 2.0)
		c.position = melhor.global_position
		var onde := melhor.global_position
		melhor.queue_free()  # vira o companheiro (sem saque)
		c.iniciar()
		World.efeito_todos(quem, &"subir_nivel", onde + Vector2(0, -10))
		quem.avisar("Domou: agora o animal te acompanha!", &"subir_nivel")


## Domador: o companheiro pula no alvo da mira, bate e o prende por 1,5 s.
class Ataque extends HabilidadeLogica:
	const PRESO := 1.5

	## Linhas da janelinha do HUD (TextoHabilidade).
	func efeitos(hab: HabilidadeData, _ficha: Ficha) -> Array[String]:
		return ["Alcance: %s" % TextoHabilidade.blocos(hab.alcance), "Prende por %s s" % TextoHabilidade.numero(PRESO), "Precisa de um companheiro (Domar ou falcão)"]

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var bichos := Companheiro.de(quem)
		if bichos.is_empty():
			LogicasArqueiro.devolver_mana(quem, hab, "Você não tem companheiro (Domar ou Assobio).")
			return
		var inimigo := LogicasArqueiro.alvo_da_mira(quem, alvo, hab.alcance * Passivas.alcance(quem))
		if inimigo == null:
			LogicasArqueiro.devolver_mana(quem, hab, "Nenhum inimigo por perto.")
			return
		var c := LogicasArqueiro.domado_de(quem)
		if c == null:
			c = bichos[0]
		World.efeito_todos(quem, &"poeira", c.global_position)
		var lado := (c.global_position - inimigo.global_position).normalized()
		c.global_position = inimigo.global_position + (lado if lado != Vector2.ZERO else Vector2.LEFT) * 10.0
		c.atacar_agora(inimigo)
		Golpes.acertar(quem, inimigo, dano_de(quem, hab), &"fisico", EfeitosEstado.PRESO, PRESO, 0.0, &"poeira")


## Domador: uma manada (3 javalis) atravessa 9 blocos na direção da mira, derrubando tudo.
class EstouroDaBoiada extends HabilidadeLogica:
	const COMPRIMENTO := 140.0
	const LARGURA := 20.0
	const DURACAO := 0.8
	const PASSOS := 8
	const DERRUBADO := 1.5

	## Linhas da janelinha do HUD (TextoHabilidade).
	func efeitos(_hab: HabilidadeData, _ficha: Ficha) -> Array[String]:
		return ["Atravessa %s na direção da mira" % TextoHabilidade.blocos(COMPRIMENTO), "Derruba por %s s" % TextoHabilidade.numero(DERRUBADO)]

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var de := quem.global_position
		var ate := de + dir * COMPRIMENTO * Passivas.alcance(quem)
		var dano := dano_de(quem, hab)
		var lado := dir.orthogonal()
		for k in [-1, 0, 1]:
			var j := Invocacao.criar(quem, de + lado * 12.0 * k - dir * 10.0 * absi(k))
			j.textura_caminho = LogicasArqueiro.FOLHA_ANIMAIS
			j.quadro_inicial = 4
			j.deslocamento = LogicasArqueiro.PES
			j.quadros = 2
			j.fps = 10.0
			j.olhando_esquerda = dir.x < 0.0
			j.duracao = DURACAO + 0.3
			j.dano = 0.0
			j.visao = 0.0
			j.iniciar()
			j.collision_mask = 0
			j.create_tween().tween_property(j, "global_position", ate + lado * 12.0 * k, DURACAO)
		var ja: Array[Node2D] = []
		for passo in range(1, PASSOS + 1):
			var t := float(passo) / PASSOS
			quem.get_tree().create_timer(DURACAO * t, false, true).timeout.connect(func() -> void:
				if not is_instance_valid(quem):
					return
				var centro := de.lerp(ate, t)
				for e in Golpes.inimigos_em_volta(quem, centro, LARGURA):
					if not e in ja:
						ja.append(e)
						Golpes.acertar(quem, e, dano, &"fisico", EfeitosEstado.DERRUBADO, DERRUBADO)
				World.efeito_todos(quem, &"poeira", centro))


## Domador (suprema): por 10 s você corre 50% mais e cada flecha salta para mais um inimigo.
class EspiritoDaFera extends HabilidadeLogica:
	const SEGUNDOS := 10.0
	const VELOCIDADE := 0.5

	## Linhas da janelinha do HUD (TextoHabilidade).
	func efeitos(_hab: HabilidadeData, _ficha: Ficha) -> Array[String]:
		return ["Velocidade: +%s%% por %s s" % [TextoHabilidade.numero(VELOCIDADE * 100.0), TextoHabilidade.numero(SEGUNDOS)], "Cada flecha salta para mais um inimigo"]

	func executar(quem: Player, _hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		quem.buffs.dar(Buffs.VELOCIDADE, VELOCIDADE, SEGUNDOS, quem)
		quem.set_meta(&"espirito_da_fera_ate_ms", Time.get_ticks_msec() + int(SEGUNDOS * 1000.0))
		World.efeito_preso_todos(quem, &"furia", SEGUNDOS, Vector2(0, -4))
