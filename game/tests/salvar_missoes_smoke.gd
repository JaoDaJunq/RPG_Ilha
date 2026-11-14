extends TesteBase
## O estado das missões vai para o arquivo do mundo e volta igual (capítulo, passo, entregas,
## lenha, pedido, pedras, regiões visitadas, falas pendentes), e a cópia que o anfitrião
## manda para os outros jogadores (estado) reproduz o que a tela precisa.

const ARQUIVO := "user://teste_salvar_missoes.save"


func _ready() -> void:
	Salvamento.apagar(ARQUIVO)
	var w := await _mundo()
	var m := w.missoes
	var p := w.jogador

	# Joga um pouco: acorda, faz a bancada, lê uma pedra, aceita um pedido.
	m.conversar(p)
	p.inventario.adicionar(&"madeira", 10)
	m.conversar(p)
	m.notificar_construiu(&"bancada")
	m.notificar_slime_morto()
	m.notificar_slime_morto()
	w.pedra_lore(Regioes.Id.PRAIA).interagir(p)
	m.visitadas.append(Regioes.Id.PRAIA)
	m.pedido = {"item": "concha", "qtd": 4, "texto": "4 conchas bonitas.", "rec": ["pocao_cura", 2], "estado": "aceito"}
	m.pedidos_feitos = 3
	m.comemora = 0.0  # só o desenho dele; não faz parte do que se compara
	var antes := m.estado()
	checar(m.acordado and String(m.passo_atual()["id"]) == "cheiro" and int(m.entregue.get("matar", 0)) == 2, "estado antes de salvar: acordado, no passo dos slimes (2/6)")
	checar(m.tem_novidade(), "ainda há o que ele quer contar")
	checar(w.salvar(), "salvou o mundo")

	# Abre de novo: tudo volta.
	w.queue_free()
	await get_tree().process_frame
	w = await _mundo()
	m = w.missoes
	checar(m.acordado and m.lenha == 10 and not m.fraquinho(), "o Brasinha continua acordado")
	checar(m.capitulo == 1 and String(m.passo_atual()["id"]) == "cheiro", "continua no passo dos slimes")
	checar(int(m.entregue.get("matar", 0)) == 2, "com 2 slimes já contados")
	checar(m.pedras_lidas() == [Regioes.Id.PRAIA] and w.pedra_lore(Regioes.Id.PRAIA).lida, "a pedra da praia continua lida")
	checar(m.visitadas.has(Regioes.Id.PRAIA) and m.visitadas.has(Regioes.Id.CLAREIRA), "as regiões visitadas voltaram")
	checar(m.pedido_aberto() and String(m.pedido["estado"]) == "aceito" and int(m.pedido["qtd"]) == 4 and m.pedidos_feitos == 3, "o pedido aceito e a contagem voltaram")
	checar(m.tem_novidade(), "as falas pendentes também voltaram")
	var fogueira := w.entidades.get_node("FogueiraAcampamento") as Construcao
	checar(is_equal_approx(float(fogueira.get_meta(&"raio_luz")), World.RAIO_FOGUEIRA), "a zona segura da fogueira voltou ao normal")
	var depois := m.estado()
	checar(str(depois) == str(antes), "o estado todo é igual ao de antes de salvar")

	# A cópia que vai para os outros jogadores.
	var copia := Missoes.new(w)
	add_child(copia)
	copia.carregar(JSON.parse_string(JSON.stringify(antes)))  # passa pelo JSON como na rede/arquivo
	checar(copia.titulo_atual() == m.titulo_atual() and copia.objetivo_texto() == m.objetivo_texto(), "um cliente enxerga a mesma missão e o mesmo objetivo")
	checar(copia.pedras_lidas() == m.pedras_lidas() and copia.marcador() == m.marcador(), "e as mesmas pedras e o mesmo marcador")
	copia.free()

	# Fim do capítulo e raízes também são salvos.
	m.entregar_semente()
	checar(w.salvar(), "salvou de novo")
	w.queue_free()
	await get_tree().process_frame
	w = await _mundo()
	checar(w.missoes.capitulo == 2 and w.missoes.semente_entregue, "o capítulo 2 continua depois de reabrir")
	checar(w.passagem(World.PONTE).aberta, "a ponte consertada continua consertada")

	Salvamento.apagar(ARQUIVO)
	terminar()


func _mundo() -> World:
	Sfx.ligado = false
	Net.classe = &"mago"
	Net.raca = &"humano"
	Net.pular_criacao = true
	var w: World = MUNDO.instantiate()
	w.arquivo_salvo = ARQUIVO
	w.slimes = 0
	w.grupos_atiradores = 0
	w.gerar_recursos = false
	add_child(w)
	await get_tree().physics_frame
	await get_tree().physics_frame
	return w
