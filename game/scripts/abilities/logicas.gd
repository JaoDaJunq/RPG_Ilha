class_name Logicas
extends RefCounted
## As lógicas das habilidades da raiz de Guerreiro, Mago e Arqueiro.
## Cada classe interna é apontada pelo campo `logica` de um HabilidadeData.

const BOLA_DE_FOGO := preload("res://scenes/abilities/fireball.tscn")
const LANCA_GELO := preload("res://scenes/abilities/lanca_gelo.tscn")
const FLECHA := preload("res://scenes/abilities/flecha.tscn")
const ARMADILHA := preload("res://scenes/abilities/armadilha.tscn")
const BOMBA := preload("res://scenes/abilities/bomba.tscn")


static func lancar(cena: PackedScene, quem: Player, dir: Vector2, dano: float, velocidade_mult := 1.0) -> Projetil:
	var p: Projetil = cena.instantiate()
	p.lancador = quem
	p.direcao = dir.normalized()
	p.dano = dano
	p.velocidade *= velocidade_mult
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
		Logicas.lancar(Logicas.FLECHA, quem, dir, dano_de(quem, hab, hab.dano * (1.0 + 2.0 * carga)), 1.0 + carga)


## Arqueiro: armadilha no chão, onde o mouse estiver (até o alcance).
class Armadilha extends HabilidadeLogica:
	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var de := quem.global_position
		var ponto := de + (alvo - de).limit_length(hab.alcance)
		# Cada jogador tem no máximo 2 armadilhas armadas; a mais antiga some.
		var minhas: Array[Node] = []
		for n in quem.get_tree().get_nodes_in_group(&"armadilhas"):
			if n.dono_id == quem.id_rede():
				minhas.append(n)
		if minhas.size() >= 2:
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
		var ponto := de + (alvo - de).limit_length(hab.alcance)
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
		p.duracao = TEMPO
		p.terminou.connect(func(pos: Vector2, acertou: bool) -> void:
			if not is_instance_valid(quem):
				return
			acertar_em_volta(quem, pos, RAIO, dano, &"fogo")
			if not acertou:  # batendo, o próprio projétil já toca a explosão dele
				World.efeito_todos(quem, &"explosao", pos))


static func criar(nome: StringName) -> HabilidadeLogica:
	match nome:
		&"Investida": return Investida.new()
		&"Giro": return Giro.new()
		&"BolaDeFogo": return BolaDeFogo.new()
		&"LancaGelo": return LancaGelo.new()
		&"TiroCarregado": return TiroCarregado.new()
		&"Armadilha": return Armadilha.new()
		&"Bloqueio": return Bloqueio.new()
		&"Furia": return Furia.new()
		&"Raio": return Raio.new()
		&"NovaGelo": return NovaGelo.new()
		&"ChuvaFlechas": return ChuvaFlechas.new()
		&"Bomba": return Bomba.new()
	push_error("Lógica de habilidade desconhecida: %s" % nome)
	return HabilidadeLogica.new()
