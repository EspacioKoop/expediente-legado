## Reconstrucción opcional de expedientes a partir del catálogo real (#155).
##
## No inventa hechos ni mantiene una segunda cronología: las tarjetas conservan
## id, tipo, folio y fecha de los registros recibidos desde casos.json. La
## validación acepta secuencias parciales y solo comprueba compatibilidad
## cronológica entre los documentos disponibles.
class_name ReconstruccionExpediente
extends RefCounted

const COMPATIBLE := "orden_compatible"
const CONTRADICCION := "contradiccion"
const DATO_AUSENTE := "dato_ausente"

const RANGO_INCOMPLETO := "incompleto"
const RANGO_CONSISTENTE := "consistente"
const RANGO_EJEMPLAR := "ejemplar"


static func tarjetas(caso: Dictionary, visibles: Array = []) -> Array:
	var filtro := {}
	for id in visibles:
		filtro[String(id)] = true
	var resultado := []
	for registro in caso.get("registros", []):
		if typeof(registro) != TYPE_DICTIONARY:
			continue
		var id := String(registro.get("id", ""))
		if id.is_empty():
			continue
		if not filtro.is_empty() and not filtro.has(id):
			continue
		(
			resultado
			. append(
				{
					"id": id,
					"tipo": String(registro.get("tipo", "")),
					"folio": String(registro.get("folio", "")),
					"fecha": String(registro.get("fecha", "")),
				}
			)
		)
	return resultado


static func validar(caso: Dictionary, orden: Array) -> Dictionary:
	var por_id := {}
	for tarjeta in tarjetas(caso):
		por_id[tarjeta["id"]] = tarjeta

	var discrepancias := []
	var validas := []
	for id_bruto in orden:
		var id := String(id_bruto)
		if not por_id.has(id):
			discrepancias.append({"tipo": DATO_AUSENTE, "id": id})
			continue
		validas.append(por_id[id])

	for indice in range(1, validas.size()):
		var anterior: Dictionary = validas[indice - 1]
		var actual: Dictionary = validas[indice]
		var fecha_anterior := String(anterior.get("fecha", ""))
		var fecha_actual := String(actual.get("fecha", ""))
		if fecha_anterior.is_empty() or fecha_actual.is_empty():
			(
				discrepancias
				. append(
					{
						"tipo": DATO_AUSENTE,
						"id":
						(
							String(anterior["id"])
							if fecha_anterior.is_empty()
							else String(actual["id"])
						),
					}
				)
			)
		elif fecha_anterior > fecha_actual:
			(
				discrepancias
				. append(
					{
						"tipo": CONTRADICCION,
						"anterior": anterior["id"],
						"actual": actual["id"],
					}
				)
			)

	var contradicciones := 0
	var ausentes := 0
	for discrepancia in discrepancias:
		if discrepancia["tipo"] == CONTRADICCION:
			contradicciones += 1
		elif discrepancia["tipo"] == DATO_AUSENTE:
			ausentes += 1

	var total_catalogo := por_id.size()
	var cobertura := 0.0 if total_catalogo == 0 else float(validas.size()) / float(total_catalogo)
	var estado := COMPATIBLE if contradicciones == 0 and ausentes == 0 else CONTRADICCION
	if contradicciones == 0 and ausentes > 0:
		estado = DATO_AUSENTE
	return {
		"estado": estado,
		"discrepancias": discrepancias,
		"cobertura": cobertura,
		"puntuacion": _puntuacion(validas.size(), contradicciones, ausentes),
		"rango": _rango(cobertura, contradicciones, ausentes),
	}


static func ordenar_compatible(caso: Dictionary, visibles: Array = []) -> Array:
	var resultado := tarjetas(caso, visibles)
	resultado.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var fecha_a := String(a.get("fecha", ""))
			var fecha_b := String(b.get("fecha", ""))
			if fecha_a != fecha_b:
				return fecha_a < fecha_b
			return String(a.get("id", "")) < String(b.get("id", ""))
	)
	return resultado


static func _puntuacion(cantidad: int, contradicciones: int, ausentes: int) -> int:
	if cantidad == 0:
		return 0
	return maxi(0, 100 - contradicciones * 25 - ausentes * 10)


static func _rango(cobertura: float, contradicciones: int, ausentes: int) -> String:
	if contradicciones > 0 or ausentes > 0:
		return RANGO_INCOMPLETO
	if cobertura >= 1.0:
		return RANGO_EJEMPLAR
	return RANGO_CONSISTENTE
