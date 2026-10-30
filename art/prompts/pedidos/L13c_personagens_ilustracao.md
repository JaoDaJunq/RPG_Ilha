# L13c · Os 6 personagens como ILUSTRAÇÃO, para virar pixel art aqui

**Por quê (30/10):** a IA não consegue desenhar pixel art com o pixel fino do Tiny Swords (~88 pixels de altura por personagem):
- no L13, com 6 por folha, ela desenhou com pixel 2x mais grosso;
- no L13b, com 1 por imagem, desenhou com pixel AINDA mais grosso (~30 pixels de altura).

Mas ela desenha muito bem ilustração limpa (teste L10). A ferramenta `game/tools/pixelizar.gd`:
- reduz a ilustração para 88 pixels de altura;
- troca as cores pelas da paleta do pacote;
- põe o contorno do pacote e a sombra.

O teste com o Mago e o Ogro do L10 ficou na mesma densidade do pacote (`evidence/comparacao/teste_pixelizado.png`, os dois primeiros embaixo). Por isso o pedido agora é de ILUSTRAÇÃO, de perfil.

**Anexar, nesta ordem:**
1. `art/sprites/desenho_hd/candidatos/hd_v1.png`: **estilo do desenho** (traço, cor chapada, contorno). Copiar o acabamento.
2. `art/prompts/reguas/personagens_4x.png`: **proporções e pose** do Tiny Swords (cabeça grande e redonda, corpo curto e roliço, perninhas curtas, de perfil para a direita).
3. `art/sprites/tiny/candidatos/personagens_base_v1.png`: **quem é cada um** (roupa, cores, objeto na mão, mesma ordem das células).

```text
TAREFA: 6 personagens em ILUSTRAÇÃO 2D limpa (NÃO pixel art), no acabamento da imagem 1 anexada (hd_v1.png), com as proporções e a pose das unidades da imagem 2 (Tiny Swords), sendo os personagens da imagem 3 (mesma ordem). Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512, um personagem por célula.

FAÇA:
- Personagem de PERFIL olhando para a DIREITA, parado, como as unidades da imagem 2.
- Proporções do Tiny Swords: cabeça grande e redonda (quase metade da altura), corpo curto e roliço, perninhas curtas, mãos redondas. Todos com a MESMA altura: cerca de 380 px, com os pés numa linha 40 px acima do fundo da célula, centralizados.
- Cores chapadas com UM tom de sombra suave (cel shading), cores apagadas como as do Tiny Swords, contorno escuro azul-acinzentado (#161c2e) uniforme e grosso (cerca de 5 px) em volta de tudo e entre as partes.
- Formas grandes e simples, poucos detalhes: rosto com olhos simples (pontos escuros ou olhos redondos pequenos), boca pequena.
- Os mesmos 6 personagens da imagem 3, mesmas roupas, cores e objetos:
  1) Humano Guerreiro: elmo de aço aberto com pluma azul, túnica azul, escudo redondo de madeira com borda de aço, espada curta.
  2) Humano Mago: capuz azul-escuro com borda dourada, mechas castanhas, túnica azul até o chão, cajado com pedra azul.
  3) Humano Arqueiro: capuz de couro marrom, túnica verde-musgo apagada, arco curto, aljava nas costas.
  4) Ogro Guerreiro: pele verde-acinzentada, corpo mais largo (mesma altura), 2 presas brancas pequenas saindo do lábio de BAIXO apontando para cima, sem capacete, ombreira de aço, saiote vermelho-escuro, porrete de madeira.
  5) Ogro Mago: mesma pele e presas, capuz e túnica azul-escuros com borda dourada, cajado com pedra azul.
  6) Ogro Arqueiro: mesma pele e presas, capuz e colete de couro MARROM, arco curto e aljava.

NÃO FAÇA:
- NÃO desenhe pixel art, nem "cara de pixel": é ilustração lisa, de traço limpo (a gente transforma em pixel depois).
- NÃO use degradê forte, brilho, textura, ruído, hachura nem pintura realista.
- NÃO desenhe de frente nem de costas: só de perfil para a direita.
- NÃO desenhe sombra no chão, chão, cenário, efeitos, texto, número ou moldura.
- NÃO deixe partes finas demais (dedos, cordas, pontas): elas somem quando o desenho fica pequeno. Tudo grosso e legível.
- NÃO desenhe marcas brancas embaixo dos olhos do ogro: as presas saem da BOCA.
- NÃO encoste na borda da célula; nada atravessa para a célula vizinha.

NÃO SIGA:
- NÃO siga o tamanho do pixel nem o estilo pixelado da imagem 3 (ela serve só para saber quem é cada um).
- NÃO siga a pose de frente da imagem 1 (ela serve só para o acabamento do traço e da cor).
- NÃO siga anime nem "chibi de olhos enormes": rosto simples como o do Tiny Swords.
```

## Depois de gerar

Salvar só em `art/sprites/tiny/candidatos/personagens_ilustracao_v1.png`. Não mexer em `game/` nem em nenhum outro arquivo. Responder com o caminho e o tamanho em pixels da imagem.
