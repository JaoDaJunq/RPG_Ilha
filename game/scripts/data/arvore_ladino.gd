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
}
