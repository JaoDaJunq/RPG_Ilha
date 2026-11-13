# L37 · Armas das 5 classes na mão e arco puxando (sprite completo)

**Por quê (13/11/2026):** os 20 personagens agora são SPRITE COMPLETO (L30/L31), em ilustração pixelizada. A arma da classe é desenhada pelo jogo na mão da frente, mas hoje vai o ÍCONE da barra (pixel art grossa de 64 px, outro estilo). O João pediu armas novas, no tamanho e no estilo dos personagens novos:
- a adaga hoje é o ícone do golpe furtivo, com riscos pretos de movimento em volta; o Ladino precisa de uma adaga LIMPA (o jogo põe uma em cada mão);
- o arco puxando (L23) "não combina mais" com o personagem completo: falta o arco nas 3 vistas, com a corda puxada e a flecha encaixada desenhadas no próprio arco.

A fogueira deste lote é feita com o Pixelbolt (efeito), sem pedido ao Codex.

**Método:** ilustração lisa, igual aos personagens (L30/L31). O Claude converte com `game/tools/pixelizar.gd` (paleta e contorno do Tiny Swords) na MESMA escala dos personagens: 1 px do jogo = ~4,5 px da ilustração.

**Anexar, nesta ordem (em todas as folhas):**
1. `art/sprites/tiny/candidatos/l31_humano_ladino_perfil.png` e `l31_humano_arqueiro_perfil.png`: **o traço, a grossura do contorno e a ESCALA**. As armas são desenhadas para caber nessas mãos fechadas (a mão tem ~60 px de largura na ilustração).
2. `art/sprites/tiny/referencias/estilo_ilustracao.png`: **o acabamento** (traço, cor chapada, contorno grosso).
3. `art/prompts/reguas/personagens_4x.png`: as unidades do Tiny Swords, para as **cores apagadas** (a espada e o arco delas).

## Folha 1 · as 4 armas

**Saída:** `art/sprites/tiny/candidatos/l37_armas_v1.png`

```text
TAREFA: uma folha com 4 ARMAS soltas, em ILUSTRAÇÃO 2D limpa (NÃO pixel art), no MESMO traço, contorno e escala dos personagens da imagem 1, com o acabamento da imagem 2 e as cores apagadas da imagem 3. Cada arma é a que o personagem da imagem 1 seguraria na mão fechada.
Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512, UMA arma por célula, centralizada. Fundo magenta chapado #FF00FF.

1) ESPADA do Guerreiro: espada curta de ferro, lâmina larga e reta de metal claro azulado (dois tons: #c5d6d2 e #8aa6a3, brilho #ffffff numa listra fina), ponta triangular, guarda reta marrom-escura, cabo de couro marrom com 2 faixas, pomo redondo. Comprimento total 200 px.
2) CAJADO do Mago: cajado de madeira escura levemente torto, com um nó no meio, e na ponta de cima um cristal azul-turquesa (#4697ac, #74c7d4, brilho #ffffff) preso por 3 galhinhos que abraçam a pedra. Comprimento total 270 px.
3) ADAGA do Ladino: adaga pequena, lâmina reta e fina de metal claro (#c5d6d2, #8aa6a3) com ponta aguda, guarda pequena curva de bronze, cabo de couro escuro, pomo pequeno. Comprimento total 120 px. LIMPA: só a adaga.
4) MAÇA do Clérigo: cabo de madeira clara com punho de couro, cabeça redonda de ferro com 6 cravos curtos e rombudos e um anel dourado (#cea554) onde a cabeça encontra o cabo. Comprimento total 180 px.
5) vazia (só o fundo magenta).
6) vazia (só o fundo magenta).

FAÇA:
- Cada arma NA DIAGONAL a 45 graus: o CABO EMBAIXO À ESQUERDA e a PONTA EM CIMA À DIREITA, reta (sem perspectiva), como se estivesse na mão de um personagem olhando para a direita, com o braço para baixo.
- O cabo bem visível e com o mesmo tamanho de uma mão fechada da imagem 1 (o jogo põe a mão em cima dele).
- Contorno #161c2e grosso (cerca de 5 px) e uniforme em volta de tudo e entre as partes, IGUAL ao dos personagens da imagem 1.
- Cores chapadas com UM tom de sombra (cel shading), luz de cima à esquerda, cores apagadas do Tiny Swords.
- Formas grandes e simples: nada mais fino que 12 px (some ao reduzir 4,5 vezes).

NÃO FAÇA:
- NÃO desenhe mão, braço, personagem, bainha, fundo, moldura, chão nem sombra no chão.
- NÃO desenhe riscos de movimento, rastro, brilho em volta, faíscas, estrelinhas nem efeito de golpe.
- NÃO use pixel art, quadradinhos, degradê suave, borrado, texto, números nem grade.
- NÃO use contorno preto puro, cores saturadas, rosa ou magenta no desenho.

NÃO SIGA:
- NÃO siga os ícones antigos do jogo (pixel art grossa com riscos em volta): o estilo agora é o dos personagens da imagem 1.
- NÃO siga "arma de RPG genérica" detalhada, com gravuras e pedras pequenas: aqui é desenho de unidade do Tiny Swords, redondinho e simples.
```

## Folhas 2, 3 e 4 · o arco puxando, uma folha por vista

**Saídas:**
- `art/sprites/tiny/candidatos/l37_arco_perfil_v1.png`
- `art/sprites/tiny/candidatos/l37_arco_frente_v1.png`
- `art/sprites/tiny/candidatos/l37_arco_costas_v1.png`

O texto é o mesmo nas 3, trocando só o bloco VISTA.

```text
TAREFA: uma folha de ANIMAÇÃO de UM ARCO CURTO sendo puxado, em ILUSTRAÇÃO 2D limpa (NÃO pixel art), no MESMO traço, contorno e escala do personagem da imagem 1 (o arco é do tamanho certo para a mão dele), com o acabamento da imagem 2 e as cores apagadas da imagem 3.
O MESMO arco em todos os quadros: madeira marrom-média (#8a5a3c, sombra #5c3a2c), pontas levemente viradas para fora, empunhadura de couro escuro no meio, corda clara (#e8dcc0). A flecha: haste de madeira clara, ponta de pedra cinza (#8aa6a3), penas claras (#e8dcc0) com uma faixa vermelha apagada.
Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512, UM quadro por célula.
1) REPOUSO: corda reta, SEM flecha.
2) PUXANDO UM POUCO: flecha encaixada na corda, a corda puxada 1/3 do caminho (forma um V aberto).
3) PUXANDO ATÉ A METADE: a corda e a flecha puxadas 2/3, o arco um pouco mais curvado.
4) PUXADO TODO: a corda bem puxada (V fechado), o arco bem curvado, a flecha pronta.
5) vazia (só o fundo magenta).
6) vazia (só o fundo magenta).

VISTA (perfil): visto de LADO, o arco EM PÉ (vertical), 240 px de altura, com a barriga (a madeira curva) virada para a DIREITA e a corda do lado ESQUERDO. A flecha DEITADA, apontando para a DIREITA, passando pela empunhadura; puxar = a corda e o fim da flecha vão para a ESQUERDA (até 90 px no quadro 4). A empunhadura no MESMO lugar da célula em todos os quadros (centro da célula).

VISTA (frente): o arqueiro mira PARA BAIXO (para quem olha), visto de cima. O arco DEITADO na horizontal, 240 px de largura, com a barriga (a madeira curva) virada para BAIXO e a corda EM CIMA. A flecha EM PÉ, apontando para BAIXO, passando pela empunhadura; puxar = a corda e o fim da flecha sobem (até 90 px no quadro 4). A empunhadura no MESMO lugar da célula em todos os quadros (centro da célula).

VISTA (costas): o arqueiro mira PARA CIMA (para longe de quem olha), visto de cima. O arco DEITADO na horizontal, 240 px de largura, com a barriga (a madeira curva) virada para CIMA e a corda EMBAIXO. A flecha EM PÉ, apontando para CIMA, passando pela empunhadura; puxar = a corda e o fim da flecha descem (até 90 px no quadro 4). A empunhadura no MESMO lugar da célula em todos os quadros (centro da célula).

FAÇA:
- O mesmo arco, mesmas cores e mesmo tamanho em todos os quadros; só a corda, a curva das pontas e a flecha mudam.
- Contorno #161c2e grosso (cerca de 5 px) e uniforme em volta de tudo, IGUAL ao do personagem da imagem 1. A corda pode ser mais fina (cerca de 8 px com o contorno).
- Cores chapadas com UM tom de sombra (cel shading), cores apagadas do Tiny Swords.
- Formas grandes e simples: nada mais fino que 8 px.

NÃO FAÇA:
- NÃO desenhe mão, braço, dedos, personagem, aljava, fundo, moldura, chão nem sombra no chão (o jogo põe o arco na mão do personagem).
- NÃO desenhe riscos de movimento, rastro, brilho, faíscas, texto, números nem grade.
- NÃO use pixel art, quadradinhos, degradê suave, borrado, contorno preto puro, cores saturadas, rosa ou magenta no desenho.

NÃO SIGA:
- NÃO siga o arco antigo do jogo (pixel art grossa, L23) nem "sprite sheet de arqueiro": só o arco, no estilo da imagem 1.
- NÃO deixe o arco na diagonal: na vista de perfil ele fica em pé; de frente e de costas, deitado.
```

## Depois de gerar

Salvar só nos caminhos acima. Não mexer em `game/` nem em nenhum outro arquivo. Responder com o caminho e o tamanho em pixels de cada imagem.

## Folha 5 · chamas da fogueira em laço (alternativa ao Pixelbolt, para comparar)

**Por quê:** o João vai passar muito tempo no acampamento e pediu a fogueira animada. O jogo desenha as pedras e a lenha (arte do L12) e põe as chamas por cima. O Claude fez uma versão com a simulação de fogo do Pixelbolt; esta é a versão desenhada, para escolher a mais bonita lado a lado.

**Anexar:**
1. `art/sprites/tiny/acampamento_v2.png`: a fogueira aprovada é o 1º desenho. Copiar o pixel, as cores das chamas (#cc5050, #f6703e, #ffdc00, #f9f4a9) e o tamanho das chamas.
2. `art/prompts/reguas/objetos_4x.png`: peças do Tiny Swords no mesmo pixel.

**Saída:** `art/sprites/tiny/candidatos/l37_chamas_v1.png`

```text
TAREFA: uma folha de ANIMAÇÃO EM LAÇO de 6 quadros com SÓ AS CHAMAS de uma fogueira pequena, em pixel art no MESMO pixel e nas MESMAS cores das chamas da fogueira da imagem 1 (o 1º desenho).
Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512, um quadro por célula, lidos da esquerda para a direita e de cima para baixo. Fundo magenta chapado #FF00FF.

FAÇA:
- Quadrados de 4x4 na imagem (cada célula = 128 pixels de jogo), sem anti-aliasing.
- As chamas com cerca de 22 pixels de jogo de largura na base e 26 a 32 de altura (na imagem: ~88 px de largura e 104 a 128 de altura), a BASE das chamas sempre na MESMA linha, 100 px acima do fundo da célula, centralizada.
- Cores: borda vermelha #cc5050 nas pontas, laranja #f6703e por fora, amarelo #ffdc00 no meio, creme #f9f4a9 no miolo de baixo. Sem contorno escuro (as chamas do pacote não têm).
- Um fogo vivo: as línguas de fogo mudam de forma e de altura de um quadro para o outro, balançando para a esquerda e a direita, e o 6º quadro emenda no 1º (laço).
- Em 2 dos 6 quadros, uma faísca (1 quadradinho amarelo ou creme) solta acima das chamas.

NÃO FAÇA:
- NÃO desenhe pedras, lenha, chão, sombra, fumaça, brilho em volta, moldura, texto nem número (o jogo põe as pedras e a lenha).
- NÃO use degradê, borrado, quadrados de tamanhos diferentes, nem cores fora das 4 indicadas (rosa ou magenta, nunca).

NÃO SIGA:
- NÃO siga "fogo realista" nem "fogo de anime": siga só as chamas da imagem 1, chapadas e simples.
```
