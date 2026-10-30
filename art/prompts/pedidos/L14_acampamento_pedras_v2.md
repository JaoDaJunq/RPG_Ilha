# L14 · Acampamento, pedras e slime refeitos no estilo Tiny Swords

**Por quê (30/10):** o João reprovou o acampamento e as pedras do L12 ("muito ruim"). Ao lado das peças do pacote, o diagnóstico mostrou:
- pixel 2 a 3 vezes maior que o deles;
- contorno preto e grosso;
- cores fortes;
- sem sombra no chão.

Ver `design/processo_arte.md`, seção "Diagnóstico do L12".

**Anexar, nesta ordem (nos dois pedidos):**
1. `art/prompts/reguas/objetos_4x.png`: **A RÉGUA.** Peças do pacote ampliadas EXATAMENTE 4x, na MESMA grade (pedra de ouro, ovelha, arbusto, toco, tora, pedrinha).
2. `art/prompts/reguas/personagens_4x.png`: tamanho dos personagens do pacote, na mesma escala, para os objetos terem o tamanho certo perto deles.
3. `evidence/comparacao/l12_atual.png`: **EXEMPLO DO QUE NÃO FAZER.** Em cima, o pacote (certo). Embaixo, a nossa tentativa anterior (errada).

**Regras (copiar no começo dos dois pedidos):**

```text
TAREFA: desenhar objetos NOVOS que pareçam ter saído do MESMO pacote da imagem-régua anexada (o jogo Tiny Swords). Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512. Cada célula tem UM objeto num quadro de 128x128 pixels de jogo, ampliado EXATAMENTE 4x (cada pixel do jogo = um quadrado de 4x4 na imagem, igual à régua).

FAÇA:
- Mesmo tamanho de pixel da régua: quadrados de 4x4, todos alinhados na mesma grade.
- O tamanho de cada objeto em PIXELS DE JOGO está na lista (na imagem, multiplique por 4). Compare com a régua: a ovelha tem ~40 de largura e o personagem ~80 de altura.
- A base do objeto 16 px acima do fundo da célula, centralizado na largura.
- Contorno de 1 pixel de jogo (4 px na imagem) na cor #161c2e em volta e entre as partes, como na régua.
- Formas redondinhas e simples, sombreamento em 2 ou 3 tons por material, luz de cima à esquerda, vistos de cima em 3/4 como as peças da régua.
- Cores apagadas do pacote: madeira #977b6b #8d6857 #c8a876 #cf9c71 #5e5455; pedra #688c8a #9cbeaa #485884 #5e5455; verde #44a079 #699157 #6e7e53; lona e papel #efe1ab #e1dca3 #bbae93; fogo #e9f044 #e76161 #cea554; contorno #161c2e.

NÃO FAÇA:
- NÃO use pixel maior que 4x4 na imagem (a tentativa anterior usou ~11 px: ficou grosseira).
- NÃO desenhe ilustração com "cara de pixel": nada de quadradinhos de tamanhos diferentes, degradê dentro do quadrado ou borrado.
- NÃO use contorno preto puro nem contorno com 2 ou mais pixels de jogo.
- NÃO use cores saturadas (nada de laranja vivo na madeira nem verde-limão).
- NÃO desenhe sombra no chão (o jogo coloca; a mancha roxa embaixo das peças da régua é a sombra deles sobre o magenta, ignore).
- NÃO desenhe chão, grama, cenário, texto, número, moldura ou linhas de grade.
- NÃO deixe o objeto maior ou menor do que a medida pedida, e nada atravessa para a célula vizinha.

NÃO SIGA:
- NÃO siga a fileira de baixo da imagem de exemplo (l12_atual.png): é o que deu errado.
- NÃO siga "pixel art de RPG genérico": siga só a régua.
```

## 1. Acampamento

**Saída:** `art/sprites/tiny/candidatos/acampamento_v2.png`

```text
(regras acima) +
1) Fogueira acesa: anel de 7 pedras cinza-azuladas redondas, 3 toras e uma chama amarela e vermelha simples. 52 x 44 pixels de jogo.
2) Barraca de lona clara (#efe1ab) em forma de A, com duas estacas de madeira e cordas, entrada escura no meio. 104 x 92.
3) Baú de madeira com tampa arredondada, cantos e fecho de metal cinza-azulado. 44 x 36.
4) Barril de madeira em pé, com dois aros de metal. 32 x 42.
5) Bancada de trabalho: mesa de madeira grossa com um martelo e uma serra em cima. 84 x 56.
6) Varal: dois postes de madeira com uma corda e um pano claro pendurado. 96 x 64.
```

## 2. Pedras, cogumelo e slime

**Saída:** `art/sprites/tiny/candidatos/pedras_slime_v2.png`

```text
(regras acima) +
1) Pedra grande cinza-azulada (#688c8a, #9cbeaa, sombra #485884), arredondada, com 2 manchinhas de musgo. O MESMO tipo de forma e acabamento da pedra de ouro da régua, mas pedra comum. 64 x 52 pixels de jogo.
2) A mesma pedra rachada ao meio, com 2 pedrinhas soltas ao lado. 70 x 52.
3) Pedra média do mesmo tipo. 44 x 36.
4) Grupinho de 3 cogumelos turquesa (#4697ac, #9cbeaa) com cabinho claro. 32 x 30.
5) Slime verde (#44a079, #39cd6a, brilho #d4edc2) parado: gota redonda, olhos de 2 pixels escuros, sem boca. 44 x 36.
6) O mesmo slime achatado (no meio do pulo). 52 x 28.
```

## Depois de gerar

Salvar só nos dois caminhos acima. Não mexer em `game/` nem em nenhum outro arquivo. Responder com os caminhos e o tamanho em pixels de cada imagem.
