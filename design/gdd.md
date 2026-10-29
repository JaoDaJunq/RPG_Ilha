# Ilha Viva: visão do jogo (GDD)

Nome provisório. Este documento consolida a conversa de 28/10/2026 (`VISAO-E-CONTINUIDADE.md` do protótipo do Codex). As ideias marcadas como **proposta** ainda não foram aprovadas.

## Em uma frase

Um co-op online de sobrevivência e exploração, para um grupo de amigos, numa ilha de fantasia colorida e misteriosa que **reage ao que o grupo faz**.

## Pilares

1. **Juntos, mas não presos.** Dá para fazer coisas em grupo ou separado, cada um com a sua câmera, sem perder a sensação de uma aventura na mesma ilha.
2. **A ilha reage, de forma previsível.** Habilidades valem para tudo no mundo: a bola de fogo acerta inimigo e também queima árvore. Cortar uma árvore dá madeira; queimar dá outra coisa. Consequências legíveis geram histórias entre amigos.
3. **Escolhas que pesam.** Classes de fantasia e uma árvore de pontos limitados, com trocas claras (ex.: abrir mão de mana por força física).
4. **Ninguém trava o grupo.** Todo mundo consegue coletar, fabricar ferramentas e abrigo simples e lutar. Uma classe facilita, mas nunca é a única saída, mesmo com um amigo offline.

## Referências

- **Core Keeper**: a principal referência visual (atmosfera, iluminação, riqueza de detalhes, personagens pequenos). A nossa ilha fica na superfície.
- **Secrets of Grindea**: RPG de ação 2D colorido, cooperação e habilidades.
- **Minecraft, 99 Noites, Green Hell, Peak, How to Fish**: sobrevivência, atividades e momentos que surgem jogando com amigos.
- **Hades, Soul Knight**: sensação de combate e controle (sem virar roguelite de salas).
- O João também gosta de Dead Cells, Everything Is Crab, Balatro, LoL e Rematch.

## Plataforma e controles

- Godot 4.7.2, 2D com visão de cima, PC Windows primeiro.
- **WASD** movimenta; o **mouse** mira e escolhe objetos e criaturas (o alvo é o próprio objeto, não um quadrado da grade).
- **E**: um toque abre baú, porta e bancada; segurar repete a ação (cortar, minerar) enquanto o jogador estiver ao alcance. O objeto sob o cursor fica destacado e mostra se o jogador está perto o bastante.
- **Clique esquerdo**: ataque básico na direção do mouse.
- **Barra de 5 ou 6 habilidades** (teclas 1 a 6, ajustável). Conjuração flexível estilo LoL, configurável por habilidade: rápida no mouse, com indicador e confirmação, ou imediata para habilidades sem alvo.
- Todos os comandos ficam no Input Map, para dar para remapear.

## Personagem e progressão

- **Classes de fantasia** em vez de profissões como foco principal.
- **Proposta** de afinidades: Guerreiro (Guardião/Berserker), Arcanista (elementos/invocação), Caçador (precisão/feras) e Místico (natureza/maldições).
- Árvore de pontos limitados, que ramifica e aprofunda estilos. Misturar árvores, os limites e o reset das escolhas são ideias a testar.
- Customização completa do personagem fica para depois; no começo o personagem é provisório.

## Mundo e progressão coletiva

- Coleta, fabricação e construção da base são atividades compartilhadas, com preparação para expedições.
- Criaturas, biomas, cavernas, ruínas, eventos e bosses dão objetivos de exploração.
- **Proposta:** bosses são guardiões de regiões e dão materiais ao grupo e escolhas de poder individuais.
- O mundo e a base são salvos e retomados entre sessões.

## Multiplayer

- Um jogador é o **anfitrião** (servidor) e os outros entram. O anfitrião valida as ações e o estado do mundo; os clientes enviam intenções (andar, interagir, lançar).
- No começo, para jogar pela internet sem mexer no roteador: Tailscale, ZeroTier ou similar. Steam fica para depois.
- Testar sempre em duas janelas e explicar o que foi verificado; funcionar localmente não prova que funciona pela internet.

## Fora do escopo por enquanto

Customização de personagem, mundo gerado proceduralmente em grande escala, Steam, PvP.
