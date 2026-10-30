extends TesteBase
## Tira o fundo da tela inicial a partir do próprio jogo (arte do Tiny Swords e as nossas
## no estilo dele): a beira da ilha com a praia e o mar, sem interface e sem jogador.
## Uso (da raiz):  <godot> --path game --resolution 1280x720 res://tests/fundo_menu.tscn
## Salva game/assets/sprites/interface/menu_fundo.png (substitui o conceito antigo).


func _ready() -> void:
	var w := await criar_mundo(5, false)
	w.jogador.visible = false
	w.hud.visible = false
	var cam := Camera2D.new()
	cam.zoom = Vector2(3, 3)
	w.add_child(cam)
	cam.make_current()
	# A primeira grama vindo da esquerda, na linha do meio: praia, mar e o bosque.
	var x := 0
	while w.tipo_do_chao(Vector2i(x, w.altura / 2)) != World.Chao.GRAMA:
		x += 1
	cam.position = Vector2(x * World.T + 120, w.centro.y - 20)
	await esperar(0.6)
	await RenderingServer.frame_post_draw
	var destino := ProjectSettings.globalize_path("res://assets/sprites/interface/menu_fundo.png")
	checar(get_viewport().get_texture().get_image().save_png(destino) == OK, "fundo do menu salvo")
	terminar()
