class_name ArvoreArqueiro
extends RefCounted
## Árvore de habilidades do Arqueiro: a tabela que ArvoreData lê. Cada classe tem o seu
## arquivo, para quem mexe numa classe não mexer nas linhas das outras.
##
## Cada nó: [id, nome, descrição, ícone, ESTADO] (as iniciais têm ainda os ramos que abrem).
## ESTADO: "" = funciona inteiro;  P ("-") = efeito pendente;  outro texto = o que ainda falta.
## Quando o efeito ficar pronto, troque o ESTADO para "" (e, se for ativa, crie o .tres em
## res://data/habilidades/<id>.tres).

const P := "-"  # efeito pendente

const DADOS := {
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
}
