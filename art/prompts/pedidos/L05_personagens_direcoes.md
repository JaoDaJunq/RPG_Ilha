# L05 · Personagens: costas, perfil e caminhada (6 personagens)

**Base aprovada:** `art/sprites/personagens/personagens_v1.png` (L03, aprovado pelo João em 29/10/2026). Agora cada um dos 6 personagens ganha uma folha com as outras direções e a caminhada.

**Correção pedida pelo João no Ogro:** o Ogro tem **duas presinhas brancas** saindo do lábio de baixo (como no teste de camadas `art/sprites/personagens/camadas_v1.png`, célula 4) e **sem** os brilhos brancos embaixo dos olhos.

**Anexar em todos:** `art/sprites/personagens/personagens_v1.png` (o personagem aprovado: copiar exatamente roupa, cores, rosto e tamanho de pixel) e `evidence/importacao/L03_L04_L02/personagens.png` (como eles ficam no tamanho do jogo).

**Regras (copiar no começo de cada geração):**

```text
PIXEL ART MINIMALISTA e FOFA, igual ao personagem aprovado anexado: mesmo tamanho, mesmas cores, mesmo rosto, mesma roupa, mesmo contorno e o MESMO TAMANHO DE PIXEL (os quadrados grandes da imagem anexada). Personagem com cerca de 32 pixels de altura, cabeça grande, poucas cores, sem detalhes miúdos.
Imagem 1536x1024 com grade de 3 colunas x 2 linhas (cada célula 512x512). Cada célula é UM quadro do personagem, centralizado, com os pés na mesma linha em todas as células, perto da borda de baixo. Fundo magenta chapado #FF00FF. Sem arma na mão. Proibido: chão, sombra, efeitos, texto, grade desenhada, moldura.
Células: 1) parado de COSTAS (olhando para cima, vemos o cabelo/capuz e as costas da roupa); 2) parado de PERFIL olhando para a DIREITA; 3) andando de FRENTE, pé esquerdo à frente; 4) andando de FRENTE, pé direito à frente; 5) andando de PERFIL para a direita, pernas abertas no meio do passo; 6) andando de COSTAS, um pé à frente.
O personagem é idêntico em todas as células; só muda a direção e a pose.
```

## Saídas (uma imagem por personagem, mesmo pedido, trocando só o personagem)

| Arquivo | Personagem (célula do anexo `personagens_v1.png`) |
|---|---|
| `art/sprites/personagens/candidatos/humano_guerreiro_v1.png` | 1: Humano Guerreiro |
| `art/sprites/personagens/candidatos/humano_mago_v1.png` | 2: Humano Mago |
| `art/sprites/personagens/candidatos/humano_arqueiro_v1.png` | 3: Humano Arqueiro |
| `art/sprites/personagens/candidatos/ogro_guerreiro_v1.png` | 4: Ogro Guerreiro (com presinhas, sem brilho embaixo dos olhos) |
| `art/sprites/personagens/candidatos/ogro_mago_v1.png` | 5: Ogro Mago (idem) |
| `art/sprites/personagens/candidatos/ogro_arqueiro_v1.png` | 6: Ogro Arqueiro (idem) |

Na geração de cada um, escrever no prompt qual personagem é ("o personagem da célula N do anexo: ...").

## Depois de gerar

Salvar só nos seis caminhos acima. Não mexer em `game/` nem em nenhum outro arquivo. Responder com os caminhos e o tamanho em pixels de cada imagem.
