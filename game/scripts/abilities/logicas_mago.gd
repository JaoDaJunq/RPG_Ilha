class_name LogicasMago
extends RefCounted
## Lógicas das habilidades novas do Mago (árvore de habilidades).
## Cada `class Nome extends HabilidadeLogica` escrita aqui já fica registrada em
## Logicas.criar: basta pôr `logica = &"Nome"` no .tres da habilidade (o nome não pode
## repetir o de outro arquivo). Peças prontas (zona, invocação, projéteis especiais,
## corrente, avanço, buffs, estados): ver design/habilidades_base.md.
##
## Tudo roda no ANFITRIÃO. Os números de dano do .tres passam por `dano_de` (Intelecto,
## melhorias e Ressonância) na hora do lançamento; o que acontece depois (zona, timer) usa
## o dano já calculado.

## Queimadura das magias de fogo: segundos e dano por segundo (× multiplicador mágico).
const QUEIMA_SEGUNDOS := 4.0
const QUEIMA_DPS := 0.25
## Desequilíbrio (design): 30% de chance de errar cada ataque por 4 s (estado Cego).
const DESEQUILIBRIO_CHANCE := 0.3
const DESEQUILIBRIO_SEGUNDOS := 4.0


## Ponto no chão na direção da mira, até `alcance` px de quem lançou.
static func ponto_mira(quem: Player, mira: Vector2, alcance: float) -> Vector2:
	var de := quem.global_position
	return de + (mira - de).limit_length(alcance * Passivas.alcance(quem))


## Dano por segundo da Queimadura que este mago aplica.
static func queima_dps(quem: Player) -> float:
	return QUEIMA_DPS * quem.ficha.multiplicador_magico()


## Anda a zona `z` um passo (do tamanho de um tique) na direção de `ate`.
static func andar_zona(z: Zona, ate: Vector2, velocidade: float) -> void:
	z.global_position += (ate - z.global_position).limit_length(velocidade * z.intervalo)


## O alvo está molhado (em cima de água ou de gelo)? Condução salta mais nele.
static func molhado(alvo: Node2D) -> bool:
	if alvo == null or not is_instance_valid(alvo):
		return false
	var w: World = alvo.get_tree().get_first_node_in_group(&"mundo")
	if w == null or w.chao == null:
		return false
	var cel := w.chao.local_to_map(w.chao.to_local(alvo.global_position))
	return w.tipo_do_chao(cel) == World.Chao.AGUA or w.eh_gelo(cel)


## Condução (chamada pelo Raio): salta para mais 1 inimigo perto do alvo; se o alvo estiver
## molhado, para mais 2 (3 saltos ao todo).
const CONDUCAO_SALTOS_MOLHADO := 3


static func conducao(quem: Player, hab: HabilidadeData, primeiro: Node2D, onde: Vector2, atordoar: float) -> Array[Node2D]:
	var saltos := CONDUCAO_SALTOS_MOLHADO if molhado(primeiro) else 1
	var feitos: Array[Node2D] = [primeiro]
	var de := onde
	var dano := HabilidadeLogica.dano_de(quem, hab)
	for k in saltos:
		var salto := Golpes.mais_perto(quem, de, Passivas.CONDUCAO_RAIO, feitos)
		if salto == null:
			break
		feitos.append(salto)
		de = salto.global_position
		Golpes.acertar(quem, salto, dano, &"raio", &"", 0.0, 0.0, &"raio")
		if is_instance_valid(salto) and salto.has_method(&"prender"):
			salto.prender(atordoar)
	feitos.remove_at(0)
	return feitos


# --- Iniciais ---------------------------------------------------------------------------

## Pedra viva: uma pedra rola até a mira; quem ela atropela leva dano e fica em
## Desequilíbrio (30% de chance de errar cada ataque por 4 s).
class PedraViva extends HabilidadeLogica:
	const VELOCIDADE := 160.0
	const RAIO := 12.0
	const PASSO := 0.1

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var ate := LogicasMago.ponto_mira(quem, alvo, hab.alcance)
		if ate.distance_to(quem.global_position) < 16.0:
			ate = quem.global_position + dir * hab.alcance
		var de := quem.global_position + (ate - quem.global_position).normalized() * 8.0
		var dano := dano_de(quem, hab)
		var z := Zona.criar(quem, de, RAIO, maxf(PASSO, de.distance_to(ate) / VELOCIDADE), PASSO)
		z.efeito_tique = &"poeira"
		var ja: Array[Node2D] = []
		z.ao_tique = func(zona: Zona, inimigos: Array[Node2D], _j: Array[Player]) -> void:
			for e in inimigos:
				if not e in ja:
					ja.append(e)
					Golpes.acertar(zona.lancador, e, dano, &"terra", EfeitosEstado.CEGO, LogicasMago.DESEQUILIBRIO_SEGUNDOS, LogicasMago.DESEQUILIBRIO_CHANCE)
			LogicasMago.andar_zona(zona, ate, VELOCIDADE)
		z.iniciar()


# --- Fogo -------------------------------------------------------------------------------

## Rastro de chamas: por 4 s, o chão por onde você anda pega fogo (cada brasa dura 2 s,
## machuca e queima quem pisa).
class RastroDeChamas extends HabilidadeLogica:
	const DURACAO := 4.0
	const BRASA_SEGUNDOS := 2.0
	const BRASA_RAIO := 12.0
	const BRASA_INTERVALO := 0.5
	const DISTANCIA_ENTRE := 10.0  # parado, não acende outra brasa no mesmo lugar

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var dano := dano_de(quem, hab)
		var dps := LogicasMago.queima_dps(quem)
		var ultima := [Vector2.INF]
		var guia := Zona.criar(quem, quem.global_position, 1.0, DURACAO, 0.25)
		guia.seguir = quem
		guia.ao_tique = func(zona: Zona, _i: Array[Node2D], _j: Array[Player]) -> void:
			var aqui: Vector2 = zona.global_position
			if (ultima[0] as Vector2).distance_to(aqui) < DISTANCIA_ENTRE:
				return
			ultima[0] = aqui
			var b := Zona.criar(zona.lancador, aqui, BRASA_RAIO, BRASA_SEGUNDOS, BRASA_INTERVALO)
			b.dano = dano
			b.elemento = &"fogo"
			b.estado = EfeitosEstado.QUEIMADURA
			b.estado_segundos = LogicasMago.QUEIMA_SEGUNDOS
			b.estado_forca = dps
			b.efeito_visual = &"explosao"
			b.escala_visual = 0.25
			b.add_to_group(&"brasas")
			b.iniciar(zona.get_parent())
		guia.iniciar()


## Mini explosão: uma brasa voa 1 s (ou até bater) e explode, empurrando e queimando.
class MiniExplosao extends HabilidadeLogica:
	const TEMPO := 1.0
	const RAIO := 32.0
	const EMPURRAO := 24.0

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var dano := dano_de(quem, hab)
		var dps := LogicasMago.queima_dps(quem)
		var p := Logicas.lancar(Logicas.BOLA_DE_FOGO, quem, dir, 0.0, 0.5)
		p.duracao = TEMPO
		p.terminou.connect(func(pos: Vector2, acertou: bool) -> void:
			if not is_instance_valid(quem):
				return
			for e in Golpes.inimigos_em_volta(quem, pos, RAIO):
				Golpes.acertar(quem, e, dano, &"fogo", EfeitosEstado.QUEIMADURA, LogicasMago.QUEIMA_SEGUNDOS, dps)
				if is_instance_valid(e):
					Golpes.puxar(e, pos, -EMPURRAO)
			if not acertou:
				World.efeito_todos(quem, &"explosao", pos))


## Tornado de fogo: um redemoinho anda até a mira puxando os inimigos para dentro e
## queimando quem está no meio.
class TornadoDeFogo extends HabilidadeLogica:
	const DURACAO := 2.5
	const VELOCIDADE := 45.0
	const INTERVALO := 0.25
	const RAIO := 20.0
	const RAIO_PUXAO := 44.0
	const PUXAO := 8.0

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var ate := LogicasMago.ponto_mira(quem, alvo, hab.alcance)
		var dano := dano_de(quem, hab)
		var dps := LogicasMago.queima_dps(quem)
		var z := Zona.criar(quem, quem.global_position, RAIO, DURACAO, INTERVALO)
		z.efeito_tique = &"giro"
		z.ao_tique = func(zona: Zona, inimigos: Array[Node2D], _j: Array[Player]) -> void:
			var centro: Vector2 = zona.global_position
			for e in Golpes.inimigos_em_volta(zona, centro, RAIO_PUXAO):
				if not e in inimigos:
					Golpes.puxar(e, centro, PUXAO, 0.15)
			for e in inimigos:
				Golpes.acertar(zona.lancador, e, dano, &"fogo", EfeitosEstado.QUEIMADURA, LogicasMago.QUEIMA_SEGUNDOS, dps)
			LogicasMago.andar_zona(zona, ate, VELOCIDADE)
		z.iniciar()


## Chuva de meteoros (suprema): por 5 s, meteoros caem numa área grande na mira (um num
## inimigo dentro e outro num ponto qualquer, a cada 0,4 s).
class ChuvaDeMeteoros extends HabilidadeLogica:
	const DURACAO := 5.0
	const INTERVALO := 0.4
	const RAIO := 48.0
	const RAIO_METEORO := 16.0

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var ponto := LogicasMago.ponto_mira(quem, alvo, hab.alcance)
		var dano := dano_de(quem, hab)
		var dps := LogicasMago.queima_dps(quem)
		var z := Zona.criar(quem, ponto, RAIO, DURACAO, INTERVALO)
		z.ao_tique = func(zona: Zona, inimigos: Array[Node2D], _j: Array[Player]) -> void:
			var quedas: Array[Vector2] = [zona.global_position + Vector2.from_angle(randf() * TAU) * RAIO * sqrt(randf())]
			if not inimigos.is_empty():
				quedas.append(inimigos.pick_random().global_position)
			for q in quedas:
				World.efeito_todos(zona, &"explosao", q)
				for e in Golpes.inimigos_em_volta(zona, q, RAIO_METEORO):
					Golpes.acertar(zona.lancador, e, dano, &"fogo", EfeitosEstado.QUEIMADURA, LogicasMago.QUEIMA_SEGUNDOS, dps)
		z.iniciar()


# --- Gelo -------------------------------------------------------------------------------

## Muralha de gelo: 5 blocos de gelo atravessados na mira por 6 s; quem encosta é empurrado
## de volta (fecha o caminho). Mirando na água, vira ponte: congela o caminho até lá.
class MuralhaDeGelo extends HabilidadeLogica:
	const DURACAO := 6.0
	const BLOCOS := 5
	const ESPACO := 14.0
	const RAIO_BLOCO := 10.0
	const EMPURRAO := 12.0
	const PONTE := 96.0

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var centro := LogicasMago.ponto_mira(quem, alvo, hab.alcance)
		var frente := (centro - quem.global_position).normalized() if centro.distance_to(quem.global_position) > 1.0 else dir
		var w: World = quem.get_tree().get_first_node_in_group(&"mundo")
		if w and w.tipo_do_chao(w.chao.local_to_map(w.chao.to_local(centro))) == World.Chao.AGUA:
			# Ponte: congela a água da frente do mago até um pouco depois da mira.
			var d := 8.0
			while d <= PONTE:
				World.congelar_agua_em(quem, quem.global_position + frente * d)
				d += 6.0
			World.efeito_todos(quem, &"congelar", centro)
			return
		var lado := frente.orthogonal()
		for k in BLOCOS:
			var b := Zona.criar(quem, centro + lado * (k - (BLOCOS - 1) / 2.0) * ESPACO, RAIO_BLOCO, DURACAO, 0.1)
			b.efeito_visual = &"congelar"
			b.add_to_group(&"muralha_gelo")
			b.ao_tique = func(zona: Zona, inimigos: Array[Node2D], _j: Array[Player]) -> void:
				for e in inimigos:
					# Volta para o lado de onde veio (o da frente da muralha, para quem está longe do mago).
					var s := signf((e.global_position - centro).dot(frente))
					var ef := EfeitosEstado.de(e)
					if ef:
						ef.empurrar(frente * (s if s != 0.0 else 1.0) * EMPURRAO, 0.1)
			b.iniciar()


## Prisão de gelo: congela por 4 s o inimigo mais perto da mira.
class PrisaoDeGelo extends HabilidadeLogica:
	const SEGUNDOS := 4.0
	const RAIO_MIRA := 32.0

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var e := Logicas.inimigo_na_mira(quem, alvo, hab.alcance, RAIO_MIRA)
		if e == null:
			return
		Golpes.acertar(quem, e, dano_de(quem, hab), &"gelo", EfeitosEstado.CONGELADO, SEGUNDOS, 0.0, &"congelar")


## Nevasca (suprema): área grande por 6 s; a cada segundo dentro, o inimigo fica mais lento
## (25%, 50%) e no terceiro congela por 2 s.
class Nevasca extends HabilidadeLogica:
	const DURACAO := 6.0
	const RAIO := 56.0
	const LENTO_POR_TIQUE := 0.25
	const TIQUES_PARA_CONGELAR := 3
	const CONGELA := 2.0

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var ponto := LogicasMago.ponto_mira(quem, alvo, hab.alcance)
		var dano := dano_de(quem, hab)
		var conta := {}
		var z := Zona.criar(quem, ponto, RAIO, DURACAO)
		z.efeito_visual = &"nova_gelo"
		z.escala_visual = 2.5
		z.ao_tique = func(zona: Zona, inimigos: Array[Node2D], _j: Array[Player]) -> void:
			for e in inimigos:
				var n: int = conta.get(e.get_instance_id(), 0) + 1
				conta[e.get_instance_id()] = n
				if n >= TIQUES_PARA_CONGELAR:
					conta[e.get_instance_id()] = 0
					Golpes.acertar(zona.lancador, e, dano, &"gelo", EfeitosEstado.CONGELADO, CONGELA, 0.0, &"congelar")
				else:
					# "frio": dano de gelo que não congela na hora (o slime congela com "gelo").
					Golpes.acertar(zona.lancador, e, dano, &"frio", EfeitosEstado.LENTIDAO, 1.5, LENTO_POR_TIQUE * n)
		z.iniciar()


# --- Raio -------------------------------------------------------------------------------

## Corrente elétrica: um choque no inimigo da mira (ou no mais perto) que pula entre até 5.
class CorrenteEletrica extends HabilidadeLogica:
	const ALVOS := 5
	const SALTO := 56.0
	const RAIO_MIRA := 40.0
	const ATORDOA := 0.3

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var primeiro := Logicas.inimigo_na_mira(quem, alvo, hab.alcance, RAIO_MIRA)
		if primeiro == null:
			primeiro = Golpes.mais_perto(quem, quem.global_position, hab.alcance)
		if primeiro == null:
			return
		Golpes.corrente(quem, primeiro, ALVOS, SALTO, dano_de(quem, hab), &"raio", &"raio", EfeitosEstado.ATORDOADO, ATORDOA)


## Totem tesla: uma torre na mira que dá choque nos inimigos perto por 8 s.
class TotemTesla extends HabilidadeLogica:
	const ARTE := "res://assets/sprites/tiny/construcao/tocha.png"  # placeholder: pedir arte ao Codex

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var t := Invocacao.criar(quem, LogicasMago.ponto_mira(quem, alvo, hab.alcance))
		t.textura_caminho = ARTE
		t.quadro = Vector2i(19, 79)
		t.escala = 0.25
		t.deslocamento = Vector2(0, -10)
		t.duracao = 8.0
		t.vida_maxima = 30.0
		t.dano = dano_de(quem, hab)
		t.elemento = &"raio"
		t.alcance = 56.0
		t.visao = 56.0
		t.intervalo = 0.8
		t.velocidade = 0.0
		t.efeito_ataque = &"raio"
		t.estado = EfeitosEstado.ATORDOADO
		t.estado_segundos = 0.2
		t.ataca_animais = true
		t.add_to_group(&"totem_tesla")
		t.iniciar()
		World.efeito_todos(quem, &"raio", t.position)


## Forma de relâmpago: vira raio e atravessa até a mira, ferindo e atordoando o caminho.
class FormaDeRelampago extends HabilidadeLogica:
	const LARGURA := 14.0
	const ATORDOA := 0.5

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		World.efeito_todos(quem, &"raio", quem.global_position)
		for e in Golpes.avancar(quem, alvo, hab.alcance, dano_de(quem, hab), &"raio", LARGURA, true, EfeitosEstado.ATORDOADO, ATORDOA):
			if is_instance_valid(e):
				World.efeito_todos(quem, &"raio", e.global_position)


## Tempestade (suprema): por 8 s, a cada segundo caem raios em até 2 inimigos perto.
class Tempestade extends HabilidadeLogica:
	const DURACAO := 8.0
	const RAIO := 96.0
	const POR_TIQUE := 2
	const ATORDOA := 0.5

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var dano := dano_de(quem, hab)
		var z := Zona.criar(quem, quem.global_position, RAIO, DURACAO)
		z.seguir = quem
		z.ao_tique = func(zona: Zona, inimigos: Array[Node2D], _j: Array[Player]) -> void:
			var lista := inimigos.duplicate()
			lista.shuffle()
			for k in mini(POR_TIQUE, lista.size()):
				Golpes.acertar(zona.lancador, lista[k], dano, &"raio", EfeitosEstado.ATORDOADO, ATORDOA, 0.0, &"raio")
		z.iniciar()
		World.efeito_todos(quem, &"furia", quem.global_position)


# --- Terra ------------------------------------------------------------------------------

## Espinhos: estacas saem do chão na mira, machucam e prendem quem está em cima por 1,5 s.
class Espinhos extends HabilidadeLogica:
	const RAIO := 22.0
	const PRENDE := 1.5

	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var ponto := LogicasMago.ponto_mira(quem, alvo, hab.alcance)
		var dano := dano_de(quem, hab)
		for e in Golpes.inimigos_em_volta(quem, ponto, RAIO):
			Golpes.acertar(quem, e, dano, &"terra", EfeitosEstado.PRESO, PRENDE)
		for desvio in [Vector2(-9, 3), Vector2(9, 3), Vector2(0, -6), Vector2.ZERO]:
			World.efeito_todos(quem, &"poeira", ponto + desvio)


## Golem de pedra: invoca um golem por 15 s que chama os inimigos e dá socos.
class GolemDePedra extends HabilidadeLogica:
	func executar(quem: Player, hab: HabilidadeData, _dir: Vector2, alvo: Vector2, _carga: float) -> void:
		var g := Invocacao.criar(quem, LogicasMago.ponto_mira(quem, alvo, hab.alcance))
		g.textura_caminho = "res://assets/sprites/tiny/pedras_slime.png"  # placeholder: pedir arte ao Codex
		g.duracao = 15.0
		g.vida_maxima = 40.0
		g.dano = dano_de(quem, hab)
		g.elemento = &"terra"
		g.alcance = 18.0
		g.intervalo = 1.0
		g.visao = 110.0
		g.velocidade = 30.0
		g.provoca_raio = 60.0
		g.add_to_group(&"golem_pedra")
		g.iniciar()
		World.efeito_todos(quem, &"poeira", g.position)


## Fenda: uma rachadura em linha reta (7 blocos) que derruba por 1 s e deixa em
## Desequilíbrio quem está nela.
class Fenda extends HabilidadeLogica:
	const LARGURA := 12.0
	const DERRUBA := 1.0

	func executar(quem: Player, hab: HabilidadeData, dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var de := quem.global_position
		var caminho := dir.normalized() * hab.alcance
		var dano := dano_de(quem, hab)
		for e in Golpes.inimigos_em_volta(quem, de + caminho / 2.0, caminho.length() / 2.0 + LARGURA):
			var p := e.global_position
			var t := clampf((p - de).dot(caminho) / caminho.length_squared(), 0.0, 1.0)
			if p.distance_to(de + caminho * t) <= LARGURA:
				Golpes.acertar(quem, e, dano, &"terra", EfeitosEstado.DERRUBADO, DERRUBA)
				EfeitosEstado.aplicar_em(e, EfeitosEstado.CEGO, LogicasMago.DESEQUILIBRIO_SEGUNDOS, LogicasMago.DESEQUILIBRIO_CHANCE, quem)
		var d := 12.0
		while d <= hab.alcance:
			World.efeito_todos(quem, &"poeira", de + dir.normalized() * d)
			d += 16.0


## Despertar da ilha (suprema): por 8 s a ilha treme em volta do mago; os inimigos perto
## erram metade dos ataques e ficam 40% mais lentos.
class DespertarDaIlha extends HabilidadeLogica:
	const DURACAO := 8.0
	const RAIO := 112.0
	const ERRA := 0.5
	const LENTO := 0.4

	func executar(quem: Player, _hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		var z := Zona.criar(quem, quem.global_position, RAIO, DURACAO)
		z.seguir = quem
		z.estado = EfeitosEstado.CEGO
		z.estado_segundos = 1.5
		z.estado_forca = ERRA
		z.efeito_tique = &"poeira"
		z.ao_tique = func(zona: Zona, inimigos: Array[Node2D], _j: Array[Player]) -> void:
			for e in inimigos:
				EfeitosEstado.aplicar_em(e, EfeitosEstado.LENTIDAO, 1.5, LENTO, zona.lancador)
			for k in 3:
				World.efeito_todos(zona, &"poeira", zona.global_position + Vector2.from_angle(randf() * TAU) * RAIO * randf_range(0.3, 0.9))
		z.iniciar()
