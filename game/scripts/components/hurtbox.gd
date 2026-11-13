class_name Hurtbox
extends Area2D
## Área que recebe acertos (golpe, bola de fogo...). Repassa para o dono pelo sinal.
## O dono decide o que cada tipo de dano faz: o slime perde vida, a árvore pega fogo.
##
## Árvore de habilidades: quando quem bate é um jogador, as passivas dele ajustam o dano
## antes (Passivas.dano_causado); a marca do Julgamento no alvo vale para todo mundo; e,
## se o golpe derrotou o alvo, o jogador fica sabendo (Sede, Contágio, Dedos leves).
##
## Durante o repasse (sinal `atingido`), `em_golpe` fica ligado com quem bateu, a força e se
## foi crítico: o ReacaoGolpe do dono lê isso para empurrar e mostrar o número (L40).
## Dano que não passa por aqui (veneno, queimadura) não empurra.

signal atingido(quantidade: float, tipo: StringName, origem: Node)

var em_golpe := false
var origem_golpe: Node
var forca_golpe := 0.0
var critico_golpe := false


func _ready() -> void:
	collision_layer = 1 << 4  # camada 5: "atingivel"
	collision_mask = 0
	monitoring = false


## `forca`: o quanto o golpe empurra e sacode o alvo (Combate.FORCA_NORMAL, FORCA_FINAL;
## 0 = não empurra).
func receber(quantidade: float, tipo: StringName, origem: Node, forca := Combate.FORCA_NORMAL) -> void:
	var dono := get_parent()
	var jogador := origem as Player if is_instance_valid(origem) else null
	var criticos_antes := int(jogador.get_meta(&"criticos", 0)) if jogador else 0
	if jogador:
		quantidade = Passivas.dano_causado(jogador, quantidade, tipo, dono)
	quantidade *= Passivas.marca_no_alvo(dono)
	var estados := EfeitosEstado.de(dono)
	if estados:
		quantidade *= estados.mult_dano_recebido()  # Marcado
	var vida: HealthComponent = dono.get_node_or_null("HealthComponent") as HealthComponent if dono else null
	var vivo_antes := vida != null and vida.esta_vivo()
	em_golpe = true
	origem_golpe = origem if is_instance_valid(origem) else null
	forca_golpe = forca
	critico_golpe = jogador != null and int(jogador.get_meta(&"criticos", 0)) > criticos_antes
	atingido.emit(quantidade, tipo, origem)
	em_golpe = false
	origem_golpe = null
	# Só inimigos e animais contam como "acerto" (Fúria, combo, companheiro); árvore não.
	if is_instance_valid(jogador) and is_instance_valid(dono) and (dono.is_in_group(&"inimigos") or dono.is_in_group(&"animais")):
		jogador.ultimo_alvo = dono as Node2D
		Passivas.acertou(jogador, dono, quantidade, tipo)
	if vivo_antes and is_instance_valid(vida) and not vida.esta_vivo() and is_instance_valid(jogador):
		Passivas.derrotou(jogador, dono)
