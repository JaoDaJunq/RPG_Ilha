extends TesteBase
## Prints dos efeitos das habilidades 3 e 4 (precisa de janela). Uma classe por vez:
##   <godot> --path game res://tests/print_habilidades.tscn -- --classe=guerreiro
## Salva evidence/novidades/hab_<classe>_<habilidade>.png.

const SLIME := preload("res://scenes/enemies/slime.tscn")

const ROTEIRO := {
	&"guerreiro": [[&"bloqueio", 0.4], [&"furia", 0.45]],
	&"mago": [[&"raio", 0.2], [&"nova_gelo", 0.45]],
	&"arqueiro": [[&"chuva_flechas", 0.3], [&"bomba", 0.25]],
}


func _ready() -> void:
	var classe := &"guerreiro"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--classe="):
			classe = StringName(a.get_slice("=", 1))
	var w := await criar_mundo(0, true, classe, &"humano")
	var p := w.jogador
	for passo in ROTEIRO[classe]:
		var alvo := p.global_position + Vector2(44, 4)
		var slime: Slime = colocar(w, SLIME, alvo)
		slime.set_physics_process(false)
		p.mira_forcada = alvo + Vector2(0, -4)
		await esperar(0.3)
		checar(p.usar_habilidade_por_id(passo[0]), "usou " + passo[0])
		await esperar(passo[1])
		await salvar_print("novidades/hab_%s_%s.png" % [classe, passo[0]])
		await esperar(1.5)
		if is_instance_valid(slime):
			slime.queue_free()
	terminar()
