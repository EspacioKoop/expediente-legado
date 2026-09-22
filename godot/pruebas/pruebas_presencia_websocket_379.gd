extends SceneTree

## Vertical real de red para #379: dos clientes WebSocket contra un relay local.

const PresenciaServicio = preload("res://guion/red/presencia_servicio.gd")
const RelayPresenciaWebSocket = preload("res://guion/red/relay_presencia_websocket.gd")
const TransporteWebSocket = preload("res://guion/red/transporte_websocket.gd")

const AHORA := 2_100_200_000

var pasadas := 0
var fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var relay := RelayPresenciaWebSocket.new()
	var inicio := relay.iniciar_disponible()
	_comprobar("relay local arranca", inicio.get("ok", false), true)
	if not bool(inicio.get("ok", false)):
		_terminar()
		return

	var transporte_a := TransporteWebSocket.new(relay.url())
	var transporte_b := TransporteWebSocket.new(relay.url())
	var cliente_a := PresenciaServicio.new(transporte_a)
	var cliente_b := PresenciaServicio.new(transporte_b)

	var apertura_a := cliente_a.abrir_sala("trayecto", "SALA-WS", "anon-ws-a")
	var apertura_b := cliente_b.abrir_sala("trayecto", "SALA-WS", "anon-ws-b")
	_comprobar("A acepta conexión no bloqueante", apertura_a["ok"], true)
	_comprobar("B acepta conexión no bloqueante", apertura_b["ok"], true)

	await _bombear(relay, [transporte_a, transporte_b], 45)
	_comprobar("A completa handshake", transporte_a.health()["online"], true)
	_comprobar("B completa handshake", transporte_b.health()["online"], true)
	_comprobar("relay ve dos miembros", relay.clientes_en_sala("SALA-WS"), 2)

	var publicacion_a := cliente_a.publicar_snapshot(
		"test-379", Vector3(1, 0, 2), 0.5, "walk", "saludo", AHORA, "ws-a-0"
	)
	var publicacion_b := cliente_b.publicar_snapshot(
		"test-379", Vector3(-3, 0, 4), -0.25, "idle", "", AHORA, "ws-b-0"
	)
	_comprobar("A publica por WebSocket", publicacion_a["ok"], true)
	_comprobar("B publica por WebSocket", publicacion_b["ok"], true)

	await _bombear(relay, [transporte_a, transporte_b], 15)
	var vistos_a := cliente_a.consultar(AHORA + 1)
	var vistos_b := cliente_b.consultar(AHORA + 1)
	_comprobar("A ve a B vía relay", vistos_a["participants"].size(), 1)
	_comprobar("B ve a A vía relay", vistos_b["participants"].size(), 1)
	if vistos_a["participants"].size() == 1:
		_comprobar(
			"A recibe actor B",
			vistos_a["participants"][0]["actor_public_id"],
			"anon-ws-b",
		)
	if vistos_b["participants"].size() == 1:
		_comprobar(
			"B recibe pose A",
			vistos_b["participants"][0]["payload"]["position"],
			[1.0, 0.0, 2.0],
		)

	_comprobar("relay corta A", relay.cortar_actor("anon-ws-a"), true)
	await _bombear(relay, [transporte_a, transporte_b], 4)
	_comprobar("servicio A sigue activo tras corte", cliente_a.activa(), true)

	var durante_corte := cliente_a.publicar_snapshot(
		"test-379", Vector3(8, 0, 2), 1.0, "walk", "asentir", AHORA + 2, "ws-a-1"
	)
	_comprobar("snapshot se conserva durante corte", durante_corte["ok"], true)

	await _bombear(relay, [transporte_a, transporte_b], 45)
	_comprobar("A reconecta sin reiniciar partida", transporte_a.health()["online"], true)
	_comprobar("relay recupera dos miembros", relay.clientes_en_sala("SALA-WS"), 2)

	await _bombear(relay, [transporte_a, transporte_b], 10)
	var reconectado := cliente_b.consultar(AHORA + 3)
	_comprobar("snapshot en cola llega tras reconectar", reconectado["participants"].size(), 1)
	if reconectado["participants"].size() == 1:
		_comprobar(
			"reconexión conserva última pose",
			reconectado["participants"][0]["payload"]["position"],
			[8.0, 0.0, 2.0],
		)

	relay.detener()
	await _bombear(relay, [transporte_a, transporte_b], 5)
	_comprobar("caída total no desactiva A", cliente_a.activa(), true)
	_comprobar("caída total no desactiva B", cliente_b.activa(), true)
	_comprobar(
		"consulta durante caída sigue siendo segura",
		cliente_a.consultar(AHORA + 4)["ok"],
		true,
	)

	cliente_a.cerrar_sala()
	cliente_b.cerrar_sala()
	_comprobar("A cierra limpio", cliente_a.activa(), false)
	_comprobar("B cierra limpio", cliente_b.activa(), false)
	_terminar()


func _bombear(
	relay: RelayPresenciaWebSocket,
	transportes: Array,
	frames: int,
	delta: float = 0.02,
) -> void:
	for _frame in range(frames):
		for transporte in transportes:
			transporte.procesar(delta)
		relay.procesar()
		for transporte in transportes:
			transporte.procesar(0.0)
		await process_frame


func _comprobar(nombre: String, obtenido: Variant, esperado: Variant) -> void:
	if obtenido == esperado:
		pasadas += 1
		return
	fallos += 1
	push_error("%s: esperado %s, obtenido %s" % [nombre, esperado, obtenido])


func _terminar() -> void:
	print("\n%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)
