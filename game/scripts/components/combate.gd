class_name Combate
extends RefCounted
## Números e funções comuns do combate corpo a corpo (L40, ver design/combate.md).
##
## Golpe básico: cada classe tem um ritmo (ESTILOS). O golpe faz parte de um combo curto
## (2 ou 3 golpes); o último bate mais forte, empurra longe, segura a tela um pouco mais
## (hit stop) e treme a câmera, mas demora mais para voltar (RECUPERACAO_FINAL).
## Quem confere o ritmo e calcula o combo é o ANFITRIÃO (Player._pedir_golpe); o dono só
## prevê o mesmo para a animação. Os efeitos (piscar, número, som, hit stop, tremor) são
## locais de cada máquina e não mexem no tempo do jogo (sem Engine.time_scale).

# --- Golpe básico por classe ---------------------------------------------------------
## recarga: segundos entre golpes; dano: multiplica o dano do golpe (a arma e a Força
## continuam valendo); combo: multiplicador de cada golpe do combo (o último é o forte);
## avanco: px que o personagem dá para a frente ao golpear (o último dá o dobro).
const ESTILOS := {
	&"guerreiro": {recarga = 0.5, dano = 1.0, combo = [1.0, 1.0, 1.8], avanco = 5.0},
	&"ladino": {recarga = 0.26, dano = 0.55, combo = [1.0, 1.0, 1.6], avanco = 3.0},
	&"clerigo": {recarga = 0.55, dano = 0.9, combo = [1.0, 1.6], avanco = 4.0},
	&"arqueiro": {recarga = 0.5, dano = 0.8, combo = [1.0, 1.5], avanco = 2.0},
	&"mago": {recarga = 0.55, dano = 0.8, combo = [1.0, 1.5], avanco = 2.0},
}
## Depois que a recarga acaba, quanto tempo o próximo golpe ainda continua o combo.
const JANELA_COMBO := 0.45
## O golpe final do combo demora mais para o próximo (recarga x este valor).
const RECUPERACAO_FINAL := 1.7
## Apertar o golpe até este tempo antes de ele ficar pronto guarda o comando (buffer).
const BUFFER := 0.2
## Folga do anfitrião ao conferir o ritmo (o pedido pode chegar antes do relógio dele).
const FOLGA_ANFITRIAO_MS := 90
## Enquanto golpeia, o personagem anda mais devagar (o golpe tem peso).
const LENTIDAO_GOLPE := 0.5
const DURACAO_AVANCO := 0.07
## Força do golpe (empurrão e reação do alvo): 1 = normal; o golpe final do combo é forte.
const FORCA_NORMAL := 1.0
const FORCA_FINAL := 3.2

# --- Sensação (tudo local) -----------------------------------------------------------
## Hit stop: o personagem e o alvo param por alguns quadros ao acertar (60 quadros/s).
const HIT_STOP := 2.0 / 60.0
const HIT_STOP_FORTE := 4.0 / 60.0
## Tremor de câmera (px do mundo; 1 px = 4 px na tela) e duração.
const TREMOR_FORTE := 1.0
const TREMOR_EXPLOSAO := 1.5
const DURACAO_TREMOR := 0.18

# --- Inimigos -------------------------------------------------------------------------
## Empurrão no alvo, em px/s no instante do acerto, por ponto de força; desacelera FREIO px/s².
## Distância = v² / (2 x FREIO): golpe normal ~3 px, golpe final ~28 px.
const EMPURRAO := 70.0
const FREIO := 900.0
## Quanto mais longe do centro (perigo da região, 0 a 1), menor a espera entre os ataques
## dos inimigos (o aviso antes do ataque não muda: continua dando para esquivar).
const RITMO_PERIGO := 0.25
## Dificuldade do mundo (fácil, normal, difícil) na espera entre os ataques.
const RITMO_DIFICULDADE := [1.2, 1.0, 0.85]


static func estilo(classe: StringName) -> Dictionary:
	return ESTILOS.get(classe, ESTILOS[&"guerreiro"])


## Multiplicador do combo para o golpe `indice` (0 = o primeiro) da classe.
static func mult_combo(classe: StringName, indice: int) -> float:
	var c: Array = estilo(classe).combo
	return float(c[clampi(indice, 0, c.size() - 1)])


static func tamanho_combo(classe: StringName) -> int:
	return (estilo(classe).combo as Array).size()


static func eh_final(classe: StringName, indice: int) -> bool:
	return indice >= tamanho_combo(classe) - 1


## Segundos até o próximo golpe depois do golpe `indice`.
static func recarga(classe: StringName, indice: int) -> float:
	var r: float = estilo(classe).recarga
	return r * (RECUPERACAO_FINAL if eh_final(classe, indice) else 1.0)


## O próximo índice do combo: continua se o golpe veio até JANELA_COMBO depois de ficar
## pronto; senão recomeça do 0. `desde`: segundos desde o golpe anterior.
static func proximo_indice(classe: StringName, anterior: int, desde: float) -> int:
	if anterior < 0 or eh_final(classe, anterior):
		return 0
	return anterior + 1 if desde <= recarga(classe, anterior) + JANELA_COMBO else 0


## Velocidade do empurrão (px/s) para um golpe com esta força.
static func empurrao(forca: float) -> float:
	return EMPURRAO * forca


## Multiplica as recargas de ataque de um inimigo pela região e pela dificuldade.
## Só para quem o Povoamento fez nascer pelas regiões (os testes e os fixos ficam 1,0).
static func ritmo_inimigo(quem: Node) -> float:
	if quem == null or not quem.is_inside_tree():
		return 1.0
	var w: World = quem.get_tree().get_first_node_in_group(&"mundo")
	if w == null:
		return 1.0
	var base: float = RITMO_DIFICULDADE[clampi(w.dificuldade, 0, RITMO_DIFICULDADE.size() - 1)]
	var perigo := 0.0
	if quem is Node2D and Povoamento.nasceu_aqui(quem):
		perigo = w.perigo_em((quem as Node2D).global_position)
	return base * (1.0 - RITMO_PERIGO * perigo)


## Treme a câmera do jogador local se ele estiver perto de `pos` (explosões).
static func tremer_perto(arvore: SceneTree, pos: Vector2, forca: float, raio := 120.0) -> void:
	for j in arvore.get_nodes_in_group(&"jogadores"):
		var p := j as Player
		if p and p.eh_local() and p.global_position.distance_to(pos) <= raio:
			p.tremer_camera(forca, DURACAO_TREMOR)
