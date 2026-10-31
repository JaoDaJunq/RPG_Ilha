extends TesteBase
## Prints da Home e dos menus (precisa de janela). Salva evidence/novidades/home_*.png.
## Uso (da raiz):  <godot> --path game --resolution 1280x720 res://tests/print_menu.tscn
## Cria três mundos de enfeite (arquivos novos, sem tocar nos seus) e apaga no fim.


func _ready() -> void:
	Sfx.ligado = false
	var ficticios: Array[String] = []
	ficticios.append(Salvamento.criar_mundo("Ilha do João", 1))
	ficticios.append(Salvamento.criar_mundo("Aventura em dupla", 2))
	ficticios.append(Salvamento.criar_mundo("Primeiros passos", 0))
	var menu: Node = load("res://scenes/ui/menu.tscn").instantiate()
	add_child(menu)
	await esperar(1.0)
	await salvar_print("novidades/home_inicio.png")
	menu._tela_jogar()
	await esperar(0.5)
	await salvar_print("novidades/home_jogar.png")
	menu._tela_multijogador()
	await esperar(0.5)
	await salvar_print("novidades/home_multijogador.png")
	menu._tela_entrar()
	await esperar(0.5)
	await salvar_print("novidades/home_entrar.png")
	Net.modo = Net.Modo.SOLO
	menu._tela_mundos()
	await esperar(0.5)
	await salvar_print("novidades/home_mundos.png")
	menu._tela_criar()
	await esperar(0.5)
	await salvar_print("novidades/home_criar_mundo.png")
	menu._tela_configuracoes()
	await esperar(0.5)
	await salvar_print("novidades/home_configuracoes.png")
	var tela: TelaConfiguracoes = menu._tela
	tela._abrir_aba(1)
	await esperar(0.4)
	await salvar_print("novidades/home_configuracoes_som.png")
	tela._abrir_aba(0)
	tela.comecar_troca(Configuracoes.GRUPOS[0].entradas[0], 0)
	await esperar(0.4)
	await salvar_print("novidades/home_configuracoes_trocando.png")
	tela.cancelar_troca()
	menu.queue_free()
	await get_tree().process_frame
	# Dentro do mundo: o HUD e o menu de pausa (Esc).
	# Teclas trocadas pelo jogador (num arquivo de teste, sem mexer nas configurações de verdade).
	Configuracoes.caminho = "user://print_config.cfg"
	for par in [[&"habilidade_1", KEY_F], [&"habilidade_2", KEY_G], [&"esquivar", KEY_SPACE]]:
		var ev := InputEventKey.new()
		ev.physical_keycode = par[1]
		Configuracoes.religar([par[0]], 0, ev)
	var w := await criar_mundo(0, false)
	w.jogador.camera.make_current()
	await esperar(0.8)
	await salvar_print("novidades/home_pausa_hud.png")
	w.get_child(0).abrir()
	await esperar(0.5)
	await salvar_print("novidades/home_pausa.png")
	w.get_child(0).fechar()
	Configuracoes.restaurar_padrao()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://print_config.cfg"))
	Configuracoes.caminho = Configuracoes.CAMINHO_PADRAO
	Configuracoes.carregar()
	for c in ficticios:
		Salvamento.apagar(c)
	terminar()
