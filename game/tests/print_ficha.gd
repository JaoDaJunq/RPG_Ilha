extends TesteBase
## Prints da ficha nova (precisa de janela). Um Elfo Mago de nível 5 com pontos para
## distribuir: a aba Atributos com a prévia do "+" da Vitalidade, e a aba Habilidades com o
## Raio aprendido e a Bola de fogo melhorada. Salva evidence/novidades/ficha_nova_*.png.


func _ready() -> void:
	var w := await criar_mundo(0, true, &"mago", &"elfo")
	var p := w.jogador
	while p.nivel < 5:
		p.ganhar_xp(Ficha.xp_para_subir(p.nivel))
	for a in [&"intelecto", &"intelecto", &"espirito", &"vitalidade", &"intelecto"]:
		p.pedir_atributo(a)
	for id in [&"raio", &"bola_de_fogo"]:
		p.pedir_aprender(id)
	await get_tree().physics_frame
	checar(p.pontos_atributo == 3 and p.pontos_habilidade == 2, "Mago nível 5 com 3 pontos de atributo e 2 de habilidade (%d, %d)" % [p.pontos_atributo, p.pontos_habilidade])
	w.hud.mostrar_aviso("")
	var ficha := w.hud.ficha()
	ficha.visible = true
	ficha.mostrar_previa(&"vitalidade")
	await esperar(0.4)
	await salvar_print("novidades/ficha_nova_atributos.png")
	ficha.abrir_aba(FichaTela.ABA_HABILIDADES)
	await esperar(0.3)
	await salvar_print("novidades/ficha_nova_habilidades.png")
	terminar()
