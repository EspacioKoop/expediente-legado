## Estado mínimo de las rutinas domésticas opcionales de la casa (#675).
##
## No modela necesidades ni progreso: solo recuerda posiciones físicas que el
## jugador ha decidido cambiar. Tres estados sobreviven entre jornadas porque
## describen cómo quedó la casa; nevera y ventana se cierran al cambiar de día
## para no convertir un gesto puntual en una simulación de mantenimiento.
class_name CasaRutinas
extends RefCounted

const CLAVE := "casa_rutinas"
const CLAVE_DIA := "dia"

const PERSIANA_ABIERTA := "persiana_abierta"
const VENTANA_ABIERTA := "ventana_abierta"
const NEVERA_ABIERTA := "nevera_abierta"
const PLATOS_RECOGIDOS := "platos_recogidos"
const TOALLA_TENDIDA := "toalla_tendida"

const PERSISTENTES := [PERSIANA_ABIERTA, PLATOS_RECOGIDOS, TOALLA_TENDIDA]
const DIARIAS := [VENTANA_ABIERTA, NEVERA_ABIERTA]
const TODAS := [
	PERSIANA_ABIERTA,
	VENTANA_ABIERTA,
	NEVERA_ABIERTA,
	PLATOS_RECOGIDOS,
	TOALLA_TENDIDA,
]


static func completar(jornada: Dictionary) -> Dictionary:
	var bruto = jornada.get(CLAVE, {})
	var estado: Dictionary
	if typeof(bruto) == TYPE_DICTIONARY:
		estado = bruto
	else:
		estado = {}
		jornada[CLAVE] = estado

	for clave in TODAS:
		if not estado.has(clave):
			estado[clave] = false

	var dia := maxi(1, int(jornada.get("dia", 1)))
	if not estado.has(CLAVE_DIA):
		estado[CLAVE_DIA] = dia
	elif int(estado.get(CLAVE_DIA, dia)) != dia:
		for clave in DIARIAS:
			estado[clave] = false
		estado[CLAVE_DIA] = dia
	return estado


## Snapshot de solo lectura para el contrato ambiental (#96). No inicializa ni
## corrige el guardado; aplica defaults sobre una copia.
static func estado(jornada: Dictionary) -> Dictionary:
	var bruto = jornada.get(CLAVE, {})
	var copia: Dictionary = bruto.duplicate(true) if typeof(bruto) == TYPE_DICTIONARY else {}
	for clave in TODAS:
		if not copia.has(clave):
			copia[clave] = false
	var dia := maxi(1, int(jornada.get("dia", 1)))
	if int(copia.get(CLAVE_DIA, dia)) != dia:
		for clave in DIARIAS:
			copia[clave] = false
	copia[CLAVE_DIA] = dia
	return copia


static func valor(jornada: Dictionary, clave: String) -> bool:
	if not TODAS.has(clave):
		return false
	return bool(completar(jornada).get(clave, false))


static func establecer(jornada: Dictionary, clave: String, activo: bool) -> bool:
	if not TODAS.has(clave):
		return false
	completar(jornada)[clave] = activo
	return true


static func alternar(jornada: Dictionary, clave: String) -> bool:
	if not TODAS.has(clave):
		return false
	var nuevo := not valor(jornada, clave)
	establecer(jornada, clave, nuevo)
	return nuevo


static func es_persistente(clave: String) -> bool:
	return PERSISTENTES.has(clave)
