extends SceneTree

## Relay local manual para probar dos instancias de #379.
##
## Uso:
## godot4 --headless --path godot --script res://herramientas/relay_presencia_local.gd
## godot4 --headless --path godot --script res://herramientas/relay_presencia_local.gd -- 19099

const RelayPresenciaWebSocket = preload("res://guion/red/relay_presencia_websocket.gd")

const PUERTO_DEFECTO := 19098

var _relay: RelayPresenciaWebSocket


func _initialize() -> void:
	var puerto := PUERTO_DEFECTO
	var argumentos := OS.get_cmdline_user_args()
	if not argumentos.is_empty():
		puerto = int(argumentos[0])

	_relay = RelayPresenciaWebSocket.new()
	var inicio := _relay.iniciar(puerto)
	if not bool(inicio.get("ok", false)):
		push_error("No se pudo iniciar relay de presencia: %s" % inicio)
		quit(1)
		return

	print("Relay presencia #379: %s" % _relay.url())


func _process(_delta: float) -> bool:
	if _relay != null:
		_relay.procesar()
	return false


func _finalize() -> void:
	if _relay != null:
		_relay.detener()
