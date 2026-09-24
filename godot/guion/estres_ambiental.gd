## Traduce exposición ambiental sostenida a hechos canónicos de estrés (#952).
##
## No guarda estado ni mide tiempo: el host decide cuándo ha transcurrido un
## intervalo real de exposición. Aquí solo se clasifica la luz ya renderizada y
## la fase canónica de Jornada, evitando otra noción paralela de "oscuridad".
class_name EstresAmbiental
extends RefCounted

const INTERVALO_SEGUNDOS := 60.0
const UMBRAL_OSCURIDAD := 0.38
const UMBRAL_ZONA_SEGURA := 0.44
const HORA_FIN_SEGURA_OFICINA := 18.0
const INTENSIDAD := 0.5


static func evento(fase: String, energia_ambiente: float, hora: float) -> String:
	if not is_finite(energia_ambiente) or not is_finite(hora):
		return ""
	if fase == "sueño":
		return ""
	if energia_ambiente <= UMBRAL_OSCURIDAD:
		return "oscuridad"
	if energia_ambiente < UMBRAL_ZONA_SEGURA:
		return ""
	if fase == "casa":
		return "zona_segura"
	if fase == "archivo" and hora < HORA_FIN_SEGURA_OFICINA:
		return "zona_segura"
	return ""
