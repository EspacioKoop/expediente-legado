class_name DiaGhostsApp
extends Node

## Integra los ghosts asíncronos de #376 en el Dia real.
##
## Solo se activa de forma explícita (o cuando IdentidadOnline ya está habilitada
## y existe un endpoint configurado). En trayecto reproduce siluetas no sólidas;
## en sueño reutiliza únicamente trayectorias relativas a un anchor local para
## coreografiar EcoDelDia, sin importar diálogo, navegación ni progreso.

const EcosSueno3D = preload("res://guion/ecos_sueno_3d.gd")
const EventoOnline = preload("res://guion/red/evento_online.gd")
const GhostDatos = preload("res://guion/red/ghost_datos.gd")
const GhostGrabador = preload("res://guion/red/ghost_grabador.gd")
const GhostRemoto3D = preload("res://guion/red/ghost_remoto_3d.gd")
const GhostServicio = preload("res://guion/red/ghost_servicio.gd")
const IdentidadOnline = preload("res://guion/red/identidad_online.gd")
const TransporteNulo = preload("res://guion/red/transporte_nulo.gd")
const TransporteWebSocket = preload("res://guion/red/transporte_websocket.gd")

const AJUSTE_ENDPOINT := "multiplayer/ghosts/websocket_url"
const ROOM_ID_DEFECTO := "GHOSTS-98"
const NOMBRE_RAIZ := "GhostsAsincronos"
const SAMPLE_RATE := 6.0
const SEGMENTO_SEGUNDOS := 6.0
const INTERVALO_CONSULTA := 2.0
const ANCHOR_SUENO := "entrada-local"

var _host
var _transporte: RefCounted
var _servicio: GhostServicio
var _grabador: GhostGrabador
var _habilitado := false
var _room_id := ROOM_ID_DEFECTO
var _actor_public_id := ""

var _scene_key := ""
var _scene_revision := ""
var _space := "scene"
var _anchor_key := ""
var _origen_anchor := Vector3.ZERO
var _modo := ""

var _segmento_tiempo := 0.0
var _tiempo_local := 0.0
var _acumulado_consulta := 0.0
var _contador_eventos := 0
var _mundo_id := 0
var _raiz_ghosts: Node3D
var _vistos: Dictionary = {}
var _pendiente_sueno: Dictionary = {}


func _ready() -> void:
	_host = get_parent()
	_configurar_desde_identidad()


func _process(delta: float) -> void:
	procesar(delta)


func _exit_tree() -> void:
	desactivar()


func configurar_transporte(
	transporte: RefCounted,
	actor_public_id: String,
	room_id: String = ROOM_ID_DEFECTO,
	habilitado: bool = true
) -> Dictionary:
	desactivar()
	var actor := actor_public_id.strip_edges()
	var sala := room_id.strip_edges()
	if not habilitado:
		return {"ok": true, "status": "disabled"}
	if actor.is_empty() or sala.is_empty():
		return {"ok": false, "status": "invalid_context"}

	_transporte = transporte if transporte != null else TransporteNulo.new()
	_actor_public_id = actor
	_room_id = sala
	_servicio = GhostServicio.new(_transporte, true)
	_servicio.configurar_actor_local(actor)
	_habilitado = true
	_acumulado_consulta = INTERVALO_CONSULTA
	_sincronizar_contexto(_ahora(-1))
	return {"ok": true, "status": "enabled", "actor_public_id": actor}


func desactivar(ahora_unix: int = -1) -> Dictionary:
	var ahora := _ahora(ahora_unix)
	if _habilitado:
		_publicar_segmento(ahora)
	var resultado := {"ok": true, "status": "disabled"}
	if _transporte != null and _transporte.has_method("cerrar_sala"):
		var cierre = _transporte.call("cerrar_sala")
		if typeof(cierre) == TYPE_DICTIONARY:
			resultado = cierre

	_habilitado = false
	_servicio = null
	_grabador = null
	_transporte = null
	_actor_public_id = ""
	_scene_key = ""
	_scene_revision = ""
	_space = "scene"
	_anchor_key = ""
	_origen_anchor = Vector3.ZERO
	_modo = ""
	_segmento_tiempo = 0.0
	_tiempo_local = 0.0
	_acumulado_consulta = 0.0
	_pendiente_sueno.clear()
	_limpiar_visuales()
	return resultado


func habilitado() -> bool:
	return _habilitado


func procesar(delta: float, ahora_unix: int = -1) -> void:
	if not _habilitado or _host == null or not is_instance_valid(_host):
		return
	if _transporte != null and _transporte.has_method("procesar"):
		_transporte.call("procesar", maxf(delta, 0.0))

	var ahora := _ahora(ahora_unix)
	_sincronizar_contexto(ahora)
	if _scene_key.is_empty():
		return
	if not _mundo_disponible():
		return

	_tiempo_local += maxf(delta, 0.0)
	_segmento_tiempo += maxf(delta, 0.0)
	_registrar_muestra()
	if _segmento_tiempo >= SEGMENTO_SEGUNDOS:
		_publicar_segmento(ahora)

	_acumulado_consulta += maxf(delta, 0.0)
	if _acumulado_consulta >= INTERVALO_CONSULTA:
		_acumulado_consulta = 0.0
		_consultar(ahora)

	if _modo == "trayecto":
		_limpiar_finalizados()
	elif _modo == "sueno":
		_aplicar_pendiente_sueno(ahora)


func forzar_publicacion(ahora_unix: int = -1) -> Dictionary:
	return _publicar_segmento(_ahora(ahora_unix))


func consultar_ahora(ahora_unix: int = -1) -> Dictionary:
	return _consultar(_ahora(ahora_unix))


func estado() -> Dictionary:
	return {
		"habilitado": _habilitado,
		"scene_key": _scene_key,
		"scene_revision": _scene_revision,
		"modo": _modo,
		"actor_public_id": _actor_public_id,
		"room_id": _room_id,
		"visibles": _raiz_ghosts.get_child_count() if is_instance_valid(_raiz_ghosts) else 0,
		"pendiente_sueno": not _pendiente_sueno.is_empty(),
	}


func _configurar_desde_identidad() -> void:
	var endpoint := String(ProjectSettings.get_setting(AJUSTE_ENDPOINT, "")).strip_edges()
	if endpoint.is_empty():
		return
	var identidad := IdentidadOnline.new()
	var carga := identidad.cargar()
	if not bool(carga.get("ok", false)) or not identidad.activa():
		return
	var actor := identidad.actor_public_id()
	if actor.is_empty():
		return
	configurar_transporte(TransporteWebSocket.new(endpoint), actor)


func _sincronizar_contexto(ahora_unix: int) -> void:
	var contexto := _contexto_actual()
	var nueva_clave := String(contexto.get("scene_key", ""))
	var nueva_revision := String(contexto.get("scene_revision", ""))
	if nueva_clave == _scene_key and nueva_revision == _scene_revision:
		return

	_publicar_segmento(ahora_unix)
	if _transporte != null and _transporte.has_method("cerrar_sala"):
		_transporte.call("cerrar_sala")
	_limpiar_visuales()
	_pendiente_sueno.clear()
	_grabador = null
	_scene_key = nueva_clave
	_scene_revision = nueva_revision
	_space = String(contexto.get("space", "scene"))
	_anchor_key = String(contexto.get("anchor_key", ""))
	_origen_anchor = contexto.get("origen_anchor", Vector3.ZERO)
	_modo = String(contexto.get("modo", ""))
	_segmento_tiempo = 0.0
	_tiempo_local = 0.0
	_acumulado_consulta = INTERVALO_CONSULTA
	_vistos.clear()
	if _servicio != null:
		_servicio.reiniciar_seleccion()

	if _scene_key.is_empty():
		return
	if _transporte != null and _transporte.has_method("abrir_sala"):
		var apertura = _transporte.call(
			"abrir_sala",
			_scene_key,
			{"room_id": _room_id, "actor_public_id": _actor_public_id}
		)
		if typeof(apertura) == TYPE_DICTIONARY and not bool(apertura.get("ok", false)):
			_scene_key = ""
			_scene_revision = ""
			_modo = ""
			return
	_crear_grabador()


func _contexto_actual() -> Dictionary:
	if _host == null or not is_instance_valid(_host):
		return {}
	if typeof(_host.jornada) != TYPE_DICTIONARY:
		return {}
	var fase := String(_host.jornada.get("fase", ""))
	var espacio: Dictionary = _host._espacio_actual if typeof(_host._espacio_actual) == TYPE_DICTIONARY else {}
	if fase == "trayecto":
		return {
			"scene_key": "trayecto",
			"scene_revision": _revision_espacio("trayecto", espacio),
			"space": "scene",
			"anchor_key": "",
			"origen_anchor": Vector3.ZERO,
			"modo": "trayecto",
		}
	if fase != "sueño":
		return {}

	var escenas = _host.jornada.get("sueno_escenas", [])
	if typeof(escenas) != TYPE_ARRAY or escenas.is_empty():
		return {}
	var escena_id := String(escenas[0]).strip_edges()
	if escena_id.is_empty():
		return {}
	return {
		"scene_key": "sueno/%s" % escena_id,
		"scene_revision": _revision_espacio("sueno-%s" % escena_id, espacio),
		"space": "anchor",
		"anchor_key": ANCHOR_SUENO,
		"origen_anchor": espacio.get("entrada", Vector3.ZERO),
		"modo": "sueno",
	}


func _crear_grabador() -> void:
	if _scene_key.is_empty() or _actor_public_id.is_empty():
		_grabador = null
		return
	_grabador = GhostGrabador.new(
		_scene_key,
		_scene_revision,
		_game_build(),
		_actor_public_id,
		SAMPLE_RATE,
		_space,
		_anchor_key
	)


func _registrar_muestra() -> void:
	if _grabador == null or _host == null or not is_instance_valid(_host):
		return
	var caminante := _host._caminante as CharacterBody3D
	if caminante == null or not is_instance_valid(caminante):
		return
	var posicion := caminante.position
	if _space == "anchor":
		posicion -= _origen_anchor
	_grabador.registrar(_tiempo_local, posicion, caminante.rotation.y)


func _publicar_segmento(ahora_unix: int) -> Dictionary:
	if _grabador == null or _servicio == null:
		return {"ok": true, "status": "no_segment"}
	var frames := _grabador.frames()
	if frames.size() < 2:
		_grabador.reiniciar()
		_segmento_tiempo = 0.0
		_tiempo_local = 0.0
		return {"ok": true, "status": "too_short"}

	_contador_eventos += 1
	var event_id := "ghost-%s-%d-%d" % [
		_actor_public_id.right(12),
		ahora_unix,
		_contador_eventos,
	]
	var creado := _grabador.exportar_evento(ahora_unix, event_id.left(EventoOnline.MAX_EVENT_ID))
	var resultado := {"ok": false, "status": "invalid_ghost"}
	if bool(creado.get("ok", false)):
		resultado = _servicio.publicar(creado["event"], ahora_unix)
	_crear_grabador()
	_segmento_tiempo = 0.0
	_tiempo_local = 0.0
	return resultado


func _consultar(ahora_unix: int) -> Dictionary:
	if _servicio == null or _scene_key.is_empty():
		return {"ok": true, "status": "inactive", "ghosts": []}
	var consulta := _servicio.consultar(
		_scene_key,
		_scene_revision,
		ahora_unix,
		_anchor_key,
	)
	if not bool(consulta.get("ok", false)):
		return consulta

	if _modo == "trayecto":
		for evento in consulta.get("ghosts", []):
			_montar_ghost_trayecto(evento, ahora_unix)
	elif _modo == "sueno" and _pendiente_sueno.is_empty():
		for evento in consulta.get("ghosts", []):
			var huella := EventoOnline.huella(evento)
			if _vistos.has(huella):
				continue
			_pendiente_sueno = evento.duplicate(true)
			break
		_aplicar_pendiente_sueno(ahora_unix)
	return consulta


func _montar_ghost_trayecto(evento: Dictionary, ahora_unix: int) -> void:
	if not _asegurar_raiz_ghosts():
		return
	var huella := EventoOnline.huella(evento)
	if _vistos.has(huella):
		return
	var ghost := GhostRemoto3D.new()
	ghost.name = "Ghost_%d" % (_raiz_ghosts.get_child_count() + 1)
	_raiz_ghosts.add_child(ghost)
	if not ghost.cargar_evento(evento, _scene_revision, ahora_unix):
		ghost.queue_free()
		return
	_vistos[huella] = true


func _aplicar_pendiente_sueno(ahora_unix: int) -> void:
	if _pendiente_sueno.is_empty() or not _mundo_disponible():
		return
	var mundo := _host._mundo as Node3D
	var eco := mundo.get_node_or_null(EcosSueno3D.NOMBRE) as Node3D
	if eco == null:
		return
	var evento := _pendiente_sueno
	var huella := EventoOnline.huella(evento)
	if EcosSueno3D.aplicar_movimiento_ghost(
		eco,
		evento,
		_scene_revision,
		_anchor_key,
		ahora_unix,
	):
		_vistos[huella] = true
		_pendiente_sueno.clear()


func _asegurar_raiz_ghosts() -> bool:
	if not _mundo_disponible():
		return false
	var mundo := _host._mundo as Node3D
	var id_mundo := mundo.get_instance_id()
	if id_mundo != _mundo_id:
		_limpiar_visuales()
		_mundo_id = id_mundo
	if is_instance_valid(_raiz_ghosts):
		return true
	_raiz_ghosts = Node3D.new()
	_raiz_ghosts.name = NOMBRE_RAIZ
	mundo.add_child(_raiz_ghosts)
	return true


func _limpiar_finalizados() -> void:
	if not is_instance_valid(_raiz_ghosts):
		return
	for hijo in _raiz_ghosts.get_children():
		if hijo.has_method("finalizado") and bool(hijo.call("finalizado")):
			hijo.queue_free()


func _limpiar_visuales() -> void:
	_mundo_id = 0
	if is_instance_valid(_raiz_ghosts):
		if _raiz_ghosts.get_parent() != null:
			_raiz_ghosts.get_parent().remove_child(_raiz_ghosts)
		_raiz_ghosts.queue_free()
	_raiz_ghosts = null


func _mundo_disponible() -> bool:
	if _host == null or not is_instance_valid(_host):
		return false
	var mundo := _host._mundo as Node3D
	return mundo != null and is_instance_valid(mundo)


func _revision_espacio(nombre: String, espacio: Dictionary) -> String:
	var entrada: Vector3 = espacio.get("entrada", Vector3.ZERO)
	var salidas: Array = []
	for salida in espacio.get("salidas", []):
		if typeof(salida) == TYPE_DICTIONARY:
			var pos: Vector3 = salida.get("pos", Vector3.ZERO)
			salidas.append([pos.x, pos.y, pos.z])
	var firma := JSON.stringify(
		{
			"entrada": [entrada.x, entrada.y, entrada.z],
			"salidas": salidas,
			"contorno": String(espacio.get("contorno", [])),
			"planta": String(espacio.get("planta", [])),
		}
	)
	var prefijo := nombre.to_lower().replace("ñ", "n").replace(" ", "-").left(36)
	return "%s-%s" % [prefijo, firma.sha256_text().left(16)]


func _game_build() -> String:
	var version := String(
		ProjectSettings.get_setting("application/config/version", "dev")
	).strip_edges()
	return "dev" if version.is_empty() else version


func _ahora(valor: int) -> int:
	if valor >= 0:
		return valor
	return int(Time.get_unix_time_from_system())
