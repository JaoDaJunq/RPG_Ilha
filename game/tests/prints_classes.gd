extends TesteBase
## Prints das classes em ação (precisa de janela). Uso:
##   <godot> --path game --resolution 1280x720 res://tests/prints_classes.tscn -- --classe=mago
## Salva em evidence/personagem/<classe>.png.

const SLIME := preload("res://scenes/enemies/slime.tscn")


func _ready() -> void:
	var classe := Net.classe
	var w := await criar_mundo(0, false, classe, Net.raca)
	var p := w.jogador
	match classe:
		&"mago":
			# Na praia: lança de gelo vira ponte sobre a água; um slime congelado.
			var y := w.altura / 2
			var areia := 0
			for x in w.largura:
				if w.tipo_do_chao(Vector2i(x, y)) == World.Chao.AREIA:
					areia = x
					break
			p.global_position = w.chao.map_to_local(Vector2i(areia + 1, y)) + Vector2(0, 6)
			p.camera.reset_smoothing()
			var s: Slime = colocar(w, SLIME, p.global_position + Vector2(40, 40))
			s.set_physics_process(false)
			await get_tree().physics_frame
			p.mira_forcada = p.global_position + Vector2(-200, -10)
			p.usar_habilidade_por_id(&"lanca_gelo")
			await esperar(1.3)
			p.mira_forcada = s.global_position + Vector2(0, -6)
			s.set_physics_process(true)
			p.usar_habilidade_por_id(&"lanca_gelo")
			await esperar(0.35)
			p.mira_forcada = p.global_position + Vector2(-60, -30)
		&"arqueiro":
			var s: Slime = colocar(w, SLIME, p.global_position + Vector2(70, 10))
			s.set_physics_process(false)
			await get_tree().physics_frame
			p.mira_forcada = p.global_position + Vector2(0, 50)
			p.usar_habilidade_por_id(&"armadilha")
			await esperar(0.2)
			p.mira_forcada = s.global_position + Vector2(0, -6)
			p.comecar_habilidade(0)  # segurando o tiro carregado
			await esperar(0.6)
		&"guerreiro":
			for d in [Vector2(-20, 0), Vector2(20, 4), Vector2(0, 22)]:
				var s: Slime = colocar(w, SLIME, p.global_position + d)
				s.set_physics_process(false)
			await get_tree().physics_frame
			p.usar_habilidade_por_id(&"giro")
			await esperar(0.12)
	if "--com-ficha" in OS.get_cmdline_user_args():
		w.hud._ficha_texto.text = w.hud._texto_ficha()
		w.hud._ficha.visible = true
	await salvar_print("personagem/%s%s.png" % [classe, "_ficha" if "--com-ficha" in OS.get_cmdline_user_args() else ""])
	terminar()
