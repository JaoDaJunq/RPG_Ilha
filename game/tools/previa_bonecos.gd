extends SceneTree
## Conferência dos personagens por peças: para cada um, o boneco MONTADO pelas peças e pelo
## pecas.json (como o jogo monta) ao lado do personagem inteiro desenhado pela IA. Se as peças
## estiverem no tamanho e no lugar certos, os dois ficam iguais.
## Uso (da raiz):  godot --headless --path game --script res://tools/previa_bonecos.gd -- --saida=../evidence/comparacao/bonecos.png

const PASTA := "res://assets/sprites/tiny/bonecos/"
const NOMES := ["humano_guerreiro", "humano_mago", "humano_arqueiro", "ogro_guerreiro", "ogro_mago", "ogro_arqueiro"]
const ZOOM := 4


func _init() -> void:
	var saida := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--saida="):
			saida = a.get_slice("=", 1)
	var celula := Vector2i(220, 110)
	var out := Image.create(celula.x * 3 * ZOOM, celula.y * 2 * ZOOM, false, Image.FORMAT_RGBA8)
	out.fill(Color("8aa64a"))
	for i in NOMES.size():
		var p := ProjectSettings.globalize_path(PASTA + NOMES[i] + "/")
		var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(p + "pecas.json"))
		var img := Image.create(celula.x, celula.y, false, Image.FORMAT_RGBA8)
		var pe := Vector2i(55, 100)  # onde ficam os pés do boneco montado
		for parte in [["mao", "mao_tras"], ["pe", "pe_tras"], ["tronco", "tronco"], ["cabeca", "cabeca"], ["pe", "pe_frente"], ["mao", "mao_frente"]]:
			var peca := Image.load_from_file(p + parte[0] + ".png")
			var pos: Array = j[parte[1]]
			img.blend_rect(peca, Rect2i(Vector2i.ZERO, peca.get_size()), pe + Vector2i(int(pos[0]), int(pos[1])))
		var inteiro := Image.load_from_file(p + "inteiro.png")
		img.blend_rect(inteiro, Rect2i(Vector2i.ZERO, inteiro.get_size()), Vector2i(130 - inteiro.get_width() / 2 + 40, pe.y + 6 - inteiro.get_height()))
		img.resize(celula.x * ZOOM, celula.y * ZOOM, Image.INTERPOLATE_NEAREST)
		out.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i((i % 3) * celula.x * ZOOM, (i / 3) * celula.y * ZOOM))
	var destino := ProjectSettings.globalize_path("res://").path_join(saida).simplify_path()
	out.save_png(destino)
	print("Salvo: ", destino)
	quit()
