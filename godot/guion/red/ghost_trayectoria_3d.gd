class_name GhostTrayectoria3D
extends Node

## Reproductor de trayectoria desacoplado de la apariencia (#376).
## Puede mover una silueta remota o un NPC onírico ya existente sin navegación,
## física, inputs remotos ni acciones ejecutables.

const GhostDatos = preload("res://guion/red/ghost_datos.gd")

var actor_public_id := ""
var gesture := ""

var _objetivo: Node3D
var _origen := Vector3.ZERO
var _frames: Array = []
var _tiempo := 0.0
var _duracion := 0.0
var _cargado := false


func cargar_evento(
	evento: Dictionary,
	objetivo: Node3D,
	scene_revision: String,
	ahora_unix: int,
	anchor_key: String = "",
	origen: Vector3 = Vector3.ZERO
) -> bool:
	if objetivo == null:
		return false
	var validacion := GhostDatos.validar_evento(evento, ahora_unix)
	if not validacion["ok"]:
		return false
	var normalizado: Dictionary = validacion["event"]
	var payload: Dictionary = normalizado["payload"]
	if String(payload["scene_revision"]) != scene_revision:
		return false
	if String(payload["space"]) == "anchor" and String(payload["anchor_key"]) != anchor_key:
		return false

	_objetivo = objetivo
	_origen = origen
	actor_public_id = String(normalizado["actor_public_id"])
	_frames = payload["frames"].duplicate(true)
	_tiempo = 0.0
	_duracion = float(_frames[_frames.size() - 1]["t"])
	_cargado = true
	_aplicar_tiempo(0.0)
	return true


func avanzar(delta: float) -> void:
	if not _cargado or delta <= 0.0 or not is_instance_valid(_objetivo):
		return
	_tiempo = minf(_tiempo + delta, _duracion)
	_aplicar_tiempo(_tiempo)


func finalizado() -> bool:
	return _cargado and _tiempo >= _duracion


func reiniciar() -> void:
	if not _cargado:
		return
	_tiempo = 0.0
	_aplicar_tiempo(0.0)


func _process(delta: float) -> void:
	avanzar(delta)


func _aplicar_tiempo(t: float) -> void:
	if _frames.is_empty() or not is_instance_valid(_objetivo):
		return
	if t <= float(_frames[0]["t"]):
		_aplicar_frame(_frames[0])
		return

	for i in range(_frames.size() - 1):
		var a: Dictionary = _frames[i]
		var b: Dictionary = _frames[i + 1]
		var ta := float(a["t"])
		var tb := float(b["t"])
		if t > tb:
			continue
		var peso := 0.0 if is_equal_approx(ta, tb) else clampf((t - ta) / (tb - ta), 0.0, 1.0)
		var pa := _vector(a["position"])
		var pb := _vector(b["position"])
		_objetivo.position = _origen + pa.lerp(pb, peso)
		_objetivo.rotation.y = lerp_angle(float(a["yaw"]), float(b["yaw"]), peso)
		gesture = String(a["gesture"] if peso < 0.5 else b["gesture"])
		_objetivo.set_meta("ghost_gesture", gesture)
		return

	_aplicar_frame(_frames[_frames.size() - 1])


func _aplicar_frame(frame: Dictionary) -> void:
	_objetivo.position = _origen + _vector(frame["position"])
	_objetivo.rotation.y = float(frame["yaw"])
	gesture = String(frame["gesture"])
	_objetivo.set_meta("ghost_gesture", gesture)


func _vector(datos: Array) -> Vector3:
	return Vector3(float(datos[0]), float(datos[1]), float(datos[2]))
