extends SceneTree
## Converte uma animação exportada pelo Pixelbolt (folha + atlas .json) numa tira
## horizontal de quadros, o formato que o jogo usa (SpriteSheets.adicionar_tira).
## Imprime o tamanho do quadro, quantos quadros e o fps médio (do tempo de cada quadro).
##
## Uso (da raiz):
##   godot --headless --path game --script res://tools/importar_pixelbolt.gd -- \
##     --pasta=C:/Projetos/ferramentas/saidas/gelo --animacao=impact \
##     --saida=res://assets/sprites/tiny/fx/gelo_impacto.png

var _args := {}


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			_args[a.substr(2).get_slice("=", 0)] = a.get_slice("=", 1)
	var pasta: String = _args["pasta"]
	var nome := pasta.get_file()
	var atlas: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(pasta.path_join(nome + ".atlas.json")))
	var folha := Image.load_from_file(pasta.path_join(nome + ".png"))
	folha.convert(Image.FORMAT_RGBA8)
	var animacao: String = _args["animacao"]
	var quadros: Array = []
	var i := 0
	while atlas["frames"].has("%s-%d" % [animacao, i]):
		quadros.append(atlas["frames"]["%s-%d" % [animacao, i]])
		i += 1
	if quadros.is_empty():
		push_error("Animação não encontrada: " + animacao)
		quit(1)
		return
	var w: int = quadros[0]["sourceSize"]["w"]
	var h: int = quadros[0]["sourceSize"]["h"]
	var tira := Image.create(w * quadros.size(), h, false, Image.FORMAT_RGBA8)
	var total_ms := 0.0
	for k in quadros.size():
		var q: Dictionary = quadros[k]
		var r := Rect2i(q["frame"]["x"], q["frame"]["y"], q["frame"]["w"], q["frame"]["h"])
		var dest := Vector2i(k * w + int(q["spriteSourceSize"]["x"]), int(q["spriteSourceSize"]["y"]))
		tira.blit_rect(folha, r, dest)
		total_ms += float(q["duration"])
	var saida: String = _args["saida"]
	if saida.begins_with("res://"):
		saida = ProjectSettings.globalize_path(saida)
	DirAccess.make_dir_recursive_absolute(saida.get_base_dir())
	tira.save_png(saida)
	print("%s: %d quadros de %dx%d, %.1f fps → %s" % [animacao, quadros.size(), w, h, 1000.0 * quadros.size() / total_ms, saida])
	quit()
