# L39 · Bichos, inimigos e itens novos (etapa 2 do mundo maior)

**Por quê (13/11/2026):** o João jogou o mundo maior e não viu nada novo: só slime, javali, coelho, ovelha, galinha e o arqueiro. A etapa 2 (`design/proposta_mundo.md`, seção 4) põe vida em cada região: animais, inimigos, minérios, a fornalha, ferramentas de cobre e ferro, poções e comidas. Os bandidos guerreiro e lanceiro vêm prontos do pacote Tiny Swords (Black Units), sem pedido.

**Três métodos neste lote:**
- **Criaturas (folhas 01 a 08):** ILUSTRAÇÃO lisa, como os personagens (L30/L31). O Claude converte com `game/tools/pixelizar.gd --animacao` (paleta e contorno do pacote). Cada folha é uma animação: 6 quadros do MESMO bicho.
- **Objetos (folhas 09 a 11):** pixel art 4x, como as pedras e o slime do L14. O Claude converte com `importar_folha.gd --pixel=4 --paleta_de --sombra`.
- **Ícones (folhas 12 a 18):** pixel art 8x, como os ícones do L17/L22. O Claude converte com `importar_folha.gd --pixel=8 --separar`.

Salvar SÓ no caminho de saída de cada folha. Não mexer em `game/` nem em nenhum outro arquivo. Responder com o caminho e o tamanho em pixels de cada imagem.

---

## Criaturas: folhas 01 a 08 (ilustração)

**Anexar, nesta ordem (em todas as folhas de criatura):**
1. `art/sprites/tiny/candidatos/l30_humano_guerreiro_perfil.png`: **o traço, a grossura do contorno e o acabamento** dos nossos personagens (ilustração lisa que o jogo pixeliza).
2. `art/sprites/tiny/referencias/estilo_ilustracao.png`: o acabamento (cor chapada, contorno grosso).
3. `art/prompts/reguas/personagens_4x.png` e `art/prompts/reguas/objetos_4x.png`: as unidades e a ovelha do Tiny Swords, para as **cores apagadas** e o jeito **redondinho e fofo**.

**Regras (copiar no começo de cada folha de criatura):**

```text
TAREFA: uma folha de ANIMAÇÃO de UMA criatura, em ILUSTRAÇÃO 2D limpa (NÃO pixel art), no MESMO traço, contorno e acabamento do personagem da imagem 1 e da imagem 2, com as cores apagadas e o jeito redondinho das unidades e da ovelha do Tiny Swords (imagem 3).
Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512, UM quadro por célula, lidos da esquerda para a direita e de cima para baixo. Fundo magenta chapado #FF00FF.

FAÇA:
- A MESMA criatura em todos os 6 quadros: mesmo tamanho, mesmas cores, mesmas proporções; só a pose muda.
- De PERFIL, olhando para a DIREITA (vista de lado, um pouco de cima, como as unidades do Tiny Swords).
- Os pés (ou a base) na MESMA linha em todos os quadros, cerca de 90 px acima do fundo da célula, e a criatura centralizada na horizontal.
- O tamanho pedido em cada folha, igual em todos os quadros.
- Contorno #161c2e grosso (cerca de 5 px) e uniforme em volta de tudo e entre as partes, IGUAL ao do personagem da imagem 1.
- Cores chapadas com UM tom de sombra (cel shading), luz de cima à esquerda, cores apagadas do Tiny Swords.
- Formas grandes, redondinhas e simples, rosto legível de longe (olhos grandes e simples). Nada mais fino que 12 px (some ao reduzir).

NÃO FAÇA:
- NÃO use pixel art, quadradinhos, degradê suave, borrado, texto, números nem grade.
- NÃO desenhe chão, grama, sombra no chão, fundo, moldura, riscos de movimento, poeira nem brilho em volta.
- NÃO use contorno preto puro, cores saturadas, rosa ou magenta no desenho.
- NÃO deixe nada encostar na borda da célula.

NÃO SIGA:
- NÃO siga "monstro de RPG genérico" detalhado, realista ou assustador demais: é um bicho fofo e redondinho do Tiny Swords.
- NÃO siga os ícones antigos do jogo (pixel art grossa).
```

### Folha 01 · CERVO (Bosque Florido, foge rápido)
**Saída:** `art/sprites/tiny/candidatos/l39_01_cervo.png`

```text
(regras) +
O CERVO: corpo marrom-alaranjado apagado (#b07a55, sombra #8d5a45), barriga e rabinho creme (#efe1ab), pintinhas creme nas costas, pernas finas mas legíveis (no mínimo 16 px), cascos escuros, focinho escuro, olho grande e doce, chifres pequenos de 2 pontas, marrom-claros. Do focinho ao rabo ~330 px; dos cascos à ponta dos chifres ~380 px.
1) PARADO: em pé, cabeça normal.
2) PASSO A: perna da frente esquerda e de trás direita para a frente.
3) PASSO B: as outras duas pernas para a frente.
4) ALERTA: cabeça bem erguida, orelhas em pé, olhando para a direita.
5) CORRENDO: no meio de um salto, pernas da frente esticadas para a frente e as de trás para trás, corpo esticado.
6) MACHUCADO: encolhido, olhos fechados apertados, cabeça para trás.
```

### Folha 02 · CARANGUEJO (Praia das Conchas, belisca se provocado)
**Saída:** `art/sprites/tiny/candidatos/l39_02_caranguejo.png`

```text
(regras) +
O CARANGUEJO: visto de lado e um pouco de cima (anda de lado), casca larga e redonda vermelho-alaranjada apagada (#c25a4a, sombra #8d4848), barriga creme, 2 olhos em hastes curtas em cima, 2 pinças grandes (uma um pouco maior), 6 perninhas curtas e grossas. ~330 px de largura, ~230 px de altura.
1) PARADO: pinças abaixadas, olhinhos para a frente.
2) PASSO A: perninhas de um lado levantadas, corpo inclinado de leve.
3) PASSO B: as perninhas do outro lado levantadas.
4) PREPARO: as duas pinças erguidas e ABERTAS, bravo (sobrancelhas tortas).
5) BELISCÃO: a pinça grande esticada para a frente (direita) e FECHADA.
6) MACHUCADO: encolhido dentro da casca, olhinhos fechados.
```

### Folha 03 · SAPO (Pântano dos Cogumelos, anda pulando)
**Saída:** `art/sprites/tiny/candidatos/l39_03_sapo.png`

```text
(regras) +
O SAPO: gordinho, verde-musgo apagado (#699157, sombra #4f7a45), barriga creme-esverdeada (#c8d6a0), pintinhas verde-escuras nas costas, olhos grandes e redondos em cima da cabeça, boca larga sorrindo, patas de trás grandes dobradas. Sentado: ~260 px de largura, ~200 px de altura.
1) PARADO: sentado, patas dobradas.
2) AGACHADO: preparando o pulo, o corpo mais baixo e achatado.
3) NO AR: pulando para a direita, patas de trás esticadas para trás, patas da frente para a frente (a base no ar, ~60 px acima da linha dos pés).
4) COAXANDO: sentado, o papo inflado como uma bola creme embaixo da boca.
5) ATERRISSANDO: patas da frente no chão, as de trás ainda abertas.
6) MACHUCADO: achatado, olhos fechados em X simples.
```

### Folha 04 · CABRA (Colinas de Pedra)
**Saída:** `art/sprites/tiny/candidatos/l39_04_cabra.png`

```text
(regras) +
A CABRA: pelo branco-acinzentado (#e3dccb, sombra #b4ab9a), barbicha, chifres curvados para trás cinza-escuros, focinho e cascos escuros, orelhas para os lados, rabinho curto em pé, olho com pupila de cabra (traço) simpático. Do focinho ao rabo ~320 px; dos cascos ao topo dos chifres ~330 px.
1) PARADO: em pé, cabeça normal.
2) PASSO A.
3) PASSO B.
4) PREPARO: cabeça abaixada com os chifres para a frente, patas da frente firmes (vai dar uma cabeçada).
5) CABEÇADA: corpo esticado para a frente, chifres bem na frente.
6) MACHUCADO: encolhida, olhos fechados, orelhas caídas.
```

### Folha 05 · COGUMELO ANDANTE (Pântano, solta esporos que deixam Lento)
**Saída:** `art/sprites/tiny/candidatos/l39_05_cogumelo.png`

```text
(regras) +
O COGUMELO ANDANTE: um cogumelo com perninhas: chapéu grande e redondo roxo-azulado apagado (#6b5e9e, sombra #4d4378) com pintas claras (#c8c0e8), pé grosso creme (#efe1ab) com uma carinha zangada (olhos pequenos e brilhantes, boca torta), dois pezinhos curtos e dois bracinhos tocos. ~260 px de largura, ~330 px de altura.
1) PARADO.
2) PASSO A: um pezinho à frente, chapéu balançando para um lado.
3) PASSO B: o outro pezinho, chapéu para o outro lado.
4) PREPARO: agachado, o chapéu inflado e maior, bochechas cheias.
5) ESPOROS: o chapéu sacudindo, com 6 a 8 bolinhas grandes (24 px) de esporo lilás-claro (#c8c0e8 com contorno) saindo de cima do chapéu.
6) MACHUCADO: chapéu amassado para o lado, olhos fechados.
```

### Folha 06 · MORCEGO (noite e cavernas, rápido e frágil)
**Saída:** `art/sprites/tiny/candidatos/l39_06_morcego.png`

```text
(regras) +
O MORCEGO: voando, corpinho redondo peludo roxo-acinzentado escuro (#5e5470, sombra #3e3850), orelhas grandes pontudas, olhos grandes amarelos-claros (#efe1ab), dois dentinhos brancos, asas de couro grandes (#4a4260 com as varetas mais escuras). Asas abertas: ~380 px de ponta a ponta. A base (a ponta dos pezinhos) na mesma linha nos quadros 1 a 3.
1) VOO A: asas para CIMA.
2) VOO B: asas abertas na horizontal.
3) VOO C: asas para BAIXO.
4) MERGULHO: asas fechadas para trás, corpo inclinado para a frente-baixo (preparo do ataque).
5) MORDIDA: boca aberta mostrando os dentinhos, asas abertas para a frente.
6) MACHUCADO: asas encolhidas, olhos fechados em X simples.
```

### Folha 07 · ESQUELETO DE MUSGO (Ruínas, renasce se não for queimado)
**Saída:** `art/sprites/tiny/candidatos/l39_07_esqueleto.png`

```text
(regras) +
O ESQUELETO DE MUSGO: um esqueleto baixinho e fofo do tamanho de uma unidade do Tiny Swords (cabeça grande e redonda, corpo pequeno), ossos creme-acinzentados (#e3dccb, sombra #b4ab9a), MUSGO verde (#699157, sombra #4f7a45) cobrindo a cabeça como um chapéu e pendurado nos ombros e costelas, olhos com brilho verde-água (#74c7d4) dentro das órbitas, segura uma espada velha curta enferrujada (lâmina #8aa6a3 com manchas marrons) na mão da frente. Em pé ~360 px de altura.
1) PARADO.
2) PASSO A.
3) PASSO B.
4) PREPARO: a espada erguida acima da cabeça.
5) GOLPE: a espada descendo na frente, inclinado para a frente.
6) DESMONTADO: um MONTINHO de ossos no chão (a caveira com musgo em cima, costelas e ossos espalhados, a espada caída do lado), ~300 px de largura e ~150 px de altura, na mesma linha dos pés.
```

### Folha 08 · GOLENZINHO DE PEDRA (Colinas, lento e forte)
**Saída:** `art/sprites/tiny/candidatos/l39_08_golem.png`

```text
(regras) +
O GOLENZINHO DE PEDRA: atarracado e fofo, corpo de blocos de pedra arredondados cinza-azulados (#8aa6a3, sombra #5f7d86) com um pouco de musgo verde em cima, braços grossos e compridos de pedra (punhos grandes), pernas curtas, olhos que brilham em amarelo-claro (#efe1ab) numa fenda do rosto, uma pedrinha laranja de cobre (#c27a4a) encravada no peito. ~330 px de largura, ~380 px de altura.
1) PARADO.
2) PASSO A: pesado, um pé à frente, inclinado.
3) PASSO B: o outro pé.
4) PREPARO: os dois punhos erguidos acima da cabeça.
5) SOCO NO CHÃO: os dois punhos batendo no chão à frente, corpo abaixado.
6) RACHADO: em pé, com rachaduras escuras pelo corpo, olhos piscando (meio fechados), um pedacinho de pedra caindo.
```

---

## Objetos: folhas 09 a 11 (pixel art 4x)

**Anexar, nesta ordem:**
1. `art/sprites/tiny/pedras_slime_v2.png`: **as nossas pedras e o slime aprovados (L14)**. Copiar EXATAMENTE o pixel, o contorno, os tons e o tamanho.
2. `art/prompts/reguas/objetos_4x.png`: a régua do Tiny Swords em 4x.
3. `art/sprites/tiny/acampamento_v2.png`: os nossos objetos do acampamento (só na folha 11).

**Regras (copiar no começo de cada folha de objeto):**

```text
FAÇA:
- Pixel art no MESMO estilo EXATO das pedras e do slime da imagem 1 e da régua (Tiny Swords): quadrados de 4x4 na imagem (cada 4 px da imagem = 1 pixel de jogo), contorno de 1 pixel #161c2e, 2 ou 3 tons por material, luz de cima à esquerda, vistos de cima em 3/4, cores apagadas do Tiny Swords.
- Imagem 1536x1024, grade de 3 colunas x 2 linhas (células de 512x512), UMA peça por célula, centralizada, base 32 px acima do fundo da célula. Fundo magenta chapado #FF00FF.
- Medidas em PIXELS DE JOGO (na imagem, multiplique por 4).
- Formas redondinhas e simples, legíveis de longe.

NÃO FAÇA:
- NÃO use quadrados de tamanhos diferentes, degradê, borrado ou anti-aliasing.
- NÃO use contorno preto puro nem cores saturadas demais.
- NÃO desenhe chão, grama, sombra no chão, texto ou moldura.
- NÃO encoste na borda da célula.

NÃO SIGA:
- NÃO siga "pixel art de RPG genérico" nem desenho detalhado fino: siga a imagem 1 e a régua.
```

### Folha 09 · slimes dos elementos
**Saída:** `art/sprites/tiny/candidatos/l39_09_slimes.png`

```text
(regras) +
Os 3 slimes são o MESMO slime verde da imagem 1 (o 5º e o 6º desenhos), com a MESMA forma, o MESMO tamanho (~44 x 36 parado, ~62 x 28 achatado) e os MESMOS olhinhos, trocando só as cores e um detalhe:
1) SLIME DE FOGO parado: laranja-avermelhado (#e0703a, sombra #b04a3a, brilho #ffdc00), com 3 linguinhas de fogo amarelas e laranjas saindo do topo.
2) O MESMO SLIME DE FOGO achatado (como o 6º desenho da imagem 1), as linguinhas de fogo baixas.
3) SLIME DE GELO parado: azul-claro gelado (#9cd4e0, sombra #4697ac, brilho #ffffff), com 2 pontas de cristal de gelo em cima e um floco branco no corpo.
4) O MESMO SLIME DE GELO achatado.
5) SLIME VENENOSO parado: roxo-esverdeado (#8a5a9e, sombra #5e3e78) com bolhas verde-limão apagadas (#a8c060) no corpo e uma gota pingando do lado.
6) O MESMO SLIME VENENOSO achatado.
```

### Folha 10 · pedras com minério (Colinas e Ruínas)
**Saída:** `art/sprites/tiny/candidatos/l39_10_minerios.png`

```text
(regras) +
As MESMAS pedras cinza-azuladas da imagem 1 (a pedra grande, o 1º desenho, ~78 x 60), agora com minério. O par de cada minério: a pedra inteira e a MESMA pedra rachada (como o 2º desenho da imagem 1: partida em 2 blocos e pedrinhas soltas).
1) PEDRA COM COBRE inteira: 4 ou 5 veios e pepitas cor de cobre (#c27a4a, brilho #e8a070, sombra #8d4f35) aparecendo na pedra, sem musgo.
2) A MESMA PEDRA COM COBRE rachada.
3) PEDRA COM FERRO inteira: pedra um pouco mais escura (#6f8790), com 4 ou 5 pepitas cor de ferrugem e cinza-prateado (#b0a39a, #8d5a45).
4) A MESMA PEDRA COM FERRO rachada.
5) PEDRA COM CRISTAL inteira: pedra cinza-azulada de onde saem 3 cristais pontudos verde-água claros (#74c7d4, brilho #ffffff, sombra #4697ac), o maior com ~18 de altura acima da pedra; musgo nas Ruínas.
6) A MESMA PEDRA COM CRISTAL rachada, um cristal quebrado.
```

### Folha 11 · fornalha, plantas e pesca
**Saída:** `art/sprites/tiny/candidatos/l39_11_fornalha_plantas.png`

```text
(regras) + anexar também a imagem 3 (acampamento: a fogueira e a bancada aprovadas).
1) FORNALHA APAGADA: forno pequeno e redondo de pedras cinza-azuladas empilhadas, em forma de cúpula baixa, com uma boca em arco escura na frente e uma chaminé curta em cima. ~36 x 40.
2) A MESMA FORNALHA ACESA: a boca com fogo laranja e amarelo (#f6703e, #ffdc00) e um brilho laranja nas pedras em volta da boca, um fiozinho de fumaça cinza na chaminé.
3) ARBUSTO SEM FRUTINHAS: arbusto redondo verde como o da régua (~44 x 36), só folhas (as frutinhas foram colhidas).
4) TUFO DE ERVAS: tufo baixo de folhas verde-claras recortadas com 3 florzinhas brancas pequenas. ~18 x 14.
5) CAPIM DE FIBRA: tufo alto de capim fino amarelo-esverdeado (#c8b860, sombra #8c8a4f), algumas pontas curvadas. ~20 x 24.
6) PONTO DE PESCA: 3 anéis de onda claros (#d6eef0) um dentro do outro e a sombrinha escura de um peixe (#3e5a6a) no meio, como visto de cima na água (sem desenhar a água). ~30 x 16.
```

---

## Ícones: folhas 12 a 18 (pixel art 8x)

**Anexar, nesta ordem:**
1. `art/sprites/tiny/efeitos_icones/icones_animais_v1.png`: **os nossos ícones de item aprovados** (carne, pena, couro, ovo). Copiar exatamente o estilo, o tamanho do pixel, o contorno e o tamanho do objeto na célula.
2. `art/sprites/tiny/efeitos_icones/icones_crafting_2_v1.png`: as ferramentas de pedra aprovadas (machado, picareta, espada).
3. `art/sprites/tiny/efeitos_icones/icones_armas_v1.png`: o cajado, o arco e a espada de ferro aprovados (só nas folhas 15 e 16).
4. `art/sprites/tiny/efeitos_icones/l25_icones_ladino.png` e `l25_icones_clerigo.png`: as adagas e a maça (só nas folhas 15 e 16).

**Regras (copiar no começo de cada folha de ícones):**

```text
FAÇA:
- Ícones de item no MESMO estilo EXATO dos ícones anexados (imagens 1 e 2): pixel art com quadrados de 8x8 na imagem (64 pixels de jogo por célula), objeto grande ocupando cerca de 40 x 40 dos 64 pixels, contorno de 1 pixel na cor #161c2e, sombreamento em 2 ou 3 tons, luz de cima à esquerda, cores apagadas do Tiny Swords: #161c2e #485884 #4697ac #9cbeaa #688c8a #c8a876 #efe1ab #977b6b #8d6857 #5e5455 #924159 #8d4848 #e76161 #cf9c71 #cea554 #e9f044 #44a079 #699157 #ffffff.
- COBRE é sempre laranja-acobreado (#c27a4a, brilho #e8a070, sombra #8d4f35). FERRO é sempre cinza-azulado escuro e liso (#8aa6a3, brilho #c5d6d2, sombra #5f7d86).
- Imagem 1536x1024, grade de 3 colunas x 2 linhas (células de 512x512), um ícone por célula, centralizado, com folga em volta.
- Fundo magenta chapado #FF00FF.

NÃO FAÇA:
- NÃO use quadrados de tamanhos diferentes, degradê dentro do quadrado, borrado nem anti-aliasing.
- NÃO use contorno preto puro nem contorno com 2 ou mais pixels.
- NÃO use cores saturadas ou neon, nem rosa ou magenta no desenho.
- NÃO desenhe fundo, moldura, quadrado atrás do ícone, sombra no chão, texto ou número.
- NÃO deixe o objeto pequeno no meio da célula nem encostando na borda.

NÃO SIGA:
- NÃO siga "ícone de RPG genérico" nem ícone realista: siga só os ícones anexados.
```

### Folha 12 · comidas
**Saída:** `art/sprites/tiny/candidatos/l39_12_icones_comida.png`
```text
(regras) +
1) FRUTINHAS: um cachinho de 5 frutinhas vermelhas redondas com 2 folhinhas verdes.
2) COCO: um coco marrom peludo, partido ao meio do lado mostrando a polpa branca.
3) PEIXE CRU: um peixe azul-acinzentado com barriga clara, deitado na diagonal.
4) PEIXE ASSADO: o mesmo peixe marrom-dourado, com marcas de grelha e um fiozinho de vapor.
5) COGUMELO: um cogumelo de chapéu vermelho apagado com pintas brancas.
6) SOPA DE COGUMELO: uma tigela de madeira com sopa bege e pedacinhos de cogumelo, vapor em cima.
```

### Folha 13 · natureza
**Saída:** `art/sprites/tiny/candidatos/l39_13_icones_natureza.png`
```text
(regras) +
1) CONCHA: uma concha leque bege-rosada apagada com listras.
2) ERVA: um raminho de folhas verde-claras recortadas com 2 florzinhas brancas.
3) FIBRA: um feixe de capim seco amarelo-esverdeado amarrado no meio.
4) CORDA: um rolo de corda bege enrolada em círculo, com a ponta solta.
5) CARNE DE SAPO: uma coxinha verde-clara de sapo (perna dobrada).
6) PINÇA DE CARANGUEJO: uma pinça grande vermelho-alaranjada apagada.
```

### Folha 14 · minérios e fornalha
**Saída:** `art/sprites/tiny/candidatos/l39_14_icones_minerios.png`
```text
(regras) +
1) MINÉRIO DE COBRE: uma pedra cinza com pepitas cor de cobre.
2) MINÉRIO DE FERRO: uma pedra escura com pepitas cor de ferrugem e prata.
3) CRISTAL: um cristal pontudo verde-água claro (#74c7d4) com brilho branco.
4) BARRA DE COBRE: um lingote de cobre (trapézio deitado visto de cima em 3/4).
5) BARRA DE FERRO: o mesmo lingote em ferro.
6) FORNALHA: um forninho redondo de pedra com a boca acesa em laranja.
```

### Folha 15 · ferramentas e mais
**Saída:** `art/sprites/tiny/candidatos/l39_15_icones_ferramentas.png`
```text
(regras) +
1) MACHADO DE COBRE: o MESMO machado de pedra da imagem 2, com a lâmina de cobre.
2) MACHADO DE FERRO: o mesmo machado com a lâmina de ferro.
3) PICARETA DE COBRE: a MESMA picareta de pedra da imagem 2, com a cabeça de cobre.
4) PICARETA DE FERRO: a mesma picareta com a cabeça de ferro.
5) VARA DE PESCAR: vara de madeira fina na diagonal com a linha clara caindo e uma boia vermelha e branca.
6) LÃ: um novelo de lã branca-acinzentada redondo, com um fio solto.
```

### Folha 16 · armas de cobre (o cobre é laranja-acobreado)
**Saída:** `art/sprites/tiny/candidatos/l39_16_icones_armas_cobre.png`
```text
(regras) + anexar também as imagens 3 e 4.
Cada arma é a MESMA arma aprovada das imagens 3 e 4, no mesmo tamanho e na mesma diagonal, trocando o metal (ou o detalhe) por COBRE.
1) ESPADA DE COBRE: a espada de ferro da imagem 3 com a lâmina de cobre.
2) CAJADO DE COBRE: o cajado da imagem 3 com anéis de cobre e um cristal laranja.
3) ARCO DE COBRE: o arco da imagem 3 com as pontas e a empunhadura de cobre.
4) ADAGAS DE COBRE: as adagas da imagem 4 com as lâminas de cobre.
5) MAÇA DE COBRE: a maça da imagem 4 com a cabeça de cobre.
6) LEITE: uma garrafinha de barro com leite branco e uma rolha.
```

### Folha 17 · armas de ferro (o ferro é cinza-azulado escuro)
**Saída:** `art/sprites/tiny/candidatos/l39_17_icones_armas_ferro.png`
```text
(regras) + anexar também as imagens 3 e 4.
Cada arma é a MESMA arma aprovada das imagens 3 e 4, no mesmo tamanho e na mesma diagonal, agora REFORÇADA em FERRO escuro (um pouco maior, com uma guarda ou faixa a mais).
1) ESPADA DE FERRO REFORÇADA: a espada da imagem 3 com a lâmina mais larga de ferro escuro e a guarda maior.
2) CAJADO DE FERRO: o cajado da imagem 3 com anéis de ferro e um cristal azul-turquesa.
3) ARCO DE FERRO: o arco da imagem 3 com as pontas e a empunhadura de ferro escuro.
4) ADAGAS DE FERRO: as adagas da imagem 4 com as lâminas de ferro escuro.
5) MAÇA DE FERRO: a maça da imagem 4 com a cabeça de ferro escuro e cravos.
6) OSSO: um osso creme de desenho animado com duas bolotas em cada ponta, com um pouco de musgo verde.
```

### Folha 18 · poções e comidas cozidas
**Saída:** `art/sprites/tiny/candidatos/l39_18_icones_pocoes.png`
```text
(regras) +
1) POÇÃO DE CURA: frasco redondo de vidro claro com líquido vermelho (#e76161), rolha de madeira, um brilho branco no vidro.
2) POÇÃO DE MANA: o mesmo frasco com líquido azul (#4697ac).
3) POÇÃO DE RESISTÊNCIA: o mesmo frasco com líquido âmbar-dourado (#cea554) e um pequeno escudo desenhado no rótulo.
4) CARNE DE SAPO ASSADA: a coxinha de sapo marrom-dourada num palitinho.
5) ESPETINHO DE COGUMELO: um palito com 3 cogumelos assados marrons.
6) FRUTINHAS ASSADAS NO COCO: meio coco com frutinhas vermelhas cozidas dentro, vapor em cima.
```
