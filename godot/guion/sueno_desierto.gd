## Identidad lógica del desierto onírico (#284).
##
## Reutiliza la familia FRAGMENTADA como extensión mineral abierta. El contenido
## sigue naciendo en #87: una frase ya conocida se desplaza al teléfono aislado
## y el resto de anomalías no modifica expediente, economía ni veredictos.
class_name SuenoDesierto
extends RefCounted

const ID := "desierto"
const FORMA := "peine"
const FAMILIA := SuenoFamilias.FRAGMENTADA


static func es_forma(id: String) -> bool:
	return id == FORMA


static func adaptar_espacio(
	espacio_base: Dictionary, estado_presentacion: Dictionary = {}
) -> Dictionary:
	if espacio_base.is_empty():
		return {}

	var familia := SuenoFamilias.de(FAMILIA)
	if familia.is_empty():
		return espacio_base.duplicate(true)

	var resultado := espacio_base.duplicate(true)
	resultado["identidad_onirica"] = ID
	resultado["estado_presentacion"] = estado_presentacion.duplicate(true)
	resultado["exterior"] = true
	resultado["ambiente"] = Color(0.58, 0.43, 0.26)
	resultado["ambiente_energia"] = 0.64
	resultado["sol"] = 0.72

	var anclas: Array = familia.get("anclas", []).duplicate(true)
	var telefono_pos := Vector3(6, 0, -8)
	var archivador_pos := Vector3(-3, 0, 7)
	var papel_pos := Vector3(9, 0, 8)
	if anclas.size() > 0:
		telefono_pos = Vector3(anclas[0])
	if anclas.size() > 1:
		archivador_pos = Vector3(anclas[1])
	if anclas.size() > 2:
		papel_pos = Vector3(anclas[2])
	resultado["desierto_telefono_pos"] = telefono_pos
	resultado["desierto_archivador_pos"] = archivador_pos
	resultado["desierto_papel_pos"] = papel_pos

	# El teléfono no inventa una voz: al acercarse devuelve exactamente una
	# frase que el sueño ya había recibido del contenido conocido de #87.
	var carteles: Array = resultado.get("carteles", []).duplicate(true)
	var frase_conocida := ""
	if not carteles.is_empty():
		var primero: Dictionary = carteles.pop_front()
		frase_conocida = String(primero.get("texto", "")).strip_edges()
		resultado["carteles"] = carteles

	resultado["anomalias_oniricas"] = {
		"horizonte_recede": {"activa": true},
		"silencio_local": {"activa": true},
		"huellas_geometricas": {"activa": true},
		"papel_enterrado": {"activa": true, "pos": papel_pos},
		"telefono_con_tono": {"activa": true, "pos": telefono_pos},
	}

	if not frase_conocida.is_empty():
		var salidas: Array = resultado.get("salidas", []).duplicate(true)
		(
			salidas
			. append(
				{
					"pos": telefono_pos + Vector3(0, 1.15, 0),
					"destino": "",
					"frase": frase_conocida,
					"tam": Vector3(2.8, 2.4, 2.8),
					"visible": false,
				}
			)
		)
		resultado["salidas"] = salidas

	return resultado
