# L20 · Ícones das armas de classe e da gosma curativa

**Por quê (31/10):** com os personagens por peças (L19), a arma da classe vira um item que vai na mão, como as ferramentas: o Guerreiro começa com espada, o Mago com cajado e o Arqueiro com arco. Faltam o cajado e o arco. Também falta o item novo feito com gel de slime.

**Anexar:**
1. `art/sprites/tiny/efeitos_icones/icones_crafting_1_v1.png`: os ícones aprovados (L17). Copiar exatamente o estilo, o pixel, o contorno e o tamanho.
2. `art/sprites/tiny/efeitos_icones/icones_crafting_2_v1.png`.

```text
FAÇA:
- Ícones no MESMO estilo EXATO dos ícones anexados: pixel art com quadrados de 8x8 na imagem (64 pixels de jogo por célula), objeto ocupando cerca de 40 x 40 dos 64 pixels, contorno de 1 pixel #161c2e, 2 ou 3 tons, luz de cima à esquerda, cores apagadas do Tiny Swords.
- Ferramentas e armas na DIAGONAL, com o cabo embaixo à esquerda e a ponta em cima à direita (igual ao machado e à espada anexados): é assim que vão na mão do personagem.
- Imagem 1536x1024, grade de 3 colunas x 2 linhas (células de 512x512), um ícone por célula, centralizado. Fundo magenta chapado #FF00FF.

NÃO FAÇA:
- NÃO use quadrados de tamanhos diferentes, degradê dentro do quadrado, borrado nem anti-aliasing.
- NÃO use contorno preto puro, cores saturadas, rosa ou magenta no desenho.
- NÃO desenhe fundo, moldura, sombra no chão, texto ou número.

NÃO SIGA:
- NÃO siga "ícone de RPG genérico": siga só os ícones anexados.
```

**Saída:** `art/sprites/tiny/candidatos/icones_armas_v1.png`

```text
1) Cajado de mago: cabo de madeira torto na diagonal com uma pedra azul-turquesa (#4697ac, brilho #ffffff) na ponta, presa por galhinhos.
2) Arco curto de madeira na diagonal, com a corda clara, sem flecha.
3) Espada de ferro: lâmina de metal claro (#9cbeaa, #688c8a) na diagonal, guarda e cabo marrom (a espada inicial do Guerreiro).
4) Gosma curativa: um pote pequeno de vidro com gosma verde (#44a079, #39cd6a) e uma cruz vermelha pequena (#e76161) no rótulo.
5) Flecha na diagonal (ponta de pedra cinza, penas claras).
6) vazia (só o fundo magenta).
```

## Depois de gerar

Salvar só no caminho acima. Não mexer em `game/` nem em nenhum outro arquivo. Responder com o caminho e o tamanho em pixels da imagem.
