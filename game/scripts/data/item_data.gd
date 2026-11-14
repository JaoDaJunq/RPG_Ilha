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
## Poção de mana: quanto de mana devolve ao usar (L39).
@export var mana := 0.0
## Poção de resistência: fração do dano a menos (0,3 = 30%) por `segundos_efeito`.
@export var resistencia := 0.0
@export var segundos_efeito := 0.0
## Arma de classe (L39): de qual classe ela é (&"guerreiro", &"mago"...), quanto multiplica o
## dano das habilidades e qual desenho vai na mão (a arma base: &"arco", &"cajado"...).
@export var arma_de: StringName = &""
@export var bonus_arma := 1.0
@export var visual_mao: StringName = &""

const PASTA := "res://data/items/"


static func carregar(item_id: StringName) -> ItemData:
	var d := load(PASTA + String(item_id) + ".tres") as ItemData
	# Item sem ícone no .tres (a arte ainda não chegou): procura icone_<id>.png; se não houver,
	# usa o gel de slime como placeholder (quando a arte chegar, basta pôr o arquivo).
	if d and d.icone == null:
		var arte := "res://assets/sprites/tiny/icones/icone_%s.png" % String(item_id)
		var gel := "res://assets/sprites/tiny/icones/item_gosma_curativa.png"
		if ResourceLoader.exists(arte):
			d.icone = load(arte) as Texture2D
		elif ResourceLoader.exists(gel):
			d.icone = load(gel) as Texture2D
	return d


static func existe(item_id: StringName) -> bool:
	return item_id != &"" and ResourceLoader.exists(PASTA + String(item_id) + ".tres")
