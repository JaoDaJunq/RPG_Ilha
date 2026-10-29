# Identidade visual (bíblia)

> **Aprovada pelo João em 29/10/2026:** o conceito **B** é o visual de **dia** e o conceito **A** é a **noite** da mesma ilha. Referências: `art/conceitos/mundo/clareira_b_v1.png` (dia) e `art/conceitos/mundo/clareira_a_v1.png` (noite). Todo pedido de arte anexa as duas.
>
> Os números técnicos abaixo (tamanhos, contorno, paleta) são a primeira tradução dos conceitos para o jogo. Eles se confirmam no primeiro lote de sprites, com print dentro do jogo.

## Sensação

Uma ilha de fantasia **viva, colorida e convidativa de dia**, que fica **misteriosa e aconchegante à noite**. Personagens pequenos num mundo grande e cheio de detalhe. Ruínas antigas cobertas de musgo sugerem segredos.

- **Dia (B):** sol filtrado pelas copas, verdes amarelados e saturados, água turquesa, árvores de flor rosa, flores e frutas coloridas. Alegre sem ficar infantil.
- **Noite (A):** sombras azul-arroxeadas frias e luz quente de fogueira e magia. Cogumelos que brilham em azul-esverdeado, slimes verdes translúcidos. **A noite é feita pelo jogo** (escurecer + luzes), não por sprites diferentes: os sprites são desenhados de dia.

## Padrão técnico

| Item | Padrão |
|---|---|
| Perspectiva | Visão de cima em 3/4: vê o topo e a frente das coisas |
| Tile do chão | 16 × 16 px |
| Personagem | Quadro de 32 × 32 px, personagem com cerca de 28 px de altura (pés na linha 30) |
| Proporção | Chibi: cabeça grande (≈ 40% da altura), olhos grandes, corpo curto, silhueta clara |
| Árvore grande | Quadro de 64 × 64 px (copa larga; o tronco toca o chão no centro de baixo) |
| Pedra, arbusto, objeto pequeno | Quadro de 32 × 32 px |
| Contorno | 1 px, escuro e colorido (marrom-escuro ou verde-escuro, nunca preto puro) |
| Sombreamento | 2–3 tons por material, luz vindo de cima-esquerda |
| Direções | Personagens e criaturas: baixo, cima e direita (a esquerda é espelho da direita) |
| No jogo | Zoom inteiro (3×), sem filtro: pixels nítidos |

## Paleta (âncoras tiradas dos conceitos)

| Grupo | Cores |
|---|---|
| Grama de dia | `#B0D050` `#90B030` `#709030` `#507030` |
| Folhagem e sombra verde | `#509050` `#307050` `#305030` `#105030` |
| Pedra e ruína | `#707070` `#505050` `#303030` (+ musgo `#709030`) |
| Areia e terra | `#E8D08A` `#C8A060` `#8A6038` |
| Água | `#40C8D8` `#2090B0` (espuma `#E8F8F8`) |
| Flores e acentos | rosa `#E890B0`, vermelho `#D04040`, azul `#5070D0`, amarelo `#F0D040` |
| Noite (feita pelo jogo) | sombra `#101030` `#103050` `#303050`; luz `#F0A040`; brilho mágico `#40E0D0` |

## Regras de produção (valem para todo sprite)

- Cada folha tem **só o objeto ou personagem**. Nada de chão, sombra projetada, rastro, poeira, faísca ou brilho (o jogo faz os efeitos e a luz).
- **Todo estado tem a sua imagem** (árvore inteira, com marcas de machado, queimada, toco).
- O mesmo personagem tem o mesmo tamanho, cores e contorno em todas as folhas.
- Fundo magenta chapado `#FF00FF` nas folhas; o Claude troca por transparente.
- Nada parecido com personagem ou marca famosa.
- Aprovação só depois de ver o sprite **dentro do jogo**, ao lado dos outros, no zoom real.
- **Paleta curta e sem pixels soltos.** A IA entrega centenas de tons por sprite; toda folha é convertida com `--cores` e `--limpar` (ver `game/tools/medir_ruido.gd`). Meta: até ~16 cores por quadro e menos de 10% de pixels soltos, como pixel art de verdade (6–8 cores, ~5%).

## Lições do primeiro lote (L01)

- A IA não respeita a ampliação pedida: a árvore veio certinha (8x), a pedra com "pixel" de ~10 px e o aventureiro de ~6,6 px (o dobro da resolução pedida). A ferramenta `game/tools/importar_folha.gd` mede o tamanho real sozinha; quando vem fino demais, reduz pela metade (`--pixel` e `--escuro`), o que perde detalhe no rosto.
- Nos próximos pedidos de personagem, anexar o aventureiro já convertido (`game/assets/sprites/personagens/aventureiro.png` ampliado) como referência de tamanho de pixel.

## Placeholders atuais

Pacote **Ninja Adventure** (Pixel-boy e AAA, CC0) para chão, plantinhas, barraca, fogueira, slime, ícones e sons. O aventureiro, as árvores e as pedras já são arte própria (L01). O que falta trocar destoa (contorno preto mais grosso): próximo pedido é o chão e o acampamento.
