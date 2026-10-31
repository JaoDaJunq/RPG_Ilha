class_name ReceitaData
extends Resource
## Receita de fabricação, como no Minecraft (os arquivos ficam em res://data/receitas/).
## Com forma: `padrao` são as linhas da grade, cada letra é um item de `chave`, espaço é
## vazio; vale em qualquer lugar da grade e também espelhada. Sem forma: só os itens de
## `ingredientes` (em qualquer posição). Receita com mais de 2x2 só cabe na bancada (3x3).

@export var resultado: StringName
@export var quantidade := 1
@export var padrao: PackedStringArray
@export var chave: Dictionary[String, StringName] = {}
@export var sem_forma := false
@export var ingredientes: Array[StringName] = []

const PASTA := "res://data/receitas/"

static var _todas: Array[ReceitaData] = []


static func todas() -> Array[ReceitaData]:
	if _todas.is_empty():
		for f in ResourceLoader.list_directory(PASTA):
			if f.ends_with(".tres"):
				_todas.append(load(PASTA + f) as ReceitaData)
	return _todas


## A receita que a grade forma (lado 2 ou 3; `grade` em linhas, &"" = vazio), ou null.
static func encontrar(grade: Array[StringName], lado: int) -> ReceitaData:
	for r in todas():
		if r.combina(grade, lado):
			return r
	return null


func combina(grade: Array[StringName], lado: int) -> bool:
	if sem_forma:
		var falta := ingredientes.duplicate()
		for item in grade:
			if item == &"":
				continue
			var k := falta.find(item)
			if k < 0:
				return false
			falta.remove_at(k)
		return falta.is_empty()
	# Recorta a grade até a caixa dos itens e compara com o padrão (normal e espelhado).
	var x0 := lado
	var y0 := lado
	var x1 := -1
	var y1 := -1
	for y in lado:
		for x in lado:
			if grade[y * lado + x] != &"":
				x0 = mini(x0, x)
				y0 = mini(y0, y)
				x1 = maxi(x1, x)
				y1 = maxi(y1, y)
	if x1 < 0:
		return false
	var largura := x1 - x0 + 1
	var altura := y1 - y0 + 1
	if altura != padrao.size() or largura != padrao[0].length():
		return false
	for espelho in [false, true]:
		var igual := true
		for y in altura:
			for x in largura:
				var letra := padrao[y][largura - 1 - x if espelho else x]
				var quer: StringName = chave.get(letra, &"") if letra != " " else &""
				if grade[(y0 + y) * lado + x0 + x] != quer:
					igual = false
		if igual:
			return true
	return false
