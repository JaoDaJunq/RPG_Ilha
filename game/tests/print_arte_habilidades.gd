extends TesteBase
## Prints da arte própria das habilidades novas (pedido L33), uma classe por vez (precisa de
## janela, sem --headless):
##   <godot> --path game res://tests/print_arte_habilidades.tscn -- --classe=arqueiro
## Salva evidence/novidades/arte_hab_<classe>.png. Classes: arqueiro, mago, ladino, clerigo,
## guerreiro.

const SLIME := preload("res://scenes/enemies/slime.tscn")

var w: World
var p: Player


func _ready() -> void:
	var classe := &"arqueiro"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--classe="):
			classe = StringName(a.trim_prefix("--classe="))
	var raca := {&"arqueiro": &"elfo", &"mago": &"humano", &"ladino": &"humano", &"clerigo": &"anao", &"guerreiro": &"ogro"}
	w = await criar_mundo(0, true, classe, raca.get(classe, &"humano"))
	p = w.jogador
	p.global_position = w.centro + Vector2(0, 40)
	await esperar(0.5)
	w.hud.mostrar_aviso("")
	match classe:
		&"arqueiro":
			await _arqueiro()
		&"mago":
			await _mago()
		&"ladino":
			await _ladino()
		&"clerigo":
			await _clerigo()
		&"guerreiro":
			await _guerreiro()
	w.hud.mostrar_aviso("")
	await salvar_print("novidades/arte_hab_%s.png" % classe)
	terminar()


## Falcão (Assobio) com a marca no alvo, mina, torre de besta e a rede caída num slime.
func _arqueiro() -> void:
	var o := p.global_position
	var a := _slime(o + Vector2(70, -30))
	_slime(o + Vector2(80, 30))
	var c := _slime(o + Vector2(-70, 20))
	await _usar(&"assobio", a.global_position)
	await _usar(&"mina_de_fogo", o + Vector2(-30, -30))
	await _usar(&"mina_de_fogo", o + Vector2(-50, -10))
	await _usar(&"torre_de_besta", o + Vector2(30, 30))
	await _usar(&"rede", c.global_position)
	await esperar(0.45)


## Golem socando, totem tesla, tornado de fogo, nevasca e espinhos.
func _mago() -> void:
	var o := p.global_position
	_slime(o + Vector2(-60, -10))
	_slime(o + Vector2(70, 40))
	_slime(o + Vector2(95, -45))
	await _usar(&"nevasca", o + Vector2(95, -45))
	await _usar(&"golem_de_pedra", o + Vector2(-40, -10))
	await _usar(&"totem_tesla", o + Vector2(40, 40))
	await _usar(&"espinhos", o + Vector2(-60, 40))
	await esperar(0.5)
	await _usar(&"tornado_de_fogo", o + Vector2(0, -60))
	await _esperar_golem()


## Nuvem tóxica, poça de ácido e a caveira da Marca da morte.
func _ladino() -> void:
	var o := p.global_position
	var a := _slime(o + Vector2(60, -30))
	_slime(o + Vector2(-60, -30))
	_slime(o + Vector2(85, 25))
	await _usar(&"nuvem_toxica", o + Vector2(-60, -30))
	await _usar(&"frasco_de_acido", o + Vector2(85, 25))
	await _usar(&"marca_da_morte", a.global_position)
	await esperar(0.5)


## Cúpula (Santuário), parede de luz (Barreira), círculo de cura e o martelo girando.
func _clerigo() -> void:
	var o := p.global_position
	# Santuário à esquerda; o Clérigo sai dele e põe a Barreira entre ele e os slimes.
	o += Vector2(60, 30)
	p.global_position = o + Vector2(-100, 0)
	_slime(o + Vector2(-80, 0))
	await esperar(0.1)
	await _usar(&"santuario", p.global_position)
	p.global_position = o
	for k in 3:
		_slime(o + Vector2(-30 + 30 * k, -75))
	await esperar(0.1)
	await _usar(&"barreira", o + Vector2(0, -100))
	await _usar(&"circulo_de_cura", o + Vector2(70, 20))
	await _usar(&"martelo_giratorio", o)
	await esperar(0.45)


## Estandarte, escudo arremessado e a corrente voando.
func _guerreiro() -> void:
	var o := p.global_position
	_slime(o + Vector2(110, -40))
	_slime(o + Vector2(110, 40))
	await _usar(&"estandarte", o + Vector2(-60, 40))
	await esperar(0.3)
	await _usar(&"escudo_arremessado", o + Vector2(110, -40))
	await _usar(&"corrente", o + Vector2(110, 40))
	await esperar(0.2)


func _esperar_golem() -> void:
	# Tira o print no instante do soco (até 2 s esperando).
	var g: Invocacao = null
	for n in get_tree().get_nodes_in_group(&"golem_pedra"):
		g = n
	var t := 0.0
	while g and is_instance_valid(g) and g.visual.animation != &"ataque" and t < 2.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	await get_tree().process_frame


func _slime(pos: Vector2) -> Slime:
	var s: Slime = colocar(w, SLIME, pos)
	s.set_physics_process(false)
	s.vida.maximo = 500.0
	s.vida.atual = 500.0
	return s


func _usar(id: StringName, mira: Vector2) -> void:
	p.aprender_de_graca(id)
	var t: Array[StringName] = [id]
	p.teclas = t
	p._recargas.clear()
	p._prontas_no_anfitriao.clear()
	p.mana = p.ficha.mana_maxima()
	p.mira_forcada = mira
	await get_tree().physics_frame
	checar(p.usar_habilidade_por_id(id), "usou %s" % id)
	await get_tree().physics_frame
