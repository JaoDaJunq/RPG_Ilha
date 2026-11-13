# L35 · Melhorias de arte: peças no tamanho real, parede de luz, baú trancado, chave, crítico e molhado

**Por quê (13/11/2026):** algumas peças do L33 eram AMPLIADAS 2 a 5 vezes no jogo para cobrir a área da habilidade (cúpula de luz, círculo de cura, poça de ácido, nuvem tóxica, tornado, nevasca, golem, totem tesla). Ampliadas, o pixel delas fica 2 a 5 vezes mais grosso que o do resto do jogo. Agora cada uma é desenhada JÁ no tamanho em que aparece, e entra no jogo sem ampliar. Também faltavam: a Barreira do Clérigo como parede de LUZ de verdade, o baú trancado, a chave, o efeito do crítico e as gotinhas do Molhado.

**Anexar em todas as folhas:**
1. `art/prompts/reguas/objetos_4x.png`: a régua do pacote Tiny Swords (o estilo a copiar e o TAMANHO DO PIXEL a copiar).
2. `art/sprites/tiny/acampamento_v2.png`: os nossos objetos aprovados (o baú do meio é o baú do acampamento).

**Regras (copiar no começo do texto de toda folha):**

```text
FAÇA:
- Pixel art no MESMO estilo da régua (Tiny Swords) e do acampamento anexados: contorno de 1 pixel #161c2e, 2 ou 3 tons por material, luz de cima à esquerda, visto de cima em 3/4, cores apagadas do Tiny Swords.
- Cada "pixel" do desenho é um QUADRADO do tamanho dito na folha (4x4 ou 3x3 ou 8x8 pixels da imagem), todos do mesmo tamanho, alinhados numa grade única.
- A peça é GRANDE de propósito: ela ocupa a área de uma habilidade no jogo. Desenhe com MUITOS pixels pequenos, como a régua (a ovelha da régua tem uns 40 pixels de largura). NÃO desenhe com blocos grossos.
- Medidas em PIXELS DA ARTE (multiplique pelo tamanho do quadrado para ter as medidas na imagem). As medidas na imagem também vão escritas.
- Efeitos de magia: formas simples, cor do elemento (luz dourada, cura verde-clara, veneno verde, fogo laranja, gelo azul-claro), com transparência feita só com pixels mais claros e espaçados (sem degradê).
- Fundo magenta chapado #FF00FF.

NÃO FAÇA:
- NÃO use quadrados de tamanhos diferentes, degradê, borrado ou anti-aliasing.
- NÃO use contorno preto puro nem cores saturadas demais.
- NÃO desenhe chão, grama, sombra no chão, texto, número, grade ou moldura.
- NÃO encoste na borda da imagem ou da célula (deixe pelo menos 16 pixels da imagem de folga).
- NÃO desenhe a peça menor do que a medida pedida.

NÃO SIGA:
- NÃO siga "pixel art de RPG genérico" nem a arte antiga do jogo: siga a régua.
```

Célula marcada "vazia": só o fundo magenta.

**Saída:** `art/sprites/tiny/candidatos/l35_<NN>.png` (NN = número da folha, 1536x1024).

---

## Folha 01: CÚPULA DE LUZ média (quadrado de 4x4; uma peça na imagem inteira)
Meia bolha de luz dourada transparente vista de lado em 3/4, como uma redoma sobre o chão: só o contorno dourado claro (2 pixels de largura, com um fio mais claro por dentro), uma faixa de brilho na curva de cima à esquerda, e alguns brilhinhos em cruz de 3x3 espalhados por dentro. O MEIO fica VAZIO (fundo magenta), para ver quem está dentro. A base é uma elipse achatada (só a borda de trás e da frente, finas).
**352 x 190 pixels da arte = 1408 x 760 na imagem**, centralizada.

## Folha 02: CÚPULA DE LUZ grande (quadrado de 3x3; uma peça na imagem inteira)
A MESMA cúpula da folha 01, maior. **496 x 264 pixels da arte = 1488 x 792 na imagem** (quadrado de 3x3 pixels da imagem), centralizada. Mesma grossura de contorno em pixels da arte (2 pixels da arte = 6 pixels da imagem).

## Folha 03: CÍRCULO DE CURA (quadrado de 4x4; uma peça na imagem inteira)
Anel de luz verde-clara deitado no chão, visto de cima em 3/4 (uma elipse larga e achatada): borda dupla (dois anéis finos, 2 pixels da arte cada), entre eles cruzinhas verdes de 5x5 e brilhos. O MEIO fica VAZIO (magenta), para ver o chão.
**288 x 140 pixels da arte = 1152 x 560 na imagem**, centralizado.

## Folha 04: CÍRCULO DE CURA grande (quadrado de 3x3; uma peça na imagem inteira)
O MESMO círculo da folha 03, maior: **496 x 236 pixels da arte = 1488 x 708 na imagem** (quadrado de 3x3), centralizado.

## Folha 05: POÇA DE ÁCIDO e PAREDE DE LUZ (quadrado de 4x4; 1 coluna x 2 linhas, células de 1536 x 512)
1. Linha de cima: POÇA DE ÁCIDO deitada no chão, vista de cima em 3/4: poça amarelo-esverdeada de borda irregular (com 3 ou 4 gotas soltas em volta), 2 ou 3 tons, bolhas de 3 a 5 pixels, brilho claro em cima à esquerda. **224 x 96 pixels da arte = 896 x 384 na imagem**, centralizada na célula.
2. Linha de baixo: PAREDE DE LUZ (a Barreira do Clérigo): uma parede de LUZ dourada, reta, vista de frente, larga e baixa. Ela é TRANSLÚCIDA: feita de faixas verticais de pixels dourados claros e brancos-amarelados com espaços de fundo entre elas (como uma cortina de luz), mais densa embaixo e se desfazendo em pixels soltos em cima. Borda de cima ondulada e suave (pixels mais claros e espaçados, sem degradê), uma linha dourada mais forte na base, 6 a 8 brilhos em cruz de 3x3. NÃO é uma tábua, NÃO tem contorno escuro em volta, NÃO é sólida. **256 x 88 pixels da arte = 1024 x 352 na imagem**, centralizada na célula.

## Folha 06: NUVEM TÓXICA (quadrado de 4x4; uma peça na imagem inteira)
Nuvem verde gorda e baixa, vista de cima em 3/4, que cobre uma área redonda: vários rolos de fumaça verde (3 tons de verde do Tiny Swords, o mais claro em cima), bolhas de 3 a 6 pixels saindo, sem símbolos. Borda de rolinhos redondos com contorno #161c2e. **256 x 150 pixels da arte = 1024 x 600 na imagem**, centralizada.

## Folha 07: TORNADO DE FOGO e TOTEM TESLA (quadrado de 4x4; 3 colunas x 1 linha, células de 512 x 1024)
1. TORNADO DE FOGO, quadro A: funil de fogo laranja, vermelho e amarelo, largo em cima e fino embaixo, com faixas de chama em espiral. **96 x 132 pixels da arte = 384 x 528 na imagem**. Base (a ponta de baixo) 64 pixels da imagem acima do fundo da célula.
2. O MESMO TORNADO, quadro B: as faixas de chama giradas (desenho igual em tamanho e posição, só as faixas mudam de lugar).
3. TOTEM TESLA: poste de metal cinza-azulado com base de pedra, bobina de cobre enrolada em cima e uma bolinha amarela brilhando no topo, com 2 risquinhos de faísca. **60 x 136 pixels da arte = 240 x 544 na imagem**. Base 64 pixels da imagem acima do fundo da célula.

## Folha 08: GOLEM DE PEDRA (quadrado de 4x4; 2 colunas x 1 linha, células de 768 x 1024; de perfil olhando para a DIREITA)
1. GOLEM parado: corpo de pedras cinza-azuladas empilhadas (as pedras da régua), musgo verde nos ombros, olhos verdes brilhando, braços grossos até perto do chão, pernas curtas. **140 x 134 pixels da arte = 560 x 536 na imagem**. Pés 64 pixels da imagem acima do fundo da célula.
2. O MESMO GOLEM dando um soco: o braço da frente esticado para a direita, o corpo inclinado. **166 x 130 pixels da arte = 664 x 520 na imagem**. Pés na mesma altura.

## Folha 09: NEVASCA (quadrado de 4x4; 2 colunas x 1 linha, células de 768 x 1024)
1. NEVASCA: nuvem baixa branco-azulada (tons de gelo do Tiny Swords) com flocos de neve de 3x3 e 5x5 caindo embaixo dela, vista de cima em 3/4. **148 x 150 pixels da arte = 592 x 600 na imagem**, centralizada.
2. vazia.

## Folha 10: BAÚ TRANCADO (quadrado de 8x8; grade 3x2, células de 512 x 512)
O baú do acampamento anexado (o do meio da folha do acampamento), nas MESMAS cores e no MESMO ângulo. **50 x 44 pixels da arte = 400 x 352 na imagem** (quadrado de 8x8: o baú ocupa quase a célula toda), base 48 pixels da imagem acima do fundo da célula. (1ª tentativa: veio com 35 pixels de largura, pequeno demais; agora são 50.)
1. BAÚ TRANCADO: o baú fechado com uma corrente de ferro cinza cruzada na frente (de um lado ao outro, passando por cima da tampa) e um CADEADO grande de ferro escuro com buraco de chave, no meio da frente.
2. BAÚ ABERTO: o mesmo baú com a tampa levantada para trás, a corrente partida caída dos lados, o cadeado aberto pendurado. Dentro, um brilho dourado.
3. vazia.
4. vazia.
5. vazia.
6. vazia.

## Folha 11: EFEITOS: CRÍTICO e MOLHADO (quadrado de 4x4; grade 3x2, células de 512 x 512)
Cada desenho centralizado na célula (o centro do desenho no centro da célula).
1. CRÍTICO, quadro 1: estouro de impacto pequeno: estrela branca de 4 pontas com miolo amarelo, **24 x 24 pixels da arte = 96 x 96 na imagem**.
2. CRÍTICO, quadro 2: o estouro no máximo: estrela de 8 pontas amarelo-alaranjada com miolo branco e contorno #161c2e, com 4 riscos de impacto saindo em volta, **52 x 52 pixels da arte = 208 x 208 na imagem**.
3. CRÍTICO, quadro 3: o estouro se desfazendo: só os 8 riscos e 4 ou 5 faíscas soltas em volta, amarelo-claro, sem o miolo, **56 x 56 pixels da arte = 224 x 224 na imagem**.
4. MOLHADO, quadro 1: gotinhas de água caindo (o desenho fica em volta da cabeça de um personagem de ~22 x 30 pixels da arte, que NÃO aparece): 4 gotas azul-claras (#7dc4d6 e branco) com contorno #161c2e, cada uma com 3 x 5 pixels da arte (12 x 20 na imagem), espalhadas numa área de **40 x 36 pixels da arte = 160 x 144 na imagem**, o meio vazio.
5. MOLHADO, quadro 2: as mesmas gotas 4 pixels da arte mais para baixo, uma nova aparecendo em cima.
6. MOLHADO, quadro 3: as gotas mais 4 pixels para baixo, a de baixo virando um respingo pequeno (3 pontinhos).

## Folha 12: ÍCONE DE CHAVE (quadrado de 8x8; grade 3x2, células de 512 x 512)
1. CHAVE (ícone de item, como os ícones do jogo): chave antiga de ferro, com argola redonda e dentes, deitada na diagonal (argola em cima à esquerda). Ferro cinza-azulado com brilho, 2 ou 3 tons, contorno #161c2e. **~30 x 30 pixels da arte = 240 x 240 na imagem**, centralizada.
2. vazia.
3. vazia.
4. vazia.
5. vazia.
6. vazia.

Salvar só nos caminhos acima. Não mexer em `game/` nem em nenhum outro arquivo.

---

## 2ª tentativa das folhas 05 a 09: ILUSTRAÇÃO (13/11)

**O que deu errado na 1ª:** a poça, a nuvem, o tornado, o totem, o golem e a nevasca vieram com "pixels" de 8 a 16 px na imagem (o jeito de desenhar da IA). Convertidos no tamanho certo, ficariam com o pixel 2 a 4 vezes mais grosso que o do pacote, o mesmo defeito que queremos tirar. A parede de luz veio boa de ideia, mas também grossa.

**Agora:** o mesmo método dos personagens (L30, L31, L34): a IA desenha uma ILUSTRAÇÃO lisa e grande, e o `pixelizar.gd` reduz para o tamanho do jogo com a paleta do pacote. A régua e o acampamento continuam anexados, mais `art/sprites/tiny/referencias/estilo_ilustracao.png` (o acabamento).

```text
TAREFA: ILUSTRAÇÃO 2D limpa (NÃO pixel art), grande, com contorno #161c2e grosso (~6 px), cores chapadas do Tiny Swords (apagadas) com 1 ou 2 tons de sombra suaves, luz de cima à esquerda, vista de cima em 3/4. Fundo magenta chapado #FF00FF.

FAÇA:
- Desenho grande, ocupando quase toda a célula (ele vai ser reduzido 3 a 4 vezes).
- Formas grandes e simples: nada fino demais (linhas com menos de 8 px somem na redução).

NÃO FAÇA:
- NÃO desenhe pixel art, quadradinhos, serrilhado, textura de ruído ou degradê forte.
- NÃO desenhe chão, sombra no chão, texto ou moldura.
- NÃO encoste na borda da célula (pelo menos 24 px de folga).

NÃO SIGA:
- NÃO siga a 1ª tentativa (pixel art grossa).
```

### Folha 05b (1536x1024, 1 coluna x 2 linhas, células de 1536 x 512)
1. Linha de cima: POÇA DE ÁCIDO deitada no chão, vista de cima em 3/4: poça amarelo-esverdeada de borda irregular com 3 ou 4 gotas soltas em volta, bolhas, brilho claro em cima à esquerda. Larga e achatada: **~1300 x 440 px** (proporção 7 por 3), centralizada.
2. Linha de baixo: PAREDE DE LUZ (Barreira do Clérigo), vista de frente, larga e baixa (**~1300 x 430 px**, proporção 3 por 1): uma cortina de LUZ dourada TRANSLÚCIDA feita de faixas verticais claras (amarelo-claro e branco-amarelado) com ESPAÇOS de fundo magenta entre elas, mais densa embaixo e se desfazendo em pontinhos em cima, uma faixa dourada na base e 6 a 8 brilhos em cruz. SEM contorno escuro em volta: é luz, não é uma tábua.

### Folha 06b (1536x1024, uma peça)
NUVEM TÓXICA: nuvem verde gorda e baixa, vista de cima em 3/4, feita de rolos redondos de fumaça (3 tons de verde apagado, o mais claro em cima), bolhas verdes subindo. **~1300 x 760 px** (proporção 5 por 3), centralizada.

### Folha 07b (1536x1024, 3 colunas x 1 linha, células de 512 x 1024)
1. TORNADO DE FOGO, quadro A: funil de fogo laranja, vermelho e amarelo, largo em cima e fino embaixo, com faixas de chama em espiral e algumas chamas soltas em volta. **~420 x 580 px**, a ponta de baixo 120 px acima do fundo da célula.
2. O MESMO TORNADO, quadro B: igual em tamanho e lugar, com as faixas de chama giradas.
3. TOTEM TESLA: poste de metal cinza-azulado com base de pedras, bobina de cobre enrolada em cima e uma bolinha amarela brilhando no topo, com 2 faíscas. **~190 x 430 px** (fino e alto), base 120 px acima do fundo da célula.

### Folha 08b (1536x1024, 2 colunas x 1 linha, células de 768 x 1024; de perfil olhando para a DIREITA)
1. GOLEM DE PEDRA parado: corpo de pedras cinza-azuladas empilhadas, musgo verde nos ombros, olhos verdes brilhando, braços grossos até perto do chão, pernas curtas. **~620 x 600 px**, pés 120 px acima do fundo da célula.
2. O MESMO GOLEM, no MESMO tamanho, dando um soco: o braço da frente esticado para a direita, o corpo inclinado. Pés na mesma altura.

### Folha 09b (1536x1024, uma peça)
NEVASCA: nuvem baixa branco-azulada (tons de gelo do Tiny Swords) com flocos de neve grandes (formas simples de 6 pontas, 30 a 50 px) caindo embaixo dela, vista de cima em 3/4. **~1000 x 1000 px** no total (a nuvem em cima, os flocos embaixo), centralizada.

**Saída:** `art/sprites/tiny/candidatos/l35_05b.png`, `l35_06b.png`, `l35_07b.png`, `l35_08b.png`, `l35_09b.png`.

**Conversão:** `pixelizar.gd` na altura do jogo (poça 96, parede 88, nuvem 150, tornado 132, totem 136, golem 134, nevasca 150 pixels da arte).
