extends TesteBase
## "Só fica ativo o que está perto" (Soneca): longe de todos os jogadores, bichos, inimigos,
## árvores e a espuma do mar dormem; chegando perto, acordam. E a rede manda para cada
## jogador só o que está perto dele.


func _ready() -> void:
	var w := await criar_mundo(0, false)
	var p := w.jogador
	await esperar(1.2)
	var s := w.soneca
	var longe_dormindo := true
	var perto_acordado := true
	var dormindo := 0
	for g in [&"inimigos", &"animais", &"recursos"]:
		for n in get_tree().get_nodes_in_group(g):
			var d := (n as Node2D).global_position.distance_to(p.global_position)
			var dorme: bool = n.process_mode == Node.PROCESS_MODE_DISABLED
			if dorme:
				dormindo += 1
			if d > Soneca.RAIO_DORMIR + 100.0 and not dorme:
				longe_dormindo = false
			if d < Soneca.RAIO_ACORDAR - 50.0 and dorme:
				perto_acordado = false
	checar(dormindo > 100 and dormindo == s.dormindo(), "o que está longe dorme (%d)" % dormindo)
	checar(longe_dormindo, "tudo o que está longe de todos dorme")
	checar(perto_acordado, "tudo o que está perto fica acordado")

	# Um bicho dormindo longe: não anda. O jogador chega perto: ele acorda e volta a pensar.
	var bicho: Animal = null
	for a in get_tree().get_nodes_in_group(&"animais"):
		if a.process_mode == Node.PROCESS_MODE_DISABLED:
			bicho = a
			break
	checar(bicho != null, "achou um bicho dormindo")
	var antes := bicho.global_position
	await esperar(1.0)
	checar(bicho.global_position == antes, "dormindo, não se mexe")
	p.global_position = bicho.global_position + Vector2(60, 0)
	await esperar(0.5)
	checar(bicho.process_mode != Node.PROCESS_MODE_DISABLED, "o jogador chegou perto: acordou")
	bicho.hurtbox.receber(0.5, &"fisico", p)
	await esperar(0.8)
	checar(bicho.global_position.distance_to(antes) > 4.0, "acordado, foge de quem bateu")
	# A espuma do mar perto também acorda; a de longe dorme.
	var acordados := 0
	var dormindo_esp := 0
	for pd in s._pedacos:
		if (pd[0] as Node).process_mode == Node.PROCESS_MODE_DISABLED:
			dormindo_esp += 1
		else:
			acordados += 1
	checar(dormindo_esp > acordados, "a espuma do mar longe dorme (%d dormindo, %d acordados)" % [dormindo_esp, acordados])

	# Rede: um jogador (peer 7) só recebe o que está perto dele.
	var outro := Node2D.new()
	outro.name = "7"
	outro.global_position = bicho.global_position + Vector2(100, 0)
	w.entidades.add_child(outro)
	var longe_dele: Node2D = null
	for a in get_tree().get_nodes_in_group(&"animais"):
		if (a as Node2D).global_position.distance_to(outro.global_position) > Soneca.RAIO_REDE + 50.0:
			longe_dele = a
			break
	checar(s._ve(7, bicho) and not s._ve(7, longe_dele), "a rede manda para cada um só o que está perto dele")
	checar(s._ve(1, longe_dele), "o anfitrião vê tudo")
	var sync := bicho.get_node("Sync") as MultiplayerSynchronizer
	checar(s._filtrados.has(sync), "os bichos têm o filtro de rede por distância")
	outro.queue_free()
	terminar()
