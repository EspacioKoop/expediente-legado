## Contrato determinista de grabación onírica (#454).
##
## Evalúa únicamente la validez de una toma y el consumo de una cinta. No
## decide cómo se consigue la cámara, no monta UI y no altera estado de sueño,
## expediente, economía, acciones, vidas ni veredicto.
class_name GrabacionOniricaContrato
extends RefCounted

enum EstadoGrabacion { VALIDA, CONTAMINADA }

const ESTADO_VALIDA := "valida"
const ESTADO_CONTAMINADA := "contaminada"
const ERROR_DURACION_INVALIDA := "duracion_invalida"
const ERROR_METRAJE_INSUFICIENTE := "metraje_insuficiente"

const CLAVES_REQUERIDAS := [
	"original_id",
	"original_identificado",
	"frase_completa",
	"tiempo_sujeto",
	"duracion_total",
	"figura_detecto_camara",
	"hubo_corte",
]


## Compatibilidad con el primer corte de #482: conserva el enum público.
static func evaluar_toma(datos: Dictionary) -> EstadoGrabacion:
	var evaluacion := evaluar_toma_detallada(datos)
	if evaluacion.get("estado") == ESTADO_VALIDA:
		return EstadoGrabacion.VALIDA
	return EstadoGrabacion.CONTAMINADA


## Forma rica del contrato. `estado` usa exactamente los strings que consume
## `cinta_onirica.estado` en la proyección integrada por #241.
static func evaluar_toma_detallada(datos: Dictionary) -> Dictionary:
	var motivos: Array[String] = []
	for clave in CLAVES_REQUERIDAS:
		if not datos.has(clave):
			motivos.append("dato_faltante:%s" % clave)

	if not datos.has("duracion_total") or not datos.has("tiempo_sujeto"):
		return _resultado(datos, motivos, 0.0)

	var duracion_total := float(datos["duracion_total"])
	var tiempo_sujeto := float(datos["tiempo_sujeto"])
	if duracion_total <= 0.0:
		motivos.append(ERROR_DURACION_INVALIDA)

	var proporcion_sujeto := 0.0
	if duracion_total > 0.0:
		if tiempo_sujeto < 0.0 or tiempo_sujeto > duracion_total:
			motivos.append("encuadre_invalido")
		else:
			proporcion_sujeto = tiempo_sujeto / duracion_total
			if proporcion_sujeto <= 0.5:
				motivos.append("sujeto_en_cuadro_50_o_menos")

	if datos.has("original_id") and String(datos["original_id"]).strip_edges().is_empty():
		motivos.append("original_sin_id")
	if datos.has("original_identificado") and not bool(datos["original_identificado"]):
		motivos.append("original_desconocido")
	if datos.has("frase_completa") and not bool(datos["frase_completa"]):
		motivos.append("frase_incompleta")
	if datos.has("figura_detecto_camara") and bool(datos["figura_detecto_camara"]):
		motivos.append("camara_detectada")
	if datos.has("hubo_corte") and bool(datos["hubo_corte"]):
		motivos.append("interrupcion")

	return _resultado(datos, motivos, proporcion_sujeto)


static func _resultado(
	datos: Dictionary, motivos: Array[String], proporcion_sujeto: float
) -> Dictionary:
	return {
		"estado": ESTADO_VALIDA if motivos.is_empty() else ESTADO_CONTAMINADA,
		"motivos": motivos.duplicate(),
		"proporcion_sujeto": proporcion_sujeto,
		"toma": datos.duplicate(true),
	}


static func nueva_cinta(capacidad_segundos: float) -> Dictionary:
	assert(capacidad_segundos >= 0.0, "La capacidad de cinta no puede ser negativa")
	return {
		"capacidad_segundos": capacidad_segundos,
		"metraje_restante": capacidad_segundos,
		"tomas": [],
	}


## Registra una toma sin mutar la cinta recibida ni sustituir tomas anteriores.
## Si la duración supera el metraje restante, rechaza toda la operación.
static func registrar_toma(cinta: Dictionary, datos: Dictionary) -> Dictionary:
	var copia := cinta.duplicate(true)
	var duracion := float(datos.get("duracion_total", 0.0))
	if duracion <= 0.0:
		return {"ok": false, "error": ERROR_DURACION_INVALIDA, "cinta": copia}

	var restante := float(cinta.get("metraje_restante", 0.0))
	if duracion > restante:
		return {"ok": false, "error": ERROR_METRAJE_INSUFICIENTE, "cinta": copia}

	var evaluacion := evaluar_toma_detallada(datos)
	var tomas: Array = copia.get("tomas", []).duplicate(true)
	tomas.append(evaluacion)
	copia["tomas"] = tomas
	copia["metraje_restante"] = restante - duracion
	return {"ok": true, "cinta": copia, "evaluacion": evaluacion}


## Adaptador explícito para la costura existente de #241.
static func para_proyeccion(evaluacion: Dictionary) -> Dictionary:
	var estado := String(evaluacion.get("estado", ""))
	assert(
		estado == ESTADO_VALIDA or estado == ESTADO_CONTAMINADA,
		"Estado de grabación onírica no proyectable"
	)
	return {
		"estado": estado,
		"motivos": evaluacion.get("motivos", []).duplicate(true),
	}
