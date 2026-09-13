## Geometría derivada de `detail-awning-small.glb` del Kenney Retro Urban Kit.
## Fuente oficial: https://kenney.nl/assets/retro-urban-kit
## SHA-256 del GLB fuente: b012c04b39d39a66c7cb45392621d7374f1ff34c6054b4a05bee019abc55b155
## Licencia: CC0-1.0. La malla se representa como código para no saltarse Git LFS
## con un binario nuevo; se eliminan texturas/materiales del pack y SIGA-98 aplica
## su propio shader PSX.
class_name RetroUrbanAwning
extends RefCounted

const VERTICES: Array[Vector3] = [
	Vector3(0.29889694, 0, -0.15000001),
	Vector3(0.29889694, 0.28079078, 0.15000001),
	Vector3(0.29889694, 0, -0.075),
	Vector3(0.29889694, 0.04941725, -0.02055213),
	Vector3(0.29889694, 0.20421149, 0.15000001),
	Vector3(0.29889694, 0, -0.075),
	Vector3(0.29889694, 0.28079078, 0.15000001),
	Vector3(0.29889694, 0, -0.15000001),
	Vector3(0.29889694, 0.04941725, -0.02055213),
	Vector3(0.29889694, 0.20421149, 0.15000001),
	Vector3(-0.29889694, 0, -0.15000001),
	Vector3(-0.29889694, 0.28079078, 0.15000001),
	Vector3(-0.29889694, 0, -0.075),
	Vector3(-0.29889694, 0.04941725, -0.02055213),
	Vector3(-0.29889694, 0.20421149, 0.15000001),
	Vector3(-0.29889694, 0, -0.075),
	Vector3(-0.29889694, 0.28079078, 0.15000001),
	Vector3(-0.29889694, 0, -0.15000001),
	Vector3(-0.29889694, 0.04941725, -0.02055213),
	Vector3(-0.29889694, 0.20421149, 0.15000001),
	Vector3(0.29889694, 0, -0.075),
	Vector3(0.29889694, 0.04941725, -0.02055213),
	Vector3(0.29889694, 0, 0.15000001),
	Vector3(0.29889694, 0.04941725, 0.15000001),
	Vector3(0.29889694, 0, 0.15000001),
	Vector3(0.29889694, 0.04941725, -0.02055213),
	Vector3(0.29889694, 0, -0.075),
	Vector3(0.29889694, 0.04941725, 0.15000001),
	Vector3(-0.29889694, 0, -0.075),
	Vector3(-0.29889694, 0.04941725, -0.02055213),
	Vector3(-0.29889694, 0, 0.15000001),
	Vector3(-0.29889694, 0.04941725, 0.15000001),
	Vector3(-0.29889694, 0, 0.15000001),
	Vector3(-0.29889694, 0.04941725, -0.02055213),
	Vector3(-0.29889694, 0, -0.075),
	Vector3(-0.29889694, 0.04941725, 0.15000001),
	Vector3(0.29889694, 0, -0.15000001),
	Vector3(0.29889694, 0.28079078, 0.15000001),
	Vector3(-0.29889694, 0, -0.15000001),
	Vector3(-0.29889694, 0.28079078, 0.15000001),
	Vector3(-0.29889694, 0, -0.15000001),
	Vector3(0.29889694, 0.28079078, 0.15000001),
	Vector3(0.29889694, 0, -0.15000001),
	Vector3(-0.29889694, 0.28079078, 0.15000001)
]

const TRIANGULOS: Array[Vector3i] = [
	Vector3i(2, 1, 0),
	Vector3i(1, 2, 3),
	Vector3i(1, 3, 4),
	Vector3i(7, 6, 5),
	Vector3i(8, 5, 6),
	Vector3i(9, 8, 6),
	Vector3i(12, 11, 10),
	Vector3i(11, 12, 13),
	Vector3i(11, 13, 14),
	Vector3i(17, 16, 15),
	Vector3i(18, 15, 16),
	Vector3i(19, 18, 16),
	Vector3i(22, 21, 20),
	Vector3i(21, 22, 23),
	Vector3i(26, 25, 24),
	Vector3i(27, 24, 25),
	Vector3i(30, 29, 28),
	Vector3i(29, 30, 31),
	Vector3i(34, 33, 32),
	Vector3i(35, 32, 33),
	Vector3i(38, 37, 36),
	Vector3i(37, 38, 39),
	Vector3i(42, 41, 40),
	Vector3i(43, 40, 41)
]


static func crear(color: Color) -> MeshInstance3D:
	var superficie := SurfaceTool.new()
	superficie.begin(Mesh.PRIMITIVE_TRIANGLES)
	for triangulo in TRIANGULOS:
		for indice in [triangulo.x, triangulo.y, triangulo.z]:
			superficie.add_vertex(VERTICES[indice])
	superficie.generate_normals()

	var instancia := MeshInstance3D.new()
	instancia.mesh = superficie.commit()
	var material := ShaderMaterial.new()
	material.shader = load(Espacio3D.SHADER_PSX)
	material.set_shader_parameter("color_base", color)
	instancia.material_override = material
	return instancia
