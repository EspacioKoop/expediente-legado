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
## uno, y eso lo decide `GatoConducta`. Aquí está el bicho, su colisión y las
## animaciones observables; hambre y afinidad siguen fuera de esta clase.
class_name Gato
extends CharacterBody3D

const COLOR := Color(0.30, 0.27, 0.25)
const COLOR_CLARO := Color(0.62, 0.58, 0.53)
const COLOR_OJO := Color(0.78, 0.62, 0.18)
const COLOR_PUPILA := Color(0.05, 0.05, 0.05)
const COLOR_NARIZ := Color(0.55, 0.36, 0.36)

## Lo alto que es. Un gato mide unos 25 cm a la cruz, y a esa escala se lee
## como un gato al lado de una silla de 45.
const ALTO := 0.26

## Cuando un mueble corta la línea recta al destino, durante un instante bordea
## el obstáculo por el lateral que más lo acerca al destino. No es navegación:
## es suficiente para que una cama o una mesa no conviertan el paseo en un
## teletransporte a través de la caja ni en quedarse empotrado para siempre.
const DURACION_DESVIO := 1.1

## Todo lo que tiene dentro el gato cabe en un solo lado: las piezas se
## describen en el sistema del cuerpo, con el morro hacia -Z y el suelo en 0.
const LOMO := [
	{"c": Vector3(0, 0.182, 0.222), "r": Vector2(0.022, 0.024)},
	{"c": Vector3(0, 0.182, 0.200), "r": Vector2(0.055, 0.058)},
	{"c": Vector3(0, 0.185, 0.150), "r": Vector2(0.078, 0.080)},
	{"c": Vector3(0, 0.180, 0.060), "r": Vector2(0.080, 0.078)},
	{"c": Vector3(0, 0.185, -0.040), "r": Vector2(0.072, 0.076)},
	{"c": Vector3(0, 0.200, -0.120), "r": Vector2(0.066, 0.078)},
	{"c": Vector3(0, 0.235, -0.175), "r": Vector2(0.050, 0.060)},
	{"c": Vector3(0, 0.270, -0.200), "r": Vector2(0.040, 0.042)},
]

## La cabeza es ancha y corta: lo contrario de un perro. Los carrillos son el
## anillo más ancho y el morro casi no sobresale.
const CABEZA := [
	{"c": Vector3(0, 0.290, -0.175), "r": Vector2(0.040, 0.040)},
	{"c": Vector3(0, 0.292, -0.205), "r": Vector2(0.068, 0.060)},
	{"c": Vector3(0, 0.285, -0.245), "r": Vector2(0.072, 0.058)},
	{"c": Vector3(0, 0.280, -0.275), "r": Vector2(0.056, 0.046)},
	{"c": Vector3(0, 0.276, -0.292), "r": Vector2(0.030, 0.026)},
]

## El hocico claro que va debajo de la nariz, y el pecho, que es lo único
## claro que se ve desde la altura del jugador.
const HOCICO := [
	{"c": Vector3(0, 0.262, -0.255), "r": Vector2(0.034, 0.024)},
	{"c": Vector3(0, 0.258, -0.290), "r": Vector2(0.026, 0.019)},
	{"c": Vector3(0, 0.260, -0.302), "r": Vector2(0.010, 0.008)},
]
const PECHO := [
	{"c": Vector3(0, 0.175, -0.080), "r": Vector2(0.040, 0.050)},
	{"c": Vector3(0, 0.200, -0.150), "r": Vector2(0.046, 0.055)},
	{"c": Vector3(0, 0.240, -0.185), "r": Vector2(0.030, 0.036)},
]

var estado: Dictionary = {}
var sitios: Array = []

var _cola: Node3D
var _cuerpo: Node3D
var _cabeza: Node3D
var _colision: CollisionShape3D
var _orejas: Array[Node3D] = []
var _reloj := 0.0
var _desvio := Vector3.ZERO
var _desvio_resto := 0.0


func _init() -> void:
	# El gato consulta las colisiones del mundo, pero no se convierte en un
	# obstáculo para el jugador. Así los muebles lo frenan sin que un animal de
	# veinte centímetros pueda bloquear un pasillo al personaje.
	collision_layer = 0
	collision_mask = 1
	_colision = CollisionShape3D.new()
	_colision.position = Vector3(0, 0.20, -0.03)
	var caja_col := BoxShape3D.new()
	caja_col.size = Vector3(0.20, 0.16, 0.50)
	_colision.shape = caja_col
	add_child(_colision)

	_cuerpo = Node3D.new()
	add_child(_cuerpo)

	_pieza(_cuerpo, LOMO, COLOR)
	_pieza(_cuerpo, PECHO, COLOR_CLARO)

	# Las patas. Delanteras rectas; traseras con muslo ancho y corvejón hacia
	# atrás, que es lo que hace que un gato parado parezca a punto de saltar.
	for x in [-0.040, 0.040]:
		_pieza(
			_cuerpo,
			[
				{"c": Vector3(x, 0.200, -0.120), "r": 0.030},
				{"c": Vector3(x, 0.110, -0.125), "r": 0.022},
				{"c": Vector3(x, 0.012, -0.130), "r": 0.019},
			],
			COLOR,
			6
		)
		_pieza(
			_cuerpo,
			[
				{"c": Vector3(x, 0.018, -0.128), "r": Vector2(0.022, 0.016)},
				{"c": Vector3(x, 0.012, -0.160), "r": Vector2(0.020, 0.010)},
			],
			COLOR_CLARO,
			6
		)
	for x in [-0.052, 0.052]:
		_pieza(
			_cuerpo,
			[
				{"c": Vector3(x, 0.200, 0.120), "r": Vector2(0.034, 0.055)},
				{"c": Vector3(x, 0.130, 0.150), "r": Vector2(0.032, 0.040)},
				{"c": Vector3(x, 0.075, 0.170), "r": 0.021},
				{"c": Vector3(x, 0.012, 0.160), "r": 0.018},
			],
			COLOR,
			6
		)
		_pieza(
			_cuerpo,
			[
				{"c": Vector3(x, 0.014, 0.172), "r": Vector2(0.021, 0.014)},
				{"c": Vector3(x, 0.011, 0.132), "r": Vector2(0.019, 0.009)},
			],
			COLOR_CLARO,
			6
		)

	# La cabeza cuelga de su nodo para poder mirar y mover las orejas.
	_cabeza = Node3D.new()
	_cabeza.position = Vector3(0, 0.27, -0.19)
	_cuerpo.add_child(_cabeza)
	var origen := _cabeza.position
	_pieza(_cabeza, _relativa(CABEZA, origen), COLOR)
	_pieza(_cabeza, _relativa(HOCICO, origen), COLOR_CLARO, 6)
	_pieza(
		_cabeza,
		_relativa(
			[
				{"c": Vector3(0, 0.281, -0.290), "r": Vector2(0.011, 0.007)},
				{"c": Vector3(0, 0.279, -0.300), "r": Vector2(0.006, 0.004)},
			],
			origen
		),
		COLOR_NARIZ,
		5
	)

	# Ojos: un disco ámbar con la pupila vertical encima. Sin ojos, a la altura
	# de la cámara, un gato es una patata con orejas.
	for x in [-0.030, 0.030]:
		_pieza(
			_cabeza,
			_relativa(
				[
					{"c": Vector3(x, 0.300, -0.272), "r": Vector2(0.017, 0.014)},
					{"c": Vector3(x, 0.300, -0.290), "r": Vector2(0.014, 0.011)},
				],
				origen
			),
			COLOR_OJO,
			6
		)
		_pieza(
			_cabeza,
			_relativa(
				[
					{"c": Vector3(x, 0.300, -0.288), "r": Vector2(0.004, 0.011)},
					{"c": Vector3(x, 0.300, -0.294), "r": Vector2(0.003, 0.008)},
				],
				origen
			),
			COLOR_PUPILA,
			4
		)

	# Orejas: una pirámide de tres lados, ancha en la base y separada, con el
	# interior claro. Son la silueta que dice «gato» antes que nada.
	for lado in [-1.0, 1.0]:
		var oreja := Node3D.new()
		oreja.position = Vector3(0.040 * lado, 0.335, -0.215) - origen
		oreja.rotation = Vector3(-0.15, 0, -0.35 * lado)
		_cabeza.add_child(oreja)
		_pieza(
			oreja,
			[
				{"c": Vector3(0, -0.012, 0), "r": Vector2(0.030, 0.014)},
				{"c": Vector3(0, 0.060, 0.004), "r": 0.0},
			],
			COLOR,
			4
		)
		_pieza(
			oreja,
			[
				{"c": Vector3(0, -0.004, -0.009), "r": Vector2(0.018, 0.005)},
				{"c": Vector3(0, 0.040, -0.004), "r": 0.0},
			],
			COLOR_NARIZ,
			4
		)
		_orejas.append(oreja)

	# La cola cuelga de su propio nodo porque se mueve. Gruesa y larga, sale
	# del lomo y sube en curva de interrogación: un gato tranquilo.
	_cola = Node3D.new()
	_cola.position = Vector3(0, 0.190, 0.200)
	_cuerpo.add_child(_cola)
	_pieza(
		_cola,
		[
			{"c": Vector3(0, 0.000, -0.020), "r": 0.024},
			{"c": Vector3(0, 0.020, 0.060), "r": 0.022},
			{"c": Vector3(0, 0.080, 0.120), "r": 0.020},
			{"c": Vector3(0, 0.170, 0.140), "r": 0.019},
			{"c": Vector3(0, 0.240, 0.115), "r": 0.017},
			{"c": Vector3(0, 0.270, 0.075), "r": 0.013},
			{"c": Vector3(0, 0.272, 0.055), "r": 0.0},
		],
		COLOR,
		6
	)


func _pieza(raiz: Node3D, espina: Array, color: Color, lados := MallaOrganica.LADOS) -> void:
	MallaOrganica.pieza(raiz, MallaOrganica.tubo(espina, lados), Vector3.ZERO, Vector3.ZERO, color)


static func _relativa(espina: Array, origen: Vector3) -> Array:
	var fuera := []
	for punto in espina:
		fuera.append({"c": punto["c"] - origen, "r": punto["r"]})
	return fuera


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

	# Conducta propone un paso; el cuerpo físico decide cuánto de ese paso cabe
	# realmente en la casa. Al final se devuelve la posición real a la conducta,
	# para que nunca crea que atravesó un mueble mientras la malla quedó detrás.
	estado["pos"] = position
	estado = GatoConducta.avanzar(estado, sitios, hambre, jugador, delta)
	var propuesta: Vector3 = estado["pos"]
	estado["pos"] = position

	var antes := position
	_mover_sin_atravesar(propuesta - position, delta)
	estado["pos"] = position

	# Mira hacia donde anda. El morro del modelo apunta a -Z, así que el yaw
	# necesita media vuelta respecto a la convención habitual (+Z hacia avance).
	# Parado conserva el rumbo: un gato que gira sobre sí mismo al llegar se ve
	# como un error de física, no como un gato.
	var avance := position - antes
	if avance.length() > 0.001:
		var giro := atan2(avance.x, avance.z) + PI
		_cuerpo.rotation.y = giro
		_colision.rotation.y = giro

	# La cola. Más deprisa con hambre, que es la otra mitad de la señal: si no
	# viene y además está tensa, algo pasa. Durante los mimos vuelve a moverse
	# con intención, pero sin parecer la tensión del hambre.
	var ritmo := 1.5
	if estado["estado"] == "hambriento":
		ritmo = 3.4
	elif estado["estado"] == "mimos":
		ritmo = 2.4
	_cola.rotation.y = sin(_reloj * ritmo) * 0.35
	_cola.rotation.x = sin(_reloj * ritmo * 0.6) * 0.12
	_animar_reposo(ritmo)


## Aplica el paso propuesto contra las mismas colisiones que usan los muebles.
## Al chocar elige un lateral y lo mantiene brevemente: una mesa se rodea en
## vez de cruzarse, sin introducir un sistema de navegación para una sola casa.
func _mover_sin_atravesar(paso: Vector3, delta: float) -> void:
	var plano := Vector3(paso.x, 0, paso.z)
	if plano.length_squared() < 0.000001:
		_desvio_resto = maxf(0.0, _desvio_resto - delta)
		return

	var distancia := minf(plano.length(), GatoConducta.VELOCIDAD * delta)
	var movimiento := plano.normalized() * distancia
	if _desvio_resto > 0.0 and _desvio.length_squared() > 0.0:
		movimiento = _desvio * distancia
		_desvio_resto = maxf(0.0, _desvio_resto - delta)

	var choque := move_and_collide(movimiento)
	if choque == null:
		return

	var normal: Vector3 = choque.get_normal()
	var lateral := Vector3(-normal.z, 0, normal.x)
	if lateral.length_squared() < 0.000001:
		return
	lateral = lateral.normalized()

	var destino: Vector3 = estado.get("destino", position)
	var hacia_destino := Vector3(destino.x - position.x, 0, destino.z - position.z)
	if (-lateral).dot(hacia_destino) > lateral.dot(hacia_destino):
		lateral = -lateral
	_desvio = lateral
	_desvio_resto = DURACION_DESVIO

	# Aprovecha el resto del paso ya en este frame; si hay una esquina, el
	# siguiente frame recalculará el lateral con la nueva normal.
	var resto := choque.get_remainder().length()
	if resto > 0.001:
		move_and_collide(lateral * resto)


## Lo que hace que no parezca una figura: respira, y de vez en cuando mueve
## una oreja. Con hambre, las orejas se echan un poco atrás. En `mimos` el
## cuerpo se frota lateralmente y la cabeza acompaña el gesto.
func _animar_reposo(ritmo: float) -> void:
	_cuerpo.scale.y = 1.0 + sin(_reloj * 2.2) * 0.012
	var dando_mimos := estado.get("estado", "") == "mimos"
	_cuerpo.position.x = sin(_reloj * 4.2) * 0.028 if dando_mimos else 0.0
	_cuerpo.rotation.z = sin(_reloj * 3.1) * 0.045 if dando_mimos else 0.0
	_cabeza.rotation.y = sin(_reloj * 0.45) * 0.18
	_cabeza.rotation.z = -0.12 if dando_mimos else 0.0
	var atras := 0.25 if ritmo > 3.0 else 0.0
	for i in _orejas.size():
		var tic := pow(maxf(sin(_reloj * 0.9 + i * 2.3), 0.0), 24.0) * 0.3
		_orejas[i].rotation.x = -0.15 - atras - tic
