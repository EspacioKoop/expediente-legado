class_name DiaSenalesMultiplayerApp
extends Node

## Integra #377 en la calle real sin convertir la red en estado de Partida.
##
## Desactivado por defecto. Al activar con un transporte (fixture o futuro
## backend) consulta únicamente durante `trayecto`, reconstruye texto desde
## claves locales y coloca las señales sobre anchors físicos declarados.

const SenalPlayer = preload("res://guion/senales/senal_player.gd")
const SenalServicio = preload("res://guion/red/senal_servicio.gd")
const SenalVocabulario = preload("res://guion/red/senal_vocabulario.gd")
const TransporteNulo = preload("res://guion/red/transporte_nulo.gd")

const FASE := "trayecto"
const SCENE_KEY := "calle"
const NOMBRE_RAIZ := "SenalesMultiplayerCalle"
const INTERVALO_CONSULTA := 1.0

const POSICIONES_ANCHOR := {
	"calle_escaparate": Vector3(-5.0, 0.15, -1.5),
	"calle_portal": Vector3(0.0, 0.15, 14.9),
}

var _host
var _servicio
var _activa := false
var _conocimiento: Array = []
var _acumulado := 0.0
var _raiz: Node3D
var _mundo_id := 0
var _players: Dictionary = {}


func _ready() -> void:
	_host = get_parent()


func _process(delta: float) -> void:
	procesar(delta)


func _exit_tree() -> void:
	desactivar()


func activar(transporte: RefCounted = null, conocimiento: Array = []) -> Dictionary:
	if _host == null or not is_instance_valid(_host):
		return {"ok": false, "status": "dia_no_disponible"}
	if _fase_actual() != FASE:
		return {"ok": false, "status": "fase_no_disponible"}
	var transporte_efectivo := transporte
	if transporte_efectivo == null:
		transporte_efectivo = TransporteNulo.new()
	_servicio = SenalServicio.new(transporte_efectivo)
	_conocimiento = conocimiento.duplicate()
	_activa = true
	_acumulado = INTERVALO_CONSULTA
	if not _asegurar_raiz():
		desactivar()
		return {"ok": false, "status": "mundo_no_disponible"}
	return {"ok": true, "status": "active"}


func desactivar() -> Dictionary:
	_activa = false
	_servicio = null
	_conocimiento.clear()
	_acumulado = 0.0
	_limpiar_players()
	return {"ok": true, "status": "inactive"}


func procesar(delta: float, ahora_unix: int = -1) -> void:
	if not _activa:
		return
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
	return _servicio.publicar(
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


func estado() -> Dictionary:
	return {
		"activa": _activa,
		"fase": _fase_actual(),
		"visibles": _players.size(),
		"anchors": POSICIONES_ANCHOR.keys(),
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
		if anterior.is_empty() or int(evento.get("created_at", 0)) >= int(anterior.get("created_at", 0)):
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
	return true


func _limpiar_players() -> void:
	_players.clear()
	_mundo_id = 0
	if is_instance_valid(_raiz):
		if _raiz.get_parent() != null:
			_raiz.get_parent().remove_child(_raiz)
		_raiz.queue_free()
	_raiz = null


func _fase_actual() -> String:
	if _host == null or not is_instance_valid(_host):
		return ""
	if typeof(_host.jornada) != TYPE_DICTIONARY:
		return ""
	return String(_host.jornada.get("fase", "")).strip_edges()


func _game_build() -> String:
	var version := String(ProjectSettings.get_setting("application/config/version", "dev")).strip_edges()
	return "dev" if version.is_empty() else version
