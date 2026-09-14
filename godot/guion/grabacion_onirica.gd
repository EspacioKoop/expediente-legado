## Contrato puro y determinista de grabación onírica.
##
## No conoce cámara, UI, escenas, expediente, economía ni veredicto. Recibe los
## hechos medidos durante una toma y decide únicamente si esa toma es `valida`
## o `contaminada`. La cinta se modela aparte y sus operaciones devuelven copias
## nuevas para no reescribir tomas previas por accidente.
class_name GrabacionOnirica
extends RefCounted

const ESTADO_VALIDA := "valida"
const ESTADO_CONTAMINADA := "contaminada"

const MOTIVO_ORIGINAL_SIN_ID := "original_sin_id"
const MOTIVO_ORIGINAL_DESCONOCIDO := "original_desconocido"
const MOTIVO_DURACION_INVALIDA := "duracion_invalida"
const MOTIVO_ENCUADRE_INVALIDO := "encuadre_invalido"
const MOTIVO_SUJETO_INSUFICIENTE := "sujeto_en_cuadro_50_o_menos"
const MOTIVO_FRASE_INCOMPLETA := "frase_incompleta"
const MOTIVO_INTERRUPCION := "interrupcion"
const MOTIVO_CAMARA_DETECTADA := "camara_detectada"

const ERROR_DURACION_INVALIDA := "duracion_invalida"
const ERROR_METRAJE_INSUFICIENTE := "metraje_insuficiente"


static func evaluar_toma(toma: Dictionary) -> Dictionary:
	var duracion_total := float(toma.get("duracion_total_segundos", 0.0))
	var duracion_en_cuadro := float(toma.get("duracion_en_cuadro_segundos", 0.0))
	var motivos: Array[String] = []

	if String(toma.get("original_id", "")).strip_edges().is_empty():
		motivos.append(MOTIVO_ORIGINAL_SIN_ID)
	if not bool(toma.get("original_identificado", false)):
		motivos.append(MOTIVO_ORIGINAL_DESCONOCIDO)
	if duracion_total <= 0.0:
		motivos.append(MOTIVO_DURACION_INVALIDA)
	if duracion_en_cuadro < 0.0 or duracion_en_cuadro > duracion_total:
		motivos.append(MOTIVO_ENCUADRE_INVALIDO)

	var proporcion_en_cuadro := 0.0
	if duracion_total > 0.0 and duracion_en_cuadro >= 0.0 and duracion_en_cuadro <= duracion_total:
		proporcion_en_cuadro = duracion_en_cuadro / duracion_total
		if proporcion_en_cuadro <= 0.5:
			motivos.append(MOTIVO_SUJETO_INSUFICIENTE)

	if not bool(toma.get("frase_completa", false)):
		motivos.append(MOTIVO_FRASE_INCOMPLETA)
	if bool(toma.get("interrumpida", false)):
		motivos.append(MOTIVO_INTERRUPCION)
	if bool(toma.get("camara_detectada", false)):
		motivos.append(MOTIVO_CAMARA_DETECTADA)

	return {
		"estado": ESTADO_VALIDA if motivos.is_empty() else ESTADO_CONTAMINADA,
		"motivos": motivos,
		"proporcion_en_cuadro": proporcion_en_cuadro,
		"toma": toma.duplicate(true),
	}


static func nueva_cinta(capacidad_segundos: float) -> Dictionary:
	assert(capacidad_segundos >= 0.0, "La capacidad de la cinta no puede ser negativa")
	return {
		"capacidad_segundos": capacidad_segundos,
		"restante_segundos": capacidad_segundos,
		"tomas": [],
	}


## Registra una toma sin mutar la cinta recibida.
##
## Si no queda metraje suficiente, la operación se rechaza completa: no consume
## segundos y no añade ni sustituye ninguna toma previa.
static func registrar_toma(cinta: Dictionary, toma: Dictionary) -> Dictionary:
	var duracion := float(toma.get("duracion_total_segundos", 0.0))
	var copia_cinta := cinta.duplicate(true)
	if duracion <= 0.0:
		return {
			"ok": false,
			"error": ERROR_DURACION_INVALIDA,
			"cinta": copia_cinta,
		}

	var restante := float(cinta.get("restante_segundos", 0.0))
	if duracion > restante:
		return {
			"ok": false,
			"error": ERROR_METRAJE_INSUFICIENTE,
			"cinta": copia_cinta,
		}

	var evaluacion := evaluar_toma(toma)
	var tomas: Array = copia_cinta.get("tomas", []).duplicate(true)
	tomas.append(evaluacion)
	copia_cinta["tomas"] = tomas
	copia_cinta["restante_segundos"] = restante - duracion
	return {
		"ok": true,
		"cinta": copia_cinta,
		"toma": evaluacion,
	}


## Devuelve una forma directamente encajable en la costura de #241:
## `resultado["cinta_onirica"] = GrabacionOnirica.para_proyeccion(evaluacion)`.
static func para_proyeccion(evaluacion: Dictionary) -> Dictionary:
	var estado := String(evaluacion.get("estado", ""))
	assert(
		estado == ESTADO_VALIDA or estado == ESTADO_CONTAMINADA,
		"La evaluación no contiene un estado de grabación proyectable"
	)
	return {
		"estado": estado,
		"motivos": evaluacion.get("motivos", []).duplicate(true),
	}
