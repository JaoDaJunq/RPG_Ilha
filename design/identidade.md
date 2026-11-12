# Identidade visual (bíblia)

> **Personagens (12/11/2026): SPRITE COMPLETO por raça e classe.** Cada um dos 20 personagens (Humano, Ogro, Elfo, Anão x Guerreiro, Mago, Arqueiro, Ladino, Clérigo) é desenhado inteiro em cada quadro, como as unidades do Tiny Swords. Regras:
> - **Corpo inteiro:** corpo, roupa da classe, rosto e cabelo da raça desenhados juntos, com bracinhos de verdade. Saem as mãozinhas soltas e as peças montadas.
> - **Proporções do Tiny Swords:** cabeça grande e redonda, corpo curto e roliço, pernas curtas.
> - **Roupas sem mangas compridas:** colete ou túnica com cavas, como o João pediu.
> - **3 vistas:** perfil olhando para a direita (a esquerda é o espelho), frente e costas.
> - **Animações em cada vista:**
>   1. parado;
>   2. respirando;
>   3. passo A;
>   4. passo B;
>   5. golpe (preparação);
>   6. golpe (ataque).
> - **Mão da frente fechada e vazia:** o item da barra (arma da classe, machado, picareta, tocha...) é desenhado pelo jogo nessa mão, num ponto marcado em cada quadro (`design/armas_na_mao.md`, jeito 2).
> - **Mesmo processo do L15:** o Codex faz ilustração lisa; `game/tools/pixelizar.gd --animacao` transforma em pixel art, na densidade, na paleta e com o contorno do pacote, sempre com a mesma escala e os pés na mesma linha.
> - **Entrada no jogo:** escala 0,25, como as unidades do pacote.
>
> Isso substitui o "personagem montado por peças" (L19, L21, L29). Piloto: Humano Guerreiro (pedido L30).

> **Direção atual (30/10/2026): estilo Tiny Swords.** O João escolheu o estilo do pacote Tiny Swords (Pixel Frog): terreno, árvores, pedras, arbustos, animais, efeitos e interface vêm do pacote; os nossos personagens e o que faltar (areia, ogro, classes próprias) são feitos pelo Codex com as unidades do pacote anexadas como régua. Escala: arte de 64 px por tile, entra no jogo com escala 0,25 e câmera em zoom 4 (1 pixel da arte = 1 pixel da tela). Ver `design/processo_arte.md`. A direção C02 abaixo fica como histórico.
>
> **Direção anterior (histórico) — C02, aprovada pelo João em 29/10/2026:** **pixel art mais fina**, conforme `art/conceitos/estilo/estilo_pixel_fino_v1.png`. O João acrescentou **Forager** e **Moonlighter (o primeiro, em 2D)** como referências. A alternativa de desenho liso não foi escolhida.
>
> Continuam valendo as cores e o clima aprovados no **C01**: conceito **B = dia** (`art/conceitos/mundo/clareira_b_v1.png`), conceito **A = noite** (`art/conceitos/mundo/clareira_a_v1.png`). Os nomes A/B de C01 e C02 são independentes. Novos pedidos anexam o C02 aprovado e as referências de dia/noite do C01.
>
> C02 aprova a direção visual de uma tela conceitual. A conversão em sprites, a escala na tela e a interface ainda precisam ser verificadas dentro do jogo. A imagem não é uma captura da versão jogável.

## Como aplicar as referências

Interpretação de produção a partir das referências indicadas pelo João:

| Referência | Aplicação no Ilha Viva |
|---|---|
| **Moonlighter** | Referência principal para acabamento: personagens expressivos, volumes legíveis, materiais distintos, animação de ações e contraste entre luz quente e ambiente frio. Concentrar detalhe no personagem, nos objetos importantes e nas construções. |
| **Forager** | Referência de clareza: árvores, minérios, recursos e construções reconhecíveis de relance; chão com áreas tranquilas para destacar o que pode ser coletado ou atacado. A leitura precisa continuar fácil com vários amigos e efeitos na tela. |
| **C01 + C02 próprios** | Manter a identidade da ilha: verdes vivos, água turquesa, flores rosas, fantasia e acampamento acolhedor; usar pixels menores e formas limpas. |

Fontes consultadas em 29/10/2026: [Forager — página oficial na Steam](https://store.steampowered.com/app/751780/Forager/) e [Moonlighter — Digital Sun](https://digitalsungames.com/games/moonlighter/). São referências de direção, sem importação dos seus sprites. A indicação desses jogos não acrescenta automaticamente sistemas de loja, compra de ilhas ou automação ao escopo.

### Tradução para o próximo lote

- **Pixel fino e nítido:** detalhe suficiente para rosto, roupa e arma se distinguirem; contorno colorido fino e grupos de cor bem definidos. Suavidade vem das formas e da resolução da arte.
- **Cenário legível:** reduzir textura repetitiva na grama, reservar flores e folhagem para grupos e bordas, preservar caminhos e áreas de combate. A densidade de detalhes do mockup não é uma obrigação.
- **Terreno orgânico:** curvas amplas entre grama, terra, areia e água, sem a aparência de blocos grandes isolados; bordas coerentes com a grade de pixels adotada.
- **Personagens:** manter as identidades de raça e classe já alinhadas. No Ogro Arqueiro, capuz marrom separado da pele verde e presas legíveis como presas.
- **Interface:** ícones reconhecíveis no tamanho final, bom contraste e painéis compactos. Texto e números são renderizados pelo Godot; a barra ilustrativa do C02 não redefine as habilidades de nenhuma classe.
- **Primeiro passo de produção:** um lote piloto com Humano Mago, Ogro Arqueiro, árvore, pedra e trecho de terreno, comparado ao visual atual na mesma área de jogo. Só então consolidar a nova escala e expandir para as outras animações e assets.
- **Escala ainda a validar:** resolver resolução de origem, escala dos sprites e câmera em conjunto, preservando proporções e área visível. Conferir encaixe dos pés, colisões e nitidez em captura nativa. Não reduzir automaticamente os novos personagens para 32 × 32, nem assumir que duplicar a resolução sozinho resolve o acabamento.

## Sensação

Uma ilha de fantasia **viva, colorida e convidativa de dia**, que fica **misteriosa e aconchegante à noite**. Personagens pequenos num mundo grande e cheio de detalhe. Ruínas antigas cobertas de musgo sugerem segredos.

- **Dia (B):** sol filtrado pelas copas, verdes amarelados e saturados, água turquesa, árvores de flor rosa, flores e frutas coloridas. Alegre sem ficar infantil.
- **Noite (A):** sombras azul-arroxeadas frias e luz quente de fogueira e magia. Cogumelos que brilham em azul-esverdeado, slimes verdes translúcidos. **A noite é feita pelo jogo** (escurecer + luzes), não por sprites diferentes: os sprites são desenhados de dia.

## Padrão técnico anterior (L01–L06; base de comparação)

Esta tabela registra a implementação anterior ao C02. Tamanhos e zoom **não são requisitos definitivos para a nova arte fina**. Visão em 3/4, coerência de luz e identidade dos personagens continuam como orientação; o lote piloto deve definir os novos tamanhos com evidência dentro do jogo.

| Item | Padrão |
|---|---|
| Perspectiva | Visão de cima em 3/4: vê o topo e a frente das coisas |
| Tile do chão | 16 × 16 px |
| Personagem | Quadro de 32 × 32 px, personagem com cerca de 28 px de altura (pés na linha 30) |
| Proporção | Chibi: cabeça grande (≈ 40% da altura), olhos grandes, corpo curto, silhueta clara |
| Árvore grande | Quadro de 64 × 64 px (copa larga; o tronco toca o chão no centro de baixo) |
| Pedra, arbusto, objeto pequeno | Quadro de 32 × 32 px |
| Contorno | 1 px, escuro e colorido (marrom-escuro ou verde-escuro, nunca preto puro) |
| Sombreamento | 2–3 tons por material, luz vindo de cima-esquerda |
| Direções | Personagens e criaturas: baixo, cima e direita (a esquerda é espelho da direita) |
| No jogo | Zoom inteiro (3×), sem filtro: pixels nítidos |

## Paleta (âncoras tiradas dos conceitos)

| Grupo | Cores |
|---|---|
| Grama de dia | `#B0D050` `#90B030` `#709030` `#507030` |
| Folhagem e sombra verde | `#509050` `#307050` `#305030` `#105030` |
| Pedra e ruína | `#707070` `#505050` `#303030` (+ musgo `#709030`) |
| Areia e terra | `#E8D08A` `#C8A060` `#8A6038` |
| Água | `#40C8D8` `#2090B0` (espuma `#E8F8F8`) |
| Flores e acentos | rosa `#E890B0`, vermelho `#D04040`, azul `#5070D0`, amarelo `#F0D040` |
| Noite (feita pelo jogo) | sombra `#101030` `#103050` `#303050`; luz `#F0A040`; brilho mágico `#40E0D0` |

## Regras de produção (valem para todo sprite)

- Cada folha tem **só o objeto ou personagem**. Nada de chão, sombra projetada, rastro, poeira, faísca ou brilho (o jogo faz os efeitos e a luz).
- **Todo estado tem a sua imagem** (árvore inteira, com marcas de machado, queimada, toco).
- O mesmo personagem tem o mesmo tamanho, cores e contorno em todas as folhas.
- Fundo magenta chapado `#FF00FF` nas folhas; o Claude troca por transparente.
- Nada parecido com personagem ou marca famosa.
- Aprovação só depois de ver o sprite **dentro do jogo**, ao lado dos outros, no zoom real.
- **Paleta curta e sem pixels soltos.** A IA pode entregar centenas de tons por sprite. O fluxo anterior usa `--cores` e `--limpar` (ver `game/tools/medir_ruido.gd`), com meta de até ~16 cores por quadro e menos de 10% de pixels soltos. Para o C02, comparar antes/depois no tamanho de exibição: a limpeza não pode apagar olhos, presas, mãos e contorno. As métricas ajudam a encontrar ruído, mas não substituem a avaliação visual.

## Lições do primeiro lote (L01)

- A IA não respeita a ampliação pedida: a árvore veio certinha (8x), a pedra com "pixel" de ~10 px e o aventureiro de ~6,6 px (o dobro da resolução pedida). A ferramenta `game/tools/importar_folha.gd` mede o tamanho real sozinha; quando vem fino demais, reduz pela metade (`--pixel` e `--escuro`), o que perde detalhe no rosto.
- No fluxo L01, usou-se o aventureiro convertido como referência de tamanho. **A partir do C02, a referência de acabamento é o conceito de pixel fino aprovado.** Os sprites antigos servem para preservar roupa, cores e identidade, sem obrigar a mesma resolução baixa.

## Histórico dos placeholders (L01)

O primeiro lote usava **Ninja Adventure** (Pixel-boy e AAA, CC0) para chão, plantinhas, barraca, fogueira, slime, ícones e sons. L02–L06 já substituíram parte desses elementos. Consultar `assets/manifest.csv` e `design/backlog.md` para o estado atual; a aprovação de C02 orienta a próxima revisão visual.
