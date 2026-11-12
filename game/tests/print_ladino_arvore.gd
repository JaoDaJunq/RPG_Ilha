extends TesteBase
## Prints das habilidades novas da árvore do Ladino (precisa de janela):
##   <godot> --path game res://tests/print_ladino_arvore.tscn
## Salva evidence/novidades/arvore_ladino_venenos.png (Frasco de ácido + Nuvem tóxica em
## slimes) e evidence/novidades/arvore_ladino_leque.png (Leque giratório com 5 pontos).

const SLIME := preload("res://scenes/enemies/slime.tscn")


func _slime(w: World, pos: Vector2) -> Slime:
	var s: Slime = colocar(w, SLIME, pos)
	s.set_physics_process(false)
	return s


func _usar(p: Player, id: StringName, mira: Vector2) -> void:
	p.aprender_de_graca(id)
	var t: Array[StringName] = [id]
	p.teclas = t
	p.mana = 500.0
	p.mira_forcada = mira
	await get_tree().physics_frame
	checar(p.usar_habilidade_por_id(id), "usou " + String(id))


func _ready() -> void:
	var w := await criar_mundo(0, true, &"ladino", &"humano")
	var p := w.jogador
	p.aprender_de_graca(&"toxina")
	var slimes: Array[Slime] = []
	for d in [Vector2(40, -6), Vector2(52, 10), Vector2(-42, 6), Vector2(-30, 18)]:
		slimes.append(_slime(w, p.global_position + d))
	await esperar(0.3)
	await _usar(p, &"nuvem_toxica", p.global_position + Vector2(46, 2))
	await _usar(p, &"frasco_de_acido", p.global_position + Vector2(-36, 12))
	await esperar(1.3)
	w.hud.mostrar_aviso("")
	await salvar_print("novidades/arvore_ladino_venenos.png")
	for s in slimes:
		s.queue_free()
	await esperar(5.0)
	var outros: Array[Slime] = []
	for d in [Vector2(56, 0), Vector2(-50, 20), Vector2(10, -48)]:
		outros.append(_slime(w, p.global_position + d))
	p.recursos.ganhar_combo(5)
	await _usar(p, &"leque_giratorio", p.global_position + Vector2(30, 0))
	await esperar(0.12)
	w.hud.mostrar_aviso("")
	await salvar_print("novidades/arvore_ladino_leque.png")
	terminar()
