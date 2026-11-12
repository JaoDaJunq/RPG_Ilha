extends TesteBase
## L32: cada nó da árvore, em todas as classes, tem um ícone só dele (nada da estrela neutra
## nem ícones repetidos), e as habilidades das teclas usam o mesmo ícone do nó.


func _ready() -> void:
	var usados := {}
	for classe in ClasseData.TODAS:
		for n in ArvoreData.nos(classe):
			checar(n.icone != null, "%s/%s tem ícone" % [classe, n.id])
			if n.icone == null:
				continue
			var caminho := n.icone.resource_path
			checar(not caminho.ends_with("icone_%s.png" % ArvoreData.ICONE_NEUTRO), "%s/%s não usa a estrela neutra" % [classe, n.id])
			checar(not usados.has(caminho), "%s/%s tem ícone único (%s já é de %s)" % [classe, n.id, caminho.get_file(), usados.get(caminho, "")])
			usados[caminho] = "%s/%s" % [classe, n.id]
			if n.habilidade:
				checar(n.habilidade.icone == n.icone, "%s/%s: a tecla usa o ícone do nó" % [classe, n.id])
	terminar()
