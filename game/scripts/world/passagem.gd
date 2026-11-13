class_name Passagem
extends StaticBody2D
## Um caminho que abre com as Sementes (etapa 3): a ponte quebrada do rio e a muralha de
## raízes do vau. Fechada, mostra o desenho fechado e (as raízes) bloqueia a passagem;
## aberta, mostra o outro desenho e deixa passar. Quem decide é o anfitrião
## (World.abrir_passagem); todos os jogadores mudam juntos.

## Folha com 2 quadros quadrados (L36): 0 e 1.
const QUADRO := 384
const PE := 8

var id := ""
var textura := ""
var aberta := false
## Quadro da folha de cada estado. A ponte: 0 inteira (aberta), 1 quebrada (fechada).
## As raízes: 0 muralha (fechada), 1 recolhidas (aberta).
var quadro_aberta := 0
var quadro_fechada := 1
## Largura do bloqueio quando fechada (0 = não bloqueia; na ponte quem bloqueia é a água).
var largura_bloqueio := 0.0
## Fica embaixo de quem passa (a ponte), em vez de entrar na ordem de quem está na frente.
var no_chao := false

var _sprite: Sprite2D
var _forma: CollisionShape2D


func _ready() -> void:
	add_to_group(&"passagens")
	if id == World.RAIZES:
		quadro_aberta = 1
		quadro_fechada = 0
	_sprite = Sprite2D.new()
	if ResourceLoader.exists(textura):
		_sprite.texture = load(textura)
	_sprite.region_enabled = true
	_sprite.centered = false
	_sprite.scale = Vector2(0.25, 0.25)
	_sprite.offset = Vector2(-QUADRO / 2.0, -QUADRO + PE)
	add_child(_sprite)  # a ponte (no_chao) fica fora das Entidades: embaixo de quem passa
	if largura_bloqueio > 0.0:
		_forma = CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(largura_bloqueio, 14)
		_forma.shape = r
		_forma.position = Vector2(0, -8)
		add_child(_forma)
	definir(aberta)


func definir(abrir: bool) -> void:
	aberta = abrir
	if _sprite == null:
		return
	_sprite.region_rect = Rect2((quadro_aberta if aberta else quadro_fechada) * QUADRO, 0, QUADRO, QUADRO)
	if _forma:
		_forma.set_deferred(&"disabled", aberta)
