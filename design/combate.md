# Combate e sensação de jogo (L40, 13/11/2026)

Reclamação do João depois de jogar:

- "o golpe básico parece uma metralhadora, fica praticamente impossível de morrer";
- "a sensação de jogar está muito DURA".

Referências: Hades, Soul Knight e Secrets of Grindea (golpe com peso, combo curto, inimigo
que reage ao apanhar, tela que "segura" o acerto).

## O que estava errado (medido)

Comando: `<godot> --headless --path game res://tests/medir_combate.tscn`. O jogador fica
parado, segurando o clique, colado no inimigo por 12 s; quando o inimigo cai, nasce outro no
mesmo lugar ("trocação sem cuidado").

1. **Metralhadora.** Todas as classes golpeavam a cada 0,35 s (2,75 golpes/s medidos),
   segurar o clique repetia sozinho e o anfitrião não conferia o ritmo (um cliente apressado
   podia mandar quantos golpes quisesse).
2. **O slime nunca chegava a atacar.** Cada golpe empurrava o slime a 160 px/s (~32 px), mais
   do que a distância de ataque dele (30 px). Resultado: **0 de dano recebido** em 12 s contra
   slimes, com qualquer classe.
3. **Dura.** O personagem ia de 0 à velocidade cheia (e parava) num quadro; o acerto não tinha
   peso nenhum (sem pausa, sem empurrão visível, só um tom avermelhado de 0,25 s no alvo); a
   câmera ficava presa no personagem; todo golpe tocava o mesmo som igual.

## Tabela antes / depois

Números da medição (`medir_combate.tscn`, antes = código do commit 86b755e, depois = este).
"Dano recebido" soma todo o dano (subir de nível cura, então a vida no fim engana).

| Classe x inimigo | Golpes/s (antes → depois) | Dano dado por s | Inimigos derrotados em 12 s | Dano recebido por s |
|---|---|---|---|---|
| Guerreiro x slime | 2,75 → 1,67 | 5,8 → 5,2 | 13 → 6 | **0,0 → 6,3** |
| Guerreiro x javali | 2,75 → 1,67 | 6,9 → 5,2 | 10 → 6 | 6,7 → 4,5 |
| Ladino x slime | 2,75 → 3,08 | 3,3 → 3,7 | 6 → 6 | **0,0 → 7,0** |
| Ladino x javali | 2,75 → 3,08 | 7,0 → 3,4 | 9 → 5 | 9,5 → 7,5 |
| Mago x slime | 2,75 → 1,33 | 1,3 → 1,1 | 3 → 2 | **0,0 → 7,0** |
| Mago x javali | 2,75 → 1,33 | 2,4 → 1,1 | 4 → 1 | 6,7 → 5,0 |
| Guerreiro parado x arqueiro inimigo | — | — | — | 2,7 → 2,7 (o jogador parado no meio do caminho; as flechas que erram não contam) |

Primeiro acerto (antes → depois): guerreiro 2,6 → 2,6; ladino 1,98 → 1,09; mago 0,9 → 0,72
(o mago mede 1,08 porque o 1º golpe dele erra o slime chegando e o que acerta é o final, x1,5).
Vida do jogador: guerreiro 120, ladino 100, mago 90 (humanos). Vida do slime 4 → 6.

Leitura: antes o slime **nunca** tirava vida de quem batia sem parar; agora, trocar golpes
parado custa de 6 a 7 de vida por segundo contra slimes (o guerreiro aguenta ~19 s, o mago
~13 s). Esquivando quando o slime achata, o custo deve cair muito (não medido: a medição não
esquiva).

Números de projeto (não medidos, saem das constantes):

| | Antes | Depois |
|---|---|---|
| Golpe: tempo entre golpes | 0,35 s (todas as classes) | guerreiro 0,5 · ladino 0,26 · clérigo 0,55 · arqueiro 0,5 · mago 0,55 s |
| Golpe: dano por classe | x1 | guerreiro x1 · ladino x0,55 · clérigo x0,9 · arqueiro x0,8 · mago x0,8 (a arma e a Força continuam valendo) |
| Combo | não tinha | guerreiro e ladino 3 golpes (o 3º x1,8 / x1,6); clérigo, arqueiro e mago 2 golpes (o 2º x1,6 / x1,5 / x1,5). O último golpe demora x1,7 para voltar |
| Anfitrião confere o ritmo | não | sim (folga de 90 ms) |
| Empurrão do golpe no inimigo | 160 px/s, ~32 px, sempre | normal ~3 px; golpe final ~28 px; **atacando, o inimigo não é empurrado** (armadura) |
| Vida do slime | 4 | 6 (o guerreiro mata com o combo de 3) |
| Recarga da flecha do arqueiro inimigo | 2,4 s | 2,0 s |
| Proteção do jogador depois de apanhar | 0,5 s | 0,4 s |
| Regeneração de vida do jogador | não existe (só comida, Bênção, Aura, subir de nível) | igual |
| Longe do centro (perigo 0 a 1) | dano x(1 + 0,8 x perigo); vida x(1 + 1,5 x perigo) | igual, **e** a espera entre os ataques cai até 25% (`Combate.ritmo_inimigo`). O aviso antes do ataque (o slime achatar, o arqueiro puxar o arco) não muda: continua dando para esquivar |

## Sensação de jogo (o que deixava "duro" e o que mudou)

Tudo é local de cada máquina; o dano continua só no anfitrião. Nada mexe em
`Engine.time_scale` (o anfitrião não "trava" o mundo dos outros).

| Ideia | Ficou? | Como | Medida (teste `combate_sensacao_smoke`) |
|---|---|---|---|
| Andar com aceleração e freada | sim | `Player.TEMPO_ACELERAR` 0,08 s, `TEMPO_FREAR` 0,06 s; depois do dash a sobra some na hora | 2 quadros: 17 de 80 px/s; cheio em 0,15 s; parado 0,1 s depois de soltar |
| Hit stop | sim | 2 quadros (golpe comum) e 4 (golpe final ou crítico): o personagem e o desenho do alvo param; a física e a rede seguem | acabou antes de 0,1 s; a física rodou ≥ 5 quadros nesse tempo |
| Piscar branco, sacudir e empurrão | sim | `ReacaoGolpe` (shader `piscar_branco`), 0,12 s de branco, sacode 1 a 2 px | branco 0,7 logo depois do golpe; empurrão normal 3,3 px, final 29,8 px |
| Tremor de câmera | sim | golpe final 1 px do mundo; explosão (`explosao`) 1,5 px, só em quem está a até 120 px | testado |
| Câmera suave olhando para a mira | sim | a câmera já seguia suave (smoothing 8); agora vai até 8 px do mundo na direção da mira, chegando aos poucos | 8 px com a mira à direita |
| Passinho para a frente no golpe | sim | 2 a 5 px por classe (o final dá o dobro), em 0,07 s | — |
| Buffer de comando | sim | apertar até 0,2 s antes da hora guarda o golpe | testado |
| Números de dano | sim | `NumeroDano`: 13 px, branco; crítico 19 px, amarelo, com "!" | testado |
| Sons variados | sim | `Sfx.tocar(nome, volume, tom, variar)`: golpe e acerto variam ±8 a 12% no tom; o golpe final e o crítico saem mais graves e mais altos | — |
| Andar mais devagar golpeando | sim | metade da velocidade durante o balanço (0,25 s) | — |

## Como funciona (para quem mexe no código)

- `game/scripts/components/combate.gd` (`Combate`): todos os números acima, o combo
  (`proximo_indice`, `recarga`, `mult_combo`), `ritmo_inimigo(quem)` e `tremer_perto`.
- `Player.golpear()` (dono): ritmo, combo previsto, buffer, passinho, som.
  `Player._pedir_golpe()` (anfitrião): confere o ritmo pelo relógio de jogo dele
  (`_relogio_ms`), decide o combo e a força, bate e avisa o dono (`_acertou_golpe`: hit stop
  e tremor). `Player.dano_do_golpe(i)` é o dano do golpe `i` do combo; `zerar_golpe()` é para
  os testes.
- `Hurtbox.receber(quantidade, tipo, origem, forca = 1.0)`: durante o repasse, `em_golpe`,
  `origem_golpe`, `forca_golpe` e `critico_golpe` ficam disponíveis.
- `game/scripts/components/reacao_golpe.gd` (`ReacaoGolpe`): a reação de qualquer criatura.
- `game/scripts/fx/numero_dano.gd` (`NumeroDano`): o número que sobe.

### Inimigo novo: como herdar o padrão

1. A cena precisa dos filhos `Visual` (AnimatedSprite2D), `HealthComponent`, `Hurtbox` e, se
   quiser, `BarraCabeca`.
2. No `_ready` (em TODAS as máquinas, antes de qualquer `if multiplayer.is_server()`):
   `reacao = ReacaoGolpe.em(self, PESO)` (PESO 1 = slime; mais pesado, menos empurrado).
3. No `_on_atingido` (anfitrião), só `vida.tomar_dano(dano, tipo)`. **Não** faça empurrão,
   tween de cor, som de acerto nem RPC de "piscar": o componente faz tudo isso e manda a vida
   para os clientes.
4. Ao andar (anfitrião): `velocity = ... + reacao.empurrao(delta) + efeitos.impulso()`, e
   `reacao.parar_empurrao()` quando `efeitos.impulso()` não for zero.
5. Enquanto ataca (preparando, pulando, investindo): `reacao.armadura = true`. É isso que faz
   "bater sem cuidado custar vida": o golpe do jogador não cancela o ataque.
6. Toda espera entre ataques multiplicada por `Combate.ritmo_inimigo(self)`.
7. Sempre um aviso antes do ataque (pose, achatar, puxar o arco) de pelo menos ~0,4 s.

Para ajustar a altura do número: `reacao.altura_numero` (px acima dos pés). Para reagir em
todas as máquinas (trocar o quadro, por exemplo): sinal `reacao.reagiu`.

## Testes e provas

- `game/tests/combate_sensacao_smoke.gd`: ritmo por classe, combo, anfitrião barrando 5
  golpes no mesmo instante, buffer, empurrão, armadura, piscar, número, crítico, hit stop sem
  mexer no tempo, tremor, slime revidando (≥ 20 de vida em 5 s de trocação), andar e câmera.
- `game/tests/medir_combate.tscn`: a medição da tabela (não entra na bateria).
- `game/tests/print_combate.tscn` (com janela): playtest roteirizado; prints em
  `evidence/novidades/combate_*.png` (e `combate_antes_*.png`, do código antigo, com
  `-- --antes`).
