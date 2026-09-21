## Las ocho historias políticas de las cartas ocultas.
##
## Encontrar una carta escondida en un documento abre un relato con cuatro
## salidas, una por eje. Lo que se elige hace tres cosas a la vez, y por eso
## este módulo es la bisagra de media capa de Prometeo:
##
## - **cuenta para el final político** (`Prometeo.eje_ganador`);
## - **da una carga de habilidad** para el combate, con tope de dos — la
##   partida política ES el equipamiento, sin pantalla de asignación;
## - **deja una secuela**, que apunta a una pista real todavía por descubrir si
##   la elección era la útil para ese expediente, o a una pista falsa si no.
##
## La corrección es POR SITUACIÓN y no por ideología: cada eje es útil en
## exactamente cuatro de las ocho cartas (invariante probada en
## `Prometeo.UTILIDAD_CARTAS`). Sin eso, el juego estaría diciendo cuál es la
## ideología buena — y eso sí sería moralizar.
class_name Historias
extends RefCounted

const CATALOGO := "res://datos/prometeo.json"

## Tope de cargas por eje. Elegir el mismo eje ocho veces no da ocho usos: dos
## es el techo, así que la ventaja de casarse con una ideología se agota.
const TOPE_CARGAS := 2

## Qué hace cada habilidad dentro de una ronda. Ninguna es un bonus pasivo:
## todas son una decisión que se gasta.
##
## `nombre` y `efecto` son CLAVES de traducción: el texto vive en
## `datos/textos.csv` y lo resuelve quien pinta el botón.
const HABILIDADES := {
	"comunismo":
	{
		"nombre": "HABILIDAD_ASAMBLEA",
		"efecto": "HABILIDAD_ASAMBLEA_EFECTO",
	},
	"centrista":
	{
		"nombre": "HABILIDAD_MESA",
		"efecto": "HABILIDAD_MESA_EFECTO",
	},
	"socialdemocrata":
	{
		"nombre": "HABILIDAD_COMISION",
		"efecto": "HABILIDAD_COMISION_EFECTO",
	},
	"neoliberal":
	{
		"nombre": "HABILIDAD_EXTERNALIZAR",
		"efecto": "HABILIDAD_EXTERNALIZAR_EFECTO",
	},
}

var catalogo: Dictionary = {}


func cargar(ruta: String = CATALOGO) -> bool:
	var fichero := FileAccess.open(ruta, FileAccess.READ)
	if fichero == null:
		push_error("No se pudo abrir %s" % ruta)
		return false
	var crudo = JSON.parse_string(fichero.get_as_text())
	fichero.close()
	if typeof(crudo) != TYPE_DICTIONARY:
		return false
	catalogo = crudo.get("historias", {})
	return not catalogo.is_empty()


func de(carta_id: String) -> Dictionary:
	return catalogo.get(carta_id, {})


## Qué enseñar al abrir una carta: sus cuatro opciones si está sin resolver, o
## su secuela si ya se decidió. Posponer no rerrollea ni sustituye opciones:
## solo deja constancia de que el jugador decidió volver después.
func vista(estado: Dictionary, carta_id: String) -> Dictionary:
	var historia := de(carta_id)
	if historia.is_empty():
		return {}

	var elegido = estado.get("historias_cartas", {}).get(carta_id)
	if elegido == null:
		return {
			"estado": "pospuesta" if esta_pospuesta(estado, carta_id) else "pendiente",
			"texto": historia["texto"],
			"opciones": historia["opciones"],
		}
	return {
		"estado": "resuelta",
		"texto": historia["texto"],
		"eje": elegido,
		"clasificacion": Prometeo.clasificar_eleccion(carta_id, elegido),
		"secuela": _secuela(historia, carta_id, elegido),
	}


## Registra que esta vez se cierra el relato sin elegir. No concede cargas,
## secuelas, puntos ni pistas: la historia sigue pendiente y puede reabrirse
## con exactamente el mismo catálogo. Repetir la operación es idempotente.
func postergar(estado: Dictionary, carta_id: String) -> bool:
	if de(carta_id).is_empty():
		return false
	if estado.get("historias_cartas", {}).has(carta_id):
		return false
	var pospuestas := _pospuestas(estado)
	if not pospuestas.has(carta_id):
		pospuestas.append(carta_id)
		pospuestas.sort()
	estado["historias_pospuestas"] = pospuestas
	return true


func esta_pospuesta(estado: Dictionary, carta_id: String) -> bool:
	var pospuestas = estado.get("historias_pospuestas", [])
	return typeof(pospuestas) == TYPE_ARRAY and pospuestas.has(carta_id)


## Registra la elección y devuelve lo que hay que contar. Muta el estado: la
## decisión es de la partida, no de la pantalla que la pregunta.
##
## Una historia ya resuelta NO se sobrescribe. En el original la asignación era
## incondicional y solo la interfaz impedía volver a preguntar, así que el
## primer sitio que llamara sin comprobarlo antes habría dejado cambiar el voto
## — y con él las cargas y el final.
func resolver(estado: Dictionary, carta_id: String, eje: String) -> Dictionary:
	var historia := de(carta_id)
	if historia.is_empty():
		return {}

	var historias: Dictionary = estado.get("historias_cartas", {})
	if not historias.has(carta_id):
		historias[carta_id] = eje
		estado["historias_cartas"] = historias
		_quitar_pospuesta(estado, carta_id)

	return vista(estado, carta_id)


## Las cargas de habilidad disponibles, por eje.
##
## La fuente ya no es solo Tarot: consume el contrato transversal de #919.
## Exposición y lectura social siguen sin conceder cargas.
func cargas(estado: Dictionary) -> Dictionary:
	return Prometeo.cargas_ideologicas(estado, TOPE_CARGAS)


## Cuántas historias quedan por decidir. Posponer no reduce este contador: el
## final político no llega hasta que se han resuelto las ocho.
func pendientes(estado: Dictionary) -> int:
	var resueltas: Dictionary = estado.get("historias_cartas", {})
	var quedan := 0
	for id in catalogo:
		if not resueltas.has(id):
			quedan += 1
	return quedan


func _pospuestas(estado: Dictionary) -> Array:
	var valor = estado.get("historias_pospuestas", [])
	return valor.duplicate() if typeof(valor) == TYPE_ARRAY else []


func _quitar_pospuesta(estado: Dictionary, carta_id: String) -> void:
	var pospuestas := _pospuestas(estado)
	if pospuestas.has(carta_id):
		pospuestas.erase(carta_id)
		estado["historias_pospuestas"] = pospuestas


func _secuela(historia: Dictionary, carta_id: String, eje: String) -> String:
	return (
		historia["secuelaUtil"]
		if Prometeo.clasificar_eleccion(carta_id, eje) == "pista"
		else historia["secuelaConfusion"]
	)
