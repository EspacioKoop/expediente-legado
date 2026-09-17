## Biblioteca permanente de cartuchos de la Portátil Color 98 (#800).
##
## No pertenece a Jornada ni a una partida concreta: una compra es del perfil de
## instalación y sigue disponible al empezar una partida nueva. Los guardados
## anteriores se leen solo como fuente de migración; nunca se reescriben aquí.
class_name PerfilRoms
extends RefCounted

const RUTA := "user://perfil_roms.json"
const VERSION := 1
const CLAVE_COMPRAS := "roms_compradas"


static func compras(ruta: String = RUTA) -> Array[String]:
	return _normalizar(_leer(ruta).get(CLAVE_COMPRAS, []))


## Registra una compra de forma idempotente y atómica.
static func registrar(id_rom: String, ruta: String = RUTA) -> bool:
	var id := id_rom.strip_edges()
	if id.is_empty():
		return false
	var adquiridas := compras(ruta)
	if adquiridas.has(id):
		return true
	adquiridas.append(id)
	return _guardar(adquiridas, ruta)


## Importa el formato previo a #800. Se conserva la clave antigua en la jornada
## para no tocar guardados históricos: una vez copiada, el perfil es la autoridad.
static func migrar_desde_jornada(jornada: Dictionary, ruta: String = RUTA) -> Array[String]:
	var adquiridas := compras(ruta)
	var antiguas := _normalizar(jornada.get(CLAVE_COMPRAS, []))
	var cambio := false
	for id_rom in antiguas:
		if adquiridas.has(id_rom):
			continue
		adquiridas.append(id_rom)
		cambio = true
	if cambio and not _guardar(adquiridas, ruta):
		push_warning("No se pudieron migrar las ROMs compradas al perfil")
	return adquiridas


## El menú principal puede migrar sin cargar Partida: leer el JSON en crudo evita
## que un guardado corrupto sea apartado antes de que el jugador pulse Continuar.
static func migrar_desde_partida(ruta_partida: String, ruta: String = RUTA) -> Array[String]:
	if not FileAccess.file_exists(ruta_partida):
		return compras(ruta)
	var fichero := FileAccess.open(ruta_partida, FileAccess.READ)
	if fichero == null:
		return compras(ruta)
	var crudo = JSON.parse_string(fichero.get_as_text())
	fichero.close()
	if typeof(crudo) != TYPE_DICTIONARY:
		return compras(ruta)
	var jornada = crudo.get("jornada", {})
	if typeof(jornada) != TYPE_DICTIONARY:
		return compras(ruta)
	return migrar_desde_jornada(jornada, ruta)


static func _normalizar(valor) -> Array[String]:
	var salida: Array[String] = []
	if typeof(valor) != TYPE_ARRAY:
		return salida
	for bruto in valor:
		var id_rom := String(bruto).strip_edges()
		if not id_rom.is_empty() and not salida.has(id_rom):
			salida.append(id_rom)
	return salida


static func _leer(ruta: String) -> Dictionary:
	if not FileAccess.file_exists(ruta):
		return {"version": VERSION, CLAVE_COMPRAS: []}
	var fichero := FileAccess.open(ruta, FileAccess.READ)
	if fichero == null:
		return {"version": VERSION, CLAVE_COMPRAS: []}
	var crudo = JSON.parse_string(fichero.get_as_text())
	fichero.close()
	if typeof(crudo) != TYPE_DICTIONARY:
		push_warning("Perfil de ROMs ilegible: %s" % ruta)
		return {"version": VERSION, CLAVE_COMPRAS: []}
	return crudo


static func _guardar(adquiridas: Array[String], ruta: String) -> bool:
	var temporal := ruta + ".nuevo"
	var fichero := FileAccess.open(temporal, FileAccess.WRITE)
	if fichero == null:
		push_error("No se pudo escribir %s" % temporal)
		return false
	var datos := {"version": VERSION, CLAVE_COMPRAS: adquiridas}
	fichero.store_string(JSON.stringify(datos, "\t"))
	fichero.close()
	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporal), ProjectSettings.globalize_path(ruta)
	)
	if error != OK:
		push_error("No se pudo reemplazar %s (error %d)" % [ruta, error])
		if FileAccess.file_exists(temporal):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temporal))
		return false
	return true
