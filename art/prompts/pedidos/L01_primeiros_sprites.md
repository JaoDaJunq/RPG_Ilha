# L01 · Primeiros sprites: aventureiro, árvore e pedra

**Objetivo:** testar a bíblia visual (`design/identidade.md`) em sprites de jogo de verdade, antes de produzir em série. São **candidatos**: só entram no jogo depois da avaliação e do print dentro do jogo.

**Anexar em todos:** `art/conceitos/mundo/clareira_b_v1.png` (referência de estilo e cores).

**Regras para todas as imagens (copiar no começo de cada geração):**

```text
PIXEL ART de verdade para um jogo 2D com visão de cima em 3/4 (vê o topo e a frente). Pixels quadrados nítidos, sem anti-aliasing, sem borrado, sem degradê suave. Imagem 1536x1024 com grade de 3 colunas x 2 linhas (cada célula 512x512), lida da esquerda para a direita e de cima para baixo. Fundo magenta chapado #FF00FF em toda a imagem, inclusive nas células vazias. Contorno de 1 pixel escuro e colorido (marrom-escuro ou verde-escuro, não preto). Luz vindo de cima-esquerda, 2 a 3 tons por material. Cada célula tem SÓ o objeto pedido, centralizado, com espaço vazio generoso em volta; nada encosta na borda da célula e nada invade a célula vizinha. Proibido: chão, grama embaixo, sombra projetada, poeira, faíscas, brilhos, rastros, texto, números, linhas de grade, moldura. Mesmo estilo, cores e acabamento da imagem de referência anexada.
```

## 1. Aventureiro (personagem provisório)

**Saída:** `art/sprites/personagens/candidatos/aventureiro_base_v1.png`

```text
Personagem: o aventureiro de cabelo castanho espetado e capuz/capa azul da imagem anexada (o que está cortando a árvore), estilo chibi: cabeça grande (cerca de 40% da altura), olhos grandes, corpo curto. Túnica azul, cinto marrom, calça clara, botas marrons. Sem machado nas mãos (mãos vazias).
Cada célula é UM quadro de 32x32 pixels ampliado 16 vezes (cada pixel vira um quadrado de 16x16). O personagem tem cerca de 28 pixels de altura e os pés ficam na mesma altura em todas as células, 2 pixels acima da borda de baixo do quadro.
Células: 1) parado de frente (olhando para baixo, para a câmera); 2) parado de costas (olhando para cima); 3) parado de perfil olhando para a DIREITA; 4) andando de frente, passo com o pé esquerdo à frente; 5) andando de perfil para a direita, pernas abertas no meio do passo; 6) vazia (só magenta).
O personagem é idêntico em todas as células: mesmo tamanho, mesmas cores, mesma roupa; só muda a pose e a direção.
```

## 2. Árvore e seus estados

**Saída:** `art/sprites/natureza/candidatos/arvore_v1.png`

```text
Árvore frondosa da imagem anexada (copa verde-amarelada cheia e arredondada, tronco marrom grosso com raízes aparentes). Cada célula é UM quadro de 64x64 pixels ampliado 8 vezes (cada pixel vira um quadrado de 8x8). A base do tronco fica no centro de baixo do quadro, 2 pixels acima da borda, igual em todas as células.
Células: 1) árvore inteira; 2) a mesma árvore com marcas de machado no tronco (talhos claros na madeira); 3) a mesma árvore depois de queimada: tronco e galhos carbonizados pretos e cinza-escuros, sem folhas, sem fogo e sem fumaça; 4) toco cortado da mesma árvore (tronco cortado baixo com anéis visíveis no topo e raízes); 5) variação da árvore inteira com copa de flores rosa (como as árvores rosas da imagem); 6) vazia (só magenta).
Mesma escala da árvore em todas as células.
```

## 3. Pedras

**Saída:** `art/sprites/natureza/candidatos/pedra_v1.png`

```text
Pedras cinza com musgo verde da imagem anexada. Cada célula é UM quadro de 32x32 pixels ampliado 16 vezes (cada pixel vira um quadrado de 16x16). A base da pedra fica no centro de baixo do quadro, 2 pixels acima da borda.
Células: 1) pedra grande arredondada com musgo no topo, cerca de 24 pixels de largura; 2) a mesma pedra rachada (uma rachadura clara em zigue-zague); 3) a mesma pedra bem quebrada, metade do tamanho, com pedaços soltos encostados nela; 4) variação: pedra marrom-clara sem musgo, mesmo tamanho da 1; 5) e 6) vazias (só magenta).
```

## Depois de gerar

Salvar só nos três caminhos de saída acima (criar as pastas se faltar). Não mexer em `game/` nem em nenhum outro arquivo. Responder com os caminhos e o tamanho em pixels de cada imagem.
