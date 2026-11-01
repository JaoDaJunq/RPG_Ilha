# Guia para o Codex continuar o projeto

*Escrito em 01/11/2026, quando o João passou a usar o Codex direto, sem o Claude no meio. Leia também `AGENTS.md`: as regras de lá continuam valendo.*

## 1. Onde o projeto está

**O jogo:** Ilha Viva, co-op de sobrevivência numa ilha, em Godot 4.7.2 (GDScript), com arte no estilo do pacote Tiny Swords.

**O que já funciona:**
- **Home e mundos:** Home com a ilha ao fundo, lista de mundos (como no Minecraft) com dificuldade, configurações (trocar teclas, volume, tela cheia) e pausa.
- **Personagem:** criação ao entrar no mundo (raça, rosto, pele, classe). 4 raças (Humano, Ogro, Elfo, Anão) e 5 classes (Guerreiro, Mago, Arqueiro, Ladino, Clérigo), cada classe com 4 habilidades.
- **Itens e fabricação:** inventário como no Minecraft, com bancada, baú e o auxílio de receitas. Construção (parede, porta, chão, tocha, fogueira) com peças que giram.
- **Mundo:** animais com saque no chão, noite com slimes, dano com cabeçada, recuo e bordas vermelhas.
- **Multiplayer:** ENet, e o anfitrião decide tudo.

O que mudou por último está no `git log`; as decisões, em `design/decisoes.md`.

**Testes:** `bash game/tools/rodar_testes.sh` (da raiz). Roda umas 26 cenas `*_smoke` sem janela e precisa terminar com `BATERIA: tudo OK`.

**Godot:** `$LOCALAPPDATA/Programs/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe` (Windows), sempre com `--headless`, menos para prints.

**O João testa** pelo atalho "Ilha Viva - Previa" da Área de Trabalho, que abre o projeto direto (`--path C:\Projetos\ilha_viva\game`). Tudo o que for salvo no projeto aparece para ele na hora.

**GitHub:** `origin` = `https://github.com/JaoDaJunq/RPG_Ilha`. O João liberou `git push` para manter o repositório em dia.

## 2. A tarefa principal agora: personagem com ARTE COMPLETA

**Decisão de 01/11:** desistimos das roupas trocáveis (as tentativas estão em `design/pesquisa_roupas.md`). Agora:

- Cada combinação **raça x classe** é um personagem inteiro, nas 3 vistas: perfil olhando para a direita, frente e costas. São 4 raças x 5 classes = **20 personagens**. Comece pelos 5 do Humano e mostre ao João antes de fazer o resto.
- O personagem continua **montado por peças**, no estilo Forager: cabeça (já com o chapéu, elmo ou capuz), tronco (já com a roupa), um pé e uma mão, que o jogo anima.
- A arma da classe continua sendo um item, desenhado na mão pelo jogo.

### Como desenhar (o jeito que funcionou no L19 e no L21)

**Pedidos de exemplo:**
- `art/prompts/pedidos/L19_personagens_por_pecas.md` (perfil);
- `art/prompts/pedidos/L21_personagens_frente_costas.md` (frente e costas);
- `art/prompts/pedidos/L24_boneco_base_e_roupas.md`, com as "Regras de todas as folhas", que valem para todo pedido.

**Cada personagem são 2 folhas de 1536x1024** (3 colunas x 2 linhas, células de 512, fundo magenta #FF00FF):
- **Folha de perfil:**
  1. o personagem montado;
  2. só a cabeça (com o chapéu, elmo ou capuz);
  3. só o tronco (com a roupa);
  4. um pé;
  5. uma mão;
  6. vazia.
- **Folha de frente e costas:**
  1. montado de frente;
  2. cabeça de frente;
  3. tronco de frente;
  4. montado de costas;
  5. cabeça de costas;
  6. tronco de costas.

**Estilo:**
- Ilustração lisa (não pixel art), com contorno #161c2e grosso e cores chapadas com um tom de sombra.
- Corpo sem braços, mãozinhas soltas e pezinhos.
- Montado com cerca de 360 px de altura.
- As peças soltas têm EXATAMENTE o tamanho que têm no montado.

**Referências de aparência:**
- Raças: as folhas `art/sprites/tiny/bonecos/l24_*` e `l25_*`.
- Roupas e cores de cada classe: as tabelas do L24 e do L25.

Salve como `art/sprites/tiny/candidatos/l29_<raca>_<classe>_perfil.png` e `l29_<raca>_<classe>_frente_costas.png`.

### Como passar para o jogo

`game/tools/montar_pecas.gd` acha cada peça dentro do personagem montado e converte em pixel art (paleta do pacote e contorno):

```bash
G="$LOCALAPPDATA/Programs/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe"
C=../art/sprites/tiny/candidatos
# perfil (cria cabeca.png, tronco.png, pe.png, mao.png, pecas.json, inteiro.png, sombra.png)
"$G" --headless --path game --script res://tools/montar_pecas.gd -- --entrada=$C/l29_humano_mago_perfil.png --nome=humano_mago --saida=res://assets/sprites/tiny/bonecos
# frente e costas (cria cabeca_frente.png, tronco_frente.png, pecas_frente.json; idem _costas)
"$G" --headless --path game --script res://tools/montar_pecas.gd -- --entrada=$C/l29_humano_mago_frente_costas.png --extras=$C/l29_humano_mago_perfil.png --nome=humano_mago --saida=res://assets/sprites/tiny/bonecos --vista=_frente --montado=0 --cabeca=1 --tronco=2
"$G" --headless --path game --script res://tools/montar_pecas.gd -- --entrada=$C/l29_humano_mago_frente_costas.png --extras=$C/l29_humano_mago_perfil.png --nome=humano_mago --saida=res://assets/sprites/tiny/bonecos --vista=_costas --montado=3 --cabeca=4 --tronco=5
```

Ogro e anão são maiores: use `--altura=88` nas três chamadas. O padrão é 80.

O resultado fica em `game/assets/sprites/tiny/bonecos/<raca>_<classe>/`.

### O código que precisa mudar

O boneco é `game/scripts/player/boneco.gd`. Hoje `vestir(aparencia, equipado)` monta tudo em camadas: base da raça + rosto + roupa + chapéu, e as peças L27 em `<raca>/pecas/`. O novo jeito:

1. **Se existir `bonecos/<raca>_<classe>/`, usa o personagem inteiro.** A classe é a da roupa do corpo equipada (`roupa_<classe>`), ou a classe do jogador.
   - A cabeça, o tronco, o pé e a mão vêm dessa pasta, nas 3 vistas.
   - Não usa chapéu, rosto nem peças à parte.
   - O tom de pele continua: `_tingir()` na cabeça e nas mãos.
   - O código antigo que fazia isso (a função `configurar(raca, classe)`) está no histórico: `git show 28f9f4e^:game/scripts/player/boneco.gd`. As pastas antigas, para comparar, também: `git show 28f9f4e --stat`.
2. **Sem roupa** (a roupinha branca): continua usando `bonecos/<raca>/base/`.
3. **As roupas trocáveis viram uma coisa só.** Vestir a "roupa da classe" mostra o personagem inteiro daquela classe. O chapéu deixa de ser peça visual; pode virar só um item de atributo, ou sair.
   - Mexer em `game/scripts/ui/criacao.gd` e `game/scripts/ui/mochila.gd`: a miniatura e os espaços Cabeça e Corpo.
   - Também em `player.gd`: `ROUPAS_BASE` e `dar_kit`.
4. **Depois de funcionar, apagar o que não se usa mais:**
   - pastas: `bonecos/<raca>/<classe>/`, `bonecos/<raca>/pecas/`, `bonecos/<raca>/rosto_*`;
   - ferramentas: `game/tools/separar_peca.gd`;
   - arte: `art/sprites/tiny/gabarito/`.
   - Registre no `assets/manifest.csv`, que deve listar todo asset novo e não listar os apagados.

### Como provar que ficou bom

- Testes: `bash game/tools/rodar_testes.sh` com tudo OK.
- Print de dentro do jogo: `game/tests/print_customizacao.tscn` (precisa de janela, sem `--headless`) salva `evidence/novidades/customizacao.png`, com as combinações da lista `COMBOS` em 3 linhas: frente, perfil e costas. Abra a imagem e confira em tamanho real.
- Pasta de aprovações do João: `C:\Users\jpach\Aprovações Ilhas Vivas\`, com uma subpasta `L29 - <assunto> (aguardando)` com os prints e um `LEIA-ME.txt` em português simples.

## 3. O que vem depois (já aprovado pelo João)

- **Árvore de habilidades v2:** `design/arvore_habilidades.md`, com as mecânicas e habilidades aprovadas em 01/11. Implementar a tela da árvore e as passivas de classe (T34 e T35 do `design/backlog.md`). O João pediu para deixar ícones e efeitos das habilidades novas para depois.
- **Tarefas abertas:** o resto está no `design/backlog.md`.

## 4. Cuidados

- **Português simples** nas respostas ao João (ele não é técnico): o que mudou, o que falta e o que ele precisa decidir.
- **Arte nunca desenhada por código.** Efeitos podem ser feitos com o Pixelbolt (`art/fx_receitas/`).
- **Multiplayer:** o estado do mundo só muda por funções do anfitrião.
- **GDScript tipado:** o Godot dá erro em `var x :=` com valor sem tipo; nesses casos, ponha o tipo explícito.
- **Commits pequenos,** com mensagem clara em português.
- **Prints de evidência:** salve em `evidence/novidades/`.
- **Rodar o Godot:** o modo `workspace-write` do Codex bloqueou o Godot ("Acesso negado"). Para rodar testes e prints, o João precisa abrir o Codex com acesso total.
