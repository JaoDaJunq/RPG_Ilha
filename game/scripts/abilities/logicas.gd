class_name Logicas
extends RefCounted
## As lógicas das habilidades da raiz de Guerreiro, Mago e Arqueiro.
## Cada classe interna é apontada pelo campo `logica` de um HabilidadeData.

const BOLA_DE_FOGO := preload("res://scenes/abilities/fireball.tscn")
const LANCA_GELO := preload("res://scenes/abilities/lanca_gelo.tscn")
const FLECHA := preload("res://scenes/abilities/flecha.tscn")
const ARMADILHA := preload("res://scenes/abilities/armadilha.tscn")


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


static func criar(nome: StringName) -> HabilidadeLogica:
	match nome:
		&"Investida": return Investida.new()
		&"Giro": return Giro.new()
		&"BolaDeFogo": return BolaDeFogo.new()
		&"LancaGelo": return LancaGelo.new()
		&"TiroCarregado": return TiroCarregado.new()
		&"Armadilha": return Armadilha.new()
	push_error("Lógica de habilidade desconhecida: %s" % nome)
	return HabilidadeLogica.new()
