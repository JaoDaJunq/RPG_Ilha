class_name Hurtbox
extends Area2D
## Área que recebe acertos (golpe, bola de fogo...). Repassa para o dono pelo sinal.
## O dono decide o que cada tipo de dano faz: o slime perde vida, a árvore pega fogo.
##
## Árvore de habilidades: quando quem bate é um jogador, as passivas dele ajustam o dano
## antes (Passivas.dano_causado); a marca do Julgamento no alvo vale para todo mundo; e,
## se o golpe derrotou o alvo, o jogador fica sabendo (Sede, Contágio, Dedos leves).

signal atingido(quantidade: float, tipo: StringName, origem: Node)


func _ready() -> void:
	collision_layer = 1 << 4  # camada 5: "atingivel"
	collision_mask = 0
	monitoring = false


func receber(quantidade: float, tipo: StringName, origem: Node) -> void:
	var dono := get_parent()
	var jogador := origem as Player if is_instance_valid(origem) else null
	if jogador:
		quantidade = Passivas.dano_causado(jogador, quantidade, tipo, dono)
	quantidade *= Passivas.marca_no_alvo(dono)
	var estados := EfeitosEstado.de(dono)
	if estados:
		quantidade *= estados.mult_dano_recebido()  # Marcado
	var vida: HealthComponent = dono.get_node_or_null("HealthComponent") as HealthComponent if dono else null
	var vivo_antes := vida != null and vida.esta_vivo()
	atingido.emit(quantidade, tipo, origem)
	# Só inimigos e animais contam como "acerto" (Fúria, combo, companheiro); árvore não.
	if is_instance_valid(jogador) and is_instance_valid(dono) and (dono.is_in_group(&"inimigos") or dono.is_in_group(&"animais")):
		jogador.ultimo_alvo = dono as Node2D
		Passivas.acertou(jogador, dono, quantidade, tipo)
	if vivo_antes and is_instance_valid(vida) and not vida.esta_vivo() and is_instance_valid(jogador):
		Passivas.derrotou(jogador, dono)
