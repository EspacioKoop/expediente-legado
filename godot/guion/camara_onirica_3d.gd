## Cámara física adquirible dentro del sueño (#140).
##
## Es un objeto de mundo, no la autoridad de grabación. Recogerlo solo emite la
## interacción normal de Interactuable3D; el controller dueño decide si debe
## crear la cinta canónica de GrabacionOniricaEstado.
class_name CamaraOnirica3D
extends Interactuable3D

const TAM_CUERPO := Vector3(0.46, 0.28, 0.22)
const TAM_COLISION := Vector3(0.62, 0.42, 0.42)


func _ready() -> void:
	verbo = Verbo.COGER
	nombre_objeto = "cámara"
	_montar_colision()
	_montar_visual()


func _montar_colision() -> void:
	if get_node_or_null("Colision") != null:
		return
	var colision := CollisionShape3D.new()
	colision.name = "Colision"
	var forma := BoxShape3D.new()
	forma.size = TAM_COLISION
	colision.shape = forma
	add_child(colision)


func _montar_visual() -> void:
	if get_node_or_null("Cuerpo") != null:
		return

	var cuerpo := MeshInstance3D.new()
	cuerpo.name = "Cuerpo"
	var caja := BoxMesh.new()
	caja.size = TAM_CUERPO
	cuerpo.mesh = caja
	cuerpo.material_override = _material(Color(0.12, 0.13, 0.15))
	add_child(cuerpo)

	var lente := MeshInstance3D.new()
	lente.name = "Lente"
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = 0.095
	cilindro.bottom_radius = 0.11
	cilindro.height = 0.16
	lente.mesh = cilindro
	lente.rotation_degrees.x = 90.0
	lente.position = Vector3(0.0, 0.0, -0.18)
	lente.material_override = _material(Color(0.035, 0.045, 0.055))
	add_child(lente)

	var ocular := MeshInstance3D.new()
	ocular.name = "Ocular"
	var ocular_malla := BoxMesh.new()
	ocular_malla.size = Vector3(0.14, 0.10, 0.12)
	ocular.mesh = ocular_malla
	ocular.position = Vector3(0.14, 0.10, 0.08)
	ocular.material_override = _material(Color(0.08, 0.09, 0.10))
	add_child(ocular)

	var asa := MeshInstance3D.new()
	asa.name = "Asa"
	var asa_malla := BoxMesh.new()
	asa_malla.size = Vector3(0.30, 0.055, 0.08)
	asa.mesh = asa_malla
	asa.position = Vector3(0.0, 0.19, 0.02)
	asa.material_override = _material(Color(0.18, 0.19, 0.20))
	add_child(asa)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	material.metallic = 0.12
	return material
