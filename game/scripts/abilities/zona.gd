class_name Zona
extends Node2D
## Zona no chão por alguns segundos: a cada `intervalo` faz dano, cura, aplica um estado
## nos inimigos e/ou dá um buff aos jogadores dentro do raio. Serve para Círculo de cura,
## Nuvem tóxica, Estandarte, Nevasca, Rastro de chamas, Santuário...
##
## Só existe no ANFITRIÃO (não é sincronizada): o que os outros veem é o `efeito_visual`
## (um Efeito em laço da tabela de Efeito, enviado a todos por World.efeito_laco_todos).
##
## Uso (numa HabilidadeLogica, que já roda no anfitrião):
##   var z := Zona.criar(quem, ponto, 40.0, 6.0)
##   z.cura = 4.0                       # por tique, nos jogadores dentro
##   z.estado = EfeitosEstado.LENTIDAO  # por tique, nos inimigos dentro
##   z.estado_forca = 0.4
##   z.efeito_visual = &"nova_gelo"
##   z.iniciar()

## Quem lançou (as curas e os danos saem em nome dele). Pode ser nulo.
var lancador: Player
var raio := 32.0
var duracao := 5.0
## Segundos entre um tique e outro.
var intervalo := 1.0
## Dano por tique nos inimigos dentro (0 = sem dano) e o elemento dele.
var dano := 0.0
var elemento: StringName = &"fisico"
## Cura por tique nos jogadores dentro (0 = sem cura).
var cura := 0.0
## Estado aplicado por tique nos inimigos dentro (vazio = nenhum). Ver EfeitosEstado.
var estado: StringName = &""
var estado_segundos := 1.5
var estado_forca := 0.0
## Buff dado por tique aos jogadores dentro (vazio = nenhum). Ver Buffs.
var buff: StringName = &""
var buff_valor := 0.0
var buff_segundos := 1.5
## Também acerta animais (além dos inimigos)?
var afeta_animais := true
## O primeiro tique acontece na hora (senão, só depois de `intervalo`).
var tique_na_hora := true
## A zona anda junto com este nó (ex.: em volta do jogador). Nulo = parada.
var seguir: Node2D
## Efeito (da tabela de Efeito) que todos veem em laço durante a zona; `escala_visual`
## multiplica o tamanho. `efeito_tique`: efeito que toca uma vez no centro a cada tique.
var efeito_visual: StringName = &""
var escala_visual := 1.0
var efeito_tique: StringName = &""
## Chamada a cada tique, para o que as opções acima não cobrem:
## func(zona: Zona, inimigos: Array[Node2D], jogadores: Array[Player]) -> void
var ao_tique: Callable

## Tiques já feitos (para os testes e para lógicas que contam).
var tiques := 0
var _tempo := 0.0
var _proximo := 0.0


## Cria a zona (ainda parada: configure e chame `iniciar()`).
static func criar(quem: Player, centro: Vector2, raio_zona: float, segundos: float, intervalo_tique := 1.0) -> Zona:
	var z := Zona.new()
	z.lancador = quem
	z.global_position = centro
	z.raio = raio_zona
	z.duracao = segundos
	z.intervalo = intervalo_tique
	return z


## Põe a zona no mundo (anfitrião). `pai` padrão: o nó das entidades do mundo.
func iniciar(pai: Node = null) -> Zona:
	if pai == null and lancador:
		pai = lancador.get_parent()
	if pai == null:
		push_error("Zona sem pai: passe `pai` ou um lançador.")
		return self
	var pos := global_position
	pai.add_child(self)
	global_position = pos
	_proximo = 0.0 if tique_na_hora else intervalo
	if efeito_visual != &"":
		if seguir:
			World.efeito_preso_todos(seguir, efeito_visual, duracao)
		else:
			World.efeito_laco_todos(self, efeito_visual, global_position, duracao, escala_visual, 0.0, self)
	return self


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if seguir:
		if not is_instance_valid(seguir):
			queue_free()
			return
		global_position = seguir.global_position
	_tempo += delta
	_proximo -= delta
	if _proximo <= 0.0 and _tempo <= duracao + 0.001:
		_proximo += intervalo
		_tique()
	if _tempo >= duracao:
		queue_free()


func _tique() -> void:
	tiques += 1
	var inimigos := inimigos_dentro()
	var jogadores := jogadores_dentro()
	var quem: Player = lancador if is_instance_valid(lancador) else null
	for e in inimigos:
		if dano > 0.0:
			var area := e.get_node_or_null("Hurtbox") as Hurtbox
			if area:
				area.receber(dano, elemento, quem)
		if estado != &"" and is_instance_valid(e):
			EfeitosEstado.aplicar_em(e, estado, estado_segundos, estado_forca, quem)
	for j in jogadores:
		if cura > 0.0:
			j.receber_cura(quem, cura)
		if buff != &"":
			j.buffs.dar(buff, buff_valor, buff_segundos, quem)
	if efeito_tique != &"":
		World.efeito_todos(self, efeito_tique, global_position)
	if ao_tique.is_valid():
		ao_tique.call(self, inimigos, jogadores)


## Inimigos (e animais, se `afeta_animais`) dentro do raio agora.
func inimigos_dentro() -> Array[Node2D]:
	return Golpes.inimigos_em_volta(self, global_position, raio, afeta_animais)


## Jogadores dentro do raio agora.
func jogadores_dentro() -> Array[Player]:
	return Golpes.jogadores_em_volta(self, global_position, raio)


## Segundos que faltam.
func restante() -> float:
	return maxf(0.0, duracao - _tempo)
