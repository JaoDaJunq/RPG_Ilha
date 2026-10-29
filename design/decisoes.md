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

## Em aberto (o João decide)

- **Nome do jogo.** Opções levantadas: Emberwild, Mossborne, Brasa & Musgo, Ilha Errante, Wildmere, Verdeluz.
- **Direção de arte final** (depende do conceito C01): tamanho do tile (16 px?), tamanho do personagem e paleta.
- **Classes, raças e atributos:** proposta v2 em `design/classes.md` aguardando o João (lista de classes, raças, atributos e ordem de construção).
- **Como os amigos vão se conectar pela internet** no começo (Tailscale, ZeroTier, Radmin VPN ou abrir porta).

## Problemas conhecidos

- Ao fechar o jogo, o Godot avisa "2 resources still in use at exit" (a música OGG que estava tocando). Não afeta o jogo; parar a música no `_exit_tree` e trocar `preload` por `load` não resolveram (29/10/2026). Investigar de novo quando houver menu e saída pelo jogo.
