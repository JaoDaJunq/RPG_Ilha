class_name PassivasGuerreiro
extends RefCounted
## Passivas novas do Guerreiro (árvore de habilidades). Passivas.gd chama estas funções em todo
## jogador, de qualquer classe: cada uma confere `p.tem(&"<nó>")` antes de agir. As
## antigas continuam em passivas.gd. Devolva 1.0 (ou não faça nada) quando não valer.
## Roda no ANFITRIÃO, menos `velocidade`, que roda no dono (quem anda).


## Multiplicador do dano que `p` causa em `alvo` (antes de aplicar).
static func dano_causado(_p: Player, _quantidade: float, _tipo: StringName, _alvo: Node) -> float:
	return 1.0


## Depois que um golpe ou habilidade de `p` acertou `alvo` (o dano já foi aplicado).
static func acertou(_p: Player, _alvo: Node, _quantidade: float, _tipo: StringName) -> void:
	pass


## Multiplicador do dano que `p` recebe.
static func dano_recebido(_p: Player, _quantidade: float, _tipo: StringName) -> float:
	return 1.0


## Multiplicador do dano de um inimigo ou animal (`atacante`) em `alvo` (Ex.: Frio que morde).
static func ataque_inimigo(_atacante: Node, _alvo: Node, _dano: float) -> float:
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
