extends TesteBase
## Prints do mundo grande (L36; precisa de janela, não roda com --headless):
##   evidence/novidades/mundo_<regiao>.png  o jogador dentro de cada região
##   evidence/novidades/mundo_pantano_noite.png  os cogumelos brilhando e a névoa
##   evidence/novidades/mundo_passagens.png  a ponte e as raízes
##   evidence/novidades/mundo_mapa.png  o mapa (M) aberto
##   evidence/novidades/mundo_ilha.png  a ilha inteira vista de cima
## E mede os FPS com 1 jogador num ponto cheio de coisas (imprime "FPS ...").
## Uso (da raiz):  <godot> --path game res://tests/print_mundo.tscn [-- --so-fps]

## Onde tirar o print de cada região (blocos), escolhido olhando a ilha de cima.
const PONTOS := {
	Regioes.Id.CLAREIRA: Vector2i(99, 70),
	Regioes.Id.BOSQUE: Vector2i(146, 74),
	Regioes.Id.PRAIA: Vector2i(96, 108),
	Regioes.Id.PANTANO: Vector2i(36, 72),
	Regioes.Id.COLINAS: Vector2i(84, 22),
	Regioes.Id.RUINAS: Vector2i(129, 33),
}
const NOMES := {
	Regioes.Id.CLAREIRA: "clareira", Regioes.Id.BOSQUE: "bosque", Regioes.Id.PRAIA: "praia",
	Regioes.Id.PANTANO: "pantano", Regioes.Id.COLINAS: "colinas", Regioes.Id.RUINAS: "ruinas",
}

var w: World


func _ready() -> void:
	w = await criar_mundo(0, false, &"guerreiro", &"humano")
	var p := w.jogador
	await esperar(1.0)
	if "--so-fps" in OS.get_cmdline_user_args():
		await _medir_fps()
		terminar()
		return
	for r in PONTOS:
		var cel: Vector2i = PONTOS[r]
		if r == Regioes.Id.RUINAS:
			cel = _perto_da_estatua(cel)
		await _ir(p, cel)
		checar(w.regiao_em(p.global_position) == r, "o jogador está em %s" % Regioes.nome(r))
		await salvar_print("novidades/mundo_%s.png" % NOMES[r])
	# As passagens (ponte e raízes).
	await _ir(p, GeradorIlha.PONTE + Vector2i(-6, 1))
	await salvar_print("novidades/mundo_ponte.png")
	await _ir(p, GeradorIlha.VAU + Vector2i(0, 4))
	await salvar_print("novidades/mundo_raizes.png")
	# O pântano de noite.
	await _ir(p, PONTOS[Regioes.Id.PANTANO])
	w.alternar_noite()
	await esperar(2.0)
	await salvar_print("novidades/mundo_pantano_noite.png")
	w.alternar_noite()
	await esperar(1.5)
	# O mapa aberto (com o que foi visto nas visitas acima), de volta ao acampamento.
	await _ir(p, Vector2i(97, 68))
	w.hud.mapa().abrir()
	await esperar(1.0)
	await salvar_print("novidades/mundo_mapa.png")
	w.hud.mapa().fechar()
	# A ilha inteira de cima.
	w.hud.visible = false
	var cam := Camera2D.new()
	cam.zoom = Vector2(0.4, 0.4)
	cam.position = Vector2(w.largura, w.altura) * World.T / 2.0
	w.add_child(cam)
	cam.make_current()
	await esperar(1.5)
	await salvar_print("novidades/mundo_ilha.png")
	cam.queue_free()
	w.hud.visible = true
	p.camera.make_current()
	await _medir_fps()
	terminar()


## Nas Ruínas, o print fica ao lado de uma estátua do guardião (se houver).
func _perto_da_estatua(padrao: Vector2i) -> Vector2i:
	for n in w.entidades.get_children():
		if n is StaticBody2D and n.get_child_count() > 1:
			var s := n.get_child(1) as Sprite2D
			if s and s.texture and s.texture.resource_path.ends_with("ruinas_altas.png") and s.region_rect.position.x == 256 and w.regiao_em(n.global_position) == Regioes.Id.RUINAS:
				return Vector2i(((n as Node2D).global_position / World.T).floor()) + Vector2i(-2, 2)
	return padrao


func _ir(p: Player, cel: Vector2i) -> void:
	p.global_position = Vector2(cel * World.T) + Vector2(8, 8)
	p.camera.reset_smoothing()
	await esperar(1.2)


## FPS no Bosque Florido (árvores, flores, bichos), com 1 jogador, por 6 segundos.
func _medir_fps() -> void:
	var p := w.jogador
	await _ir(p, PONTOS[Regioes.Id.BOSQUE])
	# Sem o limite do monitor (vsync), para ver quanto sobra de verdade.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	await esperar(2.0)
	await _contar_fps("com a Soneca (o longe dorme)")
	# Para comparar: tudo acordado.
	w.soneca.process_mode = Node.PROCESS_MODE_DISABLED
	for g in [&"inimigos", &"animais", &"recursos"]:
		for n in get_tree().get_nodes_in_group(g):
			n.process_mode = Node.PROCESS_MODE_INHERIT
	for pd in w.soneca._pedacos:
		(pd[0] as Node).process_mode = Node.PROCESS_MODE_INHERIT
	await esperar(2.0)
	await _contar_fps("sem a Soneca (tudo acordado)")
	w.soneca.process_mode = Node.PROCESS_MODE_ALWAYS


func _contar_fps(como: String) -> void:
	var quadros := 0
	var tempo := 0.0
	var inicio := Time.get_ticks_usec()
	while tempo < 6.0:
		await get_tree().process_frame
		quadros += 1
		tempo = (Time.get_ticks_usec() - inicio) / 1000000.0
	var vivos := 0
	for g in [&"inimigos", &"animais"]:
		vivos += get_tree().get_nodes_in_group(g).size()
	print("FPS medio no Bosque Florido, %s: %.1f (%d quadros em %.1f s; %d nós no mundo, %d bichos, %d dormindo)" % [
		como, quadros / tempo, quadros, tempo, w.get_tree().get_node_count(), vivos, w.soneca.dormindo()])
