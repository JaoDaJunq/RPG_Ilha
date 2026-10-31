# L21 · Os 6 personagens de FRENTE e de COSTAS (peças)

**Por quê (31/10):** o João aprovou os personagens por peças (L19, de perfil). Faltam as vistas de **frente** (andando para baixo) e de **costas** (andando para cima). Os pés e as mãos continuam os mesmos do L19; mudam a cabeça e o tronco.

**Anexar, nesta ordem:**
1. `art/sprites/tiny/bonecos/pecas_<raca>_<classe>.png`: **o personagem aprovado** (L19, de perfil). Copiar as cores, a roupa, o capuz ou elmo, o rosto e o acabamento.
2. `art/sprites/tiny/referencias/estilo_ilustracao.png`: o acabamento da ilustração.
3. `evidence/comparacao/bonecos.png`: como ele fica no jogo.

```text
TAREFA: folha de PEÇAS do MESMO personagem da imagem 1, agora visto de FRENTE e de COSTAS, em ILUSTRAÇÃO 2D limpa (NÃO pixel art), no mesmo acabamento, no estilo de montagem do Forager: corpo sem braços, mãozinhas soltas, pezinhos curtos.
Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512, uma peça por célula, centralizada, com folga. Fundo magenta chapado #FF00FF.
1) O personagem MONTADO DE FRENTE (olhando para quem joga): cabeça, tronco, os dois pezinhos lado a lado embaixo e as duas mãozinhas flutuando dos dois lados do corpo. SEM arma. Cerca de 360 px de altura (o mesmo tamanho do personagem montado da imagem 1).
2) SÓ A CABEÇA DE FRENTE, exatamente do tamanho que tem na célula 1.
3) SÓ O TRONCO DE FRENTE (sem cabeça, braços nem pernas), exatamente do tamanho que tem na célula 1.
4) O personagem MONTADO DE COSTAS (vemos a nuca, o capuz ou elmo por trás e as costas da roupa, com aljava ou escudo nas costas se ele tiver), mesmo tamanho da célula 1.
5) SÓ A CABEÇA DE COSTAS, exatamente do tamanho que tem na célula 4.
6) SÓ O TRONCO DE COSTAS, exatamente do tamanho que tem na célula 4.

FAÇA:
- O MESMO personagem da imagem 1: mesmas cores, roupa, rosto, capuz ou elmo e proporções (cabeça grande e redonda, corpo curto).
- Cores chapadas com UM tom de sombra suave, cores apagadas do Tiny Swords, contorno #161c2e grosso (cerca de 5 px) e uniforme em volta de cada peça.
- Peças inteiras e fechadas, cada uma com o contorno completo.

NÃO FAÇA:
- NÃO desenhe arma, ferramenta, escudo na mão nem nada segurado.
- NÃO desenhe braços: só as mãozinhas soltas.
- NÃO mude o tamanho das peças entre o personagem montado e as peças soltas.
- NÃO desenhe pixel art, sombra no chão, chão, cenário, texto ou moldura.
- NÃO deixe nada passar da linha da célula.
- No ogro: as presas saem da BOCA (lábio de baixo, para cima).

NÃO SIGA:
- NÃO siga a vista de perfil da imagem 1: aqui é de frente e de costas.
```

## Saídas (uma folha por personagem)

| Arquivo | Anexo 1 |
|---|---|
| `art/sprites/tiny/candidatos/frente_costas_humano_guerreiro.png` | `pecas_humano_guerreiro.png` |
| `art/sprites/tiny/candidatos/frente_costas_humano_mago.png` | `pecas_humano_mago.png` |
| `art/sprites/tiny/candidatos/frente_costas_humano_arqueiro.png` | `pecas_humano_arqueiro.png` |
| `art/sprites/tiny/candidatos/frente_costas_ogro_guerreiro.png` | `pecas_ogro_guerreiro.png` |
| `art/sprites/tiny/candidatos/frente_costas_ogro_mago.png` | `pecas_ogro_mago.png` |
| `art/sprites/tiny/candidatos/frente_costas_ogro_arqueiro.png` | `pecas_ogro_arqueiro.png` |

Salvar só nesses caminhos. Não mexer em `game/` nem em nenhum outro arquivo. Responder com os caminhos e o tamanho de cada imagem.
