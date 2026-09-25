## Identidad legible del trayecto (#277, #398): qué es cada sitio de la calle.
##
## Se sale del edificio del SIGA y se llega al portal de casa. Entre medias, a
## pie de calle, los sitios a los que el juego manda al jugador:
## - al inicio, a la espalda del spawn: la entrada del Archivo General;
## - acera izquierda: la Ventanilla de Reclamaciones (el Coliseo, #43) y la
##   tienda de electrodomésticos con dos hileras de cuatro televisores;
## - acera derecha: la tienda de videojuegos donde se compran cartuchos (#93) y
##   la administración de fincas donde se paga el alquiler (#85);
## - al fondo: el bloque de viviendas con el portal de casa.
##
## Es presentación sobre la planta que ya declara `dia_calle_app`. Las dos
## tiendas con trámite exponen un `Interactuable3D`; la regla sigue en
## `TiendaVideojuegos` y la pantalla del Coliseo en `ventanilla_app`.
class_name CalleIdentidad
extends RefCounted

const SHADER_CRISTAL_PSX := "res://arte/psx_cristal.gdshader"

const OFICINA_FACHADA_Z := -17.3
const CASA_FACHADA_Z := 16.3
const CARA_OESTE_SUR := -5.2
const CARA_OESTE_NORTE := -5.5
const CARA_ESCAPARATE := -5.47
const CARA_ESTE_SUR := 5.5
const CARA_ESTE_NORTE := 5.55

const LUZ_CALIDA := Color(1.0, 0.78, 0.46)
const LUZ_FRIA := Color(0.62, 0.74, 0.80)
const CRISTAL_APAGADO := Color(0.07, 0.08, 0.10)
const METAL := Color(0.16, 0.17, 0.18)

## Cuatro televisores por hilera, dos hileras: el escaparate que se reconoce.
const TELES_Z := [-3.75, -2.25, -0.75, 0.75]
const TELES_Y := [0.74, 1.64]
const TAM_TELE := Vector3(0.62, 0.56, 0.5)
# El escaparate real terminó creciendo a 2x4 en #398. #142 conserva seis
# familias CRT y usa los dos aparatos extra para los estados históricos válidos:
# media luna procedural y nieve.
const EMISIONES_ESCAPARATE := [
	{"contenido": "emision_crt", "canal": 0, "semilla": 1.0},
	{"contenido": "emision_crt", "canal": 1, "semilla": 2.0},
	{"contenido": "emision_crt", "canal": 2, "semilla": 3.0},
	{"contenido": "emision_crt", "canal": 3, "semilla": 4.0},
	{"contenido": "emision_crt", "canal": 4, "semilla": 5.0},
	{"contenido": "emision_crt", "canal": 5, "semilla": 6.0},
	{"contenido": "media_luna", "semilla": 7.0},
	{"contenido": "", "semilla": 8.0},
]

const FAROLAS_Z := [-10.0, 0.0, 10.0]

## Las ventanas altas deben quedar por delante de la piel de revoco de #582.
## Esa piel termina a 4,5 cm de la cara; una ventana de 2 cm centrada a 7 cm
## empieza a 6 cm y conserva 1,5 cm de aire, evitando el solape de #563.
const SALIENTE_VENTANA_FACHADA := 0.07
const GROSOR_VENTANA_FACHADA := 0.02

## Qué dice la puerta de la tienda cuando TiendaVideojuegos no vende.
const AVISOS_TIENDA := {
	"sin_dinero": "CALLE_TIENDA_FALLO_SIN_DINERO",
	"sin_stock": "CALLE_TIENDA_FALLO_SIN_STOCK",
	"fuera_del_trayecto": "CALLE_TIENDA_FALLO_FUERA_DEL_TRAYECTO",
	"jornada_invalida": "CALLE_TIENDA_FALLO_JORNADA_INVALIDA",
	"rom_desconocida": "CALLE_TIENDA_FALLO_ROM_DESCONOCIDA",
	"precio_invalido": "CALLE_TIENDA_FALLO_PRECIO_INVALIDO",
}


static func montar(mundo: Node3D) -> Node3D:
	if mundo == null:
		return null
	var existente := mundo.get_node_or_null("CalleIdentidad") as Node3D
	if existente != null:
		return existente
	var calle := Node3D.new()
	calle.name = "CalleIdentidad"
	mundo.add_child(calle)
	_edificio_oficina(calle)
	_bloque_casa(calle)
	_ventanilla_reclamaciones(calle)
	_electrodomesticos(calle)
	_videojuegos(calle)
	_alquileres(calle)
	_farolas(calle)
	_pisos_de_fachada(calle)
	return calle


# --- Extremos ------------------------------------------------------------------


static func _edificio_oficina(calle: Node3D) -> void:
	var z := OFICINA_FACHADA_Z
	var raiz := _grupo(calle, "EdificioOficina")
	_caja(
		raiz,
		"Volumen",
		Vector3(0, 7.0, z - 3.0),
		Vector3(19.0, 14.0, 6.0),
		Color(0.44, 0.45, 0.46),
		"revoco_urbano"
	)
	_caja(
		raiz,
		"Zocalo",
		Vector3(0, 1.6, z + 0.04),
		Vector3(19.0, 3.2, 0.08),
		Color(0.30, 0.29, 0.28),
		"revoco_urbano"
	)
	_caja(
		raiz, "Cornisa", Vector3(0, 14.1, z + 0.1), Vector3(19.4, 0.3, 0.3), Color(0.36, 0.36, 0.37)
	)
	# Cuatro plantas de oficinas; la cuarta es la del Archivo y queda encendida.
	for planta in 4:
		var y := 3.9 + planta * 2.6
		_caja(
			raiz,
			"Banda%d" % planta,
			Vector3(0, y + 0.65, z + 0.05),
			Vector3(17.2, 1.4, 0.04),
			CRISTAL_APAGADO
		)
		for i in 8:
			var x := -7.35 + i * 2.1
			var encendida := planta == 3 or _azar(planta * 11 + i) < 0.22
			if encendida:
				_luz(
					raiz,
					"Ventana%d_%d" % [planta, i],
					Vector3(x, y + 0.65, z + 0.08),
					Vector3(1.6, 1.15, 0.02),
					LUZ_FRIA
				)
	# Vestíbulo de cristal, puertas, marquesina y rótulo.
	_cristal(
		raiz,
		"Vestibulo",
		Vector3(0, 1.4, z + 0.09),
		Vector3(6.2, 2.6, 0.02),
		Color(0.30, 0.36, 0.35),
		0.26,
		0.12
	)
	for x in [-3.15, -0.02, 3.15]:
		_caja(
			raiz,
			"Montante%.0f" % (x * 10),
			Vector3(x, 1.4, z + 0.12),
			Vector3(0.1, 2.7, 0.08),
			METAL,
			"metal_pintado"
		)
	_cristal(
		raiz,
		"PuertaIzquierda",
		Vector3(-0.58, 1.1, z + 0.13),
		Vector3(1.05, 2.2, 0.03),
		Color(0.40, 0.46, 0.44),
		0.30,
		0.10
	)
	_cristal(
		raiz,
		"PuertaDerecha",
		Vector3(0.58, 1.1, z + 0.13),
		Vector3(1.05, 2.2, 0.03),
		Color(0.40, 0.46, 0.44),
		0.30,
		0.10
	)
	_caja(
		raiz,
		"Marquesina",
		Vector3(0, 3.1, z + 0.9),
		Vector3(7.2, 0.24, 1.8),
		Color(0.20, 0.22, 0.24),
		"metal_pintado"
	)
	_luz(raiz, "LuzMarquesina", Vector3(0, 2.97, z + 0.9), Vector3(6.4, 0.02, 0.25), LUZ_CALIDA)
	_caja(
		raiz,
		"Escalon",
		Vector3(0, 0.07, z + 0.45),
		Vector3(7.2, 0.14, 0.9),
		Color(0.34, 0.33, 0.32)
	)
	_rotulo(
		raiz,
		tr_clave("CALLE_ROTULO_OFICINA"),
		Vector3(0, 3.1, z + 1.81),
		0.0,
		Color(0.96, 0.92, 0.78),
		64
	)
	# Antena en la azotea: una silueta que se lee contra el cielo.
	_caja(raiz, "Antena", Vector3(6.0, 15.6, z - 3.0), Vector3(0.08, 3.2, 0.08), METAL)
	_luz(
		raiz,
		"BalizaAntena",
		Vector3(6.0, 17.25, z - 3.0),
		Vector3(0.14, 0.14, 0.14),
		Color(1.0, 0.2, 0.15)
	)


static func _bloque_casa(calle: Node3D) -> void:
	var z := CASA_FACHADA_Z
	var raiz := _grupo(calle, "BloqueCasa")
	# La masa superior se escalona para que el final de la calle no cierre todo
	# el campo visual como una pared. La planta baja sigue siendo continua y el
	# portal no se mueve; solo se recorta la silueta contra el cielo.
	for tramo in [
		{
			"nombre": "AlaOeste",
			"centro": Vector3(-6.4, 4.3, z + 3.1),
			"tam": Vector3(6.2, 8.6, 6.2),
		},
		{
			"nombre": "TorreCentral",
			"centro": Vector3(0.0, 5.5, z + 3.1),
			"tam": Vector3(6.8, 11.0, 6.2),
		},
		{
			"nombre": "AlaEste",
			"centro": Vector3(6.4, 4.3, z + 3.1),
			"tam": Vector3(6.2, 8.6, 6.2),
		},
	]:
		_caja(
			raiz,
			String(tramo["nombre"]),
			tramo["centro"],
			tramo["tam"],
			Color(0.50, 0.39, 0.28),
			"revoco_urbano"
		)
	_caja(
		raiz,
		"Bajos",
		Vector3(0, 1.6, z - 0.03),
		Vector3(19.0, 3.2, 0.06),
		Color(0.34, 0.25, 0.19),
		"revoco_urbano"
	)
	for alero in [
		{"nombre": "AleroOeste", "x": -6.4, "y": 8.72, "ancho": 6.4},
		{"nombre": "AleroCentral", "x": 0.0, "y": 11.12, "ancho": 7.0},
		{"nombre": "AleroEste", "x": 6.4, "y": 8.72, "ancho": 6.4},
	]:
		_caja(
			raiz,
			String(alero["nombre"]),
			Vector3(float(alero["x"]), float(alero["y"]), z - 0.2),
			Vector3(float(alero["ancho"]), 0.25, 0.5),
			Color(0.28, 0.22, 0.18)
		)
	# El portal: el marco ya lo declara dia_calle_app; aquí la puerta y su luz.
	_caja(
		raiz,
		"PuertaPortal",
		Vector3(0, 1.3, z - 0.07),
		Vector3(1.85, 2.6, 0.06),
		Color(0.30, 0.20, 0.13),
		"madera_domestica"
	)
	_cristal(
		raiz,
		"CristalPortal",
		Vector3(0, 1.95, z - 0.11),
		Vector3(0.9, 0.55, 0.02),
		Color(0.55, 0.44, 0.26),
		0.38,
		0.20
	)
	_luz(raiz, "LamparaPortal", Vector3(0, 3.35, z - 0.12), Vector3(0.3, 0.2, 0.12), LUZ_CALIDA)
	_rotulo(raiz, "7", Vector3(0.0, 2.55, z - 0.12), 180.0, Color(0.95, 0.85, 0.55), 72)
	# Bajos comerciales cerrados con persiana a los lados del portal.
	for x in [-5.2, 5.2]:
		_caja(
			raiz,
			"PersianaBajo%s" % ("O" if x < 0 else "E"),
			Vector3(x, 1.25, z - 0.08),
			Vector3(4.2, 2.3, 0.05),
			Color(0.36, 0.37, 0.37),
			"metal_pintado"
		)
	# Tres plantas de viviendas con balcón. Algunas casas tienen la luz puesta.
	for planta in 3:
		var y := 3.6 + planta * 2.7
		for i in 7:
			var x := -7.8 + i * 2.6
			# La tercera planta solo existe en la torre central: las alas bajas
			# dejan dos franjas de cielo visibles durante el tramo final.
			if planta == 2 and absf(x) > 3.2:
				continue
			var semilla := 100 + planta * 13 + i
			var nombre := "%d_%d" % [planta, i]
			if _azar(semilla) < 0.42:
				_luz(
					raiz,
					"Ventana" + nombre,
					Vector3(x, y + 0.95, z - 0.05),
					Vector3(1.1, 1.5, 0.02),
					LUZ_CALIDA
				)
			else:
				_caja(
					raiz,
					"Ventana" + nombre,
					Vector3(x, y + 0.95, z - 0.05),
					Vector3(1.1, 1.5, 0.02),
					CRISTAL_APAGADO
				)
				# Persiana medio bajada, como se deja una casa de noche.
				_caja(
					raiz,
					"Persiana" + nombre,
					Vector3(x, y + 1.45, z - 0.08),
					Vector3(1.12, 0.5, 0.03),
					Color(0.42, 0.30, 0.20),
					"madera_domestica"
				)
			if planta > 0 or absf(x) > 1.5:
				_caja(
					raiz,
					"Balcon" + nombre,
					Vector3(x, y, z - 0.35),
					Vector3(1.7, 0.1, 0.7),
					Color(0.40, 0.36, 0.32)
				)
				_caja(
					raiz,
					"Baranda" + nombre,
					Vector3(x, y + 0.5, z - 0.68),
					Vector3(1.7, 0.9, 0.04),
					METAL
				)
	# Azotea: depósito y antenas permanecen sobre el cuerpo central para que las
	# alas laterales no vuelvan a cerrar la silueta ganada.
	_caja(
		raiz,
		"Deposito",
		Vector3(-1.7, 11.7, z + 3.0),
		Vector3(1.6, 1.4, 1.6),
		Color(0.42, 0.40, 0.38),
		"metal_pintado"
	)
	for x in [-2.4, 0.8, 2.5]:
		_caja(raiz, "AntenaTV%.0f" % x, Vector3(x, 11.8, z + 1.5), Vector3(0.05, 1.6, 0.05), METAL)
		_caja(
			raiz,
			"AntenaTVBrazo%.0f" % x,
			Vector3(x, 12.4, z + 1.5),
			Vector3(0.9, 0.04, 0.04),
			METAL
		)


# --- Acera izquierda -----------------------------------------------------------


static func _ventanilla_reclamaciones(calle: Node3D) -> void:
	var x := CARA_OESTE_SUR
	var raiz := _grupo(calle, "VentanillaReclamaciones")
	_caja(
		raiz,
		"Portada",
		Vector3(x + 0.05, 1.65, -14.0),
		Vector3(0.1, 3.3, 3.8),
		Color(0.40, 0.39, 0.37),
		"revoco_urbano"
	)
	_cristal(
		raiz,
		"PuertaCristal",
		Vector3(x + 0.11, 1.15, -14.4),
		Vector3(0.02, 2.3, 1.5),
		Color(0.28, 0.33, 0.35),
		0.30,
		0.18
	)
	_cristal(
		raiz,
		"Mostrador",
		Vector3(x + 0.11, 1.5, -12.9),
		Vector3(0.02, 1.1, 0.9),
		Color(0.36, 0.40, 0.38),
		0.34,
		0.14
	)
	_caja(
		raiz,
		"Placa",
		Vector3(x + 0.12, 3.0, -14.0),
		Vector3(0.08, 0.62, 3.7),
		Color(0.10, 0.16, 0.32)
	)
	_rotulo(
		raiz,
		tr_clave("CALLE_ROTULO_RECLAMACIONES"),
		Vector3(x + 0.17, 3.0, -14.0),
		90.0,
		Color(0.95, 0.95, 0.90),
		44
	)
	_rotulo(
		raiz,
		tr_clave("CALLE_ROTULO_TURNO"),
		Vector3(x + 0.13, 1.95, -12.9),
		90.0,
		Color(1.0, 0.25, 0.2),
		32
	)
	# Postes de cola: la ventanilla se reconoce por la fila antes que por el rótulo.
	for z in [-15.3, -14.0, -12.7]:
		_caja(
			raiz,
			"PosteCola%.0f" % (z * 10),
			Vector3(x + 0.65, 0.5, z),
			Vector3(0.06, 1.0, 0.06),
			METAL
		)
	_caja(
		raiz,
		"CintaCola",
		Vector3(x + 0.65, 0.9, -14.0),
		Vector3(0.02, 0.06, 2.6),
		Color(0.55, 0.12, 0.12)
	)
	_interactuable(
		raiz,
		"EntrarVentanillaReclamaciones",
		Vector3(x + 0.6, 1.1, -14.4),
		Vector3(1.0, 2.2, 1.6),
		Interactuable3D.Verbo.USAR,
		"ventanilla de reclamaciones"
	)


static func _electrodomesticos(calle: Node3D) -> void:
	var x := CARA_ESCAPARATE
	var raiz := _grupo(calle, "Electrodomesticos")
	_caja(
		raiz,
		"Rotulo",
		Vector3(x + 0.05, 3.2, -1.5),
		Vector3(0.1, 0.5, 6.6),
		Color(0.52, 0.10, 0.08)
	)
	_rotulo(
		raiz,
		tr_clave("CALLE_ROTULO_ELECTRODOMESTICOS"),
		Vector3(x + 0.11, 3.2, -1.5),
		90.0,
		Color(1.0, 0.95, 0.82),
		56
	)
	_cristal(
		raiz,
		"CristalEscaparate",
		Vector3(-5.70, 1.62, -1.5),
		Vector3(0.03, 2.0, 6.45),
		Color(0.55, 0.65, 0.72),
		0.16,
		0.0
	)
	_luz(
		raiz,
		"InteriorTienda",
		Vector3(-6.46, 1.6, -1.5),
		Vector3(0.02, 2.0, 6.4),
		Color(0.09, 0.08, 0.08)
	)
	# Dos baldas y cuatro televisores en cada una. Cada aparato monta su propia
	# superficie para que el escaparate no vuelva a leerse como una imagen clonada.
	for fila in TELES_Y.size():
		var y: float = TELES_Y[fila]
		_caja(
			raiz,
			"Balda%d" % fila,
			Vector3(-6.12, y - 0.03, -1.5),
			Vector3(0.62, 0.05, 6.3),
			Color(0.30, 0.24, 0.18),
			"madera_domestica"
		)
		for columna in TELES_Z.size():
			var z: float = TELES_Z[columna]
			var tele := Node3D.new()
			tele.name = "Televisor%d_%d" % [fila, columna]
			tele.position = Vector3(-6.12, y + TAM_TELE.y / 2.0, z)
			tele.rotation_degrees.y = 90.0
			raiz.add_child(tele)
			Modelos.mueble(tele, "televisionVintage", TAM_TELE, Color(0.30, 0.28, 0.26))
			var indice := fila * TELES_Z.size() + columna
			var programa: Dictionary = EMISIONES_ESCAPARATE[indice]
			var declaracion := {
				"pos": Vector3(-5.84, y + 0.30, z),
				"tam": Vector2(0.40, 0.30),
				"giro": 90.0,
				"contenido": String(programa.get("contenido", "")),
				"semilla": float(programa.get("semilla", indice + 1)),
			}
			if programa.has("canal"):
				declaracion["canal"] = int(programa["canal"])
			var pantalla := Pantalla.montar(raiz, declaracion)
			pantalla.name = "Pantalla%d_%d" % [fila, columna]


# --- Acera derecha -------------------------------------------------------------


static func _videojuegos(calle: Node3D) -> void:
	var x := CARA_ESTE_SUR
	var raiz := _grupo(calle, "TiendaVideojuegos")
	_caja(
		raiz,
		"Frente",
		Vector3(x - 0.04, 1.5, -6.5),
		Vector3(0.08, 3.0, 3.9),
		Color(0.08, 0.08, 0.10)
	)
	_cristal(
		raiz,
		"Escaparate",
		Vector3(x - 0.09, 1.45, -7.2),
		Vector3(0.02, 1.6, 2.2),
		Color(0.12, 0.16, 0.34),
		0.28,
		0.35
	)
	_cristal(
		raiz,
		"Puerta",
		Vector3(x - 0.09, 1.1, -5.15),
		Vector3(0.02, 2.2, 0.9),
		Color(0.42, 0.36, 0.24),
		0.34,
		0.18
	)
	_caja(
		raiz,
		"Rotulo",
		Vector3(x - 0.08, 2.95, -6.5),
		Vector3(0.1, 0.62, 3.9),
		Color(0.04, 0.04, 0.05)
	)
	_rotulo(
		raiz,
		tr_clave("CALLE_ROTULO_VIDEOJUEGOS"),
		Vector3(x - 0.14, 3.05, -6.5),
		-90.0,
		Color(1.0, 0.32, 0.85),
		60
	)
	_rotulo(
		raiz,
		tr_clave("CALLE_ROTULO_CARTUCHOS"),
		Vector3(x - 0.14, 2.76, -6.5),
		-90.0,
		Color(0.35, 0.95, 1.0),
		30
	)
	# Cajas de cartucho en el escaparate: color de portada, sin marcas reales.
	var portadas := [
		Color(0.85, 0.20, 0.18),
		Color(0.20, 0.45, 0.85),
		Color(0.95, 0.80, 0.20),
		Color(0.25, 0.70, 0.35),
		Color(0.60, 0.25, 0.75),
		Color(0.95, 0.50, 0.15),
	]
	for i in 12:
		var fila := i / 6
		var z := -8.05 + (i % 6) * 0.34
		_luz(
			raiz,
			"Cartucho%d" % i,
			Vector3(x - 0.11, 0.95 + fila * 0.62, z),
			Vector3(0.02, 0.36, 0.26),
			portadas[(i + fila) % portadas.size()]
		)
	var neon := OmniLight3D.new()
	neon.name = "NeonVideojuegos"
	neon.light_color = Color(1.0, 0.35, 0.85)
	neon.light_energy = 1.4
	neon.omni_range = 4.0
	neon.position = Vector3(x - 0.8, 2.9, -6.5)
	raiz.add_child(neon)
	var puerta := _interactuable(
		raiz,
		"ComprarCartuchos",
		Vector3(x - 0.55, 1.1, -5.15),
		Vector3(0.9, 2.2, 1.2),
		Interactuable3D.Verbo.USAR,
		"tienda de videojuegos"
	)
	puerta.activado.connect(_comprar_cartucho.bind(puerta))


static func _alquileres(calle: Node3D) -> void:
	var x := CARA_ESTE_NORTE
	var raiz := _grupo(calle, "Alquileres")
	_caja(
		raiz,
		"Frente",
		Vector3(x - 0.04, 1.5, 10.0),
		Vector3(0.08, 3.0, 4.2),
		Color(0.16, 0.22, 0.18),
		"madera_domestica"
	)
	_cristal(
		raiz,
		"VentanillaPago",
		Vector3(x - 0.09, 1.45, 9.6),
		Vector3(0.02, 1.1, 1.6),
		Color(0.40, 0.38, 0.30),
		0.34,
		0.12
	)
	_caja(
		raiz,
		"RepisaPago",
		Vector3(x - 0.3, 0.92, 9.6),
		Vector3(0.5, 0.07, 1.8),
		Color(0.30, 0.24, 0.18),
		"madera_domestica"
	)
	_cristal(
		raiz,
		"Puerta",
		Vector3(x - 0.09, 1.1, 11.45),
		Vector3(0.02, 2.2, 0.9),
		Color(0.30, 0.27, 0.20),
		0.34,
		0.10
	)
	_caja(
		raiz,
		"Rotulo",
		Vector3(x - 0.08, 2.95, 10.0),
		Vector3(0.1, 0.62, 4.2),
		Color(0.10, 0.20, 0.14)
	)
	_rotulo(
		raiz,
		tr_clave("CALLE_ROTULO_ALQUILERES"),
		Vector3(x - 0.14, 3.05, 10.0),
		-90.0,
		Color(0.95, 0.93, 0.85),
		56
	)
	_rotulo(
		raiz,
		tr_clave("CALLE_ROTULO_FINCAS"),
		Vector3(x - 0.14, 2.76, 10.0),
		-90.0,
		Color(0.85, 0.82, 0.70),
		28
	)
	_rotulo(
		raiz,
		tr_clave("CALLE_ROTULO_PAGO_ALQUILER"),
		Vector3(x - 0.11, 2.13, 9.6),
		-90.0,
		Color(0.10, 0.10, 0.10),
		26
	)


# --- Calle ---------------------------------------------------------------------


## Las tres luces ya declaradas cuelgan de un cable entre fachadas, como en una
## calle estrecha; donde falta fachada, un poste recoge el cable.
static func _farolas(calle: Node3D) -> void:
	var raiz := _grupo(calle, "Farolas")
	for z in FAROLAS_Z:
		var oeste := (
			CARA_OESTE_SUR if z < -5.0 else (CARA_ESCAPARATE if z < 3.0 else CARA_OESTE_NORTE)
		)
		var este := CARA_ESTE_SUR if z < -3.0 else (5.0 if z < 3.0 else CARA_ESTE_NORTE)
		var nombre := "%.0f" % z
		_caja(
			raiz,
			"Cable" + nombre,
			Vector3((oeste + este) / 2.0, 2.98, z),
			Vector3(este - oeste, 0.025, 0.025),
			Color(0.05, 0.05, 0.05)
		)
		_caja(
			raiz,
			"Pantalla" + nombre,
			Vector3(0, 2.8, z),
			Vector3(0.72, 0.14, 0.72),
			METAL,
			"metal_pintado"
		)
		_caja(raiz, "Colgante" + nombre, Vector3(0, 2.9, z), Vector3(0.04, 0.16, 0.04), METAL)
		if este == 5.0:
			_caja(
				raiz,
				"Poste" + nombre,
				Vector3(este, 1.5, z),
				Vector3(0.12, 3.0, 0.12),
				METAL,
				"metal_pintado"
			)


## Las fachadas de la calle dejan de ser muros de una planta: ventanas en las
## plantas altas, con algunas casas encendidas.
static func _pisos_de_fachada(calle: Node3D) -> void:
	var raiz := _grupo(calle, "PisosFachada")
	var tramos := [
		[CARA_OESTE_SUR, -16.6, -8.6, 3, 1],
		[CARA_ESCAPARATE - 0.02, -4.6, 1.6, 2, 1],
		[CARA_OESTE_NORTE, 4.6, 15.6, 3, 1],
		[CARA_ESTE_SUR, -16.6, -4.6, 3, -1],
		[CARA_ESTE_NORTE, 4.6, 15.6, 2, -1],
	]
	for t in tramos.size():
		var tramo: Array = tramos[t]
		var cara: float = tramo[0]
		var hacia: float = tramo[4]
		var cuantas := int((tramo[2] - tramo[1]) / 1.9)
		for planta in int(tramo[3]):
			var y := 4.4 + planta * 2.7
			for i in cuantas:
				var z: float = tramo[1] + 0.95 + i * 1.9
				var posicion := Vector3(cara + hacia * SALIENTE_VENTANA_FACHADA, y, z)
				var nombre := "Ventana%d_%d_%d" % [t, planta, i]
				if _azar(t * 97 + planta * 13 + i) < 0.3:
					_luz(
						raiz,
						nombre,
						posicion,
						Vector3(GROSOR_VENTANA_FACHADA, 1.2, 0.9),
						LUZ_CALIDA
					)
				else:
					_caja(
						raiz,
						nombre,
						posicion,
						Vector3(GROSOR_VENTANA_FACHADA, 1.2, 0.9),
						CRISTAL_APAGADO
					)


## Ventanas encendidas en el fondo urbano: el skyline deja de ser un recorte negro.
static func iluminar_ventanas(edificio: Node3D, semilla: int) -> void:
	var caja := AABB()
	for malla in edificio.find_children("*", "MeshInstance3D", true, false):
		var propia: AABB = (
			edificio.global_transform.affine_inverse() * malla.global_transform * malla.get_aabb()
		)
		caja = propia if caja.size == Vector3.ZERO else caja.merge(propia)
	if caja.size == Vector3.ZERO:
		return
	var luces := Node3D.new()
	luces.name = "VentanasEncendidas"
	edificio.add_child(luces)
	# Se ilumina la cara que mira hacia la calle (el origen del trayecto).
	var hacia := -edificio.global_position
	hacia.y = 0.0
	var local := edificio.global_transform.basis.inverse() * hacia
	var eje_x := absf(local.x) > absf(local.z)
	var signo := signf(local.x if eje_x else local.z)
	var ancho := caja.size.z if eje_x else caja.size.x
	var columnas := maxi(2, int(ancho / 2.2))
	var pisos := maxi(2, int(caja.size.y / 2.8))
	var escala := edificio.scale.x
	for piso in pisos:
		for columna in columnas:
			if _azar(semilla * 31 + piso * 7 + columna) > 0.28:
				continue
			var u := lerpf(0.15, 0.85, (columna + 0.5) / columnas)
			var y := caja.position.y + caja.size.y * lerpf(0.12, 0.9, (piso + 0.5) / pisos)
			var ventana := MeshInstance3D.new()
			var malla := BoxMesh.new()
			malla.size = (
				Vector3(0.02, 1.0 / escala, 0.8 / escala)
				if eje_x
				else Vector3(0.8 / escala, 1.0 / escala, 0.02)
			)
			ventana.mesh = malla
			if eje_x:
				var borde := caja.end.x if signo > 0 else caja.position.x
				ventana.position = Vector3(
					borde + signo * 0.02, y, lerpf(caja.position.z, caja.end.z, u)
				)
			else:
				var borde := caja.end.z if signo > 0 else caja.position.z
				ventana.position = Vector3(
					lerpf(caja.position.x, caja.end.x, u), y, borde + signo * 0.02
				)
			ventana.material_override = _material_luz(LUZ_CALIDA.darkened(0.15))
			ventana.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			luces.add_child(ventana)


# --- Trámites ------------------------------------------------------------------


## Comprar en la tienda: la regla vive en TiendaVideojuegos; aquí solo se busca
## la jornada del día y se deja el resultado escrito en el propio prompt.
static func _comprar_cartucho(_actor: Node, puerta: Interactuable3D) -> void:
	var dia := _dia_de(puerta)
	if dia == null:
		return
	var jornada: Dictionary = dia.get("jornada")
	var pendiente := ""
	for entrada in TiendaVideojuegos.listar(jornada):
		if not entrada["comprada"]:
			pendiente = String(entrada["id"])
			break
	if pendiente.is_empty():
		puerta.nombre_objeto = tr_clave(
			(
				"CALLE_TIENDA_MANUAL_SERVICIO"
				if TiendaVideojuegos.consola_trucos_desbloqueada(jornada)
				else "CALLE_TIENDA_TODO_COMPRADO"
			)
		)
		return
	var resultado := TiendaVideojuegos.comprar(jornada, pendiente)
	var nombre := String(TiendaVideojuegos._buscar(pendiente).get("nombre", pendiente))
	if resultado.get("ok", false):
		if TiendaVideojuegos.consola_trucos_desbloqueada(jornada):
			puerta.nombre_objeto = tr_clave("CALLE_TIENDA_MANUAL_SERVICIO")
		else:
			puerta.nombre_objeto = tr_clave("CALLE_TIENDA_COMPRADO") % nombre
		if dia.has_method("_guardar_o_avisar"):
			dia.call("_guardar_o_avisar", "")
	else:
		var motivo := String(resultado.get("motivo", "sin_stock"))
		puerta.nombre_objeto = tr_clave(AVISOS_TIENDA.get(motivo, "CALLE_TIENDA_FALLO_SIN_STOCK"))


static func _dia_de(nodo: Node) -> Node:
	var actual := nodo.get_parent()
	while actual != null:
		if actual.get("jornada") is Dictionary:
			return actual
		actual = actual.get_parent()
	return null


# --- Piezas --------------------------------------------------------------------


static func tr_clave(clave: String) -> String:
	return TranslationServer.translate(clave)


static func _grupo(padre: Node3D, nombre: String) -> Node3D:
	var grupo := Node3D.new()
	grupo.name = nombre
	padre.add_child(grupo)
	return grupo


static func _caja(
	padre: Node3D, nombre: String, centro: Vector3, tam: Vector3, color: Color, textura := ""
) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	malla.name = nombre
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = centro
	malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Modelos._pintar(malla, color, textura)
	padre.add_child(malla)
	return malla


## Superficie que emite su propia luz: ventanas encendidas, cristales, rótulos.
static func _luz(
	padre: Node3D, nombre: String, centro: Vector3, tam: Vector3, color: Color
) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	malla.name = nombre
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = centro
	malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	malla.material_override = _material_luz(color)
	padre.add_child(malla)
	return malla


static func _material_luz(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material


static func _cristal(
	padre: Node3D,
	nombre: String,
	centro: Vector3,
	tam: Vector3,
	color: Color,
	opacidad: float = 0.30,
	emision_fuerza: float = 0.10
) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	malla.name = nombre
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = centro
	malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	malla.material_override = _material_cristal(color, hash(nombre), opacidad, emision_fuerza)
	padre.add_child(malla)
	return malla


static func _material_cristal(
	color: Color, semilla: int, opacidad: float, emision_fuerza: float
) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load(SHADER_CRISTAL_PSX)
	material.set_shader_parameter("color_base", Color(color.r, color.g, color.b, opacidad))
	material.set_shader_parameter(
		"textura", TexturaProcedural.por_nombre("cristal_urbano", Color.WHITE, semilla)
	)
	material.set_shader_parameter("con_textura", true)
	material.set_shader_parameter("escala_textura", 1.4)
	material.set_shader_parameter("emision_fuerza", emision_fuerza)
	return material


static func _rotulo(
	padre: Node3D, texto: String, pos: Vector3, giro_y: float, color: Color, tamano: int
) -> Label3D:
	var rotulo := Label3D.new()
	rotulo.name = "Rotulo_" + texto.left(12).replace(" ", "_")
	rotulo.text = texto
	rotulo.position = pos
	rotulo.rotation_degrees.y = giro_y
	rotulo.modulate = color
	rotulo.font = EstiloSiga.fuente_mono()
	rotulo.font_size = tamano
	rotulo.pixel_size = 0.0068
	rotulo.outline_size = 6
	rotulo.outline_modulate = Color(0, 0, 0, 0.7)
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.shaded = false
	rotulo.double_sided = false
	padre.add_child(rotulo)
	return rotulo


static func _interactuable(
	padre: Node3D, nombre: String, pos: Vector3, tam: Vector3, verbo: int, objeto: String
) -> Interactuable3D:
	var zona := Interactuable3D.new()
	zona.name = nombre
	zona.verbo = verbo
	zona.nombre_objeto = objeto
	zona.position = pos
	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam
	colision.shape = forma
	zona.add_child(colision)
	padre.add_child(zona)
	return zona


## Azar determinista y sin estado: la misma calle cada vez.
static func _azar(semilla: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(semilla * 7919 + 17)
	return rng.randf()
