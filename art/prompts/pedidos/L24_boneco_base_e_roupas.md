# L24 · Boneco base (roupinha branca), rostos e roupas de classe

**Por quê (01/11):** o João quer **criar o personagem** ao entrar no mundo:
1. escolher a raça e ver o bonequinho "pelado" (só uma roupinha branca);
2. trocar o rosto e a cor da pele;
3. escolher a classe: o boneco ganha a **roupa base** e o **chapéu ou elmo** da classe.

Na mochila, as roupas podem ser tiradas, e o boneco volta para a roupinha branca. Então cada roupa vira uma peça separada: o tronco com a roupa troca o tronco branco, e o chapéu ou elmo vai por cima da cabeça. O guerreiro humano do L19 copiava o do pacote (elmo com pluma azul): agora **toda a roupa é desenho nosso**.

**Piloto:** primeiro só o **Humano** (base, rostos e a roupa do Guerreiro). Se der certo, o resto segue o mesmo texto: Ogro, Mago e Arqueiro.

**Mesmo caminho do L19/L21:** ILUSTRAÇÃO lisa; o jogo transforma em pixel art (`montar_pecas.gd`). O personagem MONTADO de cada folha é a RÉGUA de tamanho: as peças soltas têm EXATAMENTE o tamanho que têm no montado.

## Regras de todas as folhas (copiar no começo)

```text
FAÇA:
- ILUSTRAÇÃO 2D limpa (NÃO pixel art), no MESMO acabamento das imagens anexadas: cores chapadas com UM tom de sombra suave (cel shading), cores apagadas do Tiny Swords, contorno #161c2e grosso (cerca de 5 px) e uniforme em volta de cada peça.
- Estilo de montagem do Forager: corpo SEM braços, duas mãozinhas redondas soltas, dois pezinhos curtos e redondos, cabeça grande e redonda, corpo curto.
- Imagem 1536x1024, grade de 3 colunas x 2 linhas (células de 512x512), UMA peça por célula, centralizada, com bastante folga. Fundo magenta chapado #FF00FF.
- Personagem montado com cerca de 360 px de altura.
- Peças inteiras e fechadas, cada uma com o contorno completo em volta.

NÃO FAÇA:
- NÃO desenhe arma, ferramenta, escudo, aljava, nem nada segurado.
- NÃO desenhe braços: só as mãozinhas soltas.
- NÃO mude o tamanho das peças entre o personagem montado e as peças soltas.
- NÃO desenhe pixel art, sombra no chão, chão, cenário, efeitos, texto, número ou moldura.
- NÃO encoste na borda da célula; nada passa para a célula vizinha.
- NÃO use rosa nem magenta no desenho.

NÃO SIGA:
- NÃO copie a roupa, o elmo, o capuz nem as cores de roupa dos personagens anexados: deles, só o acabamento do traço, as proporções e o jeito do rosto.
- NÃO siga o visual de nenhum jogo ou pacote pronto (nada de elmo com pluma azul do Tiny Swords).
```

## Folha 1 · Humano base, de perfil

**Anexar:** `art/sprites/tiny/bonecos/pecas_humano_mago.png` (proporções e rosto aprovados) e `art/sprites/tiny/referencias/estilo_ilustracao.png` (acabamento).
**Saída:** `art/sprites/tiny/candidatos/l24_humano_base_perfil.png`

```text
O HUMANO "pelado": cabelo castanho curto e bagunçado, orelhas normais, olhos de pontinho, pele cor de pêssego, vestindo só uma túnica simples BRANCA-CREME (#e8e2d0, sombra #c9c0aa), sem cinto e sem enfeites, e sapatilhas de pano claras.
1) O personagem MONTADO, de perfil olhando para a DIREITA, parado: cabeça em cima do tronco, os dois pezinhos embaixo, a mãozinha da frente flutuando à frente do peito e a de trás aparecendo atrás do corpo.
2) SÓ A CABEÇA, de perfil para a direita, do mesmo tamanho que na célula 1.
3) SÓ O TRONCO com a túnica branca, sem cabeça, sem braços e sem pernas, de perfil para a direita, do mesmo tamanho que na célula 1. A parte de cima do tronco é reta (a cabeça encaixa por cima).
4) SÓ UM PÉ (sapatilha), de perfil para a direita, do mesmo tamanho que na célula 1.
5) SÓ UMA MÃO: uma bolinha fechada (punho) cor de pêssego, do mesmo tamanho que na célula 1.
6) vazia (só o fundo magenta).
```

## Folha 2 · Humano base, de frente e de costas

**Anexar:** a Folha 1 pronta (`l24_humano_base_perfil.png`) e `estilo_ilustracao.png`.
**Saída:** `art/sprites/tiny/candidatos/l24_humano_base_frente_costas.png`

```text
O MESMO humano da imagem 1 (mesma cabeça, cabelo, túnica branca-creme e sapatilhas), mesmo tamanho:
1) MONTADO DE FRENTE (olhando para quem joga): os dois pezinhos lado a lado embaixo e as duas mãozinhas dos dois lados do corpo.
2) SÓ A CABEÇA DE FRENTE, do tamanho que tem na célula 1.
3) SÓ O TRONCO DE FRENTE (túnica branca), do tamanho que tem na célula 1.
4) MONTADO DE COSTAS (vemos a nuca e as costas da túnica).
5) SÓ A CABEÇA DE COSTAS, do tamanho que tem na célula 4.
6) SÓ O TRONCO DE COSTAS, do tamanho que tem na célula 4.
```

## Folha 3 · Humano: rostos 2 e 3, nas três vistas

**Anexar:** as Folhas 1 e 2 prontas e `estilo_ilustracao.png`.
**Saída:** `art/sprites/tiny/candidatos/l24_humano_rostos.png`

```text
SÓ CABEÇAS, todas com EXATAMENTE o mesmo tamanho e o mesmo formato de crânio da cabeça das imagens 1 e 2 (mesma posição do queixo e do pescoço); só mudam o cabelo, as orelhas e o rosto. Pele cor de pêssego, como nas imagens.
ROSTO 2: cabelo ruivo comprido preso num rabo de cavalo, sardinhas nas bochechas, olhos de pontinho.
ROSTO 3: cabelo preto curto espetado, sobrancelhas grossas, ORELHAS PONTUDAS (meio-elfo), um sorrisinho.
1) ROSTO 2 de perfil para a direita.
2) ROSTO 2 de frente.
3) ROSTO 2 de costas.
4) ROSTO 3 de perfil para a direita.
5) ROSTO 3 de frente.
6) ROSTO 3 de costas.
```

## Folha 4 · Roupa do Guerreiro (humano), de perfil e de frente

**Anexar:** as Folhas 1 e 2 prontas e `estilo_ilustracao.png`.
**Saída:** `art/sprites/tiny/candidatos/l24_humano_guerreiro_perfil_frente.png`

```text
A ROUPA BASE DO GUERREIRO no MESMO humano das imagens (mesmo tamanho): um ELMO de ferro redondo e simples, com uma tira de couro em volta e a abertura do rosto bem grande (o rosto e a franja aparecem), e uma TÚNICA vermelho-escura apagada (#9b3d3d, sombra #6e2b33) com uma cota de malha cinza curta por cima (#9cbeaa, sombra #688c8a), cinto de couro marrom com fivela, e as mesmas sapatilhas claras.
1) O GUERREIRO MONTADO de perfil olhando para a DIREITA, com o elmo e a túnica.
2) SÓ O TRONCO com a túnica e a cota, de perfil, do mesmo tamanho que na célula 1 (a parte de cima reta, onde a cabeça encaixa).
3) SÓ O ELMO de perfil, do mesmo tamanho e no mesmo ângulo que na célula 1, SEM a cabeça dentro: a abertura do rosto fica VAZADA (fundo magenta), para o rosto aparecer por baixo no jogo.
4) O GUERREIRO MONTADO DE FRENTE.
5) SÓ O TRONCO DE FRENTE.
6) SÓ O ELMO DE FRENTE, sem a cabeça dentro, com a abertura do rosto VAZADA (fundo magenta).
```

## Folha 5 · Roupa do Guerreiro (humano), de costas

**Anexar:** a Folha 4 pronta e a Folha 2 pronta.
**Saída:** `art/sprites/tiny/candidatos/l24_humano_guerreiro_costas.png`

```text
O MESMO guerreiro da imagem 1 (mesmo elmo, túnica, cota e cinto), visto DE COSTAS, do mesmo tamanho:
1) O GUERREIRO MONTADO DE COSTAS (vemos a parte de trás do elmo e as costas da túnica).
2) SÓ O TRONCO DE COSTAS, do mesmo tamanho que na célula 1.
3) SÓ O ELMO DE COSTAS, sem a cabeça dentro, do mesmo tamanho que na célula 1.
4) 5) 6) vazias (só o fundo magenta).
```

## Depois de gerar

Salvar só nos caminhos de saída indicados. Não mexer em `game/` nem em nenhum outro arquivo. Responder com os caminhos e o tamanho de cada imagem.

## Depois do piloto: as outras raças e classes (mesmos textos, trocando o que está abaixo)

O piloto do Humano deu certo (base, tons de pele e roupa do Guerreiro montados no jogo). As outras folhas usam EXATAMENTE os mesmos textos das Folhas 1 a 5, trocando:

**Ogro (Folhas 1, 2 e 3 do ogro):** saídas `l24_ogro_base_perfil.png`, `l24_ogro_base_frente_costas.png`, `l24_ogro_rostos.png`. Anexar `art/sprites/tiny/bonecos/pecas_ogro_mago.png` (proporções e rosto aprovados do ogro) no lugar do humano.
- Base: OGRO "pelado", maior e mais largo que o humano (cerca de 380 px de altura montado), pele verde-oliva (#8fb35a, sombra #6b8a43), careca com um tufinho de cabelo preto no topo, orelhas pontudas pequenas, duas presinhas brancas saindo do lábio de baixo para cima, olhos de pontinho, a MESMA túnica branca-creme simples (mais larga) e sapatilhas de pano claras. Mãos verdes.
- ROSTO 2 do ogro: moicano preto alto, uma argolinha dourada na orelha.
- ROSTO 3 do ogro: barba preta curta trançada no queixo, presas maiores, sobrancelhas grossas.

**Mago (Folhas 4 e 5, uma vez com o humano e outra com o ogro):** saídas `l24_<raca>_mago_perfil_frente.png` e `l24_<raca>_mago_costas.png`.
- Roupa: CHAPÉU de mago pontudo azul-escuro (#485884, sombra #33405f) com faixa dourada (#cea554) e a ponta caída para trás, aba redonda; MANTO azul-escuro comprido até perto dos pés, gola dourada e um cordão dourado na cintura. O chapéu sozinho: só o chapéu, sem cabeça embaixo (a parte de baixo da aba é aberta).

**Arqueiro (Folhas 4 e 5, uma vez com o humano e outra com o ogro):** saídas `l24_<raca>_arqueiro_perfil_frente.png` e `l24_<raca>_arqueiro_costas.png`.
- Roupa: CAPUZ verde-musgo (#5b7a4a, sombra #435c3a) que cobre o cabelo e deixa o rosto aparecer (abertura do rosto VAZADA no capuz sozinho); GIBÃO de couro marrom (#955c3c, sombra #6e4433) sobre uma túnica verde-musgo, cinto de couro e uma alça de couro cruzando o peito. De costas, uma aljava de couro com 3 penas aparecendo (só nas costas do tronco).

**Guerreiro do ogro (Folhas 4 e 5 com o ogro):** saídas `l24_ogro_guerreiro_perfil_frente.png` e `l24_ogro_guerreiro_costas.png`. O mesmo elmo e a mesma túnica com cota do guerreiro humano (anexar `l24_humano_guerreiro_perfil_frente.png` também), no tamanho do ogro; o elmo com abertura grande para as presas aparecerem.
