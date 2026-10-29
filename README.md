# Ilha Viva (nome provisório)

Co-op online de sobrevivência e exploração numa ilha de fantasia que reage ao que o grupo faz. Godot 4.7.2, 2D com visão de cima. Visão completa em [design/gdd.md](design/gdd.md).

## Estado

**Etapas 0 e 1 concluídas; Etapa 3 (personagem e classes) em andamento.** A base do jogo está em cenas e componentes, com placeholders CC0 do Ninja Adventure. A direção de arte foi aprovada (B = dia, A = noite) e o primeiro lote de sprites próprios espera aprovação. Tarefas em [design/backlog.md](design/backlog.md).

**O que já funciona (sozinho ou com amigos):**
- Criação de personagem no menu: raça (Humano ou Ogro) e classe (Guerreiro, Mago ou Arqueiro), com atributos que mudam vida, mana, velocidade, dano e coleta. Ficha na tecla C.
- Habilidades da classe nas teclas 1 e 2 (Investida e Giro; Bola de fogo e Lança de gelo; Tiro carregado e Armadilha), com mana e recarga, e esquiva no Espaço.
- Reações: gelo congela (e um golpe estilhaça com dano dobrado), lança de gelo sobre a água vira ponte que derrete, fogo passa devagar para árvores vizinhas.
- Menu: jogar sozinho, hospedar ou entrar pelo IP do anfitrião (até 4 jogadores).
- Multiplayer: cada um com a sua câmera; o anfitrião cuida do mundo (árvores, slimes, dano, inventário, dia e noite) e quem entra depois vê o que já mudou.
- Ilha gerada (sempre a mesma), com água que bloqueia, areia, grama, árvores, pedras, plantas e slimes.
- Acampamento com fogueira e barraca; a fogueira ilumina à noite.
- Mouse seleciona o objeto; a caixa em cima dele diz o que fazer e se está perto o bastante.
- Segurar E corta árvore (3 golpes = 3 de madeira, vira toco) e minera pedra (4 golpes = 3 de pedra, some).
- Bola de fogo (Mago): acerta slime (dano dobrado) e incendeia árvore; a árvore queimada rende **carvão** em vez de madeira.
- Golpe com clique esquerdo; slimes perseguem e machucam; ao desmaiar, o jogador volta ao acampamento.
- N alterna dia e noite; M liga/desliga o som.

**Ainda não tem:** guia para jogar pela internet (fora da mesma rede), salvar, inventário com slots, fabricação, construção, classes e árvore de habilidades, arte própria do chão, do acampamento, do slime e dos efeitos (o aventureiro, as árvores e as pedras já são próprios).

## Como rodar

1. Abra o Godot 4.7.2, clique em **Importar** e escolha `game/project.godot`.
2. Aperte **F5** e escolha no menu.

**Jogar com amigos na mesma rede (casa, Wi-Fi):** um clica em **Hospedar para amigos**; o menu mostra o IP dele (ex.: 192.168.0.10). Os outros digitam esse IP e clicam em **Entrar**. Pela internet ainda precisa de um programa como Tailscale ou ZeroTier (guia na T14).

Atalhos para testar sem o menu: `-- --solo`, `-- --hospedar` ou `-- --entrar=IP` no fim do comando do Godot.

| Ação | Tecla |
|---|---|
| Andar | WASD ou setas |
| Coletar (segurar) | E, com o mouse em cima do objeto |
| Golpear | Clique esquerdo (na direção do mouse) |
| Esquivar | Espaço |
| Habilidades da classe | 1 e 2 (Tiro carregado: segure e solte) |
| Ficha do personagem | C |
| Dia / noite | N |
| Som | M |

## Testes

Da raiz do repositório (rodam sem janela):

```bash
bash game/tools/rodar_testes.sh
```

Roda todas as cenas `game/tests/*_smoke.tscn` (coleta, fogo, combate, mundo, personagem, guerreiro, mago, arqueiro e rede) e termina com `BATERIA: tudo OK`. O teste de rede abre um segundo Godot que entra pelo 127.0.0.1, corta uma árvore e anda; os dois lados são conferidos.

Prints das duas janelas em rede (salva em `evidence/rede/`):

```bash
"$LOCALAPPDATA/Programs/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe" --path game --resolution 960x540 --position 0,60 res://tests/rede_smoke.tscn -- --com-prints
```

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
  autoload/          Events (sinais globais), Net (conexão) e Sfx (som)
  scripts/components vida, inventário, área de acerto, área de interação, inflamável
  scripts/…          jogador, mundo, recursos, slime, bola de fogo, HUD
  scenes/            cenas de cada coisa (jogador, árvore, pedra, slime, bola de fogo, mundo)
  data/items/        itens como dados (.tres)
  tests/             testes de fumaça e prints
  tools/             scripts de apoio (controles, bateria de testes, importar_folha: folha do Codex → sprite do jogo)
```

## Como as coisas conversam

Cada objeto do mundo é montado com **componentes**. A bola de fogo não sabe o que é árvore: ela entrega "1 de dano de fogo" para a área de acerto (`Hurtbox`) do que tocar. Quem recebe decide: o slime perde vida, a árvore (que tem `Flammable`) pega fogo e passa a render carvão. Uma criatura ou objeto novo reage às habilidades só por ter esses componentes.

## Assets

Placeholders: **Ninja Adventure** (Pixel-boy e AAA, CC0), escolhido por ser de um estilo só. A arte final vai ser própria, gerada pelo Codex a partir da bíblia visual. Tudo está em `assets/manifest.csv`.
