## Fondos fotorealistas ligeros para cerrar los huecos centrales de la calle.
##
## Son impostores 2D sin colisión situados detrás de las fachadas jugables. No
## sustituyen el skyline CC0: añaden una línea intermedia precisamente donde el
## centro izquierda/derecha deja ver huecos demasiado limpios entre edificios.
class_name CalleFondosFotorealistas98
extends RefCounted

const BASE := "res://assets/texturas/calle_ai_98/"
const NOMBRE_CAPA := "FondosFotorealistas98"

const BLOQUES := [
	{
		"nombre": "BloqueOesteSur98",
		"archivo": "bloque_01.webp",
		"pos": Vector3(-10.5, 0.0, -3.8),
		"altura": 10.2,
		"giro_y": 90.0,
	},
	{
		"nombre": "BloqueOesteNorte98",
		"archivo": "bloque_03.webp",
		"pos": Vector3(-12.3, 0.0, 1.4),
		"altura": 11.4,
		"giro_y": 90.0,
	},
	{
		"nombre": "BloqueEsteSur98",
		"archivo": "bloque_02.webp",
		"pos": Vector3(10.7, 0.0, -2.2),
		"altura": 10.8,
		"giro_y": -90.0,
	},
	{
		"nombre": "BloqueEsteNorte98",
		"archivo": "bloque_04.webp",
		"pos": Vector3(12.3, 0.0, 2.8),
		"altura": 11.2,
		"giro_y": -90.0,
	},
]


static func montar(mundo: Node3D) -> void:
	if mundo == null or mundo.has_node(NOMBRE_CAPA):
		return
	var capa := Node3D.new()
	capa.name = NOMBRE_CAPA
	mundo.add_child(capa)
	for datos in BLOQUES:
		_agregar_bloque(capa, datos)


static func _agregar_bloque(capa: Node3D, datos: Dictionary) -> void:
	var textura := load(BASE + String(datos.get("archivo", ""))) as Texture2D
	if textura == null:
		push_warning("No se pudo cargar fondo fotorealista: %s" % datos.get("archivo", "?"))
		return

	var altura := float(datos.get("altura", 10.0))
	var base: Vector3 = datos.get("pos", Vector3.ZERO)
	var sprite := Sprite3D.new()
	sprite.name = String(datos.get("nombre", "BloqueFondo98"))
	sprite.texture = textura
	sprite.position = base + Vector3(0.0, altura * 0.5, 0.0)
	sprite.rotation_degrees.y = float(datos.get("giro_y", 0.0))
	sprite.pixel_size = altura / maxf(float(textura.get_height()), 1.0)
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.18
	sprite.shaded = true
	sprite.double_sided = false
	sprite.fixed_size = false
	sprite.no_depth_test = false
	sprite.modulate = Color(0.72, 0.74, 0.78, 1.0)
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.set_meta("calle_ai_98", true)
	capa.add_child(sprite)
