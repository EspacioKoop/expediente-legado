## Pieles visuales de material para el trayecto (#399).
##
## No crean colisión ni estado: son capas de superficie sobre la geometría ya
## declarada por EspaciosCatalogo. Así el material puede evolucionar sin
## convertir un cambio visual en un cambio de navegación.
class_name CalleMateriales
extends RefCounted

const FACHADAS := [
	{
		"nombre": "FachadaRevocoOesteSur",
		"pos": Vector3(-5.185, 4.5, -12.65),
		"tam": Vector3(0.025, 9.0, 9.3),
		"color": Color(0.26, 0.25, 0.26),
		"material_pbr": "fachada_edificio",
	},
	{
		"nombre": "FachadaRevocoEsteCentro",
		"pos": Vector3(5.485, 5.0, -10.65),
		"tam": Vector3(0.025, 10.0, 13.3),
		"color": Color(0.26, 0.25, 0.26),
		"material_pbr": "fachada_edificio",
	},
	{
		"nombre": "FachadaRevocoOesteNorte",
		"pos": Vector3(-5.485, 5.5, 10.15),
		"tam": Vector3(0.025, 11.0, 12.3),
		"color": Color(0.26, 0.25, 0.26),
		"material_pbr": "fachada_edificio",
	},
]

## El suelo jugable sigue siendo el rectángulo 9x34 del catálogo. Estas tres
## piezas son solo la piel, a 6 mm por encima: 1.8 m de acera a cada lado y
## 5.4 m de calzada. Si falta el set PBR no se crea la pieza, de modo que un
## checkout sin LFS conserva exactamente el asfalto procedural anterior.
const SUPERFICIES_SUELO := [
	{
		"nombre": "CalzadaPBR",
		"pos": Vector3(0.0, 0.006, 0.0),
		"tam": Vector3(5.4, 0.012, 34.0),
		"material_pbr": "asfalto_urbano",
		"escala": 12.0,
	},
	{
		"nombre": "AceraOestePBR",
		"pos": Vector3(-3.6, 0.006, 0.0),
		"tam": Vector3(1.8, 0.012, 34.0),
		"material_pbr": "acera_barcelona",
		"escala": 14.0,
	},
	{
		"nombre": "AceraEstePBR",
		"pos": Vector3(3.6, 0.006, 0.0),
		"tam": Vector3(1.8, 0.012, 34.0),
		"material_pbr": "acera_barcelona",
		"escala": 14.0,
	},
]


static func montar(mundo: Node3D) -> void:
	for ficha in SUPERFICIES_SUELO:
		var superficie := _superficie_suelo(ficha)
		if superficie != null:
			mundo.add_child(superficie)
	for ficha in FACHADAS:
		mundo.add_child(_fachada(ficha))


static func _superficie_suelo(ficha: Dictionary) -> MeshInstance3D:
	var material := TexturasPBR.crear(
		String(ficha["material_pbr"]), Color.WHITE, float(ficha["escala"]), true
	)
	if material == null:
		return null

	var superficie := MeshInstance3D.new()
	superficie.name = String(ficha["nombre"])
	superficie.position = ficha["pos"]
	var caja := BoxMesh.new()
	caja.size = ficha["tam"]
	superficie.mesh = caja
	superficie.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	superficie.material_override = material
	return superficie


static func _fachada(ficha: Dictionary) -> MeshInstance3D:
	var superficie := MeshInstance3D.new()
	superficie.name = String(ficha["nombre"])
	superficie.position = ficha["pos"]
	var caja := BoxMesh.new()
	caja.size = ficha["tam"]
	superficie.mesh = caja
	superficie.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# El albedo PBR ya lleva su color real: no se multiplica por el gris oscuro
	# que usa la fachada procedural de fallback.
	var material := TexturasPBR.crear(String(ficha["material_pbr"]), Color.WHITE, 4.0, true)
	if material == null:
		material = ShaderMaterial.new()
		material.shader = load(Espacio3D.SHADER_PSX)
		material.set_shader_parameter("color_base", ficha["color"])
		material.set_shader_parameter(
			"textura",
			TexturaProcedural.por_nombre("revoco_urbano", ficha["color"], hash(ficha["nombre"]))
		)
		material.set_shader_parameter("con_textura", true)
		material.set_shader_parameter("escala_textura", 1.8)
	superficie.material_override = material
	return superficie
