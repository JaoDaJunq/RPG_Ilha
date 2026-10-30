# L10 · Teste do estilo DESENHO HD (o que a IA faz bem)

**Por quê (30/10):** o João perguntou se dá para mudar para o estilo em que a IA é boa. Em pixel art a IA desenha grande e nós reduzimos para poucos pixels, e é aí que a qualidade se perde. Em desenho de alta resolução, o jogo usa a arte quase no tamanho em que foi desenhada. Este lote vai para o mesmo lugar do jogo que o piloto de pixel v2 (L09), para comparar lado a lado.

**Anexar:** `art/conceitos/estilo/candidatos/estilo_liso_v1.png` (o estilo "desenho liso" do teste C02) e `art/sprites/personagens/personagens_v1.png` (só QUEM são o Mago e o Ogro Arqueiro: roupas e cores).

**Saída:** `art/sprites/desenho_hd/candidatos/hd_v1.png`

```text
ARTE DE JOGO 2D EM DESENHO DE ALTA RESOLUÇÃO, NÃO é pixel art: estilo desenho animado fofo e limpo, como a tela anexada (desenho liso) e como o jogo Tiny Swords. Formas arredondadas e simples, cores chapadas com UM tom de sombra suave (cel shading), contorno escuro marrom-arroxeado grosso e uniforme (cerca de 6 pixels nesta imagem) em volta de cada objeto, sem textura, sem ruído, sem degradê forte, sem pixels visíveis. Luz de cima à esquerda. Visão de cima em 3/4.
Imagem 1536x1024 com grade de 3 colunas x 2 linhas (células de 512x512). Cada célula tem UM objeto isolado, centralizado, com a base perto da borda de baixo e bastante folga em volta. Fundo magenta chapado #FF00FF, sem sombra no chão, sem chão, sem texto, sem moldura.
1) HUMANO MAGO de frente, parado, chibi fofo (cabeça grande): capuz azul-escuro com borda dourada, cabelo castanho, olhos grandes e brilhantes, bochecha rosada, túnica azul com cinto marrom, botas marrons. Cerca de 380 px de altura.
2) OGRO ARQUEIRO de frente, parado, chibi fofo, mesma altura: pele verde-acinzentada, CAPUZ DE COURO MARROM, olhos simpáticos, boca com duas presinhas brancas pequenas saindo do lábio de baixo, colete de couro, aljava nas costas.
3) Árvore grande de copa redonda verde, fofa, feita de bolas de folha, tronco marrom curto: ocupa quase a célula inteira.
4) A mesma árvore com a copa de flores ROSA.
5) Pedra cinza arredondada com musgo verde, cerca de 300 px de largura.
6) Arbusto redondo verde com frutinhas vermelhas, cerca de 300 px de largura.
```

## Depois de gerar

Salvar só no caminho acima. Não mexer em `game/` nem em nenhum outro arquivo. Responder com o caminho e o tamanho em pixels da imagem.
