## Contrato determinista de grabación onírica (#454).
##
## Evalúa únicamente la validez de una toma. No decide cómo se consigue la
## cámara, no monta UI y no altera el estado del sueño.
class_name GrabacionOniricaContrato
extends RefCounted

enum EstadoGrabacion { VALIDA, CONTAMINADA }

const CLAVES_REQUERIDAS := [
	"original_identificado",
	"frase_completa",
	"tiempo_sujeto",
	"duracion_total",
	"figura_detecto_camara",
	"hubo_corte",
]


static func evaluar_toma(datos: Dictionary) -> EstadoGrabacion:
	for clave in CLAVES_REQUERIDAS:
		if not datos.has(clave):
			return EstadoGrabacion.CONTAMINADA

	var duracion_total := float(datos["duracion_total"])
	if duracion_total <= 0.0:
		return EstadoGrabacion.CONTAMINADA

	if not bool(datos["original_identificado"]):
		return EstadoGrabacion.CONTAMINADA
	if not bool(datos["frase_completa"]):
		return EstadoGrabacion.CONTAMINADA
	if bool(datos["figura_detecto_camara"]):
		return EstadoGrabacion.CONTAMINADA
	if bool(datos["hubo_corte"]):
		return EstadoGrabacion.CONTAMINADA

	var proporcion_sujeto := float(datos["tiempo_sujeto"]) / duracion_total
	if proporcion_sujeto <= 0.5:
		return EstadoGrabacion.CONTAMINADA

	return EstadoGrabacion.VALIDA
