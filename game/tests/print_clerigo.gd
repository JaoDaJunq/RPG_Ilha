extends TesteBase
## Prints das habilidades novas da árvore do Clérigo (precisa de janela):
##   <godot> --path game res://tests/print_clerigo.tscn
## Salva evidence/novidades/arvore_clerigo_noite.png (Amanhecer e Martelo giratório à noite,
## com slimes da noite em volta) e arvore_clerigo_dia.png (Barreira, Círculo de cura e o
## Martelo da justiça voando).

const SLIME := preload("res://scenes/enemies/slime.tscn")


func _ready() -> void:
	var w := await criar_mundo(0, true, &"clerigo", &"humano")
	var p := w.jogador
	p.global_position = w.centro + Vector2(0, 90)
	await esperar(0.3)

	# Dia: Barreira na frente, Círculo de cura ao lado e o martelo voando.
	for k in 3:
		var s: Slime = colocar(w, SLIME, p.global_position + Vector2(70, -20 + 20 * k))
		s.set_physics_process(false)
	await _usar(p, &"barreira", p.global_position + Vector2(100, 0))
	await _usar(p, &"circulo_de_cura", p.global_position + Vector2(-34, 10))
	await esperar(0.5)
	await _usar(p, &"martelo_da_justica", p.global_position + Vector2(100, -40))
	await esperar(0.15)
	await salvar_print("novidades/arvore_clerigo_dia.png")
	await esperar(2.0)
	for s in get_tree().get_nodes_in_group(&"inimigos"):
		s.queue_free()

	# Noite: slimes da noite chegando; Amanhecer e Martelo giratório.
	w._aplicar_ciclo(true, true)
	p.global_position = w.centro + Vector2(160, 160)
	await esperar(0.3)
	for k in 5:
		var s: Slime = SLIME.instantiate()
		s.noturno = true
		s.position = p.global_position + Vector2(130, 0).rotated(k * TAU / 5.0)
		w.entidades.add_child(s, true)
	await esperar(0.2)
	await _usar(p, &"amanhecer", p.global_position)
	await _usar(p, &"martelo_giratorio", p.global_position)
	await esperar(0.3)
	await salvar_print("novidades/arvore_clerigo_noite.png")
	terminar()


func _usar(p: Player, id: StringName, mira: Vector2) -> void:
	p.aprender_de_graca(id)
	var t: Array[StringName] = [id]
	p.teclas = t
	p._recargas.clear()
	p._prontas_no_anfitriao.clear()
	p.mana = p.ficha.mana_maxima()
	p.mira_forcada = mira
	checar(p.usar_habilidade_por_id(id), "usou " + id)
	await get_tree().physics_frame
