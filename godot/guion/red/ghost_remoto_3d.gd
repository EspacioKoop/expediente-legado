class_name GhostRemoto3D
extends Node3D

## Reproductor visual no sólido para trayectorias históricas (#376).

const GhostDatos = preload("res://guion/red/ghost_datos.gd")

var actor_public_id := ""
var gesture := ""
var _frames: Array = []
var _tiempo := 0.0
var _duracion := 0.0
var _cargado := false


func _init() -> void:
	var cuerpo := MeshInstance3D.new()
	cuerpo.name = "SiluetaGhost"
	var malla := CapsuleMesh.new()
	malla.radius = 0.25
	malla.height = 1.70
	cuerpo.mesh = malla
	cuerpo.position.y = 0.85

	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.72, 0.78, 0.92, 0.26)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cuerpo.material_override = material
	add_child(cuerpo)


func cargar_evento(
	evento: Dictionary,
	scene_revision: String,
	ahora_unix: int,
	anchor_key: String = ""
) -> bool:
	var validacion := GhostDatos.validar_evento(evento, ahora_unix)
	if not validacion["ok"]:
		return false
	var normalizado: Dictionary = validacion["event"]
	var payload: Dictionary = normalizado["payload"]
	if String(payload["scene_revision"]) != scene_revision:
		return false
	if String(payload["space"]) == "anchor" and String(payload["anchor_key"]) != anchor_key:
		return false

	actor_public_id = String(normalizado["actor_public_id"])
	_frames = payload["frames"].duplicate(true)
	_tiempo = 0.0
	_duracion = float(_frames[_frames.size() - 1]["t"])
	_cargado = true
	_aplicar_tiempo(0.0)
	return true


func avanzar(delta: float) -> void:
	if not _cargado or delta <= 0.0:
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
	if _frames.is_empty():
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
		position = pa.lerp(pb, peso)
		rotation.y = lerp_angle(float(a["yaw"]), float(b["yaw"]), peso)
		gesture = String(a["gesture"] if peso < 0.5 else b["gesture"])
		return

	_aplicar_frame(_frames[_frames.size() - 1])


func _aplicar_frame(frame: Dictionary) -> void:
	position = _vector(frame["position"])
	rotation.y = float(frame["yaw"])
	gesture = String(frame["gesture"])


func _vector(datos: Array) -> Vector3:
	return Vector3(float(datos[0]), float(datos[1]), float(datos[2]))
