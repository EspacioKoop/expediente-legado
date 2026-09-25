## Copias falsificadas temporales para #951.
##
## Nunca escribe en el registro canónico ni en Partida. La calidad se calcula
## de forma determinista con apoyo material del propio folio y la atención
## documental del día.
class_name FalsificacionDocumental
extends RefCounted

const INTERVENCIONES := ["fecha", "sello", "firma"]


static func crear_copia(
	registro: Dictionary,
	intervencion: String,
	puntos_atencion: int,
) -> Dictionary:
	var tipo := intervencion.strip_edges().to_lower()
	if registro.is_empty() or not INTERVENCIONES.has(tipo):
		return {}

	var apoyo := _apoyo_material(registro, tipo)
	var atencion := 0
	if puntos_atencion >= 4:
		atencion = 2
	elif puntos_atencion >= 2:
		atencion = 1

	var puntuacion := apoyo + atencion
	var calidad := "baja"
	var riesgo := "alto"
	if puntuacion >= 4:
		calidad = "alta"
		riesgo = "bajo"
	elif puntuacion >= 2:
		calidad = "media"
		riesgo = "medio"

	return {
		"registro_id": String(registro.get("id", "")),
		"intervencion": tipo,
		"calidad": calidad,
		"riesgo": riesgo,
		"temporal": true,
	}


static func _apoyo_material(registro: Dictionary, intervencion: String) -> int:
	var contenido := String(registro.get("contenido", "")).to_lower()
	match intervencion:
		"fecha":
			return 2 if not String(registro.get("fecha", "")).is_empty() else 0
		"sello":
			return 2 if contenido.contains("sello") else 0
		"firma":
			return 2 if contenido.contains("firma") or contenido.contains("firmad") else 0
	return 0
