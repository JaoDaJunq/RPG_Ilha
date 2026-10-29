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
	# Já vem escolhido o personagem salvo, para continuar de onde parou.
	var meu := World.ultimo_personagem(Salvamento.ler(), Net.id_jogador)
	if not meu.is_empty():
		Net.raca = StringName(meu.get("raca", Net.raca))
		Net.classe = StringName(meu.get("classe", Net.classe))
	_montar_escolhas()
	_atualizar_mundo_salvo()
	%MundoNovo.pressed.connect(_mundo_novo)
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


## Mostra se há mundo salvo (vale para jogar sozinho e para hospedar).
func _atualizar_mundo_salvo() -> void:
	var dados := Salvamento.ler()
	%MundoNovo.visible = not dados.is_empty()
	%MundoNovo.text = "Começar mundo novo"
	if dados.is_empty():
		%InfoMundo.text = "Nenhum mundo salvo: a ilha começa do zero."
		return
	var meu := World.ultimo_personagem(dados, Net.id_jogador)
	if meu.is_empty():
		%InfoMundo.text = "Mundo salvo encontrado (sozinho ou hospedando)."
	else:
		var f := Ficha.criar(StringName(meu.get("raca", "humano")), StringName(meu.get("classe", "guerreiro")))
		%InfoMundo.text = "Mundo salvo · seu %s nível %d" % [f.titulo(), int(meu.get("nivel", 1))]


## Dois cliques para não apagar sem querer.
func _mundo_novo() -> void:
	if %MundoNovo.text != "Clique de novo para apagar":
		%MundoNovo.text = "Clique de novo para apagar"
		return
	Salvamento.apagar()
	_atualizar_mundo_salvo()
	estado.text = "Mundo apagado. A próxima partida começa do zero."


func _ir_para_o_mundo() -> void:
	get_tree().change_scene_to_file(MUNDO)
