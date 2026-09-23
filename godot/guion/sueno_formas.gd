## Las salas del sueño, declaradas.
##
## Pocas y GRANDES (#86): el sueño no es un laberinto de cuartos encadenados
## sino unos pocos sitios amplios y mal hechos donde uno se pierde de verdad.
## Por eso son pocas y no cincuenta, y por eso ninguna es un rectángulo — una
## sala rara no es una caja más grande, que es exactamente lo que `Espacio3D`
## sabía construir hasta ahora.
##
## Todo va en CELDAS de `Planta`. Nadie escribe aquí un muro ni una medida en
## metros: la geometría sale del contorno de los bloques, así que una forma es
## literalmente su silueta y no se puede quedar con un lado abierto.
##
## Lo que NO hay aquí es contenido. De qué está hecho un sueño —los documentos
## que leíste convertidos en salas, los sospechosos como figuras, las frases
## gatillo en las paredes— es #87, y meterlo antes de tiempo llenaría estas
## salas de cosas sin original detrás, que es justo lo que #79 prohíbe.
## La luz: el sueño es oscuro, pero un sitio que no se lee no da miedo, no se
## ve. Los tonos van bajos y sin saturar y aun así por encima del punto en el
## que una sala se convierte en una silueta negra — y el techo va CLARO por lo
## mismo que en la oficina: su cara de abajo está siempre en el mínimo, así que
## un techo oscuro no es oscuro, es un agujero encima de tu cabeza.
## Y el encuadre: se entra mirando hacia -z, que es a donde mira la cámara del
## caminante cuando no se la ha girado. Por eso las entradas están al fondo del
## eje largo de cada sala y no en cualquier celda de dentro: aparecer a dos
## metros de un muro convierte una nave en un armario hasta que giras.
## **De qué está hecha una sala del sueño**: de lo mismo que el archivo, mal
## (#127). El linóleo estirado hasta que una plancha mide quince metros, las
## planchas del techo puestas en el suelo, el gotelé a una escala que no existe.
## No hay ni una textura nueva — todas salen de `TexturaProcedural`, que es la
## que viste la oficina, cambiando el tamaño al que se repiten. Un sueño con
## texturas propias sería otro sitio; con las de tu trabajo a escalas
## imposibles es tu trabajo, y esa es la diferencia que persigue #79.
## #399 añade además un warp por ejes: la misma trama puede quedar aplastada,
## estirada o espejada en X/Z. El material sigue siendo reconocible, pero deja
## de obedecer la escala física del mundo despierto.
##
## Y **la luz viene de algún sitio**. Antes el techo era emisivo y punto: todo
## se veía igual de lejos que de cerca, que es lo contrario de un sitio donde
## hay que buscar la salida (#90). Ahora cada sala tiene UNA fuente lejana y de
## su propio color, así que hay una dirección hacia la que se ve mejor. Lo que
## NO se ha hecho, porque es una decisión de juego y no de arte, es que la luz
## te siga: eso cambiaría por completo cómo se busca a ciegas.
class_name SuenoFormas
extends RefCounted

## Cuántas celdas tiene que medir una sala para contar como grande. Con la
## celda a dos metros son unos 240 m²: una nave, no un despacho.
const MINIMO_GRANDE := 60

## La única fuente espacial de cada forma debe alcanzar suficiente superficie
## para revelar la trama conocida sin eliminar el gradiente de oscuridad.
const ENERGIA_LUZ_MATERIAL := 4.4
const ALCANCE_LUZ_MATERIAL := 19.0
## La trama procedural de vigilia es sutil a propósito. Deformada y filtrada
## necesita más separación antes de caer en los 32 niveles del shader PSX.
const CONTRASTE_MATERIAL_ONIRICO := 2.0

const FORMAS := {
	# Id histórico conservado por compatibilidad (#798). La cruz original deja
	# de definir tanto la planta lógica como la arquitectura visible: el recorrido
	# de celdas solo mantiene timing/mapa y la sala real usa la familia fragmentada.
	"crucero":
	{
		"rotulo": "SUENO_ROTULO",
		"bloques":
		[
			Rect2i(0, 0, 12, 8),
			Rect2i(6, 6, 12, 8),
			Rect2i(2, 12, 10, 6),
		],
		"familia_poligonal": SuenoFamilias.FRAGMENTADA,
		"textura_suelo": "linoleo",
		"textura_muro": "gotele",
		"escala_textura": 7.5,
		"deformacion_textura": Vector3(3.6, 0.45, 0.72),
		"contraste_textura": CONTRASTE_MATERIAL_ONIRICO,
		"preservar_detalle_textura": true,
		"ambiente": Color(0.20, 0.19, 0.26),
		"ambiente_energia": 0.42,
		"sol": 0.05,
		"luces":
		[
			{
				"pos": Vector3(0, 2.4, -12),
				"color": Color(0.55, 0.52, 0.78),
				"energia": ENERGIA_LUZ_MATERIAL,
				"alcance": ALCANCE_LUZ_MATERIAL,
				"tam": Vector3(0.5, 0.1, 0.5)
			}
		],
		"entrada": Vector2i(5, 16),
		"color_suelo": Color(0.26, 0.24, 0.30),
		"color_muro": Color(0.33, 0.30, 0.39),
		"color_techo": Color(0.19, 0.17, 0.22),
	},
	# Un anillo alrededor de un patio al que no se entra. Desde #279 la forma
	# lógica de celdas se conserva para timing/mapa, mientras la arquitectura
	# visible y física usa la familia cóncava ANULAR con vacío central real.
	# #284 reutiliza esa misma familia como primer castillo jugable: la forma
	# declara la identidad y el estado inicial, mientras `Sueno.espacio()`
	# conserva el contenido conocido y delega solo la presentación al adaptador.
	"patio":
	{
		"rotulo": "SUENO_ROTULO",
		"bloques":
		[
			Rect2i(0, 0, 18, 3),
			Rect2i(0, 15, 18, 3),
			Rect2i(0, 0, 3, 18),
			Rect2i(15, 0, 3, 18),
		],
		"familia_poligonal": SuenoFamilias.ANULAR,
		"identidad_onirica": SuenoCastillo.ID,
		"estado_presentacion": {"vuelta_castillo": 1, "semilla_castillo": 0},
		"textura_suelo": "techo",
		"textura_muro": "gotele",
		"escala_textura": 0.55,
		"deformacion_textura": Vector3(-0.65, 2.8, 1.35),
		"contraste_textura": CONTRASTE_MATERIAL_ONIRICO,
		"preservar_detalle_textura": true,
		"ambiente": Color(0.22, 0.21, 0.20),
		"ambiente_energia": 0.42,
		"sol": 0.04,
		# En el CORREDOR, no en el patio: puesta en el centro geométrico caía
		# en el hueco al que no se entra, iluminando un sitio donde no hay
		"luces":
		[
			# nadie y dejando la sala entera a oscuras.
			{
				"pos": Vector3(-15, 2.4, 6),
				"color": Color(0.78, 0.74, 0.62),
				"energia": ENERGIA_LUZ_MATERIAL,
				"alcance": ALCANCE_LUZ_MATERIAL,
				"tam": Vector3(0.6, 0.1, 0.6)
			}
		],
		"entrada": Vector2i(1, 16),
		"color_suelo": Color(0.28, 0.27, 0.26),
		"color_muro": Color(0.35, 0.34, 0.32),
		"color_techo": Color(0.17, 0.16, 0.15),
	},
	# El archivo, si el archivo fuera infinito a lo ancho: un pasillo larguísimo
	# con estanterías que son salas.
	"peine":
	{
		"rotulo": "SUENO_ROTULO",
		"bloques":
		[
			Rect2i(0, 0, 26, 4),
			Rect2i(2, 4, 4, 9),
			Rect2i(11, 4, 4, 9),
			Rect2i(20, 4, 4, 9),
		],
		"textura_suelo": "linoleo",
		"textura_muro": "linoleo",
		"escala_textura": 3.2,
		"deformacion_textura": Vector3(0.38, 0.62, 4.4),
		"contraste_textura": CONTRASTE_MATERIAL_ONIRICO,
		"preservar_detalle_textura": true,
		"ambiente": Color(0.22, 0.20, 0.17),
		"ambiente_energia": 0.42,
		"sol": 0.05,
		"luces":
		[
			{
				"pos": Vector3(-20, 2.4, 0),
				"color": Color(0.85, 0.70, 0.45),
				"energia": ENERGIA_LUZ_MATERIAL,
				"alcance": ALCANCE_LUZ_MATERIAL,
				"tam": Vector3(0.4, 0.1, 0.4)
			}
		],
		"entrada": Vector2i(3, 11),
		"color_suelo": Color(0.27, 0.24, 0.20),
		"color_muro": Color(0.37, 0.33, 0.27),
		"color_techo": Color(0.19, 0.17, 0.13),
	},
	# Salas que se desbordan una en otra en diagonal. Se anda siempre torcido.
	"escalera":
	{
		"rotulo": "SUENO_ROTULO",
		"bloques": [Rect2i(0, 0, 10, 6), Rect2i(7, 5, 10, 6), Rect2i(14, 10, 10, 6)],
		"textura_suelo": "moqueta",
		"textura_muro": "gotele",
		"escala_textura": 5.0,
		"deformacion_textura": Vector3(2.7, 0.33, -1.15),
		"contraste_textura": CONTRASTE_MATERIAL_ONIRICO,
		"preservar_detalle_textura": true,
		"ambiente": Color(0.17, 0.20, 0.24),
		"ambiente_energia": 0.42,
		"sol": 0.06,
		"luces":
		[
			{
				"pos": Vector3(10, 2.4, 8),
				"color": Color(0.55, 0.75, 0.85),
				"energia": ENERGIA_LUZ_MATERIAL,
				"alcance": ALCANCE_LUZ_MATERIAL,
				"tam": Vector3(0.5, 0.1, 0.5)
			}
		],
		"entrada": Vector2i(15, 14),
		"color_suelo": Color(0.20, 0.24, 0.28),
		"color_muro": Color(0.27, 0.32, 0.37),
		"color_techo": Color(0.14, 0.17, 0.19),
	},
	# Una nave enorme que se estrecha hasta un cuello y se vuelve a abrir. Se
	# ve el final desde el principio y aun así hay que rodear. Desde #279 esta
	# es además la primera forma que deja de ser ortogonal en runtime: la planta
	# se conserva como contrato lógico/timing, y la arquitectura visible/física
	# usa la familia poligonal declarada aquí.
	"embudo":
	{
		"rotulo": "SUENO_ROTULO",
		"bloques": [Rect2i(0, 0, 16, 9), Rect2i(6, 9, 4, 4), Rect2i(2, 13, 12, 7)],
		"familia_poligonal": SuenoFamilias.CONVERGENTE,
		"textura_suelo": "asfalto",
		"textura_muro": "gotele",
		"escala_textura": 0.35,
		"deformacion_textura": Vector3(-0.52, 3.1, 4.2),
		"contraste_textura": CONTRASTE_MATERIAL_ONIRICO,
		"preservar_detalle_textura": true,
		"ambiente": Color(0.24, 0.18, 0.18),
		"ambiente_energia": 0.42,
		"sol": 0.05,
		"luces":
		[
			{
				"pos": Vector3(0, 2.4, 6),
				"color": Color(0.90, 0.45, 0.35),
				"energia": ENERGIA_LUZ_MATERIAL,
				"alcance": ALCANCE_LUZ_MATERIAL,
				"tam": Vector3(0.5, 0.1, 0.5)
			}
		],
		"entrada": Vector2i(8, 18),
		"color_suelo": Color(0.30, 0.23, 0.23),
		"color_muro": Color(0.37, 0.27, 0.27),
		"color_techo": Color(0.18, 0.13, 0.13),
	},
	# Variante monumental inspirada en Gilgamesh. Conserva el rótulo genérico
	# del sueño para no introducir una clave de localización sin catálogo.
	"gilgamesh":
	{
		"rotulo": "SUENO_ROTULO",
		"bloques":
		[
			Rect2i(0, 5, 22, 6),
			Rect2i(8, 0, 6, 16),
		],
		"textura_suelo": "linoleo",
		"textura_muro": "gotele",
		"escala_textura": 7.5,
		"deformacion_textura": Vector3(5.2, 0.28, -0.58),
		"contraste_textura": CONTRASTE_MATERIAL_ONIRICO,
		"preservar_detalle_textura": true,
		"ambiente": Color(0.20, 0.19, 0.26),
		"ambiente_energia": 0.42,
		"sol": 0.05,
		"luces":
		[
			{
				"pos": Vector3(0, 2.4, -12),
				"color": Color(0.55, 0.52, 0.78),
				"energia": ENERGIA_LUZ_MATERIAL,
				"alcance": ALCANCE_LUZ_MATERIAL,
				"tam": Vector3(0.5, 0.1, 0.5)
			}
		],
		"entrada": Vector2i(11, 14),
		"color_suelo": Color(0.26, 0.24, 0.30),
		"color_muro": Color(0.33, 0.30, 0.39),
		"color_techo": Color(0.19, 0.17, 0.22),
	},
}


static func ids() -> Array:
	var lista := FORMAS.keys()
	lista.sort()
	return lista


static func de(id: String) -> Dictionary:
	return FORMAS.get(id, FORMAS[ids()[0]])
