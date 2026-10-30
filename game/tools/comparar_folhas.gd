extends SceneTree
## Validação obrigatória antes de pôr arte nova no jogo: monta uma imagem com as peças do
## PACOTE (Tiny Swords) numa linha e as NOSSAS na outra, no tamanho em que aparecem no
## jogo, sobre a grama do pacote, ampliadas igual (vizinho mais próximo). Assim dá para ver
## se o tamanho do pixel, o contorno, as cores e o tamanho dos objetos batem.
##
## Lê um arquivo de lista (--lista=caminho), uma peça por linha:
##   pacote | res://assets/tiny_swords/natureza/arvore1.png | 0 0 192 256 | 0.25
##   nosso  | res://assets/sprites/tiny/acampamento.png      | 0 0 96 96   | 0.5
## (grupo | arquivo | região x y largura altura | escala no jogo). Linhas com # são ignoradas.
##
## Uso (da raiz):
##   godot --headless --path game --script res://tools/comparar_folhas.gd -- \
##     --lista=../art/prompts/comparacoes/acampamento.txt --saida=../evidence/comparacao/acampamento.png [--zoom=4]

const GRAMA := "res://assets/tiny_swords/terreno/grama.png"

var _args := {}


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			_args[a.substr(2).get_slice("=", 0)] = a.get_slice("=", 1)
	var zoom := int(_args.get("zoom", "4"))
	var linhas := {"pacote": [], "nosso": []}
	for linha in FileAccess.get_file_as_string(_caminho(_args["lista"])).split("\n"):
		linha = linha.strip_edges()
		if linha.is_empty() or linha.begins_with("#"):
			continue
		var partes := linha.split("|")
		var grupo := partes[0].strip_edges()
		var img := Image.load_from_file(_caminho(partes[1].strip_edges()))
		img.convert(Image.FORMAT_RGBA8)
		var r := partes[2].strip_edges().split(" ", false)
		var peca := img.get_region(Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])))
		var usado := peca.get_used_rect()
		peca = peca.get_region(usado)
		# Tamanho na tela do jogo: escala no mundo x zoom da câmera.
		var fator := float(partes[3]) * zoom
		peca.resize(maxi(1, roundi(peca.get_width() * fator)), maxi(1, roundi(peca.get_height() * fator)), Image.INTERPOLATE_NEAREST)
		linhas[grupo].append(peca)

	var margem := 24
	var alturas := {}
	var largura := margem
	for g in linhas:
		var w := margem
		var h := 0
		for p: Image in linhas[g]:
			w += p.get_width() + margem
			h = maxi(h, p.get_height())
		alturas[g] = h
		largura = maxi(largura, w)
	var altura: int = margem * 3 + alturas["pacote"] + alturas["nosso"]
	var out := Image.create(largura, altura, false, Image.FORMAT_RGBA8)
	# Fundo: o miolo da grama do pacote, repetido, no mesmo zoom.
	var grama := Image.load_from_file(_caminho(GRAMA))
	grama.convert(Image.FORMAT_RGBA8)
	var bloco := grama.get_region(Rect2i(64, 64, 64, 64))
	bloco.resize(64 * zoom / 4, 64 * zoom / 4, Image.INTERPOLATE_NEAREST)
	for y in range(0, altura, bloco.get_height()):
		for x in range(0, largura, bloco.get_width()):
			out.blit_rect(bloco, Rect2i(Vector2i.ZERO, bloco.get_size()), Vector2i(x, y))
	var topo := margem
	for g in ["pacote", "nosso"]:
		var x := margem
		for p: Image in linhas[g]:
			out.blend_rect(p, Rect2i(Vector2i.ZERO, p.get_size()), Vector2i(x, topo + alturas[g] - p.get_height()))
			x += p.get_width() + margem
		topo += alturas[g] + margem
	var destino := _caminho(_args["saida"])
	DirAccess.make_dir_recursive_absolute(destino.get_base_dir())
	print("Salvo: ", destino, " (", error_string(out.save_png(destino)), ") · em cima o pacote, embaixo o nosso")
	quit()


func _caminho(p: String) -> String:
	if p.begins_with("res://"):
		return ProjectSettings.globalize_path(p)
	if p.is_absolute_path():
		return p
	return ProjectSettings.globalize_path("res://").path_join(p).simplify_path()
