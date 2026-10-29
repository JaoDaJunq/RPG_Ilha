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
	_montar_escolhas()
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


## Raça e classe: a escolha fica no Net e vai para o anfitrião ao entrar.
func _montar_escolhas() -> void:
	var raca: OptionButton = %Raca
	var classe: OptionButton = %Classe
	for id in RacaData.TODAS:
		raca.add_item(RacaData.carregar(id).nome)
	for id in ClasseData.TODAS:
		classe.add_item(ClasseData.carregar(id).nome)
	raca.select(maxi(0, RacaData.TODAS.find(Net.raca)))
	classe.select(maxi(0, ClasseData.TODAS.find(Net.classe)))
	raca.item_selected.connect(func(i: int) -> void:
		Net.raca = RacaData.TODAS[i]
		_atualizar_resumo())
	classe.item_selected.connect(func(i: int) -> void:
		Net.classe = ClasseData.TODAS[i]
		_atualizar_resumo())
	_atualizar_resumo()


func _atualizar_resumo() -> void:
	var f := Ficha.criar(Net.raca, Net.classe)
	var atributos: Array[String] = []
	for a in Ficha.ATRIBUTOS:
		atributos.append("%s %d" % [Ficha.NOMES[a].substr(0, 3), f.valor(a)])
	var habs: Array[String] = []
	for h in f.classe.habilidades:
		habs.append(h.nome)
	%Resumo.text = "%s: %s\n%s\nVida %d · Mana %d · Habilidades: %s\n%s: %s" % [
		f.titulo(), f.classe.descricao, " · ".join(atributos),
		f.vida_maxima(), f.mana_maxima(), ", ".join(habs),
		f.raca.habilidade_nome, f.raca.habilidade_descricao]


func _ir_para_o_mundo() -> void:
	get_tree().change_scene_to_file(MUNDO)
