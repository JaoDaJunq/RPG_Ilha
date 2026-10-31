class_name ItemData
extends Resource
## Definição de um item (os arquivos ficam em res://data/items/).

@export var id: StringName
@export var nome := ""
@export var icone: Texture2D
## Cor aplicada ao ícone (para placeholders que reaproveitam o mesmo desenho).
@export var cor_icone := Color.WHITE
## Quantos cabem num espaço do inventário (como no Minecraft: 64; ferramentas 1).
@export var pilha := 64
## Ferramenta: "machado" (árvores), "picareta" (pedras) ou "espada" (golpe). Vazio = não é.
@export var ferramenta: StringName
## Quanto a ferramenta ajuda: coleta mais rápida ou golpe mais forte (1 = mão vazia).
@export var poder := 1.0
## Peça que dá para pôr no mundo (construção): id da cena em res://scenes/construcao/.
@export var construcao: StringName
## Roupa: onde se veste (&"cabeca" ou &"corpo"). Vazio = não é roupa. Só visual por enquanto.
@export var equipa: StringName = &""
## Consumível: quanto de vida recupera ao usar (botão direito com ele na mão).
@export var cura := 0.0

const PASTA := "res://data/items/"


static func carregar(item_id: StringName) -> ItemData:
	return load(PASTA + String(item_id) + ".tres") as ItemData


static func existe(item_id: StringName) -> bool:
	return item_id != &"" and ResourceLoader.exists(PASTA + String(item_id) + ".tres")
