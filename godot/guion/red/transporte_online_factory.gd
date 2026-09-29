class_name TransporteOnlineFactory
extends RefCounted

## Único punto de selección de transporte concreto para superficies online (#375).
##
## Las escenas/controladores piden un transporte por endpoint y siguen hablando
## únicamente con la fachada común. Sin endpoint válido se puede degradar a nulo.
const TransporteNulo = preload("res://guion/red/transporte_nulo.gd")
const TransporteWebSocket = preload("res://guion/red/transporte_websocket.gd")


static func endpoint_valido(endpoint: String) -> bool:
	var normalizado := endpoint.strip_edges()
	return normalizado.begins_with("ws://") or normalizado.begins_with("wss://")


static func crear(endpoint: String, fallback_nulo: bool = true) -> RefCounted:
	var normalizado := endpoint.strip_edges()
	if endpoint_valido(normalizado):
		return TransporteWebSocket.new(normalizado)
	if fallback_nulo:
		return TransporteNulo.new()
	return null
