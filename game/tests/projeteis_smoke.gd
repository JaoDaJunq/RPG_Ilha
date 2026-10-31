extends TesteBase
## Projéteis passam por cima de árvores, tocos e pedras (antes paravam na caixa invisível
## da árvore, que continuava no toco). Só o fogo para numa árvore inteira, e a acende.

const SLIME := preload("res://scenes/enemies/slime.tscn")
const ARVORE := preload("res://scenes/world/arvore.tscn")


func _ready() -> void:
	var w := await criar_mundo(0, true, &"mago")
	var p := w.jogador
	var de := p.global_position

	# Lança de gelo através de uma árvore inteira.
	var arvore: ResourceNode = colocar(w, ARVORE, de + Vector2(28, 12))
	var slime: Slime = colocar(w, SLIME, de + Vector2(60, 0))
	await get_tree().physics_frame
	p.mira_forcada = slime.global_position + Vector2(0, -6)
	p.usar_habilidade_por_id(&"lanca_gelo")
	await esperar(0.6)
	checar(slime.congelado(), "a lança de gelo passa pela árvore e congela o slime")
	checar(arvore.estado == ResourceNode.Estado.INTEIRO, "a árvore continua inteira")

	# Vira toco: a caixa de acerto some.
	arvore._definir_estado(ResourceNode.Estado.ESGOTADO, 0, false)
	await get_tree().physics_frame
	checar(not arvore.hurtbox.monitorable, "o toco não recebe mais acertos")

	# Bola de fogo na árvore inteira: para nela e acende.
	var outra: ResourceNode = colocar(w, ARVORE, de + Vector2(-28, 12))
	await get_tree().physics_frame
	p.mira_forcada = de + Vector2(-60, -10)
	await esperar(1.3)
	p.usar_habilidade_por_id(&"bola_de_fogo")
	await esperar(0.5)
	checar(outra.estado == ResourceNode.Estado.QUEIMANDO, "a bola de fogo para na árvore e ela pega fogo")
	checar(get_tree().get_nodes_in_group(&"projeteis").is_empty(), "a bola de fogo acabou na árvore")
	terminar()
