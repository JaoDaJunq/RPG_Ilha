# L17 · Ícones dos itens novos (inventário e crafting estilo Minecraft)

**Por quê (31/10):** o João pediu um inventário parecido com o do Minecraft: mochila com os itens coletados e crafting básico. Precisamos dos ícones dos itens novos, no mesmo estilo e tamanho dos ícones do L16 (aprovados e no jogo).

**Anexar, nesta ordem:**
1. `art/sprites/tiny/efeitos_icones/icones_habilidades_v1.png`: **os nossos ícones aprovados** (L16). Copiar exatamente o estilo, o tamanho do pixel, o contorno e o tamanho do objeto na célula.
2. `art/sprites/tiny/efeitos_icones/icones_itens_v1.png`: os ícones de item aprovados (pedra, carvão).
3. `art/terceiros/tiny_swords/Tiny Swords (Free Pack)/UI Elements/UI Elements/Icons/Icon_02.png`: a tora de madeira do pacote (a "madeira" do jogo).

**Regras (copiar no começo de cada folha):**

```text
FAÇA:
- Ícones de item no MESMO estilo EXATO dos ícones anexados (imagens 1 e 2): pixel art com quadrados de 8x8 na imagem (64 pixels de jogo por célula), objeto grande ocupando cerca de 40 x 40 dos 64 pixels, contorno de 1 pixel na cor #161c2e, sombreamento em 2 ou 3 tons, luz de cima à esquerda, cores apagadas do Tiny Swords: #161c2e #485884 #4697ac #9cbeaa #688c8a #c8a876 #efe1ab #977b6b #8d6857 #5e5455 #924159 #8d4848 #e76161 #cf9c71 #cea554 #e9f044 #44a079 #699157 #ffffff.
- Imagem 1536x1024, grade de 3 colunas x 2 linhas (células de 512x512), um ícone por célula, centralizado, com folga em volta.
- Fundo magenta chapado #FF00FF.
- Itens de madeira na mesma madeira da tora anexada (imagem 3); itens de pedra no mesmo cinza-azulado da pedra anexada (imagem 2).

NÃO FAÇA:
- NÃO use quadrados de tamanhos diferentes, degradê dentro do quadrado, borrado nem anti-aliasing.
- NÃO use contorno preto puro nem contorno com 2 ou mais pixels.
- NÃO use cores saturadas ou neon, nem rosa ou magenta no desenho.
- NÃO desenhe fundo, moldura, quadrado atrás do ícone, sombra no chão, texto ou número.
- NÃO deixe o objeto pequeno no meio da célula nem encostando na borda.

NÃO SIGA:
- NÃO siga "ícone de RPG genérico" nem ícone realista: siga só os ícones anexados.
- NÃO copie o visual do Minecraft (blocos quadrados, texturas do Minecraft): é só a ideia do crafting.
```

## Folha 1: materiais e ferramentas de madeira

**Saída:** `art/sprites/tiny/candidatos/icones_crafting_1_v1.png`

```text
(regras) +
1) Tábuas: 2 tábuas de madeira clara empilhadas, retas, com veios simples.
2) Graveto: um graveto fino-mas-legível na diagonal, com um nozinho.
3) Tocha: graveto na diagonal com a ponta enrolada em pano e uma chama laranja e amarela.
4) Machado de madeira: cabo de graveto na diagonal, lâmina de madeira clara.
5) Picareta de madeira: cabo de graveto na diagonal, cabeça curva de madeira clara.
6) Espada de madeira: espada curta de madeira clara na diagonal, cabo marrom.
```

## Folha 2: ferramentas de pedra e construção

**Saída:** `art/sprites/tiny/candidatos/icones_crafting_2_v1.png`

```text
(regras) +
1) Machado de pedra: cabo de graveto na diagonal, lâmina de pedra cinza-azulada amarrada com corda.
2) Picareta de pedra: cabo de graveto na diagonal, cabeça curva de pedra cinza-azulada.
3) Espada de pedra: lâmina de pedra cinza-azulada na diagonal, cabo de madeira com corda.
4) Parede de madeira: um pedaço de parede de troncos em pé, vista um pouco de cima.
5) Porta de madeira: porta de tábuas com dobradiças de metal, fechada.
6) Chão de madeira: um quadrado de tábuas visto de cima em 3/4.
```

## Folha 3: móveis, saque e interface

**Saída:** `art/sprites/tiny/candidatos/icones_crafting_3_v1.png`

```text
(regras) +
1) Bancada de trabalho: mesa de madeira com martelo e serra em cima (como a bancada do acampamento do jogo, em ícone).
2) Fogueira: anel de pedras com toras e chama (em ícone).
3) Baú de madeira com cantos de metal (em ícone).
4) Gel de slime: uma gota verde translúcida (#44a079, #39cd6a, brilho #d4edc2) de gosma.
5) Seta grossa apontando para a DIREITA, cor creme (#efe1ab) com contorno #161c2e (a seta do crafting: ingredientes -> resultado).
6) Mochila de couro marrom com fivela, vista de frente (o ícone da mochila).
```

## Depois de gerar

Salvar só nos três caminhos acima. Não mexer em `game/` nem em nenhum outro arquivo. Responder com os caminhos e o tamanho em pixels de cada imagem.
