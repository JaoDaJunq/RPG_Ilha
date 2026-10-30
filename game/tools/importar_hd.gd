extends SceneTree
## Converte uma folha em DESENHO DE ALTA RESOLUÇÃO (não pixel art) gerada pelo Codex:
## grade de células com fundo magenta. Para cada célula:
##   1. tira o magenta com borda suave (a IA mistura o contorno com o fundo) e remove o
##      tom rosado que sobra nessa borda;
##   2. recorta o desenho com uma folga pequena;
##   3. reduz pela --escala com filtro de qualidade (reduzir desenho não perde nada).
## Salva um PNG por célula na pasta de --saida, com os nomes de --nomes.
##
## Uso (da raiz):
##   godot --headless --path game --script res://tools/importar_hd.gd -- \
##     --entrada=../art/sprites/desenho_hd/candidatos/hd_v1.png --saida=../art/sprites/desenho_hd/convertido \
##     --nomes=mago,ogro,arvore,arvore_rosa,pedra,arbusto [--escala=0.5] [--celula=512x512]

const MAGENTA := Color(1, 0, 1)

var _args := {}


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			_args[a.substr(2).get_slice("=", 0)] = a.get_slice("=", 1)
	var folha := Image.load_from_file(_caminho(_args.get("entrada", "")))
	if folha == null or folha.is_empty():
		push_error("Não abriu a folha")
		quit(1)
		return
	folha.convert(Image.FORMAT_RGBA8)
	var pasta := _caminho(_args.get("saida", ""))
	DirAccess.make_dir_recursive_absolute(pasta)
	var nomes: PackedStringArray = String(_args.get("nomes", "")).split(",", false)
	var escala := float(_args.get("escala", "0.5"))
	var cel := Vector2i(512, 512)
	if _args.has("celula"):
		cel = Vector2i(String(_args["celula"]).get_slice("x", 0).to_int(), String(_args["celula"]).get_slice("x", 1).to_int())
	var colunas := folha.get_width() / cel.x
	for i in nomes.size():
		var parte := folha.get_region(Rect2i((i % colunas) * cel.x, (i / colunas) * cel.y, cel.x, cel.y))
		_tirar_magenta(parte)
		var caixa := parte.get_used_rect().grow(4).intersection(Rect2i(Vector2i.ZERO, parte.get_size()))
		parte = parte.get_region(caixa)
		var tam := Vector2i(roundi(parte.get_width() * escala), roundi(parte.get_height() * escala))
		parte.resize(tam.x, tam.y, Image.INTERPOLATE_LANCZOS)
		var destino := pasta.path_join(nomes[i] + ".png")
		parte.save_png(destino)
		print("%s: %dx%d" % [nomes[i], tam.x, tam.y])
	quit()


## Quanto "magenta" o pixel é: 1 no fundo puro, ~0 nas cores do desenho (inclusive rosa e
## roxo, que têm verde ou não têm vermelho e azul altos juntos).
func _tirar_magenta(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var m := minf(c.r, c.b) - c.g
			var a := 1.0 - smoothstep(0.3, 0.8, m)
			if a <= 0.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif a < 1.0:
				# A cor da borda é desenho + fundo misturados: tira a parte do fundo.
				var limpa := Color((c.r - (1.0 - a) * MAGENTA.r) / a, (c.g - (1.0 - a) * MAGENTA.g) / a, (c.b - (1.0 - a) * MAGENTA.b) / a)
				img.set_pixel(x, y, Color(clampf(limpa.r, 0, 1), clampf(limpa.g, 0, 1), clampf(limpa.b, 0, 1), a))


func _caminho(p: String) -> String:
	if p.begins_with("res://"):
		return ProjectSettings.globalize_path(p)
	if p.is_absolute_path():
		return p
	return ProjectSettings.globalize_path("res://").path_join(p).simplify_path()
