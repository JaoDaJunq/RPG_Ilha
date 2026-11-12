class_name Companheiro
extends Invocacao
## Companheiro: segue o dono e ataca o alvo dele (o último inimigo ou animal que o dono
## acertou, Player.ultimo_alvo). Serve para o falcão do Assobio/Laço e o animal domado.
## Por padrão não some sozinho (duracao 0) e ataca animais também (caça).
##
## Uso (numa HabilidadeLogica):
##   var c := Companheiro.criar_companheiro(quem)
##   c.dano = 1.0
##   c.textura_caminho = "res://assets/sprites/tiny/animais/animais.png"  # arte (placeholder)
##   c.quadro_inicial = 4
##   c.iniciar()
## Para mandar atacar um alvo agora (Ataque!): c.atacar_agora(alvo).

const CENA_COMPANHEIRO := "res://scenes/abilities/companheiro.tscn"  # carregada na hora

## Distância que ele fica do dono quando não tem alvo, e até onde vai caçar o alvo do dono.
var distancia_dono := 18.0
var alcance_caca := 140.0
## Alvo mandado (Ataque!): vale até ele sumir.
var alvo_mandado: Node2D


static func criar_companheiro(quem: Player) -> Companheiro:
	var c: Companheiro = Invocacao.criar(quem, quem.global_position + Vector2(-14, 4), load(CENA_COMPANHEIRO) as PackedScene)
	c.duracao = 0.0
	c.velocidade = 70.0
	c.alcance = 14.0
	c.ataca_animais = true
	return c


## Os companheiros deste jogador agora.
static func de(quem: Player) -> Array[Companheiro]:
	var l: Array[Companheiro] = []
	for n in quem.get_tree().get_nodes_in_group(&"invocacoes"):
		var c := n as Companheiro
		if c and c.dono == quem and not c.is_queued_for_deletion():
			l.append(c)
	return l


## Manda o companheiro atrás de `alvo` agora.
func atacar_agora(alvo: Node2D) -> void:
	alvo_mandado = alvo
	_espera = 0.0


func _physics_process(delta: float) -> void:
	if multiplayer.is_server() and not is_instance_valid(dono):
		sumir()  # o dono saiu do jogo
		return
	super(delta)


func escolher_alvo() -> Node2D:
	if is_instance_valid(alvo_mandado) and not alvo_mandado.is_queued_for_deletion():
		return alvo_mandado
	alvo_mandado = null
	var a := dono.ultimo_alvo if is_instance_valid(dono) else null
	if is_instance_valid(a) and not a.is_queued_for_deletion() and a.global_position.distance_to(dono.global_position) <= alcance_caca:
		return a
	return null


func mover_sem_alvo() -> Vector2:
	var para := dono.global_position - global_position
	return para.normalized() if para.length() > distancia_dono else Vector2.ZERO
