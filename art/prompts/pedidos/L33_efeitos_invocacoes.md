# L33 · Arte das habilidades novas: invocações, objetos e efeitos

**Por quê (12/11/2026):** as ~85 habilidades novas da árvore funcionam, mas usam desenhos emprestados: o falcão é a galinha, o golem é uma pedra, a torre é um barril, e a nuvem tóxica quase não aparece. O João pediu a arte própria.

**Anexar em todas as folhas:**
1. `art/prompts/reguas/objetos_4x.png`: a régua do pacote Tiny Swords (o estilo a copiar).
2. `art/sprites/tiny/acampamento_v2.png`: os nossos objetos aprovados.

**Regras (copiar no começo do texto):**

```text
FAÇA:
- Pixel art no MESMO estilo da régua (Tiny Swords) e do acampamento anexados: quadrados de 4x4 na imagem (cada célula de 512 = 128 pixels de jogo), contorno de 1 pixel #161c2e, 2 ou 3 tons por material, luz de cima à esquerda, vistos de cima em 3/4, cores apagadas do Tiny Swords.
- Imagem 1536x1024, grade de 3 colunas x 2 linhas (células de 512x512), UMA peça por célula, centralizada, base 32 px acima do fundo da célula. Fundo magenta chapado #FF00FF.
- Medidas em PIXELS DE JOGO (na imagem, multiplique por 4). Um personagem nosso tem ~22 de altura; uma ovelha da régua ~40 de largura.
- Efeitos de magia: formas grandes e simples, cor do elemento (fogo laranja, gelo azul-claro, raio amarelo, terra marrom, veneno verde, luz dourada, sombra roxa), com transparência feita só por pixels mais claros (sem degradê).

NÃO FAÇA:
- NÃO use quadrados de tamanhos diferentes, degradê, borrado ou anti-aliasing.
- NÃO use contorno preto puro ou cores saturadas demais.
- NÃO desenhe chão, grama, sombra no chão, texto ou moldura.
- NÃO encoste na borda da célula.

NÃO SIGA:
- NÃO siga "pixel art de RPG genérico": siga a régua.
```

Célula marcada "vazia": só o fundo magenta.

**Saída:** `art/sprites/tiny/candidatos/l33_<NN>.png` (NN = número da folha).

## Folha 01: invocações (de perfil olhando para a DIREITA)
1. FALCÃO voando, asas para CIMA: marrom com peito claro, bico amarelo curvo. 20 x 14.
2. O MESMO FALCÃO, asas para BAIXO.
3. GOLEM DE PEDRA parado: corpo de pedras cinza empilhadas, musgo verde nos ombros, olhos verdes brilhando, braços grossos. 30 x 34.
4. O MESMO GOLEM dando um soco: um braço esticado para a frente.
5. TOTEM TESLA: poste de metal com bobina de cobre em cima e uma bolinha amarela brilhando no topo. 14 x 30.
6. TORRE DE BESTA: besta de madeira montada num tripé de madeira, virada para a direita. 24 x 22.

## Folha 02: objetos das habilidades
1. MINA DE FOGO no chão: disco de metal escuro com uma luzinha vermelha no meio. 12 x 8.
2. REDE aberta no ar: rede de corda em quadrados, quatro pesinhos nas pontas. 20 x 20.
3. A MESMA REDE caída e enrolada no chão (prendendo algo). 22 x 10.
4. ESTANDARTE: mastro de madeira fincado com bandeira vermelha com borda dourada. 14 x 32.
5. MARTELO DE LUZ: martelo de guerra dourado brilhando, deitado na horizontal (vai girar). 20 x 10.
6. ESCUDO DE ARREMESSO: escudo redondo de madeira com borda de ferro, visto de frente (vai girar). 14 x 14.

## Folha 03: efeitos no chão (vistos de cima em 3/4)
1. POÇA DE ÁCIDO: poça amarelo-esverdeada com bolhas. 40 x 18.
2. NUVEM TÓXICA: nuvem verde gorda e baixa, com bolhas. 44 x 26.
3. CÍRCULO DE CURA: anel verde-claro no chão com cruzinhas e brilhos. 48 x 22.
4. ESPINHOS DE PEDRA: quatro estacas de pedra pontudas saindo do chão. 24 x 18.
5. FENDA: rachadura reta e longa no chão, com pedrinhas soltas, na horizontal. 60 x 10.
6. BLOCO DE MURALHA DE GELO: bloco de gelo azul-claro, alto, com brilho. 16 x 24.

## Folha 04: efeitos de luz e grandes
1. CÚPULA DE LUZ: meia bolha dourada transparente (só o contorno e alguns brilhos), vista de lado. 56 x 34.
2. PAREDE DE LUZ: parede de luz dourada transparente, reta, de frente. 40 x 24.
3. METEORO caindo na diagonal (de cima à esquerda para baixo à direita): pedra em chamas com rastro de fogo. 24 x 24.
4. TORNADO DE FOGO, quadro A: funil de fogo laranja e vermelho, largo em cima. 24 x 36.
5. TORNADO DE FOGO, quadro B: o mesmo funil com as chamas giradas.
6. PEDRA ROLANDO: pedra redonda com riscos de movimento. 14 x 14.

## Folha 05: efeitos especiais
1. NEVASCA: nuvem baixa branco-azulada com flocos de neve caindo. 48 x 30.
2. MARCA DE ALVO (fica em cima da cabeça do inimigo marcado): mira vermelha redonda com quatro risquinhos. 10 x 10.
3. MARCA DA MORTE (fica em cima da cabeça): caveira roxa pequena brilhando. 10 x 10.
4. COLUNA DE LUZ: feixe vertical de luz dourada caindo do céu, estreito. 14 x 60.
5. CORRENTE com gancho, na horizontal: elos de ferro e um gancho na ponta direita. 32 x 8.
6. FORMA DE RELÂMPAGO: silhueta de pessoa feita de raios amarelos. 16 x 24.

Salvar só nos caminhos acima. Não mexer em `game/` nem em nenhum outro arquivo.
