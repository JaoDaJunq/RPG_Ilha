extends Node
## Conexão entre os jogadores. Um jogador é o anfitrião (servidor) e os outros entram pelo IP.
## No modo solo, o próprio jogo é o anfitrião (OfflineMultiplayerPeer), então o mesmo código
## de rede vale para jogar sozinho.

enum Modo { SOLO, HOSPEDAR, ENTRAR }

const PORTA_PADRAO := 7777
const MAX_JOGADORES := 4

var modo := Modo.SOLO
var endereco := "127.0.0.1"
var porta := PORTA_PADRAO
## Personagem escolhido no menu (raça e classe).
var raca: StringName = &"humano"
var classe: StringName = &"guerreiro"
## Motivo da última desconexão, para o menu mostrar.
var ultimo_erro := ""


func _ready() -> void:
	# Atalhos de linha de comando para testar sem passar pelo menu:
	#   -- --solo | --hospedar | --entrar=192.168.0.10   (opcional: --porta=7777)
	for arg in OS.get_cmdline_user_args():
		if arg == "--solo":
			modo = Modo.SOLO
		elif arg == "--hospedar":
			modo = Modo.HOSPEDAR
		elif arg.begins_with("--entrar="):
			modo = Modo.ENTRAR
			endereco = arg.get_slice("=", 1)
		elif arg.begins_with("--porta="):
			porta = arg.get_slice("=", 1).to_int()
		elif arg.begins_with("--raca="):
			raca = StringName(arg.get_slice("=", 1))
		elif arg.begins_with("--classe="):
			classe = StringName(arg.get_slice("=", 1))


func modo_pela_linha_de_comando() -> bool:
	for arg in OS.get_cmdline_user_args():
		if arg == "--solo" or arg == "--hospedar" or arg.begins_with("--entrar="):
			return true
	return false


## Liga a rede no modo escolhido. Retorna OK ou o erro.
func iniciar() -> Error:
	ultimo_erro = ""
	match modo:
		Modo.SOLO:
			multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
			return OK
		Modo.HOSPEDAR:
			var p := ENetMultiplayerPeer.new()
			var erro := p.create_server(porta, MAX_JOGADORES - 1)
			if erro != OK:
				ultimo_erro = "Não deu para abrir a porta %d (%s)." % [porta, error_string(erro)]
				return erro
			multiplayer.multiplayer_peer = p
			return OK
		Modo.ENTRAR:
			var p := ENetMultiplayerPeer.new()
			var erro := p.create_client(endereco, porta)
			if erro != OK:
				ultimo_erro = "Não deu para conectar em %s:%d (%s)." % [endereco, porta, error_string(erro)]
				return erro
			multiplayer.multiplayer_peer = p
			return OK
	return ERR_INVALID_PARAMETER


func encerrar() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


## Quem mandou a RPC atual é o anfitrião (ou é uma chamada local)?
func veio_do_anfitriao() -> bool:
	var s := multiplayer.get_remote_sender_id()
	return s == 0 or s == 1


## Endereços IPv4 desta máquina, para o anfitrião passar aos amigos.
func enderecos_locais() -> PackedStringArray:
	var lista := PackedStringArray()
	for ip in IP.get_local_addresses():
		if ip.count(".") == 3 and not ip.begins_with("127.") and not ip.begins_with("169.254."):
			lista.append(ip)
	return lista
