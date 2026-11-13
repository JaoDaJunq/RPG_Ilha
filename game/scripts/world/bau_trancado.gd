class_name BauTrancado
extends StaticBody2D
## Baú trancado espalhado pela ilha (longe do acampamento), com coisas boas dentro.
##   - O Ladino com Dedos leves abre na hora (segurar E).
##   - Quem tem uma CHAVE (o arqueiro inimigo às vezes solta) abre na hora e gasta a chave.
##   - Os outros quebram a tranca com golpes físicos (GOLPES_QUEBRAR).
## Aberto ou quebrado, o saque cai no chão, o baú fica aberto um instante (ABERTO_SEGUNDOS) e
## some (fica registrado como removido, igual às árvores derrubadas: não volta ao carregar o
## mundo nem aparece para quem entra depois).
## Todos criam o baú igual (World._espalhar_baus, mesma semente e mesmo nome); só o
## anfitrião decide abrir.
##
## Arte (pedido L35): o baú do acampamento com corrente e cadeado (quadro 0) e o mesmo aberto,
## com a corrente partida (quadro 1).

const ARTE := preload("res://assets/sprites/tiny/bau_trancado.png")
const QUADRO_TRANCADO := 0
const QUADRO_ABERTO := 1
const GOLPES_QUEBRAR := 6
## A chave que abre (some ao abrir) e a chance de o arqueiro inimigo soltar uma.
const CHAVE := &"chave"
const CHANCE_CHAVE := 0.3
## Segundos que o baú fica aberto antes de sumir.
const ABERTO_SEGUNDOS := 1.5
## Saque: [item, mínimo, máximo].
const SAQUE := [[&"gosma_curativa", 1, 2], [&"carvao", 2, 4], [&"tabua", 2, 5], [&"carne_assada", 1, 2]]

var _golpes := GOLPES_QUEBRAR
var _sprite: Sprite2D
var _aberto := false


func _ready() -> void:
	add_to_group(&"baus_trancados")
	_sprite = Sprite2D.new()
	_sprite.texture = ARTE
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(QUADRO_TRANCADO * 128, 0, 128, 128)
	_sprite.centered = false
	_sprite.offset = Vector2(-64, -128 + 8)
	_sprite.scale = Vector2(0.25, 0.25)
	add_child(_sprite)
	var corpo := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(13, 6)
	corpo.shape = r
	corpo.position = Vector2(0, -3)
	add_child(corpo)
	collision_layer = 1
	# Recebe golpes (quebrar a tranca).
	var h := Hurtbox.new()
	h.name = "Hurtbox"
	var forma := CollisionShape2D.new()
	var r2 := RectangleShape2D.new()
	r2.size = Vector2(16, 14)
	forma.shape = r2
	forma.position = Vector2(0, -7)
	h.add_child(forma)
	add_child(h)
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		h.atingido.connect(_on_atingido)
	# Segurar E abre (Interactable).
	var area := Area2D.new()
	area.name = "Interactable"
	area.set_script(preload("res://scripts/components/interactable.gd"))
	area.set(&"alcance", 34.0)
	area.set(&"tempo_segurar", 0.4)
	var f2 := CollisionShape2D.new()
	var r3 := RectangleShape2D.new()
	r3.size = Vector2(26, 18)
	f2.shape = r3
	f2.position = Vector2(0, -10)
	area.add_child(f2)
	add_child(area)


func golpes_restantes() -> int:
	return _golpes


# --- Interactable ------------------------------------------------------------------------

func pode_interagir() -> bool:
	return not _aberto


func texto_acao() -> String:
	return "Abrir baú trancado"


func destacar(ligado: bool) -> void:
	if _sprite:
		_sprite.modulate = Color(1.2, 1.2, 1.15) if ligado else Color.WHITE


func altura_visivel() -> float:
	return 20.0


## Anfitrião: o Ladino com Dedos leves abre; quem tem chave abre e gasta a chave; os outros
## recebem a dica.
func interagir(quem: Player) -> void:
	if _aberto:
		return
	if quem.tem(&"dedos_leves"):
		quem.avisar("Dedos leves: você abriu a tranca!", &"item")
		abrir()
	elif quem.inventario.quantidade_de(CHAVE) > 0:
		quem.inventario.remover(CHAVE, 1)
		quem.avisar("A chave abriu o baú (e ficou presa no cadeado).", &"item")
		abrir()
	else:
		quem.avisar("Baú trancado. Abra com uma chave (os arqueiros inimigos às vezes têm), com Dedos leves do Ladino, ou quebre a tranca com golpes (faltam %d)." % _golpes)


## Só o anfitrião: cada golpe físico de um jogador estraga a tranca um pouco.
func _on_atingido(_quantidade: float, tipo: StringName, origem: Node) -> void:
	if _aberto or tipo != &"fisico" or not origem is Player:
		return
	_golpes -= 1
	_tremer.rpc()
	if _golpes <= 0:
		(origem as Player).avisar("A tranca quebrou!", &"item")
		abrir()


## Anfitrião: solta o saque e tira o baú de todos.
func abrir() -> void:
	if _aberto or not multiplayer.is_server():
		return
	_aberto = true
	var itens := []
	for s in SAQUE:
		var n := randi_range(int(s[1]), int(s[2]))
		if n > 0:
			itens.append([s[0], n])
	World.soltar_itens(self, global_position + Vector2(0, -4), itens)
	World.efeito_todos(self, &"poeira", global_position)
	get_tree().call_group(&"mundo", &"registrar_removido", String(name))
	_mostrar_aberto.rpc()


@rpc("authority", "call_local", "reliable")
func _tremer() -> void:
	Sfx.tocar(&"golpe_coleta")
	var t := create_tween()
	t.tween_property(_sprite, "position:x", 1.5, 0.04)
	t.tween_property(_sprite, "position:x", -1.5, 0.06)
	t.tween_property(_sprite, "position:x", 0.0, 0.04)


## Todos: o baú aparece aberto, não aceita mais nada e some aos poucos.
@rpc("authority", "call_local", "reliable")
func _mostrar_aberto() -> void:
	_aberto = true
	remove_from_group(&"baus_trancados")
	Sfx.tocar(&"item")
	_sprite.region_rect = Rect2(QUADRO_ABERTO * 128, 0, 128, 128)
	_sprite.modulate = Color.WHITE
	for c in get_children():
		if c is CollisionShape2D or c is Area2D:
			c.queue_free()
	var t := create_tween()
	t.tween_interval(ABERTO_SEGUNDOS)
	t.tween_property(_sprite, "modulate:a", 0.0, 0.4)
	t.tween_callback(queue_free)
