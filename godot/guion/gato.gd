## El gato.
##
## Es el único ser vivo del juego, y por eso es lo único que NO está hecho de
## cajas: una oficina de cajas es una oficina de 1998, pero un gato de cajas es
## un gato de cajas. Se construye con `MallaOrganica`, que es un tubo a lo
## largo de una espina — un lomo que se estrecha, cuatro patas, dos orejas de
## punta y una cola que se curva. Siete lados por anillo, que sigue siendo la
## misma decisión que las texturas de 64 píxeles.
##
## Lo que lo convierte en un gato tampoco es la malla: es que se mueva como
## uno, y eso lo decide `GatoConducta`. Aquí solo está el bicho y su cola, que
## es lo único que se anima y lo que hace que un bulto parado parezca vivo.
class_name Gato
extends Node3D

const COLOR := Color(0.28, 0.26, 0.25)
const COLOR_CLARO := Color(0.40, 0.38, 0.36)

## Lo alto que es. Un gato mide unos 25 cm a la cruz, y a esa escala se lee
## como un gato al lado de una silla de 45.
const ALTO := 0.26

var estado: Dictionary = {}
var sitios: Array = []

var _cola: Node3D
var _cuerpo: Node3D
var _reloj := 0.0


func _init() -> void:
	_cuerpo = Node3D.new()
	add_child(_cuerpo)

	# El lomo. Más ancho que alto (radio elíptico) y estrechándose por delante:
	# ese perfil es la mitad de lo que se lee como un gato, y no cuesta un
	# triángulo más que un cilindro.
	(
		MallaOrganica
		. pieza(
			_cuerpo,
			(
				MallaOrganica
				. tubo(
					[
						{"c": Vector3(0, 0, 0.22), "r": Vector2(0.055, 0.050)},
						{"c": Vector3(0, 0.01, 0.10), "r": Vector2(0.093, 0.082)},
						{"c": Vector3(0, 0.01, -0.06), "r": Vector2(0.098, 0.086)},
						{"c": Vector3(0, 0, -0.18), "r": Vector2(0.080, 0.072)},
					]
				)
			),
			Vector3(0, ALTO, 0),
			Vector3.ZERO,
			COLOR
		)
	)

	# La cabeza, corta y casi redonda, y el hocico más claro: es lo único que
	# le da cara sin dibujar ojos. El primer anillo coincide con el extremo del
	# lomo para que desde arriba o 3/4 no aparezca una ranura oscura entre ambos.
	(
		MallaOrganica
		. pieza(
			_cuerpo,
			(
				MallaOrganica
				. tubo(
					[
						{"c": Vector3(0, 0, 0.02), "r": Vector2(0.066, 0.062)},
						{"c": Vector3(0, 0, -0.06), "r": Vector2(0.072, 0.068)},
						{"c": Vector3(0, 0, -0.11), "r": Vector2(0.055, 0.050)},
					]
				)
			),
			Vector3(0, ALTO + 0.12, -0.20),
			Vector3.ZERO,
			COLOR
		)
	)
	(
		MallaOrganica
		. pieza(
			_cuerpo,
			(
				MallaOrganica
				. tubo(
					[
						{"c": Vector3(0, 0, 0), "r": 0.030},
						{"c": Vector3(0, 0, -0.05), "r": 0.022},
					]
				)
			),
			Vector3(0, ALTO + 0.09, -0.32),
			Vector3.ZERO,
			COLOR_CLARO
		)
	)

	# Las orejas: un tubo cuyo último radio es cero, que es como se hace una
	# punta. Un triángulo de verdad no se vería distinto y sí sería otra clase.
	for x in [-0.045, 0.045]:
		(
			MallaOrganica
			. pieza(
				_cuerpo,
				(
					MallaOrganica
					. tubo(
						[
							{"c": Vector3(0, 0, 0), "r": Vector2(0.030, 0.014)},
							{"c": Vector3(0, 0, -0.07), "r": 0.0},
						],
						5
					)
				),
				Vector3(x, ALTO + 0.18, -0.25),
				Vector3(PI / 2.0, 0, 0),
				COLOR
			)
		)

	# Cuatro patas, tubos de pie. Las de delante algo más cortas: un gato no es
	# una mesa, y ese centímetro es lo que le da la inclinación del lomo.
	for x in [-0.055, 0.055]:
		for z in [-0.13, 0.14]:
			(
				MallaOrganica
				. pieza(
					_cuerpo,
					(
						MallaOrganica
						. tubo(
							[
								{"c": Vector3(0, 0, 0), "r": 0.026},
								{"c": Vector3(0, 0, -ALTO + 0.02), "r": 0.020},
							],
							5
						)
					),
					Vector3(x, ALTO - 0.02, z),
					Vector3(-PI / 2.0, 0, 0),
					COLOR
				)
			)

	# La cola cuelga de su propio nodo porque es lo único que se mueve.
	_cola = Node3D.new()
	_cola.position = Vector3(0, ALTO + 0.04, 0.20)
	_cuerpo.add_child(_cola)
	(
		MallaOrganica
		. pieza(
			_cola,
			(
				MallaOrganica
				. tubo(
					[
						{"c": Vector3(0, 0, 0), "r": 0.024},
						{"c": Vector3(0, 0.03, 0.10), "r": 0.019},
						{"c": Vector3(0, 0.05, 0.19), "r": 0.013},
					],
					5
				)
			),
			Vector3.ZERO,
			Vector3.ZERO,
			COLOR
		)
	)


## Lo pone en marcha. [param sitios] son los rincones por los que se mueve, y
## el primero es el cuenco: es donde se queda cuando tiene hambre.
func empezar(donde: Vector3, por_donde: Array) -> void:
	sitios = por_donde
	estado = GatoConducta.nuevo(donde)
	position = donde


## Un paso. [param hambre] son los días que lleva sin comer.
func avanzar(hambre: int, jugador: Vector3, delta: float) -> void:
	if estado.is_empty():
		return
	_reloj += delta
	estado = GatoConducta.avanzar(estado, sitios, hambre, jugador, delta)

	var antes := position
	position = estado["pos"]

	# Mira hacia donde anda. El morro del modelo apunta a -Z, así que el yaw
	# necesita media vuelta respecto a la convención habitual (+Z hacia avance).
	# Parado conserva el rumbo: un gato que gira sobre sí mismo al llegar se ve
	# como un error de física, no como un gato.
	var avance := position - antes
	if avance.length() > 0.001:
		_cuerpo.rotation.y = atan2(avance.x, avance.z) + PI

	# La cola. Más deprisa con hambre, que es la otra mitad de la señal: si no
	# viene y además está tensa, algo pasa.
	var ritmo := 3.4 if estado["estado"] == "hambriento" else 1.5
	_cola.rotation.y = sin(_reloj * ritmo) * 0.35
	_cola.rotation.x = sin(_reloj * ritmo * 0.6) * 0.12
