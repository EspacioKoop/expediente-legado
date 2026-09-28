extends SceneTree

## Vertical WebSocket real del contrato común de minijuegos (#383).

const MinijuegoServicio = preload("res://guion/red/minijuego_servicio.gd")
const RelayPresenciaWebSocket = preload("res://guion/red/relay_presencia_websocket.gd")
const TransporteWebSocket = preload("res://guion/red/transporte_websocket.gd")

const SCENE_KEY := "oficina/minijuego_coop"
const ROOM_ID := "SALA-383-WS"
const SESSION_ID := "sesion-383-ws"
const MINIGAME_ID := "golf_pasillo"

var pasadas := 0
var fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var relay := RelayPresenciaWebSocket.new()
	var inicio := relay.iniciar_disponible()
	_comprobar("relay común arranca", inicio.get("ok", false), true)
	if not bool(inicio.get("ok", false)):
		_terminar()
		return

	var transporte_a := TransporteWebSocket.new(relay.url())
	var transporte_b := TransporteWebSocket.new(relay.url())
	var servicio_a := MinijuegoServicio.new(transporte_a)
	var servicio_b := MinijuegoServicio.new(transporte_b)

	_comprobar("A abre sala", _abrir(servicio_a, ROOM_ID, SESSION_ID, "anon-mini-a")["ok"], true)
	_comprobar("B abre sala", _abrir(servicio_b, ROOM_ID, SESSION_ID, "anon-mini-b")["ok"], true)
	await _bombear(relay, [servicio_a, servicio_b], 50)
	_comprobar("A completa handshake", servicio_a.estado_transporte()["online"], true)
	_comprobar("B completa handshake", servicio_b.estado_transporte()["online"], true)
	_comprobar("relay ve dos miembros", relay.clientes_en_sala(ROOM_ID), 2)

	var ahora := int(Time.get_unix_time_from_system())
	var accion_a := (
		servicio_a
		. publicar_accion(
			"test-383-websocket",
			0,
			0,
			{"type": "shot", "direction": [0.0, -1.0], "power": 0.45},
			ahora,
			"mini-ws-a-0",
		)
	)
	_comprobar("A publica acción por WebSocket", accion_a["ok"], true)
	await _bombear(relay, [servicio_a, servicio_b], 12)
	var recibidas_b := servicio_b.consultar_acciones(ahora + 1)
	_comprobar("B consulta sin error", recibidas_b["ok"], true)
	_comprobar("B recibe una acción", recibidas_b["actions"].size(), 1)
	if recibidas_b["actions"].size() == 1:
		_comprobar(
			"B recibe actor A",
			recibidas_b["actions"][0]["actor_public_id"],
			"anon-mini-a",
		)
		_comprobar(
			"B recibe la misma sesión",
			recibidas_b["actions"][0]["payload"]["session_id"],
			SESSION_ID,
		)
		_comprobar(
			"B recibe solo parámetros de acción",
			recibidas_b["actions"][0]["payload"]["action"].has("score"),
			false,
		)

	var transporte_otra := TransporteWebSocket.new(relay.url())
	var servicio_otra := MinijuegoServicio.new(transporte_otra)
	_comprobar(
		"otra sala abre",
		_abrir(servicio_otra, "SALA-383-OTRA", SESSION_ID, "anon-mini-c")["ok"],
		true,
	)
	await _bombear(relay, [servicio_a, servicio_b, servicio_otra], 50)
	var accion_b := (
		servicio_b
		. publicar_accion(
			"test-383-websocket",
			1,
			1,
			{"type": "shot", "direction": [0.1, -0.9], "power": 0.55},
			ahora + 2,
			"mini-ws-b-1",
		)
	)
	_comprobar("B publica segunda acción", accion_b["ok"], true)
	await _bombear(relay, [servicio_a, servicio_b, servicio_otra], 12)
	_comprobar(
		"otra sala no recibe acciones",
		servicio_otra.consultar_acciones(ahora + 3)["actions"].size(),
		0,
	)
	_comprobar("A recibe acción de B", servicio_a.consultar_acciones(ahora + 3)["actions"].size(), 1)

	_comprobar("relay corta A", relay.cortar_actor("anon-mini-a"), true)
	await _bombear(relay, [servicio_a, servicio_b, servicio_otra], 5)
	_comprobar("A sigue activo tras corte", servicio_a.activa(), true)

	var en_cola := (
		servicio_a
		. publicar_accion(
			"test-383-websocket",
			2,
			2,
			{"type": "shot", "direction": [-0.1, -0.9], "power": 0.65},
			ahora + 4,
			"mini-ws-a-2",
		)
	)
	_comprobar("acción se acepta durante corte", en_cola["ok"], true)
	_comprobar("acción queda en cola", bool(en_cola.get("queued", false)), true)

	await _bombear(relay, [servicio_a, servicio_b, servicio_otra], 55)
	_comprobar("A reconecta", servicio_a.estado_transporte()["online"], true)
	await _bombear(relay, [servicio_a, servicio_b, servicio_otra], 12)
	var tras_reconexion := servicio_b.consultar_acciones(ahora + 5)
	_comprobar("B recibe acción encolada", tras_reconexion["actions"].size(), 1)
	if tras_reconexion["actions"].size() == 1:
		_comprobar(
			"reconexión conserva secuencia",
			tras_reconexion["actions"][0]["payload"]["sequence"],
			2,
		)

	var partida := {
		"dinero": 33,
		"vidas": 2,
		"pistas_descubiertas": ["pista-previa"],
	}
	var antes := JSON.stringify(partida)
	servicio_a.cerrar_sala()
	servicio_b.cerrar_sala()
	servicio_otra.cerrar_sala()
	_comprobar("cerrar sesiones no muta Partida", JSON.stringify(partida), antes)

	relay.detener()
	_terminar()


func _abrir(
	servicio: MinijuegoServicio,
	room_id: String,
	session_id: String,
	actor_id: String,
) -> Dictionary:
	return (
		servicio
		. abrir_sala(
			SCENE_KEY,
			room_id,
			session_id,
			MINIGAME_ID,
			1,
			actor_id,
		)
	)


func _bombear(
	relay: RelayPresenciaWebSocket,
	servicios: Array,
	frames: int,
	delta: float = 0.02,
) -> void:
	for _frame in range(frames):
		for servicio in servicios:
			servicio.procesar(delta)
		relay.procesar()
		for servicio in servicios:
			servicio.procesar(0.0)
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
