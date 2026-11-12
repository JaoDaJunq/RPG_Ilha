extends TesteBase
## Prints das habilidades novas do Mago (precisa de janela, sem --headless):
##   evidence/novidades/arvore_mago_fogo.png       Chuva de meteoros, Tornado e Rastro de chamas
##   evidence/novidades/arvore_mago_controle.png   Nevasca, Muralha de gelo, Totem tesla e Golem

const SLIME := preload("res://scenes/enemies/slime.tscn")

var w: World
var p: Player


func _ready() -> void:
	w = await criar_mundo(0, true, &"mago")
	p = w.jogador
	var P := w.centro + Vector2(0, 70)
	p.global_position = P
	await esperar(0.3)
	w.hud.mostrar_aviso("")
	# Fogo
	var lista: Array[Slime] = []
	for v in [Vector2(70, -20), Vector2(84, 6), Vector2(60, 24), Vector2(-60, 10), Vector2(-40, -30)]:
		lista.append(_slime(P + v))
	_usar(&"chuva_de_meteoros", P + Vector2(74, 0))
	_usar(&"tornado_de_fogo", P + Vector2(-80, 0))
	_usar(&"rastro_de_chamas", P)
	for k in 5:
		p.global_position += Vector2(0, 7)
		await esperar(0.12)
	await esperar(0.15)
	w.hud.mostrar_aviso("")
	await salvar_print("novidades/arvore_mago_fogo.png")
	for n in w.entidades.get_children():
		if n is Slime or n is Zona or n is Invocacao:
			n.queue_free()
	await esperar(2.5)
	# Gelo, raio e terra
	p.global_position = P
	for v in [Vector2(80, -10), Vector2(96, 16), Vector2(-70, -20), Vector2(-90, 20), Vector2(20, -50)]:
		_slime(P + v)
	_usar(&"nevasca", P + Vector2(88, 0))
	_usar(&"muralha_de_gelo", P + Vector2(-44, 0))
	_usar(&"totem_tesla", P + Vector2(30, -40))
	_usar(&"golem_de_pedra", P + Vector2(-30, 30))
	await esperar(1.3)
	w.hud.mostrar_aviso("")
	await salvar_print("novidades/arvore_mago_controle.png")
	terminar()


func _slime(pos: Vector2) -> Slime:
	var s: Slime = colocar(w, SLIME, pos)
	s.set_physics_process(false)
	s.vida.maximo = 100.0
	s.vida.atual = 100.0
	return s


func _usar(id: StringName, mira: Vector2) -> void:
	if not p.tem(id):
		p.aprender_de_graca(id)
	p.teclas = ArvoreData.padrao(&"mago").duplicate()
	p.teclas.append(id)
	p.mana = p.ficha.mana_maxima()
	p._recargas.clear()
	p._prontas_no_anfitriao.clear()
	p.mira_forcada = mira
	p.usar_habilidade_por_id(id)
