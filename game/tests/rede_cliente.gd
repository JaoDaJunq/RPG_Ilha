extends TesteBase
## Lado CLIENTE do teste de rede (aberto pelo rede_smoke). Não roda sozinho.

const REDE := preload("res://tests/rede_smoke.gd")


func _ready() -> void:
	Net.modo = Net.Modo.ENTRAR
	Net.endereco = "127.0.0.1"
	var w := await criar_mundo(0, true, Net.classe, Net.raca)
	var arvore := REDE.criar_arvore_teste(w)
	var arvore_antes := REDE.criar_arvore_teste(w, "ArvoreAntes", w.ponto_de_nascer(0) + Vector2(-40, 0))
	var viu_bola := [false]
	w.entidades.child_entered_tree.connect(func(n: Node) -> void:
		if n is Projetil:
			viu_bola[0] = true)

	var t := 0.0
	while w.jogador == null and t < 15.0:
		await esperar(0.1)
		t += 0.1
	if w.jogador == null:
		print("[FALHA] cliente não recebeu o próprio jogador")
		get_tree().quit(1)
		return
	var p := w.jogador
	await esperar(1.0)

	await segurar_e(p, arvore.global_position + Vector2(0, -20), 1.9)
	Input.action_press(&"mover_direita")
	await esperar(0.8)
	Input.action_release(&"mover_direita")
	var mana_antes := p.mana
	p.mira_forcada = p.global_position + Vector2(0, 40)
	p.usar_habilidade_por_id(&"armadilha")
	await esperar(0.8)
	var espera := 0.0
	while p.nivel < 2 and espera < 3.0:
		await esperar(0.1)
		espera += 0.1
	p.pedir_atributo(&"agilidade")
	await esperar(0.5)
	var anfitriao: Player = w.entidades.get_node_or_null("1")

	var slimes := 0
	# Conta os slimes do dia (os da noite nascem a qualquer momento enquanto é noite).
	for n in w.entidades.get_children():
		if n is Slime and not String(n.name).begins_with("SlimeNoite"):
			slimes += 1
	w.relatorio_teste.rpc_id(1, {
		"jogadores": get_tree().get_nodes_in_group(&"jogadores").size(),
		"slimes": slimes,
		"madeira": p.inventario.quantidade_de(&"madeira"),
		"arvore_estado": arvore.estado,
		"viu_bola": viu_bola[0],
		"vida_vista": p.vida.atual,
		"titulo": p.ficha.titulo(),
		"mana_gasta": p.mana < mana_antes,
		"nivel": p.nivel,
		"agilidade": p.ficha.valor(&"agilidade"),
		"nivel_anfitriao": anfitriao.nivel if anfitriao else -1,
		"antes_estado": arvore_antes.estado,
		"noite": w.noite,
	})
	if "--com-prints" in OS.get_cmdline_user_args():
		p.mira_forcada = null
		await salvar_print("rede/cliente.png")
	await esperar(5.0)
	get_tree().quit()
