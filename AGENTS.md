# Ilha Viva: regras para os agentes

Jogo co-op online de sobrevivência e exploração numa ilha de fantasia, em 2D com visão de cima, feito em Godot 4.7.2. O nome é provisório. O criador é o João: ele fala em português, sem jargão técnico, e aprova cada etapa antes de avançar.

Este arquivo vale para todos os agentes (Claude Code e Codex). O processo foi herdado do Smash Junq (`C:\projetos\smash_junq`), que já testou o que funciona.

## Onde está o estado do projeto

- `README.md`: o que já funciona, como rodar e como testar.
- `design/gdd.md`: a visão do jogo (o que é e o que não é).
- `design/backlog.md`: lista oficial de tarefas e etapas.
- `design/identidade.md`: a bíblia visual (rascunho até o João aprovar).
- `design/decisoes.md`: decisões tomadas e perguntas em aberto.
- `git log`: o que foi feito por último.

## Quem faz o quê

| Agente | Papel |
|---|---|
| **Claude Code** | Coordena e executa: planeja, programa em GDScript, escreve testes, integra assets, avalia as imagens contra a bíblia visual, documenta e escreve os pedidos de arte para o Codex. |
| **Codex** (`gpt-6-luna`, esforço alto) | Gera as imagens do jogo (login do ChatGPT, sem chave de API). Segue `art/prompts/README.md` e `design/identidade.md`, anexa as referências pedidas e salva só nas pastas indicadas no pedido. |

A cota do Codex é a mesma para imagens e código, então o Codex fica só com as imagens. Chamada padrão (da raiz do repositório):

```bash
codex exec -m gpt-6-luna -c model_reasoning_effort='"high"' -s workspace-write "<instrução apontando para o arquivo do pedido>"
```

Fluxo de arte: o Claude escreve o pedido em `art/prompts/pedidos/` → o Codex gera e salva como **candidato** → o Claude avalia e **copia as imagens inteiras para a pasta de aprovações do João** → o João aprova ou pede ajuste → o Claude integra, ou escreve a correção. Nada vai para `game/` sem aprovação do João.

**Estilo e método (desde 30/10/2026, ver `design/processo_arte.md`):**

- O estilo é o do pacote **Tiny Swords** (`art/terceiros/tiny_swords/`).
- Todo pedido anexa a **folha-régua** do pacote (`art/prompts/reguas/`) e traz três blocos: **FAÇA**, **NÃO FAÇA** e **NÃO SIGA**.
- **Objetos simples:** pixel art em 4x. Converter com `importar_folha.gd --pixel=4 --paleta_de=res://assets/tiny_swords/paleta.png --sombra`.
- **Personagens:** ilustração lisa. Converter com `pixelizar.gd`.
- **Antes de pôr no jogo:** comparar lado a lado com o pacote (`comparar_folhas.gd`).
- Toda peça nossa entra com escala 0,25, igual às do pacote.

**Pasta de aprovações:** `C:\Users\jpach\Aprovações Ilhas Vivas\`. Uma subpasta por pedido, com o status no nome: `<pedido> - <assunto> (aguardando)`, `(aprovado)` ou `(refazer)`, e um `LEIA-ME.txt` dizendo o que é cada imagem e o que olhar. Ao mudar o status, renomear a subpasta. Prints de dentro do jogo que dependem da aprovação dele também vão para a subpasta do pedido.

## Regras

- **Pronto quer dizer provado.** Código: `bash game/tools/rodar_testes.sh` com tudo OK. Visual: print tirado de dentro do jogo e olhado em tamanho real. Número em relatório sai de um comando; sem comando, escrever "não medido".
- **Arte nunca por código.** Nada de `draw_rect`/`draw_circle` para desenhar objeto, efeito ou personagem (só barrinha de interface e depuração). Se faltar a arte, pedir ao Codex ou usar um placeholder CC0 registrado.
  - **Exceção (João, 31/10/2026): EFEITOS podem ser feitos com o Pixelbolt** (`C:\Projetos\ferramentas\pixelbolt`, MIT). As receitas ficam em `art/fx_receitas/` (gerar com `node art/fx_receitas/gerar.mjs <pasta do Pixelbolt>`), sempre com as cores do Tiny Swords. A conversão para o jogo é `game/tools/importar_pixelbolt.gd`. Personagens e objetos continuam com o Codex.
- **Só assets próprios ou CC0** (ou licença conferida e registrada). Todo asset novo entra em `assets/manifest.csv`.
- **Todo sistema nasce pensando no multiplayer.** O estado do mundo muda por funções do servidor (o anfitrião), nunca direto pelo input do jogador.
- Godot sempre com `--headless`, exceto no playtest e nos prints. Binário: `%LOCALAPPDATA%/Programs/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`.
- Commits pequenos e com mensagem clara ao fim de cada tarefa. `git push` só com aprovação do João.
- Respostas ao João em português simples: o que mudou, o que falta e o que ele precisa decidir.
