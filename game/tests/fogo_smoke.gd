extends TesteBase
## A bola de fogo queima árvores (que passam a render carvão) e machuca slimes.

const ARVORE := preload("res://scenes/world/arvore.tscn")
const SLIME := preload("res://scenes/enemies/slime.tscn")


func _ready() -> void:
	var w := await criar_mundo()
	var p := w.jogador
	var inv := p.inventario

	var arvore: ResourceNode = colocar(w, ARVORE, p.position + Vector2(60, 0))
	p.mira_forcada = arvore.global_position + Vector2(0, -6)
	await get_tree().physics_frame
	p.lancar_bola_de_fogo()
	await esperar(0.6)
	checar(arvore.estado == ResourceNode.Estado.QUEIMANDO, "bola de fogo acende a árvore")
	checar(arvore.chamas.visible, "árvore queimando mostra as chamas")
	checar(not arvore.pode_interagir(), "árvore em chamas não pode ser cortada")
	await esperar(3.2)
	checar(arvore.estado == ResourceNode.Estado.QUEIMADO, "depois de 3 s a árvore fica queimada")
	checar(arvore.texto_acao() == "Recolher carvão", "árvore queimada oferece recolher carvão")

	p.global_position = arvore.global_position + Vector2(-20, 0)
	await segurar_e(p, arvore.global_position + Vector2(0, -14), 0.75)
	checar(inv.quantidade_de(&"carvao") == 2, "árvore queimada rende 2 de carvão (tem %d)" % inv.quantidade_de(&"carvao"))
	checar(inv.quantidade_de(&"madeira") == 0, "árvore queimada não rende madeira")
	checar(arvore.estado == ResourceNode.Estado.ESGOTADO, "depois de recolher o carvão vira toco")

	# Fogo no slime: tira 2 de 3 de vida.
	var slime: Slime = colocar(w, SLIME, p.global_position + Vector2(0, 50))
	slime.set_physics_process(false)
	await get_tree().physics_frame
	p.mira_forcada = slime.global_position + Vector2(0, -6)
	await esperar(0.7)  # espera a recarga da bola de fogo
	p.lancar_bola_de_fogo()
	await esperar(0.6)
	checar(is_instance_valid(slime) and slime.vida.atual == 1.0, "bola de fogo tira 2 de vida do slime")

	terminar()
