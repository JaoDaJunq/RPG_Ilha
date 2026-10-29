extends TesteBase
## Segurar E corta árvore e minera pedra; longe demais não coleta nada.

const ARVORE := preload("res://scenes/world/arvore.tscn")
const PEDRA := preload("res://scenes/world/pedra.tscn")


func _ready() -> void:
	var w := await criar_mundo()
	var p := w.jogador
	var inv := p.inventario

	# Longe demais: alvo selecionado, mas nada acontece.
	var longe: ResourceNode = colocar(w, ARVORE, p.position + Vector2(70, 0))
	await segurar_e(p, longe.global_position + Vector2(0, -20), 1.2)
	checar(p.alvo == longe.interacao, "mouse em cima da árvore seleciona a árvore")
	checar(not p.alvo_ao_alcance(), "a 70 px a árvore está fora do alcance")
	checar(inv.quantidade_de(&"madeira") == 0 and longe.golpes_restantes() == 3, "longe demais não corta")
	longe.queue_free()

	# Perto: 3 golpes de 0,5 s rendem 3 de madeira e viram toco.
	var arvore: ResourceNode = colocar(w, ARVORE, p.position + Vector2(22, 0))
	await segurar_e(p, arvore.global_position + Vector2(0, -20), 0.75)
	checar(arvore.golpes_restantes() == 2, "segurar E 0,75 s dá 1 golpe (restam %d)" % arvore.golpes_restantes())
	checar(arvore.sprite.region_rect == arvore.regioes_por_golpe[0], "depois do 1º golpe a árvore mostra a marca do machado")
	await segurar_e(p, arvore.global_position + Vector2(0, -20), 1.3)
	checar(inv.quantidade_de(&"madeira") == 3, "árvore cortada rende 3 de madeira (tem %d)" % inv.quantidade_de(&"madeira"))
	checar(arvore.estado == ResourceNode.Estado.ESGOTADO, "árvore cortada vira toco")
	checar(not arvore.pode_interagir(), "toco não é mais coletável")
	arvore.queue_free()

	# Pedra: 4 golpes rendem 3 de pedra e a pedra some.
	var pedra: ResourceNode = colocar(w, PEDRA, p.position + Vector2(0, 22))
	await segurar_e(p, pedra.global_position + Vector2(0, -12), 2.3)
	checar(inv.quantidade_de(&"pedra") == 3, "pedra minerada rende 3 de pedra (tem %d)" % inv.quantidade_de(&"pedra"))
	checar(not is_instance_valid(pedra), "pedra esgotada some do mapa")

	terminar()
