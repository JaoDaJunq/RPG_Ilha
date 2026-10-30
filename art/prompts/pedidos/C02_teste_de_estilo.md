# C02 · Teste de estilo: o jogo menos pixelado e mais polido

**Por quê:** o João achou o jogo "MUITO pixelado" duas vezes, mesmo depois de limpar o ruído das artes. O tamanho do pixel na tela (cada pixel da arte vira 3x3 na tela) é parecido com o do Core Keeper, então o problema é o estilo: a arte tem pixels grandes demais para o gosto dele. Antes de refazer tudo, ele escolhe o caminho vendo duas telas falsas do jogo, uma em cada estilo.

**Ele também pediu, e as telas já devem mostrar:**
- transição entre grama, terra, areia e água **suave e arredondada** (hoje faz degraus quebrados);
- painel do personagem e barra de habilidades com **layout melhor** (hoje ele não gosta);
- ícone da **armadilha do Arqueiro** tão claro quanto o ícone da flecha (hoje é um borrão escuro);
- **Ogro Arqueiro** sem ser "todo verde": capuz de couro marrom, para o rosto verde não se misturar com o capuz.

**Anexar nos dois:** `art/conceitos/mundo/clareira_b_v1.png` (cores e clima aprovados), `art/sprites/personagens/personagens_v1.png` (quem são os personagens) e `art/sprites/interface/icones_v1.png` (o ícone da flecha que o João acha bom).

**Regras (copiar no começo de cada geração):**

```text
TELA FALSA (mockup) de um jogo 2D co-op de sobrevivência visto de cima, numa clareira de ilha de fantasia, de dia. Imagem 1536x1024, como um print do jogo rodando. Use as cores e o clima da imagem anexada da clareira, e os personagens da folha anexada (mesmas roupas e cores), mas no ESTILO descrito abaixo.
Na tela: grama no meio; à esquerda um acampamento com chão de terra batida em volta de uma fogueira de pedras, um baú e uma mesa de trabalho; à direita uma praia de areia e depois água turquesa com espuma branca na beira. As bordas entre grama, terra, areia e água são CURVAS, SUAVES e ARREDONDADAS, sem degraus nem quadrados. Três ou quatro árvores grandes, uma pedra, alguns arbustos com frutinhas, um slime verde fofo.
Personagens: no centro o Humano Mago (capuz azul-escuro) de frente; ao lado o Ogro Arqueiro DE PERFIL andando, pele verde-acinzentada e CAPUZ DE COURO MARROM (não verde), o rosto bem separado do capuz.
Interface: em cima à esquerda um painel compacto e bonito do personagem (retratinho do rosto, nome "Nv 3 · Humano Mago", barra de vida vermelha, mana azul e experiência dourada); em cima à direita os recursos (galho, pedra, carvão com números); embaixo no centro uma barra de 6 espaços, os três primeiros com ícones claros e grandes: esquiva (botinha), flecha, e ARMADILHA DE URSO de metal com dentes abertos, bem legível, no mesmo acabamento do ícone de flecha anexado. Interface limpa, cantos arredondados, madeira escura com detalhes dourados discretos, texto legível.
Proibido: marca d'água, texto fora da interface, ruído, granulado.
```

## Saídas

| Arquivo | Estilo (acrescentar ao fim das regras) |
|---|---|
| `art/conceitos/estilo/candidatos/estilo_pixel_fino_v1.png` | PIXEL ART FINO e polido: pixels BEM MENORES que a imagem anexada (cada objeto tem o dobro de pixels de largura e de altura), formas limpas, poucas cores por objeto, sombreado suave em 3 tons, contorno escuro fino, nada de pixel solto. Sensação de Eastward e Sea of Stars. |
| `art/conceitos/estilo/candidatos/estilo_liso_v1.png` | DESENHO LISO, SEM PIXELS: ilustração 2D de desenho animado, formas arredondadas e fofas, cores chapadas com sombra suave, contorno escuro arredondado, personagens fofos de cabeça grande. Sensação de Cult of the Lamb e Ooblets. |

## Depois de gerar

Salvar só nos dois caminhos acima. Não mexer em `game/` nem em nenhum outro arquivo. Responder com os caminhos e o tamanho em pixels de cada imagem.
