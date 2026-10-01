## Guardado y reintento de tránsito para DiaApp (#1761).
##
## Posee únicamente el destino pendiente tras un fallo de escritura. Partida
## sigue siendo la autoridad de persistencia y DiaApp conserva los wrappers
## históricos que consumen controladores/subclases.
class_name DiaGuardadoApp
extends RefCounted

var transito_pendiente := ""


func guardar(host: Node, partida: Partida, destino: String) -> bool:
	if partida.guardar():
		# El escritorio se persiste aparte (#535). Su fallo no convierte en
		# fallido el guardado de campaña ni bloquea el tránsito.
		var escritorio_controller := host.get_node_or_null("EscritorioSigaController")
		if (
			escritorio_controller != null
			and escritorio_controller.has_method("guardar_estado_aplicaciones")
		):
			escritorio_controller.guardar_estado_aplicaciones()
		return true

	transito_pendiente = destino
	host.set("_hablando", false)
	var nomina = host.get("_nomina")
	if nomina is Label:
		(nomina as Label).text = host.tr("ARCHIVO_ERROR_GUARDAR")
	return false


func reintentar(host: Node, partida: Partida, jornada: Dictionary) -> void:
	var destino := transito_pendiente
	if not guardar(host, partida, destino):
		return

	transito_pendiente = ""
	var nomina = host.get("_nomina")
	if nomina is Label:
		(nomina as Label).text = host.tr("ARCHIVO_GUARDADO_HECHO")
	if destino.is_empty():
		return
	if String(jornada.get("fase", "")) != "sueño":
		host.call("_sonar", "puerta_abre")
	host.call("_entrar_en", destino)
