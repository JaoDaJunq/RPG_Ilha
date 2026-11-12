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
		[&"rastreador", "Rastreador", "Acerta animais com dano dobrado (caça mais fácil) e, a cada 5 s, vê as pegadas (poeira) dos animais a até 10 blocos.", "forca", ""],
	],
	iniciais = [
		[&"tiro_carregado", "Tiro carregado", "Quanto mais segura, mais forte e mais longe.", "", "", [&"atirador"]],
		[&"armadilha", "Armadilha", "Uma armadilha que prende quem pisar.", "", "", [&"engenhoqueiro"]],
		[&"chuva_flechas", "Chuva de flechas", "Flechas caem numa área.", "", "", [&"atirador"]],
		[&"bomba", "Bomba", "Explode ao bater; queima árvores.", "", "", [&"engenhoqueiro"]],
		[&"assobio", "Assobio", "Chama um falcão que bica um inimigo e o deixa Marcado por 5 s.", "", "", [&"domador"]],
	],
	ramos = [
		[&"atirador", "Atirador", [
			[&"ponto_fraco", "Ponto fraco", "Acertos a mais de 6 blocos dão +25% de dano.", "forca", ""],
			[&"flecha_perfurante", "Flecha perfurante", "Atravessa todos os inimigos em linha.", "", ""],
			[&"marca_do_cacador", "Marca do caçador", "O alvo marcado toma +20% de dano de todo mundo.", "", ""],
			[&"sangue_frio", "Sangue frio", "Cada acerto crítico (de mais de 6 blocos ou num alvo Marcado) devolve 3 de mana.", "espirito", ""],
			[&"rajada", "Rajada", "3 flechas seguidas, sem precisar carregar.", "", ""],
			[&"flecha_do_horizonte", "Flecha do horizonte", "Suprema. Uma flecha gigante atravessa a tela inteira.", "", ""],
		]],
		[&"engenhoqueiro", "Engenhoqueiro", [
			[&"engenhoso", "Engenhoso", "Armadilhas e bombas gastam 30% menos mana, e você pode ter 3 armadilhas.", "intelecto", ""],
			[&"rede", "Rede", "Atira uma rede: o primeiro inimigo acertado fica preso por 3 s.", "", ""],
			[&"mina_de_fogo", "Mina de fogo", "Explode quando alguém pisa e deixa Queimadura.", "", ""],
			[&"reaproveitar", "Reaproveitar", "Passar por cima de uma armadilha ou mina sua que não disparou (armada há 1,5 s) a recolhe e devolve a mana.", "espirito", ""],
			[&"torre_de_besta", "Torre de besta", "Uma torreta que atira sozinha por 12 s.", "", ""],
			[&"campo_minado", "Campo minado", "Suprema. Espalha 6 minas em volta de você de uma vez.", "", ""],
		]],
		[&"domador", "Domador", [
			[&"laco", "Laço", "O falcão te acompanha sempre e bica quem você acertar.", "agilidade", ""],
			[&"domar", "Domar", "Um animal da ilha com metade da vida ou menos vira seu companheiro (um por vez).", "", ""],
			[&"ataque", "Ataque!", "O companheiro pula no alvo e o prende por 1,5 s.", "", ""],
			[&"matilha", "Matilha", "Com o companheiro perto, você e ele ganham +15% de velocidade e de dano.", "agilidade", ""],
			[&"estouro_da_boiada", "Estouro da boiada", "Uma manada de javalis atravessa 9 blocos derrubando tudo no caminho.", "", ""],
			[&"espirito_da_fera", "Espírito da fera", "Suprema. Por 10 s você corre 50% mais rápido e cada flecha salta para mais um inimigo.", "", ""],
		]],
	],
}
