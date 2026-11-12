class_name ArvoreData
extends RefCounted
## A árvore de habilidades de cada classe (design/arvore_habilidades.md, versão 2).
##
## Como funciona:
##   - 3 passivas da classe, ligadas desde o nível 1 (sem ponto);
##   - 5 iniciais: as 2 primeiras vêm com a classe; as outras 3 custam 1 ponto (nível 2+);
##   - nível 5: escolhe UM ramo. O ramo segue a ordem passiva de entrada (5), habilidade (6),
##     habilidade (8), passiva de mestre (10), habilidade (12) e suprema (15). A entrada pede
##     uma das iniciais que levam ao ramo; cada passo seguinte pede o anterior;
##   - pontos que sobram melhoram uma habilidade aprendida (até 3 vezes).
##
## Na tabela, o último campo de cada nó diz o quanto ele já funciona no jogo:
##   ""  = funciona inteiro;  "-" = efeito pendente;  outro texto = o que ainda falta.
## Ícone: nome curto de res://assets/sprites/tiny/icones/icone_<nome>.png; vazio usa o da
## habilidade que já existe (res://data/habilidades/<id>.tres). As novas sem arte usam a
## estrela (icone_experiencia) como marcador neutro.

const PASTA_ICONES := "res://assets/sprites/tiny/icones/icone_%s.png"
const PASTA_HABILIDADES := "res://data/habilidades/%s.tres"
const ICONE_NEUTRO := "experiencia"
## Níveis e tipos dos 6 passos de cada ramo.
const NIVEIS_RAMO: Array[int] = [5, 6, 8, 10, 12, 15]
const TIPOS_RAMO := [
	NoArvore.Tipo.PASSIVA, NoArvore.Tipo.ATIVA, NoArvore.Tipo.ATIVA,
	NoArvore.Tipo.PASSIVA, NoArvore.Tipo.ATIVA, NoArvore.Tipo.ATIVA,
]
const NIVEL_INICIAIS := 2

const P := "-"  # efeito pendente

const TABELA := {
	&"guerreiro": {
		passivas = [
			[&"pele_de_ferro", "Pele de ferro", "10% menos dano físico. Empurrões te movem a metade.", "vitalidade", ""],
			[&"folego_de_batalha", "Fôlego de batalha", "Com a Fúria cheia, o próximo golpe atordoa por 1 s.", "forca", P],
			[&"braco_de_lenhador", "Braço de lenhador", "Corta árvores 20% mais rápido e carrega 20% mais madeira por pilha.", "forca", "carregar 20% mais madeira por pilha"],
		],
		iniciais = [
			[&"investida", "Investida", "Avança e empurra quem estiver no caminho.", "", "", [&"senhor_da_guerra"]],
			[&"giro", "Giro", "Gira a arma e acerta todos em volta.", "", "", [&"berserker"]],
			[&"bloqueio", "Bloqueio", "60% menos dano por 3 s.", "", "", [&"guardiao"]],
			[&"furia", "Fúria", "+50% de dano e +25% de velocidade por 5 s.", "", "", [&"berserker"]],
			[&"grito_de_guerra", "Grito de guerra", "Os inimigos em volta sentem Medo por 1,5 s; os aliados ganham +10% de dano por 6 s.", "", P, [&"senhor_da_guerra"]],
		],
		ramos = [
			[&"guardiao", "Guardião", [
				[&"muralha_viva", "Muralha viva", "Aliados atrás de você tomam 15% menos dano.", "vitalidade", ""],
				[&"escudo_arremessado", "Escudo arremessado", "O escudo quica em até 3 inimigos e atordoa cada um por 0,5 s.", "", P],
				[&"provocar", "Provocar", "Puxa a atenção de todos os inimigos em volta para você por 4 s.", "", P],
				[&"contra_golpe", "Contra-golpe", "Bloquear no instante certo devolve metade do dano ao atacante.", "forca", P],
				[&"bastiao", "Bastião", "Finca o escudo no chão: uma cúpula para todos os projéteis por 5 s.", "", P],
				[&"juramento", "Juramento", "Suprema. Por 8 s, metade do dano dos aliados perto vem para você, e você não cai abaixo de 1 de vida.", "", P],
			]],
			[&"berserker", "Berserker", [
				[&"sangue_quente", "Sangue quente", "Quanto menos vida, mais dano, até +40%.", "forca", ""],
				[&"machadada", "Machadada", "Golpe pesado em área. Derruba árvore e quebra pedra num golpe só.", "", P],
				[&"salto_esmagador", "Salto esmagador", "Pula até a mira; a onda de choque derruba os inimigos em volta.", "", P],
				[&"sede", "Sede", "Cada inimigo derrotado cura 5% da vida.", "vitalidade", ""],
				[&"redemoinho", "Redemoinho", "Gira por 3 s enquanto anda, acertando tudo.", "", P],
				[&"furia_titanica", "Fúria titânica", "Suprema. Por 10 s o guerreiro cresce, não pode ser empurrado e todo golpe vira golpe em área.", "", P],
			]],
			[&"senhor_da_guerra", "Senhor da Guerra", [
				[&"comando", "Comando", "Aliados perto andam 5% mais rápido.", "agilidade", ""],
				[&"estandarte", "Estandarte", "Finca uma bandeira: na área, os aliados dão +15% de dano e recuperam vida aos poucos.", "", P],
				[&"corrente", "Corrente", "Lança uma corrente que puxa um inimigo até você.", "", P],
				[&"veterano", "Veterano", "Recarga 10% menor por aliado perto (até 30%).", "agilidade", ""],
				[&"ordem_de_ataque", "Ordem de ataque", "Marca um inimigo: todos os aliados dão +30% de dano nele.", "", P],
				[&"avancar", "Avançar!", "Suprema. Você e os aliados perto fazem uma investida juntos, atravessando os inimigos.", "", P],
			]],
		],
	},
	&"mago": {
		passivas = [
			[&"fluxo_arcano", "Fluxo arcano", "A mana volta 25% mais rápido.", "espirito", ""],
			[&"ressonancia", "Ressonância", "Usar um elemento diferente do último dá +15% de dano.", "intelecto", ""],
			[&"faisca", "Faísca", "Acende fogueira e tocha sem gastar graveto; à noite, o mago brilha um pouco.", "intelecto", P],
		],
		iniciais = [
			[&"bola_de_fogo", "Bola de fogo", "Projétil de fogo (acende árvores).", "", "", [&"fogo"]],
			[&"lanca_gelo", "Lança de gelo", "Projétil que congela; sobre a água, faz caminho de gelo.", "", "", [&"gelo"]],
			[&"raio", "Raio", "Cai no inimigo mais perto da mira e o atordoa.", "", "", [&"raio_ramo"]],
			[&"pedra_viva", "Pedra viva", "Uma pedra rola até a mira e deixa os atingidos em Desequilíbrio.", "", P, [&"terra"]],
			[&"piscar", "Piscar", "Teleporte curto de 4 blocos na direção da mira. Útil em todo ramo.", "", "", [&"fogo", &"gelo", &"raio_ramo", &"terra"]],
		],
		ramos = [
			[&"fogo", "Fogo", [
				[&"combustao", "Combustão", "A Queimadura dura +2 s e passa para os inimigos colados.", "intelecto", P],
				[&"rastro_de_chamas", "Rastro de chamas", "Por 4 s, o chão por onde você anda pega fogo.", "", P],
				[&"mini_explosao", "Mini explosão", "Uma brasa que explode depois de 1 s, empurrando e queimando em área.", "", P],
				[&"cinzas", "Cinzas", "Inimigo que morre queimando explode.", "intelecto", P],
				[&"tornado_de_fogo", "Tornado de fogo", "Um redemoinho anda até a mira puxando os inimigos para dentro.", "", P],
				[&"chuva_de_meteoros", "Chuva de meteoros", "Suprema. Meteoros caem numa área grande por 5 s.", "", P],
			]],
			[&"gelo", "Gelo", [
				[&"frio_que_morde", "Frio que morde", "Inimigos com Lentidão também dão 15% menos dano.", "intelecto", P],
				[&"nova_gelo", "Nova de gelo", "Congela tudo em volta.", "", ""],
				[&"muralha_de_gelo", "Muralha de gelo", "Uma parede que fecha o caminho; sobre a água, vira ponte.", "", P],
				[&"estilhacar", "Estilhaçar", "Golpe físico em inimigo Congelado também acerta os vizinhos.", "forca", ""],
				[&"prisao_de_gelo", "Prisão de gelo", "Congela um inimigo forte por 4 s.", "", P],
				[&"nevasca", "Nevasca", "Suprema. Área grande por 6 s; quem fica dentro vai ficando lento até congelar.", "", P],
			]],
			[&"raio_ramo", "Raio", [
				[&"conducao", "Condução", "O Raio salta para mais 1 inimigo perto do alvo.", "intelecto", "saltar para mais 2 em alvo molhado"],
				[&"corrente_eletrica", "Corrente elétrica", "Um choque que pula entre até 5 inimigos.", "", P],
				[&"totem_tesla", "Totem tesla", "Uma torre que dá choque nos inimigos perto por 8 s.", "", P],
				[&"sobrecarga", "Sobrecarga", "A cada 4 feitiços, o próximo sai sem gastar mana.", "espirito", ""],
				[&"forma_de_relampago", "Forma de relâmpago", "Você vira raio e atravessa até a mira, ferindo quem estiver no caminho.", "", P],
				[&"tempestade", "Tempestade", "Suprema. Por 8 s, raios caem sozinhos nos inimigos perto.", "", P],
			]],
			[&"terra", "Terra", [
				[&"raizes", "Raízes", "Parado por 1 s, você toma 20% menos dano.", "vitalidade", ""],
				[&"espinhos", "Espinhos", "Estacas saem do chão e prendem quem está em cima por 1,5 s.", "", P],
				[&"golem_de_pedra", "Golem de pedra", "Invoca um golem por 15 s que chama os inimigos e dá socos.", "", P],
				[&"tremor", "Tremor", "Feitiços de terra têm 20% de chance de derrubar o alvo.", "forca", P],
				[&"fenda", "Fenda", "Uma rachadura em linha que derruba e desequilibra.", "", P],
				[&"despertar_da_ilha", "Despertar da ilha", "Suprema. A ilha treme por 8 s: inimigos erram metade dos ataques e ficam lentos.", "", P],
			]],
		],
	},
	&"arqueiro": {
		passivas = [
			[&"mao_leve", "Mão leve", "Puxa o arco 30% mais rápido e o tiro sai 15% mais rápido.", "agilidade", ""],
			[&"olho_de_aguia", "Olho de águia", "+20% de alcance em todos os tiros.", "agilidade", ""],
			[&"rastreador", "Rastreador", "Acerta animais com dano dobrado (caça mais fácil) e vê pegadas perto.", "forca", "ver pegadas de animais"],
		],
		iniciais = [
			[&"tiro_carregado", "Tiro carregado", "Quanto mais segura, mais forte e mais longe.", "", "", [&"atirador"]],
			[&"armadilha", "Armadilha", "Uma armadilha que prende quem pisar.", "", "", [&"engenhoqueiro"]],
			[&"chuva_flechas", "Chuva de flechas", "Flechas caem numa área.", "", "", [&"atirador"]],
			[&"bomba", "Bomba", "Explode ao bater; queima árvores.", "", "", [&"engenhoqueiro"]],
			[&"assobio", "Assobio", "Chama um falcão que bica um inimigo e o deixa Marcado por 5 s.", "", P, [&"domador"]],
		],
		ramos = [
			[&"atirador", "Atirador", [
				[&"ponto_fraco", "Ponto fraco", "Acertos a mais de 6 blocos dão +25% de dano.", "forca", ""],
				[&"flecha_perfurante", "Flecha perfurante", "Atravessa todos os inimigos em linha.", "", P],
				[&"marca_do_cacador", "Marca do caçador", "O alvo marcado toma +20% de dano de todo mundo.", "", P],
				[&"sangue_frio", "Sangue frio", "Cada acerto crítico devolve 3 de mana.", "espirito", P],
				[&"rajada", "Rajada", "3 flechas seguidas, sem precisar carregar.", "", P],
				[&"flecha_do_horizonte", "Flecha do horizonte", "Suprema. Uma flecha gigante atravessa a tela inteira.", "", P],
			]],
			[&"engenhoqueiro", "Engenhoqueiro", [
				[&"engenhoso", "Engenhoso", "Armadilhas e bombas gastam 30% menos mana, e você pode ter 3 armadilhas.", "intelecto", ""],
				[&"rede", "Rede", "Uma rede que prende o alvo por 3 s.", "", P],
				[&"mina_de_fogo", "Mina de fogo", "Explode quando alguém pisa e deixa Queimadura.", "", P],
				[&"reaproveitar", "Reaproveitar", "Recolher uma armadilha que não disparou devolve a mana.", "espirito", P],
				[&"torre_de_besta", "Torre de besta", "Uma torreta que atira sozinha por 12 s.", "", P],
				[&"campo_minado", "Campo minado", "Suprema. Espalha 6 minas em volta de você de uma vez.", "", P],
			]],
			[&"domador", "Domador", [
				[&"laco", "Laço", "O falcão te acompanha sempre e bica quem você acertar.", "agilidade", P],
				[&"domar", "Domar", "Um animal da ilha com pouca vida vira seu companheiro.", "", P],
				[&"ataque", "Ataque!", "O companheiro pula no alvo e o prende por 1,5 s.", "", P],
				[&"matilha", "Matilha", "Com o companheiro perto, você e ele ganham +15% de velocidade e de dano.", "agilidade", P],
				[&"estouro_da_boiada", "Estouro da boiada", "Uma manada atravessa a área derrubando tudo.", "", P],
				[&"espirito_da_fera", "Espírito da fera", "Suprema. Por 10 s você corre muito mais e cada flecha salta para mais um inimigo.", "", P],
			]],
		],
	},
	&"ladino": {
		passivas = [
			[&"pelas_costas", "Pelas costas", "Sempre +50% de dano em golpes pelas costas.", "forca", ""],
			[&"passos_de_gato", "Passos de gato", "Os inimigos só te notam quando você chega 30% mais perto.", "agilidade", ""],
			[&"dedos_leves", "Dedos leves", "Animais e slimes deixam 1 item a mais; abre baús trancados.", "agilidade", "abrir baús trancados (ainda não existem)"],
		],
		iniciais = [
			[&"golpe_furtivo", "Golpe furtivo", "Avança até o alvo; dano dobrado se ele não te via.", "", "", [&"sombra"]],
			[&"leque_adagas", "Leque de adagas", "3 adagas em leque.", "", "", [&"acrobata"]],
			[&"lamina_envenenada", "Lâmina envenenada", "Por 6 s, seus golpes causam Veneno.", "", "", [&"venenos"]],
			[&"bomba_fumaca", "Bomba de fumaça", "Por 3 s, os inimigos perdem você de vista.", "", "", [&"sombra"]],
			[&"cambalhota", "Cambalhota", "Um dash na direção da mira que libera outro dash na hora, para mudar de direção.", "", "", [&"acrobata"]],
		],
		ramos = [
			[&"sombra", "Sombra", [
				[&"emboscada", "Emboscada", "O primeiro golpe depois de sair da fumaça é crítico (dano dobrado).", "forca", ""],
				[&"sumir", "Sumir", "Fica invisível por 4 s enquanto anda (atacar quebra o efeito).", "", P],
				[&"passo_das_sombras", "Passo das sombras", "Teleporta para as costas do alvo.", "", P],
				[&"execucao", "Execução", "+100% de dano em inimigo com menos de 30% de vida.", "forca", ""],
				[&"marca_da_morte", "Marca da morte", "Finalizador: depois de 4 s, a marca explode com parte do dano que o alvo levou.", "", P],
				[&"mil_cortes", "Mil cortes", "Suprema. Você fica intocável e golpeia 8 vezes todos os inimigos em volta.", "", P],
			]],
			[&"venenos", "Venenos", [
				[&"toxina", "Toxina", "O Veneno acumula até 5 vezes.", "intelecto", P],
				[&"frasco_de_acido", "Frasco de ácido", "Uma poça que corrói; quem está dentro toma +20% de dano.", "", P],
				[&"nuvem_toxica", "Nuvem tóxica", "Uma nuvem verde que envenena por 6 s; se pegar fogo, explode.", "", P],
				[&"contagio", "Contágio", "Inimigo envenenado que morre passa o veneno para os vizinhos.", "intelecto", ""],
				[&"veneno_paralisante", "Veneno paralisante", "Finalizador: o alvo envenenado fica Atordoado por 1 s por acúmulo.", "", P],
				[&"praga", "Praga", "Suprema. Todo inimigo envenenado toma de uma vez o veneno que faltava.", "", P],
			]],
			[&"acrobata", "Acrobata", [
				[&"ritmo", "Ritmo", "Cada dash deixa o próximo golpe mais rápido e dá +10% de velocidade por 2 s.", "agilidade", ""],
				[&"danca_das_laminas", "Dança das lâminas", "Salta entre até 4 inimigos acertando cada um.", "", P],
				[&"bumerangue_de_adaga", "Bumerangue de adaga", "A adaga acerta na ida e na volta.", "", P],
				[&"esquiva_perfeita", "Esquiva perfeita", "Esquivar no último instante recarrega o dash e dá um crítico.", "agilidade", P],
				[&"leque_giratorio", "Leque giratório", "Finalizador: 3 adagas por ponto de combo, em círculo.", "", P],
				[&"tempestade_de_aco", "Tempestade de aço", "Suprema. Por 6 s, cada dash solta adagas em volta.", "", P],
			]],
		],
	},
	&"clerigo": {
		passivas = [
			[&"aura_serena", "Aura serena", "Você e os aliados perto recuperam 1 de vida a cada 3 s.", "vitalidade", ""],
			[&"fe", "Fé", "A cura que passaria da vida máxima vira escudo por 5 s.", "espirito", ""],
			[&"luz_propria", "Luz própria", "Os slimes da noite evitam chegar perto de você; a comida que você dá cura 50% a mais.", "espirito", "a comida curar 50% a mais"],
		],
		iniciais = [
			[&"cura", "Cura", "Cura você e os aliados em volta.", "", "", [&"curandeiro"]],
			[&"luz_sagrada", "Luz sagrada", "Dano de luz em volta; o triplo nos slimes da noite.", "", "", [&"inquisidor"]],
			[&"escudo_sagrado", "Escudo sagrado", "Você e os aliados perto tomam 50% menos dano por 4 s.", "", "", [&"protetor"]],
			[&"bencao", "Bênção", "Os aliados em volta regeneram vida por 8 s.", "", "", [&"curandeiro"]],
			[&"martelo_da_justica", "Martelo da justiça", "Arremessa um martelo de luz que Atordoa e volta para a mão.", "", P, [&"inquisidor"]],
		],
		ramos = [
			[&"curandeiro", "Curandeiro", [
				[&"maos_que_curam", "Mãos que curam", "Curas +25%; também tiram Veneno e Queimadura.", "vitalidade", "tirar Veneno e Queimadura (jogadores ainda não pegam esses efeitos)"],
				[&"circulo_de_cura", "Círculo de cura", "Uma área no chão que cura por 6 s.", "", P],
				[&"elo_vital", "Elo vital", "Liga você a um aliado: vocês dividem o dano e toda cura vale para os dois.", "", P],
				[&"ultimo_suspiro", "Último suspiro", "O aliado perto que cairia fica com 1 de vida (uma vez por minuto).", "vitalidade", ""],
				[&"levantar", "Levantar", "Traz de volta um aliado caído.", "", P],
				[&"fonte_da_vida", "Fonte da vida", "Suprema. Área grande que cura todo mundo e limpa os efeitos ruins por 8 s.", "", P],
			]],
			[&"protetor", "Protetor", [
				[&"egide", "Égide", "Seus escudos ficam 30% mais fortes.", "vitalidade", ""],
				[&"barreira", "Barreira", "Uma parede de luz que para os projéteis por 6 s.", "", P],
				[&"santuario", "Santuário", "Área onde os inimigos não conseguem entrar por 4 s.", "", P],
				[&"vigilia", "Vigília", "Um aliado com pouca vida perto de você toma 15% menos dano.", "vitalidade", ""],
				[&"intervencao", "Intervenção", "Um aliado fica intocável por 2 s.", "", P],
				[&"muralha_da_fe", "Muralha da fé", "Suprema. Uma cúpula grande onde ninguém toma dano por 4 s.", "", P],
			]],
			[&"inquisidor", "Inquisidor", [
				[&"fogo_sagrado", "Fogo sagrado", "O dano de luz dá +50% contra criaturas da noite e causa Queimadura.", "intelecto", "causar Queimadura"],
				[&"coluna_de_luz", "Coluna de luz", "Um raio de luz cai do céu num ponto.", "", P],
				[&"martelo_giratorio", "Martelo giratório", "O martelo gira em volta de você por 5 s.", "", P],
				[&"julgamento", "Julgamento", "Inimigos acertados pela luz tomam +15% de dano de todo mundo por 5 s.", "intelecto", ""],
				[&"aurora", "Aurora", "Um cone de luz que derrete os slimes da noite e cega os outros.", "", P],
				[&"amanhecer", "Amanhecer", "Suprema. Por 10 s, a área em volta vira dia.", "", P],
			]],
		],
	},
}

static var _cache: Dictionary = {}  # classe → Array[NoArvore]


## Todos os nós da classe, na ordem das colunas (classe, iniciais, ramos).
static func nos(classe_id: StringName) -> Array[NoArvore]:
	if _cache.has(classe_id):
		return _cache[classe_id]
	var lista: Array[NoArvore] = []
	var dados: Dictionary = TABELA.get(classe_id, {})
	if dados.is_empty():
		return lista
	var k := 0
	for linha in dados.passivas:
		var n := _no(linha, NoArvore.Tipo.PASSIVA, NoArvore.RAMO_CLASSE, k)
		n.padrao = true
		n.custo = 0
		lista.append(n)
		k += 1
	k = 0
	for linha in dados.iniciais:
		var n := _no(linha, NoArvore.Tipo.ATIVA, NoArvore.RAMO_INICIAIS, k)
		n.padrao = k < 2
		n.custo = 0 if n.padrao else 1
		n.nivel = 1 if n.padrao else NIVEL_INICIAIS
		for r in linha[5]:
			n.leva_a.append(r)
		lista.append(n)
		k += 1
	for ramo in dados.ramos:
		var anterior: NoArvore = null
		for e in ramo[2].size():
			var n := _no(ramo[2][e], TIPOS_RAMO[e], ramo[0], e)
			n.nivel = NIVEIS_RAMO[e]
			if anterior:
				n.requisitos.append(anterior.id)
			else:
				for ini in dados.iniciais:
					if ramo[0] in ini[5]:
						n.algum_de.append(ini[0])
			lista.append(n)
			anterior = n
	_cache[classe_id] = lista
	return lista


static func no(classe_id: StringName, no_id: StringName) -> NoArvore:
	if not _indice.has(classe_id):
		var d := {}
		for n in nos(classe_id):
			d[n.id] = n
		_indice[classe_id] = d
	return _indice[classe_id].get(no_id)


## Ramos da classe: [[id, nome], ...].
static func ramos(classe_id: StringName) -> Array:
	var l := []
	for r in TABELA.get(classe_id, {}).get("ramos", []):
		l.append([r[0], r[1]])
	return l


static func nome_ramo(classe_id: StringName, ramo_id: StringName) -> String:
	if ramo_id == NoArvore.RAMO_CLASSE:
		return "Da classe"
	if ramo_id == NoArvore.RAMO_INICIAIS:
		return "Iniciais"
	for r in ramos(classe_id):
		if r[0] == ramo_id:
			return r[1]
	return String(ramo_id)


static var _padrao: Dictionary = {}  # classe → Array[StringName]
static var _indice: Dictionary = {}  # classe → {id: NoArvore}


## Ids das habilidades que já vêm com a classe (as 2 primeiras iniciais).
static func padrao(classe_id: StringName) -> Array[StringName]:
	if not _padrao.has(classe_id):
		var l: Array[StringName] = []
		for n in nos(classe_id):
			if n.padrao and n.ativa():
				l.append(n.id)
		_padrao[classe_id] = l
	return _padrao[classe_id]


## O nó vem com a classe (passivas da classe e as 2 habilidades padrão)?
static func eh_padrao(classe_id: StringName, no_id: StringName) -> bool:
	var n := no(classe_id, no_id)
	return n != null and n.padrao


static func _no(linha: Array, tipo: NoArvore.Tipo, ramo: StringName, etapa: int) -> NoArvore:
	var n := NoArvore.new()
	n.id = linha[0]
	n.nome = linha[1]
	n.descricao = linha[2]
	n.tipo = tipo
	n.ramo = ramo
	n.etapa = etapa
	var estado: String = linha[4]
	n.pendente = estado == P
	n.falta = "" if estado == P else estado
	if tipo == NoArvore.Tipo.ATIVA and not n.pendente and ResourceLoader.exists(PASTA_HABILIDADES % n.id):
		n.habilidade = load(PASTA_HABILIDADES % n.id) as HabilidadeData
	var icone: String = linha[3]
	if icone == "" and n.habilidade and n.habilidade.icone:
		n.icone = n.habilidade.icone
	else:
		n.icone = load(PASTA_ICONES % (icone if icone != "" else ICONE_NEUTRO)) as Texture2D
	return n
