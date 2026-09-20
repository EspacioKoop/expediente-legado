## Los sitios del día, declarados.
##
## Uno por fase de `Jornada`. El motor de `Espacio3D` no conoce ninguno por su
## nombre: aquí solo hay medidas, bultos y a dónde lleva cada salida, así que
## añadir un sitio es una entrada más y no tocar el motor.
##
## Los rótulos son CLAVES de traducción, no texto: el texto vive en
## `datos/textos.csv` y lo resuelve quien lo pinta.
##
## Los bultos son cajas con nombre de mueble y nada más. Una mesa es una caja
## hasta que haya un asset con su ficha; llamarla mesa aquí es lo que permite
## sustituirla luego sin tocar la geografía.
class_name EspaciosCatalogo
extends RefCounted

const OFICINA := {
	"rotulo": "SITIO_OFICINA",
	"suelo": Vector2(14, 10),
	"color_suelo": Color(0.30, 0.29, 0.27),
	"color_muro": Color(0.58, 0.57, 0.52),
	"color_techo": Color(0.80, 0.80, 0.76),
	"textura_suelo": "linoleo",
	"textura_muro": "gotele",
	"textura_techo": "techo",
	# Apartada del cuarto sitio de compañero, que está en la silla de (1, 2,1):
	# desde (0, 0, 3) se entraba a 1,35 m de alguien sentado, y su cabeza ocupaba
	# un cuarto de la primera pantalla jugable de la partida. Es la misma regla
	# que ya obliga al cuñado a no estar encima de la entrada.
	"entrada": Vector3(-1.6, 0, 3.6),
	"bultos":
	# Cuatro puestos idénticos: la planta es la misma para todos, que es
	[
		# parte de lo que cuenta.
		{"pos": Vector3(-4, 0.37, -2), "tam": Vector3(2.0, 0.75, 1.0), "modelo": "desk"},
		{"pos": Vector3(-4, 0.37, 1), "tam": Vector3(2.0, 0.75, 1.0), "modelo": "desk"},
		{"pos": Vector3(1, 0.37, -2), "tam": Vector3(2.0, 0.75, 1.0), "modelo": "desk"},
		{"pos": Vector3(1, 0.37, 1), "tam": Vector3(2.0, 0.75, 1.0), "modelo": "desk"},
		# Entre los puestos y la batería de archivadores hay una mesa de
		# clasificación. No es otro puesto: no tiene silla, teléfono ni terminal.
		# Obliga a rodearla y hace visible el flujo físico del archivo — sacar,
		# separar y devolver expedientes — sin escribir ni una sola etiqueta.
		{
			"pos": Vector3(3.6, 0.37, 0.0),
			"tam": Vector3(1.3, 0.75, 0.9),
			"color": Color(0.43, 0.40, 0.35),
			"modelo": "desk",
			"rol": "mesa_clasificacion"
		},
		{
			"pos": Vector3(3.32, 0.79, -0.12),
			"tam": Vector3(0.48, 0.06, 0.34),
			"color": Color(0.28, 0.27, 0.24),
			"rol": "bandeja_clasificacion"
		},
		{
			"pos": Vector3(3.88, 0.79, 0.12),
			"tam": Vector3(0.48, 0.06, 0.34),
			"color": Color(0.28, 0.27, 0.24),
			"rol": "bandeja_clasificacion"
		},
		{
			"pos": Vector3(3.32, 0.845, -0.12),
			"tam": Vector3(0.38, 0.05, 0.26),
			"color": Color(0.80, 0.78, 0.70),
			"rol": "lote_clasificacion_sin_texto"
		},
		{
			"pos": Vector3(3.88, 0.855, 0.12),
			"tam": Vector3(0.36, 0.07, 0.24),
			"color": Color(0.76, 0.74, 0.66),
			"rol": "lote_clasificacion_sin_texto"
		},
		# La silla 4-B y las otras tres. Es el objeto que el sueño agranda
		# (#87), así que tiene que ser una silla reconocible antes de que se
		# deforme: una caja agrandada es una caja mayor.
		# A la escala de una persona sentada (#134): a 0,95 m el cuerpo tapaba
		# la silla entera y parecía flotar sobre un taburete.
		{
			"pos": Vector3(-4, 0.57, -0.9),
			"tam": Vector3(0.74, 1.14, 0.74),
			"color": Color(0.34, 0.36, 0.38),
			"modelo": "chairDesk"
		},
		{
			"pos": Vector3(-4, 0.57, 2.1),
			"tam": Vector3(0.74, 1.14, 0.74),
			"color": Color(0.34, 0.36, 0.38),
			"modelo": "chairDesk"
		},
		{
			"pos": Vector3(1, 0.57, -0.9),
			"tam": Vector3(0.74, 1.14, 0.74),
			"color": Color(0.34, 0.36, 0.38),
			"modelo": "chairDesk"
		},
		{
			"pos": Vector3(1, 0.57, 2.1),
			"tam": Vector3(0.74, 1.14, 0.74),
			"color": Color(0.34, 0.36, 0.38),
			"modelo": "chairDesk"
		},
		# El terminal de SIGA-98 en el puesto propio. Va encendido y vacío: un
		# monitor iluminado no afirma nada, uno con datos afirma una lectura que
		# nadie ha calculado.
		{
			"pos": Vector3(-4.3, 0.98, -2.1),
			"tam": Vector3(0.5, 0.45, 0.4),
			"color": Color(0.52, 0.54, 0.50),
			"modelo": "computerScreen"
		},
		# Archivadores contra el muro del fondo. Son seis y no dos: un archivo
		# con dos archivadores es un despacho.
		{
			"pos": Vector3(5.5, 0.9, -4),
			"tam": Vector3(1.0, 1.8, 0.6),
			"color": Color(0.40, 0.39, 0.36),
			"modelo": "bookcaseClosed"
		},
		{
			"pos": Vector3(5.5, 0.9, -2.5),
			"tam": Vector3(1.0, 1.8, 0.6),
			"color": Color(0.40, 0.39, 0.36),
			"modelo": "bookcaseClosed"
		},
		{
			"pos": Vector3(5.5, 0.9, -1.0),
			"tam": Vector3(1.0, 1.8, 0.6),
			"color": Color(0.40, 0.39, 0.36),
			"modelo": "bookcaseClosed"
		},
		{
			"pos": Vector3(5.5, 0.9, 0.5),
			"tam": Vector3(1.0, 1.8, 0.6),
			"color": Color(0.38, 0.37, 0.35),
			"modelo": "bookcaseClosed"
		},
		{
			"pos": Vector3(5.5, 0.9, 2.0),
			"tam": Vector3(1.0, 1.8, 0.6),
			"color": Color(0.40, 0.39, 0.36),
			"modelo": "bookcaseClosed"
		},
		{
			"pos": Vector3(5.5, 0.9, 3.5),
			"tam": Vector3(1.0, 1.8, 0.6),
			"color": Color(0.38, 0.37, 0.35),
			"modelo": "bookcaseClosed"
		},
		# Papel. Un archivo con las mesas despejadas no es un archivo: hay
		# torres encima de cada puesto, cajas contra la pared y una pila en el
		# suelo que lleva ahí desde antes que tú.
		{
			"pos": Vector3(-4.7, 0.83, -2.2),
			"tam": Vector3(0.32, 0.16, 0.24),
			"color": Color(0.80, 0.78, 0.70)
		},
		{
			"pos": Vector3(-3.4, 0.80, -1.7),
			"tam": Vector3(0.30, 0.10, 0.22),
			"color": Color(0.78, 0.76, 0.68)
		},
		{
			"pos": Vector3(1.5, 0.86, 1.3),
			"tam": Vector3(0.34, 0.22, 0.26),
			"color": Color(0.80, 0.78, 0.70)
		},
		{
			"pos": Vector3(0.4, 0.79, -2.3),
			"tam": Vector3(0.30, 0.09, 0.22),
			"color": Color(0.76, 0.74, 0.66)
		},
		# Cajas de archivo apiladas contra el muro de la izquierda.
		{
			"pos": Vector3(-6.2, 0.20, -3.4),
			"tam": Vector3(0.5, 0.40, 0.7),
			"color": Color(0.62, 0.56, 0.44),
			"modelo": "cardboardBoxClosed"
		},
		{
			"pos": Vector3(-6.2, 0.61, -3.4),
			"tam": Vector3(0.5, 0.40, 0.7),
			"color": Color(0.60, 0.54, 0.42),
			"modelo": "cardboardBoxClosed"
		},
		{
			"pos": Vector3(-6.2, 1.02, -3.4),
			"tam": Vector3(0.5, 0.40, 0.7),
			"color": Color(0.62, 0.56, 0.44),
			"modelo": "cardboardBoxClosed"
		},
		{
			"pos": Vector3(-6.2, 0.20, -2.5),
			"tam": Vector3(0.5, 0.40, 0.7),
			"color": Color(0.60, 0.54, 0.42),
			"modelo": "cardboardBoxClosed"
		},
		{
			"pos": Vector3(-6.2, 0.61, -2.5),
			"tam": Vector3(0.5, 0.40, 0.7),
			"color": Color(0.62, 0.56, 0.44),
			"modelo": "cardboardBoxClosed"
		},
		# La pila del suelo, la que nadie va a mirar nunca.
		{
			"pos": Vector3(3.6, 0.14, 4.2),
			"tam": Vector3(0.42, 0.28, 0.30),
			"color": Color(0.74, 0.72, 0.64)
		},
		{
			"pos": Vector3(4.1, 0.10, 4.3),
			"tam": Vector3(0.40, 0.20, 0.30),
			"color": Color(0.72, 0.70, 0.62)
		},
		{
			"pos": Vector3(3.0, 0.22, 4.2),
			"tam": Vector3(0.34, 0.45, 0.34),
			"color": Color(0.42, 0.41, 0.38),
			"modelo": "trashcan"
		},
		# La máquina de café, junto a la puerta. En una oficina, el sitio donde
		# se cuentan las cosas.
		{
			"pos": Vector3(-6.0, 0.75, 4.2),
			"tam": Vector3(0.7, 1.5, 0.7),
			"color": Color(0.34, 0.33, 0.36)
		},
		{
			"pos": Vector3(-5.6, 0.95, 4.2),
			"tam": Vector3(0.12, 0.35, 0.5),
			"color": Color(0.22, 0.21, 0.24)
		},
		# El tablón de anuncios: papeles de los que no se lee la letra. Uno con
		# un aviso escrito afirmaría algo que nadie ha decidido; así dice «aquí
		# hay avisos» sin mentir. Es la regla de las paredes del sueño.
		{
			"pos": Vector3(-1.5, 1.65, -4.85),
			"tam": Vector3(2.2, 1.1, 0.06),
			"color": Color(0.36, 0.30, 0.24)
		},
		{
			"pos": Vector3(-2.2, 1.75, -4.80),
			"tam": Vector3(0.28, 0.38, 0.02),
			"color": Color(0.86, 0.85, 0.78)
		},
		{
			"pos": Vector3(-1.7, 1.60, -4.80),
			"tam": Vector3(0.24, 0.32, 0.02),
			"color": Color(0.84, 0.83, 0.76)
		},
		{
			"pos": Vector3(-1.1, 1.80, -4.80),
			"tam": Vector3(0.30, 0.24, 0.02),
			"color": Color(0.88, 0.80, 0.62)
		},
		{
			"pos": Vector3(-0.7, 1.55, -4.80),
			"tam": Vector3(0.22, 0.30, 0.02),
			"color": Color(0.86, 0.85, 0.78)
		},
		# El ordenador de su puesto: encendido y sin nada legible hasta que se
		# sienta. Una pantalla con datos afirmaría una lectura que no existe.
		# La pantalla va contra el fondo de la mesa y el teclado al borde de la
		# silla (#564): al revés, quien se sentaba tenía que alcanzar el
		# teclado por detrás del propio monitor.
		{
			"pos": Vector3(-4.0, 0.98, 0.68),
			"tam": Vector3(0.42, 0.36, 0.36),
			"color": Color(0.74, 0.72, 0.66)
		},
		{
			"pos": Vector3(-4.0, 0.98, 0.87),
			"tam": Vector3(0.34, 0.26, 0.02),
			"color": Color(0.30, 0.42, 0.34),
			"emisivo": true
		},
		{
			"pos": Vector3(-4.0, 0.78, 1.35),
			"tam": Vector3(0.44, 0.04, 0.16),
			"color": Color(0.72, 0.70, 0.64)
		},
		# La salida deja de ser una caja de interacción flotante: hay una hoja de
		# puerta física, con marco y manilla. El Area3D conserva destino y rótulo
		# como contrato de tránsito, pero #790 desactiva su proximidad en runtime
		# y coloca sobre él la interacción deliberada que pide confirmación.
		{
			"pos": Vector3(-6.88, 1.05, 3.5),
			"tam": Vector3(0.12, 2.10, 1.28),
			"color": Color(0.30, 0.32, 0.31),
			"rol": "puerta_archivo"
		},
		{
			"pos": Vector3(-6.80, 1.15, 2.78),
			"tam": Vector3(0.18, 2.30, 0.14),
			"color": Color(0.44, 0.45, 0.43),
			"rol": "marco_puerta_archivo"
		},
		{
			"pos": Vector3(-6.80, 1.15, 4.22),
			"tam": Vector3(0.18, 2.30, 0.14),
			"color": Color(0.44, 0.45, 0.43),
			"rol": "marco_puerta_archivo"
		},
		{
			"pos": Vector3(-6.80, 2.30, 3.5),
			"tam": Vector3(0.18, 0.18, 1.58),
			"color": Color(0.44, 0.45, 0.43),
			"rol": "marco_puerta_archivo"
		},
		{
			"pos": Vector3(-6.74, 1.05, 3.08),
			"tam": Vector3(0.08, 0.08, 0.14),
			"color": Color(0.64, 0.60, 0.44),
			"rol": "manilla_puerta_archivo"
		},
	],
	# La luz del archivo es de fluorescente: fría, plana y de más, que es lo
	# que hace que a las tres de la tarde no se sepa qué hora es.
	"ambiente": Color(0.42, 0.43, 0.45),
	"ambiente_energia": 0.55,
	"sol": 0.25,
	"luces":
	[
		{"pos": Vector3(-4, 2.65, -2), "color": Color(0.86, 0.90, 0.92), "energia": 2.2},
		{"pos": Vector3(-4, 2.65, 2), "color": Color(0.86, 0.90, 0.92), "energia": 2.2},
		{"pos": Vector3(2, 2.65, -2), "color": Color(0.86, 0.90, 0.92), "energia": 2.2},
		{"pos": Vector3(2, 2.65, 2), "color": Color(0.86, 0.90, 0.92), "energia": 2.2},
		# El que parpadea no existe todavía; cuando exista, es una entrada más.
		{"pos": Vector3(5.5, 2.65, 0), "color": Color(0.86, 0.90, 0.92), "energia": 1.6},
	],
	# Dónde se sienta cada cual. Su puesto es el de (-4, 1): ese no se ocupa.
	# El primero de la lista es el del cuñado, que está de pie al lado de su
	# mesa porque el cuñado nunca está en la suya.
	# La ventana. Es lo que le da hora al archivo: hasta ahora la única pista de
	# que es tarde llegaba después, en la calle. El cristal va emisivo y en el
	# azul de la noche — desde dentro, una ventana de noche es una superficie
	# que se ve, no un agujero.
	"ventanas":
	[
		{
			"pos": Vector3(-1.5, 1.75, 4.9),
			"tam": Vector3(3.2, 1.5, 0.08),
			"color": Color(0.09, 0.11, 0.20)
		},
		{
			"pos": Vector3(2.6, 1.75, 4.9),
			"tam": Vector3(3.2, 1.5, 0.08),
			"color": Color(0.09, 0.11, 0.20)
		},
	],
	# En la silla de cada mesa, no delante de ella (#565): la silla ya marca
	# el sitio y el lado, y de pie en el otro lado un compañero parecía estar
	# esperando turno para su propio puesto.
	"sitios_companeros":
	# El cuñado, de pie al lado de su mesa. Apartado del punto de entrada:
	[
		# puesto encima, te saludaba antes de que hubieras dado un paso.
		Vector3(-1.9, 0, 0.4),
		Vector3(-4, 0, -0.9),
		# Al lado de su silla y no encima: es quien no trabaja y espera de pie
		# con los brazos cruzados; sobre la silla, esta le atravesaba las piernas.
		Vector3(1.75, 0, -0.9),
		# En su silla, mirando a su mesa como todas las demás: de pie al otro
		# lado, con la puerta a la espalda, su nombre te llegaba antes que su
		# cara.
		Vector3(1, 0, 2.1),
	],
	# Uno en su puesto y otro en el de al lado, que no es suyo y también humea.
	"cigarros": [Vector3(-3.3, 0.76, 1.2), Vector3(1.4, 0.76, -2.1)],
	"salidas":
	[
		{
			"pos": Vector3(-6.4, 1.1, 3.5),
			"destino": "trayecto",
			"rotulo": "SALIDA_OFICINA",
			"visible": false
		},
		# El puesto de trabajo. No lleva a una fase del día: abre una PANTALLA,
		# y se entra en ella pisando el sitio donde se trabaja — igual que se
		# ficha saliendo por la puerta. Un botón flotante diría que el archivo
		# es un menú; el puesto dice que es un sitio.
		{
			"pos": Vector3(-4, 1.1, 1),
			"destino": "expediente",
			"rotulo": "SALIDA_PUESTO",
			"tam": Vector3(2.4, 2.2, 2.2)
		},
	],
}

const CALLE := {
	"rotulo": "SITIO_CALLE",
	"suelo": Vector2(9, 34),
	# Exterior real: el fondo superior lo pinta el cielo, no una losa oscura.
	"techo": false,
	"color_suelo": Color(0.22, 0.22, 0.23),
	"color_muro": Color(0.30, 0.29, 0.30),
	"textura_suelo": "asfalto",
	"textura_muro": "gotele",
	"entrada": Vector3(0, 0, -15),
	# Se entra por un extremo y el portal está en el otro: hay que mirar hacia
	# donde se anda.
	"mirada": 180.0,
	"bultos":
	[
		{
			"pos": Vector3(-3.2, 1.4, -6),
			"tam": Vector3(1.2, 2.8, 4.0),
			"color": Color(0.26, 0.25, 0.26)
		},
		{
			"pos": Vector3(3.2, 1.4, 1),
			"tam": Vector3(1.2, 2.8, 6.0),
			"color": Color(0.26, 0.25, 0.26)
		},
		{
			"pos": Vector3(-3.2, 1.4, 8),
			"tam": Vector3(1.2, 2.8, 5.0),
			"color": Color(0.26, 0.25, 0.26)
		},
	],
	"pantallas":
	[
		{
			"pos": Vector3(-3.75, 1.75, -8.0),
			"tam": Vector2(1.15, 0.72),
			"giro": 90.0,
			"semilla": 1.0
		},
		{
			"pos": Vector3(-3.75, 1.75, -2.8),
			"tam": Vector2(1.15, 0.72),
			"giro": 90.0,
			"semilla": 2.0
		},
		{
			"pos": Vector3(-3.75, 1.75, 2.4),
			"tam": Vector2(1.15, 0.72),
			"giro": 90.0,
			"semilla": 3.0
		},
		{
			"pos": Vector3(3.75, 1.75, -5.4),
			"tam": Vector2(1.15, 0.72),
			"giro": -90.0,
			"semilla": 4.0
		},
		{
			"pos": Vector3(3.75, 1.75, -0.2),
			"tam": Vector2(1.15, 0.72),
			"giro": -90.0,
			"semilla": 5.0
		},
		{
			"pos": Vector3(3.75, 1.75, 5.0),
			"tam": Vector2(1.15, 0.72),
			"giro": -90.0,
			"semilla": 6.0
		},
	],
	"ambiente": Color(0.16, 0.17, 0.22),
	"ambiente_energia": 0.35,
	"sol": 0.08,
	# Farolas de sodio: naranjas, separadas, y con oscuridad de verdad entre
	# una y otra. Es lo que hace que la calle se ande y no se cruce.
	"luces":
	[
		{
			"pos": Vector3(0, 2.6, -10),
			"color": Color(1.0, 0.72, 0.38),
			"energia": 3.0,
			"alcance": 11.0,
			"tam": Vector3(0.5, 0.12, 0.5)
		},
		{
			"pos": Vector3(0, 2.6, 0),
			"color": Color(1.0, 0.72, 0.38),
			"energia": 3.0,
			"alcance": 11.0,
			"tam": Vector3(0.5, 0.12, 0.5)
		},
		{
			"pos": Vector3(0, 2.6, 10),
			"color": Color(1.0, 0.72, 0.38),
			"energia": 3.0,
			"alcance": 11.0,
			"tam": Vector3(0.5, 0.12, 0.5)
		},
	],
	"salidas":
	[
		{"pos": Vector3(0, 1.1, 15.5), "destino": "casa", "rotulo": "SALIDA_PORTAL"},
	],
}

const CASA := {
	"rotulo": "SITIO_CASA",
	# Crece hacia la cocina y la entrada (#785): el dormitorio, la ventana y el
	# muro izquierdo siguen donde estaban, así que sus anclas no se mueven.
	# Paredes: x de -4 a 5,5 y z de -3,5 a 4,5.
	"suelo": Vector2(9.5, 8),
	"centro_suelo": Vector2(0.75, 0.5),
	"color_suelo": Color(0.32, 0.27, 0.22),
	"color_muro": Color(0.52, 0.47, 0.42),
	# En casa la luz es de bombilla, no de fluorescente: más cálida y más floja.
	"color_techo": Color(0.62, 0.54, 0.42),
	"textura_suelo": "moqueta",
	"textura_muro": "gotele",
	"entrada": Vector3(0.5, 0, 3.4),
	"bultos":
	[
		# La cama, que es la salida del día.
		{
			"pos": Vector3(-2.4, 0.28, -2),
			"tam": Vector3(1.4, 0.55, 2.2),
			"color": Color(0.40, 0.33, 0.30)
		},
		# El cuenco del gato. Vacío mientras no se compre comida.
		{
			"pos": Vector3(2.8, 0.05, 1.5),
			"tam": Vector3(0.3, 0.1, 0.3),
			"color": Color(0.55, 0.50, 0.20)
		},
		# La televisión, apagada. Es el mismo aparato en el que #140 quiere
		# proyectar una cinta ante un jurado, y aquí está en casa sin encender:
		# que sea el MISMO modelo es lo que hará que esa escena se reconozca.
		{
			"pos": Vector3(-3.55, 0.895, 1.35),
			"tam": Vector3(0.85, 0.75, 0.6),
			"color": Color(0.38, 0.34, 0.30),
			"modelo": "televisionVintage"
		},
		{
			"pos": Vector3(5.05, 0.22, 4.15),
			"tam": Vector3(0.34, 0.45, 0.34),
			"color": Color(0.40, 0.38, 0.34),
			"modelo": "trashcan"
		},
	],
	"ambiente": Color(0.30, 0.26, 0.22),
	"ambiente_energia": 0.45,
	"sol": 0.10,
	# Una bombilla. No hay más luz en casa, y eso es parte de lo que se cuenta.
	"luces":
	[
		{
			"pos": Vector3(0.75, 2.5, 0.5),
			"color": Color(1.0, 0.84, 0.62),
			"energia": 2.6,
			"alcance": 10.0,
			"tam": Vector3(0.22, 0.22, 0.22)
		},
	],
	# Por dónde anda el gato. El PRIMERO sigue siendo el cuenco: es donde se
	# queda cuando lleva días sin comer (#92). Desde #787 cada punto puede
	# declarar además una affordance; GatoConducta conserva compatibilidad con
	# Vector3 simples para que el mismo gato siga funcionando en el sueño.
	"sitios_gato":
	[
		{"pos": Vector3(2.8, 0, 1.5), "rutina": "cuenco"},
		{"pos": Vector3(-2.4, 0, -0.6), "rutina": "dormir"},
		{"pos": Vector3(0.6, 0, 2.1), "rutina": "sentarse"},
		{"pos": Vector3(2.9, 0, -2.9), "rutina": "esconderse"},
		{"pos": Vector3(-3.2, 0, 2.4), "rutina": "observar"},
	],
	# El de casa está en la mesa del comedor, encendido y solo. Nadie lo ha apagado.
	"cigarros": [Vector3(1.7, 0.77, -1.0)],
	"salidas":
	[
		{
			"pos": Vector3(-2.4, 0.9, -2),
			"destino": "sueño",
			"rotulo": "SALIDA_DORMIR",
			"tam": Vector3(1.6, 1.2, 2.4)
		},
		# El cuenco es de los sitios que se pisan y NO llevan a otra parte: se
		# sigue estando en casa. Darle de comer es acercarse, como todo lo
		# demás en este juego — no hay menú ni inventario.
		{
			"pos": Vector3(2.8, 0.6, 1.5),
			"destino": "cuenco",
			"rotulo": "SALIDA_CUENCO",
			"tam": Vector3(1.2, 1.2, 1.2)
		},
	],
}

## El sueño NO está aquí, y esa ausencia es el issue #86.
##
## Los sitios del día son uno por fase y siempre el mismo. El sueño son tres
## escenas distintas cada noche, elegidas por lo que se leyó ese día, así que
## no se puede declarar: se compone. Vive en `Sueno` y en `SuenoFormas`, y
## quien pinta el día se lo pide en vez de buscarlo en esta tabla.

const POR_FASE := {
	"archivo": OFICINA,
	"trayecto": CALLE,
	"casa": CASA,
}


static func de_fase(fase: String) -> Dictionary:
	return POR_FASE.get(fase, OFICINA)
