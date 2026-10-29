# Ilha Viva (nome provisório)

Co-op online de sobrevivência e exploração numa ilha de fantasia que reage ao que o grupo faz. Godot 4.7.2, 2D com visão de cima. Visão completa em [design/gdd.md](design/gdd.md).

## Estado

**Etapa 0 (fundação) quase concluída.** A base do jogo foi refeita em cenas e componentes, com placeholders CC0 do Ninja Adventure. Falta o João aprovar a direção de arte (conceitos em `art/conceitos/mundo/`). Próximo passo: multiplayer (Etapa 1). Tarefas em [design/backlog.md](design/backlog.md).

**O que já funciona (solo):**
- Ilha gerada (sempre a mesma), com água que bloqueia, areia, grama, árvores, pedras, plantas e slimes.
- Acampamento com fogueira e barraca; a fogueira ilumina à noite.
- Mouse seleciona o objeto; a caixa em cima dele diz o que fazer e se está perto o bastante.
- Segurar E corta árvore (3 golpes = 3 de madeira, vira toco) e minera pedra (4 golpes = 3 de pedra, some).
- Bola de fogo (tecla 1): acerta slime (2 de dano) e incendeia árvore; a árvore queimada rende **carvão** em vez de madeira.
- Golpe com clique esquerdo; slimes perseguem e machucam; ao desmaiar, o jogador volta ao acampamento.
- N alterna dia e noite; M liga/desliga o som.

**Ainda não tem:** multiplayer, salvar, inventário com slots, fabricação, construção, classes e árvore de habilidades, arte própria.

## Como rodar

1. Abra o Godot 4.7.2, clique em **Importar** e escolha `game/project.godot`.
2. Aperte **F5**.

| Ação | Tecla |
|---|---|
| Andar | WASD ou setas |
| Coletar (segurar) | E, com o mouse em cima do objeto |
| Golpear | Clique esquerdo (na direção do mouse) |
| Bola de fogo | 1 (na direção do mouse) |
| Dia / noite | N |
| Som | M |

## Testes

Da raiz do repositório (rodam sem janela):

```bash
bash game/tools/rodar_testes.sh
```

Roda todas as cenas `game/tests/*_smoke.tscn` (coleta, fogo, combate e mundo) e termina com `BATERIA: tudo OK`.

Prints de dentro do jogo (abre uma janela por alguns segundos e salva em `evidence/fundacao/`):

```bash
"$LOCALAPPDATA/Programs/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe" --path game --resolution 1280x720 res://tests/prints_jogo.tscn
```

Se mudar os controles em `game/tools/configure_input_map.gd`, regrave o `project.godot`:

```bash
"$LOCALAPPDATA/Programs/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe" --headless --path game --script res://tools/configure_input_map.gd
```

## Organização

```text
AGENTS.md            regras para os agentes (Claude Code e Codex)
design/              GDD, backlog, bíblia visual, decisões
art/prompts/         pedidos de arte para o Codex (padrão técnico no README)
art/conceitos/       imagens de conceito (não vão para o jogo)
assets/manifest.csv  origem e licença de cada asset
evidence/            prints e provas das entregas
game/
  autoload/          Events (sinais globais) e Sfx (som)
  scripts/components vida, inventário, área de acerto, área de interação, inflamável
  scripts/…          jogador, mundo, recursos, slime, bola de fogo, HUD
  scenes/            cenas de cada coisa (jogador, árvore, pedra, slime, bola de fogo, mundo)
  data/items/        itens como dados (.tres)
  tests/             testes de fumaça e prints
  tools/             scripts de apoio (controles, bateria de testes)
```

## Como as coisas conversam

Cada objeto do mundo é montado com **componentes**. A bola de fogo não sabe o que é árvore: ela entrega "1 de dano de fogo" para a área de acerto (`Hurtbox`) do que tocar. Quem recebe decide: o slime perde vida, a árvore (que tem `Flammable`) pega fogo e passa a render carvão. Uma criatura ou objeto novo reage às habilidades só por ter esses componentes.

## Assets

Placeholders: **Ninja Adventure** (Pixel-boy e AAA, CC0), escolhido por ser de um estilo só. A arte final vai ser própria, gerada pelo Codex a partir da bíblia visual. Tudo está em `assets/manifest.csv`.
