class_name GolfCoopAcceso
extends CanvasLayer

## Entrada opt-in de #383 montada sobre el golf individual real.
##
## Reutiliza el panel/sala/transporte comunes y la autoridad de golf. No conoce
## Partida, no concede recompensas y no duplica Golf/GolfBola.
signal sesion_terminada(resultado: Dictionary)

const IdentidadOnline = preload("res://guion/red/identidad_online.gd")
const TransporteWebSocket = preload("res://guion/red/transporte_websocket.gd")
const MinijuegoSalaPanel = preload("res://guion/red/minijuego_sala_panel.gd")
const MinijuegoServicio = preload("res://guion/red/minijuego_servicio.gd")
const MinijuegoGolfAutoridad = preload("res://guion/red/minijuego_golf_autoridad.gd")
const GolfHoyoApp = preload("res://guion/golf_hoyo_app.gd")

const AJUSTE_ENDPOINT := "multiplayer/websocket_url"
const AJUSTE_ENDPOINT_LEGACY := "multiplayer/ghosts/websocket_url"
const SCENE_KEY := "oficina/golf_coop"
const NOMBRE_MINIJUEGO := "Golf de pasillo"
const INTERVALO_CONSULTA := 0.10

var identidad_ruta := IdentidadOnline.RUTA
var endpoint_override := ""
var ahora_override := -1

var _superficie: Node3D
var _configuraciones: Array = []
var _actor_override := ""
var _transporte_override: RefCounted
var _identidad: IdentidadOnline
var _servicio: MinijuegoServicio
var _autoridad: MinijuegoGolfAutoridad
var _panel: MinijuegoSalaPanel
var _abrir: Button
var _activar: Button
var _estado: Label
var _hoyo: GolfHoyoApp
var _room_id := ""
var _session_id := ""
var _actores := {}
var _acumulado := 0.0
var _hoyo_indice := -1
var ultimo_resultado: Dictionary = {}


func configurar(
	superficie: Node3D,
	configuraciones: Array,
	actor_prueba: String = "",
	transporte_prueba: RefCounted = null,
) -> void:
	if is_node_ready():
		return
	_superficie = superficie
	_configuraciones = configuraciones.duplicate(true)
	_actor_override = actor_prueba.strip_edges()
	_transporte_override = transporte_prueba


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_construir_ui()
	_refrescar_identidad()


func _process(delta: float) -> void:
	if _servicio == null:
		return
	_servicio.procesar(delta)
	_acumulado += maxf(delta, 0.0)
	if _acumulado < INTERVALO_CONSULTA:
		return
	_acumulado = 0.0
	_consultar_acciones()


func _unhandled_input(evento: InputEvent) -> void:
	if _autoridad == null or not is_instance_valid(_hoyo):
		return
	if evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cerrar_coop(true)
		return
	if not _turno_local():
		return
	if evento.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled()
		_hoyo._ajustar_angulo(-GolfHoyoApp.PASO_ANGULO)
	elif evento.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		_hoyo._ajustar_angulo(GolfHoyoApp.PASO_ANGULO)
	elif evento.is_action_pressed("ui_up"):
		get_viewport().set_input_as_handled()
		_hoyo._ajustar_potencia(GolfHoyoApp.PASO_POTENCIA)
	elif evento.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()
		_hoyo._ajustar_potencia(-GolfHoyoApp.PASO_POTENCIA)
	elif evento.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_publicar_tiro()


func _exit_tree() -> void:
	_cerrar_coop(false)


func _construir_ui() -> void:
	var raiz := Control.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(raiz)

	_abrir = Button.new()
	_abrir.name = "AbrirGolfCoop"
	_abrir.text = tr("VENTANILLA_COOP_TITULO")
	_abrir.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_abrir.offset_left = -250
	_abrir.offset_top = 18
	_abrir.offset_right = -18
	_abrir.offset_bottom = 58
	_abrir.pressed.connect(_abrir_panel)
	raiz.add_child(_abrir)

	_activar = Button.new()
	_activar.name = "ActivarGolfCoop"
	_activar.text = tr("VENTANILLA_COOP_ACTIVAR")
	_activar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_activar.offset_left = -250
	_activar.offset_top = 66
	_activar.offset_right = -18
	_activar.offset_bottom = 106
	_activar.pressed.connect(_activar_online)
	_activar.visible = false
	raiz.add_child(_activar)

	_estado = Label.new()
	_estado.name = "EstadoGolfCoop"
	_estado.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_estado.offset_left = -430
	_estado.offset_top = 112
	_estado.offset_right = -18
	_estado.offset_bottom = 172
	_estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_estado.accessibility_live = AccessibilityServer.LIVE_POLITE
	raiz.add_child(_estado)

	_panel = MinijuegoSalaPanel.new()
	_panel.name = "SalaGolfCoop"
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -280
	_panel.offset_top = -180
	_panel.offset_right = 280
	_panel.offset_bottom = 180
	_panel.crear_sala_solicitada.connect(_abrir_sala)
	_panel.unirse_sala_solicitada.connect(_abrir_sala)
	_panel.cancelar_solicitado.connect(_cancelar_panel)
	raiz.add_child(_panel)


func _refrescar_identidad() -> void:
	if not _actor_override.is_empty():
		_activar.visible = false
		return
	_identidad = IdentidadOnline.new(identidad_ruta)
	var carga := _identidad.cargar()
	var activa := bool(carga.get("ok", false)) and _identidad.activa()
	_activar.visible = not activa


func _abrir_panel() -> void:
	if _servicio != null:
		return
	_bloquear_golf_local(true)
	var actor := _actor_id()
	if actor.is_empty():
		_panel.cerrar()
		_activar.visible = true
		_estado.text = tr("VENTANILLA_COOP_DESACTIVADO")
		return
	_activar.visible = false
	_estado.text = ""
	_panel.abrir(NOMBRE_MINIJUEGO, MinijuegoGolfAutoridad.RULES_VERSION)


func _activar_online() -> void:
	if not _actor_override.is_empty():
		_activar.visible = false
		_abrir_panel()
		return
	_identidad = IdentidadOnline.new(identidad_ruta)
	var carga := _identidad.cargar()
	if not bool(carga.get("ok", false)) and String(carga.get("status", "")) != "disabled":
		_estado.text = tr("VENTANILLA_COOP_IDENTIDAD_ERROR")
		return
	var resultado := _identidad.habilitar()
	if not bool(resultado.get("ok", false)):
		_estado.text = tr("VENTANILLA_COOP_IDENTIDAD_ERROR")
		return
	_refrescar_identidad()
	_abrir_panel()


func _abrir_sala(codigo: String) -> void:
	var actor := _actor_id()
	var room_id := MinijuegoSalaPanel.normalizar_codigo(codigo)
	if actor.is_empty() or not MinijuegoSalaPanel.codigo_valido(room_id):
		_panel.mostrar_estado("closed")
		return

	var transporte := _crear_transporte()
	if transporte == null:
		_panel.mostrar_estado("closed")
		_estado.text = tr("VENTANILLA_COOP_SIN_SERVICIO")
		return

	if _servicio != null:
		_servicio.cerrar_sala()
	_servicio = MinijuegoServicio.new(transporte)
	_room_id = room_id
	_session_id = "golf-%s" % room_id.to_lower()
	_actores.clear()
	_actores[actor] = true
	ultimo_resultado.clear()

	var apertura := (
		_servicio
		. abrir_sala(
			SCENE_KEY,
			_room_id,
			_session_id,
			MinijuegoGolfAutoridad.MINIGAME_ID,
			MinijuegoGolfAutoridad.RULES_VERSION,
			actor,
		)
	)
	if not bool(apertura.get("ok", false)):
		_servicio = null
		_panel.mostrar_estado(String(apertura.get("status", "closed")))
		return

	var listo := (
		_servicio
		. publicar_accion(
			_game_build(),
			0,
			0,
			{"type": "ready"},
			_ahora(),
		)
	)
	if not bool(listo.get("ok", false)):
		_servicio.cerrar_sala()
		_servicio = null
		_panel.mostrar_estado(String(listo.get("status", "closed")))
		return

	_panel.mostrar_estado("online", {"room_id": _room_id})
	_estado.text = "Esperando a la otra persona…"
	_abrir.disabled = true
	_bloquear_golf_local(true)


func _consultar_acciones() -> void:
	if _servicio == null:
		return
	var consulta := _servicio.consultar_acciones(_ahora())
	if not bool(consulta.get("ok", false)):
		return
	for evento in consulta.get("actions", []):
		if not evento is Dictionary:
			continue
		var payload: Dictionary = evento.get("payload", {})
		var accion: Dictionary = payload.get("action", {})
		var tipo := String(accion.get("type", ""))
		if tipo == "ready":
			var actor := String(evento.get("actor_public_id", ""))
			if not actor.is_empty():
				_actores[actor] = true
			continue
		if tipo == MinijuegoGolfAutoridad.TIPO_TIRO and _autoridad != null:
			_aplicar_evento(evento)
	_asegurar_autoridad()


func _asegurar_autoridad() -> void:
	if _autoridad != null or _actores.size() < 2:
		return
	var jugadores := _actores.keys()
	jugadores.sort()
	jugadores = jugadores.slice(0, 2)
	var configuraciones := _configuraciones_para_autoridad()
	_autoridad = (
		MinijuegoGolfAutoridad
		. new(
			_room_id,
			_session_id,
			jugadores,
			configuraciones,
		)
	)
	if not _autoridad.valida():
		_autoridad = null
		_estado.text = tr("VENTANILLA_COOP_ERROR_RED")
		return
	_panel.cerrar()
	_montar_hoyo(int(_autoridad.snapshot().get("state", {}).get("hole", 0)))
	_aplicar_snapshot(_autoridad.snapshot())


func _publicar_tiro() -> void:
	if _servicio == null or _autoridad == null or not is_instance_valid(_hoyo):
		return
	if not _turno_local():
		return
	var snapshot := _autoridad.snapshot()
	var rad := deg_to_rad(_hoyo.angulo_grados)
	var direccion := Vector2(sin(rad), -cos(rad))
	var publicacion := (
		_servicio
		. publicar_accion(
			_game_build(),
			int(snapshot.get("sequence", 0)),
			int(snapshot.get("turn", 0)),
			{
				"type": MinijuegoGolfAutoridad.TIPO_TIRO,
				"direction": [direccion.x, direccion.y],
				"power": _hoyo.potencia,
			},
			_ahora(),
		)
	)
	if not bool(publicacion.get("ok", false)):
		_estado.text = tr("VENTANILLA_COOP_ERROR_RED")
		return
	var evento = publicacion.get("event", {})
	if evento is Dictionary:
		_aplicar_evento(evento)


func _aplicar_evento(evento: Dictionary) -> void:
	if _autoridad == null:
		return
	var aplicado := _autoridad.aplicar_evento(evento, _ahora())
	if not bool(aplicado.get("ok", false)):
		return
	var snapshot: Dictionary = aplicado.get("snapshot", {})
	_aplicar_snapshot(snapshot)


func _aplicar_snapshot(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	if String(snapshot.get("phase", "")) == "finished":
		ultimo_resultado = (snapshot.get("result", {}) as Dictionary).duplicate(true)
		sesion_terminada.emit(ultimo_resultado.duplicate(true))
		_estado.text = "Golf cooperativo finalizado."
		_cerrar_coop(false, true)
		return

	var estado: Dictionary = snapshot.get("state", {})
	var indice := int(estado.get("hole", 0))
	if indice != _hoyo_indice or not is_instance_valid(_hoyo):
		_montar_hoyo(indice)
	if not is_instance_valid(_hoyo):
		return

	var actual := String(estado.get("current_player", ""))
	var posiciones: Dictionary = estado.get("ball_positions", {})
	var valor_posicion = posiciones.get(actual, [0.0, 0.0])
	if valor_posicion is Array and valor_posicion.size() == 2:
		_hoyo.estado_bola["posicion"] = Vector2(
			float(valor_posicion[0]),
			float(valor_posicion[1]),
		)
		_hoyo.estado_bola["velocidad"] = Vector2.ZERO
	var golpes: Dictionary = estado.get("strokes_current", {})
	_hoyo.golpes = int(golpes.get(actual, 0))
	_hoyo.terminada = false
	_hoyo._sincronizar_bola_visual()
	_hoyo._refrescar_ui()
	_estado.text = (
		"Tu turno · sala %s" % _room_id
		if _turno_local()
		else "Turno de la otra persona · sala %s" % _room_id
	)


func _montar_hoyo(indice: int) -> void:
	if _superficie == null or indice < 0 or indice >= _configuraciones.size():
		return
	if is_instance_valid(_hoyo):
		_hoyo.queue_free()
	_hoyo = GolfHoyoApp.new()
	_hoyo.name = "GolfCoopHoyo"
	var configuracion: Dictionary = _configuraciones[indice].duplicate(true)
	configuracion["numero_hoyo"] = indice + 1
	_hoyo.configurar(configuracion)
	_hoyo.set_process_unhandled_input(false)
	_superficie.add_child(_hoyo)
	_hoyo_indice = indice
	_ocultar_golf_local(true)


func _configuraciones_para_autoridad() -> Array:
	var salida: Array = []
	for configuracion in _configuraciones:
		if configuracion is Dictionary:
			salida.append((configuracion as Dictionary).duplicate(true))
	return salida


func _cancelar_panel() -> void:
	if _servicio != null:
		_cerrar_coop(true)
		return
	_panel.cerrar()
	_activar.visible = false
	_estado.text = ""
	_bloquear_golf_local(false)


func _cerrar_coop(abandonar: bool, conservar_estado: bool = false) -> void:
	if abandonar and _autoridad != null:
		var snapshot := _autoridad.snapshot()
		if String(snapshot.get("phase", "")) != "finished":
			_autoridad.abandonar()
	if _servicio != null:
		_servicio.cerrar_sala()
	_servicio = null
	_autoridad = null
	_actores.clear()
	_room_id = ""
	_session_id = ""
	_acumulado = 0.0
	if is_instance_valid(_hoyo):
		_hoyo.queue_free()
	_hoyo = null
	_hoyo_indice = -1
	if is_instance_valid(_panel):
		_panel.cerrar()
	if is_instance_valid(_abrir):
		_abrir.disabled = false
	if not conservar_estado and is_instance_valid(_estado):
		_estado.text = ""
	_ocultar_golf_local(false)
	_bloquear_golf_local(false)


func _bloquear_golf_local(bloqueado: bool) -> void:
	var local := _hoyo_local()
	if local == null:
		return
	local.set_process_unhandled_input(not bloqueado)


func _ocultar_golf_local(oculto: bool) -> void:
	var local := _hoyo_local()
	if local == null:
		return
	local.visible = not oculto
	local.set_physics_process(not oculto)
	if not oculto:
		local.set_process_unhandled_input(true)


func _hoyo_local() -> GolfHoyoApp:
	if _superficie == null:
		return null
	for propiedad in _superficie.get_property_list():
		if String(propiedad.get("name", "")) != "hoyo_actual":
			continue
		var candidato = _superficie.get("hoyo_actual")
		if candidato is GolfHoyoApp and candidato != _hoyo:
			return candidato
		break
	return null


func _turno_local() -> bool:
	if _autoridad == null:
		return false
	var snapshot := _autoridad.snapshot()
	var estado: Dictionary = snapshot.get("state", {})
	var actual := String(estado.get("current_player", ""))
	return actual == _actor_id()


func _actor_id() -> String:
	if not _actor_override.is_empty():
		return _actor_override
	if _identidad == null:
		_identidad = IdentidadOnline.new(identidad_ruta)
		var carga := _identidad.cargar()
		if not bool(carga.get("ok", false)):
			return ""
	if not _identidad.activa():
		return ""
	return _identidad.actor_public_id()


func _crear_transporte() -> RefCounted:
	if _transporte_override != null:
		return _transporte_override
	var endpoint := _endpoint()
	if not endpoint.begins_with("ws://") and not endpoint.begins_with("wss://"):
		return null
	return TransporteWebSocket.new(endpoint)


func _endpoint() -> String:
	if not endpoint_override.strip_edges().is_empty():
		return endpoint_override.strip_edges()
	var endpoint := String(ProjectSettings.get_setting(AJUSTE_ENDPOINT, "")).strip_edges()
	if endpoint.is_empty():
		endpoint = String(ProjectSettings.get_setting(AJUSTE_ENDPOINT_LEGACY, "")).strip_edges()
	return endpoint


func _ahora() -> int:
	if ahora_override > 0:
		return ahora_override
	return int(Time.get_unix_time_from_system())


func _game_build() -> String:
	var version := (
		String(ProjectSettings.get_setting("application/config/version", "dev")).strip_edges()
	)
	return version if not version.is_empty() else "dev"
