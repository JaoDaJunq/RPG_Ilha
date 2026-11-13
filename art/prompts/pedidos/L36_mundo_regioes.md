# L36 · O mundo maior: peças das 6 regiões

**Por quê (13/11/2026):** o João aprovou a proposta do mundo maior (`design/proposta_mundo.md`). A ilha fica ~6 vezes maior, com 6 regiões: Clareira, Bosque Florido, Praia das Conchas, Pântano dos Cogumelos, Colinas de Pedra e Ruínas dos Guardiões. O pacote Tiny Swords já dá a grama (5 tons), as árvores, os arbustos, as pedras e a água. Faltam as peças abaixo.

**Anexar em todas as folhas:**
1. A régua do tamanho da folha (indicada em cada folha):
   - `art/prompts/reguas/objetos_4x.png` (células de 512x512);
   - `art/prompts/reguas/arvores_altas_4x.png` (células de 768x1024);
   - `art/prompts/reguas/largas_4x.png` (células de 1536x512).
2. `art/sprites/tiny/acampamento_v2.png`: os nossos objetos aprovados.

**Regras (copiar no começo do texto):**

```text
FAÇA:
- Pixel art no MESMO estilo da régua (Tiny Swords) e do acampamento anexados: quadrados de 4x4 na imagem (cada 4 px da imagem = 1 pixel de jogo), contorno de 1 pixel #161c2e, 2 ou 3 tons por material, luz de cima à esquerda, vistos de cima em 3/4, cores apagadas e frias do Tiny Swords.
- Imagem 1536x1024 na grade pedida, UMA peça por célula, centralizada, base 32 px acima do fundo da célula. Fundo magenta chapado #FF00FF.
- Medidas em PIXELS DE JOGO (na imagem, multiplique por 4). Um personagem nosso tem ~22 de altura; a ovelha da régua ~40 de largura; o pinheiro da régua ~120 x 190.
- Formas redondinhas e simples, legíveis de longe.

NÃO FAÇA:
- NÃO use quadrados de tamanhos diferentes, degradê, borrado ou anti-aliasing.
- NÃO use contorno preto puro nem cores saturadas demais.
- NÃO desenhe chão, grama, sombra no chão, texto ou moldura.
- NÃO encoste na borda da célula.

NÃO SIGA:
- NÃO siga "pixel art de RPG genérico" nem desenho detalhado fino: siga a régua.
```

Célula marcada "vazia": só o fundo magenta.

**Saída:** `art/sprites/tiny/candidatos/l36_<NN>.png` (NN = número da folha). Os terrenos: `art/sprites/tiny/candidatos/l36_<nome>_tilemap.png`.

## Folha 01: coqueiros (régua `arvores_altas_4x.png`; grade 2 colunas x 1 linha, células de 768x1024)
1. COQUEIRO de praia com o tronco curvado para a DIREITA: tronco fino em anéis bege-acinzentados, copa de folhas compridas verdes caídas como estrela, 3 cocos marrons embaixo da copa. ~110 x 200.
2. COQUEIRO mais reto e um pouco mais baixo, tronco levemente curvado para a ESQUERDA, 2 cocos. ~100 x 180.

## Folha 02: árvores das regiões (régua `arvores_altas_4x.png`; 2 colunas x 1 linha, células de 768x1024)
1. ÁRVORE FLORIDA ROSA (cerejeira) do Bosque: mesmo formato da árvore de copa redonda da régua, tronco marrom-acinzentado, copa cheia de flores rosa-claras em 2-3 tons com alguns pontinhos brancos. ~130 x 170.
2. ÁRVORE MORTA DO PÂNTANO: tronco escuro retorcido, galhos secos tortos, sem folhas, musgo verde-azulado pendurado nos galhos. ~110 x 170.

## Folha 03: peças altas das Ruínas (régua `objetos_4x.png`; grade 3 colunas x 1 linha, células de 512x1024)
1. COLUNA DE PEDRA ANTIGA inteira: pedra cinza-azulada com base e topo largos, manchas de musgo verde, uma rachadura. ~36 x 110.
2. ESTÁTUA QUEBRADA DE GUARDIÃO: figura de pedra ajoelhada com capuz, segurando um cajado, sem um braço, coberta de musgo, sobre um pedestal quadrado. ~60 x 100.
3. PEDRA ALTA ENTALHADA (obelisco): pedra de pé com uma espiral e uma folha entalhadas que brilham de leve em verde-água, musgo na base. ~34 x 90.

## Folha 04: Praia das Conchas (régua `objetos_4x.png`; 3 colunas x 2 linhas, células de 512x512)
1. GRUPINHO DE CONCHAS na areia: uma concha espiral bege-rosa e duas conchas leque brancas pequenas. ~26 x 14.
2. ESTRELA-DO-MAR laranja-avermelhada apagada, com pontinhos. ~18 x 16.
3. POÇA DE MARÉ: pocinha de água azul-esverdeada rasa com borda de pedrinhas cinzas e uma alga, vista de cima. ~52 x 30.
4. TRONCO TRAZIDO PELO MAR: tronco claro desbotado deitado na horizontal, galhos curtos, liso. ~56 x 18.
5. PEDRAS COM ALGAS: três pedras cinza-azuladas arredondadas com alga verde escura por cima. ~40 x 26.
6. TOCO DE COQUEIRO: toco baixo de coqueiro, anéis bege-acinzentados, corte claro em cima, umas fibras. ~22 x 22.

## Folha 05: Bosque Florido (régua `objetos_4x.png`; 3 colunas x 2 linhas, células de 512x512)
1. MOITA DE FLORES ROSA: tufo baixo de folhas verdes com várias flores rosa de 5 pétalas. ~30 x 18.
2. MOITA DE FLORES AMARELAS E BRANCAS (margaridas). ~30 x 18.
3. FLORES AZUIS ALTAS (tipo campânula), 3 hastes. ~20 x 24.
4. ARBUSTO DE FRUTINHAS: arbusto redondo verde (como o da régua) com frutinhas vermelhas. ~44 x 36.
5. TRONCO CAÍDO com musgo e duas florzinhas, deitado na horizontal. ~58 x 20.
6. COGUMELOS VERMELHOS de bolinhas brancas, grupinho de 3. ~22 x 18.

## Folha 06: Pântano dos Cogumelos (régua `objetos_4x.png`; 3 colunas x 2 linhas, células de 512x512)
1. COGUMELO GIGANTE que brilha: chapéu largo azul-turquesa com pintas claras brilhantes, pé claro grosso. ~56 x 64.
2. GRUPO DE COGUMELOS ROXOS que brilham (3 de tamanhos diferentes, chapéu roxo-claro com brilho lilás). ~30 x 26.
3. VITÓRIAS-RÉGIAS: três folhas redondas verdes com corte em V, uma flor rosa-clara, vistas de cima (vão em cima da água; sem água desenhada). ~44 x 24.
4. TABOAS: tufo de juncos altos verdes com 3 espigas marrons. ~24 x 40.
5. TOCO PODRE com musgo verde-azulado e cogumelinhos. ~30 x 24.
6. RAIZ RETORCIDA saindo do chão em arco, escura com musgo. ~44 x 22.

## Folha 07: Colinas de Pedra e Ruínas (régua `objetos_4x.png`; 3 colunas x 2 linhas, células de 512x512)
1. ROCHEDO GRANDE cinza-azulado, com faces largas e uma rachadura, um pouco de musgo. ~70 x 56.
2. PEDRAS EMPILHADAS (três pedras redondas equilibradas). ~26 x 36.
3. OSSADA: costelas e crânio de um bicho grande, ossos claros meio enterrados. ~52 x 26.
4. COLUNA QUEBRADA: só a base e um pedaço da coluna de pedra antiga, com musgo, pedaços caídos do lado. ~40 x 38.
5. PEDAÇO DE MURO ANTIGO: muro baixo de blocos de pedra cinza-azulada, quebrado nas pontas, musgo em cima. ~64 x 34.
6. LAJE ENTALHADA no chão: placa de pedra plana e rachada com uma espiral entalhada, vista de cima. ~40 x 24.

## Folha 08: ponte (régua `largas_4x.png`; 1 coluna x 2 linhas, células de 1536x512)
1. PONTE DE MADEIRA inteira, na horizontal (atravessa um rio que corre de cima para baixo): tábuas na vertical lado a lado, duas vigas embaixo, corrimão de corda com postes nas duas bordas (de cima e de baixo). GRANDE: ~350 x 100 (quase a célula inteira na largura; atravessa um rio de 5 blocos).
2. A MESMA PONTE QUEBRADA: o meio caiu (falta um buraco de tábuas no centro), tábuas soltas penduradas, corda arrebentada.

## Folha 09: raízes que fecham o caminho (régua `largas_4x.png`; 1 coluna x 2 linhas, células de 1536x512)
1. MURALHA DE RAÍZES: raízes enormes, grossas e escuras, entrelaçadas, com espinhos e musgo, formando uma barreira baixa e comprida na horizontal. GRANDE: ~350 x 100 (quase a célula inteira na largura; fecha uma passagem de 5 blocos).
2. AS MESMAS RAÍZES RECOLHIDAS: só os tocos das raízes nas duas pontas, encolhidos, com folhinhas novas brotando (o caminho do meio livre).

## Terrenos (refazer o tileset do pacote)

**Anexar:** `art/terceiros/tiny_swords/Tiny Swords (Free Pack)/Terrain/Tileset/Tilemap_color1.png` e `game/assets/sprites/tiny/areia.png` (a areia que já foi feita assim e aprovada).

Texto (trocar o MATERIAL):

```text
Refaça a imagem anexada Tilemap_color1.png (tileset de terreno do Tiny Swords, 576x384, tiles de 64x64) EXATAMENTE com o mesmo layout, os mesmos recortes, as mesmas bordas e o mesmo contorno, ampliada para 1536x1024, trocando SÓ a grama por MATERIAL. As partes de penhasco e as transparências continuam iguais. Fundo magenta chapado #FF00FF onde o original é transparente. Mesmo nível de detalhe e de tons da areia anexada (pouco detalhe, tons apagados do pacote).
```

1. `l36_trilha_tilemap.png`: TERRA BATIDA de trilha (marrom-clara apagada, umas pedrinhas e marcas de passos).
2. `l36_lama_tilemap.png`: LAMA DE PÂNTANO (verde-oliva escuro e marrom, com pocinhas de água rasa azul-esverdeada e bolhinhas).
3. `l36_piso_tilemap.png`: PISO DE PEDRA ANTIGA (lajes quadradas cinza-azuladas, rachadas, com musgo verde nas juntas).

## Depois de gerar

Salvar só no caminho indicado na instrução. Não mexer em `game/` nem em nenhum outro arquivo.
