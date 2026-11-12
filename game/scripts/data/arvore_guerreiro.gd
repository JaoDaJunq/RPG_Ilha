class_name ArvoreGuerreiro
extends RefCounted
## Árvore de habilidades do Guerreiro: a tabela que ArvoreData lê. Cada classe tem o seu
## arquivo, para quem mexe numa classe não mexer nas linhas das outras.
##
## Cada nó: [id, nome, descrição, ícone, ESTADO] (as iniciais têm ainda os ramos que abrem).
## ESTADO: "" = funciona inteiro;  P ("-") = efeito pendente;  outro texto = o que ainda falta.
## Quando o efeito ficar pronto, troque o ESTADO para "" (e, se for ativa, crie o .tres em
## res://data/habilidades/<id>.tres).

const P := "-"  # efeito pendente

const DADOS := {
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
}
