## Condiciones opcionales de una vida laboral (#152).
##
## Mantiene un estado pequeño, determinista y guardable: qué se aceptó antes de
## empezar, qué sigue vivo y qué terminó fallando o completándose. También
## expone adaptadores mínimos para hechos que ya existen en la partida (como
## fichar con cero acciones), sin duplicar las reglas de Jornada ni de la UI.
class_name Auditorias
extends RefCounted

const CLAVE_ESTADO := "auditorias"
const ACCION_SOBRANTE := "accion_sobrante"

## El contrato base solo declara identidades e incompatibilidades. Los rótulos
## pertenecen a la futura capa de selección/consulta: declarar aquí claves de
## traducción que ninguna UI consume las convertiría en texto huérfano (#105).
const CATALOGO := {
	"sin_releer": {"incompatibles": []},
	"accion_sobrante": {"incompatibles": []},
	"gato_diario": {"incompatibles": []},
	"sueno_completo": {"incompatibles": []},
}


static func ids() -> Array:
	var resultado := CATALOGO.keys()
	resultado.sort()
	return resultado


## Crea el estado al COMENZAR la vida. No hay API para añadir condiciones
## después: quien quiera cambiarlas tiene que iniciar otra vida laboral.
static func nueva(seleccion: Array = []) -> Dictionary:
	if not compatibles(seleccion):
		return {}
	var activas := []
	for valor in seleccion:
		activas.append(String(valor))
	activas.sort()
	return {
		"activas": activas,
		"fallidas": {},
		"completadas": [],
	}


## Recupera el bloque persistido, migrando partidas antiguas que aún no lo tenían.
static func asegurar_en_estado(estado_partida: Dictionary) -> Dictionary:
	var actual = estado_partida.get(CLAVE_ESTADO, {})
	if typeof(actual) != TYPE_DICTIONARY:
		actual = nueva()
		estado_partida[CLAVE_ESTADO] = actual
	elif not estado_partida.has(CLAVE_ESTADO):
		estado_partida[CLAVE_ESTADO] = actual
	return actual


## Una reasignación empieza otra vida laboral: ninguna condición de la anterior
## puede sobrevivir sin que el jugador vuelva a aceptarla.
static func reiniciar_vuelta(estado_partida: Dictionary) -> void:
	estado_partida[CLAVE_ESTADO] = nueva()


## Primer predicado conectado extremo a extremo: al fichar, "accion_sobrante"
## exige que quede al menos una acción. Observa el hecho antes de que Jornada
## cambie de fase; no cobra, no bloquea la salida y no concede recompensa.
static func resolver_fin_archivo(estado_partida: Dictionary) -> Dictionary:
	var auditoria := asegurar_en_estado(estado_partida)
	if estado(auditoria, ACCION_SOBRANTE) != "activa":
		return {"resultado": "inactiva", "id": ACCION_SOBRANTE}

	var jornada = estado_partida.get("jornada", {})
	if typeof(jornada) != TYPE_DICTIONARY:
		return {"resultado": "sin-jornada", "id": ACCION_SOBRANTE}

	var acciones := int(jornada.get("acciones", 0))
	if acciones <= 0:
		fallar(auditoria, ACCION_SOBRANTE, "sin_accion_al_fichar")
		return {"resultado": "fallida", "id": ACCION_SOBRANTE, "acciones": acciones}
	return {"resultado": "activa", "id": ACCION_SOBRANTE, "acciones": acciones}


## Valida únicamente estructura e invariantes persistibles. Las reglas de
## gameplay se evalúan en sus fronteras de evento, no durante la carga.
static func validar(auditoria) -> Array:
	if typeof(auditoria) != TYPE_DICTIONARY:
		return ["raiz no es un objeto"]

	var errores := []
	for clave in ["activas", "completadas"]:
		if not auditoria.has(clave):
			errores.append("%s ausente" % clave)
		elif typeof(auditoria[clave]) != TYPE_ARRAY:
			errores.append("%s no es una lista" % clave)
	if not auditoria.has("fallidas"):
		errores.append("fallidas ausente")
	elif typeof(auditoria["fallidas"]) != TYPE_DICTIONARY:
		errores.append("fallidas no es un objeto")
	if not errores.is_empty():
		return errores

	var activas: Array = auditoria["activas"]
	if not compatibles(activas):
		errores.append("seleccion invalida")

	var completadas: Array = auditoria["completadas"]
	var completadas_vistas := {}
	for valor in completadas:
		var id := String(valor)
		if completadas_vistas.has(id):
			errores.append("completada duplicada: %s" % id)
			continue
		completadas_vistas[id] = true
		if not CATALOGO.has(id) or not activas.has(id):
			errores.append("completada fuera de seleccion: %s" % id)

	var fallidas: Dictionary = auditoria["fallidas"]
	for clave in fallidas:
		var id := String(clave)
		if not CATALOGO.has(id) or not activas.has(id):
			errores.append("fallida fuera de seleccion: %s" % id)
		if typeof(fallidas[clave]) != TYPE_STRING:
			errores.append("motivo de fallo invalido: %s" % id)
		if completadas_vistas.has(id):
			errores.append("estado terminal duplicado: %s" % id)
	return errores


static func compatibles(seleccion: Array) -> bool:
	var vistas := {}
	for valor in seleccion:
		var id := String(valor)
		if not CATALOGO.has(id) or vistas.has(id):
			return false
		vistas[id] = true
		for otro in CATALOGO[id].get("incompatibles", []):
			if seleccion.has(otro):
				return false
	return true


static func estado(auditoria: Dictionary, id: String) -> String:
	if auditoria.get("fallidas", {}).has(id):
		return "fallida"
	if auditoria.get("completadas", []).has(id):
		return "completada"
	if auditoria.get("activas", []).has(id):
		return "activa"
	return "inactiva"


## Fallar es irreversible durante la vida. El motivo es una clave técnica para
## que UI/pruebas puedan explicar qué ocurrió sin convertirlo en puntuación.
static func fallar(auditoria: Dictionary, id: String, motivo: String = "") -> bool:
	if estado(auditoria, id) != "activa":
		return false
	auditoria["fallidas"][id] = motivo
	return true


## Completar solo es válido si la condición sobrevivió toda la vida.
static func completar(auditoria: Dictionary, id: String) -> bool:
	if estado(auditoria, id) != "activa":
		return false
	auditoria["completadas"].append(id)
	auditoria["completadas"].sort()
	return true


static func pendientes(auditoria: Dictionary) -> Array:
	var resultado := []
	for id in auditoria.get("activas", []):
		if estado(auditoria, id) == "activa":
			resultado.append(id)
	return resultado
