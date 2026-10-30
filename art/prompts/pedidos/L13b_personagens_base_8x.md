# L13b · Os 6 personagens, um por imagem, em 8x (pixel igual ao do pacote)

**Por quê:** no L13 os 6 personagens saíram bons de forma, mas com o pixel 2x maior que o do Tiny Swords. O Codex desenhou com quadrados de ~8,5 px numa célula pequena, e o personagem ficou com ~40 pixels de altura; os do pacote têm ~88. Comparação: `evidence/comparacao/l13_personagens_v1.png` (em cima o pacote, embaixo o L13).

**Solução:** um personagem por imagem, 1024x1024, num quadro de 128x128 pixels de jogo ampliado EXATAMENTE 8x. Assim o personagem tem ~88 pixels de jogo de altura, com quadrados de 8x8: a mesma densidade do pacote.

**Anexar, nesta ordem:**
1. `art/prompts/reguas/personagens_4x.png`: a RÉGUA do estilo do pacote (está em 4x; o pedido é em 8x, então cada quadrado nosso tem o DOBRO do tamanho de um quadrado da régua, e o personagem fica do dobro do tamanho na imagem).
2. `art/sprites/tiny/candidatos/personagens_base_v1.png`: o desenho APROVADO de forma de cada personagem (célula indicada). Redesenhar o MESMO personagem, com o dobro de pixels.
3. `evidence/comparacao/l13_personagens_v1.png`: em cima o pacote (certo); embaixo o L13 (forma certa, pixel grosso demais).

```text
TAREFA: redesenhar UM personagem (o da célula N da folha anexada personagens_base_v1.png) no MESMO estilo do pacote Tiny Swords da régua anexada, agora com o DOBRO de pixels. Imagem 1024x1024 = UM quadro de 128x128 pixels de jogo ampliado EXATAMENTE 8x: cada pixel do jogo é um quadrado de 8x8, todos alinhados numa grade que começa no canto (0,0).

FAÇA:
- O personagem tem cerca de 88 pixels de jogo de altura (704 px na imagem) e cerca de 64 de largura, com os pés a 16 pixels de jogo do fundo (a base dos pés em y=896 na imagem), centralizado.
- O MESMO personagem da célula indicada: mesma roupa, mesmas cores, mesma pose, mesmo objeto na mão, de perfil olhando para a direita. Só com mais pixels: mais acabamento nas bordas, nas dobras e no rosto, como as unidades da régua.
- Contorno de 1 pixel de jogo (8 px na imagem), cor #161c2e, em volta de tudo e entre as partes.
- Sombreamento em 2 ou 3 tons por material, luz de cima à esquerda, cores apagadas do pacote: #161c2e #485884 #4c5c8b #4697ac #9cbeaa #688c8a #c8a876 #efe1ab #977b6b #5e5455 #924159 #8d4848 #e76161 #cf9c71 #cea554 #44a079 #699157 #6e7e53 #ffffff.
- Proporções da régua: cabeça grande e redonda, corpo curto e roliço, perninhas curtas.

NÃO FAÇA:
- NÃO use quadrado maior nem menor que 8x8 na imagem; NÃO misture tamanhos.
- NÃO desenhe o personagem pequeno: ele ocupa ~70% da altura da imagem.
- NÃO use contorno preto puro, nem contorno com 2 ou mais pixels de jogo.
- NÃO use degradê, borrado, anti-aliasing, brilho nem textura de ruído.
- NÃO desenhe sombra no chão (o jogo coloca), chão, cenário, efeitos, texto ou moldura.
- NÃO mude a roupa, as cores nem o objeto da mão do personagem da célula indicada.
- No ogro: as presas saem da BOCA (lábio de baixo, apontando para cima); NADA de marcas brancas embaixo dos olhos.

NÃO SIGA:
- NÃO siga a fileira de baixo da imagem de comparação no tamanho do pixel (ali o pixel ficou grosso demais): siga a régua.
- NÃO siga "pixel art de RPG genérico" nem anime.
```

## Saídas (uma imagem por personagem, mesmo texto, trocando a célula)

| Arquivo | Célula de `personagens_base_v1.png` |
|---|---|
| `art/sprites/tiny/candidatos/base_humano_guerreiro.png` | 1: Humano Guerreiro |
| `art/sprites/tiny/candidatos/base_humano_mago.png` | 2: Humano Mago |
| `art/sprites/tiny/candidatos/base_humano_arqueiro.png` | 3: Humano Arqueiro |
| `art/sprites/tiny/candidatos/base_ogro_guerreiro.png` | 4: Ogro Guerreiro |
| `art/sprites/tiny/candidatos/base_ogro_mago.png` | 5: Ogro Mago |
| `art/sprites/tiny/candidatos/base_ogro_arqueiro.png` | 6: Ogro Arqueiro |

## Depois de gerar

Salvar só nos seis caminhos acima. Não mexer em `game/` nem em nenhum outro arquivo. Responder com os caminhos e o tamanho em pixels de cada imagem.
