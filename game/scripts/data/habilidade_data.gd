class_name HabilidadeData
extends Resource
## Uma habilidade (arquivos em res://data/habilidades/). O que ela faz fica no script
## `logica` (filho de HabilidadeLogica); aqui ficam os números e o jeito de lançar.

enum Modo {
	RAPIDO,    ## vai na hora, na direção do mouse
	IMEDIATO,  ## sem alvo (em volta do jogador)
	CARREGAR,  ## segura a tecla para carregar e solta para lançar
}

@export var id: StringName
@export var nome := ""
@export_multiline var descricao := ""
@export var icone: Texture2D
@export var modo := Modo.RAPIDO
@export var custo_mana := 0.0
@export var recarga := 1.0
## físico, fogo, gelo, raio, natureza, sombra, luz ou químico.
@export var elemento: StringName = &"fisico"
@export var dano := 1.0
## Distância máxima (para mira no chão, como a armadilha).
@export var alcance := 0.0
## Nome da lógica em Logicas (ex.: &"Investida").
@export var logica: StringName
