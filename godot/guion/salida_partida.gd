## Guardado previo a abandonar una partida activa (#788).
##
## Este núcleo no cambia de escena ni decide qué mensaje enseñar. Cuando recibe
## la escena del día reutiliza su camino canónico `_guardar_o_avisar("")`, que
## además de Partida guarda el estado auxiliar que corresponda. El fallback
## directo sobre Partida existe para consumidores aislados y para la regresión
## de escritura atómica.
class_name SalidaPartida
extends RefCounted

const MOTIVO_PARTIDA_NO_DISPONIBLE := "partida_no_disponible"


static func guardar_desde(escena: Node) -> Dictionary:
	if escena == null:
		return {"ok": false, "motivo": MOTIVO_PARTIDA_NO_DISPONIBLE}
	var partida_actual = escena.get("partida")
	if not partida_actual is Partida:
		return {"ok": false, "motivo": MOTIVO_PARTIDA_NO_DISPONIBLE}
	if escena.has_method("_guardar_o_avisar"):
		var guardada := bool(escena.call("_guardar_o_avisar", ""))
		return {
			"ok": guardada,
			"motivo": "" if guardada else String(partida_actual.fallo_de_guardado),
		}
	return guardar(partida_actual)


static func guardar(partida: Partida, ruta: String = Partida.RUTA) -> Dictionary:
	if partida == null:
		return {"ok": false, "motivo": MOTIVO_PARTIDA_NO_DISPONIBLE}
	if partida.guardar(ruta):
		return {"ok": true, "motivo": ""}
	return {"ok": false, "motivo": partida.fallo_de_guardado}
