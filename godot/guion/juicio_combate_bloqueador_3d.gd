## Presentación 3D de la guardia del bloqueador onírico (#1771).
class_name JuicioCombateBloqueador3D
extends RefCounted

const FEEDBACK = preload("res://guion/juicio_combate_feedback_3d.gd")


static func montar_guardia(rival: Node3D) -> MeshInstance3D:
	var guardia := MeshInstance3D.new()
	guardia.name = "GuardiaBloqueador"
	var malla := BoxMesh.new()
	malla.size = Vector3(0.95, 1.3, 0.06)
	guardia.mesh = malla
	var material := FEEDBACK.material(Color(0.55, 0.78, 1.0, 0.55), true)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	guardia.material_override = material
	guardia.position = Vector3(0.0, 0.95, 0.45)
	rival.add_child(guardia)
	return guardia
