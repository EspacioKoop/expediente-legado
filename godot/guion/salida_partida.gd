## Guardado previo a abandonar una partida activa (#788).
##
## Este núcleo no cambia de escena ni decide qué mensaje enseñar. Su único
## trabajo es pasar por Partida.guardar(), conservar el motivo técnico del
## fallo y devolver un contrato pequeño para que cualquier UI pueda bloquear
## la salida si el disco no quedó actualizado.
class_name SalidaPartida
extends RefCounted

const MOTIVO_PARTIDA_NO_DISPONIBLE := "partida_no_disponible"


static func guardar(partida: Partida, ruta: String = Partida.RUTA) -> Dictionary:
	if partida == null:
		return {"ok": false, "motivo": MOTIVO_PARTIDA_NO_DISPONIBLE}
	if partida.guardar(ruta):
		return {"ok": true, "motivo": ""}
	return {"ok": false, "motivo": partida.fallo_de_guardado}
