# L07 — lote piloto C02

## Revisão personagens v2

Correção gerada com image_gen: boca explícita e presas conectadas à boca; margens maiores. A linha dos pés ainda difere entre as duas linhas da folha; medir e normalizar na importação. v2 é a candidata para avaliação, v1 é histórico. Natureza e terreno continuam como estudos, sem validação de integração.

Prompt exato da correção:

Edit this sprite sheet preserving exact six identities, colors, front/back/right directions and magenta background1536x1024. Correct only: 1) remove the ivory tear-like marks directly underneath ogre eyes. Draw a clear horizontal dark mouth near bottom of face, with two SHORT ivory upward tusks attached at the ends of that mouth, separated from eyes by visible green cheek space; side face same anatomy. 2) Scale all six figures down uniformly to fit height340 pixels per cell512x512 with generous margin, feet baseline y440 within each row, matching scale across directions. Keep crisp fine pixel art and brown ogre hood. No text, ground, shadows, grid lines. Do not change costume.


Gerado com a ferramenta integrada image_gen em 29/10/2026. Candidatos, sem integração no jogo.

## Revisão visual

- Personagens: frente/costas/perfil presentes e capuz marrom correto. Escala e linha dos pés não obedecem ao pedido; as presas ainda parecem marcas sob os olhos. Precisa de correção antes da integração.
- Natureza: estados árvore inteira, cortada, queimada, toco e pedra inteira/rachada presentes. A primeira linha ultrapassa células de 512px; não importar com recorte automático 3x2. Exige separação e ajuste dos pontos de apoio.
- Terreno: paleta e bordas orgânicas presentes. Textura mais densa que o solicitado; precisa simplificação. É estudo contínuo, não atlas de autotiles.

A01j continua pendente: escala no jogo, animações, recorte e aprovação não foram concluídos. Nenhum arquivo game/ alterado.

## Prompts exatos

### Personagens

Use case: stylized-concept. Production candidate sprite sheet for Ilha Viva Godot top-down 3/4 fantasy game. Reference 1 approved fine pixel style, reference 2 only character identity. Create ONE character sprite sheet 1536x1024, 3 columns by 2 rows, each cell512x512, flat pure magenta #FF00FF background. Top row SAME Human Mage front, back, right profile. Bottom row SAME Ogre Archer front, back, right profile. Mage blue hood gold trim brown hair boots; ogre gray-green skin BROWN leather hood, quiver and bow, two tiny ivory tusks growing upwards FROM MOUTH, never under eyes. All idle standing poses. Fine polished genuine pixel art, source design each character within96x96 logical pixels enlarged exactly4x, max figure height320 output px, feet at cell y440. Crisp square pixels, coherent pixel grid, colored dark thin outline, clean clusters, restrained shading3 tones per material. Same scale and aligned feet throughout. Moonlighter-inspired craft and readable Forager simplicity, original identities. No text, grid lines, scenery, shadows on ground, glow, particles, anti-aliasing or blur. Preserve ample magenta margin. Deliver actual sprite sheet, not mockup.

### Natureza

Use case: stylized-concept. One production sprite sheet for original topdown 3/4 fantasy island Godot game, fine clean pixel art matching attached approved style but much less noise. 1536x1024 flat pure magenta #FF00FF background, invisible3 columns x2 rows of512x512 cells. Top row same broadleaf green tree healthy, same tree axe notch, same tree blackened leafless burned trunk. Bottom row matching tree stump, gray mossy harvestable rock, same rock cracked. Each object isolated fully inside its cell generous margins, no ground, no cast shadows, no text, no grid, no particles. Trees tall with brown trunk and clear big canopy clusters, top row consistent foot y460 and overall dimensions. Rock angular three gray tones with small moss patches. Crisp fine pixels consistent4x logical grid, colored thin outline, limited palette, no granular noise or antialias. Moonlighter level of material distinction and Forager clear silhouettes. Actual usable asset sheet, not scenery.

### Terreno

Use case stylized-concept. Terrain art candidate for topdown 2D fantasy island game. Single1536x1024 image, orthographic topdown terrain ONLY fills entire canvas, no perspective horizon. Broad quiet warm yellow-green grass left60%, sandy beach curving vertically in middle, turquoise water right25%, small compact dirt clearing entering from left middle. Clean fine pixel art, small consistent pixels, restrained3-tone clusters, very sparse grass tufts, no flowers or objects, no characters or buildings, no interface or text. Organic rounded grass-dirt sand-water edges, small crisp pale foam at shore. Original island palette from reference, Moonlighter polish with Forager readable simplicity. Flat walkable ground no cliffs, islands, shadows, 3D rendering, gradients, noise, blur. This is terrain reference patch for pilot, not a finished autotile atlas.


