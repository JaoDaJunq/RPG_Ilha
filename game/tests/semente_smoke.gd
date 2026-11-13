extends TesteBase
## O gancho da Mãe Gosma (entregar_semente) e o começo do capítulo 2: a Semente fecha o
## capítulo 1, conserta a ponte das Colinas e dá 1 ponto de árvore a cada um; a Tocha do
## Brasinha queima as raízes do vau e abre as Ruínas. As pedras de lore também são testadas.


func _ready() -> void:
	var w := await criar_mundo()
	var p := w.jogador
	var m := w.missoes
	var g := w.gerador

	# As 5 pedras de lore: uma por região, menos a Clareira.
	var vistas := 0
	for r in Regioes.TODAS:
		var pedra := w.pedra_lore(r)
		if r == Regioes.Id.CLAREIRA:
			checar(pedra == null, "a Clareira não tem pedra de lore")
		else:
			vistas += 1
			checar(pedra != null and w.regiao_em(pedra.position) == r, "tem pedra de lore em %s" % Regioes.nome(r))
			checar(ArteBrasinha.LORE_DA_REGIAO.has(r) and FalasBrasinha.LORE.has(r), "%s: imagem e frase" % Regioes.nome(r))
	checar(vistas == 5, "são 5 pedras")
	var painel_aberto := [-1]
	m.lore_aberta.connect(func(r: int) -> void: painel_aberto[0] = r)
	p.inventario.definir([])
	m.passo = Missoes.PASSO_LIBERA_PEDIDOS  # já fez a bancada; a pedra do pântano ainda não conta
	var bosque := w.pedra_lore(Regioes.Id.BOSQUE)
	checar(not bosque.lida, "a pedra começa por ler")
	bosque.interagir(p)
	checar(bosque.lida and Regioes.Id.BOSQUE in m.pedras_lidas() and painel_aberto[0] == Regioes.Id.BOSQUE, "ler abre o painel e marca a pedra como lida")
	checar(m.tem_novidade(), "o Brasinha vai comentar a pedra")
	var r := m.conversar(p)
	checar(_tem_texto(r["linhas"], "Guardiões"), "ele comenta a pedra lida na próxima visita")
	bosque.interagir(p)
	checar(m.pedras_lidas().size() == 1, "ler de novo não conta duas vezes")
	checar(String(m.passo_atual()["id"]) == "cheiro", "a pedra do bosque não mexe na missão")

	# A semente.
	checar(not w.passagem(World.PONTE).aberta, "a ponte das Colinas começa quebrada")
	var pontos := p.pontos_habilidade
	checar(m.entregar_semente(), "entregar a semente funciona")
	await get_tree().physics_frame
	checar(w.passagem(World.PONTE).aberta and w.chao.get_cell_atlas_coords(g.celulas_ponte[0]) == World.TILE_CHAO, "a ponte foi consertada")
	checar(p.pontos_habilidade == pontos + 1, "cada jogador ganha 1 ponto de árvore (%d -> %d)" % [pontos, p.pontos_habilidade])
	checar(m.capitulo == 2 and m.semente_entregue, "o capítulo 1 fechou e o 2 começou")
	checar(not m.entregar_semente() and p.pontos_habilidade == pontos + 1, "entregar a semente de novo não faz nada")
	r = m.conversar(p)
	checar(_tem_texto(r["linhas"], "SEMENTE") and _tem_texto(r["linhas"], "tocha"), "ele comemora e dá a Tocha do Brasinha")
	checar(p.inventario.quantidade_de(&"tocha_brasinha") == 1, "a Tocha do Brasinha está na mochila")
	checar(String(m.passo_atual()["id"]) == "raizes", "capítulo 2: levar a tocha até as raízes")
	checar(not w.passagem(World.RAIZES).aberta, "as raízes ainda estão fechadas")

	# Longe das raízes nada acontece; perto, elas queimam e as Ruínas abrem.
	p.global_position = w.centro
	m.verificar_tocha()
	checar(not w.passagem(World.RAIZES).aberta, "longe das raízes, a tocha não faz nada")
	p.global_position = w.passagem(World.RAIZES).global_position + Vector2(0, 20)
	m.verificar_tocha()
	await get_tree().physics_frame
	checar(w.passagem(World.RAIZES).aberta, "com a tocha perto, as raízes recuam e as Ruínas abrem")
	checar(String(m.passo_atual()["id"]) == "golem", "o próximo guardião é o Golem Ancião (para depois)")
	checar(m.regiao_do_objetivo() == Regioes.Id.COLINAS, "o alfinete aponta as Colinas")

	terminar()


func _tem_texto(linhas: Array, trecho: String) -> bool:
	for l in linhas:
		if String(l).to_lower().contains(trecho.to_lower()):
			return true
	return false
