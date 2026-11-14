class_name ArteBrasinha
extends RefCounted
## Onde ficam as texturas do Brasinha e das missões (pedido L42_brasinha.md ao Codex).
## Enquanto o arquivo não existir, `textura()` devolve null e quem chama usa o placeholder
## (a fogueira de antes, os ícones que já existem). Quando a arte chegar, é só pôr os
## arquivos nestes caminhos: nada mais muda. Todos os quadros têm 128 px.

const PASTA := "res://assets/sprites/tiny/"
const QUADRO := 128

const PARADO := PASTA + "brasinha_parado.png"  # tira de 6 quadros em laço
const HUMORES := PASTA + "brasinha_humores.png"  # 6 quadros: ver Humor
const RETRATO := PASTA + "brasinha_retrato.png"  # 2 quadros (0 normal, 1 falando)
const OBJETOS := PASTA + "objetos_historia.png"  # 6 quadros: ver Objeto
const LORE := PASTA + "lore_%d.png"  # lore_1 .. lore_5 (uma por região, ver LORE_DA_REGIAO)
const ICONE_EXCLAMACAO := PASTA + "icones/icone_missao_exclamacao.png"
const ICONE_INTERROGACAO := PASTA + "icones/icone_missao_interrogacao.png"
const ICONE_SEMENTE := PASTA + "icones/icone_semente_coracao.png"
const ICONE_ISCA := PASTA + "icones/icone_isca_gosma.png"
const ICONE_TOCHA := PASTA + "icones/icone_tocha_brasinha.png"
const ICONE_PEDRA := PASTA + "icones/icone_pedra_lore.png"

## Quadros da folha de humores.
enum Humor { FALANDO_A, FALANDO_B, FRAQUINHO, COMENDO, ASSUSTADO, COMEMORANDO }
## Quadros da folha de objetos da história.
enum Objeto { BASE_FOGUEIRA, PEDRA_APAGADA, PEDRA_LIDA, ALTAR_VAZIO, ALTAR_ISCA, RAIZES_QUEIMANDO }

## Qual imagem de lore vale para cada região (a Clareira não tem pedra).
const LORE_DA_REGIAO := {
	Regioes.Id.BOSQUE: 1, Regioes.Id.PRAIA: 2, Regioes.Id.PANTANO: 3,
	Regioes.Id.COLINAS: 4, Regioes.Id.RUINAS: 5,
}


## A textura, ou null se o arquivo ainda não existe.
static func textura(caminho: String) -> Texture2D:
	return load(caminho) as Texture2D if ResourceLoader.exists(caminho) else null


static func lore(regiao: int) -> Texture2D:
	return textura(LORE % int(LORE_DA_REGIAO.get(regiao, 0)))


## Um quadro de 128 px de uma folha, ou null se a folha não existe.
static func quadro(caminho: String, indice: int) -> AtlasTexture:
	var t := textura(caminho)
	if t == null:
		return null
	var a := AtlasTexture.new()
	a.atlas = t
	a.region = Rect2(indice * QUADRO, 0, QUADRO, QUADRO)
	return a


## A arte final do Brasinha já chegou?
static func tem_brasinha() -> bool:
	return ResourceLoader.exists(PARADO) and ResourceLoader.exists(OBJETOS)
