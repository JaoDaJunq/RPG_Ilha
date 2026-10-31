extends Node
## Sinais globais do jogo. Quem emite não precisa saber quem escuta.

## Mensagem curta para a barra de avisos do HUD.
signal aviso(texto: String)
## Um item entrou num inventário.
signal item_coletado(item_id: StringName, quantidade: int, quem: Node)
signal item_fabricado(item_id: StringName, quantidade: int, quem: Node)
signal abrir_mochila(na_bancada: bool)
