extends SceneTree
## Fogueira animada (L37): tira as chamas desenhadas da fogueira do acampamento (quadro 0 de
## acampamento.png, arte do L12) e salva só as pedras e a lenha em fogueira_base.png. As chamas
## animadas (Pixelbolt) vão por cima, no jogo. Apaga só os pixels com as cores das chamas
## (vermelho, laranja, amarelo e creme) acima da linha da lenha.
## Uso (da raiz): godot --headless --path game --script res://tools/separar_fogueira.gd

const ENTRADA := "res://assets/sprites/tiny/acampamento.png"
const SAIDA := "res://assets/sprites/tiny/fogueira_base.png"
const CORES_CHAMA := ["f6703e", "ffdc00", "f9f4a9", "e9f044", "ffff93", "cc5050", "e5c258"]
const LINHA_LENHA := 100  # abaixo disso não há chama (só lenha, brasas e pedras)
const TOPO_PEDRAS := 89  # o alto das pedras de trás


func _init() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(ENTRADA))
	img.convert(Image.FORMAT_RGBA8)
	var base := img.get_region(Rect2i(0, 0, 128, 128))
	var apagados := 0
	for y in LINHA_LENHA:
		for x in 128:
			var c := base.get_pixel(x, y)
			if c.a > 0 and c.to_html(false) in CORES_CHAMA:
				base.set_pixel(x, y, Color(0, 0, 0, 0))
				apagados += 1
	# Acima das pedras de trás (y < 89) só havia chama, com o contorno e os tons escuros dela.
	for y in TOPO_PEDRAS:
		for x in range(40, 89):
			if base.get_pixel(x, y).a > 0:
				base.set_pixel(x, y, Color(0, 0, 0, 0))
				apagados += 1
	# Pontinhos que sobraram soltos (sem vizinho de lado nem em cima/embaixo).
	var copia := base.duplicate() as Image
	for y in range(1, LINHA_LENHA):
		for x in range(1, 127):
			if copia.get_pixel(x, y).a == 0:
				continue
			var vizinhos := 0
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if copia.get_pixelv(Vector2i(x, y) + d).a > 0:
					vizinhos += 1
			if vizinhos == 0:
				base.set_pixel(x, y, Color(0, 0, 0, 0))
				apagados += 1
	print("pixels de chama apagados: ", apagados)
	base.save_png(ProjectSettings.globalize_path(SAIDA))
	quit()
