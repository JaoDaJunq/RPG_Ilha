# L16 · Efeitos, armadilha, ícones e tecla E no estilo Tiny Swords

**Por quê (30/10):** o João aprovou a base de arte (acampamento do L14 e personagens pixelizados) e pediu para pôr TUDO no jogo nesse estilo.

**Ainda no estilo antigo:**
- bola de fogo, lança de gelo, gelo na água, cristais de gelo e golpe giratório (Ninja Adventure);
- a armadilha (L04);
- os ícones de habilidade, atributo e item;
- a tecla E.

**O que vem do pacote:** explosão, poeira, fogo e brilho de subir de nível.

**Pixel art direto em 4x e 8x funciona para peças SIMPLES** (o acampamento do L14 deu certo). Por isso aqui o pedido é pixel art, com a régua.

**Anexar, nesta ordem (em todos):**
1. `art/prompts/reguas/objetos_4x.png`: **A RÉGUA** do pacote em 4x (tamanho do pixel, contorno, cores).
2. `evidence/comparacao/l14_v2_perto.png`: o que já foi aprovado (em cima o pacote; embaixo o nosso L14, aprovado).
3. `art/terceiros/tiny_swords/Tiny Swords (Free Pack)/UI Elements/UI Elements/Icons/Icon_02.png` e `Icon_05.png`: **ícones do pacote** (para as folhas de ícones).

**Regras comuns (copiar no começo de cada pedido):**

```text
FAÇA:
- Pixel art no MESMO estilo da régua anexada (Tiny Swords): contorno de 1 pixel na cor #161c2e em volta de tudo, sombreamento em 2 ou 3 tons por material, luz de cima à esquerda, formas redondinhas e simples, cores apagadas do pacote: #161c2e #485884 #4c5c8b #4697ac #9cbeaa #688c8a #c8a876 #efe1ab #977b6b #5e5455 #924159 #8d4848 #e76161 #cf9c71 #cea554 #e9f044 #44a079 #699157 #ffffff.
- Todos os quadrados do mesmo tamanho (o tamanho pedido abaixo), alinhados numa grade que começa no canto (0,0).
- Cada peça centralizada na sua célula, com folga em volta.
- Fundo magenta chapado #FF00FF.

NÃO FAÇA:
- NÃO use quadrados de tamanhos diferentes, degradê dentro do quadrado, borrado nem anti-aliasing.
- NÃO use contorno preto puro nem contorno com 2 ou mais pixels.
- NÃO use cores saturadas ou neon fora da lista.
- NÃO use rosa nem magenta no desenho (o fundo é magenta).
- NÃO desenhe sombra no chão, chão, cenário, texto, letras (exceto a letra E da tecla), números, moldura ou linhas de grade.
- NÃO encoste na borda da célula; nada atravessa para a célula vizinha.

NÃO SIGA:
- NÃO siga "pixel art de RPG genérico" nem ícones realistas: siga só a régua do Tiny Swords.
```

## 1. Efeitos e gelo (4x: cada pixel = quadrado de 4x4; célula de 512 = 128 pixels)

**Saída:** `art/sprites/tiny/candidatos/efeitos_v1.png` (1536x1024, 3x2 células de 512)

```text
(regras comuns) +
1) Bola de fogo voando para a DIREITA: bola amarela e laranja com 3 lambidas de fogo para trás (esquerda). 28 x 18 pixels.
2) Lança de gelo voando para a DIREITA: cristal azul-claro pontudo, comprido e fino-mas-legível. 32 x 10 pixels.
3) Bloco de GELO para o chão, 64 x 64 pixels, preenchendo o quadrado inteiro (sem magenta dentro dele): gelo azul-claro (#9cbeaa, #4697ac, brilhos #ffffff) com 2 rachaduras finas, que se repete lado a lado sem emenda. Sem contorno em volta do bloco.
4) Cristais de gelo saindo do chão (prende o inimigo): 3 cristais azuis pontudos juntos. 40 x 36 pixels.
5) Golpe giratório: um arco branco e azul-claro em volta (anel quebrado em 3 pedaços curvos), visto de cima. 72 x 40 pixels.
6) Estrela de acerto: estrelinha branca e amarela de 4 pontas. 20 x 20 pixels.
```

## 2. Armadilha de urso (4x: célula de 512 = 128 pixels)

**Saída:** `art/sprites/tiny/candidatos/armadilha_v1.png` (1536x1024, 3x2 células de 512; as células 5 e 6 ficam vazias)

```text
(regras comuns) +
Armadilha de urso de metal vista de cima em 3/4, com placa redonda no meio e corrente curta presa num pino, 44 x 32 pixels, MESMA armadilha nos 4 quadros:
1) ARMADA: as duas mandíbulas abertas e deitadas, dentes triangulares virados para cima.
2) FECHANDO: mandíbulas no meio do caminho, levantadas.
3) FECHADA: mandíbulas fechadas em pé, dentes cruzados.
4) GASTA: fechada, torta e com manchinhas de ferrugem (#977b6b), um dente quebrado.
5) e 6) vazias (só o fundo magenta).
```

## 3. Ícones de habilidade (8x: cada pixel = quadrado de 8x8; célula de 512 = 64 pixels)

**Saída:** `art/sprites/tiny/candidatos/icones_habilidades_v1.png` (1536x1024, 3x2 células de 512)

```text
(regras comuns) +
Ícones de habilidade no estilo dos ícones do pacote anexados (Icon_02, Icon_05): objeto grande ocupando ~48 x 48 dos 64 pixels, contorno #161c2e, sem fundo (o fundo é o magenta).
1) Bola de fogo (bola de fogo com lambidas).
2) Lança de gelo (cristal azul pontudo na diagonal).
3) Investida (escudo redondo com 2 riscos de movimento atrás).
4) Giro (espada curta com uma seta curva em volta).
5) Tiro carregado (arco com flecha brilhando amarela na corda).
6) Armadilha (a armadilha de urso aberta, vista de cima).
```

## 4. Ícones de atributo e itens (8x)

**Saída:** `art/sprites/tiny/candidatos/icones_atributos_v1.png` (1536x1024, 3x2 células de 512)

```text
(regras comuns) +
Mesmo estilo e tamanho dos ícones de habilidade.
1) Força: braço dobrado mostrando o músculo, pele #cf9c71.
2) Vitalidade: coração vermelho (#e76161, #8d4848).
3) Agilidade: bota marrom com 2 riscos de vento.
4) Intelecto: livro azul aberto.
5) Espírito: gota azul (#4697ac) com brilho branco.
6) Experiência: estrela amarela (#e9f044, #cea554).
```

## 5. Itens, esquiva e tecla E (8x)

**Saída:** `art/sprites/tiny/candidatos/icones_itens_v1.png` (1536x1024, 3x2 células de 512)

```text
(regras comuns) +
Mesmo estilo e tamanho dos ícones de habilidade.
1) Pedra: pedra cinza-azulada (#688c8a, #9cbeaa) com musgo.
2) Carvão: 2 pedaços de carvão preto-azulado com brilho cinza.
3) Esquiva: bota com rastro curvo de vento atrás.
4) Tecla E: tecla de teclado clara (#efe1ab) quadrada e arredondada, com a letra E grande escura no meio, vista um pouco de cima.
5) e 6) vazias (só o fundo magenta).
```

## Depois de gerar

Salvar só nos cinco caminhos acima. Não mexer em `game/` nem em nenhum outro arquivo. Responder com os caminhos e o tamanho em pixels de cada imagem.
