# L23 · Arco na mão, com a corda sendo puxada

**Por quê (01/11):** o João achou estranho o arco na mão do Arqueiro: hoje vai o ícone do arco na diagonal, como uma espada, e fica ao contrário. Ele também pediu que fique claro quando o Arqueiro está carregando o tiro: a corda sendo puxada. O jogo monta a flecha e as mãos por cima; aqui só o ARCO, em pé, em 4 momentos da puxada, e uma flecha deitada.

**Anexar:**
1. `art/sprites/tiny/efeitos_icones/icones_armas_v1.png`: os ícones aprovados (o arco é o 2º). Copiar EXATAMENTE o estilo, o pixel, o contorno, as cores da madeira e da corda.
2. `art/sprites/tiny/efeitos_icones/icones_crafting_1_v1.png`: mais ícones aprovados, para o tamanho do pixel.

```text
FAÇA:
- Pixel art no MESMO estilo EXATO dos ícones anexados: quadrados de 8x8 na imagem (cada célula de 512 = 64 pixels de jogo), contorno de 1 pixel #161c2e, 2 ou 3 tons por material, luz de cima à esquerda, cores apagadas do Tiny Swords. O MESMO arco do 2º ícone anexado (mesma madeira, mesma corda clara).
- O arco EM PÉ (vertical), visto de lado, com a BARRIGA (a parte curva de madeira) virada para a DIREITA e a CORDA do lado ESQUERDO. A empunhadura (o meio do arco, com a faixa de couro) fica na metade da altura.
- Arco com 44 pixels de jogo de altura nos quadros 1 a 4 (na imagem: 352 px de altura), centralizado na célula.
- A barriga do arco (a ponta mais à direita da madeira) na MESMA posição em todos os quadros 1 a 4: só a corda e as pontas do arco mudam.
- Imagem 1536x1024, grade de 3 colunas x 2 linhas (células de 512x512), um desenho por célula. Fundo magenta chapado #FF00FF.

NÃO FAÇA:
- NÃO desenhe mão, braço, personagem nem flecha nos quadros 1 a 4 (o jogo põe a flecha e as mãos por cima).
- NÃO use quadrados de tamanhos diferentes, degradê dentro do quadrado, borrado nem anti-aliasing.
- NÃO use contorno preto puro, cores saturadas, rosa ou magenta no desenho.
- NÃO desenhe fundo, moldura, sombra no chão, rastro de movimento, brilho, texto ou número.

NÃO SIGA:
- NÃO siga "arco de RPG genérico" nem "sprite sheet de arqueiro": siga só os ícones anexados.
- NÃO deixe o arco na diagonal como o ícone: aqui ele fica em pé.
```

**Saída:** `art/sprites/tiny/candidatos/arco_puxando_v1.png`

```text
1) Arco em repouso: corda reta, esticada de ponta a ponta.
2) Corda puxada um pouco: o meio da corda 4 pixels de jogo para a esquerda (forma um V bem aberto), as pontas do arco curvam um pouco mais.
3) Corda puxada até a metade: o meio da corda 8 pixels de jogo para a esquerda, pontas mais curvadas.
4) Corda puxada toda: o meio da corda 12 pixels de jogo para a esquerda (V fechado), as pontas do arco bem curvadas para a esquerda.
5) Uma FLECHA DEITADA, apontando para a DIREITA: 30 pixels de jogo de comprimento, haste de madeira clara, ponta de pedra cinza, penas claras atrás. Igual à flecha do ícone aprovado, só que deitada.
6) vazia (só o fundo magenta).
```

## Depois de gerar

Salvar só no caminho acima. Não mexer em `game/` nem em nenhum outro arquivo. Responder com o caminho e o tamanho em pixels da imagem.
