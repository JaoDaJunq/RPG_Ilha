class_name HabilidadeData
extends Resource
## Uma habilidade (arquivos em res://data/habilidades/). O que ela faz fica no script
## `logica` (filho de HabilidadeLogica); aqui ficam os números e o jeito de lançar.

enum Modo {
	RAPIDO,    ## vai na hora, na direção do mouse
	IMEDIATO,  ## sem alvo (em volta do jogador)
	CARREGAR,  ## como RAPIDO, mas segurar além da conjuração enche a carga (0 a 1)
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
## Nome da lógica: uma classe interna de Logicas ou de logicas_<classe>.gd (ex.: &"Investida").
@export var logica: StringName
## Animação do boneco ao lançar (prefixo, sem a direção): &"golpe" (padrão) ou &"parado"
## (sem animação). Vazio usa &"golpe".
@export var animacao: StringName
## Quanto tempo (s) a animação fica na tela. 0 usa o padrão (0,2 s).
@export var duracao_animacao := 0.0
## Som ao lançar (nome em Sfx). Vazio usa a tabela antiga Player.SONS (e depois &"ataque").
@export var som: StringName

# --- Conjuração (design/conjuracao.md) ---------------------------------------------
## Tempo (s) segurando a tecla antes de poder soltar (feitiço sendo conjurado, corda do arco
## sendo puxada). 0 = sai na hora. Soltar antes cancela sem gastar mana nem recarga.
## No modo CARREGAR, é a puxada mínima; segurando mais, a carga continua até encher.
@export var conjuracao := 0.0
## Atributo que deixa a conjuração mais rápida: &"intelecto" (magias), &"agilidade" (arco)
## ou vazio (tempo fixo). Fórmula em Conjuracao.reducao().
@export var atributo_conjuracao: StringName = &"intelecto"
## Velocidade de andar enquanto conjura (0,5 = metade).
@export var velocidade_conjurando := 0.5
