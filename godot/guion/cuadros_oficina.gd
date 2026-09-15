## Montaje visible de los cuadros piramidales de #195.
##
## Las imágenes todavía no forman parte de este corte. Cada declaración apunta
## al nombre definitivo que tendrá su lámina y `Cuadros` decide si existe; si
## falta, se conserva una superficie neutra dentro del marco. Así el montaje 3D
## se puede revisar antes de introducir binarios/licencias y el hueco nunca
## desaparece por un asset roto.
class_name CuadrosOficina
extends RefCounted

const ANCHO_MARCO := 0.055
const PROFUNDIDAD_MARCO := 0.045
const COLOR_MARCO := Color(0.22, 0.14, 0.09)

# Huecos que no pisan los seis pósteres de #443, el tablón, las ventanas ni la
# puerta. Los centros quedan a altura de ojo y separados unos centímetros de la
# cara interior del muro para evitar z-fighting.
const CUADROS := [
	{
		"nombre": "Piramide01",
		"pos": Vector3(-6.88, 1.95, -3.00),
		"tam": Vector2(1.10, 0.78),
		"giro": 90.0,
		"textura": "cuadro-piramide-01.png",
	},
	{
		"nombre": "Piramide02",
		"pos": Vector3(-6.88, 1.85, 1.55),
		"tam": Vector2(1.08, 0.76),
		"giro": 90.0,
		"textura": "cuadro-piramide-02.png",
	},
	{
		"nombre": "Piramide03",
		"pos": Vector3(3.25, 1.90, -4.88),
		"tam": Vector2(1.12, 0.80),
		"giro": 0.0,
		"textura": "cuadro-piramide-03.png",
	},
]


static func montar(mundo: Node3D) -> void:
	if mundo.has_node("CuadrosOficina"):
		return
	var conjunto := Node3D.new()
	conjunto.name = "CuadrosOficina"
	mundo.add_child(conjunto)
	for declaracion in CUADROS:
		_montar_cuadro(conjunto, declaracion)


static func _montar_cuadro(raiz: Node3D, declaracion: Dictionary) -> void:
	var datos := Cuadros.materializar(declaracion)
	var soporte := Node3D.new()
	soporte.name = String(declaracion.get("nombre", "Cuadro"))
	soporte.position = datos["pos"]
	soporte.rotation_degrees.y = float(datos["giro"])
	raiz.add_child(soporte)

	var tam: Vector2 = datos["tam"]
	_lamina(soporte, tam, datos)
	_marco(soporte, tam)


static func _lamina(soporte: Node3D, tam: Vector2, datos: Dictionary) -> void:
	var lamina := MeshInstance3D.new()
	lamina.name = "Lamina"
	lamina.position.z = 0.006
	var plano := QuadMesh.new()
	plano.size = tam
	lamina.mesh = plano

	var material := StandardMaterial3D.new()
	material.albedo_color = datos["color_fallback"]
	material.roughness = 1.0
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if bool(datos["usar_textura"]):
		var textura := load(String(datos["ruta_textura"])) as Texture2D
		if textura != null:
			material.albedo_texture = textura
	lamina.material_override = material
	lamina.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	soporte.add_child(lamina)


static func _marco(soporte: Node3D, tam: Vector2) -> void:
	var medio_x := tam.x / 2.0
	var medio_y := tam.y / 2.0
	var medio_marco := ANCHO_MARCO / 2.0
	var largo_horizontal := tam.x + ANCHO_MARCO * 2.0
	var largo_vertical := tam.y

	_barra(
		soporte,
		Vector3(0, medio_y + medio_marco, 0),
		Vector3(largo_horizontal, ANCHO_MARCO, PROFUNDIDAD_MARCO)
	)
	_barra(
		soporte,
		Vector3(0, -medio_y - medio_marco, 0),
		Vector3(largo_horizontal, ANCHO_MARCO, PROFUNDIDAD_MARCO)
	)
	_barra(
		soporte,
		Vector3(-medio_x - medio_marco, 0, 0),
		Vector3(ANCHO_MARCO, largo_vertical, PROFUNDIDAD_MARCO)
	)
	_barra(
		soporte,
		Vector3(medio_x + medio_marco, 0, 0),
		Vector3(ANCHO_MARCO, largo_vertical, PROFUNDIDAD_MARCO)
	)


static func _barra(soporte: Node3D, pos: Vector3, tam: Vector3) -> void:
	var barra := MeshInstance3D.new()
	barra.position = pos
	var caja := BoxMesh.new()
	caja.size = tam
	barra.mesh = caja
	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR_MARCO
	material.roughness = 0.92
	barra.material_override = material
	barra.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	soporte.add_child(barra)
