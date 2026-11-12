extends TesteBase
## Print dos 20 personagens em sprite completo (L30/L31) dentro do jogo (precisa de janela):
## uma linha por raça, uma coluna por classe, cada um com a arma da classe na mão.
## Salva evidence/novidades/personagens_todos.png (de frente) e personagens_todos_golpe.png.


func _ready() -> void:
	var w := await criar_mundo(0, true, &"guerreiro", &"humano")
	var p := w.jogador
	p.visible = false
	w.hud.visible = false
	var todos: Array[Boneco] = []
	var racas := [&"humano", &"ogro", &"elfo", &"anao"]
	for r in racas.size():
		for c in ClasseData.TODAS.size():
			var classe: StringName = ClasseData.TODAS[c]
			var b := Boneco.new()
			b.scale = Vector2.ONE * 0.25
			b.position = p.position + Vector2((c - 2) * 34, (r - 1.5) * 34 + 10)
			w.entidades.add_child(b)
			b.vestir({"raca": racas[r], "pele": 0, "classe": classe}, {})
			b.item = Player.KIT.get(classe, &"")
			b.play(&"parado_baixo")
			todos.append(b)
	await esperar(0.5)
	await salvar_print("novidades/personagens_todos.png")
	for b in todos:
		b.play(&"golpe_direita")
	await esperar(0.2)
	await salvar_print("novidades/personagens_todos_golpe.png")
	terminar()
