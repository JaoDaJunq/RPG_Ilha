# Backlog

Lista oficial de tarefas. Marcar `[x]` só com prova (teste OK ou print revisado). Cada etapa termina com aprovação do João.

## Etapa 0: fundação (em andamento)

- [x] T01 Repositório, AGENTS.md, GDD, backlog, bíblia visual (rascunho), manifesto de assets.
- [x] T02 Projeto Godot com o Input Map (WASD, E, clique, 1–6, N, M) e pixels nítidos.
- [x] T03 Componentes: vida, interagível, inflamável, saque e inventário.
- [x] T04 Cenas: jogador com câmera, árvore, pedra, slime, bola de fogo, mundo e HUD (com placeholders CC0).
- [x] T05 Testes de fumaça headless + script `rodar_testes.sh` + print dentro do jogo.
- [ ] T06 Conceito visual feito pelo Codex e aprovado pelo João (`art/prompts/pedidos/C01_conceito_visual.md`).

## Etapa 1: multiplayer desde já

- [ ] T10 Menu simples: Hospedar / Entrar (IP) / Solo.
- [ ] T11 ENet com anfitrião autoritativo: spawn dos jogadores, cada um com a sua câmera.
- [ ] T12 Sincronizar movimento (MultiplayerSynchronizer) e as ações no mundo (interagir, lançar, dano) via RPC validada pelo anfitrião.
- [ ] T13 Teste em duas janelas + teste automático de host/cliente na mesma máquina.
- [ ] T14 Guia para jogar pela internet com Tailscale/ZeroTier.

## Etapa 2: fatia jogável em rede

- [ ] T20 Inventário de verdade (slots, empilhar) e hotbar.
- [ ] T21 Fabricação básica (bancada, receitas como dados `.tres`).
- [ ] T22 Construção (paredes, chão, porta) com prévia e custo.
- [ ] T23 Inimigos com estados (patrulhar, perseguir, atacar) e saque.
- [ ] T24 Dia e noite com perigo maior à noite; luz de fogueira e tocha.
- [ ] T25 Salvar e carregar o mundo (no anfitrião).

## Etapa 3: classes e habilidades

- [ ] T30 Barra de 6 habilidades com modos de conjuração (rápido, indicador, imediato).
- [ ] T31 Primeira árvore de habilidades (uma afinidade) com pontos limitados.
- [ ] T32 Segunda afinidade e teste de grupo misto.

## Etapa 4: a ilha cresce

- [ ] T40 Mapa maior com 2–3 biomas.
- [ ] T41 Primeiro boss guardião.
- [ ] T42 Ruína ou caverna com segredo.

## Arte (contínuo, pelo Codex)

- [ ] A01 Conceito visual (T06) → bíblia visual aprovada.
- [ ] A02 Tileset da clareira (grama, terra, areia, água) no padrão aprovado.
- [ ] A03 Personagem provisório próprio (4 direções: parado, andar, atacar, coletar).
- [ ] A04 Árvore (inteira, sendo cortada, toco, queimada), pedra, slime.
- [ ] A05 Efeitos: bola de fogo, chamas na árvore, acerto.
