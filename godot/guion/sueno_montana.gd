## Identidad lógica de la montaña onírica (#284).
##
## Reutiliza la familia CONVERGENTE como cresta estrecha y transforma una frase
## ya presente en el espacio —por tanto procedente de #87— en documento congelado.
## No toca Jornada, Partida, economía, veredictos ni selección nocturna.
class_name SuenoMontana
extends RefCounted

const ID := "montana"
const FAMILIA := SuenoFamilias.CONVERGENTE


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
	resultado["ambiente"] = Color(0.42, 0.48, 0.58)
	resultado["ambiente_energia"] = 0.68
	resultado["sol"] = 0.42

	# El primer texto autorizado deja de estar escrito en un muro y pasa a ser
	# un papel atrapado en hielo. Se transforma la representación, no el dato.
	var carteles: Array = resultado.get("carteles", []).duplicate(true)
	var frase_conocida := ""
	if not carteles.is_empty():
		var primero: Dictionary = carteles.pop_front()
		frase_conocida = String(primero.get("texto", "")).strip_edges()
		resultado["carteles"] = carteles

	var anclas: Array = familia.get("anclas", []).duplicate(true)
	var hielo_pos := Vector3(-6, 0, 2)
	if anclas.size() > 1:
		hielo_pos = Vector3(anclas[1])
	elif not anclas.is_empty():
		hielo_pos = Vector3(anclas[0])
	resultado["montana_hielo_pos"] = hielo_pos

	var anomalias := {
		"cabana_perspectiva": {"activa": true},
		"huellas_anticipadas": {"activa": true},
		"crujidos_sin_fuente": {"activa": true},
		"documento_hielo": {"activa": not frase_conocida.is_empty(), "pos": hielo_pos},
	}
	resultado["anomalias_oniricas"] = anomalias

	if not frase_conocida.is_empty():
		var salidas: Array = resultado.get("salidas", []).duplicate(true)
		salidas.append(
			{
				"pos": hielo_pos + Vector3(0, 1.0, 0),
				"destino": "",
				"frase": frase_conocida,
				"tam": Vector3(2.5, 2.0, 2.5),
				"visible": false,
			}
		)
		resultado["salidas"] = salidas

		var luces: Array = resultado.get("luces", []).duplicate(true)
		luces.append(
			{
				"pos": hielo_pos + Vector3(0, 1.15, 0),
				"color": Color(0.46, 0.76, 0.94),
				"energia": 0.75,
				"alcance": 3.5,
				"carcasa": false,
			}
		)
		resultado["luces"] = luces

	return resultado
