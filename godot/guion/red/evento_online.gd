class_name EventoOnline
extends RefCounted

## Contrato de datos mínimo para multiplayer offline-first (#375).
## Solo acepta valores JSON; nunca deserializa objetos o recursos de Godot.

const PROTOCOL_VERSION := 1
const MAX_SCENE_KEY := 96
const MAX_GAME_BUILD := 64
const MAX_ACTOR_ID := 96
const MAX_EVENT_ID := 96
const MAX_COLLECTION_ITEMS := 64
const MAX_NESTING := 6
const MAX_STRING_CHARS := 512

const ESPECIFICACIONES := {
	"ghost": {"max_bytes": 4096, "max_ttl": 3600},
	"signal": {"max_bytes": 1536, "max_ttl": 900},
	"presence": {"max_bytes": 1024, "max_ttl": 120},
	"help": {"max_bytes": 2048, "max_ttl": 1800},
	"coop_combat": {"max_bytes": 1536, "max_ttl": 30},
}


static func validar(datos: Variant, ahora_unix: int) -> Dictionary:
	if typeof(datos) != TYPE_DICTIONARY:
		return _invalido("not_dictionary")
	for campo in [
		"protocol_version",
		"kind",
		"game_build",
		"scene_key",
		"created_at",
		"expires_at",
		"actor_public_id",
		"payload",
	]:
		if not datos.has(campo):
			return _invalido("missing_%s" % campo)

	var version := int(datos.get("protocol_version", -1))
	if version != PROTOCOL_VERSION:
		return _invalido("unsupported_version")

	var kind := String(datos.get("kind", ""))
	if not ESPECIFICACIONES.has(kind):
		return _invalido("unknown_kind")

	var game_build := String(datos.get("game_build", ""))
	var scene_key := String(datos.get("scene_key", ""))
	var actor_public_id := String(datos.get("actor_public_id", ""))
	if game_build.is_empty() or game_build.length() > MAX_GAME_BUILD:
		return _invalido("invalid_game_build")
	if scene_key.is_empty() or scene_key.length() > MAX_SCENE_KEY:
		return _invalido("invalid_scene_key")
	if actor_public_id.is_empty() or actor_public_id.length() > MAX_ACTOR_ID:
		return _invalido("invalid_actor_public_id")

	var created_at := int(datos.get("created_at", 0))
	var expires_at := int(datos.get("expires_at", 0))
	if created_at <= 0 or expires_at <= created_at:
		return _invalido("invalid_ttl")
	var especificacion: Dictionary = ESPECIFICACIONES[kind]
	if expires_at - created_at > int(especificacion["max_ttl"]):
		return _invalido("ttl_too_large")
	if expires_at <= ahora_unix:
		return _invalido("expired")

	var payload = datos.get("payload")
	if typeof(payload) != TYPE_DICTIONARY or not _es_json_seguro(payload):
		return _invalido("unsafe_payload")

	var evento := {
		"protocol_version": version,
		"kind": kind,
		"game_build": game_build,
		"scene_key": scene_key,
		"created_at": created_at,
		"expires_at": expires_at,
		"actor_public_id": actor_public_id,
		"payload": payload.duplicate(true),
	}
	if datos.has("event_id"):
		var event_id := String(datos.get("event_id", ""))
		if event_id.is_empty() or event_id.length() > MAX_EVENT_ID:
			return _invalido("invalid_event_id")
		evento["event_id"] = event_id

	var bytes := JSON.stringify(evento).to_utf8_buffer().size()
	if bytes > int(especificacion["max_bytes"]):
		return _invalido("event_too_large")
	return {"ok": true, "reason": "", "event": evento}


static func huella(evento: Dictionary) -> String:
	var event_id := String(evento.get("event_id", ""))
	if not event_id.is_empty():
		return "id:%s" % event_id
	return "hash:%s" % _canonico(evento).hash()


static func _es_json_seguro(valor: Variant, profundidad: int = 0) -> bool:
	if profundidad > MAX_NESTING:
		return false
	match typeof(valor):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT:
			return true
		TYPE_STRING:
			return String(valor).length() <= MAX_STRING_CHARS
		TYPE_ARRAY:
			if valor.size() > MAX_COLLECTION_ITEMS:
				return false
			for item in valor:
				if not _es_json_seguro(item, profundidad + 1):
					return false
			return true
		TYPE_DICTIONARY:
			if valor.size() > MAX_COLLECTION_ITEMS:
				return false
			for clave in valor:
				if typeof(clave) != TYPE_STRING or String(clave).length() > MAX_STRING_CHARS:
					return false
				if not _es_json_seguro(valor[clave], profundidad + 1):
					return false
			return true
		_:
			return false


static func _canonico(valor: Variant) -> String:
	match typeof(valor):
		TYPE_DICTIONARY:
			var datos: Dictionary = valor
			var claves := datos.keys()
			claves.sort()
			var partes_diccionario: Array[String] = []
			for clave in claves:
				var clave_json := JSON.stringify(String(clave))
				partes_diccionario.append("%s:%s" % [clave_json, _canonico(datos[clave])])
			return "{%s}" % ",".join(partes_diccionario)
		TYPE_ARRAY:
			var partes_array: Array[String] = []
			for item in valor:
				partes_array.append(_canonico(item))
			return "[%s]" % ",".join(partes_array)
		_:
			return JSON.stringify(valor)


static func _invalido(razon: String) -> Dictionary:
	return {"ok": false, "reason": razon, "event": {}}
