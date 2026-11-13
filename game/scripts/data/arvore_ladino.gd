class_name ArvoreLadino
extends RefCounted
## Árvore de habilidades do Ladino: a tabela que ArvoreData lê. Cada classe tem o seu
## arquivo, para quem mexe numa classe não mexer nas linhas das outras.
##
## Cada nó: [id, nome, descrição, ícone, ESTADO] (as iniciais têm ainda os ramos que abrem).
## ESTADO: "" = funciona inteiro;  P ("-") = efeito pendente;  outro texto = o que ainda falta.
## Quando o efeito ficar pronto, troque o ESTADO para "" (e, se for ativa, crie o .tres em
## res://data/habilidades/<id>.tres).

const P := "-"  # efeito pendente

const DADOS := {
	passivas = [
		[&"pelas_costas", "Pelas costas", "Sempre +50% de dano em golpes pelas costas.", "forca", ""],
		[&"passos_de_gato", "Passos de gato", "Os inimigos só te notam quando você chega 30% mais perto.", "agilidade", ""],
		[&"dedos_leves", "Dedos leves", "Inimigos e animais deixam 1 item a mais; abre os baús trancados da ilha sem chave.", "agilidade", ""],
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
			[&"emboscada", "Emboscada", "O primeiro golpe depois de sair da fumaça é sempre crítico (dano dobrado).", "forca", ""],
			[&"sumir", "Sumir", "Fica invisível por 4 s (atacar quebra o efeito).", "", ""],
			[&"passo_das_sombras", "Passo das sombras", "Teleporta para as costas do alvo e golpeia (vale o Pelas costas).", "", ""],
			[&"execucao", "Execução", "+100% de dano em inimigo com menos de 30% de vida.", "forca", ""],
			[&"marca_da_morte", "Marca da morte", "Finalizador: marca o alvo por 4 s; depois explode com parte do dano que ele levou (mais pontos, mais forte).", "", ""],
			[&"mil_cortes", "Mil cortes", "Suprema. Você fica intocável e golpeia 8 vezes todos os inimigos em volta.", "", ""],
		]],
		[&"venenos", "Venenos", [
			[&"toxina", "Toxina", "O Veneno acumula até 5 vezes.", "intelecto", ""],
			[&"frasco_de_acido", "Frasco de ácido", "Uma poça que corrói; quem está dentro toma +20% de dano.", "", ""],
			[&"nuvem_toxica", "Nuvem tóxica", "Uma nuvem que envenena por 6 s; se pegar fogo, explode.", "", ""],
			[&"contagio", "Contágio", "Inimigo envenenado que morre passa o veneno para os vizinhos.", "intelecto", ""],
			[&"veneno_paralisante", "Veneno paralisante", "Finalizador: o alvo envenenado fica Atordoado por 1 s por acúmulo.", "", ""],
			[&"praga", "Praga", "Suprema. Todo inimigo envenenado toma de uma vez o veneno que faltava.", "", ""],
		]],
		[&"acrobata", "Acrobata", [
			[&"ritmo", "Ritmo", "Cada dash deixa o próximo golpe mais rápido e dá +10% de velocidade por 2 s.", "agilidade", ""],
			[&"danca_das_laminas", "Dança das lâminas", "Salta entre até 4 inimigos acertando cada um.", "", ""],
			[&"bumerangue_de_adaga", "Bumerangue de adaga", "A adaga acerta na ida e na volta.", "", ""],
			[&"esquiva_perfeita", "Esquiva perfeita", "Esquivar no último instante (até 0,3 s antes do golpe) recarrega o dash e dá um crítico (o próximo golpe causa dano dobrado).", "agilidade", ""],
			[&"leque_giratorio", "Leque giratório", "Finalizador: 3 adagas por ponto de combo, em círculo.", "", ""],
			[&"tempestade_de_aco", "Tempestade de aço", "Suprema. Por 6 s, cada dash solta adagas em volta.", "", ""],
		]],
	],
}
