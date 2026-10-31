extends TesteBase
## Prints da reação ao dano (precisa de janela): o slime quicando para trás depois da
## cabeçada com o jogador vermelho, e o jogador com 20% de vida e as bordas vermelhas.
## Salva em evidence/novidades/dano_*.png.

const SLIME := preload("res://scenes/enemies/slime.tscn")
const ANIMAL := preload("res://scenes/animals/animal.tscn")


func _ready() -> void:
	var w := await criar_mundo(0, true, &"guerreiro", &"humano")
	var p := w.jogador
	p.global_position = w.centro + Vector2(0, 80)
	p.camera.reset_smoothing()
	var s: Slime = colocar(w, SLIME, p.global_position + Vector2(26, 0))
	await get_tree().physics_frame
	var antes := p.vida.atual
	while p.vida.atual >= antes:
		await get_tree().physics_frame
	await esperar(0.07)
	await salvar_print("novidades/dano_cabecada_slime.png")
	s.queue_free()
	await esperar(0.8)

	var j: Animal = ANIMAL.instantiate()
	j.especie = &"javali"
	j.position = p.global_position + Vector2(30, 0)
	w.entidades.add_child(j, true)
	await get_tree().physics_frame
	antes = p.vida.atual
	j.hurtbox.receber(0.1, &"fisico", p)
	while p.vida.atual >= antes:
		await get_tree().physics_frame
	await esperar(0.07)
	await salvar_print("novidades/dano_cabecada_javali.png")
	j.queue_free()

	p.vida.atual = p.vida.maximo * 0.2
	await esperar(1.5)
	await salvar_print("novidades/dano_vida_baixa.png")
	terminar()
