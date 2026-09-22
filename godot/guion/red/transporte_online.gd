class_name TransporteOnline
extends RefCounted

## Interfaz desacoplada: las escenas consumidoras solo deberían conocer estos métodos.

const EventoOnline = preload("res://guion/red/evento_online.gd")


func procesar(_delta: float) -> void:
	pass


func publicar_evento(_evento: Dictionary, _ahora_unix: int = -1) -> Dictionary:
	return _resultado(false, "not_implemented")


func consultar_eventos(_scene_key: String, _kind: String = "", _ahora_unix: int = -1) -> Dictionary:
	return _resultado(false, "not_implemented", {"events": []})


func abrir_sala(_scene_key: String, _opciones: Dictionary = {}) -> Dictionary:
	return _resultado(false, "not_implemented")


func cerrar_sala() -> Dictionary:
	return _resultado(false, "not_implemented")


func reportar_evento(_event_id: String) -> Dictionary:
	return _resultado(false, "not_implemented")


func ocultar_evento(_event_id: String) -> Dictionary:
	return _resultado(false, "not_implemented")


func health() -> Dictionary:
	return _resultado(false, "not_implemented", {"protocol_version": EventoOnline.PROTOCOL_VERSION})


func _ahora(valor: int) -> int:
	if valor >= 0:
		return valor
	return int(Time.get_unix_time_from_system())


func _resultado(ok: bool, estado: String, extras: Dictionary = {}) -> Dictionary:
	var salida := {"ok": ok, "status": estado}
	for clave in extras:
		salida[clave] = extras[clave]
	return salida
