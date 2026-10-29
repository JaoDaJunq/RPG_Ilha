class_name ItemData
extends Resource
## Definição de um item (os arquivos ficam em res://data/items/).

@export var id: StringName
@export var nome := ""
@export var icone: Texture2D
## Cor aplicada ao ícone (para placeholders que reaproveitam o mesmo desenho).
@export var cor_icone := Color.WHITE

const PASTA := "res://data/items/"


static func carregar(item_id: StringName) -> ItemData:
	return load(PASTA + String(item_id) + ".tres") as ItemData
