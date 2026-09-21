## Paletas propias para ROMs GB clásicas en la Portátil Color 98 (#1055).
##
## Solo guarda una preferencia visual por huella de ROM. No conoce el emulador,
## framebuffer, SRAM ni estado de campaña.
class_name PaletasGbClasico
extends RefCounted

const CONFIG_PATH := "user://portatil_color_98.cfg"
const SECTION := "paletas_gb"
const NORMAL := "normal"

const PALETAS := {
	"normal": {"nombre": "Núcleo (normal)"},
	"ambar": {
		"nombre": "Ámbar tenue",
		"colores": [
			Color8(46, 31, 18),
			Color8(112, 73, 31),
			Color8(194, 145, 64),
			Color8(244, 220, 146),
		],
	},
	"salvia": {
		"nombre": "Salvia LCD",
		"colores": [
			Color8(28, 40, 31),
			Color8(61, 84, 60),
			Color8(126, 147, 95),
			Color8(213, 220, 166),
		],
	},
	"humo": {
		"nombre": "Azul humo",
		"colores": [
			Color8(25, 31, 43),
			Color8(58, 72, 91),
			Color8(117, 137, 151),
			Color8(211, 220, 218),
		],
	},
}


static func ids() -> Array[String]:
	return ["normal", "ambar", "salvia", "humo"]


static func nombre(id: String) -> String:
	var entrada: Dictionary = PALETAS.get(id, PALETAS[NORMAL])
	return String(entrada.get("nombre", id))


static func colores(id: String) -> Array[Color]:
	var resultado: Array[Color] = []
	var entrada: Dictionary = PALETAS.get(id, {})
	for valor in entrada.get("colores", []):
		if valor is Color:
			resultado.append(valor)
	return resultado


static func cargar_preferencia(huella: String) -> String:
	if huella.is_empty():
		return NORMAL
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return NORMAL
	var id := String(config.get_value(SECTION, huella, NORMAL))
	return id if PALETAS.has(id) else NORMAL


static func guardar_preferencia(huella: String, id: String) -> bool:
	if huella.is_empty() or not PALETAS.has(id):
		return false
	var config := ConfigFile.new()
	var error := config.load(CONFIG_PATH)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		return false
	config.set_value(SECTION, huella, id)
	return config.save(CONFIG_PATH) == OK
