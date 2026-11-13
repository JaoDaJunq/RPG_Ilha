extends TesteBase
## Construção: pôr peças da mão no tile, regras de onde pode, quebrar com golpes (o item
## volta), porta (jogador passa, slime não), tocha protege da noite, bancada posta abre a
## fabricação 3x3 e a lista vai para o mundo salvo.


func _ready() -> void:
	var w := await criar_mundo()
	var p := w.jogador
	var inv := p.inventario
	# Um lugar de grama livre, longe do acampamento.
	p.global_position = w.centro + Vector2(0, 90)
	await esperar(0.1)
	var base := Vector2i((p.global_position / World.T).floor()) + Vector2i(1, 0)
	for par in [[&"parede_madeira", 3], [&"porta_madeira", 1], [&"chao_madeira", 2], [&"tocha", 2], [&"bancada", 1]]:
		inv.adicionar(par[0], par[1])

	_na_mao(p, &"chao_madeira")
	w.pedir_construir(base)
	checar(w._pecas.has(w._chave(base, "piso")), "pôs o chão de madeira")
	_na_mao(p, &"parede_madeira")
	checar(w.pode_construir(&"parede_madeira", base, p), "dá para pôr parede em cima do chão")
	w.pedir_construir(base)
	checar(w._pecas.has(w._chave(base, "obj")) and inv.quantidade_de(&"parede_madeira") == 2, "pôs a parede e gastou 1 (sobram %d)" % inv.quantidade_de(&"parede_madeira"))
	checar(not w.pode_construir(&"parede_madeira", base, p), "não pode pôr duas peças no mesmo tile")
	checar(not w.pode_construir(&"parede_madeira", base + Vector2i(8, 0), p), "não pode pôr longe do jogador")
	var agua := _tile_de_agua(w)
	checar(not w.pode_construir(&"parede_madeira", agua, _perto_de(agua)), "não pode pôr na água")

	# Quebrar: 4 golpes de jogador; o item volta.
	var parede: Construcao = w._pecas[w._chave(base, "obj")]
	for k in 4:
		_golpear(parede, p)
	await esperar(0.1)
	checar(not w._pecas.has(w._chave(base, "obj")) and inv.quantidade_de(&"parede_madeira") == 3, "4 golpes quebram a parede e ela volta para a mochila")

	# Porta: camada só dos slimes.
	_na_mao(p, &"porta_madeira")
	w.pedir_construir(base + Vector2i(1, 0))
	var porta: Construcao = w._pecas.get(w._chave(base + Vector2i(1, 0), "obj"))
	checar(porta != null and porta.collision_layer == Construcao.CAMADA_PORTA and p.collision_mask & Construcao.CAMADA_PORTA == 0, "porta: o jogador passa")
	var slime: Slime = preload("res://scenes/enemies/slime.tscn").instantiate()
	checar(slime.collision_mask & Construcao.CAMADA_PORTA != 0, "porta: o slime não passa")
	slime.free()

	# Tocha protege da noite.
	_na_mao(p, &"tocha")
	w.pedir_construir(base + Vector2i(0, 1))
	var tocha_pos := Vector2((base + Vector2i(0, 1)) * World.T) + Vector2(8, 16)
	checar(World.luz_que_protege(w, tocha_pos + Vector2(10, 0)) != Vector2.INF, "a tocha protege em volta dela")

	# Bancada posta abre a fabricação 3x3.
	_na_mao(p, &"bancada")
	w.pedir_construir(base + Vector2i(-1, 1))
	var bancada: Construcao = w._pecas.get(w._chave(base + Vector2i(-1, 1), "obj"))
	checar(bancada != null and bancada.is_in_group(&"bancadas"), "bancada posta é uma bancada")
	bancada.interagir(p)
	checar(inv.na_bancada, "usar a bancada posta libera a grade 3x3")

	checar(w._lista_construcoes().size() == 4, "a lista para salvar tem as 4 peças (%d)" % w._lista_construcoes().size())

	# Fogueira do acampamento (L37): pedras paradas, chamas e faíscas em laço, luz que tremula.
	var fog := w.entidades.get_node("FogueiraAcampamento") as Construcao
	checar(fog.chamas() != null and fog.chamas().is_playing() and fog.chamas().sprite_frames.get_frame_count(&"fogo") == Construcao.QUADROS_CHAMAS,
		"a fogueira tem as chamas animadas (%d quadros)" % Construcao.QUADROS_CHAMAS)
	var faiscas := fog.get_node_or_null("Faiscas") as AnimatedSprite2D
	checar(faiscas != null and faiscas.is_playing(), "a fogueira solta faíscas")
	w._aplicar_ciclo(true, true)
	var luz: PointLight2D = null
	for c in fog.get_children():
		if c is PointLight2D:
			luz = c
	var energias := {}
	for i in 6:
		await esperar(0.05)
		energias[snappedf(luz.energy, 0.001)] = true
	checar(luz.enabled and energias.size() >= 3, "à noite a luz da fogueira acende e tremula (%d valores)" % energias.size())
	w._aplicar_ciclo(false, true)
	terminar()


func _na_mao(p: Player, item: StringName) -> void:
	for i in Inventory.GUARDAR:
		if p.inventario.item_em(i) == item:
			p.inventario.pedir_clique(i)
			p.inventario.pedir_clique(0)
			if p.inventario.item_em(Inventory.MAO) != &"":
				p.inventario.pedir_clique(i)
			break
	p.barra_escolhida = 0


func _golpear(c: Construcao, p: Player) -> void:
	for n in c.get_children():
		if n is Hurtbox:
			n.receber(1.0, &"fisico", p)


func _tile_de_agua(w: World) -> Vector2i:
	for cel in w._tipo:
		if w._tipo[cel] == World.Chao.AGUA:
			var vizinho_terra := w.tipo_do_chao(cel + Vector2i(1, 0)) != World.Chao.AGUA
			if vizinho_terra:
				return cel
	return Vector2i.ZERO


## Um "jogador" de mentira parado ao lado do tile (só a posição importa).
func _perto_de(cel: Vector2i) -> Node2D:
	var n := Node2D.new()
	add_child(n)
	n.global_position = Vector2(cel * World.T) + Vector2(24, 8)
	return n
