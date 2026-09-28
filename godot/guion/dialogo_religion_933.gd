## Variantes de diálogo religioso basadas en hechos observables (#933).
##
## Esta capa solo LEE ReligionEventos. Cada interlocutor consume un canal
## concreto y únicamente hechos que puede conocer: públicos o incluidos de
## forma explícita en conocido_por. No infiere convicción ni crea estado.
class_name DialogoReligion933
extends RefCounted

const ACTOR_CUNADO := "cunado"
const ACTOR_CORRESPONDENCIA := "correspondencia"

const CLAVE_CUNADO_EXPOSICION := "RELIGION_933_CUNADO_EXPOSICION"
const CLAVE_CORRESPONDENCIA_PRACTICA := "RELIGION_933_CORRESPONDENCIA_PRACTICA"


static func resolver_clave(estado: Dictionary, actor: String) -> String:
	var actor_limpio := actor.strip_edges()
	var canal := ""
	var clave := ""
	match actor_limpio:
		ACTOR_CUNADO:
			canal = ReligionEventos.CANAL_EXPOSICION
			clave = CLAVE_CUNADO_EXPOSICION
		ACTOR_CORRESPONDENCIA:
			canal = ReligionEventos.CANAL_PRACTICA
			clave = CLAVE_CORRESPONDENCIA_PRACTICA
		_:
			return ""

	var registro_bruto: Variant = estado.get(ReligionEventos.CLAVE_ESTADO, {})
	if not registro_bruto is Dictionary:
		return ""
	var jornada_bruta: Variant = estado.get("jornada", {})
	var vuelta := 1
	if jornada_bruta is Dictionary:
		vuelta = maxi(1, int((jornada_bruta as Dictionary).get("vuelta", 1)))

	var hechos: Array = ReligionEventos.eventos_de_vuelta(
		registro_bruto as Dictionary, canal, vuelta
	)
	for indice in range(hechos.size() - 1, -1, -1):
		var valor: Variant = hechos[indice]
		if valor is Dictionary and _hecho_conocido_por(valor as Dictionary, actor_limpio):
			return clave
	return ""


static func _hecho_conocido_por(evento: Dictionary, actor: String) -> bool:
	if bool(evento.get("publico", false)):
		return true
	var conocidos: Variant = evento.get("conocido_por", [])
	return conocidos is Array and (conocidos as Array).has(actor)
