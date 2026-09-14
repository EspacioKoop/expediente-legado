## Contrato standalone del sueño del Minotauro (#437).
##
## Este módulo no decide todavía cuándo entra la familia en la noche ni monta
## geometría. Fija la parte peligrosa antes de integrarla: una topología real
## siempre navegable, una topología aparente que puede replegarse, marcas que
## quedan ancladas al espacio real y una presencia que solo bloquea nodos si
## sigue existiendo una ruta recuperable hasta la salida.
class_name SuenoMinotauro
extends RefCounted

const SEMILLA := "semilla_onirica_minotauro"
const MAX_MARCAS := 4

const ENTRADA := "entrada"
const VESTIBULO := "vestibulo"
const CRUCE_NORTE := "cruce_norte"
const CRUCE_SUR := "cruce_sur"
const ARCHIVO_ESTE := "archivo_este"
const ARCHIVO_RETORNO := "archivo_retorno"
const BISAGRA := "bisagra"
const CENTRO := "centro"
const SALIDA := "salida"

const PRESENCIAS := ["lejano", "respiracion", "cruce", "cerca"]
const TRANSFORMACIONES := ["estable", "repliegue", "mobius", "escala_imposible"]

## El grafo real no se reescribe durante la noche. Lo que cambia es qué nodo
## parece ocupar cada sitio. Separar ambas cosas permite hacer un espacio
## imposible sin que la salida deje de existir por una mutación visual.
static var _vecinos := {
	ENTRADA: [VESTIBULO],
	VESTIBULO: [ENTRADA, CRUCE_NORTE, CRUCE_SUR],
	CRUCE_NORTE: [VESTIBULO, ARCHIVO_ESTE, BISAGRA],
	CRUCE_SUR: [VESTIBULO, ARCHIVO_RETORNO, BISAGRA],
	ARCHIVO_ESTE: [CRUCE_NORTE, CENTRO],
	ARCHIVO_RETORNO: [CRUCE_SUR, CENTRO],
	BISAGRA: [CRUCE_NORTE, CRUCE_SUR, CENTRO],
	CENTRO: [ARCHIVO_ESTE, ARCHIVO_RETORNO, BISAGRA, SALIDA],
	SALIDA: [CENTRO],
}

## Coordenadas de referencia para que la integración 3D pueda construir nodos
## reconocibles en vez de una retícula uniforme. Son anclas, no un layout final.
static var _posiciones := {
	ENTRADA: Vector3(0, 0, 16),
	VESTIBULO: Vector3(0, 0, 10),
	CRUCE_NORTE: Vector3(-8, 0, 5),
	CRUCE_SUR: Vector3(7, 0, 3),
	ARCHIVO_ESTE: Vector3(-12, 0, -4),
	ARCHIVO_RETORNO: Vector3(12, 0, -6),
	BISAGRA: Vector3(1, 0, -2),
	CENTRO: Vector3(0, 0, -12),
	SALIDA: Vector3(-2, 0, -20),
}


static func habilitada(semillas: Dictionary) -> bool:
	return bool(semillas.get(SEMILLA, false))


static func registrar_semilla(semillas: Dictionary) -> void:
	semillas[SEMILLA] = true


static func estado_nuevo() -> Dictionary:
	return {
		"fase_topologica": 0,
		"marcas": [],
		"cruces": [],
		"presencia": PRESENCIAS[0],
		"bloqueo": "",
	}


static func plano() -> Dictionary:
	return {"vecinos": _vecinos.duplicate(true), "posiciones": _posiciones.duplicate(true)}


static func posicion(nodo: String) -> Vector3:
	return _posiciones.get(nodo, Vector3.ZERO)


## La fase altera la lectura visual del laberinto mediante permutaciones
## biyectivas. Una marca queda ligada al id real y por eso puede reaparecer en
## otro cruce aparente después de un repliegue.
static func nodo_real(nodo_aparente: String, fase: int) -> String:
	var normalizada := posmod(fase, TRANSFORMACIONES.size())
	if normalizada == 1:
		return _intercambiar(nodo_aparente, ARCHIVO_ESTE, ARCHIVO_RETORNO)
	if normalizada == 2:
		return _intercambiar(nodo_aparente, CRUCE_NORTE, CRUCE_SUR)
	if normalizada == 3:
		var primero := _intercambiar(nodo_aparente, ARCHIVO_ESTE, ARCHIVO_RETORNO)
		return _intercambiar(primero, CRUCE_NORTE, CRUCE_SUR)
	return nodo_aparente


static func nodo_aparente(nodo_real_id: String, fase: int) -> String:
	for candidato in _vecinos.keys():
		if nodo_real(String(candidato), fase) == nodo_real_id:
			return String(candidato)
	return nodo_real_id


static func transformacion_actual(estado: Dictionary) -> String:
	var fase := posmod(int(estado.get("fase_topologica", 0)), TRANSFORMACIONES.size())
	return TRANSFORMACIONES[fase]


## Accesibilidad: la regla topológica no cambia con reducción de movimiento;
## solo cambia cómo debe representarse la transición al integrarla en 3D.
static func presentacion_transformacion(estado: Dictionary, reduccion_movimiento: bool) -> String:
	if transformacion_actual(estado) == TRANSFORMACIONES[0]:
		return "ninguna"
	return "fundido_discreto" if reduccion_movimiento else "repliegue_continuo"


## Cruzar la bisagra o el centro repliega el espacio. El evento es determinista
## y no usa azar: misma ruta, mismas transformaciones, también tras recargar.
static func cruzar(estado: Dictionary, nodo_real_id: String) -> bool:
	if not _vecinos.has(nodo_real_id):
		return false
	var cruces: Array = estado.get("cruces", [])
	cruces.append(nodo_real_id)
	estado["cruces"] = cruces
	if nodo_real_id == BISAGRA or nodo_real_id == CENTRO:
		estado["fase_topologica"] = posmod(
			int(estado.get("fase_topologica", 0)) + 1, TRANSFORMACIONES.size()
		)
	return true


static func poner_marca(estado: Dictionary, nodo_aparente_id: String) -> bool:
	if not _vecinos.has(nodo_aparente_id):
		return false
	var marcas: Array = estado.get("marcas", [])
	if marcas.size() >= MAX_MARCAS:
		return false
	var fase := int(estado.get("fase_topologica", 0))
	var real := nodo_real(nodo_aparente_id, fase)
	for marca in marcas:
		if String(marca.get("real", "")) == real:
			return false
	marcas.append(
		{
			"real": real,
			"aparente_inicial": nodo_aparente_id,
			"fase_inicial": fase,
		}
	)
	estado["marcas"] = marcas
	return true


static func leer_marca(estado: Dictionary, indice: int) -> Dictionary:
	var marcas: Array = estado.get("marcas", [])
	if indice < 0 or indice >= marcas.size():
		return {}
	var marca: Dictionary = marcas[indice]
	var fase := int(estado.get("fase_topologica", 0))
	var aparece := nodo_aparente(String(marca.get("real", "")), fase)
	var inicial := String(marca.get("aparente_inicial", ""))
	return {
		"real": marca.get("real", ""),
		"aparece_en": aparece,
		"lectura": "estable" if aparece == inicial else "desplazada",
	}


static func vecinos_reales(nodo: String, bloqueado: String = "") -> Array:
	if not _vecinos.has(nodo) or nodo == bloqueado:
		return []
	var resultado := []
	for vecino in _vecinos[nodo]:
		if String(vecino) != bloqueado:
			resultado.append(vecino)
	return resultado


## BFS explícito: esta es la garantía que usa la presencia antes de cerrar una
## ruta. Nunca se acepta un bloqueo porque "parezca" que queda otra salida.
static func ruta(desde: String, hasta: String, bloqueado: String = "") -> Array:
	if not _vecinos.has(desde) or not _vecinos.has(hasta):
		return []
	if desde == bloqueado or hasta == bloqueado:
		return []
	var cola := [desde]
	var anteriores := {desde: ""}
	while not cola.is_empty():
		var actual := String(cola.pop_front())
		if actual == hasta:
			break
		for vecino in vecinos_reales(actual, bloqueado):
			var id := String(vecino)
			if anteriores.has(id):
				continue
			anteriores[id] = actual
			cola.append(id)
	if not anteriores.has(hasta):
		return []
	var resultado := []
	var cursor := hasta
	while not cursor.is_empty():
		resultado.push_front(cursor)
		cursor = String(anteriores.get(cursor, ""))
	return resultado


static func hay_ruta(desde: String, hasta: String = SALIDA, bloqueado: String = "") -> bool:
	return not ruta(desde, hasta, bloqueado).is_empty()


## La presencia escala por decisiones espaciales, no por reflejos. Puede cerrar
## temporalmente un nodo, pero solo después de demostrar que el jugador conserva
## una ruta a SALIDA desde su posición actual. Si ningún candidato es seguro,
## no bloquea nada.
static func responder_minotauro(estado: Dictionary, nodo_actual: String) -> Dictionary:
	if not _vecinos.has(nodo_actual):
		return {"presencia": PRESENCIAS[0], "bloqueo": "", "ruta_recuperable": false}
	var cruces: Array = estado.get("cruces", [])
	var nivel := mini(cruces.size(), PRESENCIAS.size() - 1)
	var presencia: String = String(PRESENCIAS[nivel])
	var candidatos := [ARCHIVO_RETORNO, CRUCE_SUR, ARCHIVO_ESTE, CRUCE_NORTE]
	var bloqueo := ""
	if nivel >= 2:
		for candidato in candidatos:
			var id := String(candidato)
			if id == nodo_actual:
				continue
			if hay_ruta(nodo_actual, SALIDA, id):
				bloqueo = id
				break
	estado["presencia"] = presencia
	estado["bloqueo"] = bloqueo
	return {
		"presencia": presencia,
		"bloqueo": bloqueo,
		"ruta_recuperable": hay_ruta(nodo_actual, SALIDA, bloqueo),
	}


static func liberar_bloqueo(estado: Dictionary) -> void:
	estado["bloqueo"] = ""


static func _intercambiar(valor: String, a: String, b: String) -> String:
	if valor == a:
		return b
	if valor == b:
		return a
	return valor
