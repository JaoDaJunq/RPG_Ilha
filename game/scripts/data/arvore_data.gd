class_name ArvoreData
extends RefCounted
## A árvore de habilidades de cada classe (design/arvore_habilidades.md, versão 2).
##
## Como funciona:
##   - 3 passivas da classe, ligadas desde o nível 1 (sem ponto);
##   - 5 iniciais: as 2 primeiras vêm com a classe; as outras 3 custam 1 ponto (nível 2+);
##   - nível 5: escolhe UM ramo. O ramo segue a ordem passiva de entrada (5), habilidade (6),
##     habilidade (8), passiva de mestre (10), habilidade (12) e suprema (15). A entrada pede
##     uma das iniciais que levam ao ramo; cada passo seguinte pede o anterior;
##   - pontos que sobram melhoram uma habilidade aprendida (até 3 vezes).
##
## Na tabela, o último campo de cada nó diz o quanto ele já funciona no jogo:
##   ""  = funciona inteiro;  "-" = efeito pendente;  outro texto = o que ainda falta.
## Ícone: nome curto de res://assets/sprites/tiny/icones/icone_<nome>.png; vazio usa o da
## habilidade que já existe (res://data/habilidades/<id>.tres). As novas sem arte usam a
## estrela (icone_experiencia) como marcador neutro.

const PASTA_ICONES := "res://assets/sprites/tiny/icones/icone_%s.png"
const PASTA_HABILIDADES := "res://data/habilidades/%s.tres"
const ICONE_NEUTRO := "experiencia"
## Níveis e tipos dos 6 passos de cada ramo.
const NIVEIS_RAMO: Array[int] = [5, 6, 8, 10, 12, 15]
const TIPOS_RAMO := [
	NoArvore.Tipo.PASSIVA, NoArvore.Tipo.ATIVA, NoArvore.Tipo.ATIVA,
	NoArvore.Tipo.PASSIVA, NoArvore.Tipo.ATIVA, NoArvore.Tipo.ATIVA,
]
const NIVEL_INICIAIS := 2

const P := "-"  # efeito pendente

## A tabela de cada classe fica no arquivo dela (arvore_<classe>.gd), para cada um mexer só
## nas suas linhas. O formato está explicado lá.
const TABELA := {
	&"guerreiro": ArvoreGuerreiro.DADOS,
	&"mago": ArvoreMago.DADOS,
	&"arqueiro": ArvoreArqueiro.DADOS,
	&"ladino": ArvoreLadino.DADOS,
	&"clerigo": ArvoreClerigo.DADOS,
}

static var _cache: Dictionary = {}  # classe → Array[NoArvore]


## Todos os nós da classe, na ordem das colunas (classe, iniciais, ramos).
static func nos(classe_id: StringName) -> Array[NoArvore]:
	if _cache.has(classe_id):
		return _cache[classe_id]
	var lista: Array[NoArvore] = []
	var dados: Dictionary = TABELA.get(classe_id, {})
	if dados.is_empty():
		return lista
	var k := 0
	for linha in dados.passivas:
		var n := _no(linha, NoArvore.Tipo.PASSIVA, NoArvore.RAMO_CLASSE, k)
		n.padrao = true
		n.custo = 0
		lista.append(n)
		k += 1
	k = 0
	for linha in dados.iniciais:
		var n := _no(linha, NoArvore.Tipo.ATIVA, NoArvore.RAMO_INICIAIS, k)
		n.padrao = k < 2
		n.custo = 0 if n.padrao else 1
		n.nivel = 1 if n.padrao else NIVEL_INICIAIS
		for r in linha[5]:
			n.leva_a.append(r)
		lista.append(n)
		k += 1
	for ramo in dados.ramos:
		var anterior: NoArvore = null
		for e in ramo[2].size():
			var n := _no(ramo[2][e], TIPOS_RAMO[e], ramo[0], e)
			n.nivel = NIVEIS_RAMO[e]
			if anterior:
				n.requisitos.append(anterior.id)
			else:
				for ini in dados.iniciais:
					if ramo[0] in ini[5]:
						n.algum_de.append(ini[0])
			lista.append(n)
			anterior = n
	_cache[classe_id] = lista
	return lista


static func no(classe_id: StringName, no_id: StringName) -> NoArvore:
	if not _indice.has(classe_id):
		var d := {}
		for n in nos(classe_id):
			d[n.id] = n
		_indice[classe_id] = d
	return _indice[classe_id].get(no_id)


## Ramos da classe: [[id, nome], ...].
static func ramos(classe_id: StringName) -> Array:
	var l := []
	for r in TABELA.get(classe_id, {}).get("ramos", []):
		l.append([r[0], r[1]])
	return l


static func nome_ramo(classe_id: StringName, ramo_id: StringName) -> String:
	if ramo_id == NoArvore.RAMO_CLASSE:
		return "Da classe"
	if ramo_id == NoArvore.RAMO_INICIAIS:
		return "Iniciais"
	for r in ramos(classe_id):
		if r[0] == ramo_id:
			return r[1]
	return String(ramo_id)


static var _padrao: Dictionary = {}  # classe → Array[StringName]
static var _indice: Dictionary = {}  # classe → {id: NoArvore}


## Ids das habilidades que já vêm com a classe (as 2 primeiras iniciais).
static func padrao(classe_id: StringName) -> Array[StringName]:
	if not _padrao.has(classe_id):
		var l: Array[StringName] = []
		for n in nos(classe_id):
			if n.padrao and n.ativa():
				l.append(n.id)
		_padrao[classe_id] = l
	return _padrao[classe_id]


## O nó vem com a classe (passivas da classe e as 2 habilidades padrão)?
static func eh_padrao(classe_id: StringName, no_id: StringName) -> bool:
	var n := no(classe_id, no_id)
	return n != null and n.padrao


static func _no(linha: Array, tipo: NoArvore.Tipo, ramo: StringName, etapa: int) -> NoArvore:
	var n := NoArvore.new()
	n.id = linha[0]
	n.nome = linha[1]
	n.descricao = linha[2]
	n.tipo = tipo
	n.ramo = ramo
	n.etapa = etapa
	var estado: String = linha[4]
	n.pendente = estado == P
	n.falta = "" if estado == P else estado
	if tipo == NoArvore.Tipo.ATIVA and not n.pendente and ResourceLoader.exists(PASTA_HABILIDADES % n.id):
		n.habilidade = load(PASTA_HABILIDADES % n.id) as HabilidadeData
	var icone: String = linha[3]
	if icone == "" and n.habilidade and n.habilidade.icone:
		n.icone = n.habilidade.icone
	else:
		n.icone = load(PASTA_ICONES % (icone if icone != "" else ICONE_NEUTRO)) as Texture2D
	return n
