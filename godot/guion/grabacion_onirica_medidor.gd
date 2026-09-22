## Medición runtime de una toma de cámara onírica (#1237).
##
## Este objeto solo traduce una Camera3D y el paso del tiempo a las magnitudes
## que consume GrabacionOniricaContrato. No decide si la cámara existe, qué
## sujeto se graba, qué sabe el jugador ni el resultado de la proyección.
class_name GrabacionOniricaMedidor
extends RefCounted

var _activa := false
var _original_id := ""
var _original_identificado := false
var _duracion_total := 0.0
var _tiempo_sujeto := 0.0
var _hubo_corte := false


## Empieza una toma nueva. Reutilizar el medidor descarta exclusivamente la
## medición anterior; la cinta y sus tomas persistentes pertenecen al contrato
## de #454, no a este objeto runtime.
func iniciar(original_id: String, original_identificado: bool) -> void:
	_activa = true
	_original_id = original_id
	_original_identificado = original_identificado
	_duracion_total = 0.0
	_tiempo_sujeto = 0.0
	_hubo_corte = false


## Acumula tiempo de toma. El tiempo total corre aunque el sujeto salga de
## cuadro; el tiempo de sujeto solo avanza mientras su ancla está en el frustum.
##
## Un delta nulo/negativo no describe tiempo transcurrido y se ignora para que
## pausas o relojes reajustados no puedan mejorar ni empeorar una toma.
func muestrear(camara: Camera3D, posicion_sujeto: Vector3, delta: float) -> void:
	if not _activa or delta <= 0.0:
		return
	_duracion_total += delta
	if esta_en_cuadro(camara, posicion_sujeto):
		_tiempo_sujeto += delta


## Un corte no borra lo ya grabado: deja una marca irreversible en esta toma.
## Si después se sigue muestreando, el contrato la seguirá considerando
## contaminada por no haber sido continua.
func interrumpir() -> void:
	if _activa:
		_hubo_corte = true


## Cierra la medición y devuelve exactamente las claves que consume #454.
## "Frase completa" y "cámara detectada" son hechos del contenido/IA que el
## medidor geométrico no puede ni debe inferir.
func finalizar(frase_completa: bool, figura_detecto_camara: bool) -> Dictionary:
	if not _activa:
		return {}
	_activa = false
	return {
		"original_id": _original_id,
		"original_identificado": _original_identificado,
		"frase_completa": frase_completa,
		"tiempo_sujeto": _tiempo_sujeto,
		"duracion_total": _duracion_total,
		"figura_detecto_camara": figura_detecto_camara,
		"hubo_corte": _hubo_corte,
	}


func esta_activa() -> bool:
	return _activa


## Política mínima y reproducible de "en cuadro" para este corte: el punto de
## referencia del sujeto debe estar dentro del frustum de la Camera3D. No se
## usa proyección a píxeles ni tamaño de viewport, así que el resultado no
## depende de la resolución de pantalla.
static func esta_en_cuadro(camara: Camera3D, posicion_sujeto: Vector3) -> bool:
	return camara != null and camara.is_position_in_frustum(posicion_sujeto)
