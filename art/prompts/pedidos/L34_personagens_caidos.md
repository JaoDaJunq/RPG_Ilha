# L34 · Personagem caído (os 20 personagens)

**Por quê (12/11/2026):** o João quer que o personagem caia no chão quando a vida acaba (tela de morte, 8 s até reviver). Precisa do desenho de cada personagem caído.

**Mesmo processo do L30/L31** (ilustração lisa, depois o `pixelizar.gd`). Para o personagem não mudar de tamanho na conversão, cada personagem ocupa DUAS células: em pé (cópia do quadro 1 do perfil) e caído.

**Anexar:**
1. As folhas de PERFIL dos personagens da folha (`art/sprites/tiny/candidatos/l30_<raca>_guerreiro_perfil.png` e `l31_<raca>_<classe>_perfil.png`): o MESMO traço, cores, roupa, rosto e tamanho.
2. `art/sprites/tiny/referencias/estilo_ilustracao.png`.

## Texto

```text
TAREFA: folha de ILUSTRAÇÃO 2D limpa (NÃO pixel art), no MESMO acabamento e tamanho das folhas de perfil anexadas (imagens 1). Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512, fundo magenta chapado #FF00FF.
Para cada personagem da lista, duas células lado a lado:
 a) EM PÉ: cópia exata do quadro 1 (parado) do perfil dele, olhando para a direita, ~380 px de altura, pés 40 px acima do fundo da célula.
 b) CAÍDO: o MESMO personagem, no MESMO tamanho, deitado de costas no chão, de perfil (cabeça à direita, pés à esquerda), olhos fechados (dois risquinhos), braços largados, MÃOS VAZIAS. O corpo encostado 40 px acima do fundo da célula. O chapéu, o elmo ou o capuz continuam na cabeça.

FAÇA:
- O MESMO personagem das imagens 1: roupa, cores, rosto, cabelo, proporções e contorno #161c2e grosso (~5 px).
- Cores chapadas com um tom de sombra suave.

NÃO FAÇA:
- NÃO desenhe arma, sangue, ferida, estrelinhas, fantasma, chão, sombra, texto ou moldura.
- NÃO mude o tamanho do personagem entre a célula em pé e a caída.
- NÃO encoste na borda da célula.
```

## Folhas (em `art/sprites/tiny/candidatos/`)

Para cada raça (humano, ogro, elfo, anao), duas folhas:

| Saída | Células 1-2 | Células 3-4 | Células 5-6 |
|---|---|---|---|
| `l34_<raca>_caidos_1.png` | guerreiro | mago | arqueiro |
| `l34_<raca>_caidos_2.png` | ladino | clerigo | vazias |

(Na grade, as células 1-2-3 são a linha de cima e 4-5-6 a de baixo: o par "a, b" de cada personagem vai na ordem 1-2, 3-4, 5-6.)

Salvar só nos caminhos acima. Não mexer em `game/` nem em nenhum outro arquivo.
