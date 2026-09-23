## Reasignación: salir del puesto y empezar otra vida laboral.
##
## Cuando esta escena empieza, `Acusacion.perder_vida` ya ha aplicado y guardado
## el cambio de vuelta. La cinemática no reinicia nada: enseña que la persona
## sale, que el expediente firmado se queda en la mesa y que lo personal cruza
## a la vida siguiente.
##
## Desde #899 rueda en 3D, como pidió #395: la mesa del archivo que ya se vio
## en el sello, el pasillo de la oficina y la casa. Se reproduce sobre el visor,
## que no tiene sala detrás, así que cada plano trae su `decorado`.
class_name DespidoCinematica
extends RefCounted

const ID := "despido-reasignacion"

const PAPEL := Color("dedbd2")
const TINTA := Color("3e3e42")
const CARPETA := Color("81745f")
const BORDE := Color("50483c")
const FIGURA := Color("77736b")
const ESCOLTA := Color("4b4b4b")
const MADERA := Color("6b5442")
const LUZ_CALLE := Color("e8e2cf")

## Dónde queda la carpeta sellada: el mismo sitio de la mesa en el que se selló.
const CARPETA_POS := SelloCinematica.A7

## Hacia dónde camina la salida: una puerta con la luz de fuera, al fondo.
const PUERTA := Vector3(0.0, 1.1, -5.9)

## La credencial nueva, sobre la mesa de casa.
const CREDENCIAL := Vector3(0.05, MesaCinematica.TABLERO, 0.1)


## `gato_presente` solo decide si aparece el gato que recuerda que sigue siendo
## tuyo; si ya se había ido, la escena no lo resucita visualmente.
## `voz_cunado` es una CLAVE de traducción y solo aparece durante la salida: el
## cuñado es la única persona que rompe el silencio del despido (#81).
static func planos_de(gato_presente: bool, vistas: int = 0, voz_cunado: String = "") -> Array:
	var rodaje := planos(gato_presente)
	rodaje[1]["voz"] = voz_cunado
	return Cinematica.resolver(rodaje, {}, vistas)


## Variante de cierre para #100/#150. Conserva `planos_de()` para llamadas
## antiguas y añade el informe que EvaluacionDesempeno selló ANTES del reset.
## No usa el resto de RemateVidaCinematica aquí: dinero, alquiler y mapa ya
## pertenecen a la vida nueva. El gato sí es continuidad real entre vueltas.
static func planos_con_remate(
	estado: Dictionary, vistas: int = 0, voz_cunado: String = ""
) -> Array:
	var resumen := RemateVida.resumir(estado)
	var planos := planos_de(bool(resumen["gato_presente"]), vistas, voz_cunado)
	planos.append_array(EvaluacionDesempenoCinematica.planos_de(estado, vistas))
	return planos


## Orientar -> acción -> residuo (#856): el puesto que se queda, la salida y
## lo que llega a la mañana siguiente.
static func planos(gato_presente: bool) -> Array:
	var carpeta := CARPETA_POS + Vector3(0, 0.03, 0)
	var credencial := CREDENCIAL + Vector3(0, 0.02, 0)
	return [
		{
			# La carpeta sellada permanece físicamente en el puesto y la silla
			# se queda apartada: cambia la persona, no el veredicto firmado.
			"tipo": "3d",
			"nombre": "puesto",
			"decorado": _puesto_que_queda(),
			"camara_desde": Vector3(0.55, 1.2, 0.75),
			"mira_desde": carpeta,
			"camara": Vector3(0.35, 1.7, 1.75),
			"mira": Vector3(0.1, 0.7, 0.3),
			"segundos": 2.2,
		},
		{
			# Dos figuras escoltan a la persona hacia la puerta. No hay
			# celebración ni caída: la misma composición sirve como castigo y,
			# tras perder la casa, como alivio.
			"tipo": "3d",
			"nombre": "salida",
			"decorado": _pasillo_de_salida(),
			"camara_desde": Vector3(0.0, 1.6, 3.4),
			"mira_desde": Vector3(0.0, 1.2, -4.0),
			"camara": Vector3(0.0, 1.5, 1.6),
			"mira": PUERTA,
			"segundos": 2.6,
		},
		{
			# Una credencial limpia sobre la mesa de casa. El gato solo está si
			# seguía antes del despido: es continuidad personal, no laboral.
			"tipo": "3d",
			"nombre": "nuevo-dia",
			"decorado": _nuevo_dia(gato_presente),
			"camara_desde": Vector3(0.5, 1.25, 0.6),
			"mira_desde": credencial,
			"camara": Vector3(0.75, 1.55, 1.35),
			"mira": credencial + Vector3(0.2, 0, 0),
			"segundos": 2.4,
		},
	]


static func _puesto_que_queda() -> Dictionary:
	var decorado := (
		MesaCinematica
		. con(
			[
				MesaCinematica.pieza(CARPETA_POS.x, CARPETA_POS.z, Vector3(0.38, 0.03, 0.5), BORDE),
				MesaCinematica.pieza(
					CARPETA_POS.x, CARPETA_POS.z, Vector3(0.36, 0.004, 0.48), CARPETA, 0.03
				),
				MesaCinematica.pieza(
					CARPETA_POS.x, CARPETA_POS.z + 0.1, Vector3(0.13, 0.002, 0.07), TINTA, 0.034
				),
			]
		)
	)
	# La silla, retirada de la mesa y vacía.
	(
		decorado["bultos"]
		. append(
			{
				"pos": Vector3(0.45, 0.45, 0.95),
				"tam": Vector3(0.55, 0.9, 0.55),
				"color": Color(0.30, 0.30, 0.32),
				"modelo": "chairDesk",
			}
		)
	)
	return decorado


## El pasillo de la planta con las texturas del archivo y, al fondo, la
## puerta que da a la escalera, encendida con la luz de fuera.
static func _pasillo_de_salida() -> Dictionary:
	var oficina := EspaciosCatalogo.OFICINA
	return {
		"suelo": Vector2(3, 12),
		"color_suelo": oficina["color_suelo"],
		"color_muro": oficina["color_muro"],
		"color_techo": oficina["color_techo"],
		"textura_suelo": oficina["textura_suelo"],
		"textura_muro": oficina["textura_muro"],
		"textura_techo": oficina["textura_techo"],
		"bultos":
		[
			{"pos": PUERTA, "tam": Vector3(1.1, 2.2, 0.1), "color": LUZ_CALLE, "emisivo": true},
		],
		"figuras":
		[
			_de_espaldas(Vector3(0.0, 0.0, -1.9), FIGURA),
			_de_espaldas(Vector3(-0.65, 0.0, -1.6), ESCOLTA),
			_de_espaldas(Vector3(0.65, 0.0, -1.6), ESCOLTA),
		],
		"luces":
		[
			{"pos": Vector3(0, 2.3, 0.5), "color": Color(0.90, 0.92, 0.86), "energia": 0.8},
			{"pos": Vector3(0, 2.0, -5.2), "color": LUZ_CALLE, "energia": 1.6},
		],
	}


## Alguien que camina hacia la puerta: se le ve la espalda, no la cara.
static func _de_espaldas(pos: Vector3, color: Color) -> Dictionary:
	return {"pos": pos, "color": color, "modelo": Companeros.CUERPO, "giro": PI}


## La mesa de casa por la mañana, con los colores y texturas de la casa.
static func _nuevo_dia(gato_presente: bool) -> Dictionary:
	var casa := EspaciosCatalogo.CASA
	var mesa := MesaCinematica.TABLERO
	var decorado := {
		"suelo": Vector2(4, 4),
		"color_suelo": casa["color_suelo"],
		"color_muro": casa["color_muro"],
		"color_techo": casa["color_techo"],
		"textura_suelo": casa["textura_suelo"],
		"textura_muro": casa["textura_muro"],
		"bultos":
		[
			{
				"pos": Vector3(0, mesa / 2.0, 0),
				"tam": Vector3(1.6, mesa, 0.85),
				"color": MADERA,
				"modelo": "household_goods/dine_table_01",
			},
			{
				"pos": Vector3(-0.35, 0.47, 0.65),
				"tam": Vector3(0.45, 0.94, 0.53),
				"color": MADERA,
				"modelo": "household_goods/chair_01",
			},
			MesaCinematica.pieza(CREDENCIAL.x, CREDENCIAL.z, Vector3(0.24, 0.006, 0.16), PAPEL),
		],
		"luces":
		[
			{"pos": Vector3(-0.6, 2.2, 0.9), "color": Color(0.98, 0.90, 0.74), "energia": 1.7},
		],
	}
	for i in 3:
		decorado["bultos"].append(
			MesaCinematica.pieza(
				CREDENCIAL.x - 0.03 + 0.02 * float(i % 2),
				CREDENCIAL.z - 0.04 + 0.04 * i,
				Vector3(0.14 - 0.04 * float(i % 2), 0.002, 0.012),
				TINTA,
				0.006
			)
		)
	if gato_presente:
		decorado["gatos"] = [
			{"pos": Vector3(0.42, mesa, -0.05), "giro": -0.6, "pose": "durmiendo"},
		]
	return decorado
