## Señalética y calendario de pared del archivo (#1468).
##
## Láminas propias generadas por `scripts/generar_senaletica_oficina_98.py`.
## Van planas contra el muro y no como billboard: una señal que gira con la
## cámara delata que es un recorte. Sin física ni interacción; idempotente para
## que los reconstruidos de fase no la dupliquen.
class_name SenaleticaOficina98
extends RefCounted

const BASE := "res://assets/texturas/senaletica_oficina_98/"
const NOMBRE_CAPA := "SenaleticaOficina98"

# Huecos libres de pósteres, cuadros, ventanas y puerta. La salida va sobre el
# dintel de la puerta del archivo, como exige cualquier local público.
const LAMINAS := [
	{
		"nombre": "SalidaEmergencia98",
		"archivo": "salida_emergencia_98.png",
		"pos": Vector3(-6.86, 2.54, 3.5),
		"giro": 90.0,
		"alto": 0.20,
	},
	{
		"nombre": "Extintor98",
		"archivo": "extintor_98.png",
		"pos": Vector3(-3.85, 1.85, 4.88),
		"giro": 180.0,
		"alto": 0.26,
	},
	{
		"nombre": "CalendarioPared98",
		"archivo": "calendario_pared_98.png",
		"pos": Vector3(0.55, 1.65, 4.88),
		"giro": 180.0,
		"alto": 0.44,
	},
]


static func montar(mundo: Node3D) -> void:
	if mundo.has_node(NOMBRE_CAPA):
		return
	var capa := Node3D.new()
	capa.name = NOMBRE_CAPA
	mundo.add_child(capa)
	for datos in LAMINAS:
		_montar_lamina(capa, datos)


static func _montar_lamina(capa: Node3D, datos: Dictionary) -> void:
	var textura := load(BASE + String(datos["archivo"])) as Texture2D
	if textura == null:
		push_warning("No se pudo cargar la lámina de pared: %s" % datos["archivo"])
		return
	var lamina := MeshInstance3D.new()
	lamina.name = String(datos["nombre"])
	lamina.position = datos["pos"]
	lamina.rotation_degrees.y = float(datos["giro"])
	var alto := float(datos["alto"])
	var plano := QuadMesh.new()
	plano.size = Vector2(alto * textura.get_width() / textura.get_height(), alto)
	lamina.mesh = plano
	# Cantos redondeados transparentes: recorte por alfa, sin ordenar mezclas.
	var material := StandardMaterial3D.new()
	material.albedo_texture = textura
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.5
	material.roughness = 1.0
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	lamina.material_override = material
	lamina.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lamina.set_meta("senaletica_oficina_98", true)
	capa.add_child(lamina)
