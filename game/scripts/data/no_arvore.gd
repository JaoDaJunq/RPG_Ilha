class_name NoArvore
extends RefCounted
## Um nó da árvore de habilidades (design/arvore_habilidades.md, versão 2). Os nós de
## cada classe são montados por ArvoreData a partir de uma tabela.

enum Tipo { PASSIVA, ATIVA }

## Colunas especiais (as outras são os ramos: &"guardiao", &"fogo"...).
const RAMO_CLASSE := &"classe"
const RAMO_INICIAIS := &"iniciais"
## Melhorias de uma habilidade depois de aprendida (pontos que sobram).
const MELHORIAS := 3
## Cada melhoria: +15% de dano e 10% menos recarga.
const DANO_POR_MELHORIA := 0.15
const RECARGA_POR_MELHORIA := 0.1

var id: StringName
var nome := ""
var descricao := ""
var tipo := Tipo.PASSIVA
var ramo: StringName
## Posição na coluna, de cima para baixo.
var etapa := 0
## Nível mínimo do personagem para aprender.
var nivel := 1
var custo := 1
## Todos estes precisam estar aprendidos.
var requisitos: Array[StringName] = []
## Pelo menos um destes precisa estar aprendido (a entrada de um ramo).
var algum_de: Array[StringName] = []
## Ativa que já existe no jogo (vai para as teclas Q R T E).
var habilidade: HabilidadeData
var icone: Texture2D
## Já vem com a classe, sem gastar ponto (passivas da classe e as 2 habilidades padrão).
var padrao := false
## Ainda não faz nada no jogo: dá para aprender, mas o efeito fica para depois.
var pendente := false
## Parte do efeito que ainda não existe ("" = funciona inteiro).
var falta := ""
## Iniciais: os ramos que esta habilidade abre.
var leva_a: Array[StringName] = []


func ativa() -> bool:
	return tipo == Tipo.ATIVA


## Ativa com efeito de verdade: vai para as teclas e aceita melhorias.
func usavel() -> bool:
	return ativa() and habilidade != null and not pendente


func rank_maximo() -> int:
	return 1 + MELHORIAS if usavel() else 1


## "Funciona", "Parcial: ..." ou "Efeito pendente".
func texto_estado_efeito() -> String:
	if pendente:
		return "Efeito pendente: dá para aprender, mas ainda não faz nada no jogo."
	if falta != "":
		return "Ainda falta: " + falta
	return ""
