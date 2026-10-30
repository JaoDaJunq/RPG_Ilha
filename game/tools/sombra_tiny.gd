class_name SombraTiny
extends RefCounted
## A sombra no chão do Tiny Swords, para pôr embaixo das nossas peças na conversão. A IA
## não consegue fazer transparência sobre o magenta, então a sombra vem do próprio pacote:
## a elipse (#161c2e a 27%) que fica embaixo do trabalhador, preenchida linha a linha onde
## os pés a cobrem, e esticada (vizinho mais próximo) para ~85% da largura da base do desenho.

const COR := Color("161c2e45")  # #161c2e com 27% (alfa 0x45)
const MOLDE := "res://assets/tiny_swords/unidades/azul/trabalhador_parado.png"

static var _sombra: Image


## `caixa`: onde está o desenho dentro de `tira`. Só pinta onde a tira está transparente.
static func por(tira: Image, caixa: Rect2i) -> void:
	if _sombra == null:
		_sombra = _molde()
	# Largura da base: a linha mais larga entre as 4 de baixo do desenho.
	var base_l := 0
	for y in range(caixa.end.y - 4, caixa.end.y):
		var e := caixa.end.x
		var d := caixa.position.x
		for x in range(caixa.position.x, caixa.end.x):
			if tira.get_pixel(x, y).a > 0.0:
				e = mini(e, x)
				d = maxi(d, x)
		base_l = maxi(base_l, d - e + 1)
	var largura := maxi(8, roundi(maxf(base_l, caixa.size.x * 0.6) * 0.85))
	var s := _sombra.duplicate() as Image
	s.resize(largura, maxi(3, roundi(largura * _sombra.get_height() / float(_sombra.get_width()))), Image.INTERPOLATE_NEAREST)
	var origem := Vector2i(caixa.position.x + (caixa.size.x - largura) / 2, caixa.end.y - s.get_height() / 2 - 1)
	for y in s.get_height():
		for x in s.get_width():
			var p := origem + Vector2i(x, y)
			if s.get_pixel(x, y).a > 0.0 and p.x >= 0 and p.y >= 0 and p.x < tira.get_width() and p.y < tira.get_height() and tira.get_pixelv(p).a == 0.0:
				tira.set_pixelv(p, COR)


static func _molde() -> Image:
	var u := Image.load_from_file(ProjectSettings.globalize_path(MOLDE))
	u.convert(Image.FORMAT_RGBA8)
	var q := u.get_region(Rect2i(0, 0, 192, 192))
	var linhas := {}
	for y in q.get_height():
		for x in q.get_width():
			var a := q.get_pixel(x, y).a
			if a > 0.15 and a < 0.4:
				var l: Vector2i = linhas.get(y, Vector2i(x, x))
				linhas[y] = Vector2i(mini(l.x, x), maxi(l.y, x))
	var ys: Array = linhas.keys()
	ys.sort()
	var x0 := 9999
	var x1 := 0
	for y in ys:
		x0 = mini(x0, linhas[y].x)
		x1 = maxi(x1, linhas[y].y)
	var img := Image.create(x1 - x0 + 1, ys.size(), false, Image.FORMAT_RGBA8)
	for k in ys.size():
		var l: Vector2i = linhas[ys[k]]
		for x in range(l.x, l.y + 1):
			img.set_pixel(x - x0, k, COR)
	return img
