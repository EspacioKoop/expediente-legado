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
	var resultado: Dictionary = {}
	var tipo := intervencion.strip_edges().to_lower()
	if not registro.is_empty() and INTERVENCIONES.has(tipo):
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

		resultado = {
			"registro_id": String(registro.get("id", "")),
			"intervencion": tipo,
			"calidad": calidad,
			"riesgo": riesgo,
			"temporal": true,
		}
	return resultado


static func _apoyo_material(registro: Dictionary, intervencion: String) -> int:
	var contenido := String(registro.get("contenido", "")).to_lower()
	var apoyo := 0
	match intervencion:
		"fecha":
			apoyo = 2 if not String(registro.get("fecha", "")).is_empty() else 0
		"sello":
			apoyo = 2 if contenido.contains("sello") else 0
		"firma":
			apoyo = 2 if contenido.contains("firma") or contenido.contains("firmad") else 0
	return apoyo
