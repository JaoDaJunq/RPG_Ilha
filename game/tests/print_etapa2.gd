extends TesteBase
## Prints da etapa 2 (L39; precisa de janela, não roda com --headless): cada bicho e inimigo
## novo no seu bioma, a fornalha, os minérios, os coletáveis e o livro de receitas com os
## itens novos. Salva em evidence/novidades/etapa2_*.png.
## Uso (da raiz):  <godot> --path game res://tests/print_etapa2.tscn

## Pontos de cada região (blocos), os mesmos do print do mundo (print_mundo.gd).
const PONTOS := {
	Regioes.Id.CLAREIRA: Vector2i(99, 70),
	Regioes.Id.BOSQUE: Vector2i(146, 74),
	Regioes.Id.PRAIA: Vector2i(96, 108),
	Regioes.Id.PANTANO: Vector2i(36, 72),
	Regioes.Id.COLINAS: Vector2i(84, 22),
	Regioes.Id.RUINAS: Vector2i(129, 33),
}

## [print, região, [[tipo, deslocamento], ...]]
const BICHOS := [
	["cervo", Regioes.Id.BOSQUE, [["cervo", Vector2(80, 6)], ["cervo", Vector2(-90, -10)]]],
	["caranguejo", Regioes.Id.PRAIA, [["caranguejo", Vector2(40, 6)], ["caranguejo", Vector2(-50, 16)]]],
	["sapo", Regioes.Id.PANTANO, [["sapo", Vector2(36, 8)], ["sapo", Vector2(-44, -6)]]],
	["cabra", Regioes.Id.COLINAS, [["cabra", Vector2(44, 4)], ["cabra", Vector2(-50, 12)]]],
	["slime_fogo", Regioes.Id.PRAIA, [["slime_fogo", Vector2(44, 4)]]],
	["slime_gelo", Regioes.Id.COLINAS, [["slime_gelo", Vector2(44, 4)]]],
	["slime_veneno", Regioes.Id.PANTANO, [["slime_veneno", Vector2(44, 4)]]],
	["bandido_guerreiro", Regioes.Id.BOSQUE, [["bandido_guerreiro", Vector2(46, 2)]]],
	["bandido_lanceiro", Regioes.Id.COLINAS, [["bandido_lanceiro", Vector2(56, 2)]]],
	["cogumelo", Regioes.Id.PANTANO, [["cogumelo", Vector2(34, 4)], ["cogumelo", Vector2(-40, 10)]]],
	["esqueleto", Regioes.Id.RUINAS, [["esqueleto", Vector2(40, 4)]]],
	["golem", Regioes.Id.COLINAS, [["golem", Vector2(40, 2)]]],
]

var w: World
var p: Player


func _ready() -> void:
	w = await criar_mundo(0, false, &"guerreiro", &"humano")
	p = w.jogador
	p.vida.maximo = 9999.0  # o print não pode acabar com o jogador caído
	p.vida.curar_tudo()
	await esperar(1.0)
	for b in BICHOS:
		await _bicho(b[0], b[1], b[2])
	# O esqueleto desmontado (sem fogo ele levanta).
	await _ir(PONTOS[Regioes.Id.RUINAS])
	var e := w.povoamento.criar("esqueleto", p.global_position + Vector2(36, 4), Regioes.Id.RUINAS) as Esqueleto
	await esperar(0.2)
	e.hurtbox.receber(999.0, &"fisico", p)
	await esperar(0.6)
	await salvar_print("novidades/etapa2_esqueleto_desmontado.png")
	e.queue_free()
	# O morcego, à noite no Bosque.
	await _ir(PONTOS[Regioes.Id.BOSQUE])
	w.alternar_noite()
	await esperar(1.5)
	for k in 3:
		w.povoamento.criar("morcego_noite", p.global_position + Vector2(40 + k * 20, -10 + k * 14), Regioes.Id.BOSQUE)
	await esperar(0.9)
	await salvar_print("novidades/etapa2_morcego.png")
	w.alternar_noite()
	await esperar(1.5)
	# Minérios (Colinas e Ruínas).
	await _perto_de(func(r: Node) -> bool: return r.has_meta(&"minerio") and (r as ResourceNode).item_id == &"minerio_cobre", Vector2(-10, 24))
	await salvar_print("novidades/etapa2_minerios_colinas.png")
	await _perto_de(func(r: Node) -> bool: return r.has_meta(&"minerio") and (r as ResourceNode).item_id == &"cristal", Vector2(-10, 24))
	await salvar_print("novidades/etapa2_cristal.png")
	# Coletáveis: o arbusto de frutinhas, ervas e capim no Bosque; conchas na Praia.
	await _perto_de(func(r: Node) -> bool: return String(r.name).begins_with("Coleta") and (r as ResourceNode).item_id == &"frutinhas", Vector2(-14, 20))
	await salvar_print("novidades/etapa2_frutinhas.png")
	await _perto_de(func(r: Node) -> bool: return String(r.name).begins_with("Coleta") and (r as ResourceNode).item_id == &"concha", Vector2(-14, 20))
	await salvar_print("novidades/etapa2_conchas.png")
	# A fornalha no acampamento, acesa, com uma barra feita.
	await _ir(Vector2i(99, 70))
	var cel := Vector2i((p.global_position / World.T).floor()) + Vector2i(2, -1)
	var f := w._criar_peca(&"fornalha", cel)
	p.inventario.adicionar(&"minerio_cobre", 3)
	p.inventario.adicionar(&"carvao", 3)
	for k in Inventory.BARRA:
		if p.inventario.item_em(k) == &"minerio_cobre":
			p.barra_escolhida = k
	if f:
		f.interagir(p)
	await esperar(0.4)
	await salvar_print("novidades/etapa2_fornalha.png")
	# A mochila e o livro de receitas, com os itens novos.
	var inv := p.inventario
	inv.definir([])
	for par in [[&"barra_cobre", 6], [&"barra_ferro", 4], [&"minerio_ferro", 5], [&"cristal", 3], [&"erva", 8],
			[&"cogumelo", 6], [&"gel_slime", 4], [&"fibra", 9], [&"corda", 2], [&"graveto", 6], [&"peixe", 3],
			[&"frutinhas", 7], [&"coco", 2], [&"concha", 5], [&"carne_sapo", 2], [&"osso", 3], [&"espada_ferro", 1],
			[&"pocao_cura", 2], [&"pocao_mana", 1], [&"pocao_resistencia", 1], [&"vara_pescar", 1], [&"picareta_cobre", 1]]:
		inv.adicionar(par[0], par[1])
	var m: Mochila = w.hud._mochila
	inv.na_bancada = true
	m.abrir(&"bancada")
	m._selecionar_receita(&"pocao_cura")
	await esperar(0.6)
	await salvar_print("novidades/etapa2_livro_receitas.png")
	m.fechar()
	inv.na_bancada = true
	m.abrir(&"bancada")
	m._selecionar_receita(&"espada_cobre")
	await esperar(0.6)
	await salvar_print("novidades/etapa2_livro_espada_cobre.png")
	m.fechar()
	terminar()


func _ir(cel: Vector2i) -> void:
	p.global_position = Vector2(cel * World.T) + Vector2(8, 8)
	p.camera.reset_smoothing()
	await esperar(1.0)


func _bicho(nome: String, regiao: int, quem: Array) -> void:
	await _ir(PONTOS[regiao])
	var criados: Array[Node] = []
	for q in quem:
		criados.append(w.povoamento.criar(q[0], p.global_position + Vector2(q[1]), regiao))
	await esperar(0.8)
	await salvar_print("novidades/etapa2_%s.png" % nome)
	for c in criados:
		if is_instance_valid(c):
			c.queue_free()
	p.vida.curar_tudo()
	for t in EfeitosEstado.TODOS:
		p.efeitos.remover(t)


## Leva o jogador para perto do recurso mais perto do centro que passa no filtro.
func _perto_de(filtro: Callable, desvio: Vector2) -> void:
	var melhor: Node2D = null
	for r in get_tree().get_nodes_in_group(&"recursos"):
		if filtro.call(r) and (melhor == null or (r as Node2D).global_position.distance_to(w.centro) < melhor.global_position.distance_to(w.centro)):
			melhor = r
	if melhor == null:
		checar(false, "achou o recurso para o print")
		return
	p.global_position = melhor.global_position + desvio
	p.camera.reset_smoothing()
	await esperar(1.0)
