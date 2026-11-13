extends TesteBase
## Prints das armas das classes na mão (L37), dentro do jogo (precisa de janela):
##   armas_classes_parado.png / armas_classes_golpe.png: os 5 Humanos (uma coluna por classe),
##     de perfil (em cima) e de frente (embaixo), parados e no golpe;
##   armas_ladino_vistas.png: o Ladino das 4 raças (uma linha por raça) com as 2 adagas, nas 3 vistas;
##   armas_arco_puxando.png: o Arqueiro das 3 vistas (uma linha por vista) em repouso e nos 3
##     tempos da puxada.
## Os mesmos com "_zoom" no fim saem com a câmera 1,5x mais perto.


func _ready() -> void:
	var w := await criar_mundo(0, true, &"guerreiro", &"humano", true, 0)
	var p := w.jogador
	p.visible = false
	w.hud.visible = false
	var centro := p.position + Vector2(0, 70)
	p.position = centro
	var cam: Camera2D = p.camera
	await esperar(0.3)

	# 1) As 5 classes do Humano.
	var linhas := [&"parado_direita", &"parado_baixo"]
	var bonecos: Array[Boneco] = []
	for l in linhas.size():
		for c in ClasseData.TODAS.size():
			var classe: StringName = ClasseData.TODAS[c]
			var b := _boneco(w, centro + Vector2((c - 2) * 36, (l - 0.5) * 40 + 12), &"humano", classe)
			b.play(linhas[l])
			bonecos.append(b)
	await _dois_prints("novidades/armas_classes_parado", cam)
	for b in bonecos:
		b.play(&"golpe_direita" if String(b.animation).ends_with("direita") else &"golpe_baixo")
	await esperar(0.2)
	await salvar_print("novidades/armas_classes_golpe.png")
	for b in bonecos:
		b.play(&"parado_direita")
		b.play(&"golpe_direita" if bonecos.find(b) < 5 else &"golpe_baixo")
	cam.zoom *= 1.5
	await esperar(0.2)
	await salvar_print("novidades/armas_classes_golpe_zoom.png")
	cam.zoom /= 1.5
	# Também a preparação do golpe (braço para trás).
	for b in bonecos:
		b.play(&"parado_direita")
		b.play(&"golpe_direita" if bonecos.find(b) < 5 else &"golpe_baixo")
	await esperar(0.06)
	await salvar_print("novidades/armas_classes_golpe_preparo.png")
	_limpar(bonecos)

	# 2) O Ladino das 4 raças, nas 3 vistas.
	var vistas := [&"parado_direita", &"parado_baixo", &"parado_cima"]
	var racas := [&"humano", &"ogro", &"elfo", &"anao"]
	for r in racas.size():
		for v in vistas.size():
			var b := _boneco(w, centro + Vector2((v - 1) * 40, (r - 1.5) * 30 - 4), racas[r], &"ladino")
			b.play(vistas[v])
			bonecos.append(b)
	await _dois_prints("novidades/armas_ladino_vistas", cam)
	_limpar(bonecos)

	# 3) O Arqueiro puxando o arco nas 3 vistas: repouso e os 3 tempos da puxada.
	var cargas := [-1.0, 0.2, 0.5, 1.0]
	for v in vistas.size():
		for k in cargas.size():
			var b := _boneco(w, centro + Vector2((k - 1.5) * 36, (v - 1) * 32 - 2), &"humano", &"arqueiro")
			b.play(vistas[v])
			b.carga = cargas[k]
			bonecos.append(b)
	await _dois_prints("novidades/armas_arco_puxando", cam)
	_limpar(bonecos)
	terminar()


func _boneco(w: World, pos: Vector2, raca: StringName, classe: StringName) -> Boneco:
	var b := Boneco.new()
	b.scale = Vector2.ONE * 0.25
	b.position = pos
	w.entidades.add_child(b)
	b.vestir({"raca": raca, "pele": 0, "classe": classe}, {})
	b.item = Player.KIT.get(classe, &"")
	return b


func _dois_prints(nome: String, cam: Camera2D) -> void:
	await esperar(0.4)
	await salvar_print(nome + ".png")
	cam.zoom *= 1.5
	await esperar(0.2)
	await salvar_print(nome + "_zoom.png")
	cam.zoom /= 1.5


func _limpar(lista: Array[Boneco]) -> void:
	for b in lista:
		b.queue_free()
	lista.clear()
