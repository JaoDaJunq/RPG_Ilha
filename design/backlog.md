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

- [x] T20 Inventário estilo Minecraft (31/10): mochila (I ou Tab) com 27 espaços, barra 1-9, pilhas de 64, cliques do Minecraft (esquerdo, direito, Shift), item na mão. Habilidades foram para Q, R, F, G.
- [x] T21 Fabricação (31/10): grade 2x2 na mochila e 3x3 na bancada (segurar E), receitas com forma como no Minecraft em `data/receitas/`; ferramentas de madeira e pedra (machado e picareta coletam mais rápido, espada bate mais forte).
- [x] T22 Construção (31/10): parede, porta (o jogador passa, o slime não), chão de madeira, tocha, fogueira, baú e bancada; prévia verde ou vermelha; golpes quebram e devolvem o item; salvo no mundo e sincronizado.
- [x] T23 Slimes com estados (31/10): passeiam, perseguem, achatam antes de pular (aviso) e pulam; deixam gel de slime.
- [x] T24 Noite perigosa (31/10): slimes mais fortes nascem no escuro (mais jogadores, mais slimes), fogem da luz da fogueira e das tochas, derretem ao amanhecer.
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

- [x] F01 **Armadilha do Arqueiro ruim:** o ícone no chão não faz sentido e o efeito de prender também não. Arte própria pedida em L04 (armada, fechando, fechada) → integrar.
- [x] F02 **Painéis feios** (menu, ficha, HUD): arte própria pedida em L04 (painel, botões, espaços, ícones de atributos) + fonte pixel → refazer menu, ficha e HUD.
- [x] F03 **Personagem pixelado e feio** comparado ao conceito: refazer desenhado no tamanho do jogo, com menos detalhes e mais fofo; personagens são ponto forte do jogo. Pedido L03 (com teste de caracterização raça × classe).
- [x] F04 Inventário de verdade (ver T20).
- [x] F05 Personagens por peças, estilo Forager (31/10, L19): cabeça, tronco, pezinhos e mãozinhas soltas; o item da barra vai na mão da frente e bate junto. Cada classe começa com a sua arma (espada de ferro, cajado, arco).
- [x] F06 *(feito junto com a interface)* **Tirar "CHEGUE MAIS PERTO"** e trocar a caixa por só uma teclinha "E" em cima da árvore/pedra quando estiver perto (arte da tecla pedida em L04).

## Etapa 4: a ilha cresce

- [ ] T40 Mapa maior com 2–3 biomas.
- [ ] T41 Primeiro boss guardião.
- [ ] T42 Ruína ou caverna com segredo.

## Arte (contínuo, pelo Codex)

**Direção atual:** C02 aprovado em 29/10/2026: pixel art mais fina, com Forager e Moonlighter como referências. Ver `design/identidade.md`. As integrações anteriores continuam registradas abaixo; a qualidade final do novo estilo ainda precisa ser demonstrada no jogo.

L07: laboratório Godot isolado em `art/piloto_c02/abrir.cmd`, captura real revisada em `evidence/piloto_c02/dia.png`. Recortes e escala de exibição preparados; terreno v2 simplificado. A01j permanece pendente de avaliação visual do João e integração no jogo principal. O laboratório usa poses paradas, sem combate/coleta; não equivale à conclusão da migração.

- [x] A01i C02: João escolheu a proposta de pixel art fina. Conceito preservado em `art/conceitos/estilo/estilo_pixel_fino_v1.png`; pasta de aprovação atualizada. Desenho liso não escolhido.

- [x] A01 Conceito visual (T06) → bíblia visual aprovada.
- [x] A01b Lote L01 (aventureiro, árvore, pedras): aprovado e no jogo (29/10). Ferramenta `game/tools/importar_folha.gd` converte as folhas do Codex.
- [x] A01d Lote L02 (chão, acampamento, plantas, slime): aprovado e no jogo (29/10). Chão convertido com --preencher (sem grade).
- [x] A01e Lotes L03 (personagens) e L04 (interface, ícones, armadilha): aprovados e no jogo (29/10).
- [x] A01f L05 (costas, perfil e caminhada): substituído pelos personagens do L15 (estilo Tiny Swords).
- [x] A01l **Jogo migrado para o estilo Tiny Swords (30/10)**: terreno, espuma, árvores, tocos, arbustos e interface do pacote; câmera em zoom 4. Provisório: árvore queimada só escurece, sem marca de machado; beira da ilha em degraus (terreno em blocos).
- [x] A01m Personagens próprios no estilo Tiny Swords (L15, 30/10): os 6 (Humano e Ogro x Guerreiro, Mago, Arqueiro) com parado, respirando, 2 passos, preparando e golpe, de perfil. Ilustração do Codex pixelizada aqui na densidade do pacote. No jogo; aguardando o João testar.
- [x] A01n Acampamento, pedras, cogumelo e slime refeitos (L14) e efeitos, gelo, armadilha e ícones (L16) no estilo Tiny Swords, comparados lado a lado com o pacote. No jogo; aguardando o João testar.
- [ ] A01o Próximos: personagem de costas e de frente (hoje só de perfil), árvore queimada própria, marca de machado, arco puxando a flecha e cajado brilhando ao lançar.
- [ ] A01p *(guardado, 31/10)* Mais efeitos com o Pixelbolt (receitas em `art/fx_receitas/`): fogo na fogueira e nas árvores, fumaça, respingo na água, golpe do guerreiro, cura, raio. O João pediu para esperar.
- [ ] A01g Fonte pixel própria (a do pacote placeholder tinha o "i" quebrado; hoje usa a fonte padrão do Godot). Ex.: Pixelify Sans (OFL), precisa de autorização para baixar.
