extends SceneTree
## Monta uma "folha-régua" para anexar nos pedidos ao Codex: peças prontas do pacote
## (Tiny Swords) ampliadas EXATAMENTE N vezes, na MESMA grade que pedimos de volta
## (3 colunas x 2 linhas de 512 px, fundo magenta, base a 16 px do fundo da célula).
## Assim a IA vê na prática o tamanho do pixel, o contorno e as cores que tem de copiar.
##
## Lista (--lista=caminho), uma peça por linha:  arquivo | x y largura altura
## Uso (da raiz):
##   godot --headless --path game --script res://tools/montar_regua.gd -- \
##     --lista=../art/prompts/reguas/objetos.txt --saida=../art/prompts/reguas/objetos_4x.png [--vezes=4]

const CELULA := 512
const MAGENTA := Color(1, 0, 1)

var _args := {}


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			_args[a.substr(2).get_slice("=", 0)] = a.get_slice("=", 1)
	var vezes := int(_args.get("vezes", "4"))
	var out := Image.create(CELULA * 3, CELULA * 2, false, Image.FORMAT_RGBA8)
	out.fill(MAGENTA)
	var i := 0
	for linha in FileAccess.get_file_as_string(_caminho(_args["lista"])).split("\n"):
		linha = linha.strip_edges()
		if linha.is_empty() or linha.begins_with("#"):
			continue
		var partes := linha.split("|")
		var img := Image.load_from_file(_caminho(partes[0].strip_edges()))
		img.convert(Image.FORMAT_RGBA8)
		var r := partes[1].strip_edges().split(" ", false)
		var peca := img.get_region(Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])))
		peca = peca.get_region(peca.get_used_rect())
		peca.resize(peca.get_width() * vezes, peca.get_height() * vezes, Image.INTERPOLATE_NEAREST)
		# A sombra do pacote é semitransparente: sobre o magenta ela vira a mistura das duas.
		var celula := Vector2i((i % 3) * CELULA, (i / 3) * CELULA)
		var destino := celula + Vector2i((CELULA - peca.get_width()) / 2, CELULA - 16 - peca.get_height())
		out.blend_rect(peca, Rect2i(Vector2i.ZERO, peca.get_size()), destino)
		i += 1
	var saida := _caminho(_args["saida"])
	DirAccess.make_dir_recursive_absolute(saida.get_base_dir())
	print("Salvo: ", saida, " (", error_string(out.save_png(saida)), ")")
	quit()


func _caminho(p: String) -> String:
	if p.begins_with("res://"):
		return ProjectSettings.globalize_path(p)
	if p.is_absolute_path():
		return p
	return ProjectSettings.globalize_path("res://").path_join(p).simplify_path()
