extends TesteBase
## Caído e tela de morte: vida 0 → o jogador cai (parado, sem golpe, sem dano, ignorado pelos
## slimes), a tela de morte conta 8 s, o botão "Reviver agora" só libera aos 4 s, aos 8 s
## volta sozinho no acampamento (vida cheia, 2 s protegido). O Levantar do Clérigo e um aliado
## segurando E levantam ali mesmo. Último suspiro e Juramento ainda não deixam cair. Dois
## caídos voltam cada um no seu tempo.

const SLIME := preload("res://scenes/enemies/slime.tscn")
const JOGADOR := preload("res://scenes/player/player.tscn")

var w: World
var p: Player
var aliado: Player


func _ready() -> void:
	w = await criar_mundo(0, true, &"clerigo")
	p = w.jogador
	p.global_position = w.centro + Vector2(0, 80)
	aliado = JOGADOR.instantiate()
	aliado.name = "2"
	aliado.classe = &"guerreiro"
	aliado.position = p.global_position + Vector2(16, 0)
	w.entidades.add_child(aliado)
	await get_tree().physics_frame

	await _queda_e_tela()
	await _botao_aos_4s()
	await _levantar_do_clerigo()
	await _segurar_e()
	await _nao_deixam_cair()
	await _todos_caidos()
	terminar()


func _queda_e_tela() -> void:
	p.inventario.adicionar(&"maca", 1)
	p.global_position = w.centro + Vector2(40, 90)
	var onde := p.global_position
	await get_tree().physics_frame
	p.vida.tomar_dano(100000.0)
	await get_tree().physics_frame
	checar(p.caido and p.vida.atual == 0.0, "vida 0: o jogador cai")
	checar(p.global_position == onde, "cai no lugar (não volta na hora para o acampamento)")
	var tela := p.tela_morte()
	checar(tela != null and tela.visible, "a tela de morte abre para quem caiu")
	checar(tela != null and tela.texto_contagem() == "8", "a contagem começa em 8 (%s)" % (tela.texto_contagem() if tela else "-"))
	checar(tela != null and not tela.botao_liberado(), "o botão Reviver agora começa travado")
	checar(p.visual.caido and not p.visual._item.visible, "o boneco deita e esconde o item da mão")
	if not p.visual.tem_arte_caido():
		checar(is_equal_approx(p.visual._completo.rotation, -PI / 2.0), "sem caido.png: placeholder (o perfil girado 90°)")
	checar(not aliado.caido and aliado.tela_morte() == null, "quem não caiu não vê tela de morte")
	# Caído não toma dano, não anda nem golpeia.
	checar(not p.vida.tomar_dano(10.0) and p.vida.atual == 0.0, "caído não toma mais dano")
	Input.action_press(&"mover_direita")
	await esperar(0.3)
	Input.action_release(&"mover_direita")
	checar(p.global_position == onde, "caído não anda")
	var s: Slime = colocar(w, SLIME, onde + Vector2(30, 0))
	s.vida.maximo = 1000.0
	s.vida.atual = 1000.0
	p.mira_forcada = s.global_position
	p._recarga_golpe = 0.0
	p._pedir_golpe(Vector2.RIGHT)
	await get_tree().physics_frame
	checar(s.vida.atual == 1000.0, "caído não golpeia")
	aliado.global_position = w.centro + Vector2(-400, -300)  # longe, mas de pé
	await esperar(0.3)
	checar(s._escolher_alvo() != p, "os inimigos ignoram o caído (vão atrás de quem está de pé)")
	s.queue_free()
	# Aos 2 s, o botão continua travado (e o anfitrião recusa o pedido).
	await esperar(1.5)
	checar(tela.texto_contagem() == "6", "a contagem desce (aos 2 s mostra %s)" % tela.texto_contagem())
	tela.apertar_reviver()
	p._pedir_reviver()
	await get_tree().physics_frame
	checar(p.caido and not tela.botao_liberado(), "antes dos 4 s o botão não revive")
	await esperar(2.2)
	checar(tela.botao_liberado(), "aos 4 s o botão libera")
	# Sem apertar: volta sozinho aos 8 s.
	await esperar(3.2)
	checar(p.caido, "ainda caído antes dos 8 s")
	await esperar(1.0)
	checar(not p.caido and p.tela_morte() == null, "aos 8 s volta sozinho e a tela fecha")
	checar(p.global_position == p.ponto_de_retorno, "volta no acampamento")
	checar(p.vida.atual == p.vida.maximo and p.vida.protegido(), "volta com a vida cheia e protegido")
	checar(not p.visual.caido and is_zero_approx(p.visual._completo.rotation), "o boneco levanta")
	await esperar(Player.PROTECAO_REVIVER + 0.2)
	checar(not p.vida.protegido(), "a proteção dura uns 2 s")


func _botao_aos_4s() -> void:
	p.global_position = w.centro + Vector2(60, 90)
	await get_tree().physics_frame
	p.vida.tomar_dano(100000.0)
	await esperar(Player.TEMPO_BOTAO + 0.2)
	var tela := p.tela_morte()
	checar(tela != null and tela.botao_liberado(), "caiu de novo: aos 4 s o botão está liberado")
	tela.apertar_reviver()
	await get_tree().physics_frame
	await get_tree().physics_frame
	checar(not p.caido and p.global_position == p.ponto_de_retorno, "Reviver agora volta no acampamento na hora")
	checar(p.vida.atual == p.vida.maximo and p.vida.protegido(), "Reviver agora: vida cheia e protegido")


func _levantar_do_clerigo() -> void:
	p.global_position = w.centro + Vector2(0, 80)
	aliado.global_position = p.global_position + Vector2(50, 0)
	var onde := aliado.global_position
	await get_tree().physics_frame
	aliado.vida.tomar_dano(100000.0)
	await get_tree().physics_frame
	checar(aliado.caido and aliado.visual.caido, "o aliado cai (todos veem o boneco caído)")
	p.aprender_de_graca(&"levantar")
	var t: Array[StringName] = [&"levantar"]
	p.teclas = t
	p._recargas.clear()
	p._prontas_no_anfitriao.clear()
	p.mana = p.ficha.mana_maxima()
	p.mira_forcada = onde
	checar(p.usar_habilidade_por_id(&"levantar"), "o Clérigo usa o Levantar")
	await get_tree().physics_frame
	checar(not aliado.caido and aliado.global_position == onde, "Levantar levanta o caído ali mesmo")
	checar(is_equal_approx(aliado.vida.atual, aliado.vida.maximo * LogicasClerigo.Levantar.VIDA),
			"Levantar: volta com parte da vida (%.0f de %.0f)" % [aliado.vida.atual, aliado.vida.maximo])


func _segurar_e() -> void:
	aliado.vida.tirar_protecao()
	aliado.global_position = p.global_position + Vector2(14, 0)
	await get_tree().physics_frame
	aliado.vida.tomar_dano(100000.0)
	await get_tree().physics_frame
	checar(p.aliado_caido_perto() == aliado and p.comecar_ajuda(), "perto do caído, o E começa a levantar")
	Input.action_press(&"habilidade_4")
	await esperar(1.5)
	checar(aliado.caido and p.progresso_interacao() > 0.3, "segurando E: a barrinha enche (%.0f%%)" % (p.progresso_interacao() * 100.0))
	await esperar(Player.TEMPO_AJUDA - 1.5 + 0.3)
	Input.action_release(&"habilidade_4")
	await get_tree().physics_frame
	checar(not aliado.caido, "segurando E por 3 s o aliado levanta")
	checar(is_equal_approx(aliado.vida.atual, aliado.vida.maximo * Player.VIDA_AJUDA), "levanta com pouca vida (%.0f)" % aliado.vida.atual)


func _nao_deixam_cair() -> void:
	# Último suspiro: o Clérigo perto segura o aliado com 1 de vida.
	p.aprender_de_graca(&"ultimo_suspiro")
	p._suspiro_pronto_ms = 0
	aliado.vida.curar_tudo()
	aliado.global_position = p.global_position + Vector2(20, 0)
	await get_tree().physics_frame
	aliado.vida.tomar_dano(100000.0)
	checar(not aliado.caido and is_equal_approx(aliado.vida.atual, 1.0), "Último suspiro: não cai (fica com 1 de vida)")
	# Juramento: o guerreiro não cai abaixo de 1 de vida.
	aliado.vida.curar_tudo()
	aliado.vida.tirar_protecao()
	aliado.global_position = p.global_position + Vector2(400, 0)  # longe do Clérigo
	aliado.set_meta(PassivasGuerreiro.META_JURAMENTO, Time.get_ticks_msec() + 5000)
	await get_tree().physics_frame
	aliado.vida.tomar_dano(100000.0)
	checar(not aliado.caido and aliado.vida.atual >= 1.0, "Juramento: não cai (ficou com %.1f de vida)" % aliado.vida.atual)
	aliado.remove_meta(PassivasGuerreiro.META_JURAMENTO)


func _todos_caidos() -> void:
	aliado.vida.curar_tudo()
	aliado.vida.tirar_protecao()
	p.vida.tirar_protecao()
	aliado.global_position = p.global_position + Vector2(400, 0)
	await get_tree().physics_frame
	p.vida.tomar_dano(100000.0)
	await esperar(2.0)
	aliado.vida.tomar_dano(100000.0)
	await get_tree().physics_frame
	checar(p.caido and aliado.caido, "os dois caídos")
	await esperar(Player.TEMPO_REVIVER - 2.0 + 0.3)
	checar(not p.caido and aliado.caido, "cada um volta no seu tempo (o primeiro já voltou)")
	await esperar(2.0)
	checar(not aliado.caido and aliado.global_position == aliado.ponto_de_retorno, "o segundo volta no acampamento dele")
