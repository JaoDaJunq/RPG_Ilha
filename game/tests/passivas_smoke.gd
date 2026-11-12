extends TesteBase
## Passivas da árvore de habilidades mudando números de verdade no jogo (as da classe valem
## desde o nível 1; as de ramo são aprendidas com `aprender_de_graca`, o atalho dos testes).

const SLIME := preload("res://scenes/enemies/slime.tscn")
const ANIMAL := preload("res://scenes/animals/animal.tscn")


func _ready() -> void:
	await _guerreiro()
	await _ladino()
	await _mago()
	await _arqueiro()
	await _clerigo()
	terminar()


func _fim(w: World) -> void:
	w.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


## Slime parado e com muita vida, para medir o dano de cada acerto.
func _alvo(w: World, pos: Vector2, vida := 100.0) -> Slime:
	var s: Slime = colocar(w, SLIME, pos)
	s.set_physics_process(false)
	await get_tree().physics_frame
	s.vida.maximo = maxf(vida, 1.0)
	s.vida.atual = vida
	return s


## Dano que um acerto de `quantidade` (pela Hurtbox, como golpe e habilidades) tira do alvo.
func _acerto(alvo: Node2D, quantidade: float, tipo: StringName, origem: Node) -> float:
	var v: HealthComponent = alvo.get_node("HealthComponent")
	v._protecao = 0.0  # sem a proteção curta depois de cada golpe: um acerto atrás do outro
	var antes := v.atual
	(alvo.get_node("Hurtbox") as Hurtbox).receber(quantidade, tipo, origem)
	return antes - v.atual


func _guerreiro() -> void:
	var w := await criar_mundo(0, true, &"guerreiro")
	var p := w.jogador
	var v := p.vida
	var antes := v.atual
	v.tomar_dano(10.0, &"fisico")
	checar(is_equal_approx(antes - v.atual, 9.0), "Pele de ferro: 10 de dano físico viram %.1f" % (antes - v.atual))
	v.curar_tudo()
	await esperar(0.1)

	var s := await _alvo(w, p.global_position + Vector2(30, 0))
	p.aprender_de_graca(&"sangue_quente")
	checar(is_equal_approx(_acerto(s, 1.0, &"fisico", p), 1.0), "Sangue quente com a vida cheia: sem bônus")
	v.atual = v.maximo / 2.0
	var meio := _acerto(s, 1.0, &"fisico", p)
	checar(is_equal_approx(meio, 1.2), "Sangue quente com metade da vida: +20%% (%.2f)" % meio)

	p.aprender_de_graca(&"sede")
	var fraco := await _alvo(w, p.global_position + Vector2(-30, 0), 0.5)
	var vida_antes := v.atual
	_acerto(fraco, 1.0, &"fisico", p)
	checar(is_equal_approx(v.atual - vida_antes, v.maximo * 0.05), "Sede: derrotar cura 5%% da vida (+%.1f)" % (v.atual - vida_antes))
	await _fim(w)


func _ladino() -> void:
	var w := await criar_mundo(0, true, &"ladino")
	var p := w.jogador
	# O slime parado olha para a direita (sem espelhar o desenho).
	var s := await _alvo(w, p.global_position + Vector2(30, 0))
	s.visual.flip_h = false
	checar(is_equal_approx(_acerto(s, 1.0, &"fisico", p), 1.5), "Pelas costas: o ladino atrás do slime dá +50%")
	s.visual.flip_h = true
	checar(is_equal_approx(_acerto(s, 1.0, &"fisico", p), 1.0), "de frente: dano normal")

	p.aprender_de_graca(&"execucao")
	s.vida.atual = 20.0
	checar(is_equal_approx(_acerto(s, 1.0, &"fisico", p), 2.0), "Execução: inimigo com menos de 30% de vida leva o dobro")
	s.vida.atual = 100.0

	p.aprender_de_graca(&"emboscada")
	p.esconder(0.3)
	await esperar(0.4)
	checar(is_equal_approx(_acerto(s, 1.0, &"fisico", p), 2.0), "Emboscada: o primeiro golpe depois da fumaça é crítico")
	checar(is_equal_approx(_acerto(s, 1.0, &"fisico", p), 1.0), "Emboscada: só o primeiro")
	s.queue_free()

	# Dedos leves (da classe): o slime derrotado deixa 1 pilha a mais.
	var fraco := await _alvo(w, p.global_position + Vector2(0, 40), 0.5)
	_acerto(fraco, 1.0, &"fisico", p)
	await get_tree().physics_frame
	checar(get_tree().get_nodes_in_group(&"itens_chao").size() == 2, "Dedos leves: o slime deixa o gel dele e mais 1 (%d pilhas)" % get_tree().get_nodes_in_group(&"itens_chao").size())

	# Contágio: o envenenado que morre passa o veneno ao vizinho.
	p.aprender_de_graca(&"contagio")
	var a := await _alvo(w, p.global_position + Vector2(60, 60), 0.5)
	var b := await _alvo(w, p.global_position + Vector2(80, 60))
	a.envenenar(3.0, 1.0)
	_acerto(a, 1.0, &"fisico", p)
	checar(b.envenenado, "Contágio: o vizinho ficou envenenado")
	b.queue_free()

	# Passos de gato (da classe): o slime só nota o ladino a 70% da distância.
	var olho: Slime = colocar(w, SLIME, p.global_position + Vector2(-75, 0))
	await esperar(0.3)
	checar(not olho.persegue(p), "Passos de gato: a 75 px (visão de 90) o slime não notou o ladino")
	olho.global_position = p.global_position + Vector2(-55, 0)
	await esperar(0.3)
	checar(olho.persegue(p), "mais perto (55 px) ele nota")
	await _fim(w)


func _mago() -> void:
	var w := await criar_mundo(0, true, &"mago")
	var p := w.jogador
	# Fluxo arcano (da classe): mana volta 25% mais rápido.
	p.mana = 0.0
	await esperar(1.0)
	var esperado := p.ficha.regeneracao_mana() * 1.25
	checar(absf(p.mana - esperado) < esperado * 0.15, "Fluxo arcano: %.2f de mana em 1 s (sem a passiva seria %.2f)" % [p.mana, p.ficha.regeneracao_mana()])
	p.mana = p.ficha.mana_maxima()

	# Raízes: parado por 1 s, toma 20% menos dano.
	p.aprender_de_graca(&"raio")
	p.aprender_de_graca(&"raizes")
	await esperar(1.2)
	var antes := p.vida.atual
	p.vida.tomar_dano(10.0, &"fisico")
	checar(is_equal_approx(antes - p.vida.atual, 8.0), "Raízes: parado, 10 de dano viram %.1f" % (antes - p.vida.atual))
	p.vida.curar_tudo()

	# Ressonância (da classe): Raio depois de Bola de fogo bate 15% mais que Raio depois de Raio.
	var s := await _alvo(w, p.global_position + Vector2(50, 0))
	p.mira_forcada = s.global_position
	p.usar_habilidade_por_id(&"raio")
	await esperar(0.1)
	var raio1 := 100.0 - s.vida.atual
	p.mira_forcada = p.global_position + Vector2(0, -80)
	p.usar_habilidade_por_id(&"bola_de_fogo")
	await esperar(3.1)
	s.vida.atual = 100.0
	p.mira_forcada = s.global_position
	p.usar_habilidade_por_id(&"raio")
	await esperar(0.1)
	var raio2 := 100.0 - s.vida.atual
	checar(raio1 > 0.0 and is_equal_approx(raio2, raio1 * 1.15), "Ressonância: Raio depois da Bola de fogo %.3f contra %.3f (+15%%)" % [raio2, raio1])

	# Condução: o raio salta para o vizinho.
	p.aprender_de_graca(&"conducao")
	var vizinho := await _alvo(w, s.global_position + Vector2(0, 30))
	await esperar(3.1)
	p.usar_habilidade_por_id(&"raio")
	await esperar(0.1)
	checar(vizinho.vida.atual < 100.0, "Condução: o raio saltou para o vizinho (vida %.2f)" % vizinho.vida.atual)

	# Sobrecarga: a cada 4 feitiços, o próximo sai de graça.
	p.aprender_de_graca(&"sobrecarga")
	for i in 4:
		p.mana = p.ficha.mana_maxima()
		p._recargas.clear()
		p._prontas_no_anfitriao.clear()
		p.mira_forcada = p.global_position + Vector2(0, -80)
		p.usar_habilidade_por_id(&"bola_de_fogo")
		await get_tree().physics_frame
	checar(p.feitico_gratis(), "Sobrecarga: depois de 4 feitiços, o próximo é de graça")
	p._recargas.clear()
	p._prontas_no_anfitriao.clear()
	var mana_antes := p.mana
	p.usar_habilidade_por_id(&"bola_de_fogo")
	await get_tree().physics_frame
	checar(p.mana >= mana_antes and not p.feitico_gratis(), "o feitiço de graça não gastou mana (%.1f → %.1f)" % [mana_antes, p.mana])
	await _fim(w)


func _arqueiro() -> void:
	var w := await criar_mundo(0, true, &"arqueiro")
	var p := w.jogador
	# Rastreador (da classe): animais levam o dobro.
	var bicho: Animal = colocar(w, ANIMAL, p.global_position + Vector2(40, 0))
	bicho.set_physics_process(false)
	await get_tree().physics_frame
	bicho.vida.maximo = 100.0
	bicho.vida.atual = 100.0
	checar(is_equal_approx(_acerto(bicho, 1.0, &"fisico", p), 2.0), "Rastreador: animal leva o dobro")
	# Engenhoso: armadilha 30% mais barata e 3 armadas.
	var hab := ArvoreData.no(&"arqueiro", &"armadilha").habilidade
	p.aprender_de_graca(&"engenhoso")
	checar(is_equal_approx(p.custo_de(hab), hab.custo_mana * 0.7) and Passivas.armadilhas_maximas(p) == 3, "Engenhoso: armadilha custa %.1f de mana (era %.1f) e cabem 3" % [p.custo_de(hab), hab.custo_mana])
	await _fim(w)


func _clerigo() -> void:
	var w := await criar_mundo(0, true, &"clerigo")
	var p := w.jogador
	var v := p.vida
	# Aura serena (da classe): +1 de vida a cada 3 s.
	v.atual = v.maximo - 10.0
	await esperar(3.2)
	checar(is_equal_approx(v.atual, v.maximo - 9.0), "Aura serena: +1 de vida em 3 s (%.1f de %.1f)" % [v.atual, v.maximo])

	# Fé (da classe): curar com a vida cheia vira escudo, que segura o próximo dano.
	v.curar_tudo()
	p.usar_habilidade_por_id(&"cura")
	await get_tree().physics_frame
	var cura := Logicas.Cura.quantidade(p.ficha)
	checar(is_equal_approx(v.escudo, cura), "Fé: a cura que sobrou virou %.1f de escudo" % v.escudo)
	var antes := v.atual
	v.tomar_dano(5.0, &"magico")
	checar(v.atual == antes and is_equal_approx(v.escudo, cura - 5.0), "o escudo segura o dano antes da vida")

	# Mãos que curam: +25%; Égide: escudos 30% mais fortes.
	p.aprender_de_graca(&"maos_que_curam")
	v.escudo = 0.0
	p._recargas.clear()  # sem esperar a recarga da Cura
	p._prontas_no_anfitriao.clear()
	p.mana = p.ficha.mana_maxima()
	v.atual = 1.0
	p.usar_habilidade_por_id(&"cura")
	await get_tree().physics_frame
	checar(is_equal_approx(v.atual, minf(v.maximo, 1.0 + cura * 1.25)), "Mãos que curam: a Cura sobe para %.1f (era %.1f)" % [cura * 1.25, cura])

	# Último suspiro: quem cairia fica com 1 de vida, uma vez por minuto.
	p.aprender_de_graca(&"ultimo_suspiro")
	v.escudo = 0.0
	v.curar_tudo()
	await esperar(0.1)
	v.tomar_dano(10000.0, &"fisico")
	checar(is_equal_approx(v.atual, 1.0), "Último suspiro: ficou com 1 de vida (%.1f)" % v.atual)

	# Julgamento: a luz marca, e o alvo marcado leva +15% de qualquer um.
	p.aprender_de_graca(&"julgamento")
	var s := await _alvo(w, p.global_position + Vector2(20, 0))
	_acerto(s, 1.0, &"luz", p)
	checar(is_equal_approx(_acerto(s, 1.0, &"fisico", null), 1.15), "Julgamento: depois da luz, o slime leva +15% até de armadilha")
	await _fim(w)
