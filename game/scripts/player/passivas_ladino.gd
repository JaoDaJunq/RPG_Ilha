class_name PassivasLadino
extends RefCounted
## Passivas novas do Ladino (árvore de habilidades). Passivas.gd chama estas funções em todo
## jogador, de qualquer classe: cada uma confere `p.tem(&"<nó>")` antes de agir. As
## antigas continuam em passivas.gd. Devolva 1.0 (ou não faça nada) quando não valer.
## Roda no ANFITRIÃO, menos `velocidade`, que roda no dono (quem anda).

## Toxina: o Veneno de quem tem a passiva acumula até 5 vezes.
const TOXINA_ACUMULOS := 5
## Esquiva perfeita: o golpe do inimigo chegou até 0,3 s depois do dash.
const ESQUIVA_PERFEITA_MS := 300
## Tempestade de aço: adagas soltas a cada dash.
const TEMPESTADE_ADAGAS := 8


## Toxina (chamado por EfeitosEstado.aplicar): quantos acúmulos de Veneno `origem` consegue.
static func acumulos_veneno(origem: Node) -> int:
	var p := origem as Player if is_instance_valid(origem) else null
	return TOXINA_ACUMULOS if p and p.tem(&"toxina") else 1


## O jogador deu um dash (Shift; o anfitrião chama em Player._pedir_esquiva).
## Esquiva perfeita guarda a hora; a Tempestade de aço solta adagas em volta.
static func esquivou(p: Player) -> void:
	var agora := Time.get_ticks_msec()
	if p.tem(&"esquiva_perfeita"):
		p.set_meta(&"esquiva_ms", agora)
	if agora < int(p.get_meta(&"tempestade_ate_ms", 0)):
		LogicasLadino.adagas_em_volta(p, TEMPESTADE_ADAGAS, float(p.get_meta(&"tempestade_dano", 1.0)))


## Multiplicador do dano que `p` causa em `alvo` (antes de aplicar).
## (Esquiva perfeita: o crítico garantido fica em Passivas.forcar_critico / _critico.)
static func dano_causado(_p: Player, _quantidade: float, _tipo: StringName, _alvo: Node) -> float:
	return 1.0


## Depois que um golpe ou habilidade de `p` acertou `alvo` (o dano já foi aplicado).
static func acertou(p: Player, _alvo: Node, _quantidade: float, _tipo: StringName) -> void:
	# Sumir: atacar quebra a invisibilidade.
	if p.get_meta(&"sumindo", false):
		p.set_meta(&"sumindo", false)
		p.efeitos.remover(EfeitosEstado.INVISIVEL)


## Multiplicador do dano que `p` recebe.
static func dano_recebido(_p: Player, _quantidade: float, _tipo: StringName) -> float:
	return 1.0


## Multiplicador do dano de um inimigo ou animal (`atacante`) em `alvo` (Ex.: Frio que morde).
static func ataque_inimigo(_atacante: Node, alvo: Node, _dano: float) -> float:
	# Esquiva perfeita: o golpe chegou logo depois do dash (ainda protegido): o dash
	# recarrega na hora e o próximo acerto é crítico.
	var p := alvo as Player
	if p and p.tem(&"esquiva_perfeita") and p.has_meta(&"esquiva_ms") and p.vida.protegido() \
			and Time.get_ticks_msec() - int(p.get_meta(&"esquiva_ms")) <= ESQUIVA_PERFEITA_MS:
		p.remove_meta(&"esquiva_ms")
		Passivas.forcar_critico(p)
		p.liberar_esquiva()
		World.efeito_todos(p, &"subir_nivel", p.global_position + Vector2(0, -14))
		p.avisar("Esquiva perfeita! Dash pronto e o próximo golpe é crítico.")
	return 1.0


## `p` derrotou `alvo`.
static func derrotou(_p: Player, _alvo: Node) -> void:
	pass


## Multiplicador de velocidade (roda no DONO).
static func velocidade(_p: Player) -> float:
	return 1.0


## Multiplicador da recarga da habilidade.
static func recarga(_p: Player, _hab: HabilidadeData) -> float:
	return 1.0


## Multiplicador do custo de mana da habilidade.
static func custo_mana(_p: Player, _hab: HabilidadeData) -> float:
	return 1.0


## Todo quadro, no anfitrião (auras, relógios).
static func processar(_p: Player, _delta: float) -> void:
	pass
