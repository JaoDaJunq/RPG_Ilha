# L41 · Fogueira nova, do zero

**Por quê (13/11/2026):** o João achou ruim a fogueira atual. Ela é a fogueira parada do L12 com as chamas apagadas por ferramenta, mais as chamas do L37 por cima e as faíscas do Pixelbolt. Ficou remendada. Agora é UM desenho só, inteiro, em cada quadro: pedras em volta, lenha e chamas juntas, numa animação em laço.

Duas versões, para escolher a melhor lado a lado no jogo:
- **Folhas 1 e 2:** pixel art 4x (como os objetos simples do L14 e do L36).
- **Folha 3:** ilustração lisa (como os personagens), que o Claude converte com `pixelizar.gd --animacao`.

**Anexar, nesta ordem (em todas as folhas):**
1. `art/prompts/reguas/objetos_4x.png`: peças do Tiny Swords ampliadas EXATAMENTE 4x. O tamanho do pixel, o contorno #161c2e, as cores apagadas e a sombra.
2. `art/sprites/tiny/acampamento_v2.png`: o nosso acampamento aprovado. O tamanho da fogueira (1º desenho), as cores das pedras e da lenha e o tamanho do pixel. NÃO copie o desenho dessa fogueira: faça uma nova, mais bonita.

**Saídas (só nestes caminhos):**
- `art/sprites/tiny/candidatos/l41_fogueira_pixel.png` (folha 1)
- `art/sprites/tiny/candidatos/l41_fogueira_apagada_pixel.png` (folha 2)
- `art/sprites/tiny/candidatos/l41_fogueira_ilustracao.png` (folha 3)

## Folha 1 · fogueira acesa em laço, pixel art 4x

```text
TAREFA: uma folha de ANIMAÇÃO EM LAÇO de 6 quadros de UMA FOGUEIRA DE ACAMPAMENTO INTEIRA, desenhada inteira em cada quadro: um anel de pedras, lenha cruzada no meio e as chamas saindo da lenha. Pixel art no MESMO estilo da imagem 1 (Tiny Swords) e do acampamento da imagem 2.
Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512, um quadro por célula, lidos da esquerda para a direita e de cima para baixo. Fundo magenta chapado #FF00FF.

O DESENHO (igual em todos os quadros, só o fogo muda):
- ANEL DE PEDRAS visto de cima em 3/4: 8 a 9 pedras redondinhas cinza-azuladas (#5b7383, #8aa6a3, luz #c5d6d2), as de trás mais altas na tela e as da frente na frente da lenha, formando uma elipse de ~76 x 34 pixels de jogo. Contorno #161c2e de 1 pixel de jogo em cada pedra.
- LENHA: 3 a 4 toras curtas marrons (#6e4a3c, #955c3c, corte claro #cea554) cruzadas em pirâmide no meio do anel, com brasas laranja (#f6703e) e vermelhas (#cc5050) entre elas.
- CHAMAS: uma fogueira viva saindo da lenha, ~36 pixels de jogo de largura e 40 a 52 de altura. Cores: vermelho #cc5050 nas pontas e por fora, laranja #f6703e, amarelo #ffdc00 no meio e creme #f9f4a9 no miolo de baixo. As chamas NÃO têm contorno escuro.
- 1 a 2 faíscas (quadradinhos amarelos ou creme) soltas acima das chamas em alguns quadros, em lugares diferentes.

A ANIMAÇÃO:
- As PEDRAS e a LENHA ficam EXATAMENTE iguais e no MESMO lugar nos 6 quadros (pode copiar pixel por pixel).
- Só as chamas mudam: as línguas de fogo sobem, balançam para a esquerda e a direita e mudam de altura; o 6º quadro emenda no 1º (laço).
- As brasas piscam: algumas trocam de laranja para vermelho de um quadro para o outro.

FAÇA:
- Quadrados de 4x4 na imagem (cada 4 px da imagem = 1 pixel de jogo; cada célula = 128 x 128 pixels de jogo), sem anti-aliasing.
- A fogueira centralizada na célula, com a BASE das pedras da frente SEMPRE na MESMA linha, 32 px acima do fundo da célula.
- 2 ou 3 tons por material, luz de cima à esquerda, formas redondinhas e simples, cores apagadas do Tiny Swords (só o fogo é vivo).

NÃO FAÇA:
- NÃO use quadrados de tamanhos diferentes, degradê, borrado ou anti-aliasing.
- NÃO use contorno preto puro.
- NÃO desenhe chão, grama, sombra no chão, fumaça, brilho em volta, luz no chão, texto, número nem moldura.
- NÃO encoste na borda da célula.

NÃO SIGA:
- NÃO copie a fogueira da imagem 2 (ela está boa só no tamanho e nas cores); desenhe uma nova, mais caprichada.
- NÃO siga "fogo realista" nem "fogo de anime": chamas chapadas, simples e redondinhas, no estilo da imagem 1.
```

## Folha 2 · a mesma fogueira apagada, pixel art 4x

```text
TAREFA: a MESMA fogueira da folha anterior (mesmo anel de pedras e mesma lenha, mesmo tamanho e mesmo lugar na célula), agora APAGADA. Pixel art no MESMO estilo da imagem 1 e da imagem 2.
Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512. Fundo magenta chapado #FF00FF.

1) FOGUEIRA APAGADA: o anel de pedras igual; no meio, a lenha queimada e preta (#3b3b4a, #5b5b6b) caída, um monte de cinzas cinza-claras (#a9b4b8, #d4dcdc) e 2 ou 3 brasinhas laranja (#f6703e) quase apagadas. Sem chamas e sem fumaça.
2) a 6) vazias (só o fundo magenta).

FAÇA / NÃO FAÇA / NÃO SIGA: os mesmos da folha 1 (quadrados de 4x4, base das pedras da frente 32 px acima do fundo da célula, contorno #161c2e, sem chão, sem sombra, sem fumaça, sem texto).
```

## Folha 3 · fogueira acesa em laço, ilustração lisa

```text
TAREFA: a mesma ideia da folha 1 (fogueira de acampamento inteira: anel de pedras, lenha cruzada e chamas, 6 quadros em laço), agora em ILUSTRAÇÃO 2D limpa (NÃO pixel art), que vai ser reduzida 4 vezes no jogo.
Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512, um quadro por célula, lidos da esquerda para a direita e de cima para baixo. Fundo magenta chapado #FF00FF.

O DESENHO:
- Anel de 8 a 9 pedras redondas cinza-azuladas (#5b7383, #8aa6a3, luz #c5d6d2) em elipse de ~300 x 130 px, visto de cima em 3/4; as pedras da frente na frente da lenha.
- 3 a 4 toras marrons (#6e4a3c, #955c3c, corte claro #cea554) cruzadas no meio, com brasas laranja e vermelhas.
- Chamas de ~140 px de largura e 160 a 210 px de altura: vermelho #cc5050 por fora, laranja #f6703e, amarelo #ffdc00 e creme #f9f4a9 no miolo de baixo. Chamas sem contorno.
- 1 a 2 faíscas soltas acima das chamas em alguns quadros.

A ANIMAÇÃO: pedras e lenha IDÊNTICAS e no MESMO lugar nos 6 quadros; só as chamas mudam (sobem, balançam, mudam de altura) e o 6º quadro emenda no 1º. A base das pedras da frente na MESMA linha em todos os quadros, 110 px acima do fundo da célula, centralizada.

FAÇA:
- Contorno #161c2e grosso (cerca de 5 px) e uniforme em volta das pedras e da lenha (as chamas sem contorno).
- Cores chapadas com UM tom de sombra (cel shading), luz de cima à esquerda, cores apagadas do Tiny Swords (só o fogo é vivo).
- Formas grandes e simples: nada mais fino que 12 px (some ao reduzir 4 vezes).

NÃO FAÇA:
- NÃO desenhe pixel art, degradê, borrado, textura, chão, sombra no chão, fumaça, brilho em volta, texto, número nem moldura.
- NÃO encoste na borda da célula.

NÃO SIGA:
- NÃO siga "fogo realista" nem "fogo de anime": chamas chapadas e redondinhas, no espírito da imagem 1.
```

## Depois de gerar

Salvar só nos 3 caminhos indicados. Não mexer em `game/` nem em nenhum outro arquivo.
