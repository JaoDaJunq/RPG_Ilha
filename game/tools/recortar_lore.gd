extends SceneTree
## Recorta as 5 lajes de lore da folha L42 (ilustração lisa, fundo magenta, 3x2 células de
## 512 px) em lore_1.png .. lore_5.png: tira o magenta e recorta cada laje. Não pixeliza:
## o painel de lore mostra a ilustração inteira, suavizada.
## Uso: godot --headless --path game --script res://tools/recortar_lore.gd -- \
##   --entrada=../art/sprites/tiny/candidatos/l42_06_lore.png --saida=res://assets/sprites/tiny/

const CELULA := 512
const LARGURA := 360


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			args[a.substr(2).get_slice("=", 0)] = a.get_slice("=", 1)
	var entrada: String = args["entrada"]
	if not entrada.is_absolute_path():
		entrada = ProjectSettings.globalize_path("res://").path_join(entrada)
	var folha := Image.load_from_file(entrada)
	folha.convert(Image.FORMAT_RGBA8)
	for i in 5:
		var parte := folha.get_region(Rect2i((i % 3) * CELULA, (i / 3) * CELULA, CELULA, CELULA))
		for y in parte.get_height():
			for x in parte.get_width():
				var c := parte.get_pixel(x, y)
				if c.r > 0.75 and c.b > 0.75 and c.g < 0.45:
					parte.set_pixel(x, y, Color(0, 0, 0, 0))
		parte = parte.get_region(parte.get_used_rect())
		parte.resize(LARGURA, roundi(parte.get_height() * LARGURA / float(parte.get_width())), Image.INTERPOLATE_LANCZOS)
		var destino := ProjectSettings.globalize_path(String(args["saida"]).path_join("lore_%d.png" % (i + 1)))
		print("lore_%d: %dx%d %s" % [i + 1, parte.get_width(), parte.get_height(), error_string(parte.save_png(destino))])
	quit()
