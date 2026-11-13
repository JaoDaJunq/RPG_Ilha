# Base comum das habilidades (para os 5 agentes de classe)

Este arquivo explica as peças prontas para implementar os nós pendentes da árvore
(`design/arvore_habilidades.md`). Cada agente mexe **só nos arquivos da sua classe**. Tudo
o que muda o mundo roda no **anfitrião** (as lógicas já rodam lá).

Testes das peças: `game/tests/pecas_smoke.gd` e `game/tests/efeitos_estado_smoke.gd` (bons
exemplos de uso). Rode sempre `bash game/tools/rodar_testes.sh` até ver `BATERIA: tudo OK`.

## 1. Onde cada classe escreve (sem pisar nos outros)

| O quê | Arquivo da sua classe | Como entra no jogo |
|---|---|---|
| Lógica das ativas | `game/scripts/abilities/logicas_<classe>.gd` | Toda `class Nome extends HabilidadeLogica` dali já fica registrada. No `.tres`, `logica = &"Nome"`. O nome não pode repetir o de outro arquivo (nem os de `logicas.gd`: Investida, Giro, Raio, Bomba, Armadilha...). |
| Dados da ativa | `game/data/habilidades/<id>.tres` (um arquivo por habilidade) | `ArvoreData` carrega pelo id do nó. |
| Estado do nó na árvore | `game/scripts/data/arvore_<classe>.gd` | Último campo do nó: `""` funciona, `P` pendente, texto = o que falta. Ao terminar, troque para `""`. |
| Passivas novas | `game/scripts/player/passivas_<classe>.gd` | `passivas.gd` chama as funções de todas as classes; cada uma confere `p.tem(&"<nó>")`. |
| Testes | `game/tests/<classe>_<algo>_smoke.gd` (+ `.tscn` igual aos outros) | O `rodar_testes.sh` roda todo `*_smoke.tscn`. |

Arquivos comuns (`logicas.gd`, `passivas.gd`, `player.gd`, `slime.gd`, `animal.gd`,
`world.gd`, as peças abaixo): só mexa se for indispensável, em poucas linhas, e diga no
relatório. Se precisar de algo novo em uma peça, prefira as opções `ao_tique`/`ao_atacar`
(Callable) ou o sinal `acertou` em vez de mudar a peça.

Os testes antigos que falam de nós pendentes (ex.: `arvore_smoke.gd` usa `assobio` como
"pendente" e `flecha_perfurante` como "não vai para as teclas") vão quebrar quando o nó
ficar pronto: troque por outro nó que continue pendente, ou ajuste a frase.

### Exemplo completo de uma ativa

`game/data/habilidades/grito_de_guerra.tres`:

```
[gd_resource type="Resource" script_class="HabilidadeData" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/data/habilidade_data.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/sprites/tiny/icones/icone_experiencia.png" id="2"]

[resource]
script = ExtResource("1")
id = &"grito_de_guerra"
nome = "Grito de guerra"
descricao = "..."
icone = ExtResource("2")
modo = 1
custo_mana = 8.0
recarga = 10.0
elemento = &"fisico"
dano = 0.0
logica = &"GritoDeGuerra"
animacao = &"golpe"
som = &"giro"
```

`game/scripts/abilities/logicas_guerreiro.gd`:

```gdscript
class GritoDeGuerra extends HabilidadeLogica:
	func executar(quem: Player, _hab: HabilidadeData, _dir: Vector2, _alvo: Vector2, _carga: float) -> void:
		Golpes.estado_em_volta(quem, quem.global_position, 48.0, EfeitosEstado.MEDO, 1.5)
		Golpes.buff_em_volta(quem, 80.0, Buffs.DANO, 0.10, 6.0)
		World.efeito_todos(quem, &"furia", quem.global_position)
```

E em `arvore_guerreiro.gd`, o último campo de `grito_de_guerra` passa de `P` para `""`.

`HabilidadeData` (campos novos): `animacao` (`&"golpe"` padrão, `&"parado"` = sem
animação), `duracao_animacao` (0 = 0,2 s) e `som` (nome em `Sfx`; vazio usa a tabela antiga
`Player.SONS`). `HabilidadeLogica.dano_de(quem, hab)` já soma atributo, melhorias e passivas.

## 2. Efeitos de estado — `EfeitosEstado` (components/efeitos_estado.gd)

Slimes, animais e jogadores têm um filho `EfeitosEstado`. Só o anfitrião aplica; todos
recebem a lista (RPC) e pintam o desenho com o tom do estado mais importante.

```gdscript
EfeitosEstado.aplicar_em(alvo, EfeitosEstado.LENTIDAO, 3.0, 0.4, quem)  # 40% mais lento por 3 s
var e := EfeitosEstado.de(alvo)   # o componente (ou nulo)
e.aplicar(EfeitosEstado.VENENO, 3.0, 1.0, quem, 5)   # Veneno acumula até 5 (Toxina)
e.tem(EfeitosEstado.CONGELADO); e.restante(...); e.forca(...); e.acumulos(...); e.origem(...)
e.dano_restante(EfeitosEstado.VENENO)   # Praga: o veneno que falta, de uma vez
e.remover(EfeitosEstado.QUEIMADURA); e.limpar_ruins()   # Mãos que curam, Fonte da vida
e.empurrar(Vector2(-30, 0), 0.15)   # empurrão ou puxão (respeita paredes)
```

| Estado | `forca` | O que faz |
|---|---|---|
| `QUEIMADURA` | dano por segundo | tique a cada 1 s, `segundos` tiques (tipo `&"queimadura"`) |
| `VENENO` | dano por segundo por acúmulo | igual, × acúmulos (`max_acumulos`, padrão 1) |
| `LENTIDAO` | fração perdida (0,4 = 40%) | anda mais devagar |
| `CONGELADO` / `ATORDOADO` / `DERRUBADO` | — | não anda nem ataca |
| `PRESO` | — | não anda (enraizado) |
| `MEDO` | — | foge da `origem` (ou do jogador mais perto) e não ataca |
| `MARCADO` | dano a mais (0 = 20%) | toma mais dano de todo mundo (Hurtbox) |
| `CEGO` | chance de errar (0 = sempre) | o ataque erra (`erra_ataque()`) |
| `PROVOCADO` | — | persegue a `origem` (um jogador ou uma invocação) |
| `INVISIVEL` | — | jogadores: os inimigos não veem (`Player.escondido()`) |

- Os tiques passam pela Hurtbox sem repetir as passivas de quem aplicou; se derrubarem o
  alvo, `Passivas.derrotou(origem, alvo)` é chamado (Contágio, Sede, Cinzas...).
- O congelar/estilhaçar e o veneno antigos agora usam o componente (`slime.congelado()`,
  `prender()`, `envenenar(seg, dano, origem)` continuam valendo; o animal ganhou `prender()`).
- No jogador: Lentidão/Preso/Atordoado entram na velocidade (`Passivas.velocidade`).
- Dano do inimigo no jogador passa por `Passivas.ataque_inimigo(atacante, alvo, dano)`:
  use o gancho `ataque_inimigo` da sua passiva (ex.: Frio que morde olha
  `EfeitosEstado.de(atacante).tem(LENTIDAO)`).

## 3. Peças reutilizáveis (game/scripts/abilities/)

### Zona no chão — `Zona` (zona.gd)
Só existe no anfitrião; os outros veem o `efeito_visual` (Efeito em laço).
```gdscript
var z := Zona.criar(quem, ponto, 40.0, 6.0)   # raio, segundos (intervalo padrão 1 s)
z.dano = dano_de(quem, hab); z.elemento = &"quimico"   # por tique nos inimigos dentro
z.cura = 4.0                                           # por tique nos jogadores dentro
z.estado = EfeitosEstado.VENENO; z.estado_segundos = 2.0; z.estado_forca = 1.0
z.buff = Buffs.DANO; z.buff_valor = 0.15; z.buff_segundos = 1.5   # Estandarte
z.seguir = quem              # anda junto (Rastro de chamas, Martelo giratório)
z.efeito_visual = &"circulo_cura"; z.escala_visual = Efeito.escala_para_raio(&"circulo_cura", 36.0)
z.efeito_tique = &"poeira"   # peças de arte: Efeito.PECAS (poça, nuvem, cúpula, nevasca...)
z.ao_tique = func(zona: Zona, inimigos: Array[Node2D], jogadores: Array[Player]) -> void: pass
z.iniciar()
```
Tiques: na hora (`tique_na_hora`) e a cada `intervalo` até o fim (6 s → 7 tiques).

### Invocação / torreta — `Invocacao` (invocacao.gd + scenes/abilities/invocacao.tscn)
Tem vida (`HealthComponent`), tempo de vida e ataca sozinha o inimigo mais perto.
Sincronizada (spawner do mundo).
```gdscript
var g := Invocacao.criar(quem, ponto)
g.desenho(["golem"], 6.0, "golem_soco")   # arte inteira de assets/sprites/tiny/habilidades/
g.escala = 0.5               # (opcional) maior; folhas antigas: textura_caminho + quadro
g.duracao = 15.0; g.vida_maxima = 40.0
g.dano = dano_de(quem, hab); g.elemento = &"terra"
g.alcance = 18.0; g.intervalo = 1.0; g.visao = 110.0
g.velocidade = 30.0          # 0 = parada (Totem tesla, Torre de besta)
g.provoca_raio = 60.0        # Golem: chama os inimigos (eles batem nele)
g.projetil = preload("res://scenes/abilities/flecha.tscn")   # Torre de besta (vazio = acerto direto)
g.efeito_ataque = &"raio"    # Totem tesla
g.estado = EfeitosEstado.ATORDOADO; g.estado_segundos = 0.5
g.ao_atacar = func(inv: Invocacao, alvo: Node2D) -> void: pass
g.iniciar()
```
A invocação ataca em nome dela mesma (não usa as passivas do dono). A arte vai por caminho,
sincronizada ao nascer; o desenho do ataque (`textura_ataque`) aparece em todos a cada golpe.

### Companheiro — `Companheiro` (companheiro.gd + scenes/abilities/companheiro.tscn)
Uma Invocação que segue o dono e ataca o alvo dele (`Player.ultimo_alvo`, o último inimigo
ou animal que ele acertou). Não some sozinho.
```gdscript
var c := Companheiro.criar_companheiro(quem)
c.dano = 1.0; c.textura_caminho = "..."; c.iniciar()
Companheiro.de(quem)      # os companheiros do jogador (Matilha: "com o companheiro perto")
c.atacar_agora(alvo)      # Ataque!
```

### Projéteis especiais — `Projetil` (projetil.gd)
Depois de criar (ex.: `Logicas.lancar(...)` devolve o projétil), ligue:
```gdscript
var p := Logicas.lancar(Logicas.FLECHA, quem, dir, dano_de(quem, hab))
p.perfura = true                    # Flecha perfurante, Flecha do horizonte
p.quiques = 2; p.raio_quique = 64   # Escudo arremessado (quica em 3)
p.volta = true                      # Bumerangue de adaga, Martelo da justiça
p.puxa = 48.0                       # Corrente (puxa até o lançador)
p.estado = EfeitosEstado.ATORDOADO; p.estado_segundos = 0.5
p.acertou.connect(func(alvo: Node, pos: Vector2) -> void: pass)   # a cada acerto
```
Sem nada ligado, o projétil é igual ao de antes (para no primeiro).

### Golpes prontos — `Golpes` (golpes.gd, funções estáticas)
```gdscript
Golpes.inimigos_em_volta(quem, centro, raio, com_animais := true)   # do mais perto ao mais longe
Golpes.jogadores_em_volta(quem, centro, raio)
Golpes.mais_perto(quem, centro, raio, menos := [])
Golpes.acertar(quem, alvo, dano, elemento, estado, segundos, forca, efeito)
Golpes.corrente(quem, primeiro, 5, 56.0, dano, &"raio", &"raio")     # salta entre 5 alvos
Golpes.avancar(quem, mira, hab.alcance, dano, &"raio", 14.0, true)   # teleporte com dano no caminho
Golpes.buff_em_volta(quem, 80.0, Buffs.VELOCIDADE, 0.15, 6.0)         # no jogador e aliados perto
Golpes.estado_em_volta(quem, quem.global_position, 48.0, EfeitosEstado.PROVOCADO, 4.0)
Golpes.puxar(alvo, quem.global_position, 40.0)
```

### Buffs do jogador — `Buffs` (components/buffs.gd; `p.buffs`)
`p.buffs.dar(tipo, valor, segundos, de)`: `DANO` (+15% = 0,15, vale em todo dano que o
jogador causa), `VELOCIDADE`, `REDUCAO` (0,3 = 30% menos dano), `REGENERACAO` (vida por
segundo, cura em nome de `de`) e `ESCUDO` (vira escudo da vida na hora). Vale o mais forte
de cada tipo. Leitura: `p.buffs.tem()`, `valor()`, `mult()`, `restante()`.

## 4. Recursos de classe — `RecursosClasse` (player/recursos_classe.gd; `p.recursos`)
- **Fúria (Guerreiro)**: 0 a 100. +8 por acerto, +1,5 por ponto de vida perdido; depois de
  6 s sem lutar, cai 10 por segundo. `p.recursos.furia`, `furia_cheia()`,
  `gastar_furia(50.0) -> bool`, `ganhar_furia(x)`.
- **Combo (Ladino)**: 0 a 5. +1 por acerto (no máximo um a cada 0,15 s: o leque não dá 3);
  some depois de 10 s sem acertar. `p.recursos.combo`, `gastar_combo() -> int` (finalizador:
  devolve os pontos e zera), `ganhar_combo(n)`.
- O HUD mostra a barra embaixo da mana (só para Guerreiro e Ladino).

## 5. Passivas por classe — `passivas_<classe>.gd`
Funções que `passivas.gd` chama em todo jogador (devolva 1.0 quando não valer):

| Função | Quando | Devolve |
|---|---|---|
| `dano_causado(p, qtd, tipo, alvo)` | antes de um acerto do jogador | multiplicador |
| `acertou(p, alvo, qtd, tipo)` | depois de acertar inimigo/animal | — |
| `dano_recebido(p, qtd, tipo)` | jogador vai tomar dano | multiplicador |
| `ataque_inimigo(atacante, alvo, dano)` | inimigo/animal acertando alguém | multiplicador |
| `derrotou(p, alvo)` | jogador derrotou alvo | — |
| `velocidade(p)` | no DONO, ao andar | multiplicador |
| `recarga(p, hab)` / `custo_mana(p, hab)` | ao lançar | multiplicador |
| `processar(p, delta)` | todo quadro, anfitrião | — |

```gdscript
# passivas_mago.gd — Frio que morde
static func ataque_inimigo(atacante: Node, _alvo: Node, _dano: float) -> float:
	var e := EfeitosEstado.de(atacante)
	var mago := e.origem(EfeitosEstado.LENTIDAO) as Player if e else null
	return 0.85 if mago and mago.tem(&"frio_que_morde") else 1.0
```

## 6. Regras que continuam valendo
- Nada de arte desenhada por código: efeitos só da tabela de `Efeito` (giro, poeira,
  congelar, explosao, subir_nivel, escudo, furia, raio, nova_gelo) via `World.efeito_todos`,
  `World.efeito_preso_todos` e `World.efeito_laco_todos`, ou receitas Pixelbolt novas em
  `art/fx_receitas/`. Arte de invocação/companheiro e peças de habilidade: `Efeito.PECAS` e `Invocacao.desenho` (pedido L33). Peças andando: `World.efeito_movel_todos`.
- O anfitrião muda o estado; o cliente só pede (as lógicas já rodam no anfitrião).
- Commits pequenos em português; sem `git push`.
