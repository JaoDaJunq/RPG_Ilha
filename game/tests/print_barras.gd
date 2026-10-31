extends TesteBase
## Print (precisa de janela): slimes e animais com o nível em cima da cabeça, a barra de vida
## de quem apanhou e a janelinha de uma habilidade aberta. Salva em evidence/novidades/.

const SLIME := preload("res://scenes/enemies/slime.tscn")
const ANIMAL := preload("res://scenes/animals/animal.tscn")


func _ready() -> void:
	var w := await criar_mundo(0, true, &"mago", &"humano")
	var p := w.jogador
	var c := p.global_position + Vector2(0, -40)
	var bichos: Array[Node2D] = []
	var s := colocar(w, SLIME, c + Vector2(-50, 0))
	var n: Slime = SLIME.instantiate()
	n.noturno = true
	n.position = c + Vector2(-20, 14)
	w.entidades.add_child(n, true)
	bichos.append(s)
	bichos.append(n)
	var especies := [&"galinha", &"coelho", &"ovelha", &"javali"]
	for i in especies.size():
		var a: Animal = ANIMAL.instantiate()
		a.especie = especies[i]
		a.position = c + Vector2(15 + i * 28, (i % 2) * 14 - 4)
		w.entidades.add_child(a, true)
		bichos.append(a)
	for b in bichos:
		b.set_physics_process(false)  # parados, para a imagem ficar igual
	await esperar(0.3)
	# Batem em alguns: o slime, o javali e a ovelha mostram a barra.
	s.hurtbox.receber(1.0, &"fisico", null)
	bichos[5].hurtbox.receber(1.0, &"fisico", null)
	bichos[4].hurtbox.receber(1.0, &"fisico", null)
	n.hurtbox.receber(2.0, &"fisico", null)
	await esperar(0.25)
	w.hud.mostrar_descricao(1)
	await esperar(0.3)
	await salvar_print("novidades/barras_e_descricao.png")
	terminar()
