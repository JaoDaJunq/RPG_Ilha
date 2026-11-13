extends TesteBase
## MEDIÇÃO (não é smoke, não entra na bateria): o jogador fica PARADO segurando o clique
## (golpe automático) contra um inimigo por TEMPO segundos; quando o inimigo cai, nasce outro
## no mesmo lugar. Mede golpes por segundo, inimigos derrotados e a vida perdida.
## É a "trocação sem cuidado" de que o João reclamou. Os números do design/combate.md saem daqui.
## Rodar (da raiz):  <godot> --headless --path game res://tests/medir_combate.tscn

const SLIME := preload("res://scenes/enemies/slime.tscn")
const ANIMAL := preload("res://scenes/animals/animal.tscn")
const ATIRADOR := preload("res://scenes/enemies/atirador.tscn")
const TEMPO := 12.0


func _ready() -> void:
	for classe in [&"guerreiro", &"ladino", &"mago"]:
		await _medir(classe, &"slime")
		await _medir(classe, &"javali")
	await _medir(&"guerreiro", &"atirador")
	terminar()


func _novo(w: World, tipo: StringName, onde: Vector2) -> Node2D:
	if tipo == &"slime":
		return colocar(w, SLIME, onde)
	if tipo == &"atirador":
		return colocar(w, ATIRADOR, onde)
	var a: Animal = ANIMAL.instantiate()
	a.especie = &"javali"
	a.position = onde
	w.entidades.add_child(a, true)
	return a


func _medir(classe: StringName, tipo: StringName) -> void:
	var w := await criar_mundo(0, true, classe)
	var p := w.jogador
	p.dar_kit()
	for k in Inventory.BARRA:
		var id := p.inventario.item_em(k)
		if ItemData.existe(id) and ItemData.carregar(id).ferramenta == &"espada":
			p.barra_escolhida = k
	var dist := 70.0 if tipo == &"atirador" else 26.0
	var onde := p.global_position + Vector2(dist, 0)
	var alvo := _novo(w, tipo, onde)
	var dado := [0.0, -1.0]  # dano total no inimigo; 1º golpe
	var contar := func(q: float, _t: StringName) -> void:
		dado[0] += q
		if dado[1] < 0.0:
			dado[1] = q
	var vida_alvo: float = (alvo.get("vida") as HealthComponent).maximo
	(alvo.get("vida") as HealthComponent).dano_recebido.connect(contar)
	var derrotados := 0
	var golpes := 0
	var antes := 0.0
	var caiu_em := -1.0
	var t := 0.0
	var vida0 := p.vida.atual
	var perdida := [0.0]  # soma do dano (subir de nível cura, então não dá para olhar só a vida)
	p.vida.dano_recebido.connect(func(q: float, _t: StringName) -> void: perdida[0] += q)
	if tipo != &"atirador":
		Input.action_press(&"atacar")
	while t < TEMPO:
		await get_tree().physics_frame
		var dt := get_physics_process_delta_time()
		t += dt
		p.global_position = onde - Vector2(dist, 0) if not p.caido else p.global_position
		if is_instance_valid(alvo):
			p.mira_forcada = alvo.global_position + Vector2(0, -6)
		var r: float = p.get("_recarga_golpe")
		if r > antes + 0.01:
			golpes += 1
		antes = r
		if not is_instance_valid(alvo) or alvo.is_queued_for_deletion():
			derrotados += 1
			alvo = _novo(w, tipo, onde)
			(alvo.get("vida") as HealthComponent).dano_recebido.connect(contar)
		if p.caido and caiu_em < 0.0:
			caiu_em = t
			break
	Input.action_release(&"atacar")

	print("MEDIDA %s x %s (vida %.0f): golpes/s %.2f | 1º golpe %.2f | dano dado %.1f/s | derrotados %d em %.1f s | dano recebido %.0f (vida máx. %.0f, %.1f/s) | caiu: %s" % [
		classe, tipo, vida_alvo, golpes / maxf(t, 0.01), dado[1], dado[0] / maxf(t, 0.01), derrotados, t, perdida[0], vida0, perdida[0] / maxf(t, 0.01),
		("aos %.1f s" % caiu_em) if caiu_em >= 0.0 else "não"])
	w.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame
