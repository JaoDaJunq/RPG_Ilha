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
