# L26 · Piloto do gabarito: vestir o boneco SEM mexer nele

**Por quê (01/11):** o encaixe das roupas ficou ruim porque cada roupa vinha de um desenho novo. Agora (pesquisa em `design/pesquisa_roupas.md`, opção A, aprovada pelo João) a roupa é desenhada **em cima do boneco-gabarito**: a imagem anexada é o boneco base, e a sua tarefa é **vesti-lo sem mexer em mais nada**. O jogo compara a sua imagem com o gabarito e recorta só o que mudou. Por isso, qualquer mudança de lugar, tamanho ou pose estraga tudo.

**Anexar:** `art/sprites/tiny/gabarito/gabarito_humano.png` (o GABARITO: 3 vistas do mesmo boneco, uma por coluna: perfil olhando para a direita, frente e costas).

```text
TAREFA: EDITAR a imagem anexada (o gabarito). Devolva uma imagem do MESMO tamanho (1536x1024), com o MESMO fundo magenta #FF00FF e os MESMOS 3 bonecos, cada um EXATAMENTE no mesmo lugar, do mesmo tamanho e na mesma pose, agora VESTINDO a roupa pedida.

FAÇA:
- Mantenha IDÊNTICOS, pixel por pixel, tudo o que a roupa não cobre: o rosto, os olhos, as mãos, os pés, o contorno e a posição de cada parte.
- A roupa por cima do corpo, no mesmo acabamento (ilustração lisa, contorno #161c2e grosso, cores chapadas com um tom de sombra).
- Chapéu ou capuz encaixado na cabeça como ele ficaria de verdade: o cabelo que ficaria escondido debaixo dele NÃO aparece; o cabelo que apareceria (a franja, os lados abaixo da aba) continua igual.

NÃO FAÇA:
- NÃO mova, NÃO aumente, NÃO diminua e NÃO gire nenhum boneco. NÃO mude a pose, a mão nem o pé.
- NÃO desenhe arma, sombra no chão, fundo, texto, moldura ou nada fora dos bonecos.
- NÃO redesenhe o rosto nem as mãos.

NÃO SIGA:
- NÃO faça um personagem novo parecido: é o MESMO desenho, só vestido.
```

## Roupas do piloto

| Saída | Roupa |
|---|---|
| `art/sprites/tiny/gabarito/gabarito_humano_mago.png` | CHAPÉU de mago pontudo azul-escuro (#485884, sombra #33405f) com faixa dourada (#cea554), ponta caída para trás, aba redonda. MANTO azul-escuro até perto dos pés, gola dourada e cordão dourado na cintura. |
| `art/sprites/tiny/gabarito/gabarito_humano_arqueiro.png` | CAPUZ verde-musgo (#5b7a4a, sombra #435c3a) que cobre o cabelo e deixa o rosto à mostra. GIBÃO de couro marrom (#955c3c, sombra #6e4433) sobre túnica verde-musgo, cinto de couro e uma alça cruzando o peito; de costas, uma aljava com 3 penas. |

Salvar só no caminho da saída. Não mexer em mais nenhum arquivo. Responder com o caminho e o tamanho da imagem.
