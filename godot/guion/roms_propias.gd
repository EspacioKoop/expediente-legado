## Índice operativo de las ROMs propias (datos/roms_propias.json).
##
## Es la única lista: el build compila las jugables, la tienda vende las que
## tienen precio, la consola enseña las incluidas y las compradas, y las
## contrapartes oníricas usan `fuente_semilla(id)` como fuente estable.
class_name RomsPropias
extends RefCounted

const INDICE := "res://datos/roms_propias.json"
const JUGABLE := "jugable"
const EN_PROYECTO := "en_proyecto"
const PREFIJO_SEMILLA := "rom:"

static var _cache: Array[Dictionary] = []


static func todas() -> Array[Dictionary]:
	if _cache.is_empty():
		var datos = JSON.parse_string(FileAccess.get_file_as_string(INDICE))
		if typeof(datos) == TYPE_DICTIONARY:
			for entrada in datos.get("roms", []):
				if (
					typeof(entrada) == TYPE_DICTIONARY
					and not String(entrada.get("id", "")).is_empty()
				):
					_cache.append(entrada)
	var copia: Array[Dictionary] = []
	for entrada in _cache:
		copia.append(entrada.duplicate(true))
	return copia


static func por_id(id_rom: String) -> Dictionary:
	for entrada in todas():
		if entrada["id"] == id_rom:
			return entrada
	return {}


static func jugables() -> Array[Dictionary]:
	return todas().filter(func(e): return e.get("estado", "") == JUGABLE)


static func en_proyecto() -> Array[Dictionary]:
	return todas().filter(func(e): return e.get("estado", "") == EN_PROYECTO)


## Lo que vende la tienda: jugables con precio, en el orden del índice.
static func a_la_venta() -> Array[Dictionary]:
	return jugables().filter(func(e): return int(e.get("precio", 0)) > 0)


## Presente en esta build: el artefacto compilado existe.
static func disponible(entrada: Dictionary) -> bool:
	var ruta := String(entrada.get("rom", ""))
	return not ruta.is_empty() and FileAccess.file_exists(ruta)


## Lo que enseña la consola: incluidas de serie, compradas y desbloqueadas por
## sistemas externos. RomsPropias no conoce por qué se produjo el desbloqueo.
static func en_consola(compradas: Array, desbloqueadas: Array = []) -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for entrada in jugables():
		var id_rom := String(entrada.get("id", ""))
		if (
			(
				bool(entrada.get("incluida", false))
				or compradas.has(id_rom)
				or desbloqueadas.has(id_rom)
			)
			and disponible(entrada)
		):
			salida.append(entrada)
	return salida


## Fuente estable para `SemillasOniricas.activar_semilla_onirica`.
static func fuente_semilla(id_rom: String) -> String:
	if por_id(id_rom).is_empty():
		return ""
	return PREFIJO_SEMILLA + id_rom
