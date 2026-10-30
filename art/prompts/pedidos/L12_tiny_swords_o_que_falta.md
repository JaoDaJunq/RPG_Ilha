# L12 · O que o pacote Tiny Swords não tem, no estilo dele

**Por quê (30/10):** o João mandou migrar o jogo para o estilo Tiny Swords. O terreno, as árvores, os arbustos, as pedrinhas e os personagens vêm do pacote. Faltam as peças abaixo, que precisam parecer do MESMO pacote.

**Régua de estilo (anexar em todos):**
- `art/terceiros/tiny_swords/Tiny Swords (Free Pack)/Terrain/Resources/Wood/Trees/Tree1.png`
- `art/terceiros/tiny_swords/Tiny Swords (Free Pack)/Buildings/Blue Buildings/House1.png`
- `art/terceiros/tiny_swords/Tiny Swords (Free Pack)/Terrain/Resources/Gold/Gold Stones/Gold Stone 3.png`
- `art/terceiros/tiny_swords/Tiny Swords (Free Pack)/Units/Blue Units/Pawn/Pawn_Idle.png`
- `evidence/fundacao/dia.png` (como o jogo está agora: as peças velhas do acampamento destoam)

**Estilo (copiar no começo de cada geração):**

```text
Arte NOVA no MESMO ESTILO EXATO do pacote Tiny Swords anexado: pixel art de traço grosso, contorno escuro azul-acinzentado grosso, formas redondinhas e simples, tons dessaturados, mesma luz, mesma sombra oval cinza-transparente no chão embaixo de cada objeto. Tem que parecer do MESMO pacote. Cada objeto isolado, centralizado na sua célula, com folga em volta. Fundo magenta chapado #FF00FF. Sem texto, sem grade desenhada, sem moldura, sem chão em volta.
```

## 1. Acampamento

**Saída:** `art/sprites/tiny/candidatos/acampamento_v1.png`

```text
Imagem 1536x1024 com grade de 3 colunas x 2 linhas (células de 512x512). Mesmo tamanho de pixel em todas as células, e o mesmo tamanho de pixel das árvores anexadas.
1) Fogueira acesa: anel de pedras cinza redondas, toras e chama laranja-amarela.
2) Barraca de lona clara com estacas de madeira, um pouco maior que a casinha anexada é pequena.
3) Baú de madeira com cantos de metal.
4) Barril de madeira com aros de metal.
5) Bancada de trabalho de madeira com um martelo e uma serra em cima.
6) Varal: dois postes de madeira com uma corda e um pano pendurado.
```

## 2. Natureza e criatura

**Saída:** `art/sprites/tiny/candidatos/natureza_v1.png`

```text
Imagem 1536x1024 com grade de 3 colunas x 2 linhas (células de 512x512). Mesmo tamanho de pixel das árvores anexadas.
1) Pedra grande cinza minerável (mesmo formato e tamanho da pedra de ouro anexada, mas pedra cinza comum com um pouco de musgo, sem ouro).
2) A mesma pedra rachada ao meio (depois de golpes de picareta).
3) Pinheiro QUEIMADO: o mesmo pinheiro anexado (Tree1, quadro 1), todo carbonizado, galhos pretos e cinza, sem folhas verdes, umas brasinhas laranja.
4) Cogumelo azul-turquesa brilhante pequeno (um grupinho de 3).
5) Slime verde translúcido fofo, parado (olhos simples).
6) O mesmo slime achatado no meio de um pulo.
```

## 3. Areia (tileset)

**Saída:** `art/sprites/tiny/candidatos/areia_tilemap_v1.png`

**Anexar também:** `art/terceiros/tiny_swords/Tiny Swords (Free Pack)/Terrain/Tileset/Tilemap_color1.png`

```text
Refaça a imagem anexada Tilemap_color1.png (tileset de terreno do Tiny Swords, 576x384, tiles de 64x64) EXATAMENTE com o mesmo layout, os mesmos recortes, as mesmas bordas e o mesmo contorno, ampliada para 1536x1024, trocando SÓ a grama por AREIA de praia clara (bege-amarelada, poucos detalhes: alguns pontinhos e conchinhas). As partes de penhasco e as transparências continuam iguais. Fundo transparente onde o original é transparente (ou magenta chapado #FF00FF).
```

## Depois de gerar

Salvar só nos três caminhos acima. Não mexer em `game/` nem em nenhum outro arquivo. Responder com os caminhos e o tamanho em pixels de cada imagem.
