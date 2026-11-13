extends Node
## Toca efeitos sonoros curtos e a música. P liga e desliga tudo (M é o mapa).

const SONS := {
	&"ataque": preload("res://assets/placeholder/ninja/audio/ataque.wav"),
	&"bola_de_fogo": preload("res://assets/placeholder/ninja/audio/bola_de_fogo.wav"),
	&"fogo": preload("res://assets/placeholder/ninja/audio/fogo.wav"),
	&"golpe_coleta": preload("res://assets/placeholder/ninja/audio/golpe_coleta.wav"),
	&"acerto": preload("res://assets/placeholder/ninja/audio/acerto.wav"),
	&"item": preload("res://assets/placeholder/ninja/audio/item.wav"),
	&"esquiva": preload("res://assets/placeholder/ninja/audio/esquiva.wav"),
	&"flecha": preload("res://assets/placeholder/ninja/audio/flecha.wav"),
	&"giro": preload("res://assets/placeholder/ninja/audio/giro.wav"),
	&"subir_nivel": preload("res://assets/placeholder/ninja/audio/subir_nivel.wav"),
}
const MUSICA := preload("res://assets/placeholder/ninja/audio/musica_clareira.ogg")

var ligado := true
var _musica: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_musica = AudioStreamPlayer.new()
	_musica.stream = MUSICA
	_musica.volume_db = -18.0
	_musica.finished.connect(func() -> void: if ligado: _musica.play())
	add_child(_musica)


func tocar_musica() -> void:
	if ligado and not _musica.playing:
		_musica.play()


## `tom`: 1 = normal; menos é mais grave. `variar`: sorteia o tom em ±variar (golpes e
## acertos não soam sempre iguais).
func tocar(nome: StringName, volume_db := -8.0, tom := 1.0, variar := 0.0) -> void:
	if not ligado or not SONS.has(nome):
		return
	var p := AudioStreamPlayer.new()
	p.stream = SONS[nome]
	p.volume_db = volume_db
	p.pitch_scale = maxf(0.1, tom + randf_range(-variar, variar))
	p.finished.connect(p.queue_free)
	add_child(p)
	p.play()


func alternar() -> void:
	ligado = not ligado
	if ligado:
		_musica.play()
	else:
		_musica.stop()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("alternar_som"):
		alternar()
