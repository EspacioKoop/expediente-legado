class_name GhostServicio
extends RefCounted

## Adaptador offline-first para publicar/consultar ghosts sin acoplar escenas al transporte (#376).

const GhostDatos = preload("res://guion/red/ghost_datos.gd")

const MAX_VISIBLES := 3

var _transporte: RefCounted
var _habilitado := true


func _init(transporte: RefCounted, habilitado: bool = true) -> void:
	_transporte = transporte
	_habilitado = habilitado


func habilitar(valor: bool) -> void:
	_habilitado = valor


func habilitado() -> bool:
	return _habilitado


func publicar(evento: Dictionary, ahora_unix: int) -> Dictionary:
	if not _habilitado:
		return {"ok": true, "status": "disabled", "delivered": false}
	var validacion := GhostDatos.validar_evento(evento, ahora_unix)
	if not validacion["ok"]:
		return {"ok": false, "status": "invalid_ghost", "reason": validacion["reason"]}
	if _transporte == null or not _transporte.has_method("publicar_evento"):
		return {"ok": false, "status": "transport_unavailable", "delivered": false}
	return _transporte.call("publicar_evento", validacion["event"], ahora_unix)


func consultar(
	scene_key: String,
	scene_revision: String,
	ahora_unix: int,
	anchor_key: String = ""
) -> Dictionary:
	if not _habilitado:
		return {"ok": true, "status": "disabled", "ghosts": []}
	if _transporte == null or not _transporte.has_method("consultar_eventos"):
		return {"ok": false, "status": "transport_unavailable", "ghosts": []}

	var consulta = _transporte.call("consultar_eventos", scene_key, GhostDatos.KIND, ahora_unix)
	if typeof(consulta) != TYPE_DICTIONARY:
		return {"ok": false, "status": "invalid_transport_response", "ghosts": []}
	if not bool(consulta.get("ok", false)):
		return {
			"ok": false,
			"status": String(consulta.get("status", "transport_error")),
			"ghosts": [],
		}

	var salida: Array = []
	var actores := {}
	for crudo in consulta.get("events", []):
		var validacion := GhostDatos.validar_evento(crudo, ahora_unix)
		if not validacion["ok"]:
			continue
		var evento: Dictionary = validacion["event"]
		var payload: Dictionary = evento["payload"]
		if String(payload["scene_revision"]) != scene_revision:
			continue
		if String(payload["space"]) == "anchor" and String(payload["anchor_key"]) != anchor_key:
			continue
		var actor := String(evento["actor_public_id"])
		if actores.has(actor):
			continue
		actores[actor] = true
		salida.append(evento)
		if salida.size() >= MAX_VISIBLES:
			break

	return {"ok": true, "status": "ok", "ghosts": salida}
