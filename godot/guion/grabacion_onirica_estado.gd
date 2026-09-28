## Estado persistente de la cinta onírica (#1682).
##
## Esta capa no mide encuadre ni decide si una toma es válida: delega esas
## reglas en GrabacionOniricaContrato. Su única responsabilidad es conservar
## una cinta evaluada dentro del estado canónico de Partida y exponer, de forma
## explícita, qué toma se ha seleccionado para una acusación.
class_name GrabacionOniricaEstado
extends RefCounted

const CLAVE_ESTADO := "grabacion_onirica"
const SIN_TOMA := -1
const ERROR_CINTA_NO_INICIADA := "cinta_no_iniciada"


static func nuevo() -> Dictionary:
	return {
		"cinta": {},
		"toma_seleccionada": SIN_TOMA,
	}


static func asegurar_en_estado(estado: Dictionary) -> Dictionary:
	var actual = estado.get(CLAVE_ESTADO, {})
	if typeof(actual) != TYPE_DICTIONARY:
		actual = nuevo()
	estado[CLAVE_ESTADO] = completar(actual)
	return estado[CLAVE_ESTADO]


static func completar(actual: Dictionary) -> Dictionary:
	var salida := actual.duplicate(true)
	if typeof(salida.get("cinta", {})) != TYPE_DICTIONARY:
		salida["cinta"] = {}
	else:
		salida["cinta"] = salida.get("cinta", {}).duplicate(true)
	var indice = salida.get("toma_seleccionada", SIN_TOMA)
	salida["toma_seleccionada"] = int(indice) if _entero(indice) else SIN_TOMA
	return salida


static func iniciar_cinta(estado: Dictionary, capacidad_segundos: float) -> Dictionary:
	var contenedor := asegurar_en_estado(estado)
	contenedor["cinta"] = GrabacionOniricaContrato.nueva_cinta(capacidad_segundos)
	contenedor["toma_seleccionada"] = SIN_TOMA
	return contenedor["cinta"].duplicate(true)


## Registra la evaluación producida por el contrato sin seleccionar
## implícitamente qué toma acabará ante el jurado. La elección es una operación
## aparte para evitar una política oculta de «la última siempre gana».
static func registrar_toma(estado: Dictionary, datos: Dictionary) -> Dictionary:
	var contenedor := asegurar_en_estado(estado)
	var cinta: Dictionary = contenedor.get("cinta", {})
	if cinta.is_empty():
		return {
			"ok": false,
			"error": ERROR_CINTA_NO_INICIADA,
			"cinta": {},
		}

	var resultado := GrabacionOniricaContrato.registrar_toma(cinta, datos)
	if bool(resultado.get("ok", false)):
		contenedor["cinta"] = resultado.get("cinta", {}).duplicate(true)
	return resultado.duplicate(true)


static func seleccionar_toma(estado: Dictionary, indice: int) -> bool:
	var contenedor := asegurar_en_estado(estado)
	var cinta: Dictionary = contenedor.get("cinta", {})
	var tomas = cinta.get("tomas", [])
	if typeof(tomas) != TYPE_ARRAY or indice < 0 or indice >= tomas.size():
		return false
	contenedor["toma_seleccionada"] = indice
	return true


static func seleccion_actual(estado: Dictionary) -> Dictionary:
	var contenedor := asegurar_en_estado(estado)
	var cinta: Dictionary = contenedor.get("cinta", {})
	var tomas = cinta.get("tomas", [])
	if typeof(tomas) != TYPE_ARRAY:
		return {}
	var indice := int(contenedor.get("toma_seleccionada", SIN_TOMA))
	if indice < 0 or indice >= tomas.size():
		return {}
	var evaluacion = tomas[indice]
	return evaluacion.duplicate(true) if typeof(evaluacion) == TYPE_DICTIONARY else {}


## Devuelve exclusivamente una toma YA evaluada y explícitamente seleccionada
## cuyo original pertenece al expediente firmado. No reevalúa la grabación y
## no consume, borra ni modifica la cinta.
static func para_caso(estado: Dictionary, caso: Dictionary) -> Dictionary:
	var evaluacion := seleccion_actual(estado)
	if evaluacion.is_empty():
		return {}

	var toma = evaluacion.get("toma", {})
	if typeof(toma) != TYPE_DICTIONARY:
		return {}
	var original_id := String(toma.get("original_id", "")).strip_edges()
	if original_id.is_empty() or not _caso_contiene_original(caso, original_id):
		return {}

	var proyeccion := GrabacionOniricaContrato.para_proyeccion(evaluacion)
	proyeccion["original_id"] = original_id
	proyeccion["toma_indice"] = int(asegurar_en_estado(estado).get("toma_seleccionada", SIN_TOMA))
	return proyeccion


static func _caso_contiene_original(caso: Dictionary, original_id: String) -> bool:
	var registros = caso.get("registros", [])
	if typeof(registros) != TYPE_ARRAY:
		return false
	for registro in registros:
		if typeof(registro) != TYPE_DICTIONARY:
			continue
		if String(registro.get("id", "")).strip_edges() == original_id:
			return true
	return false


static func validar(actual) -> Array:
	var errores := []
	if typeof(actual) != TYPE_DICTIONARY:
		return ["no es un objeto"]

	var cinta = actual.get("cinta", {})
	if typeof(cinta) != TYPE_DICTIONARY:
		errores.append("cinta no es un objeto")
		return errores

	var indice = actual.get("toma_seleccionada", SIN_TOMA)
	if not _entero(indice) or int(indice) < SIN_TOMA:
		errores.append("toma_seleccionada inválida")

	if cinta.is_empty():
		if _entero(indice) and int(indice) != SIN_TOMA:
			errores.append("toma seleccionada sin cinta")
		return errores

	for clave in ["capacidad_segundos", "metraje_restante", "tomas"]:
		if not cinta.has(clave):
			errores.append("cinta.%s ausente" % clave)

	var capacidad = cinta.get("capacidad_segundos", -1.0)
	var restante = cinta.get("metraje_restante", -1.0)
	if not _numero_no_negativo(capacidad):
		errores.append("cinta.capacidad_segundos inválida")
	if not _numero_no_negativo(restante):
		errores.append("cinta.metraje_restante inválido")
	if _numero_no_negativo(capacidad) and _numero_no_negativo(restante):
		if float(restante) > float(capacidad):
			errores.append("cinta.metraje_restante supera capacidad")

	var tomas = cinta.get("tomas", [])
	if typeof(tomas) != TYPE_ARRAY:
		errores.append("cinta.tomas no es una lista")
		return errores

	for i in tomas.size():
		var evaluacion = tomas[i]
		if typeof(evaluacion) != TYPE_DICTIONARY:
			errores.append("cinta.tomas[%d] no es un objeto" % i)
			continue
		var estado := String(evaluacion.get("estado", ""))
		if (
			estado
			not in [
				GrabacionOniricaContrato.ESTADO_VALIDA,
				GrabacionOniricaContrato.ESTADO_CONTAMINADA,
			]
		):
			errores.append("cinta.tomas[%d].estado inválido" % i)
		if typeof(evaluacion.get("motivos", [])) != TYPE_ARRAY:
			errores.append("cinta.tomas[%d].motivos no es una lista" % i)
		if typeof(evaluacion.get("toma", {})) != TYPE_DICTIONARY:
			errores.append("cinta.tomas[%d].toma no es un objeto" % i)

	if _entero(indice) and int(indice) >= tomas.size():
		errores.append("toma_seleccionada fuera de rango")
	return errores


static func _numero_no_negativo(valor) -> bool:
	return (
		typeof(valor) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(valor)) and float(valor) >= 0.0
	)


static func _entero(valor) -> bool:
	if typeof(valor) == TYPE_INT:
		return true
	if typeof(valor) != TYPE_FLOAT or not is_finite(valor):
		return false
	return floor(valor) == valor
