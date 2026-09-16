## Identidad lógica de la pesadilla escolar (#284).
##
## Reutiliza `crucero`: sus dos pasillos cruzados ya leen como circulación
## escolar y conservan la física/timing estabilizados. La adaptación ocurre
## después de #87 y solo transforma la representación de contenido ya conocido.
class_name SuenoEscuela
extends RefCounted

const ID := "escuela"
const FORMA := "crucero"

const PUPITRE_INTERACCION := Vector3(-12.0, 0.0, -1.0)
const TAQUILLAS_REFERENCIA := Vector3(12.0, 0.0, 3.0)
const RELOJ_REFERENCIA := Vector3(0.0, 2.05, -14.8)


static func es_forma(id: String) -> bool:
	return id == FORMA


static func adaptar_espacio(
	espacio_base: Dictionary, estado_presentacion: Dictionary = {}
) -> Dictionary:
	if espacio_base.is_empty():
		return {}

	var resultado := espacio_base.duplicate(true)
	resultado["identidad_onirica"] = ID
	resultado["estado_presentacion"] = estado_presentacion.duplicate(true)
	resultado["ambiente"] = Color(0.33, 0.36, 0.30)
	resultado["ambiente_energia"] = 0.54
	resultado["sol"] = 0.03
	resultado["escuela_pupitre_pos"] = PUPITRE_INTERACCION
	resultado["escuela_taquillas_pos"] = TAQUILLAS_REFERENCIA
	resultado["escuela_reloj_pos"] = RELOJ_REFERENCIA

	# El primer texto autorizado deja de ser un cartel literal y aparece como
	# un dibujo infantil sobre un pupitre. La interacción sigue devolviendo la
	# misma frase: cambia la forma del recuerdo, nunca su contenido factual.
	var carteles: Array = resultado.get("carteles", []).duplicate(true)
	var frase_conocida := ""
	if not carteles.is_empty():
		var primero: Dictionary = carteles.pop_front()
		frase_conocida = String(primero.get("texto", "")).strip_edges()
		resultado["carteles"] = carteles

	resultado["anomalias_oniricas"] = {
		"aulas_reordenadas": {"activa": true},
		"timbre_fuera_horario": {"activa": true},
		"pupitres_pared_vacia": {"activa": true},
		"voces_aula_vacia": {"activa": true},
		"dibujo_mutante": {"activa": not frase_conocida.is_empty()},
		"reloj_tres_agujas": {"activa": true},
	}

	if not frase_conocida.is_empty():
		var salidas: Array = resultado.get("salidas", []).duplicate(true)
		salidas.append(
			{
				"pos": PUPITRE_INTERACCION + Vector3(0.0, 1.0, 0.0),
				"destino": "",
				"frase": frase_conocida,
				"tam": Vector3(2.4, 2.0, 2.4),
				"visible": false,
			}
		)
		resultado["salidas"] = salidas

	return resultado
