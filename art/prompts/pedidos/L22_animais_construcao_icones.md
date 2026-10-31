# L22 · Animais, paredes de lado e ícones novos

**Por quê (31/10):** o João pediu:
- **animais iniciais** para a ilha (a ovelha já vem do pacote Tiny Swords, animada);
- **girar as peças de construção** com a rodinha do mouse (falta a parede e a porta vistas de lado);
- **4 habilidades por classe** (faltam os ícones de 6 habilidades novas).

**Anexar nas folhas 1 e 2:**
1. `art/prompts/reguas/objetos_4x.png`: A RÉGUA do pacote em 4x (tem a ovelha deles).
2. `art/sprites/tiny/acampamento_v2.png`: o nosso acampamento aprovado (L14).
3. `art/sprites/tiny/construcao_v1.png`: a parede e a porta aprovadas (L18), só na folha 2.

**Anexar na folha 3:** `art/sprites/tiny/efeitos_icones/icones_habilidades_v1.png` (os nossos ícones de habilidade aprovados).

**Regras das folhas 1 e 2 (copiar no começo):**

```text
FAÇA:
- Pixel art no MESMO estilo da régua (Tiny Swords) e do acampamento anexados: quadrados de 4x4 na imagem (cada célula de 512 = 128 pixels de jogo), contorno de 1 pixel #161c2e, 2 ou 3 tons por material, luz de cima à esquerda, vistos de cima em 3/4, cores apagadas do Tiny Swords.
- Imagem 1536x1024, grade de 3 colunas x 2 linhas (células de 512x512), uma peça por célula, centralizada, base 32 px acima do fundo da célula. Fundo magenta chapado #FF00FF.
- Medidas em PIXELS DE JOGO (na imagem, multiplique por 4). A ovelha da régua tem cerca de 40 de largura.

NÃO FAÇA:
- NÃO use quadrados de tamanhos diferentes, degradê, borrado ou anti-aliasing.
- NÃO use contorno preto puro, contorno grosso ou cores saturadas.
- NÃO desenhe sombra no chão, grama, texto ou moldura.

NÃO SIGA:
- NÃO siga "pixel art de RPG genérico": siga a régua.
```

## Folha 1: animais (de perfil, olhando para a DIREITA)

**Saída:** `art/sprites/tiny/candidatos/animais_v1.png`

```text
1) GALINHA parada: branca com crista vermelha e bico amarelo, gordinha. 20 x 20.
2) A MESMA GALINHA andando: uma perna à frente, corpo um pouco inclinado.
3) COELHO parado: marrom-claro, orelhas compridas, rabinho branco. 18 x 18.
4) O MESMO COELHO no meio de um pulo: esticado, patas para trás.
5) JAVALI parado: marrom-escuro, peludo, dois dentes brancos curtos, focinho rosado. 36 x 26.
6) O MESMO JAVALI andando: pernas abertas no meio do passo.
```

## Folha 2: parede e porta vistas DE LADO (para girar)

**Saída:** `art/sprites/tiny/candidatos/construcao_lateral_v1.png`

```text
As MESMAS parede e porta da imagem 3 anexada, agora vistas DE LADO (correndo de cima para baixo na tela, como uma parede vertical vista de cima em 3/4): 16 de largura x 80 de altura, a parede ocupando um tile de 16 de largura.
1) PAREDE de troncos vista de lado: uma fileira de troncos empilhados de cima para baixo, o topo dos troncos aparecendo.
2) PORTA de tábuas FECHADA vista de lado, no mesmo batente.
3) A MESMA PORTA ABERTA vista de lado (o vão escuro aparecendo).
4) 5) 6) vazias (só o fundo magenta).
```

## Folha 3: ícones (8x)

**Saída:** `art/sprites/tiny/candidatos/icones_habilidades_v2.png`

```text
Mesmo estilo EXATO dos ícones anexados (8x8 na imagem, objeto de ~40 x 40 dos 64 pixels, contorno #161c2e). Imagem 1536x1024, grade 3x2 (células de 512), um ícone por célula, fundo magenta.
1) Bloqueio (Guerreiro): escudo redondo de madeira e aço na frente, com um brilho azul em volta.
2) Fúria (Guerreiro): punho cerrado vermelho com três riscos de raiva.
3) Raio (Mago): raio amarelo em zigue-zague caindo de uma nuvenzinha cinza.
4) Nova de gelo (Mago): estrela de gelo azul-clara com ondas em volta.
5) Chuva de flechas (Arqueiro): três flechas caindo na diagonal, de cima para baixo.
6) Bomba (Arqueiro pirotécnico): bomba redonda preta-azulada com pavio aceso.
```

## Folha 4: ícones de itens dos animais (8x, mesmas regras da folha 3)

**Saída:** `art/sprites/tiny/candidatos/icones_animais_v1.png`

```text
1) Carne crua: um pedaço de carne vermelha com osso branco.
2) Carne assada: o mesmo pedaço, marrom dourado, com um fiozinho de vapor.
3) Pena branca.
4) Couro: um pedaço de couro marrom dobrado.
5) Ovo branco.
6) vazia (só o fundo magenta).
```

Salvar só nos quatro caminhos acima. Não mexer em `game/` nem em nenhum outro arquivo. Responder com os caminhos e o tamanho de cada imagem.
