## Registro persistente del pasaporte de inspección (#154).
##
## El catálogo describe puntos físicos ya existentes. Esta capa no sabe de UI
## ni concede recursos: traduce observaciones deliberadas a ids estables dentro
## del almacén que Partida ya persiste y deriva variantes solo de hechos reales
## presentes en la Jornada guardada.
class_name PasaporteInspeccion
extends RefCounted

const RUTA_CATALOGO := "res://datos/puntos_inspeccion.json"
const PREFIJO_SELLO := "inspeccion:"
const SEPARADOR_VARIANTE := "@"
const ZONAS := ["archivo", "trayecto", "casa", "sueño"]
const CONDICIONES_ESPECIALES := ["noche", "lluvia", "reasignacion", "gato-ausente"]


static func catalogo() -> Array:
	var fichero := FileAccess.open(RUTA_CATALOGO, FileAccess.READ)
	if fichero == null:
		push_error("No se pudo abrir %s" % RUTA_CATALOGO)
		return []
	var datos = JSON.parse_string(fichero.get_as_text())
	fichero.close()
	if typeof(datos) != TYPE_ARRAY:
		push_error("El catálogo de puntos de inspección no es una lista")
		return []
	return datos


static func ficha(punto_id: String) -> Dictionary:
	for entrada in catalogo():
		if String(entrada.get("id", "")) == punto_id:
			return entrada
	return {}


static func sello_id(punto_id: String) -> String:
	return PREFIJO_SELLO + punto_id


static func variante_id(punto_id: String, condicion: String) -> String:
	return sello_id(punto_id) + SEPARADOR_VARIANTE + condicion


static func observado(estado: Dictionary, punto_id: String) -> bool:
	var obtenidos: Array = estado.get(Sellos.CLAVE_ESTADO, [])
	return obtenidos.has(sello_id(punto_id))


static func variantes(estado: Dictionary, punto_id: String) -> Array:
	var obtenidos: Array = estado.get(Sellos.CLAVE_ESTADO, [])
	var resultado := []
	for condicion in CONDICIONES_ESPECIALES:
		if obtenidos.has(variante_id(punto_id, condicion)):
			resultado.append(condicion)
	return resultado


## Condiciones que se pueden demostrar desde la Jornada persistida.
##
## No se inventa un reloj paralelo ni una bandera de clima: Jornada y Clima
## siguen siendo las fuentes de verdad. "Tras salir del sueño" queda fuera hasta
## que exista un hecho persistido que distinga ese instante de cualquier mañana.
static func condiciones_activas(estado: Dictionary) -> Array:
	var jornada = estado.get("jornada", {})
	if typeof(jornada) != TYPE_DICTIONARY:
		return []

	var activas := []
	if Jornada.franja_horaria(jornada) == "noche":
		activas.append("noche")
	if Clima.estado(int(jornada.get("dia", 1))) == Clima.LLUVIA:
		activas.append("lluvia")
	if int(jornada.get("vuelta", 1)) > 1:
		activas.append("reasignacion")

	var gato = jornada.get("gato", {})
	if typeof(gato) == TYPE_DICTIONARY and not bool(gato.get("presente", true)):
		activas.append("gato-ausente")
	return activas


## Registra una observación deliberada una sola vez.
##
## No concede un sello del catálogo general: usa su almacén persistente para no
## crear otro sistema de guardado, pero mantiene un prefijo propio hasta que el
## pasaporte tenga una superficie de consulta específica.
static func registrar_observacion(estado: Dictionary, punto_id: String) -> Dictionary:
	var entrada := ficha(punto_id)
	if entrada.is_empty():
		return {"resultado": "desconocido", "id": punto_id}
	if String(entrada.get("modo_observacion", "")) != "examinar":
		return {"resultado": "modo-invalido", "id": punto_id}

	var id_sello := sello_id(punto_id)
	var obtenidos: Array = estado.get(Sellos.CLAVE_ESTADO, []).duplicate()
	if obtenidos.has(id_sello):
		return {
			"resultado": "ya-observado",
			"id": punto_id,
			"sello": id_sello,
			"zona": String(entrada.get("zona", "")),
		}

	obtenidos.append(id_sello)
	estado[Sellos.CLAVE_ESTADO] = obtenidos
	return {
		"resultado": "registrado",
		"id": punto_id,
		"sello": id_sello,
		"zona": String(entrada.get("zona", "")),
	}


## Registro usado por el runtime: prueba que el jugador está en la zona del
## punto, registra la observación base y añade únicamente variantes demostrables
## desde el mismo estado persistido. Repetir no escribe ids duplicados.
static func registrar_observacion_contextual(estado: Dictionary, punto_id: String) -> Dictionary:
	var entrada := ficha(punto_id)
	if entrada.is_empty():
		return {"resultado": "desconocido", "id": punto_id, "cambio": false}

	var jornada = estado.get("jornada", {})
	if typeof(jornada) != TYPE_DICTIONARY:
		return {"resultado": "sin-jornada", "id": punto_id, "cambio": false}

	var zona := String(entrada.get("zona", ""))
	if String(jornada.get("fase", "")) != zona:
		return {
			"resultado": "zona-invalida",
			"id": punto_id,
			"zona": zona,
			"cambio": false,
		}

	var base := registrar_observacion(estado, punto_id)
	var nuevas := []
	var activas := condiciones_activas(estado)
	var obtenidos: Array = estado.get(Sellos.CLAVE_ESTADO, []).duplicate()
	for condicion in activas:
		var id_variante := variante_id(punto_id, String(condicion))
		if obtenidos.has(id_variante):
			continue
		obtenidos.append(id_variante)
		nuevas.append(condicion)
	if not nuevas.is_empty():
		estado[Sellos.CLAVE_ESTADO] = obtenidos

	return {
		"resultado": String(base.get("resultado", "")),
		"id": punto_id,
		"zona": zona,
		"variantes_activas": activas,
		"variantes_nuevas": nuevas,
		"cambio": String(base.get("resultado", "")) == "registrado" or not nuevas.is_empty(),
	}


static func progreso(estado: Dictionary) -> Dictionary:
	var por_zona := {}
	for zona in ZONAS:
		por_zona[zona] = {"observados": 0, "total": 0}

	var total := 0
	var observados := 0
	for entrada in catalogo():
		var zona := String(entrada.get("zona", ""))
		if not por_zona.has(zona):
			continue
		total += 1
		var resumen_zona: Dictionary = por_zona[zona]
		resumen_zona["total"] = int(resumen_zona["total"]) + 1
		if observado(estado, String(entrada.get("id", ""))):
			observados += 1
			resumen_zona["observados"] = int(resumen_zona["observados"]) + 1

	return {
		"observados": observados,
		"total": total,
		"completo": total > 0 and observados == total,
		"por_zona": por_zona,
	}


static func progreso_especial(estado: Dictionary) -> Dictionary:
	var por_condicion := {}
	for condicion in CONDICIONES_ESPECIALES:
		por_condicion[condicion] = 0

	var total := 0
	for entrada in catalogo():
		var punto_id := String(entrada.get("id", ""))
		for condicion in variantes(estado, punto_id):
			total += 1
			por_condicion[condicion] = int(por_condicion[condicion]) + 1
	return {"obtenidas": total, "por_condicion": por_condicion}
