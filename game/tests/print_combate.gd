extends TesteBase
## Playtest roteirizado do combate (L40; precisa de janela): o guerreiro anda até três
## slimes, segura o clique (golpes seguidos), apanha e dá um crítico. Salva prints dos
## momentos e uma "folha de quadros" (12 quadros seguidos do combo, como um gif parado) em
## evidence/novidades/combate_*.png. Com `-- --antes` os nomes saem combate_antes_* (para
## comparar com o código de antes; o roteiro só usa o que já existia).
## Rodar (da raiz):
##   <godot> --path game --resolution 1280x720 res://tests/print_combate.tscn [-- --antes]

const SLIME := preload("res://scenes/enemies/slime.tscn")
const QUADROS := 12
const A_CADA := 4  # quadros de física entre um quadro e outro da folha (~0,07 s)

var _prefixo := "combate_"


func _ready() -> void:
	if "--antes" in OS.get_cmdline_user_args():
		_prefixo = "combate_antes_"
	var w := await criar_mundo(0, true, &"guerreiro", &"humano")
	var p := w.jogador
	p.dar_kit()
	p.global_position = w.centro + Vector2(0, 80)
	p.camera.reset_smoothing()
	await esperar(0.5)
	var slimes: Array[Slime] = []
	for d in [Vector2(70, -6), Vector2(84, 24), Vector2(64, -34)]:
		var s: Slime = colocar(w, SLIME, p.global_position + d)
		s.vida.maximo = 30.0  # duram o roteiro todo
		s.vida.atual = 30.0
		slimes.append(s)
	await get_tree().physics_frame

	# 1. Anda até eles (a câmera vai junto, olhando para a mira).
	p.mira_forcada = slimes[0].global_position
	Input.action_press(&"mover_direita")
	await esperar(0.35)
	await salvar_print("novidades/%s1_andando.png" % _prefixo)
	await esperar(0.15)
	Input.action_release(&"mover_direita")

	# 2. Segura o clique: o primeiro acerto.
	var alvo := slimes[0]
	p.mira_forcada = alvo.global_position + Vector2(0, -6)
	var vida_alvo := alvo.vida.atual
	Input.action_press(&"atacar")
	var folha: Array[Image] = []
	var quadro := 0
	var acertou := false
	var t := 0.0
	while t < 1.6:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if is_instance_valid(alvo):
			p.mira_forcada = alvo.global_position + Vector2(0, -6)
		if not acertou and is_instance_valid(alvo) and alvo.vida.atual < vida_alvo:
			acertou = true
			await salvar_print("novidades/%s2_acerto.png" % _prefixo)
		quadro += 1
		if folha.size() < QUADROS and quadro % A_CADA == 0:
			await RenderingServer.frame_post_draw
			folha.append(get_viewport().get_texture().get_image())
	_salvar_folha(folha, "novidades/%s6_folha_combo.png" % _prefixo)

	# 3. Continua trocando golpes até apanhar.
	var vida_p := p.vida.atual
	t = 0.0
	while t < 4.0 and p.vida.atual >= vida_p:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if is_instance_valid(alvo):
			p.mira_forcada = alvo.global_position + Vector2(0, -6)
	await esperar(0.05)
	await salvar_print("novidades/%s3_apanhou.png" % _prefixo)
	print("PLAYTEST %sapanhou em %.1f s (vida %.0f -> %.0f)" % [_prefixo, t, vida_p, p.vida.atual])

	# 4. Mais 3 s de trocação: quanto custa?
	var vida_antes := p.vida.atual
	await esperar(3.0)
	print("PLAYTEST %s3 s de trocação: vida %.0f -> %.0f" % [_prefixo, vida_antes, p.vida.atual])
	await salvar_print("novidades/%s4_trocacao.png" % _prefixo)
	Input.action_release(&"atacar")

	# 5. Um crítico (o número maior e amarelo).
	Passivas.chance_critico = 1.0
	await esperar(0.8)
	for s in slimes:
		if is_instance_valid(s):
			alvo = s
	if is_instance_valid(alvo):
		p.mira_forcada = alvo.global_position + Vector2(0, -6)
		vida_alvo = alvo.vida.atual
		p.golpear()
		while is_instance_valid(alvo) and alvo.vida.atual >= vida_alvo:
			await get_tree().physics_frame
		await esperar(0.08)
		await salvar_print("novidades/%s5_critico.png" % _prefixo)
	Passivas.chance_critico = -1.0
	terminar()


## Junta os quadros numa grade 4 x 3, cada um na metade do tamanho, com 4 px entre eles.
func _salvar_folha(quadros: Array[Image], caminho: String) -> void:
	if quadros.is_empty():
		return
	var lado := 4
	var largura := quadros[0].get_width() / 2
	var altura := quadros[0].get_height() / 2
	var linhas := ceili(quadros.size() / float(lado))
	var folha := Image.create(lado * largura + (lado + 1) * 4, linhas * altura + (linhas + 1) * 4, false, Image.FORMAT_RGBA8)
	folha.fill(Color(0.09, 0.09, 0.13))
	for i in quadros.size():
		var q := quadros[i]
		q.convert(Image.FORMAT_RGBA8)
		q.resize(largura, altura, Image.INTERPOLATE_NEAREST)
		folha.blit_rect(q, Rect2i(0, 0, largura, altura), Vector2i(4 + (i % lado) * (largura + 4), 4 + (i / lado) * (altura + 4)))
	var destino := ProjectSettings.globalize_path("res://").path_join("../evidence").path_join(caminho)
	DirAccess.make_dir_recursive_absolute(destino.get_base_dir())
	checar(folha.save_png(destino) == OK, "folha de quadros salva: " + caminho)
