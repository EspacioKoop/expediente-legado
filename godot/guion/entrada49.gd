## Modelo narrativo puro para la vertical "La Entrada 49" (#2469).
##
## No toca estado global ni el catálogo compartido. Modela la contradicción
## documental, las cuatro decisiones SIGA y la huella que un corte posterior
## puede consumir en diálogo, expediente o sueño.
class_name Entrada49
extends RefCounted

const REGISTRO_EXTRA := "E49-SIN-NOMBRE"
const DECISIONES := ["aislar", "validar", "borrar", "investigar"]


static func analizar_fuentes(datos: Dictionary) -> Dictionary:
	var fuentes: Array = datos.get("fuentes", [])
	var discrepancias := []
	var max_trabajadores := 0
	var max_raciones := 0
	for valor in fuentes:
		if not valor is Dictionary:
			continue
		var fuente := valor as Dictionary
		var trabajadores := int(fuente.get("trabajadores", 0))
		var raciones := int(fuente.get("raciones", 0))
		max_trabajadores = maxi(max_trabajadores, trabajadores)
		max_raciones = maxi(max_raciones, raciones)
		if raciones != trabajadores:
			(
				discrepancias
				. append(
					{
						"fuente": String(fuente.get("id", "")),
						"diferencia": raciones - trabajadores,
					}
				)
			)
	return {
		"fuentes_validas": fuentes.size(),
		"trabajadores": max_trabajadores,
		"raciones": max_raciones,
		"discrepancias": discrepancias,
		"patron_48_49": max_trabajadores == 48 and max_raciones == 49,
	}


static func procesar_importacion(datos: Dictionary, decision: String) -> Dictionary:
	if not DECISIONES.has(decision):
		return {"ok": false, "error": "decision_desconocida"}

	var extra: Dictionary = datos.get("registro_extra", {})
	var procedencia: Array = extra.get("procedencia", [])
	var resultado := {
		"ok": true,
		"decision": decision,
		"registro_id": String(extra.get("id", REGISTRO_EXTRA)),
		"procedencia": procedencia.duplicate(),
		"reaparece": false,
		"estado": "",
		"desbloqueos": [],
		"eco_onirico": {},
	}

	match decision:
		"aislar":
			resultado["estado"] = "cuarentena"
			resultado["desbloqueos"] = ["buscar_procedencia", "comparar_fuentes"]
			resultado["eco_onirico"] = _eco("archivo_sellado", 2)
		"validar":
			resultado["estado"] = "activo"
			resultado["desbloqueos"] = ["listar_personal_49"]
			resultado["eco_onirico"] = _eco("puesto_vacio_ocupado", 3)
		"borrar":
			resultado["estado"] = "eliminado"
			resultado["reaparece"] = true
			resultado["desbloqueos"] = ["auditar_reaparicion"]
			resultado["eco_onirico"] = _eco("tablilla_reescrita", 4)
		"investigar":
			resultado["estado"] = "pendiente_revision"
			resultado["desbloqueos"] = [
				"buscar_procedencia",
				"comparar_fuentes",
				"preguntar_companero",
			]
			resultado["eco_onirico"] = _eco("sala_de_tablillas", 5)
	return resultado


static func _eco(motivo: String, intensidad: int) -> Dictionary:
	return {
		"origen": "entrada49",
		"motivo": motivo,
		"intensidad": intensidad,
		"afirmacion_metafisica": false,
	}
