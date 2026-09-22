class_name PresenciaRemota3D
extends Node3D

## Representación visual no sólida de otro participante (#379).
## No hereda de PhysicsBody/Area y por tanto no puede bloquear al jugador.

const PresenciaDatos = preload("res://guion/red/presencia_datos.gd")
const INTERPOLACION_POR_SEGUNDO := 10.0

var actor_public_id := ""
var motion := "idle"
var gesture := ""
var _objetivo_pos := Vector3.ZERO
var _objetivo_yaw := 0.0
var _tiene_muestra := false


func _init() -> void:
	var cuerpo := MeshInstance3D.new()
	cuerpo.name = "Silueta"
	var malla := CapsuleMesh.new()
	malla.radius = 0.26
	malla.height = 1.72
	cuerpo.mesh = malla
	cuerpo.position.y = 0.86

	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.65, 0.78, 1.0, 0.34)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cuerpo.material_override = material
	add_child(cuerpo)


func aplicar_evento(evento: Dictionary) -> bool:
	var ahora := int(evento.get("created_at", 0))
	var validacion := PresenciaDatos.validar_evento(evento, ahora)
	if not validacion["ok"]:
		return false
	var normalizado: Dictionary = validacion["event"]
	var payload: Dictionary = normalizado["payload"]
	var p: Array = payload["position"]
	actor_public_id = String(normalizado["actor_public_id"])
	motion = String(payload["motion"])
	gesture = String(payload["gesture"])
	_objetivo_pos = Vector3(float(p[0]), float(p[1]), float(p[2]))
	_objetivo_yaw = float(payload["yaw"])
	if not _tiene_muestra:
		position = _objetivo_pos
		rotation.y = _objetivo_yaw
		_tiene_muestra = true
	return true


func avanzar(delta: float) -> void:
	if not _tiene_muestra or delta <= 0.0:
		return
	var peso := clampf(delta * INTERPOLACION_POR_SEGUNDO, 0.0, 1.0)
	position = position.lerp(_objetivo_pos, peso)
	rotation.y = lerp_angle(rotation.y, _objetivo_yaw, peso)


func _process(delta: float) -> void:
	avanzar(delta)


func estado_visual() -> Dictionary:
	return {
		"actor_public_id": actor_public_id,
		"motion": motion,
		"gesture": gesture,
		"target_position": _objetivo_pos,
		"target_yaw": _objetivo_yaw,
	}
