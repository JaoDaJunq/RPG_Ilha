class_name Logicas
extends RefCounted
## As lógicas das habilidades da raiz de Guerreiro, Mago, Arqueiro, Ladino e Clérigo.
## Cada classe interna é apontada pelo campo `logica` de um HabilidadeData.

const BOLA_DE_FOGO := preload("res://scenes/abilities/fireball.tscn")
const LANCA_GELO := preload("res://scenes/abilities/lanca_gelo.tscn")
const FLECHA := preload("res://scenes/abilities/flecha.tscn")
const ARMADILHA := preload("res://scenes/abilities/armadilha.tscn")
const BOMBA := preload("res://scenes/abilities/bomba.tscn")
const ADAGA := preload("res://scenes/abilities/adaga.tscn")


static func lancar(cena: PackedScene, quem: Player, dir: Vector2, dano: float, velocidade_mult := 1.0) -> Projetil:
	var p: Projetil = cena.instantiate()
	p.lancador = quem
	p.direcao = dir.normalized()
	p.dano = dano
	p.velocidade *= velocidade_mult
	p.duracao *= Passivas.alcance(quem)  # Olho de águia: voa mais tempo, vai mais longe
	p.position = quem.global_position + Vector2(0, -10) + p.direcao * 8.0
	quem.get_parent().add_child(p, true)
	return p


## Guerreiro: avança e empurra tudo no caminho.
class Investida extends HabilidadeLogica:
	const DISTANCIA := 56.0

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var inicio := quem.global_position + Vector2(0, -10)
		var passos := 4
		var ja: Array[Node] = []
		for i in passos + 1:
			var ponto := inicio + dir * DISTANCIA * i / passos
			var forma := CircleShape2D.new()
			forma.radius = 12.0
			var consulta := PhysicsShapeQueryParameters2D.new()
			consulta.shape = forma
			consulta.transform = Transform2D(0.0, ponto)
			consulta.collide_with_areas = true
			consulta.collide_with_bodies = false
			consulta.collision_mask = 1 << 4
			for r in quem.get_world_2d().direct_space_state.intersect_shape(consulta, 16):
				var area := r.collider as Hurtbox
				if area and not area.get_parent() is Player and not area in ja:
					ja.append(area)
					area.receber(dano_de(quem, hab), &"fisico", quem)
		quem.mover_por_habilidade(dir * DISTANCIA, 0.18)
		World.efeito_todos(quem, &"poeira", quem.global_position)


## Guerreiro: golpe em volta.
class Giro extends HabilidadeLogica:
	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		acertar_em_volta(quem, quem.global_position + Vector2(0, -8), 26.0, dano_de(quem, hab), &"fisico")
		World.efeito_todos(quem, &"giro", quem.global_position + Vector2(0, -8))


## Mago: bola de fogo (queima árvores, tira mais vida de slimes).
class BolaDeFogo extends HabilidadeLogica:
	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		Logicas.lancar(Logicas.BOLA_DE_FOGO, quem, dir, dano_de(quem, hab))


## Mago: lança de gelo (congela; sobre a água deixa um caminho de gelo).
class LancaGelo extends HabilidadeLogica:
	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		Logicas.lancar(Logicas.LANCA_GELO, quem, dir, dano_de(quem, hab))


## Arqueiro: segura para carregar; carregado vai mais longe e bate mais.
class TiroCarregado extends HabilidadeLogica:
	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, carga: float) -> void:
		carga = clampf(carga, 0.0, 1.0)
		# Mão leve: a flecha voa mais rápido, mas chega à mesma distância (o alcance é do Olho de águia).
		var rapido := Passivas.MAO_LEVE_TIRO if quem.tem(&"mao_leve") else 1.0
		var p := Logicas.lancar(Logicas.FLECHA, quem, dir, dano_de(quem, hab, hab.dano * (1.0 + 2.0 * carga)), (1.0 + carga) * rapido)
		p.duracao /= rapido


## Arqueiro: armadilha no chão, onde o mouse estiver (até o alcance).
class Armadilha extends HabilidadeLogica:
	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var de := quem.global_position
		var ponto := de + (alvo - de).limit_length(hab.alcance * Passivas.alcance(quem))
		# Cada jogador tem no máximo 2 armadilhas armadas (3 com o Engenhoso); a mais antiga some.
		var minhas: Array[Node] = []
		for n in quem.get_tree().get_nodes_in_group(&"armadilhas"):
			if n.dono_id == quem.id_rede() and not n.is_queued_for_deletion():
				minhas.append(n)
		if minhas.size() >= Passivas.armadilhas_maximas(quem):
			minhas[0].queue_free()
		var a: Node2D = Logicas.ARMADILHA.instantiate()
		a.dono_id = quem.id_rede()
		a.dano = dano_de(quem, hab)
		a.position = ponto
		quem.get_parent().add_child(a, true)


## Guerreiro: por 3 s toma 60% menos dano.
class Bloqueio extends HabilidadeLogica:
	const DURACAO := 3.0
	const REDUCAO := 0.6

	func executar(quem: Player, _hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		quem.bloquear(REDUCAO, DURACAO)
		World.efeito_preso_todos(quem, &"escudo", DURACAO, Vector2(0, -9))


## Guerreiro: por 5 s, +50% de dano físico e +25% de velocidade.
class Furia extends HabilidadeLogica:
	const DURACAO := 5.0

	func executar(quem: Player, _hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		quem.enfurecer(DURACAO)
		World.efeito_todos(quem, &"furia", quem.global_position)


## Mago: raio no inimigo mais perto do ponto do mouse (até o alcance do mago); atordoa.
class Raio extends HabilidadeLogica:
	const ALCANCE_MAGO := 120.0
	const RAIO_MIRA := 28.0
	const ATORDOAR := 1.2

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var melhor: Node2D = null
		var menor := RAIO_MIRA
		for n in quem.get_tree().get_nodes_in_group(&"inimigos") + quem.get_tree().get_nodes_in_group(&"animais"):
			var e := n as Node2D
			if e == null or e.global_position.distance_to(quem.global_position) > ALCANCE_MAGO:
				continue
			var d := e.global_position.distance_to(alvo)
			if d <= menor:
				menor = d
				melhor = e
		if melhor == null:
			return
		var onde := melhor.global_position
		var area := melhor.get_node_or_null("Hurtbox") as Hurtbox
		if area:
			area.receber(dano_de(quem, hab), &"raio", quem)
		if is_instance_valid(melhor) and melhor.has_method(&"prender"):
			melhor.prender(ATORDOAR)
		World.efeito_todos(quem, &"raio", onde)
		# Condução: o raio salta para mais 1 inimigo perto (mais 2 se o alvo estiver molhado).
		if quem.tem(&"conducao"):
			LogicasMago.conducao(quem, hab, melhor, onde, ATORDOAR)


## Mago: congela tudo em volta.
class NovaGelo extends HabilidadeLogica:
	const RAIO := 36.0

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var centro := quem.global_position + Vector2(0, -8)
		acertar_em_volta(quem, centro, RAIO, dano_de(quem, hab), &"gelo")
		World.efeito_todos(quem, &"nova_gelo", quem.global_position)


## Arqueiro: no ponto da mira, depois de um instante, flechas caem e machucam todos ali.
class ChuvaFlechas extends HabilidadeLogica:
	const ATRASO := 0.4
	const RAIO := 30.0
	const FLECHAS := 5

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var de := quem.global_position
		var ponto := de + (alvo - de).limit_length(hab.alcance * Passivas.alcance(quem))
		var dano := dano_de(quem, hab)
		World.chuva_de_flechas_todos(quem, ponto, RAIO, FLECHAS, ATRASO)
		quem.get_tree().create_timer(ATRASO).timeout.connect(func() -> void:
			if not is_instance_valid(quem):
				return
			acertar_em_volta(quem, ponto, RAIO, dano, &"fisico"))


## Arqueiro: bomba que explode ao bater em algo ou depois de 0,8 s.
class Bomba extends HabilidadeLogica:
	const RAIO := 34.0
	const TEMPO := 0.8

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var dano := dano_de(quem, hab)
		# O projétil só leva a bomba (e acende o que encostar); quem machuca é a explosão.
		var p := Logicas.lancar(Logicas.BOMBA, quem, dir, 0.0, 0.85)
		p.duracao = TEMPO * Passivas.alcance(quem)
		p.terminou.connect(func(pos: Vector2, acertou: bool) -> void:
			if not is_instance_valid(quem):
				return
			acertar_em_volta(quem, pos, RAIO, dano, &"fogo")
			if not acertou:  # batendo, o próprio projétil já toca a explosão dele
				World.efeito_todos(quem, &"explosao", pos))


## Ladino: avança até o inimigo perto do mouse e dá um golpe forte; dobra se ele não perseguia.
class GolpeFurtivo extends HabilidadeLogica:
	const RAIO_MIRA := 28.0
	const MULTIPLICADOR := 2.0
	const COLADO := 12.0  # px que sobram entre o ladino e o inimigo depois do avanço
	const DURACAO_AVANCO := 0.12

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var inimigo := Logicas.inimigo_na_mira(quem, alvo, hab.alcance, RAIO_MIRA)
		if inimigo == null:
			return
		var area := inimigo.get_node_or_null("Hurtbox") as Hurtbox
		if area == null:
			return
		var furtivo: bool = not (inimigo.has_method(&"persegue") and inimigo.persegue(quem))
		var dano := dano_de(quem, hab) * (MULTIPLICADOR if furtivo else 1.0)
		var onde := inimigo.global_position
		var para := onde - quem.global_position
		var anda := maxf(0.0, para.length() - COLADO)
		if anda > 0.0:
			quem.mover_por_habilidade(para.normalized() * anda, DURACAO_AVANCO)
		World.efeito_todos(quem, &"poeira", quem.global_position)
		area.receber(dano, &"fisico", quem)
		quem.envenenar_atingido(area)
		World.efeito_todos(quem, &"giro", onde + Vector2(0, -8))
		if furtivo:
			quem.avisar("Golpe furtivo! Dano dobrado.")


## Ladino: por 6 s, os golpes envenenam (dano pequeno por segundo, por 3 s).
class LaminaEnvenenada extends HabilidadeLogica:
	const DURACAO := 6.0

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		quem.envenenar_golpes(DURACAO, dano_de(quem, hab))
		World.efeito_todos(quem, &"poeira", quem.global_position)


## Ladino: por 3 s os inimigos perdem o jogador de vista e param de perseguir.
class BombaFumaca extends HabilidadeLogica:
	const DURACAO := 3.0

	func executar(quem: Player, _hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		quem.esconder(DURACAO)
		for desvio in [Vector2(-8, 2), Vector2(8, 2), Vector2(0, -6)]:
			World.efeito_todos(quem, &"poeira", quem.global_position + desvio)


## Ladino: três adagas em leque.
class LequeAdagas extends HabilidadeLogica:
	const ABERTURA := 0.28  # radianos (16 graus) entre uma adaga e a vizinha
	const ADAGAS := 3

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var dano := dano_de(quem, hab)
		for k in ADAGAS:
			Logicas.lancar(Logicas.ADAGA, quem, dir.rotated((k - (ADAGAS - 1) / 2.0) * ABERTURA), dano)


## Clérigo: cura quem está perto (e ele mesmo).
class Cura extends HabilidadeLogica:
	const RAIO := 56.0
	const BASE := 10.0
	const POR_ESPIRITO := 2.0

	static func quantidade(ficha: Ficha) -> float:
		return BASE + POR_ESPIRITO * ficha.valor(&"espirito")

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var cura := quantidade(quem.ficha) * quem.mult_habilidade(hab)
		for j in Logicas.jogadores_em_volta(quem, RAIO):
			j.receber_cura(quem, cura)
			World.efeito_todos(j, &"subir_nivel", j.global_position + Vector2(0, -14))


## Clérigo: ele e quem está perto tomam 50% menos dano por 4 s.
class EscudoSagrado extends HabilidadeLogica:
	const RAIO := 56.0
	const REDUCAO := 0.5
	const DURACAO := 4.0

	func executar(quem: Player, _hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		# Égide: escudos 30% mais fortes (50% → 65% menos dano).
		var reducao := minf(0.9, REDUCAO * Passivas.escudos(quem))
		for j in Logicas.jogadores_em_volta(quem, RAIO):
			j.bloquear(reducao, DURACAO)
			World.efeito_preso_todos(j, &"escudo", DURACAO, Vector2(0, -9))


## Clérigo: luz em volta; slimes da noite levam o triplo (isso fica no Slime).
class LuzSagrada extends HabilidadeLogica:
	const RAIO := 40.0

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var centro := quem.global_position + Vector2(0, -8)
		acertar_em_volta(quem, centro, RAIO, dano_de(quem, hab), &"luz")
		World.efeito_todos(quem, &"subir_nivel", quem.global_position + Vector2(0, -14))


## Clérigo: por 8 s, ele e quem está perto recuperam vida aos poucos.
class Bencao extends HabilidadeLogica:
	const RAIO := 56.0
	const DURACAO := 8.0
	const VIDA_POR_SEGUNDO := 3.0

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		for j in Logicas.jogadores_em_volta(quem, RAIO):
			j.abencoar(DURACAO, VIDA_POR_SEGUNDO * quem.mult_habilidade(hab), quem)
			World.efeito_todos(j, &"subir_nivel", j.global_position + Vector2(0, -14))


## Mago (árvore, inicial): teleporte curto na direção da mira.
class Piscar extends HabilidadeLogica:
	const DURACAO := 0.05

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		World.efeito_todos(quem, &"poeira", quem.global_position)
		quem.vida.proteger(DURACAO + 0.1)
		quem.mover_por_habilidade(dir * hab.alcance, DURACAO)
		World.efeito_todos(quem, &"poeira", quem.global_position + dir * hab.alcance)


## Ladino (árvore, inicial): um dash na direção da mira que libera o dash comum na hora,
## para o segundo pulo mudar de direção.
class Cambalhota extends HabilidadeLogica:
	const DURACAO := 0.16

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		quem.vida.proteger(DURACAO + 0.1)
		quem.mover_por_habilidade(dir * hab.alcance, DURACAO)
		quem.liberar_esquiva()
		World.efeito_todos(quem, &"poeira", quem.global_position)


## Jogadores (o próprio incluso) a até `raio` px de quem lançou: os aliados do Clérigo.
static func jogadores_em_volta(quem: Player, raio: float) -> Array[Player]:
	var l: Array[Player] = []
	for n in quem.get_tree().get_nodes_in_group(&"jogadores"):
		var p := n as Player
		if p and not p.criando and p.global_position.distance_to(quem.global_position) <= raio:
			l.append(p)
	return l


## O inimigo ou animal mais perto do ponto da mira (até `raio_mira` dele), desde que esteja a
## até `alcance` px de quem lançou. Nulo se não houver.
static func inimigo_na_mira(quem: Player, mira: Vector2, alcance: float, raio_mira: float) -> Node2D:
	var melhor: Node2D = null
	var menor := raio_mira
	for n in quem.get_tree().get_nodes_in_group(&"inimigos") + quem.get_tree().get_nodes_in_group(&"animais"):
		var e := n as Node2D
		if e == null or e.is_queued_for_deletion() or e.global_position.distance_to(quem.global_position) > alcance:
			continue
		var d := e.global_position.distance_to(mira)
		if d <= menor:
			menor = d
			melhor = e
	return melhor


## Arquivos de lógicas de cada classe (um por classe, para cada um mexer só no seu).
## Toda `class Nome extends HabilidadeLogica` escrita num deles (ou aqui) já fica registrada:
## o campo `logica` do .tres é o nome da classe interna.
const POR_CLASSE: Array[Script] = [
	preload("res://scripts/abilities/logicas_guerreiro.gd"),
	preload("res://scripts/abilities/logicas_mago.gd"),
	preload("res://scripts/abilities/logicas_arqueiro.gd"),
	preload("res://scripts/abilities/logicas_ladino.gd"),
	preload("res://scripts/abilities/logicas_clerigo.gd"),
]

static var _registro: Dictionary = {}  # nome da lógica → classe interna (GDScript)


## A lógica pelo nome (procura aqui e nos arquivos de cada classe).
static func criar(nome: StringName) -> HabilidadeLogica:
	var classe := classe_da_logica(nome)
	if classe:
		return classe.new()
	push_error("Lógica de habilidade desconhecida: %s" % nome)
	return HabilidadeLogica.new()


## A classe interna da lógica `nome`, ou nula. O mesmo nome em dois arquivos dá erro.
static func classe_da_logica(nome: StringName) -> GDScript:
	if _registro.is_empty():
		var scripts: Array[Script] = [load("res://scripts/abilities/logicas.gd")]
		scripts.append_array(POR_CLASSE)
		for s in scripts:
			var mapa := s.get_script_constant_map()
			for k in mapa:
				var c: Variant = mapa[k]
				if c is GDScript and (c as GDScript).can_instantiate() and (c as GDScript).new() is HabilidadeLogica:
					if _registro.has(StringName(k)):
						push_error("Lógica com o mesmo nome em dois arquivos: %s" % k)
					_registro[StringName(k)] = c
	return _registro.get(nome)
