## Pieles visuales de material para el trayecto (#399).
##
## No crean colisión ni estado: son capas de superficie sobre la geometría ya
## declarada por EspaciosCatalogo. Así el material puede evolucionar sin
## convertir un cambio visual en un cambio de navegación.
class_name CalleMateriales
extends RefCounted

## La piel no puede rozar la cara arquitectónica: con 2,5 mm de separación el
## depth buffer alternaba ambas superficies al mover la cámara (#563). Dejamos
## 2 cm libres antes de empezar el volumen visual, sin tocar colisiones.
const SEPARACION_FACHADA := 0.02
const GROSOR_PIEL_FACHADA := 0.025

const FACHADAS := [
	{
		"nombre": "FachadaRevocoOesteSur",
		"cara_x": CalleIdentidad.CARA_OESTE_SUR,
		"hacia_calle": 1.0,
		"pos": Vector3(0.0, 4.5, -12.65),
		"tam": Vector3(GROSOR_PIEL_FACHADA, 9.0, 9.3),
		"color": Color(0.26, 0.25, 0.26),
		"material_pbr": "fachada_edificio",
	},
	{
		"nombre": "FachadaRevocoEsteCentro",
		"cara_x": CalleIdentidad.CARA_ESTE_SUR,
		"hacia_calle": -1.0,
		"pos": Vector3(0.0, 5.0, -10.65),
		"tam": Vector3(GROSOR_PIEL_FACHADA, 10.0, 13.3),
		"color": Color(0.26, 0.25, 0.26),
		"material_pbr": "fachada_edificio",
	},
	{
		"nombre": "FachadaRevocoOesteNorte",
		"cara_x": CalleIdentidad.CARA_OESTE_NORTE,
		"hacia_calle": 1.0,
		"pos": Vector3(0.0, 5.5, 10.15),
		"tam": Vector3(GROSOR_PIEL_FACHADA, 11.0, 12.3),
		"color": Color(0.26, 0.25, 0.26),
		"material_pbr": "fachada_edificio",
	},
]

## El suelo jugable sigue siendo el rectángulo 9x34 del catálogo. Estas tres
## piezas son solo la piel, a 6 mm por encima: 1.8 m de acera a cada lado y
## 5.4 m de calzada. Los sets PBR mandan cuando existen; sin LFS se conserva
## la misma separación visual mediante fallbacks procedurales, sin colisión.
const SUPERFICIES_SUELO := [
	{
		"nombre": "CalzadaMaterial",
		"pos": Vector3(0.0, 0.006, 0.0),
		"tam": Vector3(5.4, 0.012, 34.0),
		"material_pbr": "asfalto_urbano",
		"escala": 12.0,
		"fallback_textura": "asfalto",
		"fallback_color": Color(0.20, 0.20, 0.21),
		"fallback_metros": 1.2,
	},
	{
		"nombre": "AceraOesteMaterial",
		"pos": Vector3(-3.6, 0.006, 0.0),
		"tam": Vector3(1.8, 0.012, 34.0),
		"material_pbr": "acera_barcelona",
		"escala": 14.0,
		"fallback_textura": "loseta_acera",
		"fallback_color": Color(0.46, 0.45, 0.42),
		"fallback_metros": 0.8,
	},
	{
		"nombre": "AceraEsteMaterial",
		"pos": Vector3(3.6, 0.006, 0.0),
		"tam": Vector3(1.8, 0.012, 34.0),
		"material_pbr": "acera_barcelona",
		"escala": 14.0,
		"fallback_textura": "loseta_acera",
		"fallback_color": Color(0.46, 0.45, 0.42),
		"fallback_metros": 0.8,
	},
]


static func montar(mundo: Node3D) -> void:
	for ficha in SUPERFICIES_SUELO:
		mundo.add_child(_superficie_suelo(ficha))
	for ficha in FACHADAS:
		mundo.add_child(_fachada(ficha))


static func _superficie_suelo(ficha: Dictionary) -> MeshInstance3D:
	var material := TexturasPBR.crear(
		String(ficha["material_pbr"]), Color.WHITE, float(ficha["escala"]), true
	)
	if material == null:
		material = _material_fallback_suelo(ficha)

	var superficie := MeshInstance3D.new()
	superficie.name = String(ficha["nombre"])
	superficie.position = ficha["pos"]
	var caja := BoxMesh.new()
	caja.size = ficha["tam"]
	superficie.mesh = caja
	superficie.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	superficie.material_override = material
	return superficie


static func _material_fallback_suelo(ficha: Dictionary) -> ShaderMaterial:
	var color: Color = ficha["fallback_color"]
	var textura := String(ficha["fallback_textura"])
	var material := ShaderMaterial.new()
	material.shader = load(Espacio3D.SHADER_PSX)
	material.set_shader_parameter("color_base", color)
	material.set_shader_parameter(
		"textura", TexturaProcedural.por_nombre(textura, color, hash(ficha["nombre"]))
	)
	material.set_shader_parameter("con_textura", true)
	material.set_shader_parameter("escala_textura", 1.0 / float(ficha["fallback_metros"]))
	return material


static func _fachada(ficha: Dictionary) -> MeshInstance3D:
	var superficie := MeshInstance3D.new()
	superficie.name = String(ficha["nombre"])
	var tam: Vector3 = ficha["tam"]
	var posicion: Vector3 = ficha["pos"]
	posicion.x = (
		float(ficha["cara_x"]) + float(ficha["hacia_calle"]) * (SEPARACION_FACHADA + tam.x * 0.5)
	)
	superficie.position = posicion
	var caja := BoxMesh.new()
	caja.size = tam
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
