## Traduce estados ya existentes a una reacción puramente presentacional (#787).
##
## No recibe posiciones, pistas, objetivos ni estado de campaña: solo la fase declarada de
## #539, cuántas anomalías 3D ya existen en la sala y si el gato está en estado
## de ayuda completa. La prioridad evita que varios sistemas peleen por la pose.
class_name GatoReaccionContextual
extends RefCounted

const CONTAMINACION := "contaminacion_os98"
const ANOMALIA_SUENO := "anomalia_sueno"


static func decidir(
	fase_contaminacion: int, anomalias_sueno: int, ayuda_completa: bool
) -> Dictionary:
	if not ayuda_completa:
		return {}
	if fase_contaminacion >= ContaminacionOs98.FASE_CONTAMINACION_CRUZADA:
		return {
			"id": CONTAMINACION,
			"estado": "escondido",
		}
	if anomalias_sueno > 0:
		return {
			"id": ANOMALIA_SUENO,
			"estado": "observando",
		}
	return {}
