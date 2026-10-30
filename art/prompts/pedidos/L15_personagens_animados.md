# L15 · Os 6 personagens com animação (ilustração para pixelizar)

**Base aprovada pelo João (30/10):** a comparação `evidence/comparacao/teste_pixelizado.png`, com os dois primeiros embaixo: ilustração da IA transformada em pixel art aqui por `game/tools/pixelizar.gd`, na densidade do Tiny Swords. Ele também aprovou o acampamento do L14.

**Por que ilustração e não pixel art:** quando se pede pixel art, a IA sempre engrossa o pixel (L13, L13b). A ilustração vira pixel art na conversão:
- ela é reduzida para ~88 pixels de altura;
- as cores trocam pelas da paleta do pacote;
- a borda recebe o contorno do pacote.

**Uma folha por personagem** (6 folhas), com os quadros da animação.

**Anexar, nesta ordem:**
1. `art/sprites/desenho_hd/candidatos/hd_v1.png`: **acabamento do desenho** (traço, cor chapada, contorno grosso).
2. `art/prompts/reguas/personagens_4x.png`: **proporções e pose** do Tiny Swords (cabeça grande e redonda, corpo curto e roliço, perninhas curtas, de perfil para a direita).
3. `art/sprites/tiny/candidatos/personagens_base_v1.png`: **quem é cada um** (roupa, cores, objeto na mão). Célula indicada na tabela.
4. `evidence/comparacao/teste_pixelizado.png`: o resultado aprovado depois da conversão (os dois primeiros embaixo).

```text
TAREFA: uma folha de animação de UM personagem (o da célula N da imagem 3), em ILUSTRAÇÃO 2D limpa (NÃO pixel art), no acabamento da imagem 1, com as proporções das unidades do Tiny Swords da imagem 2. Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512, UM quadro por célula, na ordem:
1) PARADO, de perfil olhando para a direita.
2) PARADO RESPIRANDO: igual ao 1, com o corpo 3% mais baixo e os ombros um pouco para baixo.
3) ANDANDO, passo A: perna da frente esticada para a frente, perna de trás para trás, braços balançando ao contrário.
4) ANDANDO, passo B: o contrário do passo A (a outra perna na frente).
5) GOLPE, preparação: o objeto da mão puxado para trás e para cima (espada, porrete ou cajado levantado; arco puxado com a flecha na corda).
6) GOLPE, ataque: o objeto à frente no fim do golpe (espada ou porrete descendo na frente; cajado apontado para a frente; flecha acabando de sair do arco).

FAÇA:
- O MESMO personagem em todos os quadros: mesma roupa, cores, rosto, tamanho e proporções. Só muda a pose.
- Mesmo tamanho em todos os quadros: corpo com cerca de 380 px de altura em pé, os pés sempre na mesma linha, 40 px acima do fundo da célula, centralizado. A cabeça tem o mesmo tamanho em todos os quadros.
- De PERFIL olhando para a DIREITA em todos os quadros.
- Proporções do Tiny Swords: cabeça grande e redonda (quase metade da altura), corpo curto e roliço, perninhas curtas, mãos redondas.
- Cores chapadas com UM tom de sombra suave (cel shading), cores apagadas como as do Tiny Swords, contorno #161c2e grosso (cerca de 5 px) e uniforme em volta de tudo e entre as partes.
- Formas grandes e simples, poucos detalhes, rosto simples (olhos pequenos escuros, boca pequena).

NÃO FAÇA:
- NÃO desenhe pixel art nem "cara de pixel": é ilustração lisa (a gente transforma em pixel depois).
- NÃO use degradê forte, brilho, textura, ruído, hachura nem pintura realista.
- NÃO desenhe de frente nem de costas.
- NÃO desenhe rastro, linha de velocidade, brilho de magia, poeira, flecha voando longe, sombra no chão, chão, cenário, texto, número ou moldura (o jogo faz os efeitos).
- NÃO deixe partes finas demais (dedos, cordas, cabo fino): elas somem quando o desenho fica pequeno. Tudo grosso e legível.
- NÃO mude o tamanho do personagem entre os quadros, nem a altura dos pés.
- NÃO encoste na borda da célula; nada atravessa para a célula vizinha (golpe compacto, dentro da célula).
- No ogro: as presas saem da BOCA (lábio de baixo, apontando para cima); NADA de marcas brancas embaixo dos olhos.

NÃO SIGA:
- NÃO siga o estilo pixelado nem o tamanho do pixel da imagem 3 (ela serve só para saber quem é o personagem).
- NÃO siga a pose de frente da imagem 1 (ela serve só para o acabamento).
- NÃO siga anime nem "chibi de olhos enormes": rosto simples como o do Tiny Swords.
```

## Saídas (uma folha por personagem, mesmo texto, trocando a célula)

| Arquivo | Personagem (célula de `personagens_base_v1.png`) |
|---|---|
| `art/sprites/tiny/candidatos/anim_humano_guerreiro.png` | 1: Humano Guerreiro (elmo aberto com pluma azul, túnica azul, escudo redondo de madeira com borda de aço, espada curta) |
| `art/sprites/tiny/candidatos/anim_humano_mago.png` | 2: Humano Mago (capuz azul-escuro com borda dourada, mechas castanhas, túnica azul longa, cajado com pedra azul) |
| `art/sprites/tiny/candidatos/anim_humano_arqueiro.png` | 3: Humano Arqueiro (capuz de couro marrom, túnica verde-musgo apagada, arco curto, aljava) |
| `art/sprites/tiny/candidatos/anim_ogro_guerreiro.png` | 4: Ogro Guerreiro (pele verde-acinzentada, mais largo, presas da boca, ombreira de aço, saiote vermelho-escuro, porrete) |
| `art/sprites/tiny/candidatos/anim_ogro_mago.png` | 5: Ogro Mago (pele e presas do ogro, capuz e túnica azul-escuros com borda dourada, cajado com pedra azul) |
| `art/sprites/tiny/candidatos/anim_ogro_arqueiro.png` | 6: Ogro Arqueiro (pele e presas do ogro, capuz e colete de couro MARROM, arco curto, aljava) |

## Depois de gerar

Salvar só nos seis caminhos acima. Não mexer em `game/` nem em nenhum outro arquivo. Responder com os caminhos e o tamanho em pixels de cada imagem.
