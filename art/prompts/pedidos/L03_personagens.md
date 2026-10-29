# L03 · Personagens: desenhados no tamanho do jogo + teste de caracterização

**Por quê:** o João achou o aventureiro do L01 pixelado e feio. O L01 foi desenhado com detalhe demais e depois reduzido pela metade; o rosto virou sujeira. Personagens são um ponto forte do jogo. Agora o pedido é desenhar **direto no tamanho final**, com **poucos detalhes** e **bonitinho** (fofo, limpo, legível), e já testar a **caracterização** (raça × classe).

**Tamanho (não muda):** a ilha usa tile de 16 px e árvores de ~60 px; no conceito aprovado a árvore tem ~4× a altura do personagem. Então o personagem tem **cerca de 28 pixels de altura**. É o tamanho de personagens de Stardew Valley e Core Keeper: o charme vem de formas simples, não de detalhe.

**Anexar:** `art/conceitos/mundo/clareira_b_v1.png` (estilo e cores) e `evidence/importacao/aventureiro.png` (o aventureiro atual: é o TAMANHO certo, mas está feio por excesso de detalhe; o novo deve ser mais simples e mais bonito).

**Regras para as duas imagens (copiar no começo de cada geração):**

```text
PIXEL ART de verdade, MINIMALISTA e FOFA, para personagens de um jogo 2D visto de cima em 3/4. O personagem inteiro tem só 28 pixels de altura, então cada pixel conta: formas grandes e simples, poucas cores (no máximo 12 por personagem), contorno escuro de 1 pixel (marrom ou roxo bem escuro, não preto), sombreamento de no máximo 2 tons por cor, sem textura, sem detalhes miúdos, sem pixels soltos. Estilo chibi: cabeça grande (cerca de 45% da altura), olhos grandes e simples (2 pixels de largura por 2 ou 3 de altura, com 1 pixel de brilho), corpo pequeno e arredondado, expressão simpática. Pense em Stardew Valley e Core Keeper.
Imagem 1536x1024 com grade de 3 colunas x 2 linhas (cada célula 512x512). Cada célula é UM quadro de 32x32 pixels ampliado 16 vezes: cada pixel do desenho vira um quadrado ENORME de 16x16 na imagem, todos do mesmo tamanho e alinhados numa grade. Conte os quadrados: o personagem tem 28 quadrados de altura. Os pés ficam na mesma linha em todas as células, 2 quadrados acima da borda de baixo do quadro.
Fundo magenta chapado #FF00FF em toda a imagem. Cada célula tem só o personagem, de frente (olhando para a câmera), parado, braços ao lado do corpo, SEM arma na mão. Proibido: chão, sombra, brilhos, efeitos, texto, números, grade desenhada, moldura.
```

## 1. Teste de caracterização (raça × classe)

**Saída:** `art/sprites/personagens/candidatos/personagens_v1.png`

```text
Seis personagens do mesmo jogo, todos de frente, mesmo estilo e mesma proporção de cabeça:
1) HUMANO GUERREIRO: cabelo castanho curto, peitoral de couro marrom com ombreira de metal, túnica vermelha, botas.
2) HUMANO MAGO: cabelo castanho, capuz e manto azul-marinho com detalhes dourados, faixa na cintura.
3) HUMANO ARQUEIRO: cabelo castanho, capuz verde-folha, colete de couro, aljava pequena nas costas aparecendo atrás do ombro.
4) OGRO GUERREIRO: ogro FOFO, pele verde-oliva, duas presinhas brancas saindo da boca, orelhas pontudas pequenas, careca ou topete; 2 quadrados mais largo de cada lado e 2 quadrados mais alto que o humano (30 de altura); mesma roupa do Humano Guerreiro, no tamanho dele.
5) OGRO MAGO: o mesmo ogro com a roupa do Humano Mago (capuz e manto azul-marinho).
6) OGRO ARQUEIRO: o mesmo ogro com a roupa do Humano Arqueiro (capuz verde e colete).
O rosto e o corpo do humano são iguais nas células 1 a 3 (só a roupa muda); o rosto e o corpo do ogro são iguais nas células 4 a 6.
```

## 2. Teste de camadas (corpo + roupa separados)

**Saída:** `art/sprites/personagens/candidatos/camadas_v1.png`

```text
Teste de personagem em CAMADAS para montar raça + roupa no jogo. Todas as células usam EXATAMENTE a mesma posição e o mesmo tamanho do quadro: se as imagens forem colocadas uma em cima da outra, a roupa tem de encaixar perfeitamente no corpo.
1) HUMANO, só o CORPO: pele, rosto, cabelo castanho curto, roupa de baixo simples (camiseta e short bege), pés descalços.
2) Só a ROUPA DE MAGO, sem corpo nem cabeça visíveis: capuz e manto azul-marinho com detalhes dourados, exatamente onde ficariam sobre o corpo da célula 1 (o capuz em volta de onde fica a cabeça, sem cobrir o rosto).
3) Só a ROUPA DE GUERREIRO, sem corpo: peitoral de couro com ombreira de metal, túnica vermelha e botas, encaixada no corpo da célula 1.
4) OGRO, só o CORPO: pele verde-oliva, presinhas, roupa de baixo bege, pés descalços; 30 quadrados de altura e mais largo.
5) Só a ROUPA DE MAGO no tamanho do OGRO, encaixada no corpo da célula 4.
6) Montagem de conferência: o corpo da célula 1 com a roupa da célula 2 por cima (como deve ficar no jogo).
```

## Depois de gerar

Salvar só nos dois caminhos de saída acima (criar as pastas se faltar). Não mexer em `game/` nem em nenhum outro arquivo. Responder com os caminhos e o tamanho em pixels de cada imagem.
