## Reloj de inactividad del Prometeo legado (#1029).
##
## El legado no medía teclas ni movimiento: reiniciaba su reloj únicamente al
## aparecer progreso de Prometeo (Tarot o logros). Este contrato conserva esa
## semántica sin persistir un timestamp de pared ni convertir cargar() en evento.
class_name InactividadPrometeo
extends RefCounted

const SEGUNDOS_FINAL := 720.0
const LOGRO_FINAL := "la-garganta-abierta"

var _firma := ""
var _sin_progreso := 0.0
var _final_emitido := false


func iniciar(estado: Dictionary) -> void:
	_firma = firma_progreso(estado)
	_sin_progreso = 0.0
	_final_emitido = false


func avanzar(estado: Dictionary, delta: float) -> bool:
	var firma_actual := firma_progreso(estado)
	if firma_actual != _firma:
		_firma = firma_actual
		_sin_progreso = 0.0
		_final_emitido = false
		return false

	if _final_emitido:
		return false

	_sin_progreso += maxf(delta, 0.0)
	if _sin_progreso < SEGUNDOS_FINAL:
		return false

	_final_emitido = true
	return true


static func firma_progreso(estado: Dictionary) -> String:
	return JSON.stringify(
		{
			"tarot": _estado_tarot(estado),
			"logros": _estado_logros(estado),
		}
	)


static func desbloquear_logro_final(estado: Dictionary) -> bool:
	for logro in estado.get("logros", []):
		if typeof(logro) != TYPE_DICTIONARY:
			continue
		if String(logro.get("id", "")) != LOGRO_FINAL:
			continue
		if bool(logro.get("desbloqueado", false)):
			return false
		logro["desbloqueado"] = true
		return true
	return false


static func _estado_tarot(estado: Dictionary) -> Array:
	var resumen: Array = []
	for carta in estado.get("tarot", []):
		if typeof(carta) != TYPE_DICTIONARY:
			continue
		resumen.append(
			{
				"id": String(carta.get("id", "")),
				"recogida": bool(carta.get("recogida", false)),
				"gastada": bool(carta.get("gastada", false)),
			}
		)
	return resumen


static func _estado_logros(estado: Dictionary) -> Array:
	var resumen: Array = []
	for logro in estado.get("logros", []):
		if typeof(logro) != TYPE_DICTIONARY:
			continue
		resumen.append(
			{
				"id": String(logro.get("id", "")),
				"desbloqueado": bool(logro.get("desbloqueado", false)),
			}
		)
	return resumen
