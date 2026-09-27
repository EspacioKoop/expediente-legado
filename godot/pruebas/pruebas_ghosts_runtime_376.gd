extends SceneTree

## Segundo vertical de #376: runtime real de Dia + WebSocket asíncrono.

const DiaGhostsApp = preload("res://guion/dia_ghosts_app.gd")
const RelayPresenciaWebSocket = preload("res://guion/red/relay_presencia_websocket.gd")
const TransporteWebSocket = preload("res://guion/red/transporte_websocket.gd")

var pasadas := 0
var fallos := 0
var _ahora := int(Time.get_unix_time_from_system())


class HostFalso:
	extends Node3D

	var jornada := {"fase": "trayecto", "sueno_escenas": []}
	var _espacio_actual := {
		"entrada": Vector3.ZERO,
		"salidas": [{"pos": Vector3(6.0, 0.0, 0.0)}],
		"contorno": [],
		"planta": [],
	}
	var _mundo: Node3D
	var _caminante: CharacterBody3D

	func _init() -> void:
		_mundo = Node3D.new()
		_mundo.name = "Mundo"
		add_child(_mundo)

		_caminante = CharacterBody3D.new()
		_caminante.name = "Caminante"
		add_child(_caminante)

	func poner_sueno(id_escena: String) -> void:
		jornada["fase"] = "sueño"
		jornada["sueno_escenas"] = [id_escena]
		_espacio_actual = {
			"entrada": Vector3.ZERO,
			"salidas": [{"pos": Vector3(6.0, 0.0, 0.0)}],
			"contorno": [],
			"planta": [],
		}


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var relay := RelayPresenciaWebSocket.new()
	var inicio := relay.iniciar_disponible(19280, 20)
	_comprobar("relay de ghosts arranca", inicio.get("ok", false), true)
	if not bool(inicio.get("ok", false)):
		_terminar()
		return

	await _probar_trayecto_asincrono(relay)
	await _probar_movimiento_npc_sueno(relay)
	relay.detener()
	_terminar()


func _probar_trayecto_asincrono(relay: RelayPresenciaWebSocket) -> void:
	var host_a := HostFalso.new()
	var transporte_a := TransporteWebSocket.new(relay.url())
	var a := _nuevo_controlador(host_a, transporte_a, "anon-ghost-a")
	_comprobar("A activa ghosts", a.estado()["habilitado"], true)
	_comprobar("A abre contexto trayecto", a.estado()["scene_key"], "trayecto")
	await _bombear_controladores(relay, [a], 50)

	for i in range(5):
		host_a._caminante.position = Vector3(float(i), 0.0, 0.5)
		a.procesar(0.20, _ahora)
		relay.procesar()
		await process_frame
	var publicado := a.forzar_publicacion(_ahora)
	_comprobar("A publica trayectoria real", publicado.get("ok", false), true)
	await _bombear_red(relay, [transporte_a], 12)
	a.desactivar(_ahora)

	var host_b := HostFalso.new()
	var transporte_b := TransporteWebSocket.new(relay.url())
	var b := _nuevo_controlador(host_b, transporte_b, "anon-ghost-b")
	await _bombear_controladores(relay, [b], 50)
	var consulta := b.consultar_ahora(_ahora + 1)
	_comprobar("B recibe historia aunque A ya salió", consulta.get("ghosts", []).size() >= 1, true)

	var raiz := host_b._mundo.get_node_or_null(DiaGhostsApp.NOMBRE_RAIZ)
	_comprobar("runtime monta raíz de ghosts", raiz != null, true)
	_comprobar(
		"runtime monta al menos un ghost", raiz != null and raiz.get_child_count() >= 1, true
	)
	if raiz != null and raiz.get_child_count() >= 1:
		var ghost = raiz.get_child(0)
		_comprobar("ghost histórico pertenece a A", ghost.actor_public_id, "anon-ghost-a")
		_comprobar(
			"ghost histórico no tiene colisión", ghost.has_method("get_collision_layer"), false
		)
	b.desactivar(_ahora + 1)
	host_a.free()
	host_b.free()


func _probar_movimiento_npc_sueno(relay: RelayPresenciaWebSocket) -> void:
	var host_a := HostFalso.new()
	host_a.poner_sueno("crucero")
	var transporte_a := TransporteWebSocket.new(relay.url())
	var a := _nuevo_controlador(host_a, transporte_a, "anon-sueno-a")
	_comprobar("A abre contexto de sueño", a.estado()["scene_key"], "sueno/crucero")
	_comprobar(
		"revisión de sueño existe", not String(a.estado()["scene_revision"]).is_empty(), true
	)
	await _bombear_controladores(relay, [a], 50)

	for i in range(5):
		host_a._caminante.position = Vector3(float(i) * 0.5, 0.0, 0.0)
		a.procesar(0.20, _ahora + 10)
		relay.procesar()
		await process_frame
	var publicado := a.forzar_publicacion(_ahora + 10)
	_comprobar("A publica movimiento onírico anchor-local", publicado.get("ok", false), true)
	await _bombear_red(relay, [transporte_a], 12)
	a.desactivar(_ahora + 10)

	var host_b := HostFalso.new()
	host_b.poner_sueno("crucero")
	var eco := Node3D.new()
	eco.name = "EcoDelDia"
	eco.position = Vector3(10.0, 0.0, 5.0)
	host_b._mundo.add_child(eco)

	var transporte_b := TransporteWebSocket.new(relay.url())
	var b := _nuevo_controlador(host_b, transporte_b, "anon-sueno-b")
	await _bombear_controladores(relay, [b], 50)
	var consulta := b.consultar_ahora(_ahora + 11)
	_comprobar("B recibe trayectoria de sueño pasada", consulta.get("ghosts", []).size() >= 1, true)

	var trayectoria := eco.get_node_or_null("MovimientoGhost")
	_comprobar("EcoDelDia reutiliza trayectoria remota", trayectoria != null, true)
	_comprobar("NPC no recibe NavigationAgent3D", eco.get_node_or_null("NavigationAgent3D"), null)
	if trayectoria != null:
		trayectoria.avanzar(2.0)
		_comprobar(
			"NPC conserva offset local del anchor", is_equal_approx(eco.position.z, 5.0), true
		)
		_comprobar("NPC se mueve con la forma de la run", eco.position.x > 10.0, true)

	var raiz := host_b._mundo.get_node_or_null(DiaGhostsApp.NOMBRE_RAIZ)
	_comprobar("sueño no monta silueta-guía paralela", raiz, null)
	b.desactivar(_ahora + 11)
	host_a.free()
	host_b.free()


func _nuevo_controlador(
	host: HostFalso, transporte: RefCounted, actor_public_id: String
) -> DiaGhostsApp:
	var controlador := DiaGhostsApp.new()
	host.add_child(controlador)
	controlador._host = host
	var configurado := (
		controlador
		. configurar_transporte(
			transporte,
			actor_public_id,
			DiaGhostsApp.ROOM_ID_DEFECTO,
		)
	)
	_comprobar("controller acepta transporte", configurado.get("ok", false), true)
	return controlador


func _bombear_controladores(
	relay: RelayPresenciaWebSocket,
	controladores: Array,
	frames: int,
	delta: float = 0.02,
) -> void:
	for _frame in range(frames):
		for controlador in controladores:
			controlador.procesar(delta, _ahora)
		relay.procesar()
		for controlador in controladores:
			controlador.procesar(0.0, _ahora)
		await process_frame


func _bombear_red(
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
	print("\nGhosts runtime #376: %d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)
