extends TesteBase
## Prints do arqueiro inimigo (precisa de janela; não roda na bateria):
##   1. atirador_atirando.png: dois arqueiros, um puxando o arco e uma flecha voando.
##   2. atirador_barreira.png: a Barreira do Clérigo segurando as flechas.
##   3. atirador_bastiao.png: a cúpula do Bastião segurando as flechas.

const ATIRADOR := preload("res://scenes/enemies/atirador.tscn")


func _ready() -> void:
	var w := await criar_mundo(0, true, &"clerigo", &"humano")
	var p := w.jogador
	p.global_position = w.centro + Vector2(-20, 70)
	await get_tree().physics_frame
	var arqueiros: Array[Atirador] = []
	for d in [Vector2(72, -14), Vector2(84, 22)]:
		var a: Atirador = colocar(w, ATIRADOR, p.global_position + d)
		arqueiros.append(a)
	await get_tree().physics_frame
	for a in arqueiros:
		a._recarga = 99.0
		a.raio_visao = 200.0
	await esperar(0.6)
	# 1. Um atira (a flecha voando), o outro está puxando o arco.
	arqueiros[0]._recarga = 0.0
	await esperar(0.35)
	arqueiros[1]._recarga = 0.0
	await esperar(0.35)
	w.hud.mostrar_aviso("")
	await salvar_print("novidades/atirador_atirando.png")
	await esperar(2.0)
	p.vida.curar_tudo()
	# 2. Barreira na frente: as flechas param nela.
	_logica(p, &"clerigo", &"barreira", arqueiros[0].global_position)
	for a in arqueiros:
		a._recarga = 0.0
	await esperar(0.86)
	w.hud.mostrar_aviso("")
	await salvar_print("novidades/atirador_barreira.png")
	await esperar(LogicasClerigo.Barreira.DURACAO)
	p.vida.curar_tudo()
	# 3. Cúpula do Bastião.
	_logica(p, &"guerreiro", &"bastiao", p.global_position)
	for a in arqueiros:
		a._recarga = 0.0
	await esperar(0.86)
	w.hud.mostrar_aviso("")
	await salvar_print("novidades/atirador_bastiao.png")
	terminar()


func _logica(p: Player, classe: StringName, id: StringName, mira: Vector2) -> void:
	var hab := ArvoreData.no(classe, id).habilidade
	(Logicas.classe_da_logica(hab.logica).new() as HabilidadeLogica).executar(p, hab, (mira - p.global_position).normalized(), mira, 0.0)
