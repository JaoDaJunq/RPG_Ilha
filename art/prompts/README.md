# Pedidos de arte: como funciona

O Claude escreve um pedido em `pedidos/`, com o prompt pronto, os anexos e o caminho de saída. O Codex gera e salva **só** no caminho indicado. O Claude avalia, copia as imagens inteiras para `C:\Users\jpach\Aprovações Ilhas Vivas\<pedido> - <assunto> (aguardando)\` com um `LEIA-ME.txt`, e só integra depois da aprovação do João (ou escreve a correção).

## Padrão técnico (vale para todo pedido de sprite, depois que a bíblia visual for aprovada)

**Atualização C02 — 29/10/2026:** João escolheu pixel art mais fina e adicionou Forager e Moonlighter como referências. Anexar `art/conceitos/estilo/estilo_pixel_fino_v1.png` aos novos pedidos, junto com os conceitos de dia/noite. A tabela abaixo é o padrão dos lotes anteriores: tamanhos e ampliação precisam ser revistos no lote piloto descrito em `design/identidade.md`. Não reduzir automaticamente a arte nova para 32 × 32 nem usar o aventureiro antigo como limite de detalhe. Cada novo pedido deve declarar tamanho de origem e tamanho esperado na tela; ainda não há uma nova resolução aprovada.

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
