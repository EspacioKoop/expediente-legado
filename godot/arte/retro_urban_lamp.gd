## Geometría derivada de `detail-light-single.glb` del Kenney Retro Urban Kit.
## Fuente oficial: https://kenney.nl/assets/retro-urban-kit
## SHA-256 del GLB fuente: aac24987fa7651f8e892f4e661b3bb67c6866edb726e0ab092e9c747f0a69151
## Licencia: CC0-1.0. La malla se representa como código para no saltarse Git LFS
## con un binario nuevo; se eliminan texturas/materiales del pack y SIGA-98 aplica
## su propio shader PSX.
class_name RetroUrbanLamp
extends RefCounted

const VERTICES: Array[Vector3] = [
	Vector3(0.0231, 0.96000004, -0.0231),
	Vector3(0.0231, 0.95381039, -1.8047785e-16),
	Vector3(-0.0231, 0.96000004, -0.0231),
	Vector3(-0.0231, 0.95381039, -1.8047785e-16),
	Vector3(0.0231, 0.93689996, 0.016910372),
	Vector3(-0.0231, 0.93689996, 0.016910372),
	Vector3(-0.0231, 0.9138, 0.0231),
	Vector3(0.0231, 0.9138, 0.0231),
	Vector3(-0.034649998, 0.96000004, -0.1551),
	Vector3(-0.034649998, 0.96000004, -0.20460001),
	Vector3(-0.0231, 0.96000004, -0.089099996),
	Vector3(1.4438228e-15, 0.96000004, -0.22109999),
	Vector3(-0.0231, 0.96000004, -0.0231),
	Vector3(0.0231, 0.96000004, -0.0231),
	Vector3(0.0231, 0.96000004, -0.089099996),
	Vector3(0.034649998, 0.96000004, -0.1551),
	Vector3(0.034649998, 0.96000004, -0.20460001),
	Vector3(0.034649998, 0.96000004, -0.1551),
	Vector3(0.034649998, 0.9138, -0.1551),
	Vector3(0.0231, 0.96000004, -0.089099996),
	Vector3(0.0231, 0.9138, -0.089099996),
	Vector3(0.034649998, 0.9138, -0.1551),
	Vector3(0.034649998, 0.9138, -0.20460001),
	Vector3(0.0231, 0.9138, -0.089099996),
	Vector3(1.4438228e-15, 0.9138, -0.22109999),
	Vector3(-0.0231, 0.9138, -0.089099996),
	Vector3(-0.034649998, 0.9138, -0.20460001),
	Vector3(-0.034649998, 0.9138, -0.1551),
	Vector3(-0.0231, 0.9138, -0.0231),
	Vector3(0.0231, 0.9138, -0.0231),
	Vector3(0.0231, 0.24455433, 0.0231),
	Vector3(-0.0231, 0.24455433, 0.0231),
	Vector3(0.0231, 0.9138, 0.0231),
	Vector3(-0.0231, 0.9138, 0.0231),
	Vector3(-0.0231, 0.24455433, -0.0231),
	Vector3(0.0231, 0.24455433, -0.0231),
	Vector3(-0.0231, 0.9138, -0.0231),
	Vector3(0.0231, 0.9138, -0.0231),
	Vector3(0.043099999, 0, 0.043099999),
	Vector3(0.043099999, 0, -0.043099999),
	Vector3(-0.043099999, 0, 0.043099999),
	Vector3(-0.043099999, 0, -0.043099999),
	Vector3(0.034649998, 0.96000004, -0.20460001),
	Vector3(0.034649998, 0.9138, -0.20460001),
	Vector3(0.034649998, 0.96000004, -0.1551),
	Vector3(0.034649998, 0.9138, -0.1551),
	Vector3(-0.034649998, 0.9138, -0.20460001),
	Vector3(-0.034649998, 0.96000004, -0.20460001),
	Vector3(-0.034649998, 0.9138, -0.1551),
	Vector3(-0.034649998, 0.96000004, -0.1551),
	Vector3(-0.034649998, 0.9138, -0.1551),
	Vector3(-0.034649998, 0.96000004, -0.1551),
	Vector3(-0.0231, 0.9138, -0.089099996),
	Vector3(-0.0231, 0.96000004, -0.089099996),
	Vector3(-0.034649998, 0.9138, -0.20460001),
	Vector3(1.4438228e-15, 0.9138, -0.22109999),
	Vector3(-0.034649998, 0.96000004, -0.20460001),
	Vector3(1.4438228e-15, 0.96000004, -0.22109999),
	Vector3(1.4438228e-15, 0.9138, -0.22109999),
	Vector3(0.034649998, 0.9138, -0.20460001),
	Vector3(1.4438228e-15, 0.96000004, -0.22109999),
	Vector3(0.034649998, 0.96000004, -0.20460001),
	Vector3(0.0231, 0.96000004, -0.089099996),
	Vector3(0.0231, 0.9138, -0.089099996),
	Vector3(0.0231, 0.96000004, -0.0231),
	Vector3(0.0231, 0.9138, -0.0231),
	Vector3(0.0231, 0.95381039, -1.8047785e-16),
	Vector3(0.0231, 0.24455433, -0.0231),
	Vector3(0.0231, 0.24455433, 0.0231),
	Vector3(0.0231, 0.93689996, 0.016910372),
	Vector3(0.0231, 0.9138, 0.0231),
	Vector3(-0.0231, 0.24455433, -0.0231),
	Vector3(-0.0231, 0.9138, -0.0231),
	Vector3(-0.0231, 0.24455433, 0.0231),
	Vector3(-0.0231, 0.96000004, -0.0231),
	Vector3(-0.0231, 0.96000004, -0.089099996),
	Vector3(-0.0231, 0.9138, -0.089099996),
	Vector3(-0.0231, 0.95381039, -1.8047785e-16),
	Vector3(-0.0231, 0.93689996, 0.016910372),
	Vector3(-0.0231, 0.9138, 0.0231),
	Vector3(-0.043099999, 0, -0.043099999),
	Vector3(0.043099999, 0, -0.043099999),
	Vector3(-0.043099999, 0.24455433, -0.043099999),
	Vector3(0.043099999, 0.24455433, -0.043099999),
	Vector3(-0.043099999, 0, -0.043099999),
	Vector3(-0.043099999, 0.24455433, -0.043099999),
	Vector3(-0.043099999, 0, 0.043099999),
	Vector3(-0.043099999, 0.24455433, 0.043099999),
	Vector3(0.043099999, 0.24455433, -0.043099999),
	Vector3(0.043099999, 0, -0.043099999),
	Vector3(0.043099999, 0.24455433, 0.043099999),
	Vector3(0.043099999, 0, 0.043099999),
	Vector3(0.043099999, 0, 0.043099999),
	Vector3(-0.043099999, 0, 0.043099999),
	Vector3(0.043099999, 0.24455433, 0.043099999),
	Vector3(-0.043099999, 0.24455433, 0.043099999),
	Vector3(-0.0231, 0.24455433, -0.0231),
	Vector3(-0.043099999, 0.24455433, -0.043099999),
	Vector3(0.0231, 0.24455433, -0.0231),
	Vector3(-0.0231, 0.24455433, 0.0231),
	Vector3(0.043099999, 0.24455433, -0.043099999),
	Vector3(-0.043099999, 0.24455433, 0.043099999),
	Vector3(0.043099999, 0.24455433, 0.043099999),
	Vector3(0.0231, 0.24455433, 0.0231),
]

const TRIANGULOS: Array[Vector3i] = [
	Vector3i(2, 1, 0),
	Vector3i(1, 2, 3),
	Vector3i(3, 4, 1),
	Vector3i(4, 3, 5),
	Vector3i(6, 4, 5),
	Vector3i(4, 6, 7),
	Vector3i(10, 9, 8),
	Vector3i(9, 10, 11),
	Vector3i(12, 11, 10),
	Vector3i(13, 11, 12),
	Vector3i(14, 11, 13),
	Vector3i(15, 11, 14),
	Vector3i(11, 15, 16),
	Vector3i(19, 18, 17),
	Vector3i(18, 19, 20),
	Vector3i(23, 22, 21),
	Vector3i(22, 23, 24),
	Vector3i(24, 23, 25),
	Vector3i(24, 25, 26),
	Vector3i(26, 25, 27),
	Vector3i(23, 28, 25),
	Vector3i(28, 23, 29),
	Vector3i(32, 31, 30),
	Vector3i(31, 32, 33),
	Vector3i(36, 35, 34),
	Vector3i(35, 36, 37),
	Vector3i(40, 39, 38),
	Vector3i(39, 40, 41),
	Vector3i(44, 43, 42),
	Vector3i(43, 44, 45),
	Vector3i(48, 47, 46),
	Vector3i(47, 48, 49),
	Vector3i(52, 51, 50),
	Vector3i(51, 52, 53),
	Vector3i(56, 55, 54),
	Vector3i(55, 56, 57),
	Vector3i(60, 59, 58),
	Vector3i(59, 60, 61),
	Vector3i(64, 63, 62),
	Vector3i(63, 64, 65),
	Vector3i(65, 64, 66),
	Vector3i(65, 66, 67),
	Vector3i(67, 66, 68),
	Vector3i(68, 66, 69),
	Vector3i(68, 69, 70),
	Vector3i(73, 72, 71),
	Vector3i(72, 73, 74),
	Vector3i(75, 72, 74),
	Vector3i(72, 75, 76),
	Vector3i(74, 73, 77),
	Vector3i(77, 73, 78),
	Vector3i(78, 73, 79),
	Vector3i(82, 81, 80),
	Vector3i(81, 82, 83),
	Vector3i(86, 85, 84),
	Vector3i(85, 86, 87),
	Vector3i(90, 89, 88),
	Vector3i(89, 90, 91),
	Vector3i(94, 93, 92),
	Vector3i(93, 94, 95),
	Vector3i(98, 97, 96),
	Vector3i(96, 97, 99),
	Vector3i(98, 100, 97),
	Vector3i(101, 99, 97),
	Vector3i(100, 98, 102),
	Vector3i(101, 103, 99),
	Vector3i(102, 103, 101),
	Vector3i(103, 102, 98),
]

static var _malla_compartida: ArrayMesh


static func crear(color: Color) -> MeshInstance3D:
	var instancia := MeshInstance3D.new()
	instancia.mesh = _obtener_malla_compartida()
	# Es dressing de fachada/calle, no un objeto de gameplay: sin colisión y sin pasada
	# de sombras adicional. Cada instancia mantiene un único material/superficie.
	instancia.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = load(Espacio3D.SHADER_PSX)
	material.set_shader_parameter("color_base", color)
	instancia.material_override = material
	return instancia


static func _obtener_malla_compartida() -> ArrayMesh:
	if _malla_compartida != null:
		return _malla_compartida

	var superficie := SurfaceTool.new()
	superficie.begin(Mesh.PRIMITIVE_TRIANGLES)
	for triangulo in TRIANGULOS:
		for indice in [triangulo.x, triangulo.y, triangulo.z]:
			superficie.add_vertex(VERTICES[indice])
	superficie.generate_normals()
	_malla_compartida = superficie.commit()
	return _malla_compartida
