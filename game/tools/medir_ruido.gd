extends SceneTree
## Mede o "ruído" de sprites: quantas cores diferentes e quantos pixels são diferentes
## de TODOS os 4 vizinhos (pixel solto), por quadro. Pixel art limpa tem poucas cores e
## quase nenhum pixel solto; arte gerada por IA e reduzida costuma ter muitos.
## Uso: godot --headless --path game --script res://tools/medir_ruido.gd -- arquivo:quadroLargura ...

func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		var partes := arg.rsplit(":", true, 1)  # o caminho pode ter ":" (res://, C:)
		var caminho := partes[0]
		var largura := int(partes[1])
		var img := Image.load_from_file(ProjectSettings.globalize_path(caminho) if caminho.begins_with("res://") else caminho)
		img.convert(Image.FORMAT_RGBA8)
		var q := maxi(1, img.get_width() / largura) if largura > 0 else 1
		var w := img.get_width() / q
		var cores_tot := 0.0
		var soltos_tot := 0.0
		for i in q:
			var cores := {}
			var opacos := 0
			var soltos := 0
			for y in img.get_height():
				for x in range(i * w, (i + 1) * w):
					var c := img.get_pixel(x, y)
					if c.a < 0.5:
						continue
					opacos += 1
					cores[c.to_rgba32()] = true
					var igual := false
					for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						var nx: int = x + d.x
						var ny: int = y + d.y
						if nx >= i * w and nx < (i + 1) * w and ny >= 0 and ny < img.get_height():
							if img.get_pixel(nx, ny).to_rgba32() == c.to_rgba32():
								igual = true
					if not igual:
						soltos += 1
			cores_tot += cores.size()
			soltos_tot += 100.0 * soltos / maxi(opacos, 1)
		print("%-48s cores/quadro %5.1f   pixels soltos %4.1f%%" % [caminho.get_file(), cores_tot / q, soltos_tot / q])
	quit()
