# L29 · Personagens completos do Humano

**Por quê (01/11):** desistimos das roupas trocáveis. Cada combinação de raça e classe é um personagem completo com cabeça (incluindo cabelo e chapéu/capuz), tronco (incluindo a roupa), mão e pé próprios. O jogo continua montando e animando essas peças; a arma continua sendo um item separado na mão.

**Este pedido cobre só o Humano:** Guerreiro, Mago, Arqueiro, Ladino e Clérigo. São duas folhas por classe (10 folhas ao todo), cada uma gerada e conferida antes de começar a seguinte. Não gerar outras raças.

## Regras para todas as folhas

**Anexar em cada folha de perfil, nesta ordem:**

1. `art/sprites/tiny/bonecos/l24_humano_base_perfil.png` — proporção, rosto, mãos e pés do Humano.
2. A folha de roupa correspondente já existente em `art/sprites/tiny/bonecos/` — identidade e cores da classe; seguir o arquivo indicado na tabela.
3. `art/sprites/tiny/referencias/estilo_ilustracao.png` — acabamento de ilustração lisa.
4. `art/prompts/reguas/personagens_4x.png` — régua de formas e acabamento Tiny Swords.

**Para cada folha de frente e costas, anexar nesta ordem:**

1. A folha de perfil L29 recém-gerada para a mesma classe — manter o MESMO personagem, roupa, cores, tamanho e traço.
2. A folha de roupa L24/L25 correspondente indicada na tabela — detalhe da roupa, em especial costas e acessórios.
3. `art/sprites/tiny/referencias/estilo_ilustracao.png`.
4. `art/prompts/reguas/personagens_4x.png`.

### Formato comum

Cada arquivo mede 1536 × 1024 px: grade regular de 3 colunas × 2 linhas; cada célula mede 512 × 512 px. Fundo sólido magenta `#FF00FF`. Uma figura/peça centralizada por célula, com folga em todos os lados. O personagem completo mede aproximadamente 360 px de altura. As peças isoladas devem ter exatamente o mesmo tamanho e formato que a parte correspondente do personagem completo da mesma vista.

**FAÇA:**

- Ilustração 2D lisa, sem pixel art, no acabamento dos exemplos anexados: formas simples, cores chapadas e um tom de sombra suave; contorno espesso e contínuo `#161c2e`.
- Proporções do Humano da referência: cabeça grande e arredondada, corpo curto, olhos simples, duas mãos fechadas e soltas sem braços, pés curtos e arredondados.
- Faça a cabeça completa com cabelo e cobertura de cabeça da classe; faça o tronco completo com toda a roupa e acessórios presos ao corpo. Não desenhe rosto/cabeça dentro da peça de tronco, nem pernas ou braços.
- Nas roupas de Mago, Arqueiro e Ladino, faça o tronco sem mangas: colete ou túnica com cavas simples. As mãos continuam separadas como peças, sem mangas nem braços entre elas e o tronco.
- Desenhe as partes completas com contorno fechado. Fundo magenta aparece nos espaços vazados e fora das peças.
- O equipamento visual é parte inseparável desta classe. Mantenha a mesma aparência nas três vistas.

**NÃO FAÇA:**

- Não desenhe armas, ferramentas, escudos segurados, objetos nas mãos, efeitos, cenário, chão, sombra projetada, texto, números ou molduras.
- Não desenhe braços; mostre apenas mãos soltas ao lado do tronco. Uma mão e um pé na folha de perfil; duas mãos e dois pés apenas no personagem montado.
- Não faça mangas nas roupas de Mago, Arqueiro e Ladino.
- Não use rosa nem magenta no personagem. Não deixe nada atravessar a borda da célula.
- Não faça pixel art, textura granulada, degradê, brilho ou muitos detalhes finos.

**NÃO SIGA:**

- Não copie o magenta ou a grade como elementos desenhados; eles são só o fundo e o posicionamento da folha.
- Não copie a pose de perfil para a folha de frente e costas: desenhe as vistas pedidas de verdade.
- A régua Tiny Swords serve para escala e clareza; não copie nenhuma unidade, roupa ou acessório dela.

## Folha A · Perfil e peças

```text
Crie uma folha 1536 × 1024 px, grade de 3 × 2 células de 512 × 512 px, fundo sólido #FF00FF. É o personagem completo de classe indicado na ficha da tabela abaixo, no estilo e proporções da imagem 1 e com a roupa da imagem 2.

Célula 1 (superior esquerda): personagem inteiro parado, de perfil olhando para a DIREITA. Cabeça sobre o tronco; os dois pés aparecem embaixo, um um pouco à frente do outro; duas mãos fechadas e soltas, sem braços, uma à frente do peito e outra parcialmente aparecendo atrás. Sem arma.
Célula 2 (superior centro): somente a cabeça completa de perfil para a direita, com cabelo e chapéu/capuz/touca do personagem. Mesmo tamanho exato da cabeça montada na célula 1.
Célula 3 (superior direita): somente o tronco completo com roupa, cinto, bolsas, capas ou acessórios que pertençam ao corpo; sem cabeça, sem braços, sem mãos e sem pernas. Perfil para a direita. Topo reto para encaixe da cabeça. Mesmo tamanho exato do tronco montado na célula 1.
Célula 4 (inferior esquerda): somente um pé calçado, de perfil para a direita, exatamente do tamanho e formato de um pé montado na célula 1.
Célula 5 (inferior centro): somente uma mão fechada, na cor de pele humana e com eventual luva que pertença à classe, exatamente do tamanho e formato de uma mão montada na célula 1.
Célula 6 (inferior direita): vazia, só o fundo magenta.

Respeite os blocos FAÇA, NÃO FAÇA e NÃO SIGA acima. Todas as partes precisam corresponder ao mesmo humano da célula 1; peças isoladas sem pose, sem inclinação diferente e sem variação de escala.
```

## Folha B · Frente e costas

```text
Crie uma folha 1536 × 1024 px, grade de 3 × 2 células de 512 × 512 px, fundo sólido #FF00FF. Continue exatamente o MESMO personagem da folha A anexada, usando também a roupa da outra referência anexada.

Célula 1 (superior esquerda): personagem inteiro DE FRENTE, olhando para quem joga, parado; cabeça sobre o tronco, dois pés lado a lado e mãos soltas dos dois lados do corpo. Sem arma.
Célula 2 (superior centro): somente a cabeça completa DE FRENTE, com o mesmo cabelo e chapéu/capuz/touca; do mesmo tamanho e formato da cabeça montada na célula 1.
Célula 3 (superior direita): somente o tronco completo DE FRENTE, com todos os detalhes da roupa e sem cabeça, braços, mãos ou pernas; exatamente do tamanho do tronco montado na célula 1.
Célula 4 (inferior esquerda): o mesmo personagem inteiro DE COSTAS; vemos a nuca e a parte de trás do chapéu/capuz/touca e a parte de trás da roupa e seus acessórios. Mesma altura e proporções da célula 1. Dois pés e duas mãos visíveis, sem braços. Sem arma.
Célula 5 (inferior centro): somente a cabeça completa DE COSTAS, do mesmo tamanho da cabeça montada na célula 4.
Célula 6 (inferior direita): somente o tronco completo DE COSTAS, com todos os detalhes traseiros da roupa, exatamente do tamanho do tronco montado na célula 4.

Respeite os blocos FAÇA, NÃO FAÇA e NÃO SIGA acima. Frente e costas são vistas diretas, sem virar três quartos; mantenha idênticas a roupa, as cores, o contorno, o tamanho do corpo e os detalhes do personagem da folha A.
```

## Fichas e saídas

| Classe | Referência da roupa a anexar | Traje e detalhes a preservar | Folha A (perfil) | Folha B (frente e costas) |
|---|---|---|---|---|
| Guerreiro | `art/sprites/tiny/bonecos/l24_humano_guerreiro_perfil_frente.png` | Elmo de ferro redondo simples com tira de couro e abertura grande para o rosto e a franja; túnica vermelha escura apagada, cota curta cinza-esverdeada, cinto marrom com fivela; sapatilhas claras. Escudo preso às costas do tronco, visível só onde couber na vista de costas. | `art/sprites/tiny/candidatos/l29_humano_guerreiro_perfil.png` | `art/sprites/tiny/candidatos/l29_humano_guerreiro_frente_costas.png` |
| Mago | `art/sprites/tiny/bonecos/l24_humano_mago_perfil_frente.png` | Chapéu pontudo azul-escuro de ponta caída para trás, faixa dourada; túnica longa azul-escura sem mangas, gola e cordão dourados. | `art/sprites/tiny/candidatos/l29_humano_mago_perfil.png` | `art/sprites/tiny/candidatos/l29_humano_mago_frente_costas.png` |
| Arqueiro | `art/sprites/tiny/bonecos/l24_humano_arqueiro_perfil_frente.png` | Capuz verde-musgo que emoldura o rosto; colete de couro marrom sem mangas sobre túnica verde-musgo; cinto e alça cruzada no peito; aljava presa às costas com três penas visíveis. | `art/sprites/tiny/candidatos/l29_humano_arqueiro_perfil.png` | `art/sprites/tiny/candidatos/l29_humano_arqueiro_frente_costas.png` |
| Ladino | `art/sprites/tiny/bonecos/l25_humano_ladino_perfil_frente.png` | Bandana cinza-escura amarrada na cabeça, duas pontas atrás; colete preto-acinzentado sem mangas; lenço vermelho-escuro no pescoço; cinto com duas bainhas pequenas vazias para adagas. | `art/sprites/tiny/candidatos/l29_humano_ladino_perfil.png` | `art/sprites/tiny/candidatos/l29_humano_ladino_frente_costas.png` |
| Clérigo | `art/sprites/tiny/bonecos/l25_humano_clerigo_perfil_frente.png` | Touca branco-pérola com borda dourada cobrindo cabelo e orelhas e deixando o rosto visível; túnica azul-clara comprida, faixa dourada na cintura, pequeno sol dourado no peito. | `art/sprites/tiny/candidatos/l29_humano_clerigo_perfil.png` | `art/sprites/tiny/candidatos/l29_humano_clerigo_frente_costas.png` |

## Conferência e entrega

Gerar uma folha por vez. Depois de cada geração, conferir a imagem inteira antes da próxima: tamanho 1536 × 1024, seis células, fundo magenta, identidade da classe, três peças com escala coerente e ausência de armas. Se houver erro, corrigir aquela folha e conferi-la novamente.

Salvar somente no caminho exato da tabela, em `art/sprites/tiny/candidatos/`. As imagens são candidatas para apresentação ao João; não tratá-las como arte aprovada.
