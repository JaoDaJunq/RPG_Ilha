class_name UsoItens
extends RefCounted
## O que os itens novos da etapa 2 (L39) fazem, fora do Player (para não crescer mais o
## player.gd). Tudo roda no ANFITRIÃO.
##   - poções de mana e de resistência (a de cura usa o `cura` de sempre);
##   - vara de pescar: botão direito perto da água; depois de um tempinho vem um peixe
##     (num ponto de pesca, com as ondinhas, vêm dois);
##   - armas de classe de cobre e ferro: o dano das habilidades cresce (bonus_arma) e a mão
##     mostra o desenho da arma base (visual_mao);
##   - o que a fogueira e a fornalha cozinham e o que a fornalha derrete.

## Cru → cozido (fogueira e fornalha).
const COZINHAR := {
	&"carne_crua": &"carne_assada",
	&"peixe": &"peixe_assado",
	&"carne_sapo": &"carne_sapo_assada",
}
## Minério → barra (só a fornalha). Gasta 1 de combustível (carvão ou madeira) a cada barra.
const DERRETER := {
	&"minerio_cobre": &"barra_cobre",
	&"minerio_ferro": &"barra_ferro",
}
const COMBUSTIVEIS: Array[StringName] = [&"carvao", &"madeira", &"graveto"]

## Pesca: distância até a água e o tempo esperando o peixe.
const ALCANCE_AGUA := 30.0
const ESPERA_PEIXE := Vector2(1.4, 2.6)
const RAIO_PONTO_PESCA := 70.0


## Botão direito com um item novo na mão. Devolve se tratou (o Player não faz mais nada).
static func usar(p: Player, espaco: int, dados: ItemData) -> bool:
	if dados.mana > 0.0:
		var maximo := p.ficha.mana_maxima()
		if p.mana >= maximo:
			p.avisar("Sua mana já está cheia.")
			return true
		p.inventario.gastar(espaco, 1)
		p.mana = minf(maximo, p.mana + dados.mana)
		p._enviar_mana()
		World.efeito_todos(p, &"subir_nivel", p.global_position)
		p.avisar("+%d de mana" % int(dados.mana), &"item")
		return true
	if dados.resistencia > 0.0:
		p.inventario.gastar(espaco, 1)
		p.buffs.dar(Buffs.REDUCAO, dados.resistencia, dados.segundos_efeito)
		World.efeito_todos(p, &"escudo", p.global_position + Vector2(0, -8))
		p.avisar("Resistência: %d%% menos dano por %d s" % [int(dados.resistencia * 100.0), int(dados.segundos_efeito)], &"item")
		return true
	if dados.ferramenta == &"vara":
		pescar(p)
		return true
	return false


## Joga a linha na água mais perto (anfitrião). Devolve onde caiu a boia (INF: sem água perto).
static func pescar(p: Player) -> Vector2:
	var w := p.get_tree().get_first_node_in_group(&"mundo") as World
	if w == null:
		return Vector2.INF
	if p.has_meta(&"pescando"):
		p.avisar("Espere o peixe morder...")
		return Vector2.INF
	var agua := agua_perto(w, p.global_position)
	if agua == Vector2.INF:
		p.avisar("Chegue na beira da água para pescar (botão direito com a vara na mão).")
		return Vector2.INF
	p.set_meta(&"pescando", true)
	World.efeito_todos(p, &"respingo", agua)
	p.avisar("Pescando... fique perto da água.")
	var espera := randf_range(ESPERA_PEIXE.x, ESPERA_PEIXE.y)
	p.get_tree().create_timer(espera, false, true).timeout.connect(_fisgou.bind(p, agua))
	return agua


static func _fisgou(p: Player, agua: Vector2) -> void:
	if not is_instance_valid(p):
		return
	p.remove_meta(&"pescando")
	if p.global_position.distance_to(agua) > ALCANCE_AGUA * 2.5 or p.caido:
		p.avisar("O peixe fugiu: você se afastou da água.")
		return
	var qtd := 1
	for ponto in p.get_tree().get_nodes_in_group(&"pontos_pesca"):
		if (ponto as Node2D).global_position.distance_to(agua) < RAIO_PONTO_PESCA:
			qtd = 2
	var item := &"peixe"
	if randf() < 0.12:
		item = &"concha"
	World.efeito_todos(p, &"respingo", agua)
	p.inventario.adicionar(item, qtd)
	p.ganhar_xp(3)
	p.avisar("+%d %s" % [qtd, ItemData.carregar(item).nome.to_lower()], &"item")


## O ponto de água mais perto de `pos` (até ALCANCE_AGUA), ou INF.
static func agua_perto(w: World, pos: Vector2) -> Vector2:
	var melhor := Vector2.INF
	var cel0 := Vector2i((pos / World.T).floor())
	var r := ceili(ALCANCE_AGUA / World.T)
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var cel := cel0 + Vector2i(dx, dy)
			if w.tipo_do_chao(cel) != World.Chao.AGUA:
				continue
			var c := Vector2(cel * World.T) + Vector2(World.T, World.T) / 2.0
			if c.distance_to(pos) <= ALCANCE_AGUA and (melhor == Vector2.INF or c.distance_to(pos) < melhor.distance_to(pos)):
				melhor = c
	return melhor


## Quanto as armas de classe da barra multiplicam o dano das habilidades (vale a melhor).
static func bonus_arma(p: Player) -> float:
	if p.ficha == null or p.ficha.classe == null:
		return 1.0
	var melhor := 1.0
	for k in Inventory.BARRA:
		var id := p.inventario.item_em(k)
		if not ItemData.existe(id):
			continue
		var d := ItemData.carregar(id)
		if d.arma_de == p.ficha.classe.id:
			melhor = maxf(melhor, d.bonus_arma)
	return melhor


## O desenho que vai na mão: as armas de cobre e ferro usam o da arma base.
static func visual_mao(item_id: StringName) -> StringName:
	if not ItemData.existe(item_id):
		return item_id
	var d := ItemData.carregar(item_id)
	return d.visual_mao if d.visual_mao != &"" else item_id


## O que este item vira no fogo (&"" se não cozinha).
static func cozido(item_id: StringName) -> StringName:
	return COZINHAR.get(item_id, &"")
