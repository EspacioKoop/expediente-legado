## Gato 2D de escritorio para SIGA (#92, #285).
##
## Dibujo procedural original: no depende de sprites ni de licencias externas.
## Su estado visual deriva del mismo nivel que GatoAyuda; no crea afinidad,
## reglas ni contenido. Las animaciones son deliberadamente pequeñas y se
## congelan por completo cuando `reduccion_movimiento` está activa.
class_name GatoAsistente2D
extends Control

const ANCHO := 132.0
const ALTO := 150.0
const NIVEL_COMPLETO := GatoAyuda.COMPLETA
const NIVEL_ESCASO := GatoAyuda.ESCASA

var _nivel := NIVEL_COMPLETO
var _reduccion_movimiento := false
var _tiempo := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(ANCHO, ALTO)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(not _reduccion_movimiento)
	queue_redraw()


func configurar(nivel: String, reduccion_movimiento: bool) -> void:
	_nivel = nivel
	_reduccion_movimiento = reduccion_movimiento
	set_process(not reduccion_movimiento)
	queue_redraw()


func _process(delta: float) -> void:
	_tiempo = fmod(_tiempo + delta, 8.0)
	queue_redraw()


func _draw() -> void:
	var tinta := Color(0.10, 0.10, 0.12)
	var pelaje := Color(0.82, 0.83, 0.78)
	var sombra := Color(0.45, 0.46, 0.42)
	var interior_oreja := Color(0.62, 0.48, 0.47)
	var ojo := Color(0.03, 0.03, 0.04)
	var cansado := _nivel == NIVEL_ESCASO
	var balanceo := 0.0 if _reduccion_movimiento else sin(_tiempo * 1.8) * 2.2

	# Cola grande detrás del cuerpo: una silueta de gato antes que un icono.
	draw_arc(Vector2(104, 104 + balanceo), 24.0, -1.0, 2.8, 24, tinta, 9.0)
	draw_arc(Vector2(104, 104 + balanceo), 24.0, -1.0, 2.8, 24, sombra, 5.0)

	# Torso sentado y pecho claro. Las patas llegan al borde inferior para que el
	# personaje tenga peso y no parezca una cabeza flotante.
	var cuerpo := PackedVector2Array(
		[
			Vector2(35, 82),
			Vector2(26, 113),
			Vector2(31, 142),
			Vector2(101, 142),
			Vector2(106, 113),
			Vector2(96, 82),
		]
	)
	draw_colored_polygon(cuerpo, pelaje)
	draw_polyline(
		PackedVector2Array(
			[cuerpo[0], cuerpo[1], cuerpo[2], cuerpo[3], cuerpo[4], cuerpo[5], cuerpo[0]]
		),
		tinta,
		3.0
	)
	draw_colored_polygon(
		PackedVector2Array([Vector2(51, 88), Vector2(45, 132), Vector2(87, 132), Vector2(81, 88)]),
		Color(0.90, 0.90, 0.85)
	)
	draw_line(Vector2(51, 137), Vector2(48, 146), tinta, 3.0)
	draw_line(Vector2(81, 137), Vector2(84, 146), tinta, 3.0)

	# Orejas con interior visible y cabeza ligeramente más ancha que el boceto
	# anterior. La asimetría de una oreja baja cuando tiene hambre da estado sin
	# barra ni número.
	var oreja_izq_y := 22.0 + (7.0 if cansado else 0.0)
	draw_colored_polygon(
		PackedVector2Array([Vector2(28, 43), Vector2(22, oreja_izq_y), Vector2(48, 36)]), pelaje
	)
	draw_colored_polygon(
		PackedVector2Array([Vector2(84, 36), Vector2(111, 20), Vector2(104, 45)]), pelaje
	)
	draw_colored_polygon(
		PackedVector2Array([Vector2(30, 38), Vector2(25, oreja_izq_y + 7), Vector2(43, 36)]),
		interior_oreja
	)
	draw_colored_polygon(
		PackedVector2Array([Vector2(90, 35), Vector2(106, 25), Vector2(101, 40)]), interior_oreja
	)
	draw_circle(Vector2(66, 61), 40.0, pelaje)
	draw_arc(Vector2(66, 61), 40.0, 0.0, TAU, 36, tinta, 3.0)

	# Parpadeo corto y determinista. Con reducción de movimiento permanece con
	# los ojos abiertos y no se solicita redraw por frame.
	var parpadea := not _reduccion_movimiento and _tiempo > 3.65 and _tiempo < 3.82
	if parpadea:
		draw_line(Vector2(45, 58), Vector2(55, 58), tinta, 3.0)
		draw_line(Vector2(77, 58), Vector2(87, 58), tinta, 3.0)
	elif cansado:
		draw_arc(Vector2(50, 59), 6.0, 0.15, PI - 0.15, 12, ojo, 3.0)
		draw_arc(Vector2(82, 59), 6.0, 0.15, PI - 0.15, 12, ojo, 3.0)
	else:
		draw_circle(Vector2(50, 58), 4.4, ojo)
		draw_circle(Vector2(82, 58), 4.4, ojo)
		draw_circle(Vector2(51, 57), 1.1, Color(0.88, 0.90, 0.84))
		draw_circle(Vector2(83, 57), 1.1, Color(0.88, 0.90, 0.84))

	# Hocico, boca y bigotes. En estado escaso la boca cae un poco: es expresión,
	# no juicio ni dato nuevo para el jugador.
	draw_colored_polygon(
		PackedVector2Array([Vector2(61, 70), Vector2(71, 70), Vector2(66, 76)]), sombra
	)
	draw_line(Vector2(66, 76), Vector2(66, 81), tinta, 2.0)
	var boca_y := 84.0 if cansado else 81.0
	draw_line(Vector2(66, 81), Vector2(57, boca_y), tinta, 2.0)
	draw_line(Vector2(66, 81), Vector2(75, boca_y), tinta, 2.0)
	for y in [69.0, 76.0, 83.0]:
		draw_line(Vector2(45, y), Vector2(12, y - 5.0), tinta, 2.0)
		draw_line(Vector2(87, y), Vector2(120, y - 5.0), tinta, 2.0)
