extends TesteBase
## Prints das habilidades novas do Arqueiro (precisa de janela, sem --headless):
##   - evidence/novidades/arvore_arqueiro_engenhoqueiro.png: Campo minado em volta, a Torre de
##     besta atirando e a Flecha do horizonte (gigante) voando;
##   - evidence/novidades/arvore_arqueiro_domador.png: o falcão do Laço, o javali domado e o
##     Estouro da boiada passando pelos slimes.

const SLIME := preload("res://scenes/enemies/slime.tscn")
const ANIMAL := preload("res://scenes/animals/animal.tscn")


func _ready() -> void:
	var w := await criar_mundo(0, true, &"arqueiro", &"elfo")
	var p := w.jogador
	p.global_position = w.centro + Vector2(0, 40)
	await esperar(0.5)
	w.hud.mostrar_aviso("")
	var o := p.global_position

	# 1) Engenhoqueiro + Atirador.
	var slimes: Array[Node] = []
	for v in [Vector2(90, -30), Vector2(110, 10), Vector2(-100, 30)]:
		var s: Slime = colocar(w, SLIME, o + v)
		s.set_physics_process(false)
		s.vida.maximo = 100.0
		s.vida.atual = 100.0
		slimes.append(s)
	await _usar(p, &"campo_minado", o)
	await _usar(p, &"torre_de_besta", o + Vector2(40, -10))
	await esperar(1.0)
	await _usar(p, &"flecha_do_horizonte", o + Vector2(-100, 20))
	await esperar(0.12)
	w.hud.mostrar_aviso("")
	await salvar_print("novidades/arvore_arqueiro_engenhoqueiro.png")
	for g in [&"invocacoes", &"projeteis", &"inimigos"]:
		for n in get_tree().get_nodes_in_group(g):
			n.queue_free()
	await esperar(0.3)

	# 2) Domador.
	p.aprender_de_graca(&"laco")
	var bicho: Animal = ANIMAL.instantiate()
	bicho.especie = &"javali"
	bicho.position = o + Vector2(-30, 20)
	w.entidades.add_child(bicho, true)
	await get_tree().physics_frame
	bicho.vida.atual = 1.0
	await _usar(p, &"domar", bicho.global_position)
	for v in [Vector2(60, -4), Vector2(100, 6), Vector2(70, -50)]:
		var s: Slime = colocar(w, SLIME, o + v)
		s.set_physics_process(false)
		s.vida.maximo = 100.0
		s.vida.atual = 100.0
	await esperar(0.6)
	await _usar(p, &"estouro_da_boiada", o + Vector2(140, 0))
	await esperar(0.45)
	w.hud.mostrar_aviso("")
	await salvar_print("novidades/arvore_arqueiro_domador.png")
	terminar()


func _usar(p: Player, id: StringName, mira: Vector2) -> void:
	p.aprender_de_graca(id)
	p.teclas = [&"tiro_carregado", &"armadilha", id] as Array[StringName]
	p.mana = p.ficha.mana_maxima()
	p._recargas.clear()
	p._prontas_no_anfitriao.clear()
	p.mira_forcada = mira
	await get_tree().physics_frame
	checar(p.usar_habilidade_por_id(id), "usou %s" % id)
	await get_tree().physics_frame
