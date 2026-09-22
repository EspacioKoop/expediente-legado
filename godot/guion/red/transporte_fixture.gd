class_name TransporteFixture
extends "res://guion/red/transporte_online.gd"

## Transporte determinista para pruebas: inyecta eventos sin sockets ni servidor.

var _entrantes: Array = []
var _salientes: Array = []
var _timeout_simulado := false


func _init(eventos: Array = []) -> void:
	for evento in eventos:
		inyectar(evento)


func inyectar(evento: Variant) -> void:
	if typeof(evento) == TYPE_DICTIONARY:
		_entrantes.append(evento.duplicate(true))
	else:
		_entrantes.append(evento)


func simular_timeout(activo: bool) -> void:
	_timeout_simulado = activo


func publicados() -> Array:
	return _salientes.duplicate(true)


func publicar_evento(evento: Dictionary, ahora_unix: int = -1) -> Dictionary:
	if _timeout_simulado:
		return _resultado(false, "timeout", {"delivered": false})
	var validacion := EventoOnline.validar(evento, _ahora(ahora_unix))
	if not validacion["ok"]:
		return _resultado(false, "invalid_event", {"reason": validacion["reason"]})
	_salientes.append(validacion["event"].duplicate(true))
	return _resultado(true, "ok", {"delivered": true})


func consultar_eventos(scene_key: String, kind: String = "", ahora_unix: int = -1) -> Dictionary:
	if _timeout_simulado:
		return _resultado(false, "timeout", {"events": []})
	var salida: Array = []
	var vistos := {}
	var ahora := _ahora(ahora_unix)
	for crudo in _entrantes:
		var validacion := EventoOnline.validar(crudo, ahora)
		if not validacion["ok"]:
			continue
		var evento: Dictionary = validacion["event"]
		if evento["scene_key"] != scene_key:
			continue
		if not kind.is_empty() and evento["kind"] != kind:
			continue
		var huella := EventoOnline.huella(evento)
		if vistos.has(huella):
			continue
		vistos[huella] = true
		salida.append(evento)
	return _resultado(true, "ok", {"events": salida})


func abrir_sala(scene_key: String, _opciones: Dictionary = {}) -> Dictionary:
	if _timeout_simulado:
		return _resultado(false, "timeout", {"opened": false})
	return _resultado(not scene_key.is_empty(), "ok", {"opened": not scene_key.is_empty()})


func cerrar_sala() -> Dictionary:
	return _resultado(true, "ok", {"closed": true})


func reportar_evento(event_id: String) -> Dictionary:
	if _timeout_simulado:
		return _resultado(false, "timeout", {"delivered": false})
	return _resultado(not event_id.is_empty(), "ok", {"delivered": not event_id.is_empty()})


func ocultar_evento(event_id: String) -> Dictionary:
	return _resultado(not event_id.is_empty(), "ok", {"hidden": not event_id.is_empty()})


func health() -> Dictionary:
	if _timeout_simulado:
		return _resultado(
			false,
			"timeout",
			{
				"online": false,
				"transport": "fixture",
				"protocol_version": EventoOnline.PROTOCOL_VERSION,
			}
		)
	return _resultado(
		true,
		"ok",
		{
			"online": true,
			"transport": "fixture",
			"protocol_version": EventoOnline.PROTOCOL_VERSION,
		}
	)
