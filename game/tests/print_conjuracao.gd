extends TesteBase
## Prints da conjuração (L38, precisa de janela): o mago conjurando o Tornado de fogo com o
## anel vermelho, amarelo e verde (piscando), e o arqueiro puxando o arco.
## Salva evidence/novidades/conjuracao_*.png (a tela toda e um recorte perto do personagem).


func _ready() -> void:
	var w := await criar_mundo(0, true, &"mago", &"humano")
	var p := w.jogador
	_na_mao(p, &"cajado")
	p.teclas = ArvoreData.padrao(&"mago").duplicate()
	p.aprender_de_graca(&"tornado_de_fogo")
	var i := 0
	for k in p.habilidades().size():
		if p.habilidades()[k].id == &"tornado_de_fogo":
			i = k
	var t := Conjuracao.tempo(p, p.habilidades()[i])
	p.mira_forcada = p.global_position + Vector2(60, -8)
	await esperar(0.6)
	p.comecar_habilidade(i)
	await esperar(t * 0.4)
	await _print("conjuracao_1_vermelho")
	await esperar(t * 0.45)
	await _print("conjuracao_2_amarelo")
	await esperar(t * 0.15 + 0.06)
	await _print("conjuracao_3_verde_piscando")
	await esperar(0.4)
	await _print("conjuracao_4_verde")
	p.soltar_carga()
	await esperar(0.35)
	await _print("conjuracao_5_lancou")
	w.queue_free()
	await esperar(0.2)

	w = await criar_mundo(0, true, &"arqueiro", &"humano")
	p = w.jogador
	_na_mao(p, &"arco")
	p.mira_forcada = p.global_position + Vector2(60, -8)
	await esperar(0.6)
	p.comecar_habilidade(0)
	await esperar(0.12)
	await _print("conjuracao_6_arco_puxando")
	await esperar(0.3)
	await _print("conjuracao_7_arco_verde")
	await esperar(1.0)
	await _print("conjuracao_8_arco_carga_cheia")
	p.soltar_carga()
	terminar()


func _na_mao(p: Player, item: StringName) -> void:
	for k in Inventory.BARRA:
		if p.inventario.item_em(k) == item:
			p.barra_escolhida = k


## A tela toda e um recorte de 320x200 em volta do personagem (aumentado 2x, sem borrar).
func _print(nome: String) -> void:
	await salvar_print("novidades/%s.png" % nome)
	var img := get_viewport().get_texture().get_image()
	var c := img.get_size() / 2
	var r := img.get_region(Rect2i(c.x - 160, c.y - 130, 320, 200))
	r.resize(640, 400, Image.INTERPOLATE_NEAREST)
	var destino := ProjectSettings.globalize_path("res://").path_join("../evidence/novidades/%s_perto.png" % nome)
	r.save_png(destino)
