class_name Salvamento
extends RefCounted
## Lê e grava os arquivos de mundo (só o anfitrião usa). Cada mundo é um arquivo em
## user://mundos/<nome seguro>.save, em JSON simples:
## {
##   "versao": 1, "semente": 22117, "noite": false,
##   "nome": "Meu mundo", "dificuldade": 1, "criado_em": 1790000000, "salvo_em": 1790000000,
##   "recursos": {"Arvore12": [estado, golpes_restantes], ...},   (só os que mudaram)
##   "removidos": ["Pedra3", ...],
##   "jogadores": {"<id do jogador>": {raca, classe, nivel, xp, pontos..., itens, pos}}
## }
## O mundo antigo (user://mundos/ilha.save, de antes da lista de mundos) não tem nome nem
## dificuldade: aparece na lista como "Ilha", dificuldade Normal.

const VERSAO := 1
const PASTA := "user://mundos/"
const PADRAO := "user://mundos/ilha.save"

## Pasta onde a lista de mundos procura e cria arquivos (os testes trocam por uma temporária).
static var pasta_atual := PASTA

## Dificuldade do mundo (0, 1, 2): o nome e a frase que o menu mostra.
const DIFICULDADES: Array[Dictionary] = [
	{"nome": "Fácil", "descricao": "Inimigos mais fracos. Para explorar a ilha sem pressa."},
	{"nome": "Normal", "descricao": "O jogo como foi pensado: um desafio justo."},
	{"nome": "Difícil", "descricao": "Inimigos mais fortes e que machucam mais. Para quem quer sofrer."},
]

const _ACENTOS := {
	"á": "a", "à": "a", "â": "a", "ã": "a", "ä": "a", "é": "e", "è": "e", "ê": "e", "ë": "e",
	"í": "i", "ì": "i", "î": "i", "ï": "i", "ó": "o", "ò": "o", "ô": "o", "õ": "o", "ö": "o",
	"ú": "u", "ù": "u", "û": "u", "ü": "u", "ç": "c", "ñ": "n",
}


static func existe(caminho := PADRAO) -> bool:
	return caminho != "" and FileAccess.file_exists(caminho)


static func ler(caminho := PADRAO) -> Dictionary:
	if not existe(caminho):
		return {}
	var texto := FileAccess.get_file_as_string(caminho)
	var dados: Variant = JSON.parse_string(texto)
	if not dados is Dictionary or int(dados.get("versao", 0)) != VERSAO:
		push_warning("Arquivo de mundo ilegível ou de outra versão: " + caminho)
		return {}
	return dados


static func gravar(dados: Dictionary, caminho := PADRAO) -> bool:
	if caminho == "":
		return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(caminho.get_base_dir()))
	# O nome e a data de criação ficam com o arquivo mesmo quando quem grava não os passa.
	if existe(caminho) and (not dados.has("nome") or not dados.has("criado_em")):
		var antigo := ler(caminho)
		for chave in ["nome", "criado_em"]:
			if not dados.has(chave) and antigo.has(chave):
				dados[chave] = antigo[chave]
	dados["salvo_em"] = int(Time.get_unix_time_from_system())
	# Grava num temporário e troca, para não estragar o mundo se o jogo fechar no meio.
	var tmp := caminho + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Não deu para gravar o mundo: %s" % error_string(FileAccess.get_open_error()))
		return false
	dados["versao"] = VERSAO
	f.store_string(JSON.stringify(dados, "\t"))
	f.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho))
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(caminho)) == OK


static func apagar(caminho := PADRAO) -> void:
	if existe(caminho):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho))


# --- Lista de mundos ------------------------------------------------------------------

## "Meu Mundo Ão!" vira "meu_mundo_ao": só letras sem acento, números e "_".
static func nome_seguro(nome: String) -> String:
	var s := nome.strip_edges().to_lower()
	for a in _ACENTOS:
		s = s.replace(a, _ACENTOS[a])
	var saida := ""
	for c in s:
		saida += c if (c >= "a" and c <= "z") or (c >= "0" and c <= "9") else "_"
	while saida.contains("__"):
		saida = saida.replace("__", "_")
	saida = saida.trim_prefix("_").trim_suffix("_")
	return saida if saida != "" else "mundo"


## Um caminho livre para um mundo com este nome ("meu_mundo.save", "meu_mundo_2.save"...).
static func caminho_novo(nome: String, pasta := "") -> String:
	if pasta == "":
		pasta = pasta_atual
	var base := nome_seguro(nome)
	var caminho := pasta.path_join(base + ".save")
	var n := 2
	while FileAccess.file_exists(caminho):
		caminho = pasta.path_join("%s_%d.save" % [base, n])
		n += 1
	return caminho


## Cria o arquivo de um mundo novo (sem nada mexido ainda) e devolve o caminho ("" se falhar).
static func criar_mundo(nome: String, dificuldade: int, pasta := "") -> String:
	var caminho := caminho_novo(nome, pasta)
	var agora := int(Time.get_unix_time_from_system())
	var ok := gravar({
		"nome": nome.strip_edges(), "dificuldade": clampi(dificuldade, 0, DIFICULDADES.size() - 1),
		"criado_em": agora, "jogadores": {},  # sem "semente": vale a do World
	}, caminho)
	return caminho if ok else ""


## Resumo de um mundo salvo para a lista: nome, dificuldade, quando foi jogado e o maior nível.
static func resumo(caminho: String) -> Dictionary:
	var dados := ler(caminho)
	if dados.is_empty():
		return {}
	var nivel := 0
	for j in dados.get("jogadores", {}).values():
		nivel = maxi(nivel, int(j.get("nivel", 1)))
	var nome := String(dados.get("nome", ""))
	if nome == "":
		nome = caminho.get_file().get_basename().capitalize()
	return {
		"caminho": caminho, "nome": nome,
		"dificuldade": clampi(int(dados.get("dificuldade", 1)), 0, DIFICULDADES.size() - 1),
		"salvo_em": int(dados.get("salvo_em", FileAccess.get_modified_time(caminho))),
		"nivel": nivel,
	}


## Todos os mundos da pasta, o jogado mais recentemente primeiro.
static func listar(pasta := "") -> Array[Dictionary]:
	if pasta == "":
		pasta = pasta_atual
	var lista: Array[Dictionary] = []
	for arquivo in DirAccess.get_files_at(pasta):
		if arquivo.ends_with(".save"):
			var r := resumo(pasta.path_join(arquivo))
			if not r.is_empty():
				lista.append(r)
	lista.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.salvo_em > b.salvo_em)
	return lista


## "agora há pouco", "há 3 dias"... para a lista.
static func texto_data(unix: int) -> String:
	var seg := int(Time.get_unix_time_from_system()) - unix
	if seg < 120:
		return "agora mesmo"
	if seg < 3600:
		return "há %d minutos" % (seg / 60)
	if seg < 86400:
		var h := seg / 3600
		return "há %d hora%s" % [h, "" if h == 1 else "s"]
	var d := seg / 86400
	if d < 60:
		return "há %d dia%s" % [d, "" if d == 1 else "s"]
	return "há %d meses" % (d / 30)
