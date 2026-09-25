class_name CombateCoop
extends RefCounted

## Sesión efímera de combate cooperativo para #380.
##
## Reutiliza `Combate` como motor de resolución y mantiene todo el estado dentro
## de este diccionario de sesión. No recibe ni conoce `Partida`.

const MAX_RONDAS := 3
const PARTICIPANTES := 2


static func nueva(rival: Dictionary, actor_a: String, actor_b: String) -> Dictionary:
	var actores := [actor_a.strip_edges(), actor_b.strip_edges()]
	actores.sort()
	if actores[0].is_empty() or actores[1].is_empty() or actores[0] == actores[1]:
		return {}
	return {
		"actores": actores,
		"combate": Combate.nuevo("ciclo", rival, {}),
		"elecciones": {},
		"historial": [],
		"terminado": false,
		"ganador": "",
	}


static func elegir(sesion: Dictionary, actor_id: String, accion: String, azar: Callable) -> Dictionary:
	if sesion.is_empty() or bool(sesion.get("terminado", true)):
		return {"ok": false, "status": "session_finished"}
	if not sesion["actores"].has(actor_id):
		return {"ok": false, "status": "unknown_actor"}
	if not Combate.TIPOS.has(accion):
		return {"ok": false, "status": "invalid_action"}

	var ronda := int(sesion["historial"].size())
	var elecciones: Dictionary = sesion["elecciones"]
	var clave := "%d:%s" % [ronda, actor_id]
	if elecciones.has(clave):
		return {"ok": false, "status": "duplicate_choice"}
	elecciones[clave] = accion

	var acciones: Array[String] = []
	for actor in sesion["actores"]:
		var actor_clave := "%d:%s" % [ronda, actor]
		if not elecciones.has(actor_clave):
			return {"ok": true, "status": "waiting_partner", "resolved": false}
		acciones.append(String(elecciones[actor_clave]))

	var combinada := _combinar(acciones[0], acciones[1])
	var resultado := Combate.jugar(sesion["combate"], combinada, "", azar)
	var registro := {
		"ronda": ronda,
		"elecciones": {
			sesion["actores"][0]: acciones[0],
			sesion["actores"][1]: acciones[1],
		},
		"accion_combinada": combinada,
		"resultado": resultado.duplicate(true),
	}
	sesion["historial"].append(registro)

	if bool(sesion["combate"]["terminado"]) or sesion["historial"].size() >= MAX_RONDAS:
		sesion["terminado"] = true
		if bool(sesion["combate"]["terminado"]):
			sesion["ganador"] = String(sesion["combate"]["ganador"])
		else:
			var vida_jugador := int(sesion["combate"]["vida_jugador"])
			var vida_rival := int(sesion["combate"]["vida_rival"])
			if vida_jugador > vida_rival:
				sesion["ganador"] = "jugadores"
			elif vida_rival > vida_jugador:
				sesion["ganador"] = "rival"
			else:
				sesion["ganador"] = "empate"

	return {
		"ok": true,
		"status": "resolved",
		"resolved": true,
		"round": registro,
		"finished": sesion["terminado"],
		"winner": sesion["ganador"],
	}


static func _combinar(a: String, b: String) -> String:
	if a == b:
		return a
	if Combate.vence_a(a) == b:
		return b
	return a
