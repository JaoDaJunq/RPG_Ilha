# L08 · Piloto SIMPLES, no sentido do Forager

**Por quê (30/10):** o João mandou prints do Forager e disse que tudo no nosso jogo parece "desenhado em 4K e depois reduzido". Ele está certo: a IA desenha muitos detalhes miúdos e a conversão espreme isso em poucos pixels, então sobra um borrão de cores. O Forager tem pixels até MAIORES que os nossos na tela; o que o deixa bonito é a **simplicidade**:
- formas grandes e redondinhas;
- cor chapada com só 1 tom de luz e 1 de sombra;
- contorno escuro de 1 pixel;
- quase nada de textura.

Então aqui a arte é pedida **já no tamanho final**, numa grade bem grossa (cada pixel do jogo = um quadrado de 16x16 na imagem), para não haver espaço para detalhe miúdo.

**Anexar:** `art/conceitos/mundo/clareira_b_v1.png` (só as CORES da ilha) e `art/sprites/personagens/personagens_v1.png` (só QUEM são o Mago e o Ogro Arqueiro: roupa e cores). Não copiar o acabamento detalhado deles.

**Regras (copiar no começo de cada geração):**

```text
PIXEL ART SIMPLES E FOFA, no espírito do jogo Forager: formas grandes, arredondadas e limpas; cada objeto tem no máximo 4 cores chapadas (cor base, 1 tom de luz, 1 tom de sombra) mais um contorno de 1 pixel num tom bem escuro da própria cor (nunca preto puro). Sem textura, sem ruído, sem pontilhado, sem degradê, sem anti-aliasing, sem detalhe miúdo. Luz vindo de cima à esquerda.
GRADE OBRIGATÓRIA: cada pixel do sprite é um QUADRADO SÓLIDO de exatamente 16x16 pixels na imagem, todos alinhados na mesma grade começando no canto (0,0). Imagem 1536x1024 = grade de 96x64 pixels de jogo, dividida em 3 colunas x 2 linhas de células de 512x512 (32x32 pixels de jogo cada). Cada objeto centralizado na sua célula, com a base perto da borda de baixo e margem de pelo menos 2 pixels de jogo. Fundo magenta chapado #FF00FF. Sem chão, sem sombra projetada, sem texto, sem grade desenhada, sem moldura.
Cores da ilha: grama #90B030 / #709030 / #507030; folhas #509050 / #307050 / #305030; tronco e madeira #C8803C / #8A5028 / #50301C; pedra #A0A0A8 / #707078 / #484850; areia #E8D08A / #C8A060; água #40C8D8 / #2090B0; espuma #E8F8F8; acentos rosa #E890B0, vermelho #D04040, azul #5070D0, amarelo #F0D040.
```

## 1. Personagens e natureza

**Saída:** `art/sprites/piloto_simples/candidatos/simples_objetos_v1.png`

```text
Células (tamanho em pixels de jogo):
1) Humano Mago de frente, parado, 16 de largura x 20 de altura: cabeça grande (metade da altura), capuz azul-escuro com borda dourada, cabelo castanho, olhos = 2 pixels escuros, bochecha rosada de 1 pixel, túnica azul, botas marrons. Fofo e legível.
2) Ogro Arqueiro de frente, parado, 16 x 20: pele verde-acinzentada, CAPUZ DE COURO MARROM (bem diferente da pele), olhos = 2 pixels escuros, boca escura com 2 presinhas brancas de 1 pixel subindo nos cantos da boca (NADA embaixo dos olhos), aljava marrom nas costas.
3) Árvore redonda: copa redonda de 26 de largura feita de 3 ou 4 "bolas" grandes de folha, tronco curto marrom de 6 de largura, altura total 30.
4) Pinheiro: 3 camadas de triângulo arredondado verde-escuro, tronquinho, 16 de largura x 28 de altura.
5) Pedra cinza arredondada com 1 manchinha de musgo verde, 16 x 13.
6) Arbusto redondo verde com 3 frutinhas vermelhas de 2 pixels, 16 x 13.
```

## 2. Chão, acampamento e armadilha

**Saída:** `art/sprites/piloto_simples/candidatos/simples_chao_itens_v1.png`

```text
Células:
1) Bloco de GRAMA de 32x32 que se repete sem emenda: UMA cor lisa #90B030 quase toda, com só 2 tufinhos de 3 pixels num verde mais escuro. Preenche a célula inteira (sem magenta).
2) Bloco de AREIA de 32x32 que se repete sem emenda: #E8D08A liso com 2 pontinhos #C8A060. Preenche a célula inteira.
3) Bloco de ÁGUA de 32x32 que se repete sem emenda: #40C8D8 liso com 2 risquinhos claros curtos. Preenche a célula inteira.
4) Fogueira: anel de 6 pedras cinza arredondadas com 2 toras e chama laranja-amarela simples no meio, 20 x 16.
5) Baú de madeira marrom com cantos e fecho dourados, 16 x 14.
6) ARMADILHA DE URSO aberta, vista de cima em 3/4: duas mandíbulas de metal cinza-claro em semicírculo com dentes triangulares brancos, placa redonda no meio, contorno escuro, 18 x 12. Bem legível: tem que dar para saber na hora que é uma armadilha de urso.
```

## Depois de gerar

Salvar só nos dois caminhos acima. Não mexer em `game/` nem em nenhum outro arquivo. Responder com os caminhos e o tamanho em pixels de cada imagem.
