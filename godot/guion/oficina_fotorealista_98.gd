## Dressing fotorealista 2D para la oficina SIGA-98.
##
## Los cinco recortes se montan como Sprite3D con billboard fijo en Y: conservan
## escala de mundo, reciben la luz del archivo y no añaden física ni interacción.
## La capa es idempotente para que los reconstruidos de fase no dupliquen props.
class_name OficinaFotorealista98
extends RefCounted

const BASE := "res://assets/texturas/oficina_ai_98/"
const NOMBRE_CAPA := "OficinaFotorealista98"

const PROPS := [
	{
		"nombre": "Fotocopiadora98",
		"archivo": "fotocopiadora_98.webp",
		"pos": Vector3(-5.95, 0.73, 0.0),
		"altura": 1.46,
	},
	{
		"nombre": "DispensadorAgua98",
		"archivo": "dispensador_agua_98.webp",
		"pos": Vector3(-5.05, 0.73, 4.15),
		"altura": 1.46,
	},
	{
		"nombre": "Fax98",
		"archivo": "fax_98.webp",
		"pos": Vector3(5.42, 2.02, -1.0),
		"altura": 0.48,
	},
	{
		"nombre": "Grapadora98",
		"archivo": "grapadora_98.webp",
		"pos": Vector3(3.62, 0.88, 0.34),
		"altura": 0.16,
	},
	{
		"nombre": "Perforadora98",
		"archivo": "perforadora_98.webp",
		"pos": Vector3(3.58, 0.90, -0.34),
		"altura": 0.22,
	},
]


static func montar(raiz: Node3D) -> void:
	if raiz.has_node(NOMBRE_CAPA):
		return
	var capa := Node3D.new()
	capa.name = NOMBRE_CAPA
	raiz.add_child(capa)
	for datos in PROPS:
		_agregar_sprite(capa, datos)


static func _agregar_sprite(capa: Node3D, datos: Dictionary) -> void:
	var textura := load(BASE + String(datos["archivo"])) as Texture2D
	if textura == null:
		push_warning("No se pudo cargar prop fotorealista: %s" % datos["archivo"])
		return

	var sprite := Sprite3D.new()
	sprite.name = String(datos["nombre"])
	sprite.texture = textura
	var posicion: Vector3 = datos.get("pos", Vector3.ZERO)
	sprite.position = posicion
	sprite.pixel_size = float(datos.get("altura", 0.5)) / maxf(float(textura.get_height()), 1.0)
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.18
	sprite.shaded = true
	# Un billboard que proyecta sombra depende de la cámara activa; estos props
	# son dressing y no deben introducir sombras inconsistentes entre capturas.
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.set_meta("oficina_ai_98", true)
	capa.add_child(sprite)
