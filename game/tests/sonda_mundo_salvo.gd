extends SceneTree
## Sonda (não é teste da bateria): abre o MENU como o atalho da área de trabalho, entra num
## mundo salvo do jogador (uma CÓPIA, para não estragar o original) e tira prints, para achar
## o que quebra fora dos testes. Uso (com janela):
##   godot --path game --script res://tests/sonda_mundo_salvo.gd -- meu_mundo.save


func _initialize() -> void:
	var nome: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "meu_mundo.save"
	DirAccess.make_dir_recursive_absolute("user://teste_mundos")
	var copia := "user://teste_mundos/sonda_" + nome
	DirAccess.copy_absolute(ProjectSettings.globalize_path("user://mundos/" + nome), ProjectSettings.globalize_path(copia))
	change_scene_to_file("res://scenes/ui/menu.tscn")
	await process_frame
	await process_frame
	await _print("sonda_menu")
	current_scene.call(&"_jogar_mundo", copia, "Sonda", 1)
	for i in 3:
		await create_timer(3.0).timeout
		await _print("sonda_mundo_%d" % i)
	print("SONDA: cena atual = ", current_scene.name if current_scene else "nenhuma")
	quit()


func _print(nome: String) -> void:
	await RenderingServer.frame_post_draw
	var destino := ProjectSettings.globalize_path("res://").path_join("../evidence/sonda/%s.png" % nome)
	DirAccess.make_dir_recursive_absolute(destino.get_base_dir())
	root.get_texture().get_image().save_png(destino)
	print("SONDA print: ", nome)
