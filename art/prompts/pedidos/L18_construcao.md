# L18 · Peças de construção no mundo (parede, porta, chão, tocha)

**Por quê (31/10):** com o inventário estilo Minecraft, o jogador fabrica parede, porta, chão e tocha e coloca no mundo. Os ícones já existem (L17); faltam as peças como aparecem no chão, no MESMO estilo do acampamento do L14 (aprovado pelo João).

**Anexar, nesta ordem:**
1. `art/prompts/reguas/objetos_4x.png`: **A RÉGUA** do pacote em 4x (tamanho do pixel, contorno, cores).
2. `art/sprites/tiny/acampamento_v2.png`: o nosso acampamento aprovado (L14). Copiar o acabamento da madeira, o contorno e as cores.
3. `art/sprites/tiny/efeitos_icones/icones_crafting_2_v1.png`: os ícones da parede, da porta e do chão (L17). As peças têm de ser as mesmas coisas, agora no tamanho do mundo.

**Regras (copiar no começo):**

```text
FAÇA:
- Pixel art no MESMO estilo da régua e do acampamento anexados: quadrados de 4x4 na imagem (cada célula de 512 = 128 pixels de jogo), contorno de 1 pixel #161c2e, sombreamento em 2 ou 3 tons, luz de cima à esquerda, vistos de cima em 3/4, cores apagadas do Tiny Swords: madeira #977b6b #8d6857 #c8a876 #cf9c71 #5e5455; metal #688c8a #9cbeaa #485884; contorno #161c2e.
- Imagem 1536x1024, grade de 3 colunas x 2 linhas (células de 512x512), uma peça por célula, centralizada, base 32 px acima do fundo da célula. Fundo magenta chapado #FF00FF.
- As medidas abaixo são em PIXELS DE JOGO (na imagem, multiplique por 4).

NÃO FAÇA:
- NÃO use quadrados de tamanhos diferentes, degradê dentro do quadrado, borrado ou anti-aliasing.
- NÃO use contorno preto puro nem contorno com 2 ou mais pixels.
- NÃO use cores saturadas (nada de laranja vivo na madeira).
- NÃO desenhe sombra no chão, grama, chão em volta, texto ou moldura.
- NÃO deixe a peça maior ou menor do que a medida pedida.

NÃO SIGA:
- NÃO siga "pixel art de RPG genérico" nem o Minecraft (blocos quadrados): siga só a régua e o acampamento.
```

**Saída:** `art/sprites/tiny/candidatos/construcao_v1.png`

```text
(regras) +
1) PAREDE de troncos de madeira em pé, um segmento: 64 de largura x 80 de altura (a frente dos troncos e o topo deles aparecendo, vista de cima em 3/4). As laterais retas, para encaixar com outro segmento igual ao lado sem emenda.
2) PORTA de tábuas FECHADA, com dobradiças de metal, dentro de um batente de troncos: 64 x 80 (do mesmo tamanho da parede, para ficar no meio de uma parede).
3) A MESMA PORTA ABERTA: o batente igual, a porta virada para dentro (dá para ver o vão escuro).
4) CHÃO de tábuas visto de cima: um quadrado de 64 x 64 preenchendo a medida toda, tábuas na horizontal, que se repete lado a lado sem emenda (sem contorno em volta).
5) TOCHA em pé: um poste fino de madeira fincado no chão com a ponta enrolada em pano e uma chama laranja-amarela pequena: 16 x 48.
6) vazio (só o fundo magenta).
```

## Depois de gerar

Salvar só no caminho acima. Não mexer em `game/` nem em nenhum outro arquivo. Responder com o caminho e o tamanho em pixels da imagem.
