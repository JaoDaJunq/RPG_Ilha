# Decisões e perguntas em aberto

## Decididas

| Data | Decisão |
|---|---|
| 28/10/2026 | Godot, 2D com visão de cima, co-op online para amigos. |
| 28/10/2026 | Classes de fantasia como foco da progressão (não profissões). |
| 29/10/2026 | O protótipo do Codex (`Documents\Codex\2026-10-28\se\outputs\ilha-fantasia`) fica só como referência; a base é refeita em cenas e componentes. |
| 29/10/2026 | Repositório em `C:\projetos\ilha_viva`, seguindo o processo do Smash Junq (AGENTS.md, pedidos de arte ao Codex, manifesto, testes headless). |
| 29/10/2026 | Placeholders só do pacote **Ninja Adventure (CC0)**, para não misturar estilos enquanto a arte própria não chega. |
| 29/10/2026 | Árvore queimada vira **tronco queimado** que rende **carvão** em vez de madeira (consequência previsível do fogo). |
| 29/10/2026 | Direção de arte aprovada: conceito **B = dia** e conceito **A = noite** da mesma ilha (a noite é feita pelo jogo com luz, não com sprites diferentes). |
| 29/10/2026 | Multiplayer: um jogador é o anfitrião e manda no mundo; cada jogador controla o próprio movimento. Coletar, golpear, lançar e dia/noite são pedidos que o anfitrião confere. Modo solo usa o mesmo código. |
| 29/10/2026 | Uma classe por personagem (troca na fogueira, pagando material raro). Esquiva no Espaço para todos. Fogo se espalha para árvores vizinhas, mas devagar. |
| 29/10/2026 | Criação de personagem com raça + classe + atributos (Força, Vitalidade, Agilidade…); raças dão vantagens e desvantagens sem proibir combinações. Proposta detalhada em `design/classes.md`. |
| 29/10/2026 | Proposta v2 de personagem aprovada: 5 raças, 7 classes em 4 famílias, 5 atributos, reações entre elementos e arte em camadas (`design/classes.md`). |
| 29/10/2026 | **C02: João escolheu pixel art mais fina** (`art/conceitos/estilo/estilo_pixel_fino_v1.png`) e acrescentou **Forager e Moonlighter** como inspiração. Preservar cores e clima do C01. Direção registrada em `design/identidade.md`; a escala dos sprites e a tradução para o jogo serão validadas num lote piloto. Aprovação de estilo, sem mudança de mecânicas ou aprovação automática de L05/L06. |
| 30/10/2026 | **Estilo Tiny Swords.** Depois dos pilotos L08 (simples), L09 (pixel v2) e L10 (desenho HD), o João escolheu o estilo do pacote Tiny Swords (Pixel Frog) e pediu para usar os assets dele onde der e criar os nossos com base neles. Pacote gratuito baixado em `art/terceiros/tiny_swords/` (uso comercial permitido, sem redistribuir). Piloto no jogo: `tests/piloto_tiny.tscn`. Processo em `design/processo_arte.md`. |
| 31/10/2026 | **Pixelbolt para efeitos.** O João achou o Pixelbolt (ferramenta MIT que gera pixel art e animação a partir de receitas em texto, com simulação de fogo, fumaça e líquido) e autorizou o teste. Efeitos animados (bola de fogo, lança de gelo, estouro de gelo) feitos com ele, nas cores do Tiny Swords, comparados com o pacote e postos no jogo. Exceção à regra "arte nunca por código", só para efeitos. A explosão continua a do pacote. |

| 01/11/2026 | **Personagem com arte COMPLETA por raça e classe (desiste das roupas trocáveis).** Foram testados três jeitos de vestir o boneco: roupa desenhada à parte e encaixada (L24/L25), roupa recortada de um boneco vestido (L26) e peças separadas em cima de um boneco careca (L27). Nenhum ficou bom o bastante para o João. Agora cada combinação raça x classe é um personagem inteiro, desenhado pelo Codex nas 3 vistas (perfil, frente, costas), montado por peças como no L19/L21 (cabeça, tronco, pés, mãos). São mais desenhos, mas sempre ficam bonitos. A pesquisa e os testes ficam em `design/pesquisa_roupas.md`. Daqui em diante o João também usa o Codex para programar (guia: `design/guia_codex.md`). |
| 12/11/2026 | **Novo conceito de arte do personagem: SPRITE COMPLETO.** Como agora o personagem é só raça + classe (sem roupas, cabelos ou rostos trocáveis), cada um dos 20 personagens (4 raças x 5 classes) passa a ser desenhado INTEIRO em cada quadro da animação, como as unidades do Tiny Swords: corpo, roupa, rosto e cabelo juntos, com bracinhos de verdade (sem as mãozinhas soltas do Forager). Animações em 3 vistas (perfil, frente, costas; a esquerda é o perfil espelhado): parado, respirando, 2 passos e golpe (preparação e ataque). A mão da frente fica fechada e vazia: o item da barra (arma da classe, machado, tocha...) é desenhado pelo jogo nessa mão, num ponto marcado por quadro (jeito 2 de `design/armas_na_mao.md`). Substitui o "montado por peças" de 01/11 (L19, L21, L29). Piloto: Humano Guerreiro (pedido L30). |

| 13/11/2026 | **Mundo maior aprovado** (`design/proposta_mundo.md`): "não precisa ter dó, quero tudo funcionando e bem bonitinho". Etapa 1 feita (L36): ilha de 190 x 130 blocos com semente fixa nova (36036), 6 regiões, rio que separa o norte com duas passagens (ponte e raízes, abertas até a etapa 3), bichos por região, "só ativo perto" e mapa na tecla M. O som foi da tecla M para a P. Mundo salvo da ilha antiga começa de novo, com aviso. |
| 13/11/2026 | **Emendas do terreno refeitas e fogueira nova (L41, aguardando o João).** As bordas entre os chãos passam a ser montadas em quartos de bloco, com canto de dentro arredondado, contorno da cor do próprio chão (o azul-escuro só na beira da água), textura grande no miolo (a lama não se repete mais) e tufos e pedacinhos nas emendas. A fogueira é um desenho só, do zero (pedras, lenha e chamas juntas, 6 quadros); a de remendo do L37 saiu, junto com as faíscas do Pixelbolt. Detalhes em `design/processo_arte.md`. |

## Em aberto (o João decide)

- **Nome do jogo.** Opções levantadas: Emberwild, Mossborne, Brasa & Musgo, Ilha Errante, Wildmere, Verdeluz.

## Problemas conhecidos

- Ao fechar o jogo, o Godot avisa "2 resources still in use at exit" (a música OGG que estava tocando). Não afeta o jogo; parar a música no `_exit_tree` e trocar `preload` por `load` não resolveram (29/10/2026). Investigar de novo quando houver menu e saída pelo jogo.
