class_name RacaData
extends Resource
## Uma raça jogável (arquivos em res://data/racas/). Dá bônus e penalidades nos atributos
## e uma habilidade de raça. Nunca proíbe classe nenhuma.

@export var id: StringName
@export var nome := ""
@export_multiline var descricao := ""
## Somado aos atributos da classe. Chaves: forca, vitalidade, agilidade, intelecto, espirito.
@export var bonus: Dictionary[StringName, int] = {}
@export var habilidade_nome := ""
@export_multiline var habilidade_descricao := ""

const PASTA := "res://data/racas/"
const TODAS: Array[StringName] = [&"humano", &"ogro"]


static func carregar(raca_id: StringName) -> RacaData:
	return load(PASTA + String(raca_id) + ".tres") as RacaData
