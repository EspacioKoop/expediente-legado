class_name GhostServicio
extends RefCounted

## Adaptador offline-first para publicar/consultar ghosts sin acoplar escenas al transporte (#376).
##
## La selección es deliberadamente pequeña: excluye al actor local, prefiere
## actores no vistos recientemente y conserva el orden de frescura que entrega
## el transporte/relay.

const GhostDatos = preload("res://guion/red/ghost_datos.gd")

const MAX_VISIBLES := 3
const MAX_ACTORES_RECIENTES := 6

var _transporte: RefCounted
var _habilitado := true
var _actor_public_id := ""
var _actores_recientes: Array[String] = []
var _veces_mostrado: Dictionary = {}


func _init(transporte: RefCounted, habilitado: bool = true) -> void:
	_transporte = transporte
	_habilitado = habilitado


func habilitar(valor: bool) -> void:
	_habilitado = valor


func habilitado() -> bool:
	return _habilitado


func configurar_actor_local(actor_public_id: String) -> void:
	_actor_public_id = actor_public_id.strip_edges()


func reiniciar_seleccion() -> void:
	_actores_recientes.clear()
	_veces_mostrado.clear()


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
	scene_key: String, scene_revision: String, ahora_unix: int, anchor_key: String = ""
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

	var validos: Array[Dictionary] = []
	var actores_evento := {}
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
		if actor.is_empty() or actor == _actor_public_id or actores_evento.has(actor):
			continue
		actores_evento[actor] = true
		validos.append(evento)

	var salida: Array = []
	_seleccionar(validos, salida, true)
	if salida.size() < MAX_VISIBLES:
		_seleccionar(validos, salida, false)
	for evento in salida:
		_recordar_actor(String(evento["actor_public_id"]))

	return {"ok": true, "status": "ok", "ghosts": salida}


func _seleccionar(validos: Array[Dictionary], salida: Array, solo_nuevos: bool) -> void:
	var candidatos := validos.duplicate()
	candidatos.sort_custom(_ordenar_candidatos)
	for evento in candidatos:
		if salida.size() >= MAX_VISIBLES:
			return
		var actor := String(evento["actor_public_id"])
		var reciente := _actores_recientes.has(actor)
		if solo_nuevos == reciente:
			continue
		var ya_elegido := false
		for elegido in salida:
			if String(elegido["actor_public_id"]) == actor:
				ya_elegido = true
				break
		if not ya_elegido:
			salida.append(evento)


func _ordenar_candidatos(a: Dictionary, b: Dictionary) -> bool:
	var actor_a := String(a.get("actor_public_id", ""))
	var actor_b := String(b.get("actor_public_id", ""))
	var veces_a := int(_veces_mostrado.get(actor_a, 0))
	var veces_b := int(_veces_mostrado.get(actor_b, 0))
	if veces_a != veces_b:
		return veces_a < veces_b

	var creado_a := int(a.get("created_at", 0))
	var creado_b := int(b.get("created_at", 0))
	if creado_a != creado_b:
		return creado_a > creado_b
	return actor_a < actor_b


func _recordar_actor(actor_public_id: String) -> void:
	_veces_mostrado[actor_public_id] = int(_veces_mostrado.get(actor_public_id, 0)) + 1
	_actores_recientes.erase(actor_public_id)
	_actores_recientes.append(actor_public_id)
	while _actores_recientes.size() > MAX_ACTORES_RECIENTES:
		_actores_recientes.pop_front()
