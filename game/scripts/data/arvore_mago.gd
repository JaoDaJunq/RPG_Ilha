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
		[&"faisca", "Faísca", "À noite, o mago brilha: a luz dele fica maior e afasta os slimes da noite de perto (1,5 bloco).", "intelecto", ""],
	],
	iniciais = [
		[&"bola_de_fogo", "Bola de fogo", "Projétil de fogo (acende árvores).", "", "", [&"fogo"]],
		[&"lanca_gelo", "Lança de gelo", "Projétil que congela; sobre a água, faz caminho de gelo.", "", "", [&"gelo"]],
		[&"raio", "Raio", "Cai no inimigo mais perto da mira e o atordoa.", "", "", [&"raio_ramo"]],
		[&"pedra_viva", "Pedra viva", "Uma pedra rola até a mira e deixa os atingidos em Desequilíbrio (30% de chance de errar por 4 s).", "", "", [&"terra"]],
		[&"piscar", "Piscar", "Teleporte curto de 4 blocos na direção da mira. Útil em todo ramo.", "", "", [&"fogo", &"gelo", &"raio_ramo", &"terra"]],
	],
	ramos = [
		[&"fogo", "Fogo", [
			[&"combustao", "Combustão", "Seus acertos de fogo deixam Queimadura por 6 s (+2 s) e ela passa para os inimigos colados.", "intelecto", ""],
			[&"rastro_de_chamas", "Rastro de chamas", "Por 4 s, o chão por onde você anda pega fogo.", "", ""],
			[&"mini_explosao", "Mini explosão", "Uma brasa que explode depois de 1 s, empurrando e queimando em área.", "", ""],
			[&"cinzas", "Cinzas", "Inimigo que morre queimando explode.", "intelecto", ""],
			[&"tornado_de_fogo", "Tornado de fogo", "Um redemoinho anda até a mira puxando os inimigos para dentro.", "", ""],
			[&"chuva_de_meteoros", "Chuva de meteoros", "Suprema. Meteoros caem numa área grande por 5 s.", "", ""],
		]],
		[&"gelo", "Gelo", [
			[&"frio_que_morde", "Frio que morde", "Seus acertos de gelo deixam Lentidão por 3 s; inimigos com essa Lentidão dão 15% menos dano.", "intelecto", ""],
			[&"nova_gelo", "Nova de gelo", "Congela tudo em volta.", "", ""],
			[&"muralha_de_gelo", "Muralha de gelo", "Uma muralha de gelo que empurra de volta quem encosta; mirando na água, vira ponte.", "", ""],
			[&"estilhacar", "Estilhaçar", "Golpe físico em inimigo Congelado também acerta os vizinhos.", "forca", ""],
			[&"prisao_de_gelo", "Prisão de gelo", "Congela um inimigo forte por 4 s.", "", ""],
			[&"nevasca", "Nevasca", "Suprema. Área grande por 6 s; quem fica dentro vai ficando lento até congelar.", "", ""],
		]],
		[&"raio_ramo", "Raio", [
			[&"conducao", "Condução", "O Raio salta para mais 1 inimigo perto do alvo; se o alvo estiver molhado (na água ou no gelo), para mais 2.", "intelecto", ""],
			[&"corrente_eletrica", "Corrente elétrica", "Um choque que pula entre até 5 inimigos.", "", ""],
			[&"totem_tesla", "Totem tesla", "Uma torre que dá choque nos inimigos perto por 8 s.", "", ""],
			[&"sobrecarga", "Sobrecarga", "A cada 4 feitiços, o próximo sai sem gastar mana.", "espirito", ""],
			[&"forma_de_relampago", "Forma de relâmpago", "Você vira raio e atravessa até a mira, ferindo quem estiver no caminho.", "", ""],
			[&"tempestade", "Tempestade", "Suprema. Por 8 s, raios caem sozinhos nos inimigos perto.", "", ""],
		]],
		[&"terra", "Terra", [
			[&"raizes", "Raízes", "Parado por 1 s, você toma 20% menos dano.", "vitalidade", ""],
			[&"espinhos", "Espinhos", "Estacas saem do chão e prendem quem está em cima por 1,5 s.", "", ""],
			[&"golem_de_pedra", "Golem de pedra", "Invoca um golem por 15 s que chama os inimigos e dá socos.", "", ""],
			[&"tremor", "Tremor", "Feitiços de terra têm 20% de chance de derrubar o alvo.", "forca", ""],
			[&"fenda", "Fenda", "Uma rachadura em linha que derruba e desequilibra.", "", ""],
			[&"despertar_da_ilha", "Despertar da ilha", "Suprema. A ilha treme por 8 s: inimigos erram metade dos ataques e ficam lentos.", "", ""],
		]],
	],
}
