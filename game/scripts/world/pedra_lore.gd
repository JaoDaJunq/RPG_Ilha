class_name PedraLore
extends StaticBody2D
## Pedra antiga com uma lembrança da ilha (uma por região, menos a Clareira). Clicar nela
## abre o painel com a imagem e uma frase (PainelLore). O anfitrião anota que foi lida
## (Missoes.ler_pedra): a do pântano conta para a missão "Pedras que lembram".
##
## Arte final: objetos_historia.png, quadro PEDRA_APAGADA e PEDRA_LIDA (ArteBrasinha).
## Enquanto não chega, usa a pedra comum do mundo, arroxeada se ainda não foi lida.

const PLACEHOLDER := preload("res://assets/sprites/tiny/pedras_slime.png")
const COR_NAO_LIDA := Color(0.85, 0.7, 1.3)
const COR_LIDA := Color(0.8, 0.8, 0.85)

var regiao := Regioes.Id.PANTANO
var lida := false
var _sprite: Sprite2D


func _ready() -> void:
	add_to_group(&"pedras_lore")
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.scale = Vector2(0.25, 0.25)
	_sprite.offset = Vector2(-64, -128 + 8)
	add_child(_sprite)
	var forma := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 7.0
	forma.shape = c
	forma.position = Vector2(0, -5)
	add_child(forma)
	var area := Area2D.new()
	area.name = "Interactable"
	area.set_script(preload("res://scripts/components/interactable.gd"))
	area.set(&"alcance", 34.0)
	area.set(&"tempo_segurar", 0.15)
	var f2 := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(28, 26)
	f2.shape = r
	f2.position = Vector2(0, -12)
	area.add_child(f2)
	add_child(area)
	definir_lida(lida)


func definir_lida(valor: bool) -> void:
	lida = valor
	if _sprite == null:
		return
	var quadro := ArteBrasinha.quadro(ArteBrasinha.OBJETOS, ArteBrasinha.Objeto.PEDRA_LIDA if lida else ArteBrasinha.Objeto.PEDRA_APAGADA)
	if quadro:
		_sprite.texture = quadro.atlas
		_sprite.region_enabled = true
		_sprite.region_rect = quadro.region
		_sprite.modulate = Color.WHITE
	else:
		_sprite.texture = PLACEHOLDER
		_sprite.region_enabled = true
		_sprite.region_rect = Rect2(0, 0, 128, 128)
		_sprite.modulate = COR_LIDA if lida else COR_NAO_LIDA


func pode_interagir() -> bool:
	return true


func texto_acao() -> String:
	return "Ler a pedra"


func destacar(ligado: bool) -> void:
	if _sprite:
		_sprite.self_modulate = Color(1.15, 1.15, 1.05) if ligado else Color.WHITE


func altura_visivel() -> float:
	return 24.0


## Só o anfitrião chama (o jogador clicou).
func interagir(quem: Player) -> void:
	var w := get_tree().get_first_node_in_group(&"mundo") as World
	if w and w.missoes:
		w.missoes.ler_pedra(quem, regiao)
