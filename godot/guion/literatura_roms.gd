## Acceso data-driven a ROMs literarias (#1179).
##
## El catálogo declara la condición, pero solo el registro canónico de
## LiteraturaEventos decide si una obra se conoce. Posesión e insight no bastan.
class_name LiteraturaRoms
extends RefCounted


static func desbloqueadas(
	registro: Dictionary,
	ruta_catalogo: String = LiteraturaCatalogo.RUTA,
) -> Array:
	var salida := []
	for obra_bruta in LiteraturaCatalogo.todas(ruta_catalogo):
		if typeof(obra_bruta) != TYPE_DICTIONARY:
			continue
		var obra: Dictionary = obra_bruta
		var rom_variante = obra.get("rom", {})
		if typeof(rom_variante) != TYPE_DICTIONARY:
			continue
		var rom: Dictionary = rom_variante
		if String(rom.get("estado", "")) != "jugable":
			continue
		if String(rom.get("desbloqueo", "")) != "conocimiento":
			continue
		if not LiteraturaEventos.obra_conocida(registro, String(obra.get("id", ""))):
			continue
		var id_rom := String(rom.get("id", "")).strip_edges()
		if not id_rom.is_empty() and not salida.has(id_rom):
			salida.append(id_rom)
	return salida
