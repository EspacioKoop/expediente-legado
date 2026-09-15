## Una figura: silueta low-poly sin rostro.
##
## No hay cara, y eso no es una limitación — a quien acusas nunca le ves la
## cara, porque es un comité, una empresa o un cargo. Estaba escrita dentro del
## careo (#61) y sale de ahí al llegar su segundo consumidor: el sueño (#87)
## puebla sus salas con los mismos sospechosos, y dos siluetas distintas para
## la misma persona serían dos personas.
##
## #279 prohíbe que una figura humana final siga siendo una pila de cajas. La
## silueta conserva la abstracción sin rostro, pero ahora usa volúmenes curvos
## low-poly: cinco cápsulas para cuerpo/extremidades y una esfera facetada para
## la cabeza. Sigue siendo geometría procedural, barata y sin asset externo.
class_name FiguraSilueta
extends RefCounted

const ALTO := 1.94
const SEGMENTOS_RADIALES := 8
const ANILLOS := 4


static func altura() -> float:
	return ALTO


static func construir(raiz: Node3D, base: Vector3, color: Color) -> Node3D:
	var figura := Node3D.new()
	figura.position = base
	raiz.add_child(figura)

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0

	# Piernas separadas y ligeramente abiertas: incluso a contraluz la base
	# deja de leerse como un único bloque rectangular.
	_capsula(figura, Vector3(-0.17, 0.45, 0), 0.13, 0.90, Vector3(0.90, 1.0, 0.75), -0.04, material)
	_capsula(figura, Vector3(0.17, 0.45, 0), 0.13, 0.90, Vector3(0.90, 1.0, 0.75), 0.04, material)

	# El torso se ensancha en hombros por escala, no mediante un cubo. Los
	# brazos rompen la simetría mínima para que el contorno no parezca un tótem.
	_capsula(figura, Vector3(0, 1.06, 0), 0.36, 1.10, Vector3(1.12, 1.0, 0.62), 0.0, material)
	_capsula(figura, Vector3(-0.42, 1.05, 0.01), 0.105, 0.82, Vector3(0.90, 1.0, 0.70), 0.15, material)
	_capsula(figura, Vector3(0.42, 1.03, -0.01), 0.105, 0.82, Vector3(0.90, 1.0, 0.70), -0.11, material)

	_esfera(figura, Vector3(0, 1.72, 0), 0.22, Vector3(1.0, 1.0, 0.86), material)
	return figura


static func _capsula(
	padre: Node3D,
	posicion: Vector3,
	radio: float,
	alto: float,
	escala: Vector3,
	giro_z: float,
	material: Material
) -> void:
	var instancia := MeshInstance3D.new()
	var capsula := CapsuleMesh.new()
	capsula.radius = radio
	capsula.height = alto
	capsula.radial_segments = SEGMENTOS_RADIALES
	capsula.rings = ANILLOS
	instancia.mesh = capsula
	instancia.position = posicion
	instancia.scale = escala
	instancia.rotation.z = giro_z
	instancia.material_override = material
	padre.add_child(instancia)


static func _esfera(
	padre: Node3D, posicion: Vector3, radio: float, escala: Vector3, material: Material
) -> void:
	var instancia := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = radio
	esfera.height = radio * 2.0
	esfera.radial_segments = SEGMENTOS_RADIALES
	esfera.rings = ANILLOS
	instancia.mesh = esfera
	instancia.position = posicion
	instancia.scale = escala
	instancia.material_override = material
	padre.add_child(instancia)
