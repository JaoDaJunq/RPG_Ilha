class_name Ficha
extends RefCounted
## Os atributos de um personagem (raça + classe) e o que eles valem no jogo.
## Os mesmos cálculos rodam no anfitrião e em cada jogador, então todos chegam nos mesmos números.

const ATRIBUTOS: Array[StringName] = [&"forca", &"vitalidade", &"agilidade", &"intelecto", &"espirito"]
const NOMES := {
	&"forca": "Força", &"vitalidade": "Vitalidade", &"agilidade": "Agilidade",
	&"intelecto": "Intelecto", &"espirito": "Espírito",
}

var raca: RacaData
var classe: ClasseData
var valores: Dictionary[StringName, int] = {}


## `distribuidos`: pontos que o jogador colocou ao subir de nível.
static func criar(raca_id: StringName, classe_id: StringName, distribuidos: Dictionary = {}) -> Ficha:
	var f := Ficha.new()
	f.raca = RacaData.carregar(raca_id)
	f.classe = ClasseData.carregar(classe_id)
	for a in ATRIBUTOS:
		f.valores[a] = f.classe.atributos.get(a, 5) + f.raca.bonus.get(a, 0) + int(distribuidos.get(a, 0))
	return f


func valor(atributo: StringName) -> int:
	return valores.get(atributo, 5)


func titulo() -> String:
	return "%s %s" % [raca.nome, classe.nome]


# --- O que cada atributo vale (números pequenos e redondos de propósito) ------

func vida_maxima() -> float:
	return 40.0 + valor(&"vitalidade") * 10.0


func mana_maxima() -> float:
	return 10.0 + valor(&"intelecto") * 5.0


## Mana recuperada por segundo.
func regeneracao_mana() -> float:
	return 0.5 + valor(&"espirito") * 0.25


func velocidade() -> float:
	return 68.0 + valor(&"agilidade") * 2.0


func multiplicador_fisico() -> float:
	return 1.0 + (valor(&"forca") - 5) * 0.1


func multiplicador_magico() -> float:
	return 1.0 + (valor(&"intelecto") - 5) * 0.1


## Multiplica o tempo de cada golpe de coleta (menos é mais rápido).
func tempo_coleta() -> float:
	return clampf(1.0 - (valor(&"forca") - 5) * 0.05, 0.6, 1.3)


func recarga_esquiva() -> float:
	return clampf(1.2 - valor(&"agilidade") * 0.05, 0.6, 1.2)


func multiplicador(elemento: StringName) -> float:
	return multiplicador_fisico() if elemento == &"fisico" else multiplicador_magico()


# --- Níveis ----------------------------------------------------------------------

const NIVEL_MAXIMO := 16  # do 1 ao 16: 15 pontos de habilidade ao todo
const PONTOS_ATRIBUTO_POR_NIVEL := 2
const PONTOS_HABILIDADE_POR_NIVEL := 1


## Experiência para sair do nível `n` para o seguinte.
static func xp_para_subir(n: int) -> int:
	return 20 + (n - 1) * 15


## Bônus de raça na experiência (Humano: Versátil, +10%).
func experiencia_ajustada(quantidade: int) -> int:
	return roundi(quantidade * 1.1) if raca.id == &"humano" else quantidade
