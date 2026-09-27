extends SceneTree

const DiaSenalesMultiplayerApp = preload("res://guion/dia_senales_multiplayer_app.gd")
const RelaySenalesWebSocket = preload("res://guion/red/relay_senales_websocket.gd")
const SenalServicio = preload("res://guion/red/senal_servicio.gd")
const TransporteWebSocket = preload("res://guion/red/transporte_websocket.gd")


class HostFalso:
	extends Node3D
	var jornada := {"fase": "trayecto"}
	var _mundo: Node3D

	func _init() -> void:
		_mundo = Node3D.new()
		_mundo.name = "Mundo"
		add_child(_mundo)


var pasadas := 0
var fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var ahora := int(Time.get_unix_time_from_system())
	var relay := RelaySenalesWebSocket.new()
	var inicio := relay.iniciar_disponible()
	_comprobar("relay de señales arranca", inicio.get("ok", false), true)
	if not bool(inicio.get("ok", false)):
		_terminar()
		return

	var host := HostFalso.new()
	root.add_child(host)
	var transporte_dia := TransporteWebSocket.new(relay.url())
	var controller := DiaSenalesMultiplayerApp.new()
	host.add_child(controller)
	await process_frame
	var activacion := (
		controller
		. activar(
			transporte_dia,
			[],
			"anon-signal-dia",
			"SALA-SENAL",
		)
	)
	_comprobar("Dia acepta sala remota opt-in", activacion["ok"], true)
	_comprobar("Dia conserva room_id", controller.estado()["room_id"], "SALA-SENAL")

	var transporte_b := TransporteWebSocket.new(relay.url())
	var servicio_b := SenalServicio.new(transporte_b)
	var apertura_b := servicio_b.abrir_sala("calle", "SALA-SENAL", "anon-signal-b")
	_comprobar("segundo cliente abre sala", apertura_b["ok"], true)

	await _bombear(relay, controller, [transporte_b], 50)
	_comprobar("Dia completa handshake", controller.estado()["red_status"], "online")
	_comprobar("B completa handshake", servicio_b.health()["online"], true)
	_comprobar("relay ve dos clientes", relay.clientes_en_sala("SALA-SENAL"), 2)

	var publicacion := (
		controller
		. publicar_en_anchor(
			"anon-signal-dia",
			"calle_escaparate",
			"cuidado_con",
			["trampa"],
			ahora,
			-1,
			"signal-a-0",
		)
	)
	_comprobar("Dia publica señal por WebSocket", publicacion["ok"], true)
	await _bombear(relay, controller, [transporte_b], 12)
	var consulta_b := servicio_b.consultar("calle", [], ahora + 1)
	_comprobar("B recibe señal del Dia", consulta_b["signals"].size(), 1)
	if consulta_b["signals"].size() == 1:
		_comprobar(
			"B recibe el event_id esperado",
			consulta_b["signals"][0].get("event_id", ""),
			"signal-a-0",
		)

	var bloqueada := (
		servicio_b
		. publicar(
			"calle",
			"test-377",
			"anon-signal-b",
			"calle_escaparate",
			"cuidado_con",
			["simbolo_amarillo"],
			ahora + 2,
			["simbolo_amarillo"],
			-1,
			"signal-b-locked",
		)
	)
	_comprobar("relay admite token catalogado sin conocer progreso", bloqueada["ok"], true)
	await _bombear(relay, controller, [transporte_b], 12)
	_comprobar("relay retiene dos señales", relay.retenidas("SALA-SENAL"), 2)

	servicio_b.cerrar_sala()
	await _bombear(relay, controller, [], 5)
	_comprobar("B sale sin borrar persistencia", relay.retenidas("SALA-SENAL"), 2)

	var transporte_c := TransporteWebSocket.new(relay.url())
	var servicio_c := SenalServicio.new(transporte_c)
	var apertura_c := servicio_c.abrir_sala("calle", "SALA-SENAL", "anon-signal-c")
	_comprobar("C entra después de publicar", apertura_c["ok"], true)
	await _bombear(relay, controller, [transporte_c], 50)
	var replay_c := servicio_c.consultar("calle", [], ahora + 3)
	_comprobar("C recibe replay persistido", replay_c["signals"].size(), 1)
	if replay_c["signals"].size() == 1:
		_comprobar(
			"anti-spoiler filtra replay bloqueado",
			replay_c["signals"][0].get("event_id", ""),
			"signal-a-0",
		)

	var ocultada := servicio_c.ocultar_evento("signal-a-0")
	_comprobar("C oculta señal localmente", ocultada["ok"], true)
	servicio_c.cerrar_sala()
	await _bombear(relay, controller, [], 5)
	servicio_c.abrir_sala("calle", "SALA-SENAL", "anon-signal-c")
	await _bombear(relay, controller, [transporte_c], 50)
	var replay_oculto := servicio_c.consultar("calle", [], ahora + 4)
	_comprobar("señal oculta no reaparece tras reconectar", replay_oculto["signals"].size(), 0)

	var transporte_otra := TransporteWebSocket.new(relay.url())
	var servicio_otra := SenalServicio.new(transporte_otra)
	servicio_otra.abrir_sala("calle", "SALA-OTRA", "anon-signal-otra")
	await _bombear(relay, controller, [transporte_c, transporte_otra], 50)
	var aislada := servicio_otra.consultar("calle", ["simbolo_amarillo"], ahora + 5)
	_comprobar("otra sala no recibe señales", aislada["signals"].size(), 0)

	relay.detener()
	await _bombear(relay, controller, [transporte_c, transporte_otra], 6)
	_comprobar("caída de relay no desactiva Dia", controller.estado()["activa"], true)
	_comprobar(
		"caída queda como estado de red, no fallo de gameplay",
		controller.estado()["red_status"] != "online",
		true,
	)

	servicio_c.cerrar_sala()
	servicio_otra.cerrar_sala()
	controller.desactivar()
	_comprobar("desactivar Dia cierra corte remoto", controller.estado()["activa"], false)
	host.queue_free()
	await process_frame
	_terminar()


func _bombear(
	relay: RelaySenalesWebSocket,
	controller: DiaSenalesMultiplayerApp,
	transportes: Array,
	frames: int,
	delta: float = 0.02,
) -> void:
	for _frame in range(frames):
		controller.procesar(delta)
		for transporte in transportes:
			transporte.procesar(delta)
		relay.procesar()
		controller.procesar(0.0)
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
