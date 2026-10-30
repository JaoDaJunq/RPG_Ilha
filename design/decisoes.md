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

## Em aberto (o João decide)

- **Nome do jogo.** Opções levantadas: Emberwild, Mossborne, Brasa & Musgo, Ilha Errante, Wildmere, Verdeluz.

## Problemas conhecidos

- Ao fechar o jogo, o Godot avisa "2 resources still in use at exit" (a música OGG que estava tocando). Não afeta o jogo; parar a música no `_exit_tree` e trocar `preload` por `load` não resolveram (29/10/2026). Investigar de novo quando houver menu e saída pelo jogo.
