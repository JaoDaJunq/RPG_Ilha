# Pedidos de arte: como funciona

O Claude escreve um pedido em `pedidos/`, com o prompt pronto, os anexos e o caminho de saída. O Codex gera e salva **só** no caminho indicado. O Claude avalia e integra, ou escreve a correção.

## Padrão técnico (vale para todo pedido de sprite, depois que a bíblia visual for aprovada)

| Item | Padrão |
|---|---|
| Visão | De cima, em 3/4 (topo e frente visíveis) |
| Quadro | 32 × 32 px para personagem e objetos pequenos; 64 × 64 para árvore e objetos grandes |
| Ampliação na imagem | Inteira (8× para 32 px, 8× para 64 px), cada pixel vira um quadrado nítido |
| Folha | 1536 × 1024, grade de 3 colunas × 2 linhas (até 6 quadros), lida da esquerda para a direita e de cima para baixo |
| Fundo | Magenta chapado `#FF00FF`, sem degradê nem sombra (o Claude troca por transparente) |
| Base | O ponto em que o objeto toca o chão fica na mesma linha em todos os quadros |
| Contorno | 1 px, escuro, da paleta |
| Proibido | Anti-aliasing, borrado, degradê suave, texto, números, grade, moldura, chão, rastro, poeira, brilho |
| Margem | Espaço vazio generoso em volta; nada encosta na borda da célula |
| Referências | Todo pedido anexa o conceito aprovado e um sprite já aprovado, quando houver |

## Onde salvar

- Conceitos: `art/conceitos/<tema>/<nome>_vN.png`
- Sprites candidatos: `art/sprites/<grupo>/candidatos/<nome>_vN.png` (fora do git até a aprovação)
- Sprites aprovados: `art/sprites/<grupo>/<nome>.png`, e o Claude copia para `game/assets/`
