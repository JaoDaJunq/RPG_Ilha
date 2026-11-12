# Processo de arte v2 (30/10/2026)

O João tem razão: a IA consegue fazer a arte do jogo, porque no Smash Junq ela faz. Este processo copia o que funciona lá e corrige o que fizemos diferente aqui.

## O que medimos

`importar_folha.gd` agora mostra a **nitidez da grade**: quanto de cada "pixel" desenhado é de uma cor só.

| Imagem | Nitidez |
|---|---|
| Sprite final do Smash Junq (Juba, já convertido) | 100% |
| Saídas cruas do Codex no Smash Junq (Arara-Canga) | 30–53% |
| Nossas folhas (árvore L01, personagens L03, piloto L08) | 46–54% |

Conclusão: **a IA crua é igual nos dois projetos.** A diferença está no que fazemos antes e depois dela.

## O que o Smash Junq faz e nós não fazíamos

1. **Sprites maiores, mostrados menores.**
   - No Smash Junq, o personagem tem de 40 a 60 px num quadro de 64x64 e aparece ampliado só 2x.
   - Aqui o personagem tinha ~28 px num quadro de 40x40, ampliado 3x. No L08 eram ~20 px ampliados 4x.
   - Com poucos pixels, cada erro da IA vira um borrão visível: olho torto, contorno quebrado.
2. **Grade exata e conhecida.**
   - Eles pedem "64x64 ampliado EXATAMENTE 8x" (ou 128x128 em 4x).
   - Nós deixávamos a IA escolher e a ferramenta adivinhava (6,6 px, 12,45 px...).
3. **Régua anexada em TODO pedido.**
   - Os mesmos dois sprites aprovados (Juba e Seu Capivas) vão em todas as folhas de todos os personagens.
   - Isso segura o nível de detalhe e o tamanho do pixel.
4. **Parágrafo LIMPEZA em todo pedido.**
   - "NÃO desenhe ilustração detalhada fina com cara de pixel."
   - 2-3 tons por material, contorno contínuo, rosto legível de longe.
5. **Portão da etapa A.**
   - Primeiro só o sprite base e o parado. O Claude confere, registra a paleta usada e só então pede o resto.
   - Uma base ruim não vira 50 folhas ruins.
6. **Conferência automática e revisor separado.**
   - Escala, pedaços soltos e quadros cortados são medidos.
   - Um revisor de contexto limpo, que só vê as imagens e as regras, pode barrar a entrega antes de o João ver.
7. **Pixel nítido em qualquer zoom.**
   - O shader `pixel_nitido` com filtro linear mantém os blocos quadrados mesmo quando a câmera não está num zoom inteiro.

## Regras do Ilha Viva a partir de agora

| Item | Antes | Agora |
|---|---|---|
| Personagem | quadro 40x40, ~28 px de altura | quadro **64x64**, ~46 px de altura, pedido em **8x** |
| Árvore, objeto grande | quadro 64x64 | quadro **128x128**, pedido em **4x** |
| Objeto pequeno, item | 32x32 | **64x64** em 8x |
| Zoom da câmera | 3x | **2x** (personagem continua com ~92 px na tela, com o dobro de pixels) |
| Contorno | escuro colorido | 1 px **#2A1A14** em tudo |
| Régua anexada | nenhuma fixa | `juba/parado.png` (só nitidez) + o primeiro sprite aprovado do Ilha Viva, que vira a régua própria |

**Ordem de todo lote novo:**

1. **Pedido.**
   - Usar o modelo do L09: grade exata e parágrafo LIMPEZA.
   - Anexar a régua, a direção (C02) e a identidade do personagem.
2. **Etapa A:**
   - um sprite base;
   - conferir: nitidez da grade, altura em px, cores, pixels soltos;
   - print no jogo, no zoom real.
3. **Registrar a paleta** usada na etapa A e colar nos pedidos seguintes. A conversão usa `--paleta_de`.
4. **Gerar o resto.**
   - No máximo 2 tentativas por folha.
   - Defeito de grade, escala ou sujeira se corrige com ferramenta, não com outra geração.
5. **Revisor separado** (subagente sem o histórico) olha as imagens contra as regras.
6. **Pasta de aprovações**, com print de dentro do jogo ao lado do que existe hoje.

## Referências externas indicadas pelo João (30/10)

| Pacote | O que é | Licença | Uso |
|---|---|---|---|
| [Tiny Swords](https://pixelfrog-assets.itch.io/tiny-swords) (Pixel Frog) | Versão nova em desenho de alta resolução com contorno grosso, não é pixel art | Uso comercial permitido; não pode redistribuir (versão antiga CC0) | Referência de clareza e acabamento |
| [Sprout Lands UI](https://cupnooble.itch.io/sprout-lands-ui-pack) (Cup Nooble) | Interface fofa em pixel, tons pastel | Grátis só **não comercial**; comercial no Premium (US$ 3,99) | Referência para painel e botões; usar só com o Premium |
| [Shikashi's Fantasy Icons](https://shikashipx.itch.io/shikashis-fantasy-icons-pack) | 284 ícones 32x32, inclusive **armadilha de urso**, poções, armas | Uso comercial com crédito a "Matt Firth (shikashipx)" e "game-icons.net" (CC BY 4.0) | Pode virar os ícones de verdade do jogo |

Nada disso foi baixado ainda: baixar só com o "sim" do João. O repositório não tem remoto (não é público), então guardar pacotes "sem redistribuição" nele é aceitável. Isso precisa ser revisto se um dia o código for publicado.

## Atualização (30/10): estilo Tiny Swords

O João escolheu o estilo do **Tiny Swords**. O pacote gratuito foi baixado em `art/terceiros/tiny_swords/` (uso comercial permitido, sem redistribuir).

**O que vem do pacote:**
- terreno de grama em 5 tons, com borda e espuma animada da água;
- árvores animadas, tocos, pedras, arbustos;
- ovelhas;
- unidades: guerreiro, arqueiro, monge, lanceiro e trabalhador com machado e picareta;
- fogo, poeira, explosão, respingo;
- interface: faixas, barras, botões, ícones e retratos.

**O que nós fazemos (Codex), com as unidades do pacote anexadas como régua:**
- areia, que o pacote não tem;
- os nossos personagens: raças e classes;
- o que mais faltar.

**Escala:** a arte do pacote é feita para tile de 64 px. No jogo entra com escala 0,25 e câmera em zoom 4, então 1 pixel da arte = 1 pixel da tela em 1280x720.

**Primeiro teste (L11, Mago e Ogro Arqueiro):**
- A IA desenhou com o pixel 2x maior que o do pacote. Dobrando, ficam com a mesma altura das unidades deles (88 px).
- Ainda ficam um pouco mais detalhados, saturados e com contorno preto. Os deles são mais redondinhos e dessaturados, com contorno azul-escuro e sombra oval cinza.
- Próxima versão: pedir exatamente isso.

## Diagnóstico do L12 (30/10, o João reprovou o acampamento e as pedras)

A comparação lado a lado (`evidence/comparacao/l12_atual.png`, em cima o pacote, embaixo o nosso) mostrou cinco erros:

1. **Pixel 2 a 3 vezes maior que o do pacote.** O Codex desenhou com "pixels" de ~11 px e eu ampliei a peça para o tamanho certo no jogo (escala 0,5 a 0,75). Barraca, bancada e pedras ficaram em blocos grossos ao lado do pixel fino deles. **Regra nova:** toda peça nossa entra com escala 0,25, igual ao pacote. Se o desenho não tiver o tamanho certo no pixel do pacote, volta para o Codex; não se amplia.
2. **Contorno preto e grosso.** O do pacote é uma cor só, **#161c2e**, com 1 pixel de largura.
3. **Cores fortes.** A madeira laranja e o verde saturado são nossos. O pacote tem tons apagados e frios. **Regra nova:** a conversão troca cada cor pela mais próxima da paleta do pacote (`game/assets/tiny_swords/paleta.png`, 150 cores).
4. **Sem sombra no chão.** No pacote, todo objeto tem uma elipse **#161c2e com 27% de opacidade**. A IA não sabe fazer transparência sobre magenta. **Regra nova:** o Codex NÃO desenha sombra; a conversão copia a sombra do próprio pacote para baixo da peça.
5. **Referências erradas.** Anexávamos imagens do pacote em tamanhos diferentes do pedido, e também a arte antiga, que a IA acabava copiando. **Regra nova:** anexar uma **folha-régua** (`game/tools/montar_regua.gd`): peças do pacote ampliadas EXATAMENTE 4x, na MESMA grade do pedido. A arte antiga só vai com um aviso explícito de "NÃO SIGA".

**Validação antes de pôr no jogo:** rodar `game/tools/comparar_folhas.gd`, que coloca a peça do pacote e a nossa lado a lado, no tamanho do jogo. Só entra no jogo o que passar nessa comparação, e o João vê a comparação.

## O que aprendemos com os personagens (L13, L13b, L13c)

- **A IA não desenha pixel art fino.** Pedindo pixel art, ela escolhe sozinha um desenho de ~30 a 60 pixels no total, por mais que o pedido diga "8x8" ou "4x4":
  - 6 por folha (L13): pixel 2x mais grosso que o do pacote;
  - 1 por imagem (L13b): ainda mais grosso, ~30 pixels de altura.
- **Objetos simples deram certo em 4x (L14)**, porque a medida pedida em pixels do jogo cabia no jeito dela desenhar. Mesmo assim, é preciso converter no grade do pacote (`--pixel=4`).
- **Personagens: pedir ILUSTRAÇÃO e pixelizar aqui** (`game/tools/pixelizar.gd`):
  1. a IA desenha liso, de perfil, com contorno grosso e cor chapada;
  2. a ferramenta reduz para ~88 pixels de altura e troca as cores pelas da paleta do pacote;
  3. ela pinta a borda com #161c2e e põe a sombra do pacote.

  O teste (`evidence/comparacao/teste_pixelizado.png`) ficou na densidade exata do pacote.
- O pedido de ilustração precisa de: "NÃO desenhe pixel art", "nada fino demais" (some ao reduzir) e "de perfil para a direita".

## Efeitos animados com o Pixelbolt (31/10)

O Pixelbolt (`C:\Projetos\ferramentas\pixelbolt`, licença MIT, sem dependências, roda com Node) gera efeitos animados a partir de receitas em texto, com simulação de fogo, fumaça e líquido.

- **Receitas:** em `art/fx_receitas/`, geradas por `gerar.mjs` a partir dos exemplos dele:
  - as cores são trocadas pelas do Tiny Swords (fogo: #955c3c, #cf8935, #cea554, #ffdc00, #ffffff; gelo: tons azul-esverdeados do pacote);
  - fica só a direção para a direita, porque o jogo gira o efeito;
  - a peça é aumentada na receita (`aumentar`), nunca esticando o pixel.
- **Gerar:**
  1. `node bin/pixelbolt.js compile <receita> --out <saida.json>`;
  2. `render <saida.json> --out <pasta>`;
  3. `game/tools/importar_pixelbolt.gd` converte a folha para a tira do jogo;
  4. `gif ... --scale 4` gera a prévia animada para o João ver.
- **No jogo:**
  - bola de fogo: 8 quadros;
  - lança de gelo: 8 quadros;
  - estouro de gelo, quando a lança acerta: 12 quadros.

  A explosão continua a do pacote. Comparação: `evidence/comparacao/pixelbolt_fx.png` e os GIFs `pixelbolt_*.gif`.

## Personagens por peças (L19, 31/10)

- **Estilo Forager:** cabeça, tronco, dois pezinhos e duas mãozinhas soltas; o item da barra vai na mão da frente. O jogo monta e anima as peças (`game/scripts/player/boneco.gd`), sempre em pixels inteiros da arte.
- **Pedido:** uma folha por personagem, em ilustração.
  - Célula 0: o personagem MONTADO, sem arma.
  - Células 1 a 4: cabeça, tronco, pé e mão.
- **A IA erra o tamanho das peças** (o pé do ogro veio quase 2x maior). Por isso `game/tools/montar_pecas.gd` não confia no tamanho:
  1. acha cada peça dentro do personagem montado, testando escalas e posições;
  2. assim descobre a escala e o lugar certos de cada uma;
  3. pega a mancha inteira mesmo quando a IA passa da linha da célula.
- **Saída:** em `game/assets/sprites/tiny/bonecos/<raca>_<classe>/` ficam:
  - as peças (`cabeca`, `tronco`, `pe`, `mao`);
  - `sombra.png`;
  - `inteiro.png`;
  - `pecas.json`, com o lugar de cada peça.
- **Conferência:** `game/tools/previa_bonecos.gd` põe o boneco montado pelas peças ao lado do personagem inteiro (`evidence/comparacao/bonecos.png`). Tem de ficar igual.

## Sprite completo por raça e classe (12/11/2026, substitui as peças)

Com o personagem reduzido a raça + classe, não há mais o que trocar. Por isso, cada um dos 20 personagens volta a ser **desenhado inteiro em cada quadro**, como no L15, que já tinha dado certo para o perfil. Agora são as 3 vistas e sem a arma na mão.

**3 folhas por personagem** (uma por vista: perfil, frente, costas), cada uma com 6 quadros:
- parado, respirando;
- passo A, passo B;
- golpe preparação, golpe ataque.

**Desenho:**
- Ilustração lisa, contorno #161c2e grosso, cel shading de um tom.
- Proporções do Tiny Swords, roupa sem mangas compridas.
- Mão da frente fechada e vazia.

**Conversão:** `game/tools/pixelizar.gd --animacao` (escala do 1º quadro e pés na mesma linha). O resultado vai para `game/assets/sprites/tiny/personagens/<raca>_<classe>/<vista>.png`, uma tira de 6 quadros.

**No jogo:**
- O jogo troca o quadro conforme a ação (parado, andando, golpe) e a vista.
- Um arquivo de pontos marca onde fica a mão da frente em cada quadro. O item da barra é desenhado ali e gira no golpe.

**Pedidos:** L30 é o piloto (Humano Guerreiro). Depois que o João aprovar, vêm os outros 19.
