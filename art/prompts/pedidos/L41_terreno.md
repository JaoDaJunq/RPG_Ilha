# L41 · Transições do terreno: texturas novas e peças para as emendas

**Por quê (13/11/2026):** o João jogou o mundo maior e achou ruins as emendas entre as regiões e os chãos: emendas retas, cantos quadrados, contorno escuro de penhasco entre duas gramas, linhas claras de areia aparecendo, franja roxa na trilha e a lama com um desenho que se repete a cada bloco.

**O que muda no jogo (feito pelo Claude):**
- As bordas passam a ser montadas em quartos de bloco, com cantos de dentro e de fora arredondados.
- Entre dois chãos de terra firme, o contorno fica da cor escura do próprio chão (sem o azul-escuro de penhasco), com uma sombrinha.
- O miolo de cada chão vem de uma TEXTURA GRANDE, presa ao mundo (não ao bloco), então a repetição some.

**Para isso faltam:**
- as texturas grandes (folhas T1 a T4);
- peças pequenas para espalhar nas emendas e disfarçar a linha (folhas D1 e D2).

**Anexar em todas as folhas:**
1. `art/prompts/reguas/objetos_4x.png`: peças do Tiny Swords ampliadas EXATAMENTE 4x (tamanho do pixel, contorno #161c2e, cores apagadas).
2. `art/terceiros/tiny_swords/Tiny Swords (Free Pack)/Terrain/Tileset/Tilemap_color1.png`: a grama do pacote (como o chão é desenhado: poucos tons, manchinhas simples).
3. `game/assets/sprites/tiny/mundo/lama.png`, `trilha.png`, `piso.png` e `game/assets/sprites/tiny/areia.png`: os chãos de hoje (as CORES valem; o desenho do miolo NÃO, ver NÃO SIGA).

**Regras (copiar no começo do texto de cada folha):**

```text
FAÇA:
- Pixel art no MESMO estilo da imagem 1 (Tiny Swords): quadrados de 4x4 na imagem (cada 4 px da imagem = 1 pixel de jogo), sem anti-aliasing.
- Cores apagadas do Tiny Swords, poucos tons, formas redondinhas e simples.

NÃO FAÇA:
- NÃO use quadrados de tamanhos diferentes, degradê, borrado ou anti-aliasing.
- NÃO use contorno preto puro nem cores saturadas demais.
- NÃO escreva texto, número, grade nem moldura.

NÃO SIGA:
- NÃO siga "pixel art de RPG genérico" nem desenho detalhado fino: siga a imagem 1.
- NÃO copie o miolo dos chãos de hoje (imagem 3): ele tem manchas grandes que se repetem e viram um padrão xadrez no jogo.
```

## Texturas grandes (T1 a T4)

Texto comum (trocar o MATERIAL e as CORES):

```text
TAREFA: uma TEXTURA DE CHÃO visto de cima, que ocupa a imagem INTEIRA (1536x1024, sem fundo magenta, sem borda, sem moldura), em pixel art 4x (= 384 x 256 pixels de jogo). Vai ser repetida lado a lado no jogo, então:
- a textura se repete SEM EMENDA: o que sai pela direita continua pela esquerda, e o que sai por baixo continua por cima;
- o desenho é ESPALHADO POR IGUAL: nenhuma mancha grande, nenhum detalhe que chame atenção sozinho, nenhuma linha reta, nada no centro diferente das beiradas;
- detalhes pequenos (2 a 6 pixels de jogo) e muitos, em lugares variados, para não formar padrão;
- 3 ou 4 tons só, bem próximos, como a grama da imagem 2 (um tom base, um mais escuro, um mais claro e, se precisar, um quarto tom de detalhe).
MATERIAL: ...
```

- **T1** `art/sprites/tiny/candidatos/l41_textura_lama.png`: LAMA DE PÂNTANO. Base verde-oliva escuro #515039, mais escuro #3f3f2e, mais claro #66653d e detalhe marrom-avermelhado apagado #6e4a3c. Pocinhas pequenas de 3 a 6 pixels de água parada com um brilho de 1 pixel #7ea69a, bolhinhas e marcas de lodo. Sem manchas grandes vermelhas.
- **T2** `art/sprites/tiny/candidatos/l41_textura_trilha.png`: TERRA BATIDA de trilha. Base marrom-clara #d1a273, mais escura #b8865d, mais clara #e0b98a. Pedrinhas de 1 a 3 pixels, rachadinhas curtas, umas marcas de pegada bem apagadas.
- **T3** `art/sprites/tiny/candidatos/l41_textura_piso.png`: PISO DE PEDRA ANTIGA das ruínas. Lajes RETANGULARES cinza-azuladas (#809eaa, junta escura #5b7383, luz #a3bcc2) de tamanhos variados, em fileiras, com MUITAS rachaduras pequenas, algumas lajes faltando um canto, e musgo verde (#7f9a4f, #96a85a) nas juntas em pontos espalhados (não em todas). As fileiras atravessam a imagem e emendam nas beiradas.
- **T4** `art/sprites/tiny/candidatos/l41_textura_areia.png`: AREIA DE PRAIA. Base #fee8a8, mais escura #f1cf8a, mais clara #fff4cc. Ondinhas de vento curtas de 1 pixel de altura e grãozinhos; RARAMENTE uma conchinha de 3 pixels. Bem calma (é o chão da praia inteira).

## Folha D1 · tufos de grama para as emendas (régua `objetos_4x.png`)

```text
TAREFA: 6 TUFOS DE GRAMA baixos, para espalhar na beira da grama, onde ela encosta na terra, na areia ou na lama. Pixel art no MESMO estilo da imagem 1 (a moita da régua é a referência de traço).
Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512, UMA peça por célula, centralizada, base 32 px acima do fundo da célula. Fundo magenta chapado #FF00FF.
Cada tufo: folhinhas pontudas saindo de um ponto, ~20 a 30 pixels de jogo de largura e 8 a 12 de altura, contorno #161c2e de 1 pixel, 3 tons do verde indicado (escuro embaixo, claro nas pontas).
1) tufo largo, verde-amarelado: #80ac5e, #9bb94e, luz #b8b958.
2) tufo largo, verde de folha: #789e5f, #85b156, luz #93ba4f.
3) tufo largo, verde-esmeralda: #5da067, #5fab62, luz #74b363.
4) tufo largo, verde-oliva acinzentado: #77915c, #839a5e, luz #969f64.
5) tufo largo, verde-azulado de pântano: #528e89, #569b8d, luz #63a486.
6) tufo pequeno com 2 florzinhas brancas de 2 pixels, verde-amarelado como o 1.
NÃO desenhe chão, terra, sombra no chão nem moldura. NÃO encoste na borda da célula.
```

## Folha D2 · pedacinhos para as emendas (régua `objetos_4x.png`)

```text
TAREFA: 6 peças pequenas e baixas para espalhar onde dois chãos se encontram. Pixel art no MESMO estilo da imagem 1.
Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512, UMA peça por célula, centralizada, base 32 px acima do fundo da célula. Fundo magenta chapado #FF00FF. Contorno #161c2e de 1 pixel em tudo, 2 ou 3 tons por material, luz de cima à esquerda, peças achatadas (são quase do chão).
1) TORRÕES DE TERRA E PEDRINHAS (beira da trilha): 2 torrões marrom-claros e 3 pedrinhas cinza. ~22 x 10.
2) LAJES SOLTAS (beira do piso das ruínas): 2 pedaços de laje cinza-azulada rachados, um com musgo. ~28 x 14.
3) LAJE PEQUENA AFUNDADA na grama: 1 pedaço de laje quase escondido, com musgo. ~16 x 10.
4) LODO NA BEIRA DA LAMA: 2 pocinhas de lodo verde-oliva escuro com bolhinhas. ~26 x 10.
5) PEDRINHAS DE PRAIA e 1 conchinha (beira da areia). ~20 x 10.
6) FOLHINHAS CAÍDAS e um galhinho seco. ~20 x 10.
NÃO desenhe chão em volta, sombra no chão nem moldura. NÃO encoste na borda da célula.
```

## Depois de gerar

Salvar só nos 6 caminhos indicados (T1 a T4, `l41_decoracao_tufos.png` para a D1 e `l41_decoracao_emendas.png` para a D2, em `art/sprites/tiny/candidatos/`). Não mexer em `game/` nem em nenhum outro arquivo.

## Folha D1b · tufos MENORES (correção da D1)

**Por quê:** na D1 os tufos vieram com ~78 x 36 pixels de jogo (o pedido era 20 a 30 de largura). No jogo parecem moitas, maiores que a borda da grama. Mesma folha, bem menores.

**Saída:** `art/sprites/tiny/candidatos/l41_decoracao_tufos_v2.png`

```text
TAREFA: a MESMA folha de 6 tufos de grama da imagem anexada l41_decoracao_tufos.png (mesmas cores, mesmo traço, mesma ordem), mas MUITO MENORES: cada tufo com NO MÁXIMO 32 pixels de jogo de largura e 14 de altura (na imagem: no máximo 128 x 56 px, com quadrados de 4x4). Só 5 a 7 folhinhas pontudas por tufo, baixinho e achatado.
Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512, UM tufo por célula, centralizado, base 32 px acima do fundo da célula. Fundo magenta chapado #FF00FF. Contorno #161c2e de 1 pixel de jogo.
O 6º: tufo pequeno com 2 florzinhas brancas de 2 pixels, também no máximo 32 x 14.
NÃO desenhe chão, sombra, moldura nem texto. NÃO faça tufos grandes: o tufo inteiro cabe num quadrado de 128 x 56 da imagem.
```
Anexar também `art/sprites/tiny/candidatos/l41_decoracao_tufos.png` (a D1, para as cores e o traço).
