## Identidad lógica de la pesadilla escolar (#284).
##
## Reutiliza el id histórico `crucero`, no su forma (#798). La física visible
## procede de la familia poligonal declarada por SuenoFormas y la adaptación
## escolar solo deforma contenido ya conocido después de #87.
class_name SuenoEscuela
extends RefCounted

const ID := "escuela"
const FORMA := "crucero"

const PUPITRE_INTERACCION := Vector3(-3.0, 0.0, 6.0)
const TAQUILLAS_REFERENCIA := Vector3(6.0, 0.0, 2.0)
const RELOJ_REFERENCIA := Vector3(-5.0, 2.05, -7.0)


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

	# El dibujo reutiliza el primer texto autorizado como eco visual/interactivo,
	# pero no lo consume: #87 sigue conservando íntegro su reparto de carteles.
	var carteles: Array = resultado.get("carteles", []).duplicate(true)
	var frase_conocida := ""
	if not carteles.is_empty():
		var primero: Dictionary = carteles[0]
		frase_conocida = String(primero.get("texto", "")).strip_edges()

	# #798/#87: el contenido del día modifica también el espacio, no solo el
	# decorado. Si existe una frase conocida, aparece un plano diagonal parcial
	# como "folio/expediente" sobredimensionado. Su presencia y longitud dependen
	# de material realmente leído y deja abiertos ambos extremos para no bloquear.
	var tabiques: Array = resultado.get("tabiques_poligonales", []).duplicate(true)
	if not frase_conocida.is_empty():
		var largo := clampf(4.0 + float(frase_conocida.length()) * 0.03, 4.0, 6.5)
		(
			tabiques
			. append(
				{
					"desde": Vector2(-5.5, -2.5),
					"hasta": Vector2(-5.5 + largo, 0.8),
					"altura_desde": 1.35,
					"altura_hasta": 2.35,
				}
			)
		)
	resultado["tabiques_poligonales"] = tabiques

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
		(
			salidas
			. append(
				{
					"pos": PUPITRE_INTERACCION + Vector3(0.0, 1.0, 0.0),
					"destino": "",
					"frase": frase_conocida,
					"tam": Vector3(2.4, 2.0, 2.4),
					"visible": false,
				}
			)
		)
		resultado["salidas"] = salidas

	return resultado
