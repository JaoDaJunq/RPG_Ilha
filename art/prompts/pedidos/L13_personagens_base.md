# L13 · Nossos 6 personagens no estilo Tiny Swords (etapa A: só o parado)

**Por quê (30/10):** o jogo está no estilo Tiny Swords e os personagens ainda são os do pacote. Estes são os NOSSOS: 2 raças x 3 classes. Antes das animações (andar, golpe), o João aprova o desenho base de cada um.

**O que deu errado antes (não repetir):** no L11 e no L12 o Codex desenhou com o pixel 2 a 3 vezes maior que o do pacote, com contorno preto grosso e cores fortes. Ao lado das peças do pacote, ficou grosseiro.

**Anexar, nesta ordem:**
1. `art/prompts/reguas/personagens_4x.png`: **A RÉGUA.** Seis unidades do pacote ampliadas EXATAMENTE 4x, na MESMA grade desta folha. Copiar dela o tamanho do pixel, o tamanho do personagem, o contorno, as cores e as proporções.
2. `evidence/comparacao/l12_atual.png`: **EXEMPLO DO QUE NÃO FAZER.** Em cima, o pacote (certo). Embaixo, a nossa tentativa anterior (errada: pixel grosso, contorno preto, cores fortes).
3. `art/sprites/personagens/personagens_v1.png`: **SÓ para saber quem é quem** (as cores da roupa de cada um). NÃO copiar o estilo, o tamanho do pixel nem o rosto desta imagem.

```text
TAREFA: desenhar 6 personagens NOVOS que pareçam ter saído do MESMO pacote da imagem-régua anexada (o jogo Tiny Swords). Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512. Cada célula tem UM personagem de 128x128 pixels de jogo, ampliado EXATAMENTE 4x (cada pixel do jogo = um quadrado de 4x4 na imagem, igual à régua).

FAÇA:
- Mesmo tamanho de pixel da régua: quadrados de 4x4, todos alinhados na mesma grade.
- Mesmo tamanho de personagem da régua: cerca de 80 pixels de jogo de altura (320 na imagem), pés na mesma altura dos pés da régua, 16 px acima do fundo da célula.
- Mesmo jeito de corpo da régua: cabeça grande e redonda, corpo curto e roliço, perninhas curtas e finas, mãos redondinhas.
- Contorno de 1 pixel de jogo (4 px na imagem) na cor #161c2e em volta de tudo e entre as partes, como na régua.
- Sombreamento em 2 ou 3 tons por material, com luz de cima à esquerda, cores apagadas como na régua. Use estas cores do pacote: #161c2e #485884 #4c5c8b #4697ac #9cbeaa #688c8a #c8a876 #efe1ab #977b6b #5e5455 #924159 #8d4848 #e76161 #cf9c71 #cea554 #44a079 #699157 #6e7e53 #ffffff.
- Personagem de PERFIL olhando para a DIREITA, parado, igual às unidades da régua.
- Rosto simples como o do trabalhador da régua: olhos de 2 pixels escuros, boca de 1 ou 2 pixels.

OS 6 PERSONAGENS:
1) HUMANO GUERREIRO: elmo de aço aberto (dá para ver o rosto) com pluma azul, túnica azul, escudo redondo de madeira com borda de aço, espada curta.
2) HUMANO MAGO: capuz azul-escuro com borda dourada, mechas de cabelo castanho, túnica azul até o chão, cajado de madeira com uma pedra azul na ponta.
3) HUMANO ARQUEIRO: capuz de couro marrom, túnica verde-musgo apagada, arco curto de madeira na mão, aljava nas costas.
4) OGRO GUERREIRO: pele verde-acinzentada (#699157 e #6e7e53), corpo mais largo e forte que o humano (mesma altura), duas presas brancas pequenas saindo do lábio de BAIXO e apontando para cima, sem capacete, ombreira de couro, porrete de madeira grosso.
5) OGRO MAGO: mesma pele e presas do ogro guerreiro, capuz e túnica azul-escuros com borda dourada (como o mago humano), cajado com pedra azul.
6) OGRO ARQUEIRO: mesma pele e presas, capuz de couro MARROM e colete marrom (nada de roupa verde: a pele já é verde), arco curto e aljava.

NÃO FAÇA:
- NÃO use pixel maior que 4x4 na imagem (a tentativa anterior usou ~11 px: ficou grosseira).
- NÃO desenhe ilustração com "cara de pixel": nada de quadradinhos de tamanhos diferentes, degradê dentro de um quadrado ou borrado.
- NÃO use contorno preto puro nem contorno grosso de 2 ou mais pixels de jogo.
- NÃO use cores saturadas, neon nem degradê suave.
- NÃO desenhe sombra no chão (o jogo coloca a sombra; a mancha roxa embaixo da régua é a sombra deles sobre o magenta, ignore).
- NÃO desenhe chão, grama, cenário, efeitos, brilho, texto, número, moldura ou linhas de grade.
- NÃO deixe o personagem pequeno no meio da célula nem encostando na borda; nada atravessa para a célula vizinha.
- NÃO desenhe o ogro com marcas brancas embaixo dos olhos (parecem lágrimas): as presas saem da BOCA.
- NÃO desenhe de frente nem de costas: só de perfil para a direita.

NÃO SIGA:
- NÃO siga o estilo da imagem de identidade (personagens_v1.png): ela é de outro estilo e serve só para saber as cores da roupa.
- NÃO siga a fileira de baixo da imagem de exemplo (l12_atual.png): é o que deu errado.
- NÃO siga "pixel art de RPG genérico" nem anime: siga só a régua.
```

## Depois de gerar

Salvar só em `art/sprites/tiny/candidatos/personagens_base_v1.png`. Não mexer em `game/` nem em nenhum outro arquivo. Responder com o caminho e o tamanho em pixels da imagem.
