## Persistencia y reintento de tránsito del día (#1761).
##
## Conserva la API histórica en DiaApp, pero el estado pendiente y la escritura
## viven aquí. No decide reglas de Jornada: solo persiste el estado ya resuelto
## y completa un tránsito previamente cobrado cuando el disco vuelve a responder.
class_name DiaGuardadoApp
extends Node

var _partida: Partida
var _host: Node
var _nomina: Label
var _transito_pendiente := ""


func configurar(partida: Partida, host: Node, nomina: Label) -> void:
	_partida = partida
	_host = host
	_nomina = nomina


func guardar_o_avisar(destino: String) -> bool:
	if _partida.guardar():
		_guardar_estado_aplicaciones()
		return true
	_transito_pendiente = destino
	_nomina.text = tr("ARCHIVO_ERROR_GUARDAR")
	return false


func reintentar_guardado(
	jornada: Dictionary,
	entrar_en: Callable,
	sonar: Callable,
) -> void:
	var destino := _transito_pendiente
	if not guardar_o_avisar(destino):
		return
	_transito_pendiente = ""
	_nomina.text = tr("ARCHIVO_GUARDADO_HECHO")
	if destino.is_empty():
		return
	if jornada["fase"] != "sueño":
		sonar.call("puerta_abre")
	entrar_en.call(destino)


func destino_pendiente() -> String:
	return _transito_pendiente


func _guardar_estado_aplicaciones() -> void:
	var escritorio_controller := _host.get_node_or_null("EscritorioSigaController")
	if (
		escritorio_controller != null
		and escritorio_controller.has_method("guardar_estado_aplicaciones")
	):
		escritorio_controller.guardar_estado_aplicaciones()
