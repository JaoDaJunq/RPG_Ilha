class_name TextoHabilidade
extends RefCounted
## Texto da janelinha de uma habilidade (botão direito no HUD): nome, descrição, custo de
## mana, recarga, dano e os efeitos. Os números vêm dos mesmos lugares que o jogo usa
## (HabilidadeData, constantes das lógicas, do slime, da armadilha e do jogador).
## Distâncias em "blocos" (1 bloco = 1 tile = World.T pixels), que o jogador enxerga no mapa.

const ELEMENTOS := {
	&"fisico": "físico", &"fogo": "fogo", &"gelo": "gelo", &"raio": "raio",
	&"natureza": "natureza", &"sombra": "sombra", &"luz": "luz", &"quimico": "químico",
}
## O raio do Giro está escrito direto no código (Logicas.Giro), sem constante.
const RAIO_GIRO := 26.0


## Dicionário para o HUD desenhar: titulo, descricao, mana (texto), recarga (texto), dano
## (texto, vazio se não machuca) e efeitos (lista de linhas curtas).
static func de_habilidade(hab: HabilidadeData, tecla: String, ficha: Ficha) -> Dictionary:
	return {
		titulo = "%s · %s" % [tecla, hab.nome],
		descricao = hab.descricao,
		mana = "Mana: %s" % numero(hab.custo_mana),
		recarga = "Recarga: %s s" % numero(hab.recarga),
		dano = _dano(hab, ficha),
		efeitos = efeitos(hab, ficha),
	}


## O dash (Shift) não é uma HabilidadeData: vem das constantes do jogador.
static func de_esquiva(ficha: Ficha, tecla := "Shift") -> Dictionary:
	var distancia := Player.VELOCIDADE_ESQUIVA * Player.DURACAO_ESQUIVA
	return {
		titulo = "%s · Dash" % tecla,
		descricao = "Um pulo rápido de %s na direção em que você anda (parado, na direção do mouse). Dá para fugir do pulo do slime." % blocos(distancia),
		mana = "Sem custo de mana",
		recarga = "Recarga: %s s" % numero(ficha.recarga_esquiva() if ficha else 1.2),
		dano = "",
		efeitos = ["Não toma dano por %s s" % numero(Player.DURACAO_ESQUIVA + 0.1)] as Array[String],
	}


static func _dano(hab: HabilidadeData, ficha: Ficha) -> String:
	if hab.dano <= 0.0:
		return ""
	if hab.logica == &"LaminaEnvenenada":
		var por_segundo := hab.dano * (ficha.multiplicador(hab.elemento) if ficha else 1.0)
		return "Veneno: %s por segundo, por %d s (%s no total)" % [numero(por_segundo), roundi(Player.TEMPO_VENENO), numero(por_segundo * Player.TEMPO_VENENO)]
	var nome: String = ELEMENTOS.get(hab.elemento, String(hab.elemento))
	if ficha == null:
		return "Dano: %s (%s)" % [numero(hab.dano), nome]
	var mult := ficha.multiplicador(hab.elemento)
	var poder := "físico" if hab.elemento == &"fisico" else "mágico"
	var base := "%s × poder %s x%s" % [numero(hab.dano), poder, numero(mult)]
	if hab.logica == &"LequeAdagas":
		return "Dano: %s de físico por adaga (%s)" % [numero(hab.dano * mult), base]
	if hab.logica == &"LuzSagrada":
		return "Dano: %s de luz; %s em slimes da noite (%s)" % [numero(hab.dano * mult), numero(hab.dano * mult * 3.0), base]
	if hab.logica == &"TiroCarregado":
		return "Dano: %s a %s %s, conforme a carga (%s)" % [numero(hab.dano * mult), numero(hab.dano * 3.0 * mult), nome, base]
	return "Dano: %s de %s (%s)" % [numero(hab.dano * mult), nome, base]


## Efeitos em linhas curtas (atordoa, congela, prende, área, alcance, bônus).
static func efeitos(hab: HabilidadeData, ficha: Ficha = null) -> Array[String]:
	var l: Array[String] = []
	match hab.logica:
		&"Investida":
			l.append("Avança %s" % blocos(Logicas.Investida.DISTANCIA))
			l.append("Acerta tudo no caminho")
		&"Giro":
			l.append("Área: tudo num raio de %s" % blocos(RAIO_GIRO))
		&"BolaDeFogo":
			l.append("Slimes levam o dobro de dano")
			l.append("Incendeia árvores")
		&"LancaGelo":
			l.append("Congela por %s s" % numero(Slime.TEMPO_CONGELADO))
			l.append("Golpe físico no congelado: dano dobrado")
			l.append("Sobre a água, cria um caminho de gelo")
		&"TiroCarregado":
			l.append("Carga completa em %s s" % numero(Player.CARGA_MAXIMA))
			l.append("Carregado: até 3x de dano e 2x de velocidade")
		&"Armadilha":
			l.append("Prende por %s s" % numero(ArmadilhaChao.TEMPO_PRESO))
			l.append("Alcance: %s" % blocos(hab.alcance))
			l.append("No máximo 2 armadas ao mesmo tempo")
		&"Bloqueio":
			l.append("Dano recebido: -%s%%" % numero(Logicas.Bloqueio.REDUCAO * 100.0))
			l.append("Dura %s s" % numero(Logicas.Bloqueio.DURACAO))
		&"Furia":
			l.append("Dano físico: +%s%%" % numero((Player.BONUS_FURIA_DANO - 1.0) * 100.0))
			l.append("Velocidade: +%s%%" % numero((Player.BONUS_FURIA_VELOCIDADE - 1.0) * 100.0))
			l.append("Dura %s s" % numero(Logicas.Furia.DURACAO))
		&"Raio":
			l.append("Atordoa por %s s" % numero(Logicas.Raio.ATORDOAR))
			l.append("Alcance: %s" % blocos(Logicas.Raio.ALCANCE_MAGO))
		&"NovaGelo":
			l.append("Congela por %s s" % numero(Slime.TEMPO_CONGELADO))
			l.append("Área: tudo num raio de %s" % blocos(Logicas.NovaGelo.RAIO))
		&"ChuvaFlechas":
			l.append("Alcance: %s" % blocos(hab.alcance))
			l.append("Área: raio de %s" % blocos(Logicas.ChuvaFlechas.RAIO))
			l.append("%d flechas, caem após %s s" % [Logicas.ChuvaFlechas.FLECHAS, numero(Logicas.ChuvaFlechas.ATRASO)])
		&"Bomba":
			l.append("Explode ao bater ou após %s s" % numero(Logicas.Bomba.TEMPO))
			l.append("Área: raio de %s" % blocos(Logicas.Bomba.RAIO))
			l.append("Slimes levam o dobro de dano")
			l.append("Incendeia árvores")
		&"GolpeFurtivo":
			l.append("Avança até o inimigo (alcance: %s)" % blocos(hab.alcance))
			l.append("Dano dobrado se ele não perseguia você (x%s)" % numero(Logicas.GolpeFurtivo.MULTIPLICADOR))
		&"LaminaEnvenenada":
			l.append("Seus golpes envenenam por %d s" % roundi(Player.TEMPO_VENENO))
			l.append("Dura %s s" % numero(Logicas.LaminaEnvenenada.DURACAO))
		&"BombaFumaca":
			l.append("Inimigos perdem você de vista e param de perseguir")
			l.append("Você fica meio transparente")
			l.append("Dura %s s" % numero(Logicas.BombaFumaca.DURACAO))
		&"LequeAdagas":
			l.append("%d adagas em leque" % Logicas.LequeAdagas.ADAGAS)
		&"Cura":
			var vida := Logicas.Cura.quantidade(ficha) if ficha else Logicas.Cura.BASE
			l.append("Cura %s de vida (%s + %s por ponto de Espírito)" % [numero(vida), numero(Logicas.Cura.BASE), numero(Logicas.Cura.POR_ESPIRITO)])
			l.append("Área: aliados num raio de %s" % blocos(Logicas.Cura.RAIO))
		&"EscudoSagrado":
			l.append("Dano recebido: -%s%%" % numero(Logicas.EscudoSagrado.REDUCAO * 100.0))
			l.append("Dura %s s" % numero(Logicas.EscudoSagrado.DURACAO))
			l.append("Área: aliados num raio de %s" % blocos(Logicas.EscudoSagrado.RAIO))
		&"LuzSagrada":
			l.append("Área: tudo num raio de %s" % blocos(Logicas.LuzSagrada.RAIO))
			l.append("Slimes da noite levam o triplo de dano")
		&"Bencao":
			l.append("Recupera %s de vida por segundo" % numero(Logicas.Bencao.VIDA_POR_SEGUNDO))
			l.append("Dura %s s" % numero(Logicas.Bencao.DURACAO))
			l.append("Área: aliados num raio de %s" % blocos(Logicas.Bencao.RAIO))
		&"Piscar":
			l.append("Teleporta %s" % blocos(hab.alcance))
		&"Cambalhota":
			l.append("Avança %s" % blocos(hab.alcance))
			l.append("O dash (Shift) fica pronto na hora")
	if l.is_empty():
		# Lógicas da árvore (logicas_<classe>.gd): a própria lógica escreve as linhas.
		var classe := Logicas.classe_da_logica(hab.logica)
		var logica: Object = classe.new() if classe else null
		if logica and logica.has_method(&"linhas_efeito"):
			l.append_array(logica.linhas_efeito(hab))
	return l


## 2,5 · 3 · 0,95 (vírgula, sem zeros sobrando).
static func numero(x: float) -> String:
	var s := ("%.2f" % x).rstrip("0").rstrip(".")
	return s.replace(".", ",")


static func blocos(pixels: float) -> String:
	var n := pixels / float(World.T)
	return "%s %s" % [numero(snappedf(n, 0.1)), "bloco" if absf(n - 1.0) < 0.05 else "blocos"]
