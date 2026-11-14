class_name FalasBrasinha
extends RefCounted
## Tudo o que o Brasinha diz e o texto das missões. Cada fala é uma lista de balões curtos
## (1 a 2 linhas cada). Onde há `%d` o número entra no lugar. O Brasinha é dramático,
## guloso e convencido, mas no fundo cuida do grupo (design/proposta_brasinha.md).

# --- Missões principais ------------------------------------------------------------------
## Capítulo 1: "O fogo que fala". `tipo`: falar, entregar, construir, matar, pedra, boss.
## `intro`: o que ele diz quando o passo começa. `fim`: o que diz quando o passo termina.
const CAP1: Array[Dictionary] = [
	{
		"id": "acordar", "tipo": "falar", "titulo": "Acorde o Brasinha",
		"objetivo": "Fale com a fogueira do acampamento (clique nela).",
		"intro": [], "fim": [
			"Ei! Você aí! Não, atrás de você. Aqui embaixo. Sim, o fogo falante.",
			"Me traz lenha antes que eu vire fumaça. Dez madeiras. Por favor. Estou sendo educado, olha.",
		],
	},
	{
		"id": "lanche", "tipo": "entregar", "itens": {"madeira": 10}, "titulo": "Lanche de fogo",
		"objetivo": "Entregue madeira ao Brasinha.",
		"intro": [], "fim": [
			"AHHH! Voltei! Sou grande de novo! Olha só essa chama!",
			"Hmm, carvalho... notas de musgo... um pouco seco. Nota 7. Você vai longe.",
			"Agora faça uma bancada. Um fogo precisa de amigos que fazem coisas.",
		],
	},
	{
		"id": "bancada", "tipo": "construir", "item": "bancada", "titulo": "Mãos à obra",
		"objetivo": "Faça uma bancada de trabalho e ponha no chão.",
		"intro": [], "fim": [
			"Uma bancada! Que trabalho bonito. Eu falaria que foi eu quem fez, mas seria mentira. Só um pouquinho.",
			"Mas, olha, estou sentindo um cheiro esquisito vindo do pântano. Podridão. Dá uma olhada nos slimes por lá?",
		],
	},
	{
		"id": "cheiro", "tipo": "matar", "qtd": 6, "titulo": "Que cheiro é esse?",
		"objetivo": "Derrote slimes (de qualquer tipo).",
		"intro": [], "fim": [
			"Seis a menos! Meu nariz de fogo agradece.",
			"Esses slimes tinham o mesmo cheiro de... espera. Traga gel deles. Cinco. Preciso cheirar de perto.",
		],
	},
	{
		"id": "geleia", "tipo": "entregar", "itens": {"gel_slime": 5}, "titulo": "Geleia estranha",
		"objetivo": "Entregue Géis de Slime ao Brasinha.",
		"intro": [], "fim": [
			"Hmm... *lambe* ...isso tem gosto de Semente! Uma Semente do Coração da Ilha!",
			"Tem uma pedra antiga no pântano que lembra coisas. Vai lá ler. Eu não vou, tenho medo de lama. Digo, estou ocupado.",
		],
	},
	{
		"id": "pedra", "tipo": "pedra", "regiao": Regioes.Id.PANTANO, "titulo": "Pedras que lembram",
		"objetivo": "Ache a pedra de lembranças no Pântano e leia (clique nela).",
		"intro": [], "fim": [
			"Então é isso. A Mãe Gosma engoliu a Semente. Que mau gosto, até pra uma gosma.",
			"Vou fazer uma Isca de Gosma. Preciso de gel, cogumelos e uma coxa de sapo. Não pergunte pra quê.",
		],
	},
	{
		"id": "isca", "tipo": "entregar", "itens": {"gel_slime": 5, "cogumelo": 3, "carne_sapo": 1},
		"titulo": "A isca", "objetivo": "Entregue ao Brasinha: gel, cogumelos e carne de sapo.",
		"dar": {"isca_gosma": 1}, "intro": [], "fim": [
			"*mexe, borbulha, cheira mal* ...pronto! A Isca de Gosma!",
			"Ponha no altar do pântano e esteja pronto. A Mãe Gosma é grande, feia e mal-educada.",
		],
	},
	{
		"id": "mae_gosma", "tipo": "boss", "titulo": "A Mãe Gosma",
		"objetivo": "Atraia a Mãe Gosma com a isca e traga a Semente de volta (em breve).",
		"intro": [], "fim": [],
	},
]

## Capítulo 2: "Raízes teimosas" (só o começo; o resto vem com os próximos guardiões).
const CAP2: Array[Dictionary] = [
	{
		"id": "tocha", "tipo": "falar", "titulo": "Raízes teimosas",
		"objetivo": "Fale com o Brasinha: ele tem um presente.",
		"intro": [], "fim": [
			"Com a Semente de volta eu tô fervendo de ideias! Toma: a Tocha do Brasinha.",
			"Leve até a muralha de raízes no vau, a leste do acampamento. Raiz não gosta de mim. É recíproco.",
		],
		"dar": {"tocha_brasinha": 1},
	},
	{
		"id": "raizes", "tipo": "levar", "item": "tocha_brasinha", "titulo": "A muralha de raízes",
		"objetivo": "Leve a Tocha do Brasinha até as raízes do vau, a leste, e chegue perto.",
		"intro": [], "fim": [
			"Ouvi daqui o *tsssss*! Raízes assadas! Abriram as Ruínas!",
			"O próximo guardião é o Golem Ancião, nas Colinas. Mas isso é uma história pra depois.",
		],
	},
	{
		"id": "golem", "tipo": "boss", "titulo": "O Golem Ancião",
		"objetivo": "O Golem Ancião espera nas Colinas (em breve).",
		"intro": [], "fim": [],
	},
]

## Quando a Semente volta (entregar_semente): é o fim do capítulo 1.
const SEMENTE_VOLTOU: Array[String] = [
	"A SEMENTE! Ela voltou! Eu vou chorar. Não, é fumaça. É fumaça nos olhos.",
	"A ponte das Colinas se consertou sozinha, olha só! E cada um de vocês ganhou um ponto de árvore. De nada!",
]

# --- Brasinha no dia a dia -------------------------------------------------------------------
const FALTA_LENHA: Array[String] = [
	"Ainda faltam %d madeiras. Estou tão fraquinho que a minha sombra me ignora.",
	"Mais %d madeiras e eu volto a ser lindo. Mais lindo.",
]
const PROGRESSO_ENTREGA := "Falta %s."
const RECEBIDO := ["Hmm! Obrigado!", "Isso! Mais um pouco!", "Nhac. Delícia. Nota 8.", "Agradeço, humano gentil e cheio de bolsos."]
const CONVERSA: Array = [
	["Hmm, carvalho... notas de musgo... um pouco seco. Nota 7."],
	["Tá escuro. Eu NÃO tô com medo. Fica perto. Por motivos de... você."],
	["Sabia que eu sou o fogo mais bonito da ilha? Não tem concorrência. Eu perguntei."],
	["Se você tiver um marshmallow... não sei o que é, mas parece bom."],
	["Fogo também precisa de carinho. Pode ser em forma de lenha."],
]
const PETISCO: Array = [
	["Isso é pra mim? Uma lenhazinha? Você não devia. Mas devia mesmo."],
	["Nhac! Contente! Fico quentinho por uns minutos. Chega mais perto."],
]
const ASSUSTADO: Array[String] = [
	"Tá escuro. Eu NÃO tô com medo. Fica perto. Por motivos de... você.",
]
const FALA_PEDRA := {
	Regioes.Id.BOSQUE: ["Ah, os Guardiões... eles faziam carinho em mim. Eu era um fogo muito amado."],
	Regioes.Id.PRAIA: ["O Coração partido em cinco? Eu estava lá. Fiz um barulho. Foi muito dramático."],
	Regioes.Id.PANTANO: ["A Mãe Gosma engolindo uma Semente. Que modos. Isso tem nome: gula."],
	Regioes.Id.COLINAS: ["O Golem Ancião... ele me devia uma lenha. Ainda me deve."],
	Regioes.Id.RUINAS: ["O Guardião Esquecido... não fala dele comigo, tá? Que dá um aperto aqui no meu pavio."],
}

## Frase curta de cada pedra de lore (o painel mostra a imagem e esta frase).
const LORE := {
	Regioes.Id.BOSQUE: "Os Guardiões plantaram o Bosque e cuidavam de cada árvore, uma por uma.",
	Regioes.Id.PRAIA: "O Coração da Ilha pulsava como o mar. Um dia ele se partiu em cinco Sementes.",
	Regioes.Id.PANTANO: "Uma gosma enorme engoliu uma das Sementes. Desde então o pântano apodrece.",
	Regioes.Id.COLINAS: "O Golem Ancião guarda as Colinas. Ele nunca dormiu desde que a ilha adoeceu.",
	Regioes.Id.RUINAS: "Um Guardião ficou para trás, esquecido, vigiando o que ninguém mais lembra.",
}
const LORE_TITULO := {
	Regioes.Id.BOSQUE: "Os Guardiões", Regioes.Id.PRAIA: "O Coração partido", Regioes.Id.PANTANO: "A Mãe Gosma",
	Regioes.Id.COLINAS: "O Golem Ancião", Regioes.Id.RUINAS: "O Guardião Esquecido",
}

# --- Pedidos do dia a dia ---------------------------------------------------------------------
## `regiao`: onde se acha (o pedido só sai se alguém do grupo já visitou). `qtd`: [min, max].
const PEDIDOS: Array[Dictionary] = [
	{"item": "carne_sapo", "regiao": Regioes.Id.PANTANO, "qtd": [3, 5], "texto": "%d pernas de sapo. Não pergunte."},
	{"item": "concha", "regiao": Regioes.Id.PRAIA, "qtd": [3, 5], "texto": "%d conchas bonitas. Eu sou um fogo com bom gosto."},
	{"item": "peixe", "regiao": Regioes.Id.PRAIA, "qtd": [3, 5], "texto": "%d peixes. Quero ver se eu consigo assar sem querer."},
	{"item": "barra_cobre", "regiao": Regioes.Id.COLINAS, "qtd": [2, 4], "texto": "%d barras de cobre. Pra... decoração."},
	{"item": "frutinhas", "regiao": Regioes.Id.BOSQUE, "qtd": [4, 6], "texto": "%d frutinhas, porque fogo também faz dieta."},
	{"item": "cogumelo", "regiao": Regioes.Id.PANTANO, "qtd": [3, 6], "texto": "%d cogumelos. Estou colecionando. Não são para comer. Provavelmente."},
	{"item": "pena", "regiao": Regioes.Id.CLAREIRA, "qtd": [3, 6], "texto": "%d penas. Cócegas. Preciso de cócegas."},
]
## Recompensas possíveis: [item, quantidade].
const RECOMPENSAS: Array = [
	[&"pocao_cura", 2], [&"pocao_mana", 2], [&"sopa_cogumelo", 2], [&"carne_sapo_assada", 2],
	[&"peixe_assado", 3], [&"barra_cobre", 2], [&"barra_ferro", 1], [&"espetinho_cogumelo", 3],
]
const OFERTA := "Ei, tenho um pedido: %s Topa?"
const ACEITOU: Array[String] = ["Show! Estou esperando. Sem pressa. Tá, com um pouquinho de pressa."]
const RECUSOU: Array[String] = ["Tá bom, tá bom... *suspira dramaticamente* ...eu me viro. Sozinho. No escuro. Tudo bem."]
const PEDIDO_ENTREGUE: Array[String] = ["Perfeito! Você é o melhor humano. Segundo melhor. Toma aqui uma lembrança."]
const PEDIDO_FALTA := "Ainda quero %s. (Você tem %d.)"
const PONTO_DE_PEDIDOS: Array[String] = ["Cinco pedidos! Você ganhou um ponto de árvore. Eu mereço um aplauso também."]


static func escolher(lista: Array, rng: RandomNumberGenerator) -> Variant:
	return lista[rng.randi() % lista.size()]
