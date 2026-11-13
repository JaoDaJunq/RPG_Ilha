extends SceneTree
## Fogueira nova (L41): termina a tira convertida da folha do Codex (importar_folha.gd --fixo
## ou pixelizar.gd --animacao), que é UM desenho inteiro por quadro (pedras, lenha e chamas).
##   1. mede quanto as pedras e a lenha "tremem" de um quadro para o outro (a IA redesenha
##      cada quadro) e, se tremerem, copia as pedras e a lenha do 1º quadro para os outros:
##      só os pixels que NÃO são de fogo, abaixo da linha da lenha;
##   2. põe a sombra do pacote embaixo (SombraTiny), igual em todos os quadros.
## Uso (da raiz):
##   godot --headless --path game --script res://tools/montar_fogueira.gd -- \
##     --entrada=../art/sprites/tiny/candidatos/l41_fogueira_pixel_tira.png \
##     --saida=res://assets/sprites/tiny/fogueira.png [--quadro=128] [--lenha=96]

var _args := {}


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			_args[a.substr(2).get_slice("=", 0)] = a.get_slice("=", 1)
	var tira := Image.load_from_file(_caminho(_args["entrada"]))
	tira.convert(Image.FORMAT_RGBA8)
	var q := int(_args.get("quadro", "128"))
	var n := tira.get_width() / q
	# Linha da lenha: abaixo dela, só pedras, lenha e brasas (o fogo sobe dela para cima).
	var lenha := int(_args.get("lenha", "96"))
	# Tira a sombra que a conversão tenha posto (é refeita igual em todos os quadros).
	for y in tira.get_height():
		for x in tira.get_width():
			var c := tira.get_pixel(x, y)
			if c.a > 0.0 and c.a < 0.5:
				tira.set_pixel(x, y, Color(0, 0, 0, 0))
	var tremidos := 0
	for k in range(1, n):
		for y in range(lenha, q):
			for x in q:
				var a := tira.get_pixel(x, y)
				var b := tira.get_pixel(k * q + x, y)
				if not _fogo(a) and not _fogo(b) and a != b:
					tremidos += 1
	print("pixels de pedra/lenha diferentes do 1º quadro (somando os quadros): %d" % tremidos)
	if tremidos > 0 and not _args.has("sem_firmar"):
		for k in range(1, n):
			for y in range(lenha, q):
				for x in q:
					var a := tira.get_pixel(x, y)
					var b := tira.get_pixel(k * q + x, y)
					if not _fogo(a) and not _fogo(b):
						tira.set_pixel(k * q + x, y, a)
					elif not _fogo(a) and b.a == 0.0:
						tira.set_pixel(k * q + x, y, a)
	# A sombra do pacote: a mesma caixa (a das pedras do 1º quadro) em todos os quadros.
	var caixa := tira.get_region(Rect2i(0, lenha, q, q - lenha)).get_used_rect()
	caixa.position.y += lenha
	for k in n:
		SombraTiny.por(tira, Rect2i(caixa.position + Vector2i(k * q, 0), caixa.size))
	var destino := _caminho(_args["saida"])
	DirAccess.make_dir_recursive_absolute(destino.get_base_dir())
	print("%d quadros de %d px; salvo: %s (%s)" % [n, q, destino, error_string(tira.save_png(destino))])
	quit()


## Cor de fogo (vermelho, laranja, amarelo, creme): muito mais vermelho que azul.
static func _fogo(c: Color) -> bool:
	return c.a > 0.5 and c.r > 0.7 and c.r - c.b > 0.35 and c.g > 0.25


func _caminho(p: String) -> String:
	if p.begins_with("res://"):
		return ProjectSettings.globalize_path(p)
	if p.is_absolute_path():
		return p
	return ProjectSettings.globalize_path("res://").path_join(p).simplify_path()
