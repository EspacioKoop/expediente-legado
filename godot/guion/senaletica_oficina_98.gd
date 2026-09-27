## Señalética administrativa propia para la oficina (#1468).
##
## Son tres SVG de autoría del proyecto, reproducibles por script y sin texto.
## Se montan como planos fijos: no son billboards, no tienen colisión y no
## introducen interacción ni información de gameplay.
class_name SenaleticaOficina98
extends RefCounted

const ELEMENTOS := [
	{
		"nombre": "SalidaEmergencia",
		"ruta": "res://arte/oficina_1468/salida_emergencia.svg",
		"pos": Vector3(-6.82, 2.62, 3.50),
		"giro": 90.0,
		"alto": 0.42,
	},
	{
		"nombre": "Extintor",
		"ruta": "res://arte/oficina_1468/extintor.svg",
		"pos": Vector3(5.85, 1.72, 4.86),
		"giro": 180.0,
		"alto": 0.72,
	},
	{
		"nombre": "Calendario",
		"ruta": "res://arte/oficina_1468/calendario.svg",
		"pos": Vector3(4.35, 1.68, -4.86),
		"giro": 0.0,
		"alto": 0.88,
	},
]


static func montar(mundo: Node3D) -> Node3D:
	var existente := mundo.get_node_or_null("SenaleticaOficina98")
	if existente is Node3D:
		return existente

	var conjunto := Node3D.new()
	conjunto.name = "SenaleticaOficina98"
	mundo.add_child(conjunto)

	for datos in ELEMENTOS:
		_agregar_lamina(conjunto, datos)
	return conjunto


static func _agregar_lamina(raiz: Node3D, datos: Dictionary) -> void:
	var textura := load(String(datos["ruta"])) as Texture2D
	if textura == null:
		push_error("No se pudo cargar señalética: %s" % String(datos["ruta"]))
		return

	var lamina := MeshInstance3D.new()
	lamina.name = String(datos["nombre"])
	lamina.position = datos["pos"]
	lamina.rotation_degrees.y = float(datos["giro"])

	var plano := QuadMesh.new()
	var alto := float(datos["alto"])
	plano.size = Vector2(alto * textura.get_width() / textura.get_height(), alto)
	lamina.mesh = plano

	var material := StandardMaterial3D.new()
	material.albedo_texture = textura
	material.roughness = 0.92
	material.texture_filter = (
		BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	)
	lamina.material_override = material
	lamina.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	raiz.add_child(lamina)
