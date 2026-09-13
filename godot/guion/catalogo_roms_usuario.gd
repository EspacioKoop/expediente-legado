## Catálogo local y opt-in de ROMs aportadas por el jugador (#124).
##
## No descarga, ejecuta ni interpreta contenido. Solo descubre ficheros Game Boy
## dentro de `user://roms`, sin recursión y con límites de tamaño razonables.
## El futuro núcleo de emulación decidirá si una ROM concreta es compatible.
class_name CatalogoRomsUsuario
extends RefCounted

const CARPETA := "user://roms"
const EXTENSIONES := ["gb", "gbc"]
const MIN_BYTES := 32 * 1024
const MAX_BYTES := 8 * 1024 * 1024


static func asegurar_carpeta() -> bool:
	var usuario := DirAccess.open("user://")
	if usuario == null:
		return false
	if usuario.dir_exists("roms"):
		return true
	return usuario.make_dir_recursive("roms") == OK


static func ruta_absoluta() -> String:
	return ProjectSettings.globalize_path(CARPETA)


static func listar() -> Array[Dictionary]:
	var roms: Array[Dictionary] = []
	if not asegurar_carpeta():
		return roms
	var carpeta := DirAccess.open(CARPETA)
	if carpeta == null:
		return roms

	carpeta.list_dir_begin()
	var nombre := carpeta.get_next()
	while not nombre.is_empty():
		if not carpeta.current_is_dir() and _extension_permitida(nombre):
			var entrada := _inspeccionar(nombre)
			if not entrada.is_empty():
				roms.append(entrada)
		nombre = carpeta.get_next()
	carpeta.list_dir_end()
	roms.sort_custom(_ordenar_por_nombre)
	return roms


static func _extension_permitida(nombre: String) -> bool:
	return EXTENSIONES.has(nombre.get_extension().to_lower())


static func _inspeccionar(nombre: String) -> Dictionary:
	var ruta := CARPETA.path_join(nombre)
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		return {}
	var bytes := archivo.get_length()
	if bytes < MIN_BYTES or bytes > MAX_BYTES:
		return {}
	return {"nombre": nombre, "ruta": ruta, "bytes": bytes}


static func _ordenar_por_nombre(a: Dictionary, b: Dictionary) -> bool:
	return String(a.get("nombre", "")).to_lower() < String(b.get("nombre", "")).to_lower()
