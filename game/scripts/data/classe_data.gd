class_name ClasseData
extends Resource
## Uma classe jogável (arquivos em res://data/classes/).

@export var id: StringName
@export var nome := ""
@export var familia := ""
@export_multiline var descricao := ""
## Atributos iniciais. Chaves: forca, vitalidade, agilidade, intelecto, espirito.
@export var atributos: Dictionary[StringName, int] = {}
## Habilidades da raiz (vão para as teclas 1, 2...).
@export var habilidades: Array[HabilidadeData] = []
@export var ramo_a := ""
@export var ramo_b := ""

const PASTA := "res://data/classes/"
const TODAS: Array[StringName] = [&"guerreiro", &"mago", &"arqueiro"]


static func carregar(classe_id: StringName) -> ClasseData:
	return load(PASTA + String(classe_id) + ".tres") as ClasseData
