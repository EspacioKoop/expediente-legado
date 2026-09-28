extends SceneTree

## UI + conexión real de la presencia coop en trayecto (#379).

const DiaPresenciaCoopApp = preload("res://guion/dia_presencia_coop_app.gd")
const IdentidadOnline = preload("res://guion/red/identidad_online.gd")
const PresenciaServicio = preload("res://guion/red/presencia_servicio.gd")
const RelayPresenciaWebSocket = preload("res://guion/red/relay_presencia_websocket.gd")
const TransporteWebSocket = preload("res://guion/red/transporte_websocket.gd")

const ROOM_ID := "ABC234"
const AHORA := 2_101_000_000

var pasadas := 0
var fallos := 0


class HostFalso:
	extends Node3D

	var jornada := {"fase": "trayecto"}
	var _mundo: Node3D
	var _caminante: CharacterBody3D
	var _pantalla = null

	func _init() -> void:
		_mundo = Node3D.new()
		_mundo.name = "Mundo"
		add_child(_mundo)

		_caminante = CharacterBody3D.new()
		_caminante.name = "Caminante"
		add_child(_caminante)


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var identidad := IdentidadOnline.new()
	identidad.deshabilitar()
	ProjectSettings.set_setting(DiaPresenciaCoopApp.AJUSTE_ENDPOINT, "")

	var host := HostFalso.new()
	root.add_child(host)
	var controlador := DiaPresenciaCoopApp.new()
	host.add_child(controlador)
	await process_frame
	await process_frame

	var boton := controlador.get_node_or_null("PresenciaCoopUI/AbrirPresenciaCoop") as Button
	var panel := (
		controlador.get_node_or_null("PresenciaCoopUI/PanelPresenciaCoop") as PresenciaSalaPanel
	)
	_comprobar("botón coop existe", boton != null, true)
	_comprobar("botón solo aparece en trayecto", boton.visible, true)
	_comprobar("panel empieza cerrado", panel.visible, false)

	boton.pressed.emit()
	await process_frame
	_comprobar("botón abre panel", panel.visible, true)
	_comprobar(
		"abrir panel inmoviliza caminante",
		host._caminante.process_mode,
		Node.PROCESS_MODE_DISABLED,
	)

	var sin_endpoint := controlador.conectar_codigo(ROOM_ID)
	_comprobar("sin endpoint falla cerrado", sin_endpoint["status"], "unconfigured")
	_comprobar("sin endpoint no activa sesión", controlador.estado()["activa"], false)

	var relay := RelayPresenciaWebSocket.new()
	var inicio := relay.iniciar_disponible()
	_comprobar("relay local disponible", inicio["ok"], true)
	if not bool(inicio["ok"]):
		_terminar(host, relay, identidad)
		return

	ProjectSettings.set_setting(DiaPresenciaCoopApp.AJUSTE_ENDPOINT, relay.url())
	var apertura := controlador.conectar_codigo(ROOM_ID)
	_comprobar("UI abre sesión real", apertura["ok"], true)
	_comprobar("código queda activo", controlador.estado()["room_id"], ROOM_ID)

	var transporte_remoto := TransporteWebSocket.new(relay.url())
	var remoto := PresenciaServicio.new(transporte_remoto)
	_comprobar(
		"segundo cliente abre misma sala",
		remoto.abrir_sala("trayecto", ROOM_ID, "anon-remoto")["ok"],
		true,
	)

	await _bombear(relay, controlador, remoto, 60)
	_comprobar("cliente UI queda online", controlador.estado()["red"]["online"], true)
	_comprobar("segundo cliente queda online", remoto.estado_transporte()["online"], true)
	_comprobar("botón muestra sala", boton.text.contains(ROOM_ID), true)

	var publicado := (
		remoto
		. publicar_snapshot(
			"test-379-ui",
			Vector3(3.0, 0.0, -2.0),
			0.4,
			"walk",
			"saludo",
			AHORA,
			"ui-remoto-0",
		)
	)
	_comprobar("remoto publica presencia", publicado["ok"], true)
	await _bombear(relay, controlador, remoto, 18)

	var lista := panel.find_child("ParticipantesSala", true, false) as ItemList
	var ocultar := panel.find_child("OcultarParticipante", true, false) as Button
	_comprobar("remoto aparece en mundo", controlador.estado()["remotos"], 1)
	_comprobar("remoto aparece en lista", lista.item_count, 1)
	_comprobar("lista usa id público", lista.get_item_text(0), "anon-remoto")
	_comprobar("acción ocultar disponible", ocultar.visible and not ocultar.disabled, true)

	lista.select(0)
	ocultar.pressed.emit()
	await process_frame
	_comprobar("ocultar desmonta avatar", controlador.estado()["remotos"], 0)
	_comprobar("ocultar limpia lista", lista.item_count, 0)

	var salir := panel.find_child("SalirSala", true, false) as Button
	salir.pressed.emit()
	await process_frame
	_comprobar("salir cierra sesión", controlador.estado()["activa"], false)

	panel.cerrar_solicitado.emit()
	await process_frame
	_comprobar(
		"cerrar panel restaura caminante", host._caminante.process_mode, Node.PROCESS_MODE_INHERIT
	)

	host.jornada["fase"] = "casa"
	controlador._sincronizar_ui()
	_comprobar("fuera de trayecto se oculta acceso", boton.visible, false)

	remoto.cerrar_sala()
	_terminar(host, relay, identidad)


func _bombear(
	relay: RelayPresenciaWebSocket,
	controlador: DiaPresenciaCoopApp,
	remoto: PresenciaServicio,
	frames: int,
) -> void:
	for _frame in range(frames):
		remoto.procesar(0.02)
		controlador.procesar(0.02, AHORA)
		relay.procesar()
		remoto.procesar(0.0)
		controlador.procesar(0.0, AHORA)
		await process_frame


func _terminar(host: Node, relay: RelayPresenciaWebSocket, identidad: IdentidadOnline) -> void:
	ProjectSettings.set_setting(DiaPresenciaCoopApp.AJUSTE_ENDPOINT, null)
	identidad.deshabilitar()
	relay.detener()
	if is_instance_valid(host):
		host.queue_free()
	print("\nPresencia UI #379: %d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _comprobar(nombre: String, obtenido: Variant, esperado: Variant) -> void:
	if obtenido == esperado:
		pasadas += 1
		return
	fallos += 1
	push_error("%s: esperado %s, obtenido %s" % [nombre, esperado, obtenido])
