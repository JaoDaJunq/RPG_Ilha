class_name HabilidadeLogica
extends RefCounted
## O que uma habilidade faz. Roda só no ANFITRIÃO, depois de conferir mana e recarga.
## `dir`: direção da mira; `alvo`: ponto do mouse; `carga`: 0 a 1 (habilidades de segurar).


func executar(_quem: Player, _hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
	pass


## Dano já com o multiplicador do atributo certo, as melhorias da árvore e a Ressonância.
static func dano_de(quem: Player, hab: HabilidadeData, base := -1.0) -> float:
	var bonus := quem.bonus_dano_fisico() if hab.elemento == &"fisico" else 1.0
	return (hab.dano if base < 0.0 else base) * quem.ficha.multiplicador(hab.elemento) * bonus * quem.mult_habilidade(hab)


## Acerta todas as áreas atingíveis num círculo (menos o próprio jogador).
static func acertar_em_volta(quem: Player, centro: Vector2, raio: float, dano: float, elemento: StringName) -> int:
	var forma := CircleShape2D.new()
	forma.radius = raio
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.transform = Transform2D(0.0, centro)
	consulta.collide_with_areas = true
	consulta.collide_with_bodies = false
	consulta.collision_mask = 1 << 4
	var acertos := 0
	for r in quem.get_world_2d().direct_space_state.intersect_shape(consulta, 32):
		var area := r.collider as Hurtbox
		if area and area != quem.hurtbox and not area.get_parent() is Player:
			area.receber(dano, elemento, quem)
			acertos += 1
	return acertos
