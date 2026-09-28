## Adaptador runtime entre Camera3D, el medidor y la cinta persistente (#1682).
##
## No decide cómo se obtiene la cámara ni crea una cinta. Recibe una cámara y
## un sujeto reales, delega toda la medición a GrabacionOniricaMedidor y entrega
## exactamente la toma resultante a GrabacionOniricaEstado. Tampoco selecciona
## implícitamente una toma para la acusación.
class_name GrabacionOniricaRuntime
extends RefCounted

const ERROR_TOMA_ACTIVA := "toma_activa"
const ERROR_SIN_TOMA := "sin_toma_activa"
const ERROR_ORIGINAL_DESCONOCIDO := "original_desconocido"
const ERROR_SUJETO_INVALIDO := "sujeto_invalido"
const ERROR_CAMARA_INVALIDA := "camara_invalida"

var _medidor := GrabacionOniricaMedidor.new()
var _camara: Camera3D
var _sujeto: Node3D


func iniciar(
	camara: Camera3D,
	sujeto: Node3D,
	original_id: String,
	original_identificado: bool,
) -> Dictionary:
	if _medidor.esta_activa():
		return {"ok": false, "error": ERROR_TOMA_ACTIVA}
	if camara == null or not is_instance_valid(camara):
		return {"ok": false, "error": ERROR_CAMARA_INVALIDA}
	if sujeto == null or not is_instance_valid(sujeto):
		return {"ok": false, "error": ERROR_SUJETO_INVALIDO}
	var original := original_id.strip_edges()
	if original.is_empty() or not original_identificado:
		return {"ok": false, "error": ERROR_ORIGINAL_DESCONOCIDO}

	_camara = camara
	_sujeto = sujeto
	_medidor.iniciar(original, true)
	return {"ok": true, "original_id": original}


func muestrear(delta: float) -> void:
	if not _medidor.esta_activa():
		return
	if (
		_camara == null
		or not is_instance_valid(_camara)
		or _sujeto == null
		or not is_instance_valid(_sujeto)
	):
		_medidor.interrumpir()
		return
	_medidor.muestrear(_camara, _sujeto.global_position, delta)


func interrumpir() -> void:
	_medidor.interrumpir()


func finalizar(
	estado: Dictionary,
	frase_completa: bool,
	figura_detecto_camara: bool,
) -> Dictionary:
	if not _medidor.esta_activa():
		return {"ok": false, "error": ERROR_SIN_TOMA}

	var toma := _medidor.finalizar(frase_completa, figura_detecto_camara)
	_camara = null
	_sujeto = null
	var resultado := GrabacionOniricaEstado.registrar_toma(estado, toma)
	if not bool(resultado.get("ok", false)):
		return resultado

	var salida := resultado.duplicate(true)
	salida["toma"] = toma.duplicate(true)
	return salida


func esta_activa() -> bool:
	return _medidor.esta_activa()
