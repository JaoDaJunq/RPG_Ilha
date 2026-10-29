# Prévia C02 no Godot

Executar abrir.cmd. WASD move, Tab troca mago/ogro, N aplica tonalidade noturna, Esc fecha. Laboratório local isolado, sem combate, coleta, colisões de cenário, animação de caminhada ou multiplayer. Não substitui o jogo principal.

Recortes removem magenta e normalizam os pés. Personagens 72px de altura na tela; árvores230px; pedra80px. Redução por vizinho mais próximo, sem retorno ao padrão32x32. Terreno v2 simplificado com image_gen integrado. O terreno ainda é uma imagem contínua, não um tileset. Variações da grade de pixel das artes ainda precisam refinamento.

Verificação: importação Godot sem erro, captura real1280x720 revisada em evidence/piloto_c02/dia.png; bateria game/tools/rodar_testes.sh: tudo OK. Movimento e troca disponíveis no código; não foi realizado playtest manual completo.

Prompt exato terreno v2:

Edit terrain only. Preserve image1536x1024, exact shoreline, dirt clearing, palette and topdown view. Radically simplify grass: 85 percent of grass surface single flat warm green color with just a few broad low contrast patches; remove almost all tiny speckles, all repetitive texture and 90 percent of grass tufts. Keep only sparse tufts in loose clusters near borders. Sand mostly flat cream, water broad turquoise bands with limited simple ripples and crisp foam. Clean fine pixel art, crisp edges, no blurry smoothing. No characters, objects, text or interface. Intended calm ground beneath detailed pixel sprites, readable like Forager with Moonlighter colors.

