# Conjuração (L38)

Pedido do João: as magias demoram um tempinho para sair, como se o personagem estivesse
conjurando; o arco precisa ser puxado. Um anel perto do personagem diz quando soltar:
**vermelho** (ainda não sai nada) → **amarelo** (quase) → **verde** (pronto, com uma piscadinha).

## Como funciona

- O jogador **segura** a tecla (Q R T E) e **solta** quando o anel fica verde.
- **Soltar antes do verde cancela**, sem gastar mana e sem entrar em recarga. A "penalidade"
  é só o tempo perdido (decisão: punir mais deixaria o mago frustrado em combate; o tempo
  perdido já pesa).
- Enquanto conjura, o personagem **anda mais devagar** (metade, na maioria; 60% puxando o
  arco; 30% nas supremas). Ajustável em cada habilidade (`velocidade_conjurando`).
- **Apanhar não cancela**: cada golpe atrasa a conjuração em 0,15 s, no máximo 0,45 s por
  conjuração (o anel volta um pouquinho). Veneno e queimadura não atrasam, só golpes.
- **Dash cancela** (é a fuga). Cair também. Enquanto conjura, o clique não golpeia (as mãos
  estão ocupadas).
- O boneco fica na pose "golpe preparação" (quadro 4 do sprite completo), arma erguida e
  virado para a mira. Com o arco, a corda vai sendo puxada.
- O verde toca um sonzinho curto (só para quem conjura).
- **Os outros jogadores veem** o anel e a pose de quem está conjurando.

### Um sistema só (o antigo "carregar")

O Tiro carregado usava o modo CARREGAR (soltava na hora, mais fraco). Agora ele é uma
conjuração como as outras: precisa puxar a corda até o verde (0,4 s de base) e, **segurando
mais**, a carga continua enchendo até a carga cheia (1 s, crítico). Depois do verde, o miolo
do anel enche de luz e pisca de novo com a carga cheia. O modo CARREGAR só diz "tem carga
extra"; o resto é igual para todas.

## Fórmula do atributo

```
tempo = base × (1 − redução)
redução = (atributo − 5) × 3%, de 0% até no máximo 40%
```

- **Magias**: o atributo é o **Intelecto**. **Arco**: a **Agilidade**. Supremas do Guerreiro:
  tempo fixo (nenhum atributo dele faz sentido aqui).
- A **Mão leve** (passiva do arqueiro) ainda puxa o arco 30% mais rápido, por cima disso.
- Exemplos: Mago humano (Intelecto 9) → −12%; com Intelecto 15 → −30%; no 19 ou mais → −40%.
- A janelinha da habilidade (botão direito no HUD) mostra a linha "Conjuração: 0,88 s (base
  1 s, −12% pelo Intelecto 9; −3% por ponto…)". A ficha (C) mostra dois quadradinhos novos:
  "conjurar" e "puxar arco", com a redução atual.

## Tabela

Tempo de base (sem atributo). "Mago humano" = Intelecto 9 (−12%); "Arqueiro humano" =
Agilidade 9 (−12%) e Mão leve (÷1,3). Velocidade = quanto anda conjurando.

| Classe | Habilidade | Base (s) | Atributo | Velocidade | Com o atributo inicial |
|---|---|---|---|---|---|
| Mago | Bola de fogo | 0,3 | Intelecto | 50% | 0,26 s |
| Mago | Lança de gelo | 0,4 | Intelecto | 50% | 0,35 s |
| Mago | Raio | 0,5 | Intelecto | 50% | 0,44 s |
| Mago | Pedra viva | 0,3 | Intelecto | 50% | 0,26 s |
| Mago | Mini explosão | 0,4 | Intelecto | 50% | 0,35 s |
| Mago | Tornado de fogo | 1,0 | Intelecto | 50% | 0,88 s |
| Mago | Chuva de meteoros (suprema) | 1,8 | Intelecto | 30% | 1,58 s |
| Mago | Nova de gelo | 0,5 | Intelecto | 50% | 0,44 s |
| Mago | Muralha de gelo | 0,6 | Intelecto | 50% | 0,53 s |
| Mago | Prisão de gelo | 0,7 | Intelecto | 50% | 0,62 s |
| Mago | Nevasca (suprema) | 1,6 | Intelecto | 30% | 1,41 s |
| Mago | Corrente elétrica | 0,5 | Intelecto | 50% | 0,44 s |
| Mago | Totem tesla | 0,8 | Intelecto | 50% | 0,70 s |
| Mago | Tempestade (suprema) | 1,8 | Intelecto | 30% | 1,58 s |
| Mago | Espinhos | 0,5 | Intelecto | 50% | 0,44 s |
| Mago | Golem de pedra | 1,2 | Intelecto | 50% | 1,06 s |
| Mago | Fenda | 0,7 | Intelecto | 50% | 0,62 s |
| Mago | Despertar da ilha (suprema) | 2,0 | Intelecto | 30% | 1,76 s |
| Arqueiro | Tiro carregado (+ carga até 1 s) | 0,4 | Agilidade | 60% | 0,27 s |
| Arqueiro | Flecha perfurante | 0,6 | Agilidade | 60% | 0,41 s |
| Arqueiro | Marca do caçador | 0,4 | Agilidade | 60% | 0,27 s |
| Arqueiro | Chuva de flechas | 0,5 | Agilidade | 60% | 0,34 s |
| Arqueiro | Flecha do horizonte (suprema) | 1,5 | Agilidade | 30% | 1,02 s |
| Arqueiro | Campo minado (suprema) | 1,0 | Agilidade | 50% | 0,68 s |
| Arqueiro | Espírito da fera (suprema) | 0,8 | Agilidade | 50% | 0,54 s |
| Clérigo | Cura | 0,5 | Intelecto | 50% | = base* |
| Clérigo | Luz sagrada | 0,4 | Intelecto | 50% | = base* |
| Clérigo | Bênção | 0,5 | Intelecto | 50% | = base* |
| Clérigo | Coluna de luz | 0,5 | Intelecto | 50% | = base* |
| Clérigo | Aurora | 0,4 | Intelecto | 50% | = base* |
| Clérigo | Círculo de cura | 0,8 | Intelecto | 50% | = base* |
| Clérigo | Levantar | 1,0 | Intelecto | 50% | = base* |
| Clérigo | Santuário | 0,6 | Intelecto | 50% | = base* |
| Clérigo | Fonte da vida (suprema) | 1,5 | Intelecto | 30% | = base* |
| Clérigo | Muralha da fé (suprema) | 1,2 | Intelecto | 30% | = base* |
| Clérigo | Amanhecer (suprema) | 1,8 | Intelecto | 30% | = base* |
| Guerreiro | Juramento (suprema) | 0,8 | fixo | 50% | 0,8 s |
| Guerreiro | Fúria titânica (suprema) | 0,8 | fixo | 50% | 0,8 s |
| Ladino | Praga (suprema) | 0,8 | Intelecto | 50% | 0,8 s (Intelecto 4) |

\* Clérigo humano: Intelecto 4 + 1 da raça = 5, sem redução no começo; cada ponto a mais em
Intelecto tira 3%. Arqueiro: o tempo inicial já conta a Mão leve.

### O que NÃO conjura (sai na hora)

- **Movimento e fuga**: Piscar, Forma de relâmpago, Rastro de chamas, Investida, Cambalhota,
  Passo das sombras, Avançar!, Mil cortes, Salto esmagador.
- **Golpes rápidos e corpo a corpo**: Giro, Machadada, Redemoinho, Golpe furtivo, Dança das
  lâminas, Martelo da justiça, Martelo giratório, Leque giratório.
- **Defesas** (precisam ser na hora): Bloqueio, Bastião, Escudo sagrado, Barreira,
  Intervenção, Bomba de fumaça, Sumir, Provocar, Elo vital.
- **Arremessos e armadilhas** (não são feitiço nem arco): Bomba, Armadilha, Rede, Mina de
  fogo, Torre de besta, Frasco de ácido, Nuvem tóxica, Leque de adagas, Bumerangue, Escudo
  arremessado, Corrente, Veneno paralisante.
- **Ordens e gritos**: Grito de guerra, Fúria, Estandarte, Ordem de ataque, Assobio, Ataque!,
  Domar, Estouro da boiada, Lâmina envenenada, Marca da morte, Tempestade de aço.
- **Rajada** (3 flechas seguidas, "não precisa carregar").

O ataque básico (clique) continua sendo o golpe de perto para todas as classes; ainda não há
um tiro básico com o arco no clique. Quando houver, ele usa a mesma Conjuracao.

## Rede

- O **dono** conta o próprio tempo (anel liso, sem esperar a rede) e manda ao anfitrião
  "comecei" ao apertar e "soltei" (o pedido normal da habilidade) ao soltar.
- O **anfitrião** conta o tempo dele, a partir do "comecei". Ao receber o "soltei":
  - sem "comecei", ou mais de 0,2 s antes da hora: **recusa** (e devolve a recarga ao dono);
  - até 0,2 s antes (rede desigual, atraso do golpe ainda a caminho): **espera a hora** e só
    então lança. Nada sai antes do tempo no relógio do anfitrião.
  - A carga do Tiro carregado vale a do anfitrião (com 0,15 de folga para a rede).
- O anfitrião avisa todos para mostrar o anel de quem conjura; a pose vai pela animação
  sincronizada.
- Testes: `Player.usar_habilidade_por_id` é o atalho dos testes e pula a conjuração; o
  anfitrião só aceita esse atalho do jogador dele mesmo (nenhum código do jogo usa).

## Onde está

- `game/scripts/player/conjuracao.gd`: as regras e a rede (filho "Conjuracao" do Player).
- `game/scripts/ui/anel_conjuracao.gd`: o anel (indicador de interface).
- `HabilidadeData`: `conjuracao`, `atributo_conjuracao`, `velocidade_conjurando`.
- Teste: `game/tests/conjuracao_smoke.gd`. Prints: `game/tests/print_conjuracao.gd`.
