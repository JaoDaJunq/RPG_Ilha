class_name Interactable
extends Area2D
## Área que o mouse seleciona. O jogador consulta isso para saber o que está sob o cursor.
## O dono (pai) precisa ter: pode_interagir(), texto_acao(), interagir(quem) e destacar(ligado).

## Distância máxima (em pixels do mundo) entre o jogador e o objeto para interagir.
@export var alcance := 28.0
## Segurar E por este tempo faz uma interação (0 = um toque basta).
@export var tempo_segurar := 0.5


func _ready() -> void:
	collision_layer = 1 << 3  # camada 4: "selecionavel"
	collision_mask = 0
	monitoring = false
	input_pickable = false


func dono() -> Node:
	return get_parent()


func disponivel() -> bool:
	return dono().has_method("pode_interagir") and dono().pode_interagir()


func perto_de(posicao: Vector2) -> bool:
	return global_position.distance_to(posicao) <= alcance
