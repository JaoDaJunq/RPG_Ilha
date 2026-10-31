class_name ResourceNode
extends StaticBody2D
## Árvore, pedra e qualquer coisa que se coleta segurando E.
##
## Estados: INTEIRO → (fogo) QUEIMANDO → QUEIMADO → (coleta) ESGOTADO
##          INTEIRO → (coleta) ESGOTADO
## Cortar rende o item normal; queimar transforma o que ele rende (árvore → carvão).
##
## Rede: as árvores e pedras nascem iguais em todos os jogadores (mesma semente e mesmos
## nomes). Só o anfitrião muda o estado e avisa todo mundo com _definir_estado.

enum Estado { INTEIRO, QUEIMANDO, QUEIMADO, ESGOTADO }

## Fogo do Tiny Swords (quadros de 64 px, escala 0,25).
const TEXTURA_CHAMAS := preload("res://assets/tiny_swords/fx/fogo.png")

@export var acao := "Cortar"
@export var golpes := 3
@export var item_id: StringName = &"madeira"
@export var quantidade := 3
@export var acao_queimado := "Recolher carvão"
@export var item_queimado: StringName = &"carvao"
@export var quantidade_queimado := 2
## Some do mapa ao esgotar (pedra); se falso, vira a região "esgotado" (toco).
@export var some_ao_esgotar := false
@export var regiao_inteiro := Rect2()
@export var regiao_queimado := Rect2()
@export var regiao_esgotado := Rect2()
## Aparência depois de cada golpe (1º, 2º...). O último vale para os golpes seguintes.
## Vazio: não muda até esgotar (ex.: a variação rosa ainda não tem marca de machado).
@export var regioes_por_golpe: Array[Rect2] = []
## Arte do Tiny Swords (tile de 64 px): entra com escala 0,25. `pe`: quantos pixels da arte
## há entre a base do desenho e o fundo do quadro. `quadros`: a arte "inteira" é uma tira
## animada (árvore balançando ao vento). Texturas vazias = a do Sprite2D da cena.
@export var escala := 1.0
@export var pe := 0
@export var quadros := 1
@export var textura_inteiro: Texture2D
@export var textura_esgotado: Texture2D
## Sem arte de árvore queimada no pacote: por enquanto ela escurece (provisório).
@export var cor_queimado := Color.WHITE
## Fogo: depois de quanto tempo queimando passa para as vizinhas, e até que distância.
@export var espalhar_apos := 2.0
@export var raio_do_fogo := 42.0

var estado := Estado.INTEIRO
var _golpes_restantes: int

@onready var sprite: Sprite2D = $Sprite2D
@onready var interacao: Interactable = $Interactable
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var inflamavel: Flammable = get_node_or_null("Flammable")
@onready var chamas: Node2D = get_node_or_null("Chamas")


func _ready() -> void:
	add_to_group(&"recursos")
	_golpes_restantes = golpes
	if textura_inteiro:
		sprite.texture = textura_inteiro
	_textura_inteiro = sprite.texture
	sprite.scale = Vector2(escala, escala)
	_tempo_animacao = randf() * 2.0
	set_process(quadros > 1)
	hurtbox.atingido.connect(_on_atingido)
	if inflamavel:
		inflamavel.apagou_queimado.connect(_on_queimou)
	if chamas:
		chamas.visible = false
		var f := SpriteFrames.new()
		f.remove_animation(&"default")
		SpriteSheets.adicionar_tira(f, TEXTURA_CHAMAS, &"queimando", Vector2i(64, 64), 8, 10.0)
		for c in chamas.get_children():
			if c is AnimatedSprite2D:
				c.sprite_frames = f
				c.scale = Vector2(0.25, 0.25)
				c.play(&"queimando")
				c.frame = randi() % 8
	_mostrar(regiao_inteiro)


func pode_interagir() -> bool:
	return estado == Estado.INTEIRO or estado == Estado.QUEIMADO


func texto_acao() -> String:
	return acao_queimado if estado == Estado.QUEIMADO else acao


func destacar(ligado: bool) -> void:
	sprite.modulate = Color(1.15, 1.15, 1.05) if ligado else Color.WHITE


## Um "golpe" de coleta. Só o anfitrião chama (o jogador pede pela rede).
func interagir(quem: Player) -> void:
	if not multiplayer.is_server() or not pode_interagir():
		return
	if estado == Estado.QUEIMADO:
		_entregar(quem, item_queimado, quantidade_queimado)
		_definir_estado.rpc(Estado.ESGOTADO, 0, true)
		return
	var restantes := _golpes_restantes - 1
	if restantes <= 0:
		_entregar(quem, item_id, quantidade)
		_definir_estado.rpc(Estado.ESGOTADO, 0, true)
	else:
		_definir_estado.rpc(estado, restantes, true)


## Um projétil desse elemento para aqui? Só o fogo, numa árvore inteira (que pega fogo).
func para_projetil(elemento: StringName) -> bool:
	return elemento == &"fogo" and estado == Estado.INTEIRO and inflamavel != null


func golpes_restantes() -> int:
	return _golpes_restantes


## O anfitrião manda o estado para um jogador que acabou de entrar.
func enviar_estado_para(peer: int) -> void:
	if estado != Estado.INTEIRO or _golpes_restantes != golpes:
		_definir_estado.rpc_id(peer, estado, _golpes_restantes, false)


@rpc("any_peer", "call_local", "reliable")
func _definir_estado(novo: Estado, restantes: int, com_golpe: bool) -> void:
	if not Net.veio_do_anfitriao():
		return
	_golpes_restantes = restantes
	if com_golpe:
		Sfx.tocar(&"golpe_coleta")
		_tremer()
	if novo == estado:
		var dados := golpes - restantes
		if estado == Estado.INTEIRO and dados > 0 and not regioes_por_golpe.is_empty():
			_mostrar(regioes_por_golpe[mini(dados, regioes_por_golpe.size()) - 1])
		return
	estado = novo
	if chamas:
		chamas.visible = estado == Estado.QUEIMANDO
	match estado:
		Estado.QUEIMANDO:
			Sfx.tocar(&"fogo")
		Estado.QUEIMADO:
			set_process(false)
			sprite.self_modulate = cor_queimado
			_mostrar(regiao_queimado)
		Estado.ESGOTADO:
			destacar(false)
			# O toco não recebe mais acertos (a caixa da árvore inteira ficava invisível no ar).
			hurtbox.set_deferred(&"monitorable", false)
			if some_ao_esgotar:
				if multiplayer.is_server():
					get_tree().call_group(&"mundo", &"registrar_removido", name)
				queue_free()
			else:
				set_process(false)
				sprite.self_modulate = Color.WHITE
				if textura_esgotado:
					sprite.texture = textura_esgotado
				_mostrar(regiao_esgotado)


func _on_atingido(_quantidade: float, tipo: StringName, _origem: Node) -> void:
	if multiplayer.is_server() and tipo == &"fogo" and incendiar():
		World.avisar_todos(self, "Uma árvore pegou fogo! Queimada, ela vira carvão. O fogo passa para as vizinhas devagar.")


## Só o anfitrião chama. Retorna se pegou fogo agora.
func incendiar() -> bool:
	if estado != Estado.INTEIRO or inflamavel == null or not inflamavel.acender():
		return false
	_definir_estado.rpc(Estado.QUEIMANDO, _golpes_restantes, false)
	get_tree().create_timer(espalhar_apos, false, true).timeout.connect(_espalhar_fogo)
	return true


## O fogo passa para as árvores vizinhas (uma vez, depois de `espalhar_apos`).
func _espalhar_fogo() -> void:
	if not is_inside_tree() or estado == Estado.ESGOTADO:
		return
	for r in get_tree().get_nodes_in_group(&"recursos"):
		if r != self and r.global_position.distance_to(global_position) <= raio_do_fogo:
			(r as ResourceNode).incendiar()


func _on_queimou() -> void:
	if multiplayer.is_server():
		_definir_estado.rpc(Estado.QUEIMADO, _golpes_restantes, false)


## Experiência por terminar uma coleta.
const XP_COLETA := 2


func _entregar(quem: Player, item: StringName, qtd: int) -> void:
	quem.inventario.adicionar(item, qtd)
	quem.ganhar_xp(XP_COLETA)
	quem.avisar("+%d %s" % [qtd, ItemData.carregar(item).nome.to_lower()], &"item")


func _mostrar(regiao: Rect2) -> void:
	sprite.region_enabled = true
	sprite.region_rect = regiao
	sprite.centered = false
	sprite.offset = Vector2(-regiao.size.x / 2.0, -regiao.size.y + pe)
	_altura_visivel = (_medir_altura(sprite.texture, regiao) - pe) * escala


var _textura_inteiro: Texture2D
var _tempo_animacao := 0.0


## Árvore balançando: troca o quadro da tira enquanto está inteira (e sem marca de golpe).
func _process(delta: float) -> void:
	if estado != Estado.INTEIRO or sprite.texture != _textura_inteiro or sprite.region_rect.size != regiao_inteiro.size:
		return
	_tempo_animacao += delta
	var q := int(_tempo_animacao * 8.0) % quadros
	sprite.region_rect.position = regiao_inteiro.position + Vector2(q * regiao_inteiro.size.x, 0)


## Altura do desenho que aparece agora (do chão até o topo), para a teclinha E ficar
## logo acima de cada objeto: mais alta na árvore, mais baixa na pedra e no toco.
func altura_visivel() -> float:
	return _altura_visivel


var _altura_visivel := 0.0
static var _alturas: Dictionary = {}


static func _medir_altura(tex: Texture2D, regiao: Rect2) -> float:
	var chave := "%s|%s" % [tex.resource_path, regiao]
	if not _alturas.has(chave):
		var usado := tex.get_image().get_region(Rect2i(regiao)).get_used_rect()
		_alturas[chave] = regiao.size.y - usado.position.y
	return _alturas[chave]


func _tremer() -> void:
	var t := create_tween()
	t.tween_property(sprite, "position:x", 1.5, 0.04)
	t.tween_property(sprite, "position:x", -1.5, 0.06)
	t.tween_property(sprite, "position:x", 0.0, 0.04)


## Só o anfitrião chama, ao carregar o mundo salvo (antes de alguém entrar).
func carregar_estado(novo: int, restantes: int) -> void:
	_definir_estado(novo as Estado, restantes, false)
