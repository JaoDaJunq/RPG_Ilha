extends TesteBase
## Prints das melhorias de arte do pedido L35 (precisa de janela, sem --headless):
##   <godot> --path game res://tests/print_melhorias.tscn -- --cena=cupulas
## Salva evidence/novidades/melhorias_<cena>.png. Cenas: cupulas, cura, ladino, mago,
## barreira, bau, critico, molhado.

const SLIME := preload("res://scenes/enemies/slime.tscn")
const ATIRADOR := preload("res://scenes/enemies/atirador.tscn")

var w: World
var p: Player


func _ready() -> void:
	var cena := "cupulas"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--cena="):
			cena = a.trim_prefix("--cena=")
	var classe: StringName = {"cupulas": &"clerigo", "cura": &"clerigo", "barreira": &"clerigo", "ladino": &"ladino", "mago": &"mago"}.get(cena, &"guerreiro")
	var raca := {&"mago": &"humano", &"ladino": &"humano", &"clerigo": &"anao", &"guerreiro": &"ogro"}
	w = await criar_mundo(0, true, classe, raca.get(classe, &"humano"))
	p = w.jogador
	p.global_position = w.centro + Vector2(0, 40)
	await esperar(0.5)
	w.hud.mostrar_aviso("")
	match cena:
		"cupulas":
			await _cupulas()
		"cura":
			await _cura()
		"ladino":
			await _ladino()
		"mago":
			await _mago()
		"barreira":
			await _barreira()
		"bau":
			await _bau()
		"critico":
			await _critico()
		"molhado":
			await _molhado()
	w.hud.mostrar_aviso("")
	await salvar_print("novidades/melhorias_%s.png" % cena)
	terminar()


## Cúpula média (Santuário, raio 48) e a grande (Muralha da fé, raio 64), com slimes dentro.
func _cupulas() -> void:
	var o := p.global_position
	_slime(o + Vector2(-90, -10))
	_slime(o + Vector2(70, 0))
	p.global_position = o + Vector2(-90, 0)
	await esperar(0.1)
	await _usar(&"santuario", p.global_position)
	p.global_position = o + Vector2(70, 10)
	await esperar(0.1)
	await _usar(&"muralha_da_fe", p.global_position)
	p.global_position = o + Vector2(-10, 15)
	await esperar(0.5)


## Círculo de cura (raio 36) e Fonte da vida (raio 72).
func _cura() -> void:
	var o := p.global_position
	await _usar(&"circulo_de_cura", o + Vector2(-90, 0))
	await _usar(&"fonte_da_vida", o + Vector2(60, 0))
	p.global_position = o + Vector2(-15, 25)
	await esperar(0.5)


## Poça de ácido e nuvem tóxica.
func _ladino() -> void:
	var o := p.global_position
	_slime(o + Vector2(-60, -20))
	_slime(o + Vector2(70, 10))
	await _usar(&"nuvem_toxica", o + Vector2(-60, -20))
	await _usar(&"frasco_de_acido", o + Vector2(70, 10))
	await esperar(1.0)


## Golem, totem tesla, tornado de fogo e nevasca, no tamanho real.
func _mago() -> void:
	var o := p.global_position
	_slime(o + Vector2(-60, -10))
	_slime(o + Vector2(95, -45))
	await _usar(&"nevasca", o + Vector2(95, -45))
	await _usar(&"golem_de_pedra", o + Vector2(-40, -10))
	await _usar(&"totem_tesla", o + Vector2(40, 40))
	await esperar(0.3)
	await _usar(&"tornado_de_fogo", o + Vector2(0, -60))
	await esperar(0.6)


## Barreira do Clérigo: a parede de luz entre ele e os slimes (de pé e de lado).
func _barreira() -> void:
	var o := p.global_position
	for k in 3:
		_slime(o + Vector2(-30 + 30 * k, -75))
	await esperar(0.1)
	await _usar(&"barreira", o + Vector2(0, -100))
	p.global_position = o + Vector2(90, 30)
	await esperar(0.1)
	_slime(o + Vector2(170, 30))
	await _usar(&"barreira", o + Vector2(200, 30))
	p.global_position = o + Vector2(45, 10)  # a câmera pega as duas paredes
	await esperar(0.6)


## Baú trancado, o mesmo aberto (com a chave) e a chave no chão e na barra.
func _bau() -> void:
	var o := p.global_position
	var b1 := BauTrancado.new()
	b1.name = "BauPrint1"
	b1.position = o + Vector2(-50, -10)
	w.entidades.add_child(b1)
	var b2 := BauTrancado.new()
	b2.name = "BauPrint2"
	b2.position = o + Vector2(20, -10)
	w.entidades.add_child(b2)
	await esperar(0.2)
	p.inventario.adicionar(BauTrancado.CHAVE, 2)
	p.global_position = o + Vector2(20, 12)
	b2.interagir(p)
	World.soltar_itens(p, o + Vector2(-20, 30), [[BauTrancado.CHAVE, 1]])
	# Um terceiro só aberto (sem o saque na frente), para ver o desenho do baú aberto.
	var b3 := BauTrancado.new()
	b3.name = "BauPrint3"
	b3.position = o + Vector2(70, 20)
	w.entidades.add_child(b3)
	await esperar(0.1)
	b3._mostrar_aberto()
	await esperar(0.6)
	w.hud.mostrar_aviso("")


## O estouro do crítico (Tiro carregado cheio do guerreiro: golpes com crítico garantido).
func _critico() -> void:
	var o := p.global_position
	var s := _slime(o + Vector2(24, 0))
	var s2 := _slime(o + Vector2(-40, -30))
	await esperar(0.2)
	Passivas.chance_critico = 1.0
	Golpes.acertar(p, s, 1.0, &"fisico")
	Golpes.acertar(p, s2, 1.0, &"fisico")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	# Congela o estouro no quadro do meio (o maior) para o print.
	for e in get_tree().root.find_children("*", "Efeito", true, false):
		if e is Efeito and (e as Efeito).animation == &"tocar":
			(e as Efeito).pause()
			(e as Efeito).frame = 1
	await esperar(0.1)
	Passivas.chance_critico = -1.0


## Molhado: o jogador e um arqueiro inimigo pingando; um respingo de quem entrou na água.
func _molhado() -> void:
	var agua := _celula_agua()
	var o := p.global_position
	if agua != Vector2.INF:
		o = agua + Vector2(-30, 0)
		p.global_position = o
	await esperar(0.2)
	p.efeitos.aplicar(EfeitosEstado.MOLHADO, 30.0)
	var a: Atirador = colocar(w, ATIRADOR, o + Vector2(-40, 10))
	a.set_physics_process(false)
	a.efeitos.aplicar(EfeitosEstado.MOLHADO, 30.0)
	var s := _slime(o + Vector2(40, 10))
	s.efeitos.aplicar(EfeitosEstado.MOLHADO, 30.0)
	if agua != Vector2.INF:
		w.entidades.add_child(Efeito.criar(&"respingo", agua))
	await esperar(0.35)


## Ponto do mundo em cima da água mais perto da fogueira (ou INF).
func _celula_agua() -> Vector2:
	var melhor := Vector2.INF
	for cel in w.chao.get_used_cells():
		if w.tipo_do_chao(cel) == World.Chao.AGUA:
			var pos := w.chao.to_global(w.chao.map_to_local(cel))
			if pos.distance_to(w.centro) < melhor.distance_to(w.centro):
				melhor = pos
	return melhor


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
