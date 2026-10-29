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
func criar_mundo(slimes := 0, limpar := true) -> World:
	Sfx.ligado = false
	var w: World = MUNDO.instantiate()
	w.slimes = slimes
	add_child(w)
	if limpar:
		for n in w.entidades.get_children():
			if n is ResourceNode:
				n.free()
	await get_tree().physics_frame
	return w


func colocar(w: World, cena: PackedScene, pos: Vector2) -> Node2D:
	var n: Node2D = cena.instantiate()
	n.position = pos
	w.entidades.add_child(n)
	return n


## Segura E por `segundos` mirando no ponto indicado.
func segurar_e(p: Player, mira: Vector2, segundos: float) -> void:
	p.mira_forcada = mira
	await get_tree().physics_frame
	Input.action_press(&"interagir")
	await esperar(segundos)
	Input.action_release(&"interagir")
	await get_tree().physics_frame
