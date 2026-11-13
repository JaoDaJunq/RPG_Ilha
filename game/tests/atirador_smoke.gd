extends TesteBase
## Arqueiro inimigo (Atirador): anda, mantém distância, atira; a flecha machuca, para na
## Barreira do Clérigo e na cúpula do Bastião do Guerreiro; respeita Cego, Medo e Provocado;
## solta saque e experiência; nasce em grupos no mundo e à noite.

const ATIRADOR := preload("res://scenes/enemies/atirador.tscn")

var w: World
var p: Player
## Flechas inimigas criadas e como cada uma acabou (acertou algo?).
var _flechas := 0
var _acertos := 0
var _paradas := 0


func _ready() -> void:
	w = await criar_mundo(0, true, &"guerreiro")
	p = w.jogador
	p.global_position = w.centro + Vector2(0, 60)
	w.entidades.child_entered_tree.connect(_nasceu)
	await get_tree().physics_frame
	await _anda_e_distancia()
	await _atira_e_machuca()
	await _estados()
	await _barreira()
	await _bastiao()
	await _saque()
	await _no_mundo()
	terminar()


func _nasceu(n: Node) -> void:
	var pr := n as Projetil
	if pr and pr.do_inimigo:
		_flechas += 1
		pr.terminou.connect(func(_pos: Vector2, acertou: bool) -> void:
			if acertou:
				_acertos += 1
			else:
				_paradas += 1)


func _atirador(pos: Vector2, recarga := 99.0) -> Atirador:
	var a: Atirador = colocar(w, ATIRADOR, pos)
	await get_tree().physics_frame
	a._recarga = recarga
	return a


func _limpar() -> void:
	for a in get_tree().get_nodes_in_group(&"atiradores"):
		a.queue_free()
	for pr in get_tree().get_nodes_in_group(&"projeteis"):
		pr.queue_free()
	p.vida.curar_tudo()
	p.efeitos.limpar_ruins()
	_flechas = 0
	_acertos = 0
	_paradas = 0
	await esperar(0.3)


func _anda_e_distancia() -> void:
	# Longe (mas vendo): chega mais perto.
	var a := await _atirador(p.global_position + Vector2(120, 0))
	checar(a.is_in_group(&"inimigos") and a.visual.sprite_frames.has_animation(&"atirando"), "o arqueiro inimigo é um inimigo, com as animações do pacote (parado, andando, atirando)")
	await esperar(1.0)
	var d := a.global_position.distance_to(p.global_position)
	checar(d < 112.0 and a.animacao == &"andando", "longe, ele anda até o jogador (%.0f px)" % d)
	# Perto demais: recua para manter distância.
	a.global_position = p.global_position + Vector2(24, 0)
	await esperar(1.2)
	d = a.global_position.distance_to(p.global_position)
	checar(d > 40.0, "perto demais, ele recua (%.0f px)" % d)
	await _limpar()


func _atira_e_machuca() -> void:
	var a := await _atirador(p.global_position + Vector2(80, 0), 0.0)
	await esperar(0.2)
	checar(a.mirando() and a.animacao == &"atirando", "puxa o arco antes de atirar (o aviso)")
	await esperar(1.3)
	checar(_flechas >= 1, "atirou uma flecha (%d)" % _flechas)
	checar(_acertos >= 1 and p.vida.atual < p.vida.maximo, "a flecha acertou e machucou o jogador (vida %.1f de %.1f)" % [p.vida.atual, p.vida.maximo])
	await _limpar()


func _estados() -> void:
	# Cego (sempre erra): a flecha sai torta e não pega.
	var a := await _atirador(p.global_position + Vector2(90, 0), 0.0)
	a.efeitos.aplicar(EfeitosEstado.CEGO, 5.0, 1.0)
	await esperar(1.6)
	checar(_flechas >= 1 and is_equal_approx(p.vida.atual, p.vida.maximo), "Cego: atira mas erra (%d flechas, vida cheia)" % _flechas)
	await _limpar()
	# Medo: foge de quem assustou e não atira.
	a = await _atirador(p.global_position + Vector2(70, 0), 0.0)
	a.efeitos.aplicar(EfeitosEstado.MEDO, 2.0, 0.0, p)
	await get_tree().physics_frame
	var antes := a.global_position.distance_to(p.global_position)
	await esperar(1.0)
	checar(a.global_position.distance_to(p.global_position) > antes + 10.0 and _flechas == 0, "Medo: foge e não atira (%.0f → %.0f px)" % [antes, a.global_position.distance_to(p.global_position)])
	await _limpar()
	# Provocado: corre atrás de quem provocou (mesmo na distância em que ficaria parado).
	a = await _atirador(p.global_position + Vector2(85, 0))
	a.efeitos.aplicar(EfeitosEstado.PROVOCADO, 4.0, 0.0, p)
	await esperar(1.4)
	var d := a.global_position.distance_to(p.global_position)
	checar(d < 65.0, "Provocado: vem até quem provocou, saindo da distância boa (85 → %.0f px)" % d)
	await _limpar()
	# Atordoado: não anda nem atira; Preso: não anda, mas atira.
	a = await _atirador(p.global_position + Vector2(80, 0), 0.0)
	a.efeitos.aplicar(EfeitosEstado.ATORDOADO, 1.5)
	await esperar(1.0)
	checar(_flechas == 0, "Atordoado: não atira")
	await _limpar()
	a = await _atirador(p.global_position + Vector2(80, 0), 0.0)
	a.efeitos.aplicar(EfeitosEstado.PRESO, 3.0)
	var pos := a.global_position
	await esperar(1.2)
	checar(_flechas >= 1 and a.global_position.distance_to(pos) < 1.0, "Preso: não sai do lugar, mas atira")
	await _limpar()
	# A armadilha do Arqueiro também pega o arqueiro inimigo.
	var armadilha: Node2D = colocar(w, preload("res://scenes/abilities/armadilha.tscn"), p.global_position + Vector2(60, 40))
	await get_tree().physics_frame
	a = await _atirador(armadilha.global_position + Vector2(0, 14))
	a.global_position = armadilha.global_position
	await esperar(0.3)
	checar(a.efeitos.tem(EfeitosEstado.PRESO), "a armadilha prende o arqueiro inimigo")
	await _limpar()


## Usa a ativa `id` da árvore de `classe` (a lógica de verdade), mirando em `mira`.
func _usar_logica(classe: StringName, id: StringName, mira: Vector2) -> void:
	var hab := ArvoreData.no(classe, id).habilidade
	var logica: HabilidadeLogica = Logicas.classe_da_logica(hab.logica).new()
	logica.executar(p, hab, (mira - p.global_position).normalized(), mira, 0.0)


func _barreira() -> void:
	var a := await _atirador(p.global_position + Vector2(90, 0), 0.0)
	_usar_logica(&"clerigo", &"barreira", a.global_position)
	await esperar(1.6)
	checar(_flechas >= 1 and _paradas == _flechas and _acertos == 0, "Barreira: as flechas param na parede de luz (%d de %d)" % [_paradas, _flechas])
	checar(is_equal_approx(p.vida.atual, p.vida.maximo), "Barreira: o jogador atrás dela não se machuca")
	await esperar(LogicasClerigo.Barreira.DURACAO)  # a parede acaba
	await _limpar()


func _bastiao() -> void:
	var a := await _atirador(p.global_position + Vector2(90, 0), 0.0)
	_usar_logica(&"guerreiro", &"bastiao", p.global_position)
	await esperar(1.6)
	checar(_flechas >= 1 and _paradas == _flechas and _acertos == 0, "Bastião: as flechas param na cúpula (%d de %d)" % [_paradas, _flechas])
	checar(is_equal_approx(p.vida.atual, p.vida.maximo), "Bastião: quem está na cúpula não leva a flecha")
	await esperar(LogicasGuerreiro.Bastiao.DURACAO)
	# Sem a cúpula, a flecha volta a pegar.
	a._recarga = 0.0
	await esperar(1.5)
	checar(_acertos >= 1, "sem a cúpula, a flecha volta a acertar")
	await _limpar()


func _saque() -> void:
	var a := await _atirador(p.global_position + Vector2(40, 0))
	var xp := p.xp + p.nivel * 1000
	a.vida.atual = 1.0
	Golpes.acertar(p, a, 5.0, &"fisico")
	await get_tree().physics_frame
	checar(not is_instance_valid(a) or a.is_queued_for_deletion(), "derrotado, o arqueiro some")
	checar(get_tree().get_nodes_in_group(&"itens_chao").size() >= 1, "deixa saque no chão (penas)")
	checar(p.xp + p.nivel * 1000 > xp, "dá experiência para quem estava perto")
	await pegar_do_chao(p)
	await _limpar()


func _no_mundo() -> void:
	# Grupos de 2, longe da fogueira (o teste liga a geração; nos outros testes fica em 0).
	w.gerar_recursos = true
	w.grupos_atiradores = 2
	w._criar_atiradores()
	var lista := get_tree().get_nodes_in_group(&"atiradores")
	var longe := true
	for a in lista:
		longe = longe and (a as Node2D).global_position.distance_to(w.centro) >= 250.0
	checar(lista.size() == 4 and longe, "o mundo põe 2 grupos de 2 arqueiros longe da fogueira (%d)" % lista.size())
	for a in lista:
		a.queue_free()
	await get_tree().physics_frame
	# À noite nasce o arqueiro da noite (no escuro, longe); amanhece e ele vai embora.
	w.noite = true
	for k in 60:
		w._atirador_da_noite(get_tree().get_nodes_in_group(&"jogadores"))
		if not get_tree().get_nodes_in_group(&"atiradores").is_empty():
			break
	var noturnos := get_tree().get_nodes_in_group(&"atiradores")
	checar(noturnos.size() == 1 and (noturnos[0] as Atirador).noturno, "à noite nasce um arqueiro da noite (1 + 1 por jogador no máximo)")
	for k in 60:
		w._atirador_da_noite(get_tree().get_nodes_in_group(&"jogadores"))
	checar(get_tree().get_nodes_in_group(&"atiradores").size() <= 2, "não passa do limite da noite (%d)" % get_tree().get_nodes_in_group(&"atiradores").size())
	w.noite = false
	await esperar(0.2)
	checar(get_tree().get_nodes_in_group(&"atiradores").filter(func(a: Node) -> bool: return not a.is_queued_for_deletion()).is_empty(), "amanheceu: o arqueiro da noite vai embora")
	w.grupos_atiradores = 0
	w.gerar_recursos = false
