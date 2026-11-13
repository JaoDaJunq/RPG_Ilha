class_name ArvoreClerigo
extends RefCounted
## Árvore de habilidades do Clérigo: a tabela que ArvoreData lê. Cada classe tem o seu
## arquivo, para quem mexe numa classe não mexer nas linhas das outras.
##
## Cada nó: [id, nome, descrição, ícone, ESTADO] (as iniciais têm ainda os ramos que abrem).
## ESTADO: "" = funciona inteiro;  P ("-") = efeito pendente;  outro texto = o que ainda falta.
## Quando o efeito ficar pronto, troque o ESTADO para "" (e, se for ativa, crie o .tres em
## res://data/habilidades/<id>.tres).

const P := "-"  # efeito pendente

const DADOS := {
	passivas = [
		[&"aura_serena", "Aura serena", "Você e os aliados perto recuperam 1 de vida a cada 3 s.", "vitalidade", ""],
		[&"fe", "Fé", "A cura que passaria da vida máxima vira escudo por 5 s.", "espirito", ""],
		[&"luz_propria", "Luz própria", "Os slimes da noite evitam chegar perto de você; a comida que você e os aliados perto comem cura 50% a mais.", "espirito", ""],
	],
	iniciais = [
		[&"cura", "Cura", "Cura você e os aliados em volta.", "", "", [&"curandeiro"]],
		[&"luz_sagrada", "Luz sagrada", "Dano de luz em volta; o triplo nos slimes da noite.", "", "", [&"inquisidor"]],
		[&"escudo_sagrado", "Escudo sagrado", "Você e os aliados perto tomam 50% menos dano por 4 s.", "", "", [&"protetor"]],
		[&"bencao", "Bênção", "Os aliados em volta regeneram vida por 8 s.", "", "", [&"curandeiro"]],
		[&"martelo_da_justica", "Martelo da justiça", "Arremessa um martelo de luz que Atordoa e volta para a mão.", "", "", [&"inquisidor"]],
	],
	ramos = [
		[&"curandeiro", "Curandeiro", [
			[&"maos_que_curam", "Mãos que curam", "Curas +25%; também tiram Veneno e Queimadura.", "vitalidade", ""],
			[&"circulo_de_cura", "Círculo de cura", "Uma área no chão que cura por 6 s.", "", ""],
			[&"elo_vital", "Elo vital", "Liga você a um aliado: vocês dividem o dano e toda cura vale para os dois.", "", ""],
			[&"ultimo_suspiro", "Último suspiro", "O aliado perto que cairia fica com 1 de vida (uma vez por minuto).", "vitalidade", ""],
			[&"levantar", "Levantar", "Levanta ali mesmo o aliado caído perto, com metade da vida.", "", ""],
			[&"fonte_da_vida", "Fonte da vida", "Suprema. Área grande que cura todo mundo e limpa os efeitos ruins por 8 s.", "", ""],
		]],
		[&"protetor", "Protetor", [
			[&"egide", "Égide", "Seus escudos ficam 30% mais fortes.", "vitalidade", ""],
			[&"barreira", "Barreira", "Uma parede de luz que os inimigos (e os projéteis deles) não atravessam por 6 s.", "", ""],
			[&"santuario", "Santuário", "Área onde os inimigos não conseguem entrar por 4 s.", "", ""],
			[&"vigilia", "Vigília", "Um aliado com pouca vida perto de você toma 15% menos dano.", "vitalidade", ""],
			[&"intervencao", "Intervenção", "O aliado na mira (ou você) fica intocável por 2 s.", "", ""],
			[&"muralha_da_fe", "Muralha da fé", "Suprema. Uma cúpula grande onde ninguém toma dano por 4 s.", "", ""],
		]],
		[&"inquisidor", "Inquisidor", [
			[&"fogo_sagrado", "Fogo sagrado", "O dano de luz dá +50% contra criaturas da noite e causa Queimadura.", "intelecto", ""],
			[&"coluna_de_luz", "Coluna de luz", "Um raio de luz cai do céu num ponto.", "", ""],
			[&"martelo_giratorio", "Martelo giratório", "O martelo gira em volta de você por 5 s.", "", ""],
			[&"julgamento", "Julgamento", "Inimigos acertados pela luz tomam +15% de dano de todo mundo por 5 s.", "intelecto", ""],
			[&"aurora", "Aurora", "Um cone de luz que derrete os slimes da noite e cega os outros.", "", ""],
			[&"amanhecer", "Amanhecer", "Suprema. Por 10 s, a área em volta vira dia.", "", ""],
		]],
	],
}
