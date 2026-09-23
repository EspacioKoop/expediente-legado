class_name IdentidadOnline
extends RefCounted

## Identidad pública mínima para funciones online (#375).
##
## - desactivada por defecto;
## - pseudónimo aleatorio local, sin nombre de cuenta/SO/rutas/IP;
## - persistencia separada de Partida;
## - regenerar reemplaza el pseudónimo;
## - desactivar borra el identificador persistido y deja, como máximo, una
##   lápida sin identidad si el borrado físico falla.
##
## El servidor puede decidir después si valida/reemplaza este identificador,
## pero ninguna escena necesita conocer de dónde sale.

const VERSION := 1
const RUTA := "user://identidad_online.json"
const PREFIJO := "anon-"
const BYTES_ID := 16
const DIGITOS_HEX := BYTES_ID * 2

var ruta: String
var habilitada := false
var _actor_public_id := ""


func _init(ruta_archivo: String = RUTA) -> void:
	ruta = ruta_archivo


func cargar() -> Dictionary:
	habilitada = false
	_actor_public_id = ""
	if not FileAccess.file_exists(ruta):
		return {"ok": true, "status": "disabled"}

	var fichero := FileAccess.open(ruta, FileAccess.READ)
	if fichero == null:
		return {"ok": false, "status": "unreadable"}
	var crudo = JSON.parse_string(fichero.get_as_text())
	fichero.close()
	if not _estado_valido(crudo):
		return {"ok": false, "status": "invalid"}

	habilitada = bool(crudo["enabled"])
	_actor_public_id = String(crudo["actor_public_id"]) if habilitada else ""
	return {
		"ok": true,
		"status": "enabled" if habilitada else "disabled",
		"actor_public_id": actor_public_id(),
	}


func habilitar() -> Dictionary:
	if habilitada and _id_valido(_actor_public_id):
		return {"ok": true, "status": "enabled", "actor_public_id": _actor_public_id}

	var anterior_habilitada := habilitada
	var anterior_id := _actor_public_id
	habilitada = true
	_actor_public_id = _nuevo_id()
	if not _guardar():
		habilitada = anterior_habilitada
		_actor_public_id = anterior_id
		return {"ok": false, "status": "write_failed", "actor_public_id": actor_public_id()}
	return {"ok": true, "status": "enabled", "actor_public_id": _actor_public_id}


func regenerar() -> Dictionary:
	if not habilitada:
		return {"ok": false, "status": "disabled", "actor_public_id": ""}

	var anterior := _actor_public_id
	_actor_public_id = _nuevo_id()
	if not _guardar():
		_actor_public_id = anterior
		return {"ok": false, "status": "write_failed", "actor_public_id": anterior}
	return {"ok": true, "status": "regenerated", "actor_public_id": _actor_public_id}


func deshabilitar() -> Dictionary:
	habilitada = false
	_actor_public_id = ""

	# Primero se reemplaza cualquier estado previo por una lápida sin ID.
	# Si el unlink posterior falla, el fichero restante ya no contiene identidad.
	if not _guardar():
		return {"ok": false, "status": "write_failed", "actor_public_id": ""}
	if FileAccess.file_exists(ruta):
		var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
		if error != OK and FileAccess.file_exists(ruta):
			return {"ok": true, "status": "disabled_tombstone", "actor_public_id": ""}
	return {"ok": true, "status": "disabled", "actor_public_id": ""}


func activa() -> bool:
	return habilitada


func actor_public_id() -> String:
	return _actor_public_id if habilitada and _id_valido(_actor_public_id) else ""


func _guardar() -> bool:
	var temporal := ruta + ".nuevo"
	var fichero := FileAccess.open(temporal, FileAccess.WRITE)
	if fichero == null:
		return false
	var guardado := fichero.store_string(
		JSON.stringify(
			{
				"version": VERSION,
				"enabled": habilitada,
				"actor_public_id": actor_public_id(),
			}
		)
	)
	fichero.close()
	if not guardado:
		if FileAccess.file_exists(temporal):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temporal))
		return false

	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporal), ProjectSettings.globalize_path(ruta)
	)
	if error != OK:
		if FileAccess.file_exists(temporal):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temporal))
		return false
	return true


static func _estado_valido(datos: Variant) -> bool:
	if typeof(datos) != TYPE_DICTIONARY or datos.size() != 3:
		return false
	if not datos.has("version") or int(datos["version"]) != VERSION:
		return false
	if not datos.has("enabled") or typeof(datos["enabled"]) != TYPE_BOOL:
		return false
	if not datos.has("actor_public_id") or typeof(datos["actor_public_id"]) != TYPE_STRING:
		return false
	if bool(datos["enabled"]):
		return _id_valido(String(datos["actor_public_id"]))
	return String(datos["actor_public_id"]).is_empty()


static func _id_valido(valor: String) -> bool:
	if not valor.begins_with(PREFIJO) or valor.length() != PREFIJO.length() + DIGITOS_HEX:
		return false
	var hexadecimal := valor.substr(PREFIJO.length())
	for indice in range(hexadecimal.length()):
		if "0123456789abcdef".find(hexadecimal.substr(indice, 1)) < 0:
			return false
	return true


static func _nuevo_id() -> String:
	return PREFIJO + Crypto.new().generate_random_bytes(BYTES_ID).hex_encode()
