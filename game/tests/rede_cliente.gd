extends TesteBase
## Lado CLIENTE do teste de rede (aberto pelo rede_smoke). Não roda sozinho.

const REDE := preload("res://tests/rede_smoke.gd")


func _ready() -> void:
	Net.modo = Net.Modo.ENTRAR
	Net.endereco = "127.0.0.1"
	# Entra como Humano Guerreiro (o padrão) e passa pela tela de criação: Ogro Arqueiro.
	var w := await criar_mundo(0, true, &"guerreiro", &"humano", false)
	var arvore := REDE.criar_arvore_teste(w)
	var arvore_antes := REDE.criar_arvore_teste(w, "ArvoreAntes", w.ponto_de_nascer(0) + Vector2(-40, 0))
	var viu_bola := [false]
	w.entidades.child_entered_tree.connect(func(n: Node) -> void:
		if n is Projetil:
			viu_bola[0] = true)

	# Nível e barra de vida em cima dos slimes: o que este cliente vê (nome -> nível; vida da
	# barra quando ela aparece depois de um golpe do anfitrião).
	var niveis := {}
	var barra_vista := [-1.0]
	get_tree().process_frame.connect(func() -> void:
		for n in w.entidades.get_children():
			if n is Slime:
				niveis[String(n.name)] = n.barra.texto_nivel()
				if n.barra.barra_visivel():
					barra_vista[0] = n.barra._barra.value)

	var t := 0.0
	while w.jogador == null and t < 15.0:
		await esperar(0.1)
		t += 0.1
	if w.jogador == null:
		print("[FALHA] cliente não recebeu o próprio jogador")
		get_tree().quit(1)
		return
	var p := w.jogador
	t = 0.0
	while p.tela_de_criacao() == null and t < 10.0:
		await esperar(0.1)
		t += 0.1
	var viu_criar := p.tela_de_criacao() != null
	if viu_criar:
		var tela := p.tela_de_criacao()
		tela.escolher_raca(&"ogro")
		tela.definir_rosto(1)
		tela.definir_pele(2)
		tela.avancar()
		tela.escolher_classe(&"arqueiro")
		tela.confirmar()
	t = 0.0
	while p.criando and t < 10.0:
		await esperar(0.1)
		t += 0.1
	await esperar(1.0)

	# O cliente coleta com a mão (as ferramentas do teste são só do anfitrião): bem mais lento.
	await segurar_e(p, arvore.global_position + Vector2(0, -20), 9.5)
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
	p.pedir_aprender(&"chuva_flechas")  # o ponto de habilidade do nível 2
	await esperar(0.5)
	var anfitriao: Player = w.entidades.get_node_or_null("1")

	var slimes := 0
	# Conta os slimes do dia (os da noite nascem a qualquer momento enquanto é noite).
	for n in w.entidades.get_children():
		if n is Slime and not String(n.name).begins_with("SlimeNoite"):
			slimes += 1
	var no_chao := []
	for i in get_tree().get_nodes_in_group(&"itens_chao"):
		no_chao = [String((i as ItemChao).item), (i as ItemChao).quantidade]
	w.relatorio_teste.rpc_id(1, {
		"viu_criar": viu_criar,
		"aparencia_anfitriao": String(anfitriao.aparencia.get("raca", "")) if anfitriao else "",
		"roupa_anfitriao": String(anfitriao.equipado.get("corpo", "")) if anfitriao else "",
		"roupa_propria": String(p.equipado.get("corpo", "")),
		"pele_propria": int(p.aparencia.get("pele", -1)),
		"item_chao": no_chao,
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
		"arvore_chuva": p.tem(&"chuva_flechas"),
		"teclas": p.habilidades().size(),
		"nivel_anfitriao": anfitriao.nivel if anfitriao else -1,
		"antes_estado": arvore_antes.estado,
		"noite": w.noite,
		"niveis_slime": niveis,
		"barra_slime": barra_vista[0],
	})
	if "--com-prints" in OS.get_cmdline_user_args():
		p.mira_forcada = null
		await salvar_print("rede/cliente.png")
	await esperar(5.0)
	get_tree().quit()
