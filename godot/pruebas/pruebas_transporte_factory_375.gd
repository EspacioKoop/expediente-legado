extends SceneTree

const TransporteOnlineFactory = preload("res://guion/red/transporte_online_factory.gd")
const TransporteNulo = preload("res://guion/red/transporte_nulo.gd")
const TransporteWebSocket = preload("res://guion/red/transporte_websocket.gd")

var pasadas := 0
var fallos := 0


func _init() -> void:
	_probar()
	print("transporte_factory_375: %d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _probar() -> void:
	_comprobar(
		TransporteOnlineFactory.endpoint_valido(" wss://relay.invalid "),
		"acepta wss normalizado",
	)
	_comprobar(
		not TransporteOnlineFactory.endpoint_valido("https://relay.invalid"),
		"rechaza transporte ajeno",
	)

	var nulo := TransporteOnlineFactory.crear("")
	_comprobar(nulo is TransporteNulo, "sin endpoint usa transporte nulo")

	var estricto := TransporteOnlineFactory.crear("", false)
	_comprobar(estricto == null, "modo estricto no inventa conexión")

	var websocket := TransporteOnlineFactory.crear("wss://relay.invalid", false)
	_comprobar(websocket is TransporteWebSocket, "endpoint websocket crea transporte real")
	_comprobar(
		String(websocket.endpoint_url) == "wss://relay.invalid",
		"la factoría conserva el endpoint normalizado",
	)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		pasadas += 1
		return
	fallos += 1
	push_error("FALLO #375: " + nombre)
