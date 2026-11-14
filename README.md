# Ilha Viva (nome provisório)

Co-op online de sobrevivência e exploração numa ilha de fantasia que reage ao que o grupo faz. Godot 4.7.2, 2D com visão de cima. Visão completa em [design/gdd.md](design/gdd.md).

## Estado

**Etapas 0 e 1 concluídas; Etapa 3 (personagem e classes) em andamento.** A base do jogo está em cenas e componentes. Desde 30/10/2026 a arte segue o estilo do pacote **Tiny Swords** (Pixel Frog): terreno, árvores e interface vêm do pacote; personagens, acampamento, pedras, slime, efeitos e ícones são nossos, feitos pelo Codex no mesmo pixel do pacote (processo em [design/processo_arte.md](design/processo_arte.md)). Tarefas em [design/backlog.md](design/backlog.md).

**O que já funciona (sozinho ou com amigos):**
- Inventário estilo Minecraft: mochila (I ou Tab) com 27 espaços e barra 1-9, pilhas de 64, fabricação 2x2 na mochila e 3x3 na bancada, ferramentas de madeira e pedra, item na mão.
- Construção: parede, porta, chão de madeira, tocha, fogueira, baú e bancada, com prévia; golpes quebram e devolvem.
- Baú que guarda itens (27 espaços, como no Minecraft), salvo no mundo.
- Personagens por peças (estilo Forager): cabeça, tronco, pezinhos e mãozinhas; o item da barra vai na mão. Cada classe começa com a sua arma.
- Gosma curativa (2 gel de slime): botão direito com ela na mão recupera vida.
- Animais (galinha, coelho, ovelha e javali): passeiam, fogem, o javali revida; deixam carne, pena, couro e ovo. Carne crua vira assada na fogueira.
- Saque no chão (como no Minecraft): animais, slimes e baú quebrado soltam os itens no chão; é só chegar perto para pegar (o que não couber na mochila fica lá, e some depois de 5 minutos).
- Nível em cima da cabeça de slimes e animais; a barra de vida aparece quando apanham e some 4 s depois. Personagem de frente, de perfil e de costas; 4 habilidades por classe. Balanceamento em [design/balanceamento.md](design/balanceamento.md).
- Noite perigosa: slimes mais fortes no escuro, que fogem da luz e derretem ao amanhecer; derrotados deixam gel de slime.
- Arqueiro inimigo (Archer preto do Tiny Swords): grupos de 2 nas bordas da ilha e, à noite, um arqueiro da noite de vez em quando. Fica longe, puxa o arco (o aviso) e atira; a flecha para nas paredes, na Barreira do Clérigo e na cúpula do Bastião. Respeita os estados (Cego erra, Medo foge, Provocado persegue...) e deixa penas e experiência.
- Baús trancados longe da fogueira (com corrente e cadeado): o Ladino com Dedos leves abre na hora; uma CHAVE (o arqueiro inimigo solta em 30% das vezes) abre na hora e some; os outros quebram a tranca com 6 golpes. Aberto, o baú fica um instante com a tampa levantada e some. Acerto crítico (5%, dano dobrado, com estouro de impacto próprio) e estado Molhado (água, gelo derretido: gotinhas pingando e respingo ao entrar na água).
- Dano que dá para sentir: slime e javali dão uma cabeçada (acertam uma vez e recuam); quem apanha dá um passo para trás, fica vermelho, a tela treme de leve e, com pouca vida, as bordas ficam vermelhas.
- Arte no estilo Tiny Swords:
  - ilha com mar e espuma animada, areia, grama, árvores balançando, arbustos e tocos;
  - o boneco por camadas (L24): Humano e Ogro de roupinha branca, 3 rostos e 3 tons de pele cada, e as roupas e chapéus do Guerreiro, do Mago e do Arqueiro, de perfil, de frente e de costas, parados, andando e golpeando;
  - acampamento, pedras que racham, cogumelo azul que brilha à noite e slime;
  - efeitos (bola de fogo, lança de gelo, gelo na água, cristais, golpe giratório, explosão, poeira, brilho de nível) e a armadilha;
  - interface com painéis, botões, barras, retrato do personagem, ícones e teclinha E.
- Mundo salvo: árvores cortadas, pedras, noite e o seu personagem (nível, pontos, itens, onde estava) voltam ao abrir de novo. Cada raça + classe é um personagem salvo separado. Vários mundos, como no Minecraft: cada um é um arquivo em `user://mundos/` com nome e dificuldade (o mundo antigo `ilha.save` aparece na lista como "Ilha").
- Home com a ilha viva ao fundo: Jogar (Sozinho ou Multijogador, lista de mundos com Jogar e Apagar, Criar mundo novo com nome e dificuldade Fácil, Normal ou Difícil), Configurações (trocar as teclas, volume e tela cheia, gravados em `user://configuracoes.cfg`) e Sair. Raça e classe ficam para depois de entrar no mundo. Esc no mundo abre a pausa (Continuar, Configurações, Sair para o menu, que salva antes). Ficha na tecla C.
- Criação de personagem dentro do mundo (L24): na primeira vez que o jogador entra num mundo, abre a tela de criação (o mundo segue rodando para os outros). Passo 1: raça (Humano ou Ogro), rosto e pele, com o bonequinho ao lado de roupa branca mudando na hora. Passo 2: classe (Guerreiro, Mago ou Arqueiro), e o boneco veste as roupas base dela. "Entrar no mundo" manda a escolha ao anfitrião, que confere, define a ficha (atributos que mudam vida, mana, velocidade, dano e coleta), veste as roupas e põe a arma da classe na barra. Quem já tem personagem salvo no mundo pula a tela. Ficha na tecla C. Testes e linha de comando (`--solo`, `--hospedar`, `--entrar`, `--raca`, `--classe`) pulam a tela (`Net.pular_criacao`); `--criar` força.
- Roupas: dois espaços (cabeça e corpo) na mochila, ao lado de um bonequinho que mostra o personagem vestido (como no Minecraft). Arrastar ou Shift + clique veste e tira; sem roupa, o boneco fica com a roupinha branca. Por enquanto só visual (a classe vem da escolha, não das roupas).
- Raças e classes básicas de RPG: 4 raças (Humano, Ogro, Elfo com Passo leve, Anão com Mineiro) e 5 classes (Guerreiro, Mago, Arqueiro, Ladino com Golpe furtivo, Lâmina envenenada, Bomba de fumaça e Leque de adagas, Clérigo com Cura, Escudo sagrado, Luz sagrada e Bênção). Números em `design/balanceamento.md`. Provisório até a arte chegar: Elfo e Anão usam o corpo do Humano, e Ladino e Clérigo usam ícones e roupas emprestados (colete e bandana ficam brancos até haver arte).
- Níveis e experiência: derrotar slimes (dividido com quem está perto) e coletar dão experiência; cada nível dá 2 pontos de atributo (botões "+" na ficha) e 1 de habilidade (gasto na árvore). Humano ganha 10% a mais.
- Ficha (C, `game/scripts/ui/ficha_tela.gd`): retrato, classe, raça, nível e experiência em cima; abas Atributos e Habilidades, cada uma com um selo dourado com os pontos para gastar. Atributos em ladrilhos com um "+" grande (o mouse em cima mostra a prévia do que sobe, em verde) e os status em caixinhas com ícone; Habilidades lista as das teclas com o nível e o botão "Abrir árvore".
- Árvore de habilidades (K, ou o botão na ficha; `design/arvore_habilidades.md`): 3 passivas da classe desde o nível 1, 2 habilidades padrão, mais 3 iniciais nos níveis 2 a 4, UM ramo a partir do nível 5 e melhorias (até 3 por habilidade) com os pontos que sobram. O jogador pede, o anfitrião confere (pontos, nível, pré-requisito, ramo) e manda para todos; a árvore e as teclas Q R T E escolhidas são salvas no mundo. Passivas que já mudam o jogo ficam em `game/scripts/player/passivas.gd`; nós com "!" na tela ainda estão com o efeito pendente. Caminhos ligam cada nó ao pré-requisito (e as iniciais à entrada de cada ramo): dourado quando os dois estão aprendidos, verde quando dá para aprender o de baixo, cinza quando bloqueado.
- Base comum das habilidades (`design/habilidades_base.md`): cada classe tem os seus arquivos de lógicas (`abilities/logicas_<classe>.gd`), de árvore (`data/arvore_<classe>.gd`) e de passivas (`player/passivas_<classe>.gd`). Efeitos de estado nos slimes, animais e jogadores (Queimadura, Veneno, Lentidão, Congelado, Atordoado, Preso, Medo, Marcado, Derrubado, Cego, Provocado, Invisível), buffs de aliados, Fúria do Guerreiro e combo do Ladino (barra no HUD) e peças prontas: zona no chão, invocação/torreta, companheiro, projétil que perfura/quica/volta/puxa, corrente, avanço. Testes: `efeitos_estado_smoke` e `pecas_smoke`.
- Habilidades da classe nas teclas 1 e 2 (Investida e Giro; Bola de fogo e Lança de gelo; Tiro carregado e Armadilha), com mana e recarga, e esquiva no Espaço.
- Reações: gelo congela (e um golpe estilhaça com dano dobrado), lança de gelo sobre a água vira ponte que derrete, fogo passa devagar para árvores vizinhas.
- Jogar sozinho, hospedar ou entrar pelo IP do anfitrião (até 4 jogadores).
- Multiplayer: cada um com a sua câmera; o anfitrião cuida do mundo (árvores, slimes, dano, inventário, dia e noite) e quem entra depois vê o que já mudou.
- Ilha grande (L36, 190 x 130 blocos, sempre a mesma) com 6 regiões ligadas por trilhas: Clareira (o acampamento, no centro), Bosque Florido (árvores rosas, flores), Praia das Conchas (areia, coqueiros, conchas), Pântano dos Cogumelos (lama, lagoinhas, cogumelos que brilham à noite, névoa), Colinas de Pedra (muitas pedras, rochedos) e Ruínas dos Guardiões (piso antigo, colunas, estátua). Um rio separa o norte: a ponte (Pântano → Colinas) e a muralha de raízes (Bosque → Ruínas) vão abrir com as Sementes; por enquanto estão abertas. Detalhes em `design/proposta_mundo.md`.
- Bichos por região (`world/povoamento.gd`, tabelas em `world/regioes.gd`): cada região enche até o limite (que cresce com os jogadores) com os bichos dela, de dia e de noite; nascem fora da tela e longe da fogueira e de construções; morto volta depois de 2 minutos; longe do centro são mais fortes. Árvores e pedras crescem de novo (5 e 8 minutos).
- Só fica ativo o que está perto (`world/soneca.gd`): bichos, árvores e a espuma longe de todos dormem, e a rede manda para cada jogador só os bichos e itens perto dele.
- Mapa (M): a ilha de cima com as regiões, o acampamento e os jogadores; o que ainda não foi visto fica coberto e vai aparecendo ao andar (salvo com o mundo).
- Brasinha e missões (etapa 3, `design/proposta_brasinha.md`, T40c): o espírito de fogo da fogueira do acampamento (clique nela para falar; balão com texto letra por letra, clique ou E avança). Começa fraquinho (luz e zona segura pela metade) e acorda com 10 madeiras; depois madeira é petisco (contente e cura leve por perto). Missões do grupo no capítulo 1 até a isca (acordar, lenha, bancada, 6 slimes, 5 géis, pedra do pântano, isca) e o começo do capítulo 2 (Tocha do Brasinha abre as raízes). `Missoes.entregar_semente()` é o gancho da Mãe Gosma (fecha o capítulo, conserta a ponte, 1 ponto de árvore a cada um). Pedidos do dia a dia (1 por vez, ao amanhecer, recusáveis, só de regiões visitadas, 1 ponto de árvore a cada 5). 5 pedras de lore (clique abre imagem e frase). Diário na tecla J, rastreador no canto, "!" e "?" em cima dele e alfinete no mapa. Tudo é do anfitrião e vai no arquivo do mundo. As passagens (ponte e raízes) começam fechadas. Arte final do L42 ligada (caminhos em `ArteBrasinha`; prints em `evidence/l42/`). Testes: `brasinha_smoke`, `pedidos_smoke`, `semente_smoke`, `salvar_missoes_smoke`, `missoes_tela_smoke`.
- Acampamento com fogueira (um desenho animado só, L41) e barraca; a fogueira ilumina à noite com a luz tremendo.
- Mouse seleciona o objeto; a caixa em cima dele diz o que fazer e se está perto o bastante.
- Segurar E corta árvore (3 golpes = 3 de madeira, vira toco) e minera pedra (4 golpes = 3 de pedra, some).
- Bola de fogo (Mago): acerta slime (dano dobrado) e incendeia árvore; a árvore queimada rende **carvão** em vez de madeira.
- Golpe com clique esquerdo; slimes perseguem e machucam; com a vida em 0 o jogador cai no chão e vê a tela de morte (volta no acampamento sozinho aos 8 s, ou pelo botão "Reviver agora" depois de 4 s); o Levantar do Clérigo ou um aliado segurando E por 3 s o levantam ali mesmo.
- N alterna dia e noite; M abre o mapa; P liga/desliga o som.

**Ainda não tem:** o efeito das habilidades novas dos ramos (marcadas com "!" na árvore) e fonte pixel própria.

## Como rodar

1. Abra o Godot 4.7.2, clique em **Importar** e escolha `game/project.godot`.
2. Aperte **F5** e escolha no menu.

**Jogar com amigos na mesma rede (casa, Wi-Fi):** um clica em **Jogar > Multijogador > Hospedar** e escolhe o mundo; a tela mostra o IP dele (ex.: 192.168.0.10). Os outros digitam esse IP e clicam em **Entrar no jogo de um amigo**. Pela internet: veja [docs/jogar_pela_internet.md](docs/jogar_pela_internet.md) (Hamachi, Radmin VPN ou Tailscale).

Atalhos para testar sem o menu: `-- --solo`, `-- --hospedar` ou `-- --entrar=IP` no fim do comando do Godot.

| Ação | Tecla |
|---|---|
| Andar | WASD ou setas |
| Coletar e quebrar (segurar) | Clique esquerdo em cima do objeto |
| Golpear (ou pôr a peça da mão) | Clique esquerdo (na direção do mouse) |
| Barra de itens | 1 a 9 ou a rodinha do mouse |
| Usar o item da mão (gosma curativa) | Botão direito |
| Abrir baú, bancada, assar na fogueira | Um clique |
| Girar parede e porta | Rodinha do mouse (com a peça na mão) |
| Mochila e fabricação | I ou Tab (na bancada: segurar E). Shift + clique manda a pilha para o outro lado; com ela aberta não há dash nem habilidades |
| Dash (esquiva) | Shift |
| Habilidades da classe | Q, R, T e E. Magias, tiros do arco e supremas: segure até o anel ficar verde e solte (soltar antes cancela; ver design/conjuracao.md). Botão direito no botão delas (ou no Shift) mostra o que fazem |
| Ficha do personagem | C |
| Árvore de habilidades | K (clique num nó para ver e aprender; com ela aberta não há dash nem habilidades) |
| Dia / noite | N |
| Mapa da ilha | M |
| Missões do Brasinha | J |
| Som | P |

## Gerar o jogo para enviar a amigos

Cria `builds/IlhaViva.exe` (um arquivo só, sem precisar do Godot):

```bash
"$LOCALAPPDATA/Programs/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe" --headless --path game --export-release "Windows Desktop" ../builds/IlhaViva.exe
```

Para enviar: zipar o `.exe` junto com um `COMO JOGAR.txt` (como abrir, controles e como entrar pelo Hamachi). A pasta `builds/` fica fora do git.

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
  tools/             scripts de apoio: controles, bateria de testes e as ferramentas de arte
                     (importar_folha, pixelizar, comparar_folhas, montar_regua, mascara_tileset)
```

## Como as coisas conversam

Cada objeto do mundo é montado com **componentes**. A bola de fogo não sabe o que é árvore: ela entrega "1 de dano de fogo" para a área de acerto (`Hurtbox`) do que tocar. Quem recebe decide: o slime perde vida, a árvore (que tem `Flammable`) pega fogo e passa a render carvão. Uma criatura ou objeto novo reage às habilidades só por ter esses componentes.

## Assets

Arte: pacote **Tiny Swords** (Pixel Frog; uso comercial permitido, sem redistribuir) e peças nossas no estilo dele (Codex). Os sons e a música ainda são do **Ninja Adventure** (CC0). Tudo está em `assets/manifest.csv`.
