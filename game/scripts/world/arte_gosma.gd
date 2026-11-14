class_name ArteGosma
extends RefCounted
## Onde ficam as texturas da Mãe Gosma (pedido L43_mae_gosma.md ao Codex). Enquanto o arquivo
## não existe, `textura()` devolve null e quem chama usa o placeholder (o slime existente,
## maior). Quando a arte chegar, é só pôr os arquivos nestes caminhos. Quadros de 128 px.

const PASTA := "res://assets/sprites/tiny/"
const QUADRO := 128

## Tira de 6 quadros por elemento ("" = a gosma normal da fase 1).
const FOLHAS := {
	&"": PASTA + "inimigos/mae_gosma.png",
	&"fogo": PASTA + "inimigos/mae_gosma_fogo.png",
	&"gelo": PASTA + "inimigos/mae_gosma_gelo.png",
	&"veneno": PASTA + "inimigos/mae_gosma_veneno.png",
}
const ARENA := PASTA + "inimigos/arena_gosma.png"  # quadros: Arena
const ICONE_GOSMA_REAL := PASTA + "icones/icone_gosma_real.png"
const ICONE_POCAO_FORTE := PASTA + "icones/icone_pocao_cura_forte.png"
const ICONE_BOSS := PASTA + "icones/icone_boss_gosma.png"

## Quadros da tira da Mãe Gosma.
enum Quadro { PARADA, RESPIRANDO, AGACHANDO, NO_AR, ESMAGANDO, MACHUCADA }
## Quadros da folha da arena.
enum Arena { ALVO, POCA, COROA }

## Escala da Mãe Gosma na arte final e no placeholder (o slime comum é pequeno).
const ESCALA_ARTE := 0.5
const ESCALA_PLACEHOLDER := 0.75
## As três menores da fase 3 usam as mesmas folhas, menores.
const ESCALA_FILHOTE := 0.6

## Cor do elemento (poça, aviso e o placeholder da gosma).
const COR := {
	&"": Color(0.75, 1.0, 0.7), &"fogo": Color(1.5, 0.8, 0.5),
	&"gelo": Color(0.7, 1.1, 1.6), &"veneno": Color(0.9, 0.5, 1.4),
}


static func textura(caminho: String) -> Texture2D:
	return load(caminho) as Texture2D if ResourceLoader.exists(caminho) else null


## A arte final da Mãe Gosma deste elemento já chegou?
static func tem_folha(elemento: StringName) -> bool:
	return ResourceLoader.exists(String(FOLHAS.get(elemento, FOLHAS[&""])))


## Um quadro de 128 px da folha da arena, ou null se ela ainda não existe.
static func quadro_arena(indice: int) -> AtlasTexture:
	var t := textura(ARENA)
	if t == null:
		return null
	var a := AtlasTexture.new()
	a.atlas = t
	a.region = Rect2(indice * QUADRO, 0, QUADRO, QUADRO)
	return a


## Põe `n` no chão do mundo: filho do mundo, logo antes das entidades, então fica embaixo de
## quem anda (alvo, poça e coroa).
static func no_chao(n: Node2D, de: Node) -> void:
	var w := de.get_tree().get_first_node_in_group(&"mundo") as World
	if w == null:
		de.add_child(n)
		return
	w.add_child(n)
	w.move_child(n, w.entidades.get_index())
