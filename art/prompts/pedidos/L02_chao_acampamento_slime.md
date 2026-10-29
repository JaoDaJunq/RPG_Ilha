# L02 · Chão, acampamento, plantas, slime e aventureiro v2

**Objetivo:** trocar o que ainda é placeholder (Ninja Adventure) para a ilha inteira ficar num estilo só, e refazer o aventureiro já no tamanho do jogo. São **candidatos**: vão para a pasta de aprovações do João antes de entrar no jogo.

**Anexar em todos:** `art/conceitos/mundo/clareira_b_v1.png` (estilo e cores) e `art/sprites/natureza/arvore_v1.png` (sprite aprovado: mesmo acabamento, contorno e tamanho de pixel).

**Regras para todas as imagens (copiar no começo de cada geração):**

```text
PIXEL ART de verdade para um jogo 2D com visão de cima em 3/4 (vê o topo e a frente). Pixels quadrados nítidos e GRANDES, todos do mesmo tamanho, sem anti-aliasing, sem borrado, sem degradê suave. Imagem 1536x1024 com grade de 3 colunas x 2 linhas (cada célula 512x512), lida da esquerda para a direita e de cima para baixo. Fundo magenta chapado #FF00FF em toda a imagem, inclusive nas células vazias. Contorno de 1 pixel escuro e colorido (marrom-escuro ou verde-escuro, não preto). Luz vindo de cima-esquerda, 2 a 3 tons por material. Cada célula tem SÓ o objeto pedido, centralizado, com espaço vazio generoso em volta; nada encosta na borda da célula e nada invade a célula vizinha. Proibido: sombra projetada, poeira, faíscas, fogo, fumaça, brilhos, rastros, texto, números, linhas de grade, moldura. Mesmo estilo, cores, contorno e tamanho de pixel da árvore anexada.
```

## 1. Chão

**Saída:** `art/sprites/chao/candidatos/chao_v1.png`

```text
Blocos de chão vistos de cima. EXCEÇÃO à regra das células: aqui cada célula tem UM bloco quadrado de chão de 32x32 pixels, ampliado 12 vezes (384x384 na imagem), centralizado na célula, com o magenta em volta. O bloco é preenchido até a borda e foi feito para se repetir lado a lado sem emenda visível (a borda esquerda continua na direita e a de cima na de baixo). Sem contorno em volta do bloco.
Células: 1) grama verde-amarelada da imagem anexada, com tufinhos; 2) a mesma grama com algumas florzinhas e trevos; 3) terra batida marrom-clara da clareira do acampamento, com pedrinhas; 4) areia clara da praia, com conchinhas raras; 5) água turquesa rasa com reflexos (sem espuma); 6) grama mais escura e densa, para a sombra da floresta.
```

## 2. Acampamento

**Saída:** `art/sprites/acampamento/candidatos/acampamento_v1.png`

```text
Objetos do acampamento da imagem anexada. Cada célula é UM quadro de 64x64 pixels ampliado 8 vezes (cada pixel vira um quadrado de 8x8). A base do objeto fica no centro de baixo do quadro, 2 pixels acima da borda.
Células: 1) barraca de lona bege em forma de A, com a entrada escura virada para a frente, cerca de 56 pixels de largura; 2) fogueira APAGADA: anel de pedras cinza com lenha cruzada no meio, sem fogo e sem fumaça, cerca de 28 pixels de largura; 3) baú de madeira com ferragens, fechado, cerca de 26 pixels de largura; 4) barril de madeira, cerca de 18 pixels de largura; 5) bancada de trabalho de madeira simples com uma serra e um martelo em cima, cerca de 40 pixels de largura; 6) varal de madeira com um pano pendurado, cerca de 40 pixels de largura.
```

## 3. Plantas pequenas

**Saída:** `art/sprites/natureza/candidatos/plantas_v1.png`

```text
Plantas pequenas de decoração do chão, como as da imagem anexada. Cada célula é UM quadro de 32x32 pixels ampliado 16 vezes (cada pixel vira um quadrado de 16x16). A base da planta fica no centro de baixo do quadro, 2 pixels acima da borda.
Células: 1) arbusto redondo com frutinhas vermelhas, cerca de 20 pixels de largura; 2) arbusto com frutinhas azuis, mesmo tamanho; 3) samambaia, cerca de 18 pixels; 4) tufo de flores amarelas e brancas, cerca de 12 pixels; 5) três cogumelos vermelhos com pintas brancas, cerca de 12 pixels; 6) dois cogumelos azul-esverdeados claros (à noite o jogo faz eles brilharem; aqui sem brilho), cerca de 12 pixels.
```

## 4. Slime

**Saída:** `art/sprites/criaturas/candidatos/slime_v1.png`

```text
Slime verde translúcido da imagem anexada (gelatina arredondada, olhos simples, brilho branco pequeno desenhado no topo como reflexo). Cada célula é UM quadro de 32x32 pixels ampliado 16 vezes (cada pixel vira um quadrado de 16x16). A base do slime fica no centro de baixo do quadro, 2 pixels acima da borda. Tamanho normal: cerca de 18 pixels de largura e 14 de altura.
Células: 1) parado; 2) achatado se preparando para pular (mais largo e mais baixo); 3) no meio do pulo (mais alto e estreito, sem chão embaixo e sem sombra); 4) caindo, quase parado de novo; 5) tomando dano: olhos fechados com força e corpo amassado de lado; 6) vazia (só magenta).
O slime é o mesmo em todas as células: mesmas cores, mesmo olho, só muda a forma.
```

## 5. Aventureiro v2 (já no tamanho do jogo)

**Saída:** `art/sprites/personagens/candidatos/aventureiro_base_v2.png`

**Anexar também:** `art/sprites/personagens/aventureiro_base_v1.png` (personagem aprovado: mesma roupa, cabelo e cores) e `evidence/importacao/aventureiro.png` (como ele fica no jogo hoje: é esse o tamanho de pixel certo).

```text
O MESMO aventureiro da imagem anexada (cabelo castanho espetado, capuz e túnica azuis, cinto marrom, calça clara, botas marrons, mãos vazias), mas redesenhado com pixels GRANDES: o personagem inteiro tem só 28 pixels de altura, igual à imagem "como fica no jogo" anexada, só que desenhado direto nesse tamanho, com olhos de 2 pixels bem legíveis e contorno limpo. Estilo chibi, cabeça com cerca de 40% da altura.
Cada célula é UM quadro de 32x32 pixels ampliado 16 vezes (cada pixel vira um quadrado de 16x16 na imagem). Os pés ficam na mesma altura em todas as células, 2 pixels acima da borda de baixo do quadro.
Células: 1) parado de frente; 2) parado de costas; 3) parado de perfil olhando para a DIREITA; 4) andando de frente, pé esquerdo à frente; 5) andando de perfil para a direita, no meio do passo; 6) andando de costas, um pé à frente.
O personagem é idêntico em todas as células: mesmo tamanho, mesmas cores, mesma roupa; só muda a pose e a direção.
```

## Depois de gerar

Salvar só nos cinco caminhos de saída acima (criar as pastas se faltar). Não mexer em `game/` nem em nenhum outro arquivo. Responder com os caminhos e o tamanho em pixels de cada imagem.
