class_name DiaPresenciaCoopApp
extends Node

## Cablea #379 al recorrido real sin convertir Dia ni Partida en estado de red.
##
## La sesión es explícitamente opt-in. Mientras no se llame activar_sala(), este
## controller no publica ni consulta nada. Solo opera en `trayecto`: cambiar de
## fase cierra la sala y desmonta las presencias remotas.

const IdentidadOnline = preload("res://guion/red/identidad_online.gd")
const PresenciaDatos = preload("res://guion/red/presencia_datos.gd")
const PresenciaServicio = preload("res://guion/red/presencia_servicio.gd")
const PresenciaRemota3D = preload("res://guion/red/presencia_remota_3d.gd")
const PresenciaSalaPanel = preload("res://guion/red/presencia_sala_panel.gd")
const TransporteNulo = preload("res://guion/red/transporte_nulo.gd")
const TransporteOnlineFactory = preload("res://guion/red/transporte_online_factory.gd")

const AJUSTE_ENDPOINT := "multiplayer/presencia/websocket_url"
const FASE_COMPARTIDA := "trayecto"
const SCENE_KEY := "trayecto"
const NOMBRE_RAIZ := "PresenciasCoopRemotas"
const FRECUENCIA_HZ := 10.0
const INTERVALO_SEGUNDOS := 1.0 / FRECUENCIA_HZ
const UMBRAL_MOVIMIENTO_CUADRADO := 0.01

var _host
var _servicio
var _activa := false
var _room_id := ""
var _actor_public_id := ""
var _gesto_pendiente := ""
var _acumulado_publicar := 0.0
var _acumulado_consultar := 0.0
var _mundo_id := 0
var _raiz_remota: Node3D
var _avatares: Dictionary = {}
var _ultimo_visto: Dictionary = {}
var _capa_ui: CanvasLayer
var _boton_sala: Button
var _panel_sala: PresenciaSalaPanel
var _caminante_ui: Node
var _modo_caminante_previo := Node.PROCESS_MODE_INHERIT
var _mouse_previo := Input.MOUSE_MODE_CAPTURED
var _panel_ui_abierto := false


func _ready() -> void:
	_host = get_parent()
	call_deferred("_asegurar_ui")


func _process(delta: float) -> void:
	_sincronizar_ui()
	procesar(delta)


func _exit_tree() -> void:
	_cerrar_panel()
	desactivar_sala()


func activar_sala(
	room_id: String,
	transporte: RefCounted = null,
	actor_public_id: String = "",
) -> Dictionary:
	if _host == null or not is_instance_valid(_host):
		return {"ok": false, "status": "dia_no_disponible"}
	if _fase_actual() != FASE_COMPARTIDA:
		return {"ok": false, "status": "fase_no_compartida"}

	var actor_id := actor_public_id.strip_edges()
	if actor_id.is_empty():
		actor_id = _crear_actor_efimero()

	var transporte_efectivo := transporte
	if transporte_efectivo == null:
		transporte_efectivo = TransporteNulo.new()

	var servicio := PresenciaServicio.new(transporte_efectivo)
	var apertura := servicio.abrir_sala(SCENE_KEY, room_id.strip_edges(), actor_id)
	if not bool(apertura.get("ok", false)):
		return apertura

	desactivar_sala()
	_servicio = servicio
	_activa = true
	_room_id = room_id.strip_edges()
	_actor_public_id = actor_id
	_acumulado_publicar = 0.0
	_acumulado_consultar = 0.0
	_gesto_pendiente = ""
	_asegurar_raiz_remota()

	var salida: Dictionary = apertura.duplicate(true)
	salida["actor_public_id"] = actor_id
	return salida


func desactivar_sala() -> Dictionary:
	var resultado := {"ok": true, "status": "inactive"}
	if _servicio != null and _servicio.activa():
		resultado = _servicio.cerrar_sala()
	_servicio = null
	_activa = false
	_room_id = ""
	_actor_public_id = ""
	_gesto_pendiente = ""
	_acumulado_publicar = 0.0
	_acumulado_consultar = 0.0
	_limpiar_remotos()
	_actualizar_lista_participantes()
	_actualizar_boton_sala()
	return resultado


func conectar_codigo(codigo: String) -> Dictionary:
	var normalizado := PresenciaSalaPanel.normalizar_codigo(codigo)
	if (
		not PresenciaSalaPanel.codigo_valido(normalizado)
		or not PresenciaDatos.validar_room_id(normalizado)
	):
		var invalido := {"ok": false, "status": "invalid_room_id"}
		_mostrar_estado_sala(invalido)
		return invalido

	var endpoint := String(ProjectSettings.get_setting(AJUSTE_ENDPOINT, "")).strip_edges()
	if endpoint.is_empty():
		var sin_endpoint := {"ok": false, "status": "unconfigured"}
		_mostrar_estado_sala(sin_endpoint)
		return sin_endpoint

	var identidad := IdentidadOnline.new()
	var carga := identidad.cargar()
	if not bool(carga.get("ok", false)):
		var invalida := {"ok": false, "status": "identity_unavailable"}
		_mostrar_estado_sala(invalida)
		return invalida
	if not identidad.activa():
		var habilitada := identidad.habilitar()
		if not bool(habilitada.get("ok", false)):
			_mostrar_estado_sala(habilitada)
			return habilitada

	var actor_id := identidad.actor_public_id()
	var transporte := TransporteOnlineFactory.crear(endpoint, false)
	if transporte == null:
		var invalido_endpoint := {"ok": false, "status": "unconfigured"}
		_mostrar_estado_sala(invalido_endpoint)
		return invalido_endpoint
	var resultado := activar_sala(normalizado, transporte, actor_id)
	_mostrar_estado_sala(resultado)
	return resultado


func ocultar_participante(actor_public_id: String) -> bool:
	if _servicio == null or not _servicio.activa():
		return false
	if not _servicio.ocultar_participante(actor_public_id):
		return false
	var avatar = _avatares.get(actor_public_id)
	if avatar != null and is_instance_valid(avatar):
		if avatar.get_parent() != null:
			avatar.get_parent().remove_child(avatar)
		avatar.queue_free()
	_avatares.erase(actor_public_id)
	_ultimo_visto.erase(actor_public_id)
	_actualizar_lista_participantes()
	return true


func hacer_gesto(gesto: String) -> bool:
	if not _activa or gesto.is_empty() or not PresenciaDatos.GESTOS.has(gesto):
		return false
	_gesto_pendiente = gesto
	return true


func procesar(delta: float, ahora_unix: int = -1) -> void:
	if not _activa:
		return
	if _host == null or not is_instance_valid(_host):
		desactivar_sala()
		return
	if _fase_actual() != FASE_COMPARTIDA:
		desactivar_sala()
		return
	if _servicio != null:
		_servicio.procesar(delta)
		_actualizar_estado_red()
	if not _host.has_method("get") or not is_instance_valid(_host._mundo):
		return

	var caminante := _host._caminante as CharacterBody3D
	if caminante == null or not is_instance_valid(caminante):
		return
	if not _asegurar_raiz_remota():
		return

	var ahora := _ahora(ahora_unix)
	_acumulado_publicar += maxf(delta, 0.0)
	_acumulado_consultar += maxf(delta, 0.0)

	if _acumulado_publicar >= INTERVALO_SEGUNDOS:
		_acumulado_publicar = 0.0
		_publicar(caminante, ahora)

	if _acumulado_consultar >= INTERVALO_SEGUNDOS:
		_acumulado_consultar = 0.0
		_consultar(ahora)


func estado() -> Dictionary:
	return {
		"activa": _activa,
		"fase": _fase_actual(),
		"room_id": _room_id,
		"actor_public_id": _actor_public_id,
		"remotos": _avatares.size(),
		"red": _estado_red(),
	}


func _publicar(caminante: CharacterBody3D, ahora_unix: int) -> void:
	if _servicio == null:
		return
	var movimiento := "idle"
	if caminante.velocity.length_squared() > UMBRAL_MOVIMIENTO_CUADRADO:
		movimiento = "walk"

	(
		_servicio
		. publicar_snapshot(
			_game_build(),
			caminante.position,
			caminante.rotation.y,
			movimiento,
			_gesto_pendiente,
			ahora_unix,
		)
	)
	# Un gesto es un impulso visual, no un estado que deba repetirse mientras
	# haya una caída de red.
	_gesto_pendiente = ""


func _consultar(ahora_unix: int) -> void:
	if _servicio == null:
		return
	var consulta: Dictionary = _servicio.consultar(ahora_unix)
	if bool(consulta.get("ok", false)):
		for evento in consulta.get("participants", []):
			_aplicar_remoto(evento, ahora_unix)
	_limpiar_expirados(ahora_unix)


func _aplicar_remoto(evento: Dictionary, ahora_unix: int) -> void:
	var actor_id := String(evento.get("actor_public_id", ""))
	if actor_id.is_empty() or _raiz_remota == null:
		return

	var avatar: PresenciaRemota3D
	if _avatares.has(actor_id) and is_instance_valid(_avatares[actor_id]):
		avatar = _avatares[actor_id]
	else:
		avatar = PresenciaRemota3D.new()
		avatar.name = "Remoto_%s" % actor_id.left(16)
		_raiz_remota.add_child(avatar)
		_avatares[actor_id] = avatar

	if avatar.aplicar_evento(evento):
		_ultimo_visto[actor_id] = ahora_unix
		_actualizar_lista_participantes()


func _limpiar_expirados(ahora_unix: int) -> void:
	for actor_id in _ultimo_visto.keys().duplicate():
		var visto := int(_ultimo_visto.get(actor_id, ahora_unix))
		if ahora_unix - visto <= PresenciaDatos.TTL_SEGUNDOS:
			continue
		var avatar = _avatares.get(actor_id)
		if avatar != null and is_instance_valid(avatar):
			if avatar.get_parent() != null:
				avatar.get_parent().remove_child(avatar)
			avatar.queue_free()
		_avatares.erase(actor_id)
		_ultimo_visto.erase(actor_id)
	_actualizar_lista_participantes()


func _asegurar_raiz_remota() -> bool:
	if _host == null or not is_instance_valid(_host):
		return false
	var mundo := _host._mundo as Node3D
	if mundo == null or not is_instance_valid(mundo):
		return false

	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_id and is_instance_valid(_raiz_remota):
		return true

	_limpiar_remotos()
	_mundo_id = mundo_id
	_raiz_remota = Node3D.new()
	_raiz_remota.name = NOMBRE_RAIZ
	mundo.add_child(_raiz_remota)
	return true


func _limpiar_remotos() -> void:
	_avatares.clear()
	_ultimo_visto.clear()
	_mundo_id = 0
	if is_instance_valid(_raiz_remota):
		if _raiz_remota.get_parent() != null:
			_raiz_remota.get_parent().remove_child(_raiz_remota)
		_raiz_remota.queue_free()
	_raiz_remota = null


func _asegurar_ui() -> void:
	if is_instance_valid(_capa_ui):
		return
	if _host == null or not is_instance_valid(_host):
		return

	_capa_ui = CanvasLayer.new()
	_capa_ui.name = "PresenciaCoopUI"
	_capa_ui.layer = 38
	add_child(_capa_ui)

	_panel_sala = PresenciaSalaPanel.new()
	_panel_sala.name = "PanelPresenciaCoop"
	_panel_sala.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel_sala.position = Vector2(-260.0, -150.0)
	_panel_sala.crear_sala_solicitada.connect(_al_crear_sala)
	_panel_sala.unirse_sala_solicitada.connect(_al_unirse_sala)
	_panel_sala.salir_sala_solicitada.connect(_salir_sala_desde_ui)
	_panel_sala.ocultar_participante_solicitado.connect(ocultar_participante)
	_panel_sala.cerrar_solicitado.connect(_cerrar_panel)
	_capa_ui.add_child(_panel_sala)

	_boton_sala = Button.new()
	_boton_sala.name = "AbrirPresenciaCoop"
	_boton_sala.text = _panel_sala.texto("boton")
	_boton_sala.accessibility_name = _panel_sala.texto("titulo")
	_boton_sala.focus_mode = Control.FOCUS_ALL
	_boton_sala.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_boton_sala.offset_left = 18.0
	_boton_sala.offset_top = -58.0
	_boton_sala.offset_right = 108.0
	_boton_sala.offset_bottom = -18.0
	_boton_sala.pressed.connect(_abrir_panel)
	_capa_ui.add_child(_boton_sala)
	_sincronizar_ui()


func _sincronizar_ui() -> void:
	if not is_instance_valid(_capa_ui):
		_asegurar_ui()
	if not is_instance_valid(_boton_sala):
		return
	var en_trayecto := _fase_actual() == FASE_COMPARTIDA
	_boton_sala.visible = en_trayecto
	if not en_trayecto and is_instance_valid(_panel_sala) and _panel_sala.visible:
		_cerrar_panel()
	_actualizar_boton_sala()


func _abrir_panel() -> void:
	if _fase_actual() != FASE_COMPARTIDA:
		return
	_asegurar_ui()
	if not is_instance_valid(_panel_sala):
		return
	if _panel_ui_abierto:
		return
	_panel_ui_abierto = true
	_mouse_previo = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_caminante_ui = _host.get("_caminante") if _host != null else null
	if is_instance_valid(_caminante_ui):
		_modo_caminante_previo = _caminante_ui.process_mode
		_caminante_ui.process_mode = Node.PROCESS_MODE_DISABLED
	_panel_sala.abrir(_room_id)
	_actualizar_lista_participantes()
	if _activa:
		_actualizar_estado_red()


func _cerrar_panel() -> void:
	if is_instance_valid(_panel_sala):
		_panel_sala.cerrar()
	if not _panel_ui_abierto:
		return
	_panel_ui_abierto = false
	if is_instance_valid(_caminante_ui):
		_caminante_ui.process_mode = _modo_caminante_previo
	_caminante_ui = null
	Input.mouse_mode = _mouse_previo


func _al_crear_sala(codigo: String) -> void:
	conectar_codigo(codigo)


func _al_unirse_sala(codigo: String) -> void:
	conectar_codigo(codigo)


func _salir_sala_desde_ui() -> void:
	desactivar_sala()
	if is_instance_valid(_panel_sala):
		_panel_sala.mostrar_estado("closed")


func _mostrar_estado_sala(resultado: Dictionary) -> void:
	if not is_instance_valid(_panel_sala):
		return
	(
		_panel_sala
		. mostrar_estado(
			String(resultado.get("status", "error")),
			{"room_id": _room_id},
		)
	)
	_actualizar_boton_sala()


func _actualizar_estado_red() -> void:
	if not _activa:
		return
	var estado_red := _estado_red()
	if is_instance_valid(_panel_sala) and _panel_sala.visible:
		_panel_sala.mostrar_estado(String(estado_red.get("status", "error")), {"room_id": _room_id})
	_actualizar_boton_sala()


func _estado_red() -> Dictionary:
	if _servicio == null or not _servicio.activa():
		return {"ok": true, "status": "inactive", "online": false}
	var estado_transporte: Variant = _servicio.estado_transporte()
	if not estado_transporte is Dictionary:
		return {"ok": false, "status": "transport_unavailable", "online": false}
	var estado: Dictionary = estado_transporte
	return estado


func _actualizar_boton_sala() -> void:
	if not is_instance_valid(_boton_sala) or not is_instance_valid(_panel_sala):
		return
	_boton_sala.text = _panel_sala.texto("boton")
	if _activa and not _room_id.is_empty():
		_boton_sala.text += " · " + _room_id


func _actualizar_lista_participantes() -> void:
	if not is_instance_valid(_panel_sala):
		return
	var actores: Array[String] = []
	for actor in _avatares.keys():
		actores.append(String(actor))
	actores.sort()
	_panel_sala.actualizar_participantes(actores)


func _fase_actual() -> String:
	if _host == null or not is_instance_valid(_host):
		return ""
	if typeof(_host.jornada) != TYPE_DICTIONARY:
		return ""
	return String(_host.jornada.get("fase", "")).strip_edges()


func _crear_actor_efimero() -> String:
	var bytes := Crypto.new().generate_random_bytes(8)
	return "anon-" + bytes.hex_encode()


func _game_build() -> String:
	var version := (
		String(ProjectSettings.get_setting("application/config/version", "dev")).strip_edges()
	)
	return "dev" if version.is_empty() else version


func _ahora(valor: int) -> int:
	if valor >= 0:
		return valor
	return int(Time.get_unix_time_from_system())
