class_name Regioes
extends RefCounted
## As 6 regiões da ilha (design/proposta_mundo.md): nome, chão, perigo e quem aparece de dia
## e de noite. O gerador da ilha (GeradorIlha) diz a região de cada bloco; o Povoamento usa
## as tabelas para fazer nascer os bichos; o mapa (M) usa o nome e a cor.
##
## Tabelas de aparecimento: lista de [tipo, peso]. `tipo` é uma chave de Povoamento.CRIATURAS
## (hoje: slime, atirador, galinha, coelho, javali, ovelha). Bicho novo da etapa 2 (cervo,
## caranguejo, sapo...) entra em Povoamento.CRIATURAS e numa linha destas tabelas.

enum Id { CLAREIRA, BOSQUE, PRAIA, PANTANO, COLINAS, RUINAS }

const TODAS: Array[int] = [Id.CLAREIRA, Id.BOSQUE, Id.PRAIA, Id.PANTANO, Id.COLINAS, Id.RUINAS]

## `perigo`: 0 (seguro) a 1 (o mais difícil); soma-se à distância do centro (ver perigo_em).
## `limite`: quantos bichos vivos a região aguenta com 1 jogador (cada jogador a mais: +50%).
## `noite`: o limite de criaturas da noite (somado ao do dia enquanto for noite).
const DADOS := {
	Id.CLAREIRA: {
		"nome": "Clareira", "perigo": 0.0, "limite": 10, "limite_noite": 3,
		"dia": [["galinha", 4], ["coelho", 4], ["ovelha", 2]],
		"noite": [["slime_noite", 1]],
	},
	Id.BOSQUE: {
		"nome": "Bosque Florido", "perigo": 0.25, "limite": 14, "limite_noite": 4,
		"dia": [["coelho", 3], ["javali", 3], ["ovelha", 2], ["slime", 3]],
		"noite": [["slime_noite", 3], ["atirador_noite", 1]],
	},
	Id.PRAIA: {
		"nome": "Praia das Conchas", "perigo": 0.3, "limite": 12, "limite_noite": 4,
		"dia": [["galinha", 2], ["atirador", 2], ["slime", 2]],
		"noite": [["slime_noite", 2], ["atirador_noite", 2]],
	},
	Id.PANTANO: {
		"nome": "Pântano dos Cogumelos", "perigo": 0.55, "limite": 14, "limite_noite": 6,
		"dia": [["slime", 6], ["javali", 1]],
		"noite": [["slime_noite", 4]],
	},
	Id.COLINAS: {
		"nome": "Colinas de Pedra", "perigo": 0.75, "limite": 12, "limite_noite": 5,
		"dia": [["ovelha", 3], ["javali", 2], ["atirador", 3]],
		"noite": [["atirador_noite", 2], ["slime_noite", 2]],
	},
	Id.RUINAS: {
		"nome": "Ruínas dos Guardiões", "perigo": 1.0, "limite": 12, "limite_noite": 6,
		"dia": [["slime", 4], ["atirador", 3]],
		"noite": [["slime_noite", 3], ["atirador_noite", 3]],
	},
}

## Cor de cada região no mapa (M): a cor média do chão dela.
const COR_MAPA := {
	Id.CLAREIRA: Color("a7a94f"), Id.BOSQUE: Color("8fae46"), Id.PRAIA: Color("e0c58a"),
	Id.PANTANO: Color("4f8a7e"), Id.COLINAS: Color("8b8a4f"), Id.RUINAS: Color("4f8a50"),
}


static func nome(r: int) -> String:
	return String(DADOS.get(r, DADOS[Id.CLAREIRA])["nome"])


static func dados(r: int) -> Dictionary:
	return DADOS.get(r, DADOS[Id.CLAREIRA])


## Limite de bichos vivos na região: cresce 50% por jogador a mais.
static func limite(r: int, jogadores: int, noite: bool) -> int:
	var d := dados(r)
	var base := int(d["limite"]) + (int(d["limite_noite"]) if noite else 0)
	return int(ceil(base * (1.0 + 0.5 * maxi(jogadores - 1, 0))))
