class_name DiaSenalesMultiplayerApp
extends Node

## Integra #377 en la calle real sin convertir la red en estado de Partida.
##
## Desactivado por defecto. Al activar con un transporte consulta únicamente
## durante `trayecto`, reconstruye texto desde claves locales y coloca las
## señales sobre anchors físicos declarados. Cada anchor puede abrir un
## compositor cerrado: nunca existe un campo de texto libre.

const Interactuable3D = preload("res://guion/interactuable_3d.gd")
const SenalCompositorUI = preload("res://guion/senales/senal_compositor_ui.gd")
const SenalPlayer = preload("res://guion/senales/senal_player.gd")
const SenalServicio = preload("res://guion/red/senal_servicio.gd")
const SenalVocabulario = preload("res://guion/red/senal_vocabulario.gd")
const TransporteNulo = preload("res://guion/red/transporte_nulo.gd")

const FASE := "trayecto"
const SCENE_KEY := "calle"
const NOMBRE_RAIZ := "SenalesMultiplayerCalle"
const INTERVALO_CONSULTA := 1.0
const TAMANO_INTERACCION := Vector3(1.2, 1.8, 1.2)

const POSICIONES_ANCHOR := {
	"calle_escaparate": Vector3(-5.0, 0.15, -1.5),
	"calle_portal": Vector3(0.0, 0.15, 14.9),
}

var _host
var _servicio
var _activa := false
var _conocimiento: Array = []
var _actor_public_id := ""
var _room_id := ""
var _red_status := "local"
var _acumulado := 0.0
var _raiz: Node3D
var _mundo_id := 0
var _players: Dictionary = {}
var _interactuables: Dictionary = {}
var _compositor: SenalCompositorUI


func _ready() -> void:
	_host = get_parent()


func _process(delta: float) -> void:
	procesar(delta)


func _exit_tree() -> void:
	desactivar()


func activar(
	transporte: RefCounted = null,
	conocimiento: Array = [],
	actor_public_id: String = "",
	room_id: String = "",
) -> Dictionary:
	if _host == null or not is_instance_valid(_host):
		return {"ok": false, "status": "dia_no_disponible"}
	if _fase_actual() != FASE:
		return {"ok": false, "status": "fase_no_disponible"}
	var transporte_efectivo := transporte
	if transporte_efectivo == null:
		transporte_efectivo = TransporteNulo.new()
	_servicio = SenalServicio.new(transporte_efectivo)
	_conocimiento = conocimiento.duplicate()
	_actor_public_id = actor_public_id.strip_edges()
	_room_id = room_id.strip_edges()
	_red_status = "local"
	if not _room_id.is_empty():
		if _actor_public_id.is_empty():
			_red_status = "identity_required"
		else:
			var apertura := _servicio.abrir_sala(SCENE_KEY, _room_id, _actor_public_id)
			_red_status = String(apertura.get("status", "transport_error"))
	_activa = true
	_acumulado = INTERVALO_CONSULTA
	if not _asegurar_raiz():
		desactivar()
		return {"ok": false, "status": "mundo_no_disponible"}
	return {"ok": true, "status": "active"}


func desactivar() -> Dictionary:
	_activa = false
	if _servicio != null and not _room_id.is_empty():
		_servicio.cerrar_sala()
	_servicio = null
	_conocimiento.clear()
	_actor_public_id = ""
	_room_id = ""
	_red_status = "local"
	_acumulado = 0.0
	_limpiar_players()
	_retirar_compositor()
	return {"ok": true, "status": "inactive"}


func procesar(delta: float, ahora_unix: int = -1) -> void:
	if not _activa:
		return
	if _servicio != null and not _room_id.is_empty():
		_servicio.procesar_red(delta)
		var salud := _servicio.health()
		_red_status = String(salud.get("status", _red_status))
	if _host == null or not is_instance_valid(_host) or _fase_actual() != FASE:
		desactivar()
		return
	if not _asegurar_raiz():
		return
	_acumulado += maxf(delta, 0.0)
	if _acumulado < INTERVALO_CONSULTA:
		return
	_acumulado = 0.0
	_consultar(ahora_unix)


func publicar_en_anchor(
	actor_public_id: String,
	anchor_id: String,
	plantilla_id: String,
	tokens: Array,
	ahora_unix: int = -1,
	gesto: int = -1,
	event_id: String = "",
) -> Dictionary:
	if not _activa or _servicio == null:
		return {"ok": false, "status": "inactive"}
	if _fase_actual() != FASE:
		return {"ok": false, "status": "fase_no_disponible"}
	if not POSICIONES_ANCHOR.has(anchor_id):
		return {"ok": false, "status": "unknown_anchor"}
	return (
		_servicio
		. publicar(
			SCENE_KEY,
			_game_build(),
			actor_public_id,
			anchor_id,
			plantilla_id,
			tokens,
			ahora_unix,
			_conocimiento,
			gesto,
			event_id,
		)
	)


func abrir_compositor(anchor_id: String) -> Dictionary:
	if not _activa or _servicio == null:
		return {"ok": false, "status": "inactive"}
	if _fase_actual() != FASE:
		return {"ok": false, "status": "fase_no_disponible"}
	if not POSICIONES_ANCHOR.has(anchor_id):
		return {"ok": false, "status": "unknown_anchor"}
	if _actor_public_id.is_empty():
		return {"ok": false, "status": "identity_required"}
	if not _asegurar_compositor():
		return {"ok": false, "status": "ui_no_disponible"}
	return _compositor.abrir(anchor_id, _conocimiento)


func estado() -> Dictionary:
	return {
		"activa": _activa,
		"fase": _fase_actual(),
		"visibles": _players.size(),
		"anchors": POSICIONES_ANCHOR.keys(),
		"anchors_interactivos": _interactuables.size(),
		"actor_configurado": not _actor_public_id.is_empty(),
		"room_id": _room_id,
		"red_status": _red_status,
		"compositor_abierto": _compositor != null and _compositor.estado()["abierto"],
	}


func _consultar(ahora_unix: int) -> void:
	if _servicio == null:
		return
	var consulta: Dictionary = _servicio.consultar(SCENE_KEY, _conocimiento, ahora_unix)
	if not bool(consulta.get("ok", false)):
		return

	var por_anchor: Dictionary = {}
	for evento in consulta.get("signals", []):
		if typeof(evento) != TYPE_DICTIONARY:
			continue
		var payload: Dictionary = evento.get("payload", {})
		var anchor_id := String(payload.get("anchor_id", ""))
		if not POSICIONES_ANCHOR.has(anchor_id):
			continue
		var anterior: Dictionary = por_anchor.get(anchor_id, {})
		if (
			anterior.is_empty()
			or int(evento.get("created_at", 0)) >= int(anterior.get("created_at", 0))
		):
			por_anchor[anchor_id] = evento

	for anchor_id in POSICIONES_ANCHOR:
		if por_anchor.has(anchor_id):
			_mostrar(String(anchor_id), por_anchor[anchor_id], ahora_unix)
		elif _players.has(anchor_id):
			var player = _players[anchor_id]
			if player != null and is_instance_valid(player):
				player.ocultar()


func _mostrar(anchor_id: String, evento: Dictionary, ahora_unix: int) -> void:
	if _raiz == null:
		return
	var player: SenalPlayer
	if _players.has(anchor_id) and is_instance_valid(_players[anchor_id]):
		player = _players[anchor_id]
	else:
		player = SenalPlayer.new()
		player.name = "Senal_%s" % anchor_id
		player.position = POSICIONES_ANCHOR[anchor_id]
		_raiz.add_child(player)
		_players[anchor_id] = player
	player.mostrar_evento(evento, _conocimiento, ahora_unix)


func _asegurar_raiz() -> bool:
	if _host == null or not is_instance_valid(_host):
		return false
	var mundo := _host._mundo as Node3D
	if mundo == null or not is_instance_valid(mundo):
		return false
	var nuevo_id := mundo.get_instance_id()
	if nuevo_id == _mundo_id and is_instance_valid(_raiz):
		return true
	_limpiar_players()
	_mundo_id = nuevo_id
	_raiz = Node3D.new()
	_raiz.name = NOMBRE_RAIZ
	mundo.add_child(_raiz)
	_montar_interactuables()
	return true


func _montar_interactuables() -> void:
	_interactuables.clear()
	if _raiz == null:
		return
	for anchor_id in POSICIONES_ANCHOR:
		var interactuable := Interactuable3D.new()
		interactuable.name = "CrearSenal_%s" % String(anchor_id)
		interactuable.position = POSICIONES_ANCHOR[anchor_id] + Vector3(0.0, 0.9, 0.0)
		interactuable.verbo = Interactuable3D.Verbo.USAR
		interactuable.nombre_objeto = ""
		interactuable.sonido = Interactuable3D.SIN_SONIDO
		interactuable.collision_mask = 0

		var colision := CollisionShape3D.new()
		colision.name = "Colision"
		var forma := BoxShape3D.new()
		forma.size = TAMANO_INTERACCION
		colision.shape = forma
		interactuable.add_child(colision)
		interactuable.activado.connect(_al_activar_anchor.bind(String(anchor_id)))
		_raiz.add_child(interactuable)
		_interactuables[anchor_id] = interactuable


func _al_activar_anchor(_actor: Node, anchor_id: String) -> void:
	abrir_compositor(anchor_id)


func _asegurar_compositor() -> bool:
	if _host == null or not is_instance_valid(_host):
		return false
	if _compositor != null and is_instance_valid(_compositor):
		return true
	_compositor = SenalCompositorUI.new()
	_compositor.name = "SenalCompositorUI"
	_compositor.publicar_solicitada.connect(_al_publicar_desde_compositor)
	_host.add_child(_compositor)
	return true


func _al_publicar_desde_compositor(anchor_id: String, plantilla_id: String, tokens: Array) -> void:
	if _compositor == null or not is_instance_valid(_compositor):
		return
	var resultado := publicar_en_anchor(
		_actor_public_id,
		anchor_id,
		plantilla_id,
		tokens,
	)
	_compositor.resolver_publicacion(resultado)


func _limpiar_players() -> void:
	_players.clear()
	_interactuables.clear()
	_mundo_id = 0
	if is_instance_valid(_raiz):
		if _raiz.get_parent() != null:
			_raiz.get_parent().remove_child(_raiz)
		_raiz.queue_free()
	_raiz = null


func _retirar_compositor() -> void:
	if not is_instance_valid(_compositor):
		_compositor = null
		return
	_compositor.cerrar()
	if _compositor.get_parent() != null:
		_compositor.get_parent().remove_child(_compositor)
	_compositor.queue_free()
	_compositor = null


func _fase_actual() -> String:
	if _host == null or not is_instance_valid(_host):
		return ""
	if typeof(_host.jornada) != TYPE_DICTIONARY:
		return ""
	return String(_host.jornada.get("fase", "")).strip_edges()


func _game_build() -> String:
	var version := (
		String(ProjectSettings.get_setting("application/config/version", "dev")).strip_edges()
	)
	return "dev" if version.is_empty() else version
