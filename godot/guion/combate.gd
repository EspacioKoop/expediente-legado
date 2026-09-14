## El motor del combate: piedra-papel-tijera burocrático.
##
## Objeción vence a Silencio, Silencio vence a Insistencia, Insistencia vence a
## Objeción. Tres vidas cada uno y una decisión por ronda.
##
## El motor es ÚNICO y lo que cambia entre sus dos usos viaja en la
## configuración, no en dos motores: el duelo autorado de un expediente juega
## en `ciclo` (determinista, aprendible — es una escena, no un desafío) y la
## Ventanilla en `reactiva` (tiende a contestar a tu última jugada, así que se
## puede cebar). Quién juega qué lo decide `Prometeo.jugada_rival`, que ya
## estaba portado y probado.
##
## Las cuatro habilidades vienen de las decisiones políticas de la partida
## (`Historias.cargas`) y **cada una es una decisión dentro de la ronda**, no un
## bonus pasivo. Ninguna toca `carta.gastada`: el canje sigue siendo lo único
## que quema cartas.
class_name Combate
extends RefCounted

## En orden circular: cada uno vence al SIGUIENTE.
const TIPOS := ["objecion", "silencio", "insistencia"]

## Cómo se llama cada jugada de cara al jugador. Los valores son CLAVES de
## traducción, no el texto: quien lo pinta llama a `etiqueta()`.
const ETIQUETAS := {
	"objecion": "COMBATE_OBJECION",
	"silencio": "COMBATE_SILENCIO",
	"insistencia": "COMBATE_INSISTENCIA",
}

const VIDA_INICIAL := 3


## El nombre de una jugada, ya en el idioma de la partida.
static func etiqueta(tipo: String) -> String:
	return TranslationServer.translate(ETIQUETAS.get(tipo, ""))


## Un combate recién empezado.
##
## [param cargas] son las de `Historias.cargas`; sin decisiones políticas
## tomadas llegan a cero y el combate es solo el juego de manos, que es
## jugable pero es la versión pobre.
static func nuevo(modo: String, rival: Dictionary, cargas: Dictionary = {}) -> Dictionary:
	return {
		"modo": modo,
		"rival": rival,
		"vida_jugador": VIDA_INICIAL,
		"vida_rival": VIDA_INICIAL,
		"ronda": 0,
		"ultima_jugada_jugador": -1,
		"cargas": cargas.duplicate(),
		# Lo que la Comisión de seguimiento ya reveló: la jugada de la ronda
		# que viene, decidida por adelantado. Revelar y luego tirar otra vez
		# convertiría la habilidad en una mentira.
		"revelada": -1,
		"terminado": false,
		"ganador": "",
	}


## Qué le vence a [param tipo]: el anterior en la cadena circular.
static func vence_a(tipo: String) -> String:
	var i := TIPOS.find(tipo)
	return TIPOS[(i + TIPOS.size() - 1) % TIPOS.size()]


## Juega una ronda. [param habilidad] es el eje cuya habilidad se gasta, o
## cadena vacía para no gastar ninguna.
##
## Muta el combate y devuelve la crónica de la ronda, que es lo que la pantalla
## cuenta. El motor no sabe pintar y no elige textos: devuelve qué pasó.
static func jugar(
	combate: Dictionary, tipo_jugador: String, habilidad: String, azar: Callable
) -> Dictionary:
	if combate["terminado"]:
		return {}

	var gastada := _gastar(combate, habilidad)
	var tipo_rival := _jugada_rival(combate, azar)

	var veredicto := "empate"
	if vence_a(tipo_rival) == tipo_jugador:
		veredicto = "gana_jugador"
	elif vence_a(tipo_jugador) == tipo_rival:
		veredicto = "gana_rival"

	var dano := 2 if gastada == "neoliberal" else 1
	var a_jugador := 0
	var a_rival := 0
	match veredicto:
		"gana_jugador":
			a_rival = dano
		"gana_rival":
			a_jugador = dano
		"empate":
			# Asamblea es la única forma de que un empate haga algo.
			if gastada == "comunismo":
				a_rival = dano

	# Mesa de diálogo se resuelve al final, después de contar el daño: la
	# ronda se juega igual y lo que cambia es que no cuesta nada. Aplicarla
	# antes haría indistinguible ganar de empatar.
	if gastada == "centrista":
		a_jugador = 0
		a_rival = 0

	combate["vida_jugador"] -= a_jugador
	combate["vida_rival"] -= a_rival
	combate["ronda"] += 1
	combate["ultima_jugada_jugador"] = TIPOS.find(tipo_jugador)

	# La Comisión de seguimiento decide YA la jugada de la ronda siguiente.
	if gastada == "socialdemocrata":
		# `jugada_rival` YA devuelve el índice dentro de TIPOS: buscarlo otra
		# vez con find() daba -1, o sea que la habilidad no revelaba nada.
		combate["revelada"] = Prometeo.jugada_rival(
			combate["modo"], combate["ronda"], TIPOS.size(), azar, combate["ultima_jugada_jugador"]
		)

	_comprobar_final(combate)

	return {
		"tipo_jugador": tipo_jugador,
		"tipo_rival": tipo_rival,
		"veredicto": veredicto,
		"habilidad": gastada,
		"dano_al_jugador": a_jugador,
		"dano_al_rival": a_rival,
		"revelada": etiqueta(TIPOS[combate["revelada"]]) if combate["revelada"] >= 0 else "",
		"replica": _replica(combate, azar),
		"terminado": combate["terminado"],
		"ganador": combate["ganador"],
	}


## Las cargas que quedan sin gastar.
static func cargas_disponibles(combate: Dictionary) -> Dictionary:
	var vivas := {}
	for eje in combate["cargas"]:
		if combate["cargas"][eje] > 0:
			vivas[eje] = combate["cargas"][eje]
	return vivas


static func _gastar(combate: Dictionary, habilidad: String) -> String:
	if habilidad.is_empty() or combate["cargas"].get(habilidad, 0) <= 0:
		return ""
	combate["cargas"][habilidad] -= 1
	return habilidad


static func _jugada_rival(combate: Dictionary, azar: Callable) -> String:
	if combate["revelada"] >= 0:
		var anunciada: String = TIPOS[combate["revelada"]]
		combate["revelada"] = -1
		return anunciada
	return TIPOS[Prometeo.jugada_rival(
		combate["modo"], combate["ronda"], TIPOS.size(), azar, combate["ultima_jugada_jugador"]
	)]


static func _comprobar_final(combate: Dictionary) -> void:
	if combate["vida_rival"] <= 0:
		combate["terminado"] = true
		combate["ganador"] = "jugador"
	elif combate["vida_jugador"] <= 0:
		combate["terminado"] = true
		combate["ganador"] = "rival"


## La réplica del rival es SOLO ambiente: sale de sus `ataques` y no cambia
## nada del juego. Un rival sin réplicas escritas no dice nada, en vez de
## decir algo genérico que rompería el tono.
static func _replica(combate: Dictionary, azar: Callable) -> String:
	var replicas: Array = combate["rival"].get("ataques", [])
	if replicas.is_empty():
		return ""
	return replicas[int(azar.call() * replicas.size()) % replicas.size()]
