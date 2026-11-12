extends TesteBase
## Prints das habilidades novas do Guerreiro (precisa de janela; não roda na bateria).
##   1. arvore_guerreiro_titanica.png: Fúria titânica (cresce) dentro do Bastião, com o
##      Estandarte ao lado e slimes com Medo (Grito de guerra).
##   2. arvore_guerreiro_redemoinho.png: Redemoinho no meio dos slimes, um deles marcado
##      pela Ordem de ataque.

const SLIME := preload("res://scenes/enemies/slime.tscn")


func _ready() -> void:
	var w := await criar_mundo(0, true, &"guerreiro", &"anao")
	var p := w.jogador
	p.global_position = w.centro + Vector2(0, 50)
	await get_tree().physics_frame
	var slimes: Array[Slime] = []
	for d in [Vector2(-38, -6), Vector2(36, 4), Vector2(-20, 30), Vector2(26, -30)]:
		var s: Slime = colocar(w, SLIME, p.global_position + d)
		s.set_physics_process(false)
		s.vida.maximo = 500.0
		s.vida.atual = 500.0
		slimes.append(s)
	await get_tree().physics_frame
	for id in [&"grito_de_guerra", &"bastiao", &"furia_titanica", &"estandarte"]:
		await _usar(p, id, p.global_position + Vector2(-30, 10))
		await esperar(0.15)
	w.hud.mostrar_aviso("")
	await esperar(0.5)
	await salvar_print("novidades/arvore_guerreiro_titanica.png")
	await esperar(0.5)
	await _usar(p, &"ordem_de_ataque", slimes[1].global_position)
	await _usar(p, &"redemoinho", p.global_position + Vector2(30, 0))
	await esperar(0.55)
	w.hud.mostrar_aviso("")
	await salvar_print("novidades/arvore_guerreiro_redemoinho.png")
	terminar()


func _usar(p: Player, id: StringName, mira: Vector2) -> void:
	p.aprender_de_graca(id)
	var t: Array[StringName] = [id]
	p.teclas = t
	p._recargas.clear()
	p._prontas_no_anfitriao.clear()
	p.mana = p.ficha.mana_maxima()
	p.mira_forcada = mira
	await get_tree().physics_frame
	p.usar_habilidade_por_id(id)
