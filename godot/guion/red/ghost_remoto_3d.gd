class_name GhostRemoto3D
extends Node3D

## Representación visual no sólida de una trayectoria histórica (#376).
## El movimiento vive en GhostTrayectoria3D para poder reutilizarlo en NPCs.

const GhostTrayectoria3D = preload("res://guion/red/ghost_trayectoria_3d.gd")

var actor_public_id: String:
	get:
		return _trayectoria.actor_public_id if _trayectoria != null else ""

var gesture: String:
	get:
		return _trayectoria.gesture if _trayectoria != null else ""

var _trayectoria: GhostTrayectoria3D


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

	_trayectoria = GhostTrayectoria3D.new()
	_trayectoria.name = "Trayectoria"
	add_child(_trayectoria)


func cargar_evento(
	evento: Dictionary, scene_revision: String, ahora_unix: int, anchor_key: String = ""
) -> bool:
	return _trayectoria.cargar_evento(
		evento, self, scene_revision, ahora_unix, anchor_key, Vector3.ZERO
	)


func avanzar(delta: float) -> void:
	_trayectoria.avanzar(delta)


func finalizado() -> bool:
	return _trayectoria.finalizado()


func reiniciar() -> void:
	_trayectoria.reiniciar()
