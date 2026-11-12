extends TesteBase
## Ficha do personagem (C), "Ideia B": selos com os pontos nas abas, o "+" de cada atributo
## gastando ponto pelo anfitrião, a prévia do que muda e a aba de habilidades.


func _ready() -> void:
	var w := await criar_mundo(0, true, &"guerreiro", &"humano")
	var p := w.jogador
	var ficha := w.hud.ficha()
	checar(not ficha.visible, "a ficha começa fechada")
	checar(ficha.texto_selo(FichaTela.ABA_ATRIBUTOS) == "" and ficha.texto_selo(FichaTela.ABA_HABILIDADES) == "", "nível 1, sem pontos: os selos ficam escondidos")
	checar(ficha.botao_mais(&"forca").disabled and ficha.botao_mais(&"forca").modulate.a == 0.0, "sem pontos: o + some")
	checar(ficha.valor_mostrado(&"vitalidade") == str(p.ficha.valor(&"vitalidade")), "o ladrilho mostra o valor (%s)" % ficha.valor_mostrado(&"vitalidade"))
	checar(ficha.valor_status(&"vida") == str(roundi(p.ficha.vida_maxima())) and ficha.valor_status(&"fisico") == "%d%%" % roundi(p.ficha.multiplicador_fisico() * 100.0),
		"as caixinhas mostram vida e dano físico (%s, %s)" % [ficha.valor_status(&"vida"), ficha.valor_status(&"fisico")])

	p.ganhar_xp(Ficha.xp_para_subir(1))
	await get_tree().physics_frame
	checar(ficha.texto_selo(FichaTela.ABA_ATRIBUTOS) == "2" and ficha.texto_selo(FichaTela.ABA_HABILIDADES) == "1",
		"nível 2: selo 2 em Atributos e 1 em Habilidades (%s, %s)" % [ficha.texto_selo(0), ficha.texto_selo(1)])
	checar(not ficha.botao_mais(&"vitalidade").disabled and ficha.botao_mais(&"vitalidade").modulate.a == 1.0, "com pontos: o + aparece")

	# Prévia: o mouse no + de Vitalidade mostra a vida nova.
	var vida := roundi(p.ficha.vida_maxima())
	var vit := p.ficha.valor(&"vitalidade")
	ficha.botao_mais(&"vitalidade").mouse_entered.emit()
	var previa := ficha.texto_previa()
	checar(previa.contains("Vida %d → %d" % [vida, vida + 10]) and previa.contains("Vitalidade %d → %d" % [vit, vit + 1]), "a prévia mostra o que muda (%s)" % previa)
	checar(ficha.valor_status(&"vida") == str(vida + 10) and ficha.valor_status(&"mana") == str(roundi(p.ficha.mana_maxima())), "na prévia, só a caixinha da vida muda")
	ficha.botao_mais(&"vitalidade").mouse_exited.emit()
	checar(ficha.texto_previa() == "" and ficha.valor_status(&"vida") == str(vida), "o mouse sai: a prévia some")

	# O + gasta o ponto (pedido ao anfitrião).
	ficha.botao_mais(&"vitalidade").pressed.emit()
	await get_tree().physics_frame
	checar(p.distribuidos.get(&"vitalidade", 0) == 1 and p.pontos_atributo == 1, "o + coloca 1 ponto em Vitalidade")
	checar(ficha.valor_mostrado(&"vitalidade") == str(vit + 1) and ficha.valor_status(&"vida") == str(vida + 10) and ficha.texto_selo(0) == "1",
		"a ficha acompanha: Vitalidade %s, vida %s, selo %s" % [ficha.valor_mostrado(&"vitalidade"), ficha.valor_status(&"vida"), ficha.texto_selo(0)])
	ficha.mostrar_previa(&"intelecto")
	checar(ficha.texto_previa().contains("Mana %d → %d" % [roundi(p.ficha.mana_maxima()), roundi(p.ficha.mana_maxima()) + 5]) and ficha.texto_previa().contains("Dano mágico"), "prévia do Intelecto: mana e dano mágico (%s)" % ficha.texto_previa())
	ficha.botao_mais(&"intelecto").pressed.emit()
	await get_tree().physics_frame
	checar(p.pontos_atributo == 0 and ficha.texto_selo(0) == "" and ficha.botao_mais(&"intelecto").disabled, "acabaram os pontos: o selo e o + somem")
	checar(ficha.texto_previa() == "", "sem pontos, sem prévia")

	# Aba Habilidades.
	ficha.abrir_aba(FichaTela.ABA_HABILIDADES)
	checar(ficha.aba() == FichaTela.ABA_HABILIDADES, "troca para a aba Habilidades")
	var nomes := ficha.nomes_habilidades()
	checar(nomes.size() == 2 and nomes[0] == ArvoreData.no(&"guerreiro", ArvoreData.padrao(&"guerreiro")[0]).nome, "a aba lista as habilidades das teclas (%s)" % ", ".join(nomes))
	checar(ficha.botao_arvore().text == "Abrir árvore (%s)" % Configuracoes.tecla_de(&"arvore"), "o botão diz a tecla da árvore (%s)" % ficha.botao_arvore().text)
	ficha.visible = true
	ficha.botao_arvore().pressed.emit()
	await get_tree().process_frame
	checar(w.hud.arvore().aberta() and not ficha.visible, "o botão fecha a ficha e abre a árvore")
	terminar()
