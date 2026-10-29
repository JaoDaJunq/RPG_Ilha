# Backlog

Lista oficial de tarefas. Marcar `[x]` só com prova (teste OK ou print revisado). Cada etapa termina com aprovação do João.

## Etapa 0: fundação (concluída)

- [x] T01 Repositório, AGENTS.md, GDD, backlog, bíblia visual (rascunho), manifesto de assets.
- [x] T02 Projeto Godot com o Input Map (WASD, E, clique, 1–6, N, M) e pixels nítidos.
- [x] T03 Componentes: vida, interagível, inflamável, saque e inventário.
- [x] T04 Cenas: jogador com câmera, árvore, pedra, slime, bola de fogo, mundo e HUD (com placeholders CC0).
- [x] T05 Testes de fumaça headless + script `rodar_testes.sh` + print dentro do jogo.
- [x] T06 Conceito visual aprovado (29/10): B = dia, A = noite. Bíblia em `design/identidade.md`.

## Etapa 1: multiplayer desde já (em andamento)

- [x] T10 Menu simples: Jogar sozinho / Hospedar / Entrar (IP).
- [x] T11 ENet com anfitrião no comando: cada jogador nasce no acampamento com a sua câmera.
- [x] T12 Movimento sincronizado; coletar, golpear, bola de fogo, dano, inventário e dia/noite passam pelo anfitrião. Quem entra depois recebe o que já mudou.
- [x] T13 Teste automático com dois jogos de verdade (`rede_smoke`) + prints das duas janelas em `evidence/rede/`.
- [x] T14 Guia em `docs/jogar_pela_internet.md` (Hamachi, já instalado no PC do João; Radmin VPN; Tailscale; firewall). Não testado com outra pessoa ainda.

## Etapa 2: fatia jogável em rede

- [ ] T20 Inventário de verdade (slots, empilhar) e hotbar.
- [ ] T21 Fabricação básica (bancada, receitas como dados `.tres`).
- [ ] T22 Construção (paredes, chão, porta) com prévia e custo.
- [ ] T23 Inimigos com estados (patrulhar, perseguir, atacar) e saque.
- [ ] T24 Dia e noite com perigo maior à noite; luz de fogueira e tocha.
- [x] T25 Salvar e carregar (anfitrião): árvores, pedras, noite e cada personagem (nível, pontos, itens, posição), um por jogador + raça + classe. Salva ao fechar a janela, ao voltar ao menu, quando alguém sai e a cada 60 s. Menu mostra o mundo salvo e tem "Começar mundo novo".

## Etapa 3: personagem, classes e habilidades (em andamento; proposta em `design/classes.md`)

- [x] T30 Ficha de atributos (raça + classe), mana, esquiva (Espaço) e barra com modos rápido, imediato e carregar. Modo "com mira" ainda falta.
- [x] T31 Criação no menu: Humano e Ogro; Guerreiro (Investida, Giro), Mago (Bola de fogo, Lança de gelo) e Arqueiro (Tiro carregado, Armadilha). Tudo em rede.
- [x] T32 Elementos e reações: congelar, estilhaçar (dano dobrado), ponte de gelo sobre a água que derrete, fogo que se espalha devagar para árvores vizinhas.
- [x] T33 Níveis 1–16 e experiência (slime 10, coleta 2, dividida num raio de 160 px; Humano +10%). Por nível: +2 pontos de atributo (botões "+" na ficha) e +1 de habilidade (guardados para a T34). Subir de nível cura e enche a mana.
- [ ] T34 Tela da árvore de habilidades (ramos de cada classe) e refazer escolhas na fogueira.
- [ ] T35 Ramos completos de Guerreiro, Mago e Arqueiro; modo "com mira".
- [ ] T36 Clérigo, Druida, Assassino e Alquimista; Elfo, Anão e Tritão.
- [ ] T37 Arte em camadas (corpo da raça + roupa da classe + arma) com o Codex.

## Feedback do playtest do João (29/10/2026)

Tudo o que foi pedido para testar funcionou. Observações:

- [ ] F01 **Armadilha do Arqueiro ruim:** o ícone no chão não faz sentido e o efeito de prender também não. Arte própria pedida em L04 (armada, fechando, fechada) → integrar.
- [ ] F02 **Painéis feios** (menu, ficha, HUD): arte própria pedida em L04 (painel, botões, espaços, ícones de atributos) + fonte pixel → refazer menu, ficha e HUD.
- [ ] F03 **Personagem pixelado e feio** comparado ao conceito: refazer desenhado no tamanho do jogo, com menos detalhes e mais fofo; personagens são ponto forte do jogo. Pedido L03 (com teste de caracterização raça × classe).
- [ ] F04 *(depois)* **Inventário** de verdade (o canto de cima não serve; o jogo vai ter muitos itens).
- [ ] F05 *(depois)* **Personagem segurando a arma/ferramenta** (espada, arco, machado) ao bater. Pesquisa e recomendação em `design/armas_na_mao.md` (arma em sprite separado, presa na mão e girada no golpe).
- [ ] F06 *(depois)* **Tirar "CHEGUE MAIS PERTO"** e trocar a caixa por só uma teclinha "E" em cima da árvore/pedra quando estiver perto (arte da tecla pedida em L04).

## Etapa 4: a ilha cresce

- [ ] T40 Mapa maior com 2–3 biomas.
- [ ] T41 Primeiro boss guardião.
- [ ] T42 Ruína ou caverna com segredo.

## Arte (contínuo, pelo Codex)

- [x] A01 Conceito visual (T06) → bíblia visual aprovada.
- [x] A01b Lote L01 (aventureiro, árvore, pedras): aprovado e no jogo (29/10). Ferramenta `game/tools/importar_folha.gd` converte as folhas do Codex.
- [ ] A01c Aventureiro redesenhado já no tamanho do jogo (~28 px): o L01 veio fino demais e perdeu detalhe no rosto ao reduzir pela metade.
- [ ] A01d Lote L02 (chão, acampamento, plantas, slime) gerado em 29/10: na pasta de aprovações, aguardando o João. Chão com emendas visíveis: provável refazer.
- [ ] A01e Lotes L03 (personagens + teste de camadas) e L04 (interface, ícones, armadilha) gerados em 29/10: na pasta de aprovações, aguardando o João. Vitrine: `evidence/vitrine/l02_l03_l04.png` (`tests/vitrine_arte.tscn`).
- [ ] A02 Tileset da clareira (grama, terra, areia, água) no padrão aprovado.
- [ ] A03 Personagem provisório próprio (4 direções: parado, andar, atacar, coletar).
- [ ] A04 Árvore (inteira, sendo cortada, toco, queimada), pedra, slime.
- [ ] A05 Efeitos: bola de fogo, chamas na árvore, acerto.
