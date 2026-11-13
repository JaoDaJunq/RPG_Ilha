extends TesteBase
## Prints do caído e da tela de morte (precisa de janela). Salva em evidence/novidades/morte_*.png:
##   morte_tela.png         a tela de morte aos 2 s (contagem 6, botão travado)
##   morte_tela_botao.png   aos 4 s (botão liberado)
##   morte_caido_mundo.png        um aliado caído no mundo (com a arte caido.png, se existir)
##   morte_caido_placeholder.png  o mesmo com o placeholder (o perfil girado 90°); "segure E" em cima

const JOGADOR := preload("res://scenes/player/player.tscn")


func _ready() -> void:
	var w := await criar_mundo(0, true, &"guerreiro", &"humano")
	var p := w.jogador
	p.global_position = w.centro + Vector2(0, 80)
	p.camera.reset_smoothing()
	await esperar(0.5)
	p.vida.tomar_dano(100000.0)
	await esperar(2.1)
	await salvar_print("novidades/morte_tela.png")
	await esperar(2.2)
	await salvar_print("novidades/morte_tela_botao.png")
	p.tela_morte().apertar_reviver()
	await esperar(0.5)

	var aliado: Player = JOGADOR.instantiate()
	aliado.name = "2"
	aliado.classe = &"mago"
	aliado.position = p.global_position + Vector2(18, 0)
	w.entidades.add_child(aliado)
	await get_tree().physics_frame
	aliado.vida.tomar_dano(100000.0)
	p.camera.reset_smoothing()
	await esperar(0.6)
	# Com a arte caido.png (se existir) e com o placeholder (o perfil girado), lado a lado no tempo.
	await salvar_print("novidades/morte_caido_mundo.png")
	aliado.visual._tira_caido = null
	await esperar(0.2)
	await salvar_print("novidades/morte_caido_placeholder.png")
	terminar()
