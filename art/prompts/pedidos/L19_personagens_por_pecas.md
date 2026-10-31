# L19 · Os 6 personagens por peças (estilo Forager: corpo, cabeça, pés e mãozinhas soltas)

**Por quê (31/10):** o João quer os personagens montados por peças, como no Forager:
- cabeça, tronco e pezinhos;
- duas mãozinhas redondas soltas do lado do corpo, sem braço.

Assim o item da barra (machado, espada, tocha, cajado...) vai na mão, e a animação é feita no jogo movendo as peças. Hoje a arma está desenhada junto no personagem (L15) e não dá para trocar.

**Mesmo caminho que deu certo no L15:** ILUSTRAÇÃO lisa, que o jogo transforma em pixel art na densidade do Tiny Swords (`game/tools/pixelizar.gd`). A célula 1 é o personagem montado e serve de RÉGUA de tamanho: as peças das outras células têm de ter EXATAMENTE o mesmo tamanho que têm na célula 1.

**Anexar, nesta ordem:**
1. `art/sprites/tiny/personagens/anim_<raca>_<classe>.png`: **o personagem aprovado** (L15). Copiar o rosto, as cores, a roupa, o capuz ou elmo e o acabamento do traço. **Sem a arma.**
2. `art/sprites/tiny/referencias/estilo_ilustracao.png`: o acabamento da ilustração (traço, cor chapada, contorno).
3. `evidence/comparacao/l15_parados.png`: como ele fica depois de virar pixel art no jogo (fileira de baixo).

```text
TAREFA: folha de PEÇAS SEPARADAS de UM personagem (o da imagem 1 anexada), em ILUSTRAÇÃO 2D limpa (NÃO pixel art), no mesmo acabamento das imagens 1 e 2, no estilo de montagem do jogo Forager: o corpo NÃO tem braços; as mãos são duas bolinhas soltas que flutuam ao lado do corpo; as pernas são dois pezinhos curtos e redondos.
Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512, UMA peça por célula, centralizada, com bastante folga em volta. Fundo magenta chapado #FF00FF.

Células:
1) O PERSONAGEM MONTADO, de perfil olhando para a DIREITA, parado: cabeça em cima do tronco, os dois pezinhos embaixo, a mãozinha da frente flutuando à frente do peito e a de trás aparecendo atrás do corpo. SEM arma e SEM nada na mão. Cerca de 360 px de altura. Esta é a régua de tamanho das outras células.
2) SÓ A CABEÇA (com o cabelo, o capuz ou o elmo), de perfil para a direita, EXATAMENTE do mesmo tamanho que na célula 1.
3) SÓ O TRONCO (a roupa, o cinto e o que fica nas costas, como aljava ou capa), sem cabeça, sem braços e sem pernas, de perfil para a direita, EXATAMENTE do mesmo tamanho que na célula 1. A parte de cima do tronco é reta (a cabeça encaixa por cima).
4) SÓ UM PÉ: um pezinho curto e redondo com a bota ou o sapato, de perfil para a direita, EXATAMENTE do mesmo tamanho que na célula 1.
5) SÓ UMA MÃO: uma bolinha fechada (punho) da cor da pele, ou com a luva do personagem, EXATAMENTE do mesmo tamanho que na célula 1.
6) vazia (só o fundo magenta).

FAÇA:
- O MESMO personagem da imagem 1: mesmo rosto, cores, roupa, capuz ou elmo, proporções e acabamento.
- Cores chapadas com UM tom de sombra suave (cel shading), cores apagadas do Tiny Swords, contorno #161c2e grosso (cerca de 5 px) e uniforme em volta de cada peça.
- Peças inteiras e fechadas, cada uma com o contorno completo em volta (vão ser montadas pelo jogo).
- Formas grandes e simples; nada fino demais.

NÃO FAÇA:
- NÃO desenhe arma, ferramenta, cajado, arco, escudo, flecha na mão, nem nada segurado.
- NÃO desenhe braços: só as mãozinhas soltas.
- NÃO mude o tamanho das peças entre a célula 1 e as outras.
- NÃO desenhe pixel art nem "cara de pixel": é ilustração lisa.
- NÃO desenhe sombra no chão, chão, cenário, efeitos, texto, número ou moldura.
- NÃO encoste na borda da célula; nada atravessa para a célula vizinha.
- No ogro: as presas saem da BOCA (lábio de baixo, para cima); nada de marcas embaixo dos olhos.

NÃO SIGA:
- NÃO siga a arma nem o braço da imagem 1 (só a cabeça, a roupa e as cores).
- NÃO siga o visual do Forager (só a ideia das mãozinhas soltas e dos pezinhos); o estilo é o das imagens 1 e 2.
```

## Saídas (uma folha por personagem, mesmo texto, trocando o anexo 1)

| Arquivo | Anexo 1 (personagem aprovado) |
|---|---|
| `art/sprites/tiny/candidatos/pecas_humano_guerreiro.png` | `anim_humano_guerreiro.png` (elmo de aço com pluma azul, túnica azul; o escudo vai NAS COSTAS do tronco) |
| `art/sprites/tiny/candidatos/pecas_humano_mago.png` | `anim_humano_mago.png` (capuz azul-escuro com borda dourada, mechas castanhas, túnica azul) |
| `art/sprites/tiny/candidatos/pecas_humano_arqueiro.png` | `anim_humano_arqueiro.png` (capuz de couro marrom, túnica verde-musgo; aljava nas costas do tronco) |
| `art/sprites/tiny/candidatos/pecas_ogro_guerreiro.png` | `anim_ogro_guerreiro.png` (pele verde, presas, ombreira de aço, saiote vermelho-escuro) |
| `art/sprites/tiny/candidatos/pecas_ogro_mago.png` | `anim_ogro_mago.png` (pele verde, presas, capuz e túnica azul-escuros com borda dourada) |
| `art/sprites/tiny/candidatos/pecas_ogro_arqueiro.png` | `anim_ogro_arqueiro.png` (pele verde, presas, capuz e colete de couro marrom; aljava nas costas) |

## Depois de gerar

Salvar só nos seis caminhos acima. Não mexer em `game/` nem em nenhum outro arquivo. Responder com os caminhos e o tamanho em pixels de cada imagem.
