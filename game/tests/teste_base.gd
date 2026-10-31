class_name TesteBase
extends Node
## Base dos testes de fumaça. Cada teste imprime [OK] ou [FALHA] por verificação
## e termina com "RESULTADO: OK" ou "RESULTADO: FALHA" (é isso que rodar_testes.sh lê).

const MUNDO := preload("res://scenes/world/world.tscn")

var _falhas := 0


func checar(condicao: bool, descricao: String) -> void:
	if condicao:
		print("[OK] ", descricao)
	else:
		_falhas += 1
		print("[FALHA] ", descricao)


func terminar() -> void:
	print("RESULTADO: ", "OK" if _falhas == 0 else "FALHA")
	get_tree().quit(0 if _falhas == 0 else 1)


func esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos, true, true).timeout


## Cria a ilha. Por padrão sem slimes e sem árvores/pedras geradas,
## para nada no caminho atrapalhar o teste.
func criar_mundo(slimes := 0, limpar := true, classe: StringName = &"mago", raca: StringName = &"humano") -> World:
	Sfx.ligado = false
	Net.classe = classe
	Net.raca = raca
	var w: World = MUNDO.instantiate()
	w.arquivo_salvo = ""  # testes não mexem no mundo salvo do João
	w.slimes = slimes
	w.gerar_recursos = not limpar
	add_child(w)
	await get_tree().physics_frame
	# Machado e picareta de pedra na barra: com a mão a coleta é bem lenta (balanceamento),
	# e segurar_e escolhe a ferramenta certa para o alvo.
	if w.jogador:
		w.jogador.inventario.adicionar(&"machado_pedra", 1)
		w.jogador.inventario.adicionar(&"picareta_pedra", 1)
	return w


func colocar(w: World, cena: PackedScene, pos: Vector2) -> Node2D:
	var n: Node2D = cena.instantiate()
	n.position = pos
	w.entidades.add_child(n, true)
	return n


## Salva o que está na tela em evidence/<caminho> (precisa de janela).
func salvar_print(caminho: String) -> void:
	var destino := ProjectSettings.globalize_path("res://").path_join("../evidence").path_join(caminho)
	DirAccess.make_dir_recursive_absolute(destino.get_base_dir())
	await RenderingServer.frame_post_draw
	var erro := get_viewport().get_texture().get_image().save_png(destino)
	checar(erro == OK, "print salvo: " + caminho)


## Segura E por `segundos` mirando no ponto indicado.
func segurar_e(p: Player, mira: Vector2, segundos: float) -> void:
	p.mira_forcada = mira
	_ferramenta_para(p, mira)
	await get_tree().physics_frame
	Input.action_press(&"interagir")
	await esperar(segundos)
	Input.action_release(&"interagir")
	await get_tree().physics_frame


## Põe na mão o machado (árvore) ou a picareta (pedra) que o jogador tiver na barra.
func _ferramenta_para(p: Player, mira: Vector2) -> void:
	var perto: ResourceNode = null
	for n in get_tree().get_nodes_in_group(&"recursos"):
		if perto == null or (n as Node2D).global_position.distance_to(mira) < perto.global_position.distance_to(mira):
			perto = n
	if perto == null:
		return
	var tipo := &"picareta" if perto.acao == "Minerar" else &"machado"
	for k in Inventory.BARRA:
		var id := p.inventario.item_em(k)
		if ItemData.existe(id) and ItemData.carregar(id).ferramenta == tipo:
			p.barra_escolhida = k
			return
