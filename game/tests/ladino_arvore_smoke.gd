extends TesteBase
## Árvore do Ladino: cada nó que era pendente agora funciona. Para cada um, aprende, usa (ou
## mede a passiva) e confere o efeito com números.

const SLIME := preload("res://scenes/enemies/slime.tscn")

const ATIVAS: Array[StringName] = [
	&"sumir", &"passo_das_sombras", &"marca_da_morte", &"mil_cortes",
	&"frasco_de_acido", &"nuvem_toxica", &"veneno_paralisante", &"praga",
	&"danca_das_laminas", &"bumerangue_de_adaga", &"leque_giratorio", &"tempestade_de_aco",
]
const PASSIVAS: Array[StringName] = [&"toxina", &"esquiva_perfeita", &"dedos_leves"]

var w: World
var p: Player
var mf := 1.0  # multiplicador físico do ladino
var mm := 1.0  # multiplicador mágico (químico, sombra)


func _ready() -> void:
	w = await criar_mundo(0, true, &"ladino")
	p = w.jogador
	p.global_position = w.centro + Vector2(-40, 70)
	mf = p.ficha.multiplicador_fisico()
	mm = p.ficha.multiplicador_magico()
	await get_tree().physics_frame
	_arvore()
	await _sumir()
	await _passo_das_sombras()
	await _marca_da_morte()
	await _mil_cortes()
	await _toxina()
	await _frasco_de_acido()
	await _nuvem_toxica()
	await _veneno_paralisante()
	await _praga()
	await _danca_das_laminas()
	await _bumerangue()
	await _esquiva_perfeita()
	await _leque_giratorio()
	await _tempestade_de_aco()
	terminar()


# --- Ajudas ----------------------------------------------------------------------------

## Slime parado (sem pensar) com 100 de vida, olhando para o ladino (sem Pelas costas).
func _slime(pos: Vector2) -> Slime:
	var s: Slime = colocar(w, SLIME, pos)
	s.set_physics_process(false)
	s.vida.maximo = 100.0
	s.vida.atual = 100.0
	s.visual.flip_h = pos.x > p.global_position.x
	return s


func _tirou(s: Slime) -> float:
	return 100.0 - (s.vida.atual if is_instance_valid(s) else 0.0)


func _limpar(lista: Array) -> void:
	for n in lista:
		if is_instance_valid(n):
			n.queue_free()
	await get_tree().physics_frame


func _perto(a: float, b: float, folga := 0.02) -> bool:
	return absf(a - b) <= folga


## Aprende `id`, põe sozinha na tecla Q e usa mirando em `mira`. Confere a mana e a recarga.
func _usar(id: StringName, mira: Vector2) -> void:
	p.aprender_de_graca(id)
	var t: Array[StringName] = [id]
	p.teclas = t
	p.mana = 500.0
	p.mira_forcada = mira
	p.global_position = p.global_position  # parado
	await get_tree().physics_frame
	var hab := ArvoreData.no(&"ladino", id).habilidade
	var usou := p.usar_habilidade_por_id(id)
	checar(usou and _perto(p.mana, 500.0 - p.custo_de(hab)) and p.recarga_restante(0) > 0.0,
			"%s: vai para a tecla, gasta %.0f de mana e entra em recarga (%.1f s)" % [hab.nome, p.custo_de(hab), p.recarga_de(hab)])


func _adagas() -> int:
	var n := 0
	for pr in get_tree().get_nodes_in_group(&"projeteis"):
		if not pr.is_queued_for_deletion():
			n += 1
	return n


# --- Árvore ----------------------------------------------------------------------------

func _arvore() -> void:
	var todos := true
	for id in ATIVAS + PASSIVAS:
		var n := ArvoreData.no(&"ladino", id)
		todos = todos and n != null and not n.pendente and n.falta == ""
	checar(todos, "os 15 nós (14 pendentes e Dedos leves) estão marcados como funcionando")
	var ativas_ok := true
	for id in ATIVAS:
		var n := ArvoreData.no(&"ladino", id)
		ativas_ok = ativas_ok and n.usavel() and n.rank_maximo() == 1 + NoArvore.MELHORIAS \
				and Logicas.classe_da_logica(n.habilidade.logica) != null and n.habilidade.id == id
	checar(ativas_ok, "as 12 ativas novas têm .tres, lógica registrada e aceitam 3 melhorias")
	checar(ArvoreData.no(&"ladino", &"dedos_leves").descricao.contains("baús trancados"), "Dedos leves volta a abrir os baús trancados (agora existem)")
	p.aprender_de_graca(&"sumir")
	checar(&"sumir" in p.ids_nas_teclas() and p.habilidades().size() == 3, "aprendida, a ativa nova vai para uma tecla livre (Q R T E)")


# --- Sombra ----------------------------------------------------------------------------

func _sumir() -> void:
	var s := _slime(p.global_position + Vector2(40, 0))
	await _usar(&"sumir", s.global_position)
	await get_tree().physics_frame
	checar(p.efeitos.tem(EfeitosEstado.INVISIVEL) and p.escondido() and _perto(p.efeitos.restante(EfeitosEstado.INVISIVEL), 4.0, 0.1),
			"Sumir: invisível por 4 s (%.1f s), os inimigos não veem" % p.efeitos.restante(EfeitosEstado.INVISIVEL))
	Golpes.acertar(p, s, 1.0, &"fisico")
	checar(not p.efeitos.tem(EfeitosEstado.INVISIVEL) and not p.escondido(), "Sumir: atacar quebra a invisibilidade")
	await _limpar([s])


func _passo_das_sombras() -> void:
	var s := _slime(p.global_position + Vector2(70, 0))  # olha para a esquerda (para o ladino)
	await _usar(&"passo_das_sombras", s.global_position)
	await esperar(0.15)
	var esperado := 2.0 * mf * Passivas.PELAS_COSTAS
	checar(p.global_position.x > s.global_position.x + 4.0, "Passo das sombras: o ladino aparece atrás do slime (%.0f px depois dele)" % (p.global_position.x - s.global_position.x))
	checar(_perto(_tirou(s), esperado), "Passo das sombras: golpe pelas costas (%.2f, esperado %.2f)" % [_tirou(s), esperado])
	p.global_position = w.centro + Vector2(-40, 70)
	await _limpar([s])


func _marca_da_morte() -> void:
	var s := _slime(p.global_position + Vector2(60, 0))
	p.recursos.gastar_combo()
	p.recursos.ganhar_combo(3)
	await _usar(&"marca_da_morte", s.global_position)
	checar(p.recursos.combo == 0 and s.efeitos.tem(EfeitosEstado.MARCADO), "Marca da morte: gasta os 3 pontos de combo e marca o alvo")
	s.vida._protecao = 0.0  # sem a proteção de 0,15 s do último golpe
	(s.get_node("Hurtbox") as Hurtbox).receber(10.0, &"fisico", null)
	var antes := _tirou(s)
	checar(_perto(antes, 12.0), "Marca da morte: o marcado toma +20%% (10 viraram %.1f)" % antes)
	await esperar(4.2)
	var explosao := _tirou(s) - antes
	var base := 2.0 * mm + antes * MarcaFracao.de(3)
	checar(_perto(explosao, base, 0.05) or _perto(explosao, base * 1.2, 0.05),
			"Marca da morte: explode com 2 + 50%% do dano levado (%.2f, esperado %.2f)" % [explosao, base])
	await _limpar([s])


func _mil_cortes() -> void:
	var a := _slime(p.global_position + Vector2(25, 0))
	var b := _slime(p.global_position + Vector2(-25, 10))
	await _usar(&"mil_cortes", p.global_position)
	checar(p.vida.protegido(), "Mil cortes: o ladino fica intocável")
	await esperar(1.6)
	var esperado := 8.0 * 1.2 * mf
	checar(_perto(_tirou(a), esperado, 0.05) and _perto(_tirou(b), esperado, 0.05),
			"Mil cortes: 8 golpes em todos em volta (%.2f e %.2f, esperado %.2f)" % [_tirou(a), _tirou(b), esperado])
	await _limpar([a, b])


# --- Venenos ---------------------------------------------------------------------------

func _toxina() -> void:
	var s := _slime(p.global_position + Vector2(60, 0))
	for k in 3:
		EfeitosEstado.aplicar_em(s, EfeitosEstado.VENENO, 3.0, 1.0, p)
	var sem := s.efeitos.acumulos(EfeitosEstado.VENENO)
	p.aprender_de_graca(&"toxina")
	for k in 7:
		EfeitosEstado.aplicar_em(s, EfeitosEstado.VENENO, 3.0, 1.0, p)
	var com := s.efeitos.acumulos(EfeitosEstado.VENENO)
	checar(sem == 1 and com == 5, "Toxina: o Veneno acumula até 5 (sem: %d, com: %d)" % [sem, com])
	await esperar(1.05)
	checar(_perto(_tirou(s), 5.0), "Toxina: 5 acúmulos dão 5x o dano por segundo (%.1f no 1º tique)" % _tirou(s))
	# Lâmina envenenada também acumula.
	s.efeitos.remover(EfeitosEstado.VENENO)
	p.envenenar_golpes(6.0, 0.6)
	for k in 3:
		p.envenenar_atingido(s.get_node("Hurtbox") as Hurtbox)
	checar(s.efeitos.acumulos(EfeitosEstado.VENENO) == 3, "Toxina: os golpes da Lâmina envenenada acumulam (%d)" % s.efeitos.acumulos(EfeitosEstado.VENENO))
	p.envenenar_golpes(0.0, 0.0)
	await _limpar([s])


func _frasco_de_acido() -> void:
	var s := _slime(p.global_position + Vector2(50, 0))
	await _usar(&"frasco_de_acido", s.global_position)
	await esperar(0.2)  # o slime fica 0,15 s protegido depois de um golpe
	checar(s.efeitos.tem(EfeitosEstado.MARCADO) and _perto(_tirou(s), 0.8 * mm), "Frasco de ácido: corrói (%.2f) e marca quem está dentro" % _tirou(s))
	var antes := _tirou(s)
	s.vida._protecao = 0.0
	(s.get_node("Hurtbox") as Hurtbox).receber(10.0, &"fisico", null)
	checar(_perto(_tirou(s) - antes, 12.0), "Frasco de ácido: dentro da poça toma +20%% de dano (10 viraram %.1f)" % (_tirou(s) - antes))
	await esperar(1.0)
	checar(_tirou(s) - antes - 12.0 >= 0.8 * mm, "Frasco de ácido: segue corroendo a cada segundo")
	await esperar(4.2)
	await _limpar([s])


func _nuvens() -> Array[Zona]:
	var l: Array[Zona] = []
	for n in p.get_parent().get_children():
		if n is Zona and n.has_meta(&"nuvem_toxica") and not n.is_queued_for_deletion():
			l.append(n)
	return l


func _nuvem_toxica() -> void:
	var s := _slime(p.global_position + Vector2(50, 0))
	await _usar(&"nuvem_toxica", s.global_position)
	await esperar(0.1)
	checar(s.efeitos.tem(EfeitosEstado.VENENO) and _perto(s.efeitos.forca(EfeitosEstado.VENENO), 0.8 * mm), "Nuvem tóxica: envenena quem está dentro (%.2f por segundo)" % s.efeitos.forca(EfeitosEstado.VENENO))
	await esperar(1.0)
	checar(s.efeitos.acumulos(EfeitosEstado.VENENO) == 2, "Nuvem tóxica: com Toxina, cada segundo dentro soma um acúmulo (%d)" % s.efeitos.acumulos(EfeitosEstado.VENENO))
	# Fogo dentro: o slime pega fogo e a nuvem explode.
	var nuvem := _nuvens()
	var antes := _tirou(s)
	EfeitosEstado.aplicar_em(s, EfeitosEstado.QUEIMADURA, 3.0, 1.0)
	await esperar(0.15)
	var explosao := 0.8 * mm * LogicasLadino.NuvemToxica.EXPLOSAO * 2.0  # o fogo dobra no slime
	checar(nuvem.size() == 1 and not is_instance_valid(nuvem[0]) and _perto(_tirou(s) - antes, explosao, 0.05),
			"Nuvem tóxica: o fogo faz a nuvem explodir (%.2f de dano, esperado %.2f)" % [_tirou(s) - antes, explosao])
	await _limpar([s])
	# Uma bola de fogo atravessando a nuvem também explode.
	var hab := ArvoreData.no(&"ladino", &"nuvem_toxica").habilidade
	LogicasLadino.NuvemToxica.new().executar(p, hab, Vector2.RIGHT, p.global_position + Vector2(60, -10), 0.0)
	var outra := _nuvens()
	Logicas.lancar(Logicas.BOLA_DE_FOGO, p, Vector2.RIGHT, 0.0)
	await esperar(0.5)
	checar(outra.size() == 1 and not is_instance_valid(outra[0]), "Nuvem tóxica: uma bola de fogo dentro dela também a faz explodir")


func _veneno_paralisante() -> void:
	var s := _slime(p.global_position + Vector2(50, 0))
	for k in 3:
		EfeitosEstado.aplicar_em(s, EfeitosEstado.VENENO, 3.0, 0.1, p)
	p.recursos.gastar_combo()
	p.recursos.ganhar_combo(2)
	await _usar(&"veneno_paralisante", s.global_position)
	var esperado := 1.5 * mm * (1.0 + 0.5 * 2)
	checar(p.recursos.combo == 1 and _perto(_tirou(s), esperado), "Veneno paralisante: gasta os 2 pontos (o golpe dá 1 novo) e bate mais (%.2f, esperado %.2f)" % [_tirou(s), esperado])
	checar(s.efeitos.tem(EfeitosEstado.ATORDOADO) and _perto(s.efeitos.restante(EfeitosEstado.ATORDOADO), 3.0, 0.05),
			"Veneno paralisante: 3 acúmulos = Atordoado por 3 s (%.1f)" % s.efeitos.restante(EfeitosEstado.ATORDOADO))
	var limpo := _slime(p.global_position + Vector2(50, 30))
	await esperar(0.2)
	p._prontas_no_anfitriao.clear()
	p._recargas.clear()
	p.mira_forcada = limpo.global_position
	p.usar_habilidade_por_id(&"veneno_paralisante")
	checar(_tirou(limpo) > 0.0 and not limpo.efeitos.tem(EfeitosEstado.ATORDOADO), "Veneno paralisante: sem veneno, não paralisa")
	await _limpar([s, limpo])


func _praga() -> void:
	var a := _slime(p.global_position + Vector2(50, 0))
	var b := _slime(p.global_position + Vector2(-120, 0))
	var c := _slime(p.global_position + Vector2(0, 60))
	for k in 4:
		EfeitosEstado.aplicar_em(a, EfeitosEstado.VENENO, 3.0, 1.0, p)
	EfeitosEstado.aplicar_em(b, EfeitosEstado.VENENO, 3.0, 0.5, p)
	var ra := a.efeitos.dano_restante(EfeitosEstado.VENENO)
	var rb := b.efeitos.dano_restante(EfeitosEstado.VENENO)
	await _usar(&"praga", p.global_position)
	checar(_perto(_tirou(a), ra) and _perto(_tirou(b), rb) and ra == 12.0,
			"Praga: cada envenenado toma de uma vez o que faltava (%.1f de %.1f e %.1f de %.1f)" % [_tirou(a), ra, _tirou(b), rb])
	checar(not a.efeitos.tem(EfeitosEstado.VENENO) and _tirou(c) == 0.0, "Praga: o veneno acaba e quem não estava envenenado não toma nada")
	await _limpar([a, b, c])


# --- Acrobata --------------------------------------------------------------------------

func _danca_das_laminas() -> void:
	var lista: Array[Slime] = []
	for k in 4:
		lista.append(_slime(p.global_position + Vector2(40 + 35 * k, 0)))
	var longe := _slime(p.global_position + Vector2(40 + 35 * 3 + 120, 0))
	var x0 := p.global_position.x
	await _usar(&"danca_das_laminas", lista[0].global_position)
	await esperar(0.2)
	var todos := true
	for s in lista:
		todos = todos and _perto(_tirou(s), 1.5 * mf)
	checar(todos and _tirou(longe) == 0.0, "Dança das lâminas: acerta 4 inimigos (1,5 cada) e não o 5º longe")
	checar(p.global_position.x - x0 > 100.0, "Dança das lâminas: o ladino termina ao lado do último (%.0f px)" % (p.global_position.x - x0))
	p.global_position = w.centro + Vector2(-40, 70)
	await _limpar(lista + [longe])


func _bumerangue() -> void:
	var s := _slime(p.global_position + Vector2(35, -10))
	await _usar(&"bumerangue_de_adaga", s.global_position)
	await esperar(1.2)
	checar(_perto(_tirou(s), 2.0 * 1.5 * mf), "Bumerangue de adaga: acerta na ida e na volta (%.2f, esperado %.2f)" % [_tirou(s), 3.0 * mf])
	# Melhoria: +15% de dano.
	p.arvore[&"bumerangue_de_adaga"] = 2
	p._prontas_no_anfitriao.clear()
	p._recargas.clear()
	var antes := _tirou(s)
	p.usar_habilidade_por_id(&"bumerangue_de_adaga")
	await esperar(1.2)
	checar(_perto(_tirou(s) - antes, 3.0 * mf * 1.15), "Bumerangue de adaga: aceita melhoria (+15%%: %.2f)" % (_tirou(s) - antes))
	await _limpar([s])


func _esquiva_perfeita() -> void:
	var s := _slime(p.global_position + Vector2(20, 0))
	p.aprender_de_graca(&"esquiva_perfeita")
	p.vida.curar_tudo()
	p.esquivar()
	await get_tree().physics_frame
	checar(p.recarga_esquiva_restante() > 0.0, "Esquiva perfeita: o dash entrou em recarga")
	var vida := p.vida.atual
	s._cabecada(p)  # o slime pula logo depois do dash
	await get_tree().physics_frame
	checar(p.vida.atual == vida and p.recarga_esquiva_restante() == 0.0, "Esquiva perfeita: o golpe passou e o dash recarregou na hora")
	await esperar(0.3)  # o dash termina
	p.global_position = s.global_position - Vector2(20, 0)  # o dash levou o ladino; volta para a frente do slime
	await esperar(0.2)
	Golpes.acertar(p, s, 1.0, &"fisico")
	var primeiro := _tirou(s)
	await esperar(0.2)
	s.vida._protecao = 0.0
	Golpes.acertar(p, s, 1.0, &"fisico")
	checar(_perto(primeiro, 2.0) and _perto(_tirou(s) - primeiro, 1.0), "Esquiva perfeita: o próximo golpe é crítico (%.1f, depois %.1f)" % [primeiro, _tirou(s) - primeiro])
	await esperar(0.5)
	p.vida.curar_tudo()
	s._cabecada(p)
	checar(p.vida.atual < p.vida.maximo, "sem esquivar, o golpe do slime machuca")
	p.vida.curar_tudo()
	await _limpar([s])


func _leque_giratorio() -> void:
	await esperar(0.8)  # as adagas de antes somem
	var antes := _adagas()
	p.recursos.gastar_combo()
	p.recursos.ganhar_combo(4)
	await _usar(&"leque_giratorio", p.global_position + Vector2(30, 0))
	checar(_adagas() - antes == 12 and p.recursos.combo == 0, "Leque giratório: 4 pontos = 12 adagas em círculo (%d)" % (_adagas() - antes))
	await esperar(0.8)
	p._prontas_no_anfitriao.clear()
	p._recargas.clear()
	antes = _adagas()
	p.usar_habilidade_por_id(&"leque_giratorio")
	checar(_adagas() - antes == 3, "Leque giratório: sem pontos, solta 3 (%d)" % (_adagas() - antes))
	await esperar(0.8)


func _tempestade_de_aco() -> void:
	var antes := _adagas()
	p.esquivar()
	await get_tree().physics_frame
	checar(_adagas() == antes, "sem a Tempestade, o dash não solta adagas")
	await _usar(&"tempestade_de_aco", p.global_position)
	await get_tree().physics_frame
	checar(p.recarga_esquiva_restante() == 0.0, "Tempestade de aço: o dash fica pronto na hora")
	antes = _adagas()
	p.esquivar()
	await get_tree().physics_frame
	checar(_adagas() - antes == PassivasLadino.TEMPESTADE_ADAGAS, "Tempestade de aço: cada dash solta 8 adagas (%d)" % (_adagas() - antes))
	p.set_meta(&"tempestade_ate_ms", Time.get_ticks_msec() - 1)
	await esperar(1.3)
	antes = _adagas()
	p.esquivar()
	await get_tree().physics_frame
	checar(_adagas() == antes, "Tempestade de aço: acabado o tempo, o dash volta ao normal")


class MarcaFracao:
	static func de(pontos: int) -> float:
		return LogicasLadino.MarcaDaMorte.fracao(pontos)
