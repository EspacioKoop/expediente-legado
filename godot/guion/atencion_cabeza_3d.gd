## Giro aditivo de cuello/cabeza para la atención selectiva de compañeros (#134).
##
## SkeletonModifier3D se evalúa después de AnimationPlayer: así el gesto se suma
## a idle/UAL/Rocketbox sin reescribir pistas ni competir con teléfono, sentado
## o conversación. Quien lo usa decide el ángulo y cuándo debe ser cero.
class_name AtencionCabeza3D
extends SkeletonModifier3D

const PESO_CUELLO := 0.35
const PESO_CABEZA := 0.65

var giro := 0.0


func _process_modification_with_delta(_delta: float) -> void:
	if is_zero_approx(giro):
		return
	var esqueleto := get_skeleton()
	if esqueleto == null:
		return
	_girar(esqueleto, "Neck", giro * PESO_CUELLO)
	_girar(esqueleto, "Head", giro * PESO_CABEZA)


func _girar(esqueleto: Skeleton3D, nombre: String, angulo: float) -> void:
	var hueso := esqueleto.find_bone(nombre)
	if hueso < 0:
		return
	var pose := esqueleto.get_bone_pose_rotation(hueso)
	esqueleto.set_bone_pose_rotation(hueso, pose * Quaternion(Vector3.UP, angulo))
