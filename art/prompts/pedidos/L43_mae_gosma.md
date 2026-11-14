# L43 · Mãe Gosma, o primeiro boss (etapa 4)

**Por quê (13/11/2026):** é o primeiro guardião (`design/proposta_mundo.md`, seção 5). Ela fica no coração do Pântano, numa arena de água rasa, e é chamada pela Isca de Gosma posta no altar. A luta tem 3 fases:
1. pula e esmaga, soltando slimes pequenos;
2. muda de elemento: fogo, gelo ou veneno;
3. se divide em 3 gosmas menores.

**Método:** pixel art 4x, da MESMA família dos nossos slimes (L14 e L39 folha 09). O Claude converte com `importar_folha.gd --pixel=4 --paleta_de=res://assets/tiny_swords/paleta.png --sombra`.

**Anexar, nesta ordem (em todas as folhas):**
1. `art/prompts/reguas/objetos_4x.png`: o tamanho do pixel, o contorno, as cores apagadas e a sombra do Tiny Swords.
2. `game/assets/sprites/tiny/inimigos/slimes_elementos.png`: os nossos slimes de fogo, gelo e veneno. A Mãe Gosma é a "mãe" deles: o mesmo traço, o mesmo brilho, o mesmo tipo de olhos e as mesmas cores por elemento.
3. `art/sprites/tiny/candidatos/l42_06_lore.png`: célula 3, a Mãe Gosma desenhada na pedra de lore. É a ideia: gosma enorme, coroa dourada, cara sonolenta e convencida.

Salvar SÓ nos caminhos de saída, em `art/sprites/tiny/candidatos/`. Não mexer em `game/` nem em nenhum outro arquivo. Responder com o caminho e o tamanho de cada imagem.

## Regras (copiar no começo das folhas 01 a 04)

```text
TAREFA: folha de ANIMAÇÃO de 6 quadros da MÃE GOSMA, um BOSS: uma gosma ENORME e redondinha (a "mãe" dos slimes da imagem 2), com uma COROA dourada pequena e torta no topo (#e8a33c, luz #ffd23f, contorno escuro), dois olhos grandes meio fechados de sono e convencimento, uma boca larga e um brilho de gosma no alto à esquerda. Dentro da barriga, meio transparente, aparece uma SEMENTE verde-água brilhando (#5fbf9f, miolo #e6fff4).
Pixel art no MESMO estilo da imagem 1 (Tiny Swords) e dos slimes da imagem 2. Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512, um quadro por célula, da esquerda para a direita e de cima para baixo. Fundo magenta chapado #FF00FF.
Quadrados de 4x4 na imagem (cada 4 px = 1 pixel de jogo; cada célula = 128x128 pixels de jogo), sem anti-aliasing. Contorno #161c2e de 1 pixel de jogo. 2 ou 3 tons por cor, luz de cima à esquerda.
TAMANHO: no quadro 1, a gosma tem ~96 pixels de jogo de largura e ~72 de altura com a coroa. A BASE da gosma SEMPRE na MESMA linha, 16 px de jogo (64 px da imagem) acima do fundo da célula, centralizada na horizontal (exceto no quadro 4, que está no ar).
OS 6 QUADROS:
1) PARADA: redonda, olhos sonolentos, sorrisinho.
2) RESPIRANDO: a mesma, 4 px de jogo mais baixa e mais larga (achatadinha), para alternar com o 1.
3) AGACHANDO: bem achatada e larga (~110 x 52), olhos apertados de força, prestes a pular.
4) NO AR: esticada para cima (~80 x 88), olhos abertos, boca em "O", com a base 28 px de jogo ACIMA da linha das outras (ela pulou).
5) ESMAGANDO: caiu, MUITO achatada e larga (~120 x 40), com respingos de gosma dos dois lados (gotas soltas), olhos fechados com força.
6) MACHUCADA: encolhida, olhos em X, a boca tremida, a coroa inclinada.
FAÇA: formas redondinhas e simples, cores apagadas do Tiny Swords, rosto legível de longe.
NÃO FAÇA: texto, chão, água, poça, sombra no chão (o jogo põe), fundo, moldura, anti-aliasing, degradê, brilho borrado; nada encostando na borda da célula.
NÃO SIGA: monstro realista, nojento ou assustador; ela é fofa e convencida como os nossos slimes.
```

### Folha 01 · Mãe Gosma normal (verde, fase 1)
**Saída:** `l43_01_mae_gosma.png`

```text
(regras) + COR: verde-limão da gosma do pântano (#9ccf4a, sombra #6f9d36, escuro #4f7a2a, brilho #e3f5a4), como o slime venenoso da imagem 2, só que mais claro e alegre.
```

### Folha 02 · Mãe Gosma de FOGO (fase 2)
**Saída:** `l43_02_mae_gosma_fogo.png`

```text
(regras) + COR: as MESMAS cores do slime de FOGO da imagem 2 (laranja e vermelho, brilho amarelo), com 3 a 4 chaminhas pequenas saindo do topo ao lado da coroa. Os MESMOS desenho e poses da folha 01, só a cor e as chaminhas mudam.
```

### Folha 03 · Mãe Gosma de GELO (fase 2)
**Saída:** `l43_03_mae_gosma_gelo.png`

```text
(regras) + COR: as MESMAS cores do slime de GELO da imagem 2 (azul-claro e branco), com 3 a 4 cristaizinhos de gelo pontudos no topo ao lado da coroa. Os MESMOS desenho e poses da folha 01, só a cor e os cristais mudam.
```

### Folha 04 · Mãe Gosma VENENOSA (fase 2)
**Saída:** `l43_04_mae_gosma_veneno.png`

```text
(regras) + COR: as MESMAS cores do slime VENENOSO da imagem 2 (roxo e verde-ácido), com 3 bolhas pequenas no topo ao lado da coroa. Os MESMOS desenho e poses da folha 01, só a cor e as bolhas mudam.
```

## Folha 05 · Peças da arena e itens (pixel art; ícones em 8x)
**Saída:** `l43_05_arena_itens.png`

```text
TAREFA: folha de 6 peças em pixel art no estilo da imagem 1 (Tiny Swords). Imagem 1536x1024, grade 3x2, células de 512x512, fundo magenta chapado #FF00FF, cada peça centralizada.
Células 1 a 3: pixel art 4x (cada 4 px = 1 pixel de jogo). Células 4 a 6: ÍCONES em pixel art 8x (cada 8 px = 1 pixel de jogo), ocupando ~70% da célula. Contorno #161c2e de 1 pixel de jogo, sem anti-aliasing.
1) ALVO DA QUEDA: uma elipse vista de cima (~100 x 44 pixels de jogo), só o CONTORNO grosso (3 pixels de jogo) em verde-gosma escuro (#4f7a2a) com 4 gotinhas em volta. É a marca no chão de onde a Mãe Gosma vai cair. Miolo vazio (magenta).
2) POÇA DE GOSMA: uma poça rasa e irregular de gosma verde-limão (#9ccf4a, sombra #6f9d36, brilho #e3f5a4), ~64 x 28 pixels de jogo, vista de cima.
3) COROA CAÍDA: a coroa dourada da Mãe Gosma tombada de lado no chão, com uma gota de gosma (~28 x 20 pixels de jogo). Fica no chão quando ela é derrotada.
4) ÍCONE GOSMA REAL: um pote de vidro pequeno com gosma verde-limão brilhante dentro e uma coroinha dourada na tampa.
5) ÍCONE POÇÃO DE CURA FORTE: um frasco redondo grande com líquido vermelho-coral (#e8605a) e uma gotinha verde de gosma boiando, rolha de cortiça.
6) ÍCONE CAVEIRA DE BOSS: uma carinha de gosma com coroa, em silhueta simples (verde e dourado), para o mapa e a barra de vida do boss.
NÃO FAÇA: texto, fundo, moldura, anti-aliasing, degradê.
```
