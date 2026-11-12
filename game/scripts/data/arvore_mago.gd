class_name ArvoreMago
extends RefCounted
## Árvore de habilidades do Mago: a tabela que ArvoreData lê. Cada classe tem o seu
## arquivo, para quem mexe numa classe não mexer nas linhas das outras.
##
## Cada nó: [id, nome, descrição, ícone, ESTADO] (as iniciais têm ainda os ramos que abrem).
## ESTADO: "" = funciona inteiro;  P ("-") = efeito pendente;  outro texto = o que ainda falta.
## Quando o efeito ficar pronto, troque o ESTADO para "" (e, se for ativa, crie o .tres em
## res://data/habilidades/<id>.tres).

const P := "-"  # efeito pendente

const DADOS := {
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
}
