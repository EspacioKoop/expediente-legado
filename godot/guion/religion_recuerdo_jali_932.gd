## Consumidor posterior de la exposición registrada por JALI 98 (#932/#935).
##
## Solo reutiliza motivos ya vistos en la ROM. No añade hechos de expedientes,
## no crea práctica, no infiere convicción y no convierte islam en mitología.
class_name ReligionRecuerdoJali932
extends RefCounted

const FUENTE := "rom:jali_98"


static func disponible(registro: Dictionary) -> bool:
	for evento_bruto in ReligionEventos.eventos(registro, ReligionEventos.CANAL_EXPOSICION):
		if typeof(evento_bruto) != TYPE_DICTIONARY:
			continue
		var evento: Dictionary = evento_bruto
		if String(evento.get("fuente", "")) == FUENTE:
			return true
	return false


static func recuerdo_para_sueno(registro: Dictionary) -> Dictionary:
	if not disponible(registro):
		return {}
	return {
		"fuente": FUENTE,
		"canal": ReligionEventos.CANAL_EXPOSICION,
		"motivos": ["geometria", "luz", "sombra", "calado"],
		"hechos_nuevos": false,
		"asume_conviccion": false,
	}
