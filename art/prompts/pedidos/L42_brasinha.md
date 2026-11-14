# L42 · Brasinha, pedras de lore e itens da história (etapa 3)

**Por quê (13/11/2026):** a etapa 3 (`design/proposta_brasinha.md`) traz o **Brasinha**, um espírito de fogo engraçadinho que mora na fogueira do acampamento, conversa com o grupo e dá as missões. Também traz as pedras de lore, o altar do pântano e os itens da história.

**Métodos:**
- **Folhas 01 a 03 e 06:** ILUSTRAÇÃO lisa, como os personagens (L30/L31). O Claude converte com `pixelizar.gd`.
- **Folha 04:** pixel art 4x (objetos).
- **Folha 05:** pixel art 8x (ícones).

Salvar SÓ no caminho de saída de cada folha, em `art/sprites/tiny/candidatos/`. Não mexer em `game/` nem em nenhum outro arquivo. Responder com o caminho e o tamanho em pixels de cada imagem.

---

## O BRASINHA (vale para as folhas 01, 02 e 03)

```text
O BRASINHA: um espírito de fogo PEQUENO e FOFO, personagem ORIGINAL deste jogo.
- Corpo: UMA chama gordinha em forma de gota de cabeça para baixo (base larga e redonda, topo em 2 ou 3 pontas de chama curtas, a do meio mais alta, como um "topete"). Por fora vermelho-alaranjado (#e8603c), meio laranja (#f6943e), miolo amarelo (#ffd23f) e um coração creme (#fff4c2) na barriga.
- Rosto no meio do corpo: DOIS olhos grandes e redondos, brancos (#fffaf0) com pupila escura (#161c2e) e um brilhinho; sobrancelhas de chama pequenas que mostram o humor; boca simples e expressiva (escura #5a1e1e por dentro).
- Bochechas: duas manchinhas vermelho-brasa (#cc3f3f).
- Bracinhos: duas línguas de chama pequenas saindo dos lados, que ele usa como mãozinhas para gesticular.
- Na base, um anelzinho de MUSGO verde apagado (#6a8a4a, sombra #4d6b3a) com 2 ou 3 folhinhas, como uma gola: ele é parte da ilha.
- Personalidade: dramático, convencido, guloso e engraçado. Caras exageradas e cartunescas.
- Contorno #161c2e grosso (~5 px) em volta do corpo inteiro (as pontas das chamas também), igual ao dos personagens da imagem 1.
- Cores chapadas com UM tom de sombra (cel shading), sem degradê, sem brilho borrado em volta.
```

**NÃO SIGA (copiar em todas as folhas do Brasinha):**

```text
NÃO SIGA:
- NÃO copie nenhum personagem de filme, anime ou jogo existente (em especial NÃO faça o demônio de fogo do "Castelo Animado"/Calcifer: nada de rosto com olhos de ovo frito, boca larga achatada, nem corpo de fogueira grande). O Brasinha é uma gotinha de chama redonda com gola de musgo, bochechas de brasa e bracinhos.
- NÃO siga fogo realista, fumaça, partículas ou brilho em volta.
- NÃO desenhe lenha, pedras, chão ou fogueira embaixo dele (a base da fogueira é outra peça).
```

**Anexar, nesta ordem (folhas 01, 02, 03):**
1. `art/sprites/tiny/candidatos/l30_humano_guerreiro_perfil.png`: o traço, o contorno e o acabamento.
2. `art/sprites/tiny/referencias/estilo_ilustracao.png`: cor chapada, contorno grosso.
3. `game/assets/sprites/tiny/fogueira.png`: a fogueira do jogo, para o tamanho (o Brasinha fica em cima da lenha, no lugar das chamas) e as cores do fogo.

### Folha 01 · Brasinha parado, em laço
**Saída:** `l42_01_brasinha_parado.png`

```text
TAREFA: folha de ANIMAÇÃO EM LAÇO de 6 quadros do BRASINHA (descrição acima), em ILUSTRAÇÃO 2D limpa (NÃO pixel art), no traço e contorno da imagem 1.
Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512, um quadro por célula, da esquerda para a direita e de cima para baixo. Fundo magenta chapado #FF00FF.
De FRENTE para quem olha, olhos para a frente, cara contente e convencida (sorrisinho de lado).
O MESMO Brasinha em todos os quadros: ~260 px de altura (até a ponta mais alta), ~220 px de largura, a BASE (a gola de musgo) SEMPRE na MESMA linha, 110 px acima do fundo da célula, centralizado na horizontal.
Só a chama se mexe: as pontas de cima balançam para um lado e para o outro e mudam um pouco de altura, o corpo "respira" (estica 4 a 8 px e volta), os bracinhos balançam. Pisca os olhos no quadro 4 (olhos fechados, dois risquinhos). O 6º quadro emenda no 1º.
FAÇA: contorno #161c2e grosso e uniforme, formas grandes e simples, nada mais fino que 12 px.
NÃO FAÇA: pixel art, degradê, brilho borrado, texto, chão, sombra, moldura; nada encostando na borda.
(+ NÃO SIGA)
```

### Folha 02 · Brasinha: humores
**Saída:** `l42_02_brasinha_humores.png`

```text
TAREFA: folha com 6 HUMORES do BRASINHA (descrição acima), ILUSTRAÇÃO 2D limpa (NÃO pixel art), no traço e contorno da imagem 1.
Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512. Fundo magenta chapado #FF00FF.
MESMO Brasinha, MESMO tamanho (~260 px de altura no normal), base na MESMA linha (110 px acima do fundo da célula), de frente, centralizado:
1) FALANDO A: boca aberta redonda no meio de uma palavra, um bracinho levantado gesticulando, sobrancelhas animadas.
2) FALANDO B: boca aberta larga num "Haha!", os dois bracinhos abertos, olhos meio fechados de convencido.
3) FRAQUINHO: o Brasinha MENOR (~150 px de altura), chama baixinha, cores mais apagadas e meio azuladas no topo (#7fa0c8 nas pontas), olhos sonolentos caídos, boca tristinha, bracinhos caídos. A base na MESMA linha.
4) COMENDO: segurando com os dois bracinhos uma tora de lenha marrom pequena (#955c3c, corte #cea554) e mordendo a ponta, olhos fechados de prazer, bochechas cheias.
5) ASSUSTADO: o corpo encolhido e tremido para baixo, olhos enormes, pupilas pequenas, boca em zigue-zague, bracinhos na frente da boca.
6) COMEMORANDO: o Brasinha MAIOR (~300 px de altura), chamas altas, os dois bracinhos para cima, olhos fechados em arquinho (^ ^), boca aberta sorrindo, 3 faiscazinhas amarelas em volta.
FAÇA / NÃO FAÇA: como na folha 01.
(+ NÃO SIGA)
```

### Folha 03 · Retrato do Brasinha (painel de conversa)
**Saída:** `l42_03_brasinha_retrato.png`

```text
TAREFA: 2 RETRATOS do BRASINHA (descrição acima) para a caixa de conversa, ILUSTRAÇÃO 2D limpa (NÃO pixel art), no traço e contorno da imagem 1.
Imagem 1024x512, 2 células de 512x512 lado a lado. Fundo magenta chapado #FF00FF.
Enquadramento de busto: o Brasinha grande, ocupando ~400 px de altura, centralizado, a gola de musgo encostando 30 px acima do fundo da célula.
1) NORMAL: sorrisinho convencido, um olho levemente mais fechado, bracinho na "cintura".
2) FALANDO: boca aberta animada, bracinho apontando para a frente (para quem lê).
FAÇA: contorno #161c2e grosso (~7 px neste tamanho), cores chapadas com UM tom de sombra.
NÃO FAÇA: pixel art, degradê, brilho borrado, texto, fundo, moldura; nada encostando na borda.
(+ NÃO SIGA)
```

---

## Folha 04 · Objetos da história (pixel art 4x)
**Saída:** `l42_04_objetos_historia.png`

**Anexar:**
1. `art/prompts/reguas/objetos_4x.png`: o tamanho do pixel, o contorno, as cores apagadas e a sombra do Tiny Swords.
2. `game/assets/sprites/tiny/fogueira.png`: a fogueira do jogo (as pedras e a lenha da peça 1 devem ser IGUAIS às dela, sem as chamas).

```text
TAREFA: folha de 6 OBJETOS em pixel art, no MESMO estilo da imagem 1 (Tiny Swords).
Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512, um objeto por célula, centralizado, a BASE 32 px acima do fundo da célula. Fundo magenta chapado #FF00FF.
Quadrados de 4x4 na imagem (cada 4 px = 1 pixel de jogo; cada célula = 128x128 pixels de jogo), sem anti-aliasing. Contorno #161c2e de 1 pixel de jogo. 2 ou 3 tons por material, luz de cima à esquerda, cores apagadas.
1) BASE DA FOGUEIRA DO BRASINHA: o MESMO anel de pedras e a MESMA lenha cruzada da fogueira da imagem 2, no MESMO tamanho, mas SEM chamas: só brasas laranja (#f6703e) e vermelhas (#cc5050) entre as toras.
2) PEDRA DE LORE APAGADA: uma laje de pedra antiga em pé (~44 x 56 pixels de jogo), cinza-esverdeada (#7d8f86, #5b6f69), musgo verde apagado no topo e nos cantos, com um desenho entalhado simples (uma espiral com 5 pontinhos em volta) em sulco escuro.
3) PEDRA DE LORE LIDA: a MESMA pedra, mas o entalhe brilhando em verde-água claro (#9fe0c8, miolo #e6fff4), sem brilho borrado em volta.
4) ALTAR DO PÂNTANO VAZIO: um altar baixo e redondo de pedra com musgo (~64 x 36 pixels de jogo), com uma cuba rasa no topo e 4 cogumelos pequenos em volta (chapéu #b85c7a, pintinhas creme).
5) ALTAR DO PÂNTANO COM A ISCA: o MESMO altar com uma bola de gosma verde-limão (#9ccf4a, sombra #6f9d36, brilho #e3f5a4) dentro da cuba, pingando pela borda.
6) PEDAÇO DE MURALHA DE RAÍZES QUEIMANDO: 3 raízes grossas marrons (#6e4a3c, #955c3c) torcidas, com as pontas em brasa laranja e chamas pequenas (#f6703e, #ffdc00), sem fumaça.
NÃO FAÇA: texto, chão, grama, fundo, moldura, sombra no chão (o jogo põe), anti-aliasing, degradê.
NÃO SIGA: realismo ou detalhe fino; tudo redondinho e simples como o Tiny Swords.
```

---

## Folha 05 · Ícones da história (pixel art 8x)
**Saída:** `l42_05_icones_historia.png`

**Anexar:**
1. `art/prompts/reguas/objetos_4x.png`: cores e contorno.
2. `game/assets/sprites/tiny/fogueira.png`: as cores do fogo.

```text
TAREFA: folha de 6 ÍCONES de inventário em pixel art.
Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512, um ícone por célula, centralizado, ocupando ~70% da célula. Fundo magenta chapado #FF00FF.
Quadrados de 8x8 na imagem (cada 8 px = 1 pixel de jogo; cada célula = 64x64 pixels de jogo), sem anti-aliasing. Contorno #161c2e de 1 pixel de jogo. 2 ou 3 tons por cor, luz de cima à esquerda.
1) SEMENTE DO CORAÇÃO: uma semente grande em forma de gota, verde-água (#5fbf9f, luz #9fe0c8, miolo #e6fff4) com um coraçãozinho brilhante dentro e um brotinho de 2 folhas no topo.
2) ISCA DE GOSMA: uma bola de gosma verde-limão (#9ccf4a, sombra #6f9d36) amarrada num graveto, com um cogumelo pequeno espetado e uma pinga caindo.
3) TOCHA DO BRASINHA: uma tocha de madeira com a chama LARANJA com dois olhinhos brancos e uma boquinha sorrindo (um pedacinho do Brasinha).
4) EXCLAMAÇÃO DE MISSÃO: um "!" grosso amarelo-ouro (#ffd23f, sombra #e8a33c) com contorno escuro.
5) INTERROGAÇÃO DE MISSÃO: um "?" grosso no MESMO estilo e cor do "!".
6) PEDRA DE LORE (ícone do diário): uma lajinha de pedra cinza-esverdeada com a espiral de 5 pontinhos brilhando verde-água.
NÃO FAÇA: texto além do "!" e do "?", fundo, moldura, anti-aliasing, degradê.
```

---

## Folha 06 · Imagens das pedras de lore (ilustração)
**Saída:** `l42_06_lore.png`

**Anexar:**
1. `art/sprites/tiny/referencias/estilo_ilustracao.png`: acabamento.
2. `art/prompts/reguas/personagens_4x.png`: as cores apagadas do Tiny Swords.

```text
TAREFA: 5 IMAGENS DE LORE no estilo de ENTALHE PINTADO NUMA LAJE DE PEDRA ANTIGA: figuras simples e chapadas (como pintura rupestre fofa), em ILUSTRAÇÃO 2D limpa (NÃO pixel art).
Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512; as imagens nas células 1 a 5, a célula 6 vazia (magenta). Fundo magenta chapado #FF00FF fora das lajes.
Cada célula: uma laje retangular de pedra cinza-esverdeada (#8a9a90, sombra #6b7b72), cantos gastos, musgo nas bordas, ocupando ~460x400 px; dentro dela, o desenho em 3 cores de "tinta" (verde-água #5fbf9f, ocre #c9883e, creme #efe1ab) e contorno #161c2e.
1) OS GUARDIÕES: 3 figurinhas redondas de capuz de musgo fazendo carinho numa ilha que tem rosto e sorri.
2) O CORAÇÃO PARTIDO: um coração verde-água no meio partindo em 5 sementes que voam para os lados.
3) A MÃE GOSMA: uma gosma enorme de coroa engolindo uma semente brilhante, com slimes pequenos em volta.
4) O GOLEM: uma figura grande de pedra dormindo numa colina, com uma semente brilhando no peito.
5) O GUARDIÃO ESQUECIDO: uma figura alta e encapuzada sozinha diante de ruínas, segurando a última semente.
FAÇA: figuras grandes, simples e legíveis; contorno grosso; traço fofo.
NÃO FAÇA: texto, letras, números, pixel art, degradê, nada encostando na borda da célula.
NÃO SIGA: hieróglifo egípcio ou desenho realista.
```

---

## Folha 02b · Humores refeitos no MESMO corpo da folha 01 (13/11/2026)
**Saída:** `l42_02b_brasinha_humores.png`

**Por quê:** na folha 02 o Brasinha ganhou corpinho e pés; na folha 01 (a que vai no jogo) ele é uma GOTINHA de chama sem pés, com a gola de folhas embaixo. Ao alternar entre as duas no jogo, ele muda de forma. Refazer os 6 humores no corpo da folha 01.

**Anexar:** 1) `art/sprites/tiny/candidatos/l42_01_brasinha_parado.png` (o corpo CERTO: copie exatamente a forma, a gola de folhas, o coração creme, as bochechas e os bracinhos de chama); 2) `art/sprites/tiny/candidatos/l42_02_brasinha_humores.png` (só as EXPRESSÕES e poses de cada humor).

```text
TAREFA: refazer a folha de 6 HUMORES do Brasinha usando EXATAMENTE o corpo da imagem 1 (gotinha de chama SEM pernas e SEM pés, gola de 3-5 folhas verdes embaixo, coração creme na barriga, bracinhos de chama nos lados), com as expressões e poses da imagem 2.
Mesmo formato da imagem 1: 1536x1024, grade 3x2, células 512x512, fundo magenta #FF00FF, de frente, centralizado, a BASE (as folhas da gola) SEMPRE na MESMA linha da imagem 1, e o MESMO tamanho da imagem 1 (exceto onde dito).
1) FALANDO A  2) FALANDO B (rindo, convencido)  3) FRAQUINHO (MENOR, ~60% do tamanho, pontas azuladas #7fa0c8, sonolento)  4) COMENDO (segurando uma tora pequena com os bracinhos)  5) ASSUSTADO (tremendo, olhos enormes)  6) COMEMORANDO (MAIOR, ~115%, bracinhos para cima, olhos ^ ^, 3 faíscas amarelas).
FAÇA: mesmo traço, contorno #161c2e e cores da imagem 1.
NÃO FAÇA: pernas, pés, corpo separado da chama, pixel art, degradê, texto, chão, sombra; nada encostando na borda.
NÃO SIGA: o corpo com pés da imagem 2; qualquer personagem existente de filme/jogo.
```
