class_name Salvamento
extends RefCounted
## Lê e grava o arquivo do mundo (só o anfitrião usa). Formato JSON simples:
## {
##   "versao": 1, "semente": 22117, "noite": false,
##   "recursos": {"Arvore12": [estado, golpes_restantes], ...},   (só os que mudaram)
##   "removidos": ["Pedra3", ...],
##   "jogadores": {"<id do jogador>": {raca, classe, nivel, xp, pontos..., itens, pos}}
## }

const VERSAO := 1
const PADRAO := "user://mundos/ilha.save"


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
