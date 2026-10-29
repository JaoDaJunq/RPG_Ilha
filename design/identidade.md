# Identidade visual (rascunho)

> **Rascunho.** Nada aqui está aprovado. Vira regra depois que o João escolher o conceito do pedido C01 (`art/prompts/pedidos/C01_conceito_visual.md`).

## Sensação

Uma ilha de fantasia **colorida de dia e misteriosa à noite**. Inspirada no Core Keeper: personagens pequenos num mundo cheio de detalhe, **iluminação** fazendo boa parte do trabalho (fogueira, magia, cogumelos que brilham), contraste forte entre luz quente e sombra fria.

## Proposta técnica (a confirmar com o conceito)

| Item | Proposta |
|---|---|
| Perspectiva | Visão de cima em 3/4 (vê o topo e a frente das coisas), como Core Keeper e Stardew |
| Tile | 16 × 16 px |
| Personagem | cerca de 24 px de altura (1,5 tile), cabeça grande, silhueta clara |
| Escala no jogo | zoom inteiro (3× ou 4×), sem filtro: pixels nítidos |
| Contorno | 1 px, cor escura da paleta (não preto puro) |
| Sombra | 2 tons por material, luz vindo de cima-esquerda |
| Direções | 4 (baixo, cima, esquerda, direita); direita pode ser espelho da esquerda se a roupa for simétrica |
| Luz | O sprite não traz brilho desenhado; o jogo adiciona luz (PointLight2D) e o ciclo dia/noite |

## Regras que já valem (herdadas do Smash Junq)

- Cada folha tem **só o objeto ou personagem**; nada de chão, sombra projetada, rastro, poeira ou brilho (o jogo faz os efeitos).
- Todo objeto que muda de estado tem uma imagem para cada estado (árvore inteira, sendo cortada, toco, queimada).
- O mesmo personagem tem o mesmo tamanho, as mesmas cores e o mesmo contorno em todas as folhas.
- Nada parecido com personagem ou marca famosa.

## Placeholders atuais

Pacote **Ninja Adventure** (Pixel-boy e AAA, CC0), escolhido por ser de um estilo só e 16 px. Não é a direção final; serve para testar a mecânica sem misturar estilos.
