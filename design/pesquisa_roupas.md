# Pesquisa: como os bons jogos encaixam roupas e chapéus no personagem

*01/11/2026. Estudo para o João decidir. Nada foi mudado no jogo.*

## O resumo em uma frase

Nos jogos em que a roupa encaixa bem, **a roupa é desenhada em cima de um boneco-gabarito fixo**, pixel por pixel, e **o cabelo é uma peça separada que o chapéu pode esconder ou trocar**. Nós fizemos o contrário: cada roupa foi desenhada num boneco diferente e o programa tenta adivinhar onde ela encaixa. É daí que vêm os erros que você viu.

## Como os jogos fazem

### Stardew Valley (o mais parecido com o nosso: pixel art, vista de cima, roupas e chapéus trocáveis)
- O fazendeiro é montado em camadas: corpo, calça, camisa, cabelo, acessório e chapéu.
- **Todo corpo usa o mesmo gabarito**, com o mesmo tamanho e as mesmas posições em cada quadro. A camisa e o chapéu são desenhados para esse gabarito e entram sempre no mesmo lugar.
- **Cada chapéu diz o que acontece com o cabelo**, num campo dos dados do chapéu ("mostrar o cabelo de verdade"):
  1. mostra o cabelo normal;
  2. troca por um **cabelo próprio para usar com chapéu** (mais curto, que cabe debaixo dele);
  3. **esconde o cabelo**.
- Fonte: [wiki de modding do Stardew, página dos chapéus](https://stardewvalleywiki.com/Modding:Hats); [guia de cabelos da comunidade](https://stardewmodding.wiki.gg/wiki/Non-Replacing_Hair_Resource_Guide); [fórum oficial](https://forums.stardewvalley.net/goto/post?id=50801).

### Don't Starve (personagem por peças, como o nosso)
- O personagem tem "símbolos" (cabeça, cabelo, corpo, chapéu). Vestir uma peça é **trocar o símbolo** pela arte daquela peça, que foi desenhada para o mesmo esqueleto.
- Chapéu fechado (elmo): **esconde as camadas de cabelo** e troca a cabeça por uma **"cabeça para chapéu"** (headbase_hat), desenhada para ficar perfeita debaixo do chapéu.
- Chapéu aberto (tiara, coroa): esconde o cabelo, mas deixa a cabeça normal.
- Fonte: [documentação dos chapéus do Don't Starve Together](https://vietnd69.github.io/dst-api-webdocs/docs/game-scripts/prefabs/hats); [fórum da Klei sobre headbase_hat](https://kleiforums.com/forums/topic/106715-headbase_hat-overlap/).

### Terraria
- O jogador é desenhado em peças (cabeça, corpo, braços, pernas), **todas na mesma grade de quadros**. Toda armadura é desenhada sobre esse mesmo molde.
- Cada capacete decide se o cabelo aparece inteiro, em versão curta ou some.
- Fonte: [wiki do Terraria](https://terraria.wiki.gg/wiki/Armor_IDs); [páginas de itens de visual](https://terrariamods.wiki.gg/wiki/Avalon/Vanity_items).

### LPC (o maior pacote livre de personagens montáveis, com milhares de peças)
- Tudo é desenhado num **gabarito único de 64x64**, quadro a quadro, por isso qualquer peça encaixa em qualquer corpo do mesmo tipo.
- Mesmo assim, cabelo com capacete era o problema mais difícil. As soluções usadas foram:
  1. uma **máscara por capacete**, dizendo onde o cabelo pode e não pode aparecer;
  2. nas ferramentas novas, **trocar o cabelo por um parecido que funcione com aquele chapéu**, ou escondê-lo no caso dos elmos.
- Fonte: [gerador LPC atualizado](https://lpc.opengameart.org/node/86658); [discussão do Universal LPC Sprite Sheet](https://lpc.opengameart.org/comment/27086).

### Forager (a referência do nosso estilo de peças)
- **Não tem roupa trocável.** As "skins" trocam o personagem inteiro. É a forma mais simples, e por isso sempre fica bonito.

## O que todos têm em comum (as 4 regras)

1. **Um gabarito fixo por tipo de corpo.** Mesmo tamanho, e os mesmos pontos de encaixe em todos os quadros e vistas: pescoço, topo da cabeça e meio do rosto.
2. **A roupa é desenhada em cima do gabarito,** no tamanho final, e não num boneco à parte. Por isso ela já nasce no lugar certo e ninguém precisa adivinhar.
3. **O cabelo é uma camada separada** da cabeça. A cabeça é careca, com o rosto, e o cabelo vai por cima.
4. **Cada chapéu tem uma regra para o cabelo:** mostrar, trocar por uma versão curta ou esconder. Às vezes a cabeça também é trocada por uma "cabeça para chapéu".

## Por que o nosso ficou ruim (o diagnóstico)

| O que os jogos fazem | O que nós fizemos | O que aconteceu |
|---|---|---|
| Roupa desenhada em cima do gabarito | Cada roupa veio de um desenho novo do Codex, com proporções e tamanho diferentes, e o programa tenta achar onde ela encaixa | Erros de alguns pixels em toda peça: chapéu baixo demais no ogro mago, bandana flutuando de costas, manto largo |
| Cabelo separado da cabeça | O cabelo vem grudado na cabeça, e cada rosto tem um volume de cabelo | O corte automático do cabelo erra, e sobram tufos ou cortes retos |
| Chapéu feito para a cabeça-gabarito | Chapéu feito para a cabeça do desenho do Codex, aplicado em outras cabeças (outros rostos e raças) | Chapéu que não senta na cabeça |
| Peças da mesma "família" | Elfo vestindo roupa do humano e anão a do ogro | Funciona pela metade, porque as cabeças são diferentes |

**Não é um problema de ajuste fino. É o método.** Por mais que eu acerte números, a roupa nunca vai encaixar perfeitamente desse jeito.

## Como podemos fazer (as opções)

### Opção A: gabarito + roupa desenhada em cima (o jeito do Stardew). Recomendada
1. O **boneco base que já temos vira o gabarito**, em pixel art, um por raça e vista. Os pontos de encaixe (pescoço, topo da cabeça e rosto) ficam marcados uma vez só.
2. **A cabeça é separada em careca + cabelo.** Pedimos ao Codex a cabeça careca de cada raça e os cabelos como peças à parte. Cada cabelo também ganha uma **versão curta, para chapéu**.
3. **A roupa é pedida desenhada EM CIMA da imagem do gabarito.** O pedido manda a própria imagem do boneco base ampliada, com grade, e diz para "vestir este boneco sem mexer no corpo". O programa compara com o gabarito e recorta só o que mudou: aquilo é a roupa, já no lugar certo.
4. **Conferência automática:** se o Codex mexeu no corpo (outro tamanho, outra posição), a folha é recusada e pedida de novo. Nada entra torto.
5. Cada chapéu entra com a regra do cabelo: **mostrar**, **curto** ou **esconder**, como no Stardew.

**Custo:** refazer as roupas (6 classes x 3 vistas) e separar os cabelos, mais uma ferramenta nova de "diferença". O encaixe passa a ser exato.
**Risco:** o Codex pode não respeitar o gabarito, mas a conferência pega isso.

### Opção B: personagem inteiro por raça e classe (o jeito do Forager)
- Sem roupa trocável. Cada combinação (raça x classe) é um desenho completo nas 3 vistas.
- **Vantagem:** sempre bonito, porque não há encaixe.
- **Desvantagem:** some a miniatura com roupas da mochila e a roupinha branca. São 4 raças x 5 classes = 20 personagens x 3 vistas, e toda roupa nova no futuro vira 20 desenhos.

### Opção C: meio-termo
- O **corpo** com a roupa é inteiro por classe (sem trocar), e só o **chapéu** e a **arma** são trocáveis, com a regra do cabelo da Opção A.
- Menos peças do que na A e ainda dá para tirar o chapéu, mas não dá para tirar a roupa do corpo.

## Minha recomendação

**Opção A, começando por um piloto pequeno antes de refazer tudo:** só o humano, com 2 cabelos e 2 roupas (mago e arqueiro, as que ficaram piores), nas 3 vistas. Se o piloto encaixar perfeito, aplicamos às outras raças e classes. Se o Codex não conseguir respeitar o gabarito, partimos para a C.

**O que você precisa decidir:** A, B ou C; e, se for a A, se posso começar pelo piloto.

## Resultado do piloto (01/11/2026, opção A)

- O Codex vestiu o gabarito sem mover o boneco: deslocamento zero nas 3 vistas, nas duas roupas (`art/sprites/tiny/gabarito/`, pedido L26).
- A ferramenta `game/tools/vestir_gabarito.gd` recorta a roupa pela diferença:
  - a camada do corpo e a camada do chapéu (o chapéu nunca leva pele nem o rosto);
  - a máscara da cabeça, que esconde o cabelo que sairia do chapéu, para qualquer rosto.
- O boneco (`boneco.gd`) usa a roupa do gabarito quando existe a pasta `<classe>_g`; senão, usa a antiga.
- Conferência: `evidence/comparacao/gabarito_mago.png` e `gabarito_arqueiro.png`. Print no jogo: `evidence/novidades/customizacao.png`.
- **Falta:** passar as outras roupas (guerreiro, ladino, clérigo) e as outras raças pelo mesmo caminho, depois que o João aprovar o piloto.
