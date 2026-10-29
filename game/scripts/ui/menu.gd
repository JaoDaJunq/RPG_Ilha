extends Control
## Menu inicial: jogar sozinho, hospedar para os amigos ou entrar no jogo de alguém.

const MUNDO := "res://scenes/world/world.tscn"

@onready var campo_ip: LineEdit = %CampoIP
@onready var estado: Label = %Estado
@onready var meus_ips: Label = %MeusIPs


func _ready() -> void:
	# Atalho de teste: --solo, --hospedar ou --entrar=IP pulam o menu.
	if Net.modo_pela_linha_de_comando():
		_ir_para_o_mundo.call_deferred()
		return
	campo_ip.text = Net.endereco
	estado.text = Net.ultimo_erro
	var ips := Net.enderecos_locais()
	meus_ips.text = "Seu IP nesta rede: " + (", ".join(ips) if not ips.is_empty() else "não encontrado")
	%Solo.pressed.connect(_jogar.bind(Net.Modo.SOLO))
	%Hospedar.pressed.connect(_jogar.bind(Net.Modo.HOSPEDAR))
	%Entrar.pressed.connect(_jogar.bind(Net.Modo.ENTRAR))
	%Solo.grab_focus()


func _jogar(modo: Net.Modo) -> void:
	Net.modo = modo
	if modo == Net.Modo.ENTRAR:
		var ip := campo_ip.text.strip_edges()
		if not ip.is_valid_ip_address():
			estado.text = "Digite o IP do anfitrião (ex.: 192.168.0.10)."
			return
		Net.endereco = ip
	_ir_para_o_mundo()


func _ir_para_o_mundo() -> void:
	get_tree().change_scene_to_file(MUNDO)
