# L06 · Chão liso (estilo Core Keeper) e bordas entre grama, areia, terra e água

**Por quê:** no jogo o chão ainda parece "sobrecarregado": a grama tem tracinhos repetidos e a troca de grama para areia/terra/água é em quadrados duros. No Core Keeper e no Stardew o chão é quase liso (manchas grandes de uma cor, poucos detalhes) e cada tipo de chão tem **borda arredondada** com o vizinho.

**Anexar em todos:** `art/conceitos/mundo/clareira_b_v1.png` (cores aprovadas) e `art/sprites/natureza/arvore_v1.png` (acabamento aprovado). Referência de sensação (não anexar, só descrever): chão do Core Keeper e do Stardew Valley.

**Regras para as duas imagens (copiar no começo de cada geração):**

```text
PIXEL ART de verdade para o CHÃO de um jogo 2D visto de cima, estilo Core Keeper e Stardew Valley: chão CALMO e LISO, manchas grandes de cor, no máximo 3 tons por tipo de chão, poucos detalhes espalhados (um tufinho, uma pedrinha) e muito espaço vazio entre eles. Nada de textura granulada, nada de ruído, nada de tracinhos repetidos. Pixels quadrados nítidos e GRANDES, todos do mesmo tamanho e alinhados numa grade de tiles de 16x16 pixels. Sem anti-aliasing, sem degradê. Cores da imagem anexada, um pouco menos saturadas. Imagem 1536x1024 com grade de 3 colunas x 2 linhas (cada célula 512x512). Fundo magenta chapado #FF00FF fora dos desenhos. Sem texto, sem grade desenhada, sem moldura, sem sombras projetadas, sem objetos (árvores, pedras grandes).
```

## 1. Blocos lisos

**Saída:** `art/sprites/chao/candidatos/chao_liso_v1.png`

```text
Cada célula tem UM bloco quadrado de chão de 32x32 pixels (2x2 tiles), ampliado 12 vezes (384x384 na imagem), centralizado, preenchido até a borda, feito para se repetir lado a lado SEM emenda. Sem contorno em volta do bloco.
Células: 1) grama: verde médio quase liso, 2 ou 3 tufinhos de 3 pixels num tom mais escuro; 2) a mesma grama com 2 florzinhas brancas e 1 amarela; 3) terra batida marrom-clara quase lisa, 2 pedrinhas; 4) areia clara quase lisa, 1 conchinha; 5) água turquesa lisa com 2 ou 3 reflexos claros curtos; 6) a mesma grama da célula 1 sem nenhum detalhe (só o verde liso).
```

## 2. Bordas (manchas para recortar)

**Saída:** `art/sprites/chao/candidatos/chao_bordas_v1.png`

```text
Cada célula mostra um pedaço de chão de 5x5 tiles (80x80 pixels, cada tile 16x16), ampliado 6 vezes (480x480 na imagem), centralizado. As bordas entre um chão e outro são ARREDONDADAS e suaves, com 1 pixel de contorno mais escuro do lado de dentro da grama, como no Core Keeper. O meio de cada chão é liso como nos blocos lisos.
Células:
1) AREIA em volta e uma mancha de GRAMA de 3x3 tiles (48x48 pixels) exatamente no meio, com os 4 cantos arredondados.
2) GRAMA em volta e um buraco de AREIA de 3x3 tiles exatamente no meio, com os cantos arredondados.
3) ÁGUA em volta e uma mancha de AREIA de 3x3 tiles no meio (praia), com espuma branca de 1 pixel na beira.
4) AREIA em volta e um buraco de ÁGUA de 3x3 tiles no meio (laguinho), com espuma branca de 1 pixel na beira.
5) GRAMA em volta e uma mancha de TERRA batida de 3x3 tiles no meio.
6) TERRA em volta e uma mancha de GRAMA de 3x3 tiles no meio.
A mancha do meio começa e termina exatamente nas linhas da grade de 16 pixels (ocupa os tiles 2, 3 e 4 de 5, nas duas direções).
```

## Depois de gerar

Salvar só nos dois caminhos acima. Não mexer em `game/` nem em nenhum outro arquivo. Responder com os caminhos e o tamanho em pixels de cada imagem.
