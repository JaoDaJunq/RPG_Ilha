# L04 · Interface (painéis, botões, espaços, ícones, tecla E) e armadilha do Arqueiro

**Por quê:** no playtest o João achou todos os painéis feios (menu, ficha, HUD) e a armadilha do Arqueiro sem sentido (era só um ícone no chão). Este lote dá arte própria para a interface e para a armadilha.

**Anexar em todos:** `art/conceitos/mundo/clareira_b_v1.png` (estilo e cores) e `art/sprites/natureza/arvore_v1.png` (acabamento de pixel aprovado).

**Regras para todas as imagens (copiar no começo de cada geração):**

```text
PIXEL ART de verdade para a interface e objetos de um jogo de fantasia 2D numa ilha (mesmo estilo e paleta da imagem anexada). Pixels quadrados nítidos e GRANDES, todos do mesmo tamanho e alinhados numa grade, sem anti-aliasing, sem borrado, sem degradê suave. Contorno escuro de 1 pixel (marrom bem escuro, não preto), 2 a 3 tons por material, luz de cima-esquerda. Imagem 1536x1024 com grade de 3 colunas x 2 linhas (cada célula 512x512). Fundo magenta chapado #FF00FF em toda a imagem. Cada célula tem só o objeto pedido, centralizado, com espaço vazio em volta; nada encosta na borda da célula. Proibido: texto (exceto onde o pedido mandar), números, grade desenhada, moldura em volta da célula, sombra projetada.
```

## 1. Peças da interface

**Saída:** `art/sprites/interface/candidatos/interface_v1.png`

```text
Peças de interface de um jogo de sobrevivência de fantasia: madeira escura envernizada com cantos de metal dourado envelhecido e rebites, interior de couro/pergaminho escuro esverdeado (para texto claro ficar legível). Aconchegante e mágico, combinando com a ilha anexada.
1) PAINEL para janelas: quadro de 48x48 pixels (ampliado 8x: cada pixel vira um quadrado de 8x8), moldura de 6 pixels de espessura com cantos decorados de metal dourado e interior liso escuro. Feito para esticar como "9-slice": os 4 cantos têm o enfeite, as bordas e o interior são lisos e repetíveis.
2) BOTÃO normal: 48x16 pixels (ampliado 8x), madeira com borda dourada, interior liso, sem texto.
3) O MESMO BOTÃO destacado (mouse em cima): madeira mais clara e borda dourada brilhante, mesmo tamanho e formato.
4) ESPAÇO de item/habilidade: quadrado de 24x24 pixels (ampliado 16x), moldura de madeira e metal com interior escuro afundado, vazio.
5) O MESMO ESPAÇO selecionado: moldura dourada mais grossa e brilhante, mesmo tamanho.
6) TECLA "E": uma teclinha de teclado de 14x14 pixels (ampliada 16x), bege-claro com contorno escuro, a letra E grande e escura no meio, legível. É o aviso que aparece em cima da árvore para mostrar que dá para interagir.
```

## 2. Ícones de atributos e da ficha

**Saída:** `art/sprites/interface/candidatos/icones_v1.png`

```text
Ícones pequenos e muito legíveis, cada um um quadro de 16x16 pixels ampliado 16 vezes (cada pixel vira um quadrado de 16x16), formas simples, cores fortes, contorno escuro:
1) FORÇA: punho fechado (pele clara, faixa vermelha no pulso).
2) VITALIDADE: coração vermelho com brilho.
3) AGILIDADE: pena verde com movimento (2 tracinhos ao lado são permitidos aqui).
4) INTELECTO: livro azul aberto com uma runa brilhante.
5) ESPÍRITO: chama azul-turquesa.
6) EXPERIÊNCIA: estrela dourada de 5 pontas.
```

## 3. Armadilha do Arqueiro

**Saída:** `art/sprites/habilidades/candidatos/armadilha_v1.png`

```text
Armadilha de caça de ferro com dentes (tipo armadilha de urso), feita para um jogo visto de cima em 3/4: vemos a armadilha deitada no chão, de cima e um pouco de frente. Cada célula é UM quadro de 32x32 pixels ampliado 16 vezes (cada pixel vira um quadrado de 16x16). A armadilha tem cerca de 22 pixels de largura e fica no centro de baixo do quadro. Desenhe SÓ a armadilha (sem chão, sem grama, sem sombra).
1) ARMADA: aberta, dentes de ferro para cima, molas e corrente curta presa a uma estaca de madeira; um pouco disfarçada com 2 ou 3 folhas verdes por cima.
2) FECHANDO: as duas mandíbulas no meio do caminho, subindo.
3) FECHADA: mandíbulas juntas, dentes encaixados (é assim que fica enquanto prende o inimigo).
4) FECHADA E GASTA: fechada, um pouco torta, sem as folhas (depois de usada, antes de sumir).
5) ÍCONE da habilidade, 16x16 pixels ampliado 16x: a armadilha aberta vista de frente, simples e legível, com fundo de círculo verde-escuro.
6) vazia (só magenta).
```

## Depois de gerar

Salvar só nos três caminhos de saída acima (criar as pastas se faltar). Não mexer em `game/` nem em nenhum outro arquivo. Responder com os caminhos e o tamanho em pixels de cada imagem.
