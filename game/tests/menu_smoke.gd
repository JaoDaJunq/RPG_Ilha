extends TesteBase
## Home e mundos: criar mundo com dificuldade, lista de mundos (inclusive o mundo antigo
## sem nome), o mundo recebe a dificuldade e salva, trocar tecla grava no arquivo e volta
## ao reabrir, o HUD segue a tecla nova e o Esc abre a pausa. Tudo em arquivos de teste.

const PASTA := "user://teste_mundos/"
const CONFIG := "user://teste_configuracoes.cfg"


func _ready() -> void:
	Sfx.ligado = false
	_limpar()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA))
	Salvamento.pasta_atual = PASTA

	# --- Mundos: criar com dificuldade e listar ------------------------------------
	checar(Salvamento.nome_seguro("Meu Mundo Ão!") == "meu_mundo_ao", "nome seguro de arquivo: " + Salvamento.nome_seguro("Meu Mundo Ão!"))
	var caminho := Salvamento.criar_mundo("Meu Mundo Ão", 2)
	checar(caminho == PASTA + "meu_mundo_ao.save" and FileAccess.file_exists(caminho), "mundo criado em " + caminho)
	var dados := Salvamento.ler(caminho)
	checar(int(dados.get("dificuldade", -1)) == 2 and dados.get("nome") == "Meu Mundo Ão", "o arquivo tem a dificuldade 2 e o nome")
	var segundo := Salvamento.criar_mundo("Meu Mundo Ão", 0)
	checar(segundo == PASTA + "meu_mundo_ao_2.save", "mesmo nome ganha outro arquivo: " + segundo)
	# O mundo de antes da lista (sem nome nem dificuldade) também aparece.
	var antigo := PASTA + "ilha.save"
	Salvamento.gravar({"semente": 22117, "jogadores": {}}, antigo)
	var f := FileAccess.open(antigo, FileAccess.READ)
	var texto := f.get_as_text()
	f.close()
	var sem_meta: Dictionary = JSON.parse_string(texto)
	sem_meta.erase("nome")
	sem_meta.erase("salvo_em")
	f = FileAccess.open(antigo, FileAccess.WRITE)
	f.store_string(JSON.stringify(sem_meta))
	f.close()
	var lista := Salvamento.listar()
	checar(lista.size() == 3, "a lista tem 3 mundos (%d)" % lista.size())
	var por_caminho := {}
	for m in lista:
		por_caminho[m.caminho] = m
	checar(por_caminho[caminho].dificuldade == 2 and por_caminho[caminho].nome == "Meu Mundo Ão", "a lista mostra nome e dificuldade difícil")
	checar(por_caminho[antigo].nome == "Ilha" and por_caminho[antigo].dificuldade == 1, "o mundo antigo aparece como Ilha (Normal)")

	# --- O mundo recebe a dificuldade e salva --------------------------------------
	Net.mundo_arquivo = caminho
	Net.mundo_nome = "Meu Mundo Ão"
	Net.mundo_dificuldade = 2
	var w: World = MUNDO.instantiate()  # sem arquivo_salvo: vale o mundo escolhido no menu
	w.slimes = 0
	add_child(w)
	await get_tree().physics_frame
	checar(w.arquivo_salvo == caminho, "o mundo abriu o arquivo escolhido no menu")
	checar(w.dificuldade == 2 and w.nome_mundo == "Meu Mundo Ão", "o mundo tem dificuldade %d e nome %s" % [w.dificuldade, w.nome_mundo])
	checar(w.salvar(), "salvou o mundo")
	dados = Salvamento.ler(caminho)
	checar(int(dados.get("dificuldade", -1)) == 2 and dados.get("nome") == "Meu Mundo Ão" and dados.has("criado_em"), "o salvamento guarda dificuldade, nome e criação")
	w.queue_free()
	await get_tree().process_frame
	# Reabre: a dificuldade vem do arquivo, mesmo que o menu diga outra coisa.
	Net.mundo_dificuldade = 0
	w = MUNDO.instantiate()
	w.slimes = 0
	add_child(w)
	await get_tree().physics_frame
	checar(w.dificuldade == 2, "reabrindo, a dificuldade volta do arquivo (%d)" % w.dificuldade)

	# --- HUD segue a tecla escolhida; Esc abre a pausa -----------------------------
	Configuracoes.caminho = CONFIG
	Configuracoes.restaurar_padrao()
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_F
	Configuracoes.religar([&"habilidade_1"], 0, ev)
	await get_tree().process_frame
	checar(w.hud._slots[0].rotulo.text == "F", "a barra de habilidades mostra a tecla nova (%s)" % w.hud._slots[0].rotulo.text)
	Configuracoes.restaurar_padrao()
	checar(w.hud._slots[0].rotulo.text == "Q", "restaurar o padrão volta o Q na barra")
	var pausa: Pausa = w.get_child(0)
	checar(pausa is Pausa and not pausa.aberta(), "a pausa existe e começa fechada")
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	Input.parse_input_event(esc)
	await get_tree().physics_frame
	await get_tree().physics_frame
	checar(pausa.aberta() and get_tree().paused, "Esc abre a pausa e congela o jogo sozinho")
	var solta := InputEventAction.new()
	solta.action = &"ui_cancel"
	solta.pressed = false
	Input.parse_input_event(solta)
	await get_tree().physics_frame
	var esc2 := InputEventAction.new()
	esc2.action = &"ui_cancel"
	esc2.pressed = true
	Input.parse_input_event(esc2)
	await get_tree().physics_frame
	await get_tree().physics_frame
	checar(not pausa.aberta() and not get_tree().paused, "Esc de novo fecha e o jogo anda")
	pausa.abrir()
	w.jogador.ganhar_xp(30)
	pausa._sair_pressionado()
	checar(pausa._sair.text == "Salvar e sair?", "sair pede confirmação")
	pausa._sair_pressionado()
	checar(not get_tree().paused, "sair descongela o jogo")
	var salvo: Dictionary = Salvamento.ler(caminho)
	var nivel := 0
	for j in salvo.get("jogadores", {}).values():
		nivel = maxi(nivel, int(j.get("nivel", 1)))
	checar(nivel >= 2, "sair para o menu salvou o progresso (nível %d)" % nivel)
	w.queue_free()
	await get_tree().process_frame
	Net.mundo_arquivo = ""
	Net.mundo_nome = ""
	Net.mundo_dificuldade = 1

	# --- Menu: as telas e a lista -------------------------------------------------
	var menu: Node = load("res://scenes/ui/menu.tscn").instantiate()
	add_child(menu)
	await esperar(0.3)
	Net.modo = Net.Modo.SOLO
	menu._tela_mundos()
	await get_tree().process_frame
	var jogar := 0
	var apagar_botoes: Array[Button] = []
	for b in menu._tela.find_children("*", "Button", true, false):
		if b.text == "Jogar":
			jogar += 1
		elif b.text == "Apagar":
			apagar_botoes.append(b)
	checar(jogar == 3 and apagar_botoes.size() == 3, "a tela de mundos mostra Jogar e Apagar para os 3 mundos (%d)" % jogar)
	var apagado: Button = apagar_botoes[0]
	apagado.pressed.emit()
	checar(apagado.text == "Certeza?" and Salvamento.listar().size() == 3, "Apagar pede confirmação e ainda não apaga")
	apagado.pressed.emit()
	await get_tree().process_frame
	checar(Salvamento.listar().size() == 2, "o segundo clique apaga (%d mundos)" % Salvamento.listar().size())
	for tela in [&"_tela_inicio", &"_tela_jogar", &"_tela_multijogador", &"_tela_entrar", &"_tela_criar", &"_tela_configuracoes"]:
		menu.call(tela)
		await get_tree().process_frame
		checar(menu._tela != null and menu._tela.get_child_count() > 0, "a tela %s abre" % tela)
	menu.queue_free()
	await get_tree().process_frame

	# --- Configurações: trocar tecla grava no arquivo e volta ao reabrir -----------
	Configuracoes.restaurar_padrao()
	checar(Configuracoes.tecla_de(&"mover_cima") == "W" and Configuracoes.movimento_atual() == "ambos", "padrão: andar com WASD e setas")
	Configuracoes.predefinir_movimento("setas")
	checar(Configuracoes.movimento_atual() == "setas" and Configuracoes.tecla_de(&"mover_cima") == "↑", "predefinição Setas")
	checar(not _tem_tecla(&"mover_cima", KEY_W) and _tem_tecla(&"mover_cima", KEY_UP), "W saiu, a seta ficou")
	Configuracoes.predefinir_movimento("wasd")
	checar(Configuracoes.movimento_atual() == "wasd" and not _tem_tecla(&"mover_cima", KEY_UP), "predefinição WASD")
	var tecla_g := InputEventKey.new()
	tecla_g.physical_keycode = KEY_G
	Configuracoes.religar([&"mochila"], 0, tecla_g)
	var botao := InputEventMouseButton.new()
	botao.button_index = MOUSE_BUTTON_MIDDLE
	Configuracoes.religar([&"usar"], 0, botao)
	Configuracoes.definir_volume(0.35)
	var cfg := ConfigFile.new()
	checar(cfg.load(CONFIG) == OK, "o arquivo de configurações existe")
	checar(cfg.get_value("controles", "mochila", []) == ["k:71", "k:%d" % KEY_TAB], "a mochila (G e Tab) foi gravada: " + str(cfg.get_value("controles", "mochila", [])))
	checar(cfg.get_value("controles", "usar", []) == ["m:3"], "o botão do meio foi gravado para Usar")
	checar(absf(float(cfg.get_value("som", "volume", 0.0)) - 0.35) < 0.001, "o volume foi gravado")
	# Reabrir o jogo: carregar aplica o arquivo por cima das teclas de fábrica.
	Configuracoes.caminho = CONFIG
	Configuracoes.carregar()
	checar(Configuracoes.tecla_de(&"mochila") == "G" and _tem_tecla(&"mochila", KEY_TAB), "ao reabrir, a mochila continua em G (e Tab)")
	checar(Configuracoes.tecla_de(&"usar") == "Clique do meio", "ao reabrir, Usar continua no botão do meio")
	checar(Configuracoes.movimento_atual() == "wasd" and absf(Configuracoes.volume - 0.35) < 0.001, "ao reabrir, andar só com WASD e volume 35%")
	checar(InputMap.action_has_event(&"mochila", tecla_g) or _tem_tecla(&"mochila", KEY_G), "o jogo de verdade usa a tecla nova")
	var conflito := Configuracoes.conflitos([&"habilidade_1"], tecla_g)
	checar(conflito == ["Mochila"], "avisa quando a tecla já é de outra ação: " + str(conflito))
	Configuracoes.restaurar_padrao()
	checar(Configuracoes.tecla_de(&"mochila") == "I" and Configuracoes.tecla_de(&"usar") == "Clique dir.", "restaurar tudo volta o padrão")
	var cfg2 := ConfigFile.new()
	cfg2.load(CONFIG)
	checar(not cfg2.has_section("controles"), "no padrão, o arquivo não guarda teclas")

	# A tela de troca: clicar numa tecla e apertar a nova.
	var tela := TelaConfiguracoes.new()
	add_child(tela)
	await get_tree().process_frame
	var entrada: Dictionary = Configuracoes.GRUPOS[1].entradas[2]  # Habilidade 1
	tela.comecar_troca(entrada, 0)
	checar(tela.esta_ouvindo(), "a tela fica esperando a nova tecla")
	var nova := InputEventKey.new()
	nova.physical_keycode = KEY_V
	tela.aplicar_evento(nova)
	checar(not tela.esta_ouvindo() and Configuracoes.tecla_de(&"habilidade_1") == "V", "a tecla V foi para a Habilidade 1")
	tela.comecar_troca(entrada, 0)
	tela.cancelar_troca()
	checar(Configuracoes.tecla_de(&"habilidade_1") == "V", "cancelar não muda nada")
	tela.queue_free()
	Configuracoes.restaurar_padrao()

	_limpar()
	Salvamento.pasta_atual = Salvamento.PASTA
	Configuracoes.caminho = Configuracoes.CAMINHO_PADRAO
	Configuracoes.carregar()
	terminar()


func _tem_tecla(acao: StringName, codigo: int) -> bool:
	for e in InputMap.action_get_events(acao):
		if e is InputEventKey and (e as InputEventKey).physical_keycode == codigo:
			return true
	return false


func _limpar() -> void:
	for arquivo in DirAccess.get_files_at(PASTA):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PASTA + arquivo))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CONFIG))
