# Personagem segurando arma e ferramenta (pesquisa para o F05)

> Nota para depois (o João pediu em 29/10/2026 para tratar mais tarde). Nada foi implementado.

## Como os jogos 2D vistos de cima costumam fazer

| Jeito | Como funciona | Exemplos | Bom | Ruim |
|---|---|---|---|---|
| **1. Quadros desenhados por arma** | Para cada ação e direção, o personagem é desenhado já segurando aquela arma (espada, machado, arco…) | Stardew Valley (ferramentas), jogos de RPG clássicos | Fica o mais bonito e natural | Multiplica a arte: armas × direções × quadros × raças |
| **2. Arma separada presa na mão** | O corpo é desenhado com a mão num ponto conhecido; a arma é um sprite à parte, encaixado nesse ponto e virado na direção do golpe. O balanço do golpe é feito girando a arma | Core Keeper, Enter the Gungeon, Hades (em parte), Terraria (ferramentas) | Uma arma nova é **um** desenho; combina com qualquer raça e roupa | Precisa marcar "onde está a mão" em cada quadro; o giro tem de ser bem ajustado para não parecer duro |
| **3. Só o efeito do golpe** | O personagem faz uma pose genérica de ataque e o jogo mostra um arco de corte | Muitos jogos pequenos | Barato | Não dá para ver qual arma está na mão (o que o João não quer) |

## Recomendação para a Ilha Viva

**Jeito 2 (arma separada presa na mão)**, que combina com o plano de personagens em camadas (corpo da raça + roupa da classe + arma):

1. Cada quadro do corpo ganha um **ponto da mão** (anotado numa tabela, como os pés que já alinhamos).
2. Cada arma/ferramenta é **um sprite pequeno** (32×32), desenhado apontando para a direita, com o **ponto do cabo** marcado.
3. O jogo encaixa o cabo na mão e **gira a arma** na direção do mouse. O golpe é um giro rápido (espada e machado), um puxão (arco) ou uma batida (picareta). A arma fica **atrás** do corpo quando o personagem olha para cima.
4. Golpes especiais que precisem de pose própria (ex.: girar a espada no Giro) ganham quadros desenhados só para eles.

Arte a pedir quando chegar a hora: espada, machado, picareta, arco, cajado (32×32 cada), e os pontos da mão em cada quadro do personagem.
