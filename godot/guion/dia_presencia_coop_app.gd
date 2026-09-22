class_name DiaPresenciaCoopApp
extends Node

## Cablea #379 al recorrido real sin convertir Dia ni Partida en estado de red.
##
## La sesión es explícitamente opt-in. Mientras no se llame activar_sala(), este
## controller no publica ni consulta nada. Solo opera en `trayecto`: cambiar de
## fase cierra la sala y desmonta las presencias remotas.

const PresenciaDatos = preload("res://guion/red/presencia_datos.gd")
const PresenciaServicio = preload("res://guion/red/presencia_servicio.gd")
const PresenciaRemota3D = preload("res://guion/red/presencia_remota_3d.gd")
const TransporteNulo = preload("res://guion/red/transporte_nulo.gd")

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


func _ready() -> void:
	_host = get_parent()


func _process(delta: float) -> void:
	procesar(delta)


func _exit_tree() -> void:
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
	return resultado


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
