## Registro mínimo del pasaporte de inspección (#154).
##
## El catálogo describe puntos físicos ya existentes. Esta capa no sabe de UI,
## economía ni escenas: únicamente traduce una observación deliberada a un id
## estable dentro de la persistencia de sellos que Partida ya guarda.
class_name PasaporteInspeccion
extends RefCounted

const RUTA_CATALOGO := "res://datos/puntos_inspeccion.json"
const PREFIJO_SELLO := "inspeccion:"
const ZONAS := ["archivo", "trayecto", "casa", "sueño"]


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


static func observado(estado: Dictionary, punto_id: String) -> bool:
	var obtenidos: Array = estado.get(Sellos.CLAVE_ESTADO, [])
	return obtenidos.has(sello_id(punto_id))


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
		por_zona[zona]["total"] = int(por_zona[zona]["total"]) + 1
		if observado(estado, String(entrada.get("id", ""))):
			observados += 1
			por_zona[zona]["observados"] = int(por_zona[zona]["observados"]) + 1

	return {
		"observados": observados,
		"total": total,
		"completo": total > 0 and observados == total,
		"por_zona": por_zona,
	}
