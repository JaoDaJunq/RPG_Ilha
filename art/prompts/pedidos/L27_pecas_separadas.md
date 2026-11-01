# L27 · Peças separadas: boneco careca, cabelos, roupas e chapéus, cada um sozinho

**Por quê (01/11):** no L26, a roupa saiu de um boneco já vestido, com o boneco recortado fora. O João viu que ficava borrado e esquisito. Agora é como nos jogos: **cada peça é desenhada sozinha e inteira**, e o jogo junta tudo. Para cada peça cair no lugar certo, ela é desenhada em cima de um **FANTASMA**: o boneco em cinza-claro, que serve só de guia e é apagado depois.

## Passo 1 · O boneco padrão CARECA

**Anexar:** `art/sprites/tiny/gabarito/gabarito_humano.png`.
**Saída:** `art/sprites/tiny/gabarito/gabarito_humano_careca.png`

```text
TAREFA: EDITAR a imagem anexada. Devolva a MESMA imagem (1536x1024, fundo magenta #FF00FF, os mesmos 3 bonecos nos mesmos lugares, mesmo tamanho e mesma pose), com uma única mudança: os 3 bonecos ficam CARECAS. Tire todo o cabelo e desenhe o alto e a parte de trás da cabeça como uma cabeça careca lisa, da cor da pele (pêssego), com o mesmo contorno grosso. As orelhas continuam. O rosto, os olhos, a túnica, as mãos e os pés ficam IDÊNTICOS.
NÃO mova, NÃO aumente, NÃO diminua nada. NÃO desenhe chapéu, nem sombra, nem fundo.
```

## Passo 2 · As peças, cada uma sozinha, em cima do FANTASMA

**Anexar:** `art/sprites/tiny/gabarito/fantasma_humano.png` (o boneco careca em cinza-claro, só como guia).

**Texto de todas as peças (copiar no começo):**
```text
TAREFA: a imagem anexada tem um FANTASMA: o mesmo boneco em 3 vistas (perfil olhando para a DIREITA, frente e costas), em cinza-claro, só como guia de tamanho e de lugar. Devolva a MESMA imagem (1536x1024, fundo magenta #FF00FF, o fantasma exatamente igual e no mesmo lugar) com UMA PEÇA desenhada por cima do fantasma, em cada uma das 3 vistas, no lugar exato onde ela fica no corpo.
FAÇA:
- Desenhe SÓ a peça pedida, inteira e caprichada, em ILUSTRAÇÃO lisa, no acabamento do jogo: contorno #161c2e grosso (cerca de 5 px) em volta de toda a peça, cores chapadas com um tom de sombra, luz de cima.
- A peça tem o tamanho do corpo do fantasma: encaixa na cabeça, no tronco etc. como se estivesse vestida nele.
- Nas 3 vistas a peça é a MESMA (mesmas cores e detalhes), vista de perfil, de frente e de costas.
NÃO FAÇA:
- NÃO pinte, NÃO mude e NÃO mova o fantasma: ele fica cinza-claro, igual ao anexado.
- NÃO desenhe pele, rosto, olhos, mãos, pés, cabelo ou qualquer outra peça além da pedida.
- NÃO desenhe arma, sombra no chão, fundo, texto ou moldura.
NÃO SIGA:
- NÃO desenhe um personagem: é só a peça, vestida no fantasma.
```

| Saída (em `art/sprites/tiny/gabarito/`) | Peça |
|---|---|
| `peca_cabelo_1.png` | CABELO castanho curto e bagunçado (#955c3c, sombra #6e4433, brilho #c06d50), cobrindo o alto da cabeça, com franja na testa (sem cobrir os olhos) e as pontas soltas atrás. |
| `peca_cabelo_2.png` | CABELO ruivo (#c94d3a, sombra #8d3a33) comprido, preso num RABO DE CAVALO alto atrás, com franja de lado. |
| `peca_roupa_mago.png` | MANTO de mago azul-escuro (#485884, sombra #33405f) do pescoço até perto dos pés, mangas largas até os pulsos (as mãos ficam de fora), gola dourada (#cea554) e cordão dourado na cintura. |
| `peca_chapeu_mago.png` | CHAPÉU de mago pontudo azul-escuro (#485884, sombra #33405f) com faixa dourada (#cea554), ponta caída para trás e aba redonda; sentado na cabeça, com a aba na altura da testa. A parte de baixo da aba fica aberta (não desenhe cabeça embaixo). |
| `peca_roupa_arqueiro.png` | GIBÃO de couro marrom (#955c3c, sombra #6e4433) sobre túnica verde-musgo (#5b7a4a) até a cintura e um pouco abaixo, cinto de couro com fivela e uma alça cruzando o peito; de costas, uma aljava de couro com 3 penas. |
| `peca_capuz_arqueiro.png` | CAPUZ verde-musgo (#5b7a4a, sombra #435c3a) cobrindo a cabeça inteira e as orelhas, com a abertura do rosto VAZADA (fundo magenta no lugar do rosto). |

Salvar só no caminho de saída. Não mexer em mais nenhum arquivo. Responder com o caminho e o tamanho da imagem.
