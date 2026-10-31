class_name Bancada
extends StaticBody2D
## Bancada de trabalho: segurar E abre a mochila com a grade de fabricação 3x3 (como a mesa
## de trabalho do Minecraft). O anfitrião libera a 3x3 para quem usou e avisa o dono.

const INTERACAO := preload("res://scripts/components/interactable.gd")


func _ready() -> void:
	add_to_group(&"bancadas")
	var area := Area2D.new()
	area.name = "Interactable"
	area.set_script(INTERACAO)
	area.set(&"alcance", 34.0)
	area.set(&"tempo_segurar", 0.15)
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = Vector2(28, 20)
	forma.shape = ret
	forma.position = Vector2(0, -10)
	area.add_child(forma)
	add_child(area)


func pode_interagir() -> bool:
	return true


func texto_acao() -> String:
	return "Usar bancada"


func destacar(ligado: bool) -> void:
	for s in get_children():
		if s is Sprite2D:
			s.modulate = Color(1.15, 1.15, 1.05) if ligado else Color.WHITE


func altura_visivel() -> float:
	return 20.0


## Só o anfitrião chama.
func interagir(quem: Player) -> void:
	quem.inventario.na_bancada = true
	quem.inventario.reenviar()
	quem.abrir_mochila.rpc_id(quem.get_multiplayer_authority(), true)
