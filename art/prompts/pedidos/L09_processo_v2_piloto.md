# L09 · Processo de arte v2: piloto (Mago, Ogro Arqueiro e natureza)

Primeiro lote do processo descrito em `design/processo_arte.md`, copiado do que funciona no Smash Junq: pixel art de verdade, numa grade exata (8x ou 4x), com sprites maiores (64x64 para personagem) e uma régua de nitidez anexada em todo pedido.

**Anexar nos dois pedidos:**
1. `art/conceitos/estilo/estilo_pixel_fino_v1.png`: direção aprovada (C02), para cores e clima;
2. `C:\projetos\smash_junq\art\pixel\juba\parado.png`: SÓ como régua de nitidez e de tamanho do pixel (blocos 8x8 limpos, contorno contínuo). Não copiar o personagem nem o estilo de luta;
3. `art/sprites/personagens/personagens_v1.png`: quem são os personagens (roupas e cores).

**LIMPEZA (colar em todo pedido):**

```text
LIMPEZA (obrigatório): pixel art DE VERDADE, nítida como o sprite de régua anexado (juba/parado.png). Cada pixel lógico é um bloco quadrado, todo de UMA cor, alinhado à grade da imagem a partir do canto (0,0). NÃO desenhe ilustração detalhada fina com cara de pixel: nada de blocos de tamanhos diferentes, nada de degradê dentro do bloco. Formas grandes de cor chapada, no máximo 3 tons por material, contorno contínuo de 1 pixel sem falhas num marrom bem escuro #2A1A14 (nunca preto puro), nenhum pixel solto, sem textura de ruído. O rosto se lê de longe: olhos de 2 pixels de altura, boca de 1 pixel. O desenho NÃO enche a célula: ocupa só o tamanho pedido, com folga em volta. Fundo magenta chapado #FF00FF. Sem chão, sem sombra projetada, sem brilho, sem efeitos, sem texto, sem grade desenhada, sem moldura. Luz de cima à esquerda.
```

## 1. Personagens (64x64, ampliado 8x)

**Saída:** `art/sprites/processo_v2/candidatos/personagens_v1.png`

```text
Imagem 1536x1024 com grade de 3 colunas x 2 linhas. Cada célula tem 512x512 e contém UM quadro de 64x64 pixels ampliado EXATAMENTE 8x (cada pixel vira um quadrado de 8x8). Personagens chibi fofos com cerca de 46 pixels de altura (cabeça grande, cerca de 40% da altura), pés na mesma linha em todos os quadros, 4 pixels acima da borda de baixo da célula. Mesma escala nos 6 quadros.
Linha de cima: HUMANO MAGO parado 1) de frente, 2) de costas, 3) de perfil olhando para a direita. Capuz azul-escuro com borda dourada, cabelo castanho saindo do capuz, rosto claro com bochecha rosada, túnica azul com cinto marrom, botas marrons. Sem cajado na mão.
Linha de baixo: OGRO ARQUEIRO parado 4) de frente, 5) de costas, 6) de perfil olhando para a direita. Pele verde-acinzentada, CAPUZ DE COURO MARROM (bem diferente da pele, e o rosto bem separado do capuz também de perfil), boca escura com 2 presinhas brancas PEQUENAS nos cantos da boca apontando para cima (NADA embaixo dos olhos), colete de couro, aljava nas costas. Sem arco na mão.
+ LIMPEZA
```

## 2. Natureza (128x128, ampliado 4x)

**Saída:** `art/sprites/processo_v2/candidatos/natureza_v1.png`

```text
Imagem 1536x1024 com grade de 3 colunas x 2 linhas. Cada célula tem 512x512 e contém UM quadro de 128x128 pixels ampliado EXATAMENTE 4x (cada pixel vira um quadrado de 4x4). Base de cada objeto na mesma linha, 6 pixels acima da borda de baixo da célula. Visão de cima em 3/4.
1) Árvore grande de folhas verdes: copa redonda e fofa feita de 4 ou 5 "bolas" grandes de folha com 3 tons de verde, tronco marrom curto e grosso com raízes; cerca de 100 de largura x 112 de altura.
2) A mesma árvore com a copa de flores ROSA (3 tons de rosa), mesmo tamanho.
3) Toco da árvore cortada, com o topo claro e anéis simples; cerca de 40 x 32.
4) Pedra cinza grande arredondada com manchas de musgo verde; cerca de 48 x 36.
5) Arbusto redondo verde com 5 frutinhas vermelhas; cerca de 40 x 32.
6) Fogueira: anel de pedras cinza com toras e chama laranja-amarela simples; cerca de 40 x 34.
+ LIMPEZA
```

## Depois de gerar

Salvar só nos dois caminhos acima. Não mexer em `game/` nem em nenhum outro arquivo. Responder com os caminhos e o tamanho em pixels de cada imagem.

## 3. Natureza v2 (refeita em 30/10: a v1 veio com "pixels" de ~12 px, então a árvore ficou com só 34 px, menor que o personagem)

**Saída:** `art/sprites/processo_v2/candidatos/natureza_v2.png`. **Anexar também** `art/sprites/processo_v2/candidatos/personagens_v1.png` (mesma escala de pixel: os quadrados desta folha têm de ser do MESMO tamanho que os dos personagens).

```text
Imagem 1024x1536 (em pé) com grade de 2 colunas x 2 linhas. Cada célula tem 512x768 e contém UM quadro de 64x96 pixels ampliado EXATAMENTE 8x (cada pixel vira um quadrado de 8x8, o MESMO tamanho de quadrado dos personagens anexados). Base de cada objeto na mesma linha, 4 pixels acima da borda de baixo da célula.
1) Árvore grande de folhas verdes, com cerca de 60 de largura x 84 de altura (quase o dobro da altura do personagem anexado): copa redonda e fofa de 4 ou 5 "bolas" grandes de folha em 3 tons de verde, tronco marrom curto e grosso com raízes.
2) A mesma árvore com a copa de flores ROSA (3 tons de rosa).
3) Pedra cinza grande arredondada com manchas de musgo verde, cerca de 40 x 30, encostada na base da célula.
4) Arbusto redondo verde com 5 frutinhas vermelhas, cerca de 34 x 28, encostado na base da célula.
+ LIMPEZA
```
