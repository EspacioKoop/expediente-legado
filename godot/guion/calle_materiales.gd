## Pieles visuales de material para las masas de fachada del trayecto (#399).
##
## No crean colisión ni estado: son una capa de superficie sobre los volúmenes
## ya declarados por EspaciosCatalogo. Así el material puede evolucionar sin
## convertir un cambio visual en un cambio de navegación.
class_name CalleMateriales
extends RefCounted

const FACHADAS := [
	{
		"nombre": "FachadaRevocoOesteSur",
		"pos": Vector3(-5.185, 4.5, -12.65),
		"tam": Vector3(0.025, 9.0, 9.3),
		"color": Color(0.26, 0.25, 0.26),
	},
	{
		"nombre": "FachadaRevocoEsteCentro",
		"pos": Vector3(5.485, 5.0, -10.65),
		"tam": Vector3(0.025, 10.0, 13.3),
		"color": Color(0.26, 0.25, 0.26),
	},
	{
		"nombre": "FachadaRevocoOesteNorte",
		"pos": Vector3(-5.485, 5.5, 10.15),
		"tam": Vector3(0.025, 11.0, 12.3),
		"color": Color(0.26, 0.25, 0.26),
	},
]


static func montar(mundo: Node3D) -> void:
	for ficha in FACHADAS:
		mundo.add_child(_fachada(ficha))


static func _fachada(ficha: Dictionary) -> MeshInstance3D:
	var superficie := MeshInstance3D.new()
	superficie.name = String(ficha["nombre"])
	superficie.position = ficha["pos"]
	var caja := BoxMesh.new()
	caja.size = ficha["tam"]
	superficie.mesh = caja
	superficie.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var material := ShaderMaterial.new()
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
