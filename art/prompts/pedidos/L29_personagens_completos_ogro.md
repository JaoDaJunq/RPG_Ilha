# L29 · Personagens completos do Ogro

**Por quê (01/11):** cada combinação de raça e classe é um personagem completo, montado no jogo por cabeça, tronco, mão e pé. A arma da classe continua sendo um item separado na mão.

**Este pedido cobre só o Ogro:** Guerreiro, Mago, Arqueiro, Ladino e Clérigo. São duas folhas por classe (10 ao todo), cada folha gerada e conferida antes da próxima.

## Regras para todas as folhas

**Anexar em cada folha de perfil, nesta ordem:**

1. `art/sprites/tiny/bonecos/l24_ogro_base_perfil.png` — rosto, pele, cabelo, proporções, mão e pé do Ogro.
2. A referência de roupa Ogro correspondente da tabela abaixo — identidade visual e detalhes de classe.
3. `art/sprites/tiny/referencias/estilo_ilustracao.png` — acabamento de ilustração lisa.
4. `art/prompts/reguas/personagens_4x.png` — régua de forma e acabamento Tiny Swords.

**Em cada folha de frente e costas, anexar nesta ordem:**

1. A folha de perfil recém-gerada da mesma classe — manter o mesmo personagem, roupa, cores, escala e traço.
2. A referência de roupa Ogro correspondente da tabela abaixo — manter detalhes de frente e costas.
3. `art/sprites/tiny/referencias/estilo_ilustracao.png`.
4. `art/prompts/reguas/personagens_4x.png`.

**Formato comum:** imagem 1536 × 1024 px, grade regular 3 × 2 de células 512 × 512 px, fundo sólido #FF00FF. Uma figura/peça centralizada em cada célula ocupada, com folga. Personagem completo com cerca de 360 px de altura. As peças isoladas têm exatamente o tamanho da parte equivalente no personagem montado.

**FAÇA:**

- Ilustração 2D lisa, sem pixel art, com formas simples, cores chapadas e um tom de sombra suave; contorno espesso contínuo #161c2e.
- Mantenha a identidade da referência Ogro: corpo baixo e robusto, pele verde-limão, cabeça grande, orelhas pontudas largas, topete preto curto, sobrancelhas marcadas, olhos simples e duas presas brancas curtas na boca. Punhos verdes e pés pequenos calçados.
- Cabeça já inclui o chapéu, elmo, bandana ou capuz da classe. Tronco já inclui toda roupa e acessórios presos ao corpo. Nenhuma peça de tronco pode conter cabeça, mãos, braços ou pernas.
- As roupas do Mago, Arqueiro e Ladino são sem mangas, com cavas simples. As mãos continuam soltas como peças; não desenhe mangas nem braços.
- Contornos das peças fechados. O fundo magenta aparece nos espaços vazados e fora das peças. Mesma roupa e escala nas vistas de perfil, frente e costas.

**NÃO FAÇA:**

- Não desenhe armas, ferramentas, escudos segurados, objetos nas mãos, efeitos, cenário, chão, sombra projetada, texto, números ou moldura.
- Não desenhe braços; somente mãos soltas ao lado do tronco. Na folha de perfil há uma mão e um pé soltos; no personagem montado podem aparecer duas mãos e dois pés.
- Não faça mangas nas roupas do Mago, Arqueiro e Ladino.
- Não use rosa nem magenta no personagem, não deixe partes cruzarem células e não faça pixel art, textura granulada, degradê, brilho ou detalhe fino em excesso.

**NÃO SIGA:**

- Magenta e grade são apenas fundo e organização: não os desenhe como elementos.
- Não repita a pose de perfil nas folhas de frente/costas. Desenhe frente direta e costas diretas de verdade.
- A régua Tiny Swords serve só para proporção e clareza; não copie qualquer unidade, roupa ou acessório do pacote.
- Não transforme o Ogro em humano: mantenha a pele verde, as orelhas ogrescas e as presas legíveis nas vistas em que o rosto aparece.

## Folha A · Perfil e peças

```text
Crie uma folha 1536 × 1024 px, grade de 3 colunas × 2 linhas de células 512 × 512 px, fundo sólido #FF00FF. Desenhe o Ogro da referência 1 usando o traje da referência 2 e o acabamento da referência 3.

Célula 1 (superior esquerda): Ogro completo de perfil olhando para a DIREITA, parado; cabeça no tronco, dois pés embaixo, duas mãos fechadas verdes soltas sem braços, uma à frente do peito e outra parcialmente atrás do corpo. Sem arma.
Célula 2 (superior centro): só a cabeça completa de perfil para a direita, com topete preto e cobertura da classe. Exatamente o tamanho da cabeça montada na célula 1.
Célula 3 (superior direita): só o tronco completo com roupa, cinto e acessórios presos ao corpo; sem cabeça, braço, mão ou perna. Perfil para a direita e topo reto para encaixe da cabeça. Exatamente o tamanho do tronco montado na célula 1.
Célula 4 (inferior esquerda): um pé calçado de perfil para a direita, do mesmo tamanho que um pé montado na célula 1.
Célula 5 (inferior centro): uma mão fechada verde, com eventual braçadeira/luva que pertença à classe, do mesmo tamanho que a mão montada na célula 1.
Célula 6 (inferior direita): vazia, apenas fundo magenta.

Todas as partes são do mesmo Ogro da célula 1. Peças soltas sem pose diferente, inclinação diferente ou variação de escala. Siga FAÇA, NÃO FAÇA e NÃO SIGA.
```

## Folha B · Frente e costas

```text
Crie uma folha 1536 × 1024 px, grade de 3 × 2 células 512 × 512 px, fundo sólido #FF00FF. Continue exatamente o MESMO Ogro da folha A anexada, usando também a referência de roupa da imagem 2.

Célula 1 (superior esquerda): personagem inteiro DE FRENTE, olhando para quem joga; cabeça sobre tronco, pés lado a lado, mãos verdes soltas dos dois lados. Sem arma.
Célula 2 (superior centro): só a cabeça completa DE FRENTE, com as mesmas feições, topete e cobertura da folha A. Mesmo tamanho da cabeça montada na célula 1.
Célula 3 (superior direita): só o tronco completo DE FRENTE, com a mesma roupa e acessórios, sem cabeça, braços, mãos ou pernas. Mesmo tamanho do tronco montado na célula 1.
Célula 4 (inferior esquerda): o mesmo personagem inteiro DE COSTAS. Mostrar nuca, verso da cobertura da cabeça, traseira da roupa e acessórios. Mesma altura e proporções da célula 1; mãos e pés aparecem, sem braços. Sem arma.
Célula 5 (inferior centro): só a cabeça completa DE COSTAS, mesmo tamanho da cabeça montada na célula 4.
Célula 6 (inferior direita): só o tronco completo DE COSTAS, com todos os detalhes traseiros da roupa, mesmo tamanho do tronco montado na célula 4.

Frente e costas são vistas diretas, sem três quartos. Mantenha as mesmas cores, contorno, escala, corpo e roupa da folha A. Siga FAÇA, NÃO FAÇA e NÃO SIGA.
```

## Fichas e saídas

| Classe | Referência de roupa | Traje e detalhes a preservar | Folha A (perfil) | Folha B (frente e costas) |
|---|---|---|---|---|
| Guerreiro | `art/sprites/tiny/bonecos/l24_ogro_guerreiro_perfil_frente.png` e `l24_ogro_guerreiro_costas.png` | Elmo arredondado de ferro cinza com faixa de couro marrom e abertura para o rosto; cota curta de escamas cinza-esverdeadas, gola e barra vermelho escuro, cinto marrom com fivela dourada. Sem escudo, que não aparece nas folhas de referência. | `art/sprites/tiny/candidatos/l29_ogro_guerreiro_perfil.png` | `art/sprites/tiny/candidatos/l29_ogro_guerreiro_frente_costas.png` |
| Mago | `art/sprites/tiny/bonecos/l24_ogro_mago_perfil_frente.png` e `l24_ogro_mago_costas.png` | Chapéu pontudo azul-escuro de ponta caída para trás, faixa dourada; túnica longa azul-escura sem mangas, com bordas douradas, gola em V e cordão dourado com nó e pontas. | `art/sprites/tiny/candidatos/l29_ogro_mago_perfil.png` | `art/sprites/tiny/candidatos/l29_ogro_mago_frente_costas.png` |
| Arqueiro | `art/sprites/tiny/bonecos/l24_ogro_arqueiro_perfil_frente.png` e `l24_ogro_arqueiro_costas.png` | Capuz verde-musgo em volta do rosto; colete marrom sem mangas com tiras de couro cruzadas e cinto com fivela dourada; aljava marrom presa às costas, com três penas claras visíveis. | `art/sprites/tiny/candidatos/l29_ogro_arqueiro_perfil.png` | `art/sprites/tiny/candidatos/l29_ogro_arqueiro_frente_costas.png` |
| Ladino | `art/sprites/tiny/bonecos/l25_ogro_ladino_perfil_frente.png` e `l25_ogro_ladino_costas.png` | Bandana cinza-escura amarrada atrás, com duas pontas; lenço triangular vermelho escuro; colete cinza-escuro sem mangas e cinto marrom com fivela dourada e duas bainhas pequenas vazias. | `art/sprites/tiny/candidatos/l29_ogro_ladino_perfil.png` | `art/sprites/tiny/candidatos/l29_ogro_ladino_frente_costas.png` |
| Clérigo | `art/sprites/tiny/bonecos/l25_ogro_clerigo_perfil_frente.png` e `l25_ogro_clerigo_costas.png` | Capuz branco-pérola contornado de dourado deixando o rosto livre; túnica azul-clara esverdeada, faixa dourada e pequeno sol dourado no peito. | `art/sprites/tiny/candidatos/l29_ogro_clerigo_perfil.png` | `art/sprites/tiny/candidatos/l29_ogro_clerigo_frente_costas.png` |

## Conferência e entrega

Gerar uma folha por vez e olhar a imagem inteira antes de gerar a próxima. Conferir formato 1536 × 1024, seis células, fundo magenta, identidade da classe, escala igual entre personagem e peças isoladas, continuidade com o mesmo Ogro e ausência de armas. Corrigir e rever qualquer folha com erro antes de prosseguir.

Salvar as dez imagens nos caminhos exatos acima, em `art/sprites/tiny/candidatos/`. São arte candidata para aprovação, não aprovada.
