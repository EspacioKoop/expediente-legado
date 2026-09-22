class_name TransporteNulo
extends "res://guion/red/transporte_online.gd"

## Transporte por defecto cuando no hay servicio online configurado.
## Nunca realiza I/O ni bloquea gameplay, guardados o transiciones.


func publicar_evento(evento: Dictionary, ahora_unix: int = -1) -> Dictionary:
	var validacion := EventoOnline.validar(evento, _ahora(ahora_unix))
	if not validacion["ok"]:
		return _resultado(false, "invalid_event", {"reason": validacion["reason"]})
	return _resultado(true, "discarded_offline", {"delivered": false})


func consultar_eventos(_scene_key: String, _kind: String = "", _ahora_unix: int = -1) -> Dictionary:
	return _resultado(true, "offline", {"events": []})


func abrir_sala(_scene_key: String, _opciones: Dictionary = {}) -> Dictionary:
	return _resultado(true, "offline", {"opened": false})


func cerrar_sala() -> Dictionary:
	return _resultado(true, "offline", {"closed": true})


func reportar_evento(_event_id: String) -> Dictionary:
	return _resultado(true, "discarded_offline", {"delivered": false})


func ocultar_evento(_event_id: String) -> Dictionary:
	return _resultado(true, "local_only", {"hidden": false})


func health() -> Dictionary:
	return _resultado(
		true,
		"offline",
		{"online": false, "transport": "null", "protocol_version": EventoOnline.PROTOCOL_VERSION}
	)
