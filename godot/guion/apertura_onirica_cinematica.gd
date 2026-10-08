## Montaje original de apertura: la oficina, la ciudad y la casa dejan de ser
## lugares continuos y parecen recuerdos incompatibles de la misma noche.
##
## Tras las dos citas y ANTES de los creditos existentes. No cita escenas ni
## emplea material audiovisual de otras obras. No dibuja figuras geometricas
## nuevas: reutiliza los decorados 3D, texturas, iluminacion y lenguaje de cine.
## Los cortes, el focal, el silencio y la reiteracion producen la inquietud.
class_name AperturaOniricaCinematica
extends RefCounted

const ID := "montaje-onirico-1998"
const DURACION_OBJETIVO_MIN := 70.0
const DURACION_OBJETIVO_MAX := 110.0


static func planos() -> Array:
	var tomas: Array = []

	# MOVIMIENTO I: LA RUTINA. La aparente normalidad se observa demasiado cerca.
	_agregar(
		tomas,
		"00:07:03",
		"La primera ficha",
		"oficina",
		5.0,
		Vector3(-1.5, 1.65, 3.2),
		Vector3(-4.0, 1.0, 1.0),
		Vector3(-3.1, 1.42, 2.4),
		Vector3(-4.0, 0.97, 0.7),
		35.0,
		0.45,
		0.0
	)
	_agregar(
		tomas,
		"REGISTRO",
		"Alguien ha encendido el terminal",
		"oficina",
		3.8,
		Vector3(-4.0, 1.65, 2.5),
		Vector3(-4.3, 1.0, 1.0),
		Vector3(-4.0, 1.15, 1.5),
		Vector3(-4.3, 0.96, 0.9),
		21.0
	)
	_agregar(
		tomas,
		"14 DE OCTUBRE",
		"No consta el año",
		"oficina",
		1.3,
		Vector3(4.0, 1.85, 2.2),
		Vector3(5.5, 1.0, -1.0),
		Vector3(5.0, 1.55, 1.2),
		Vector3(5.5, 1.0, -1.0),
		45.0
	)
	_agregar(
		tomas,
		"SIN TESTIGOS",
		"",
		"oficina",
		2.2,
		Vector3(-0.7, 1.42, 1.5),
		Vector3(-1.5, 1.7, -4.8),
		Vector3(-0.7, 1.42, 1.5),
		Vector3(-1.5, 1.7, -4.8),
		18.0
	)

	# MOVIMIENTO II: LA CALLE. La ciudad parece observar la misma habitacion.
	_agregar(
		tomas,
		"FRECUENCIA 98",
		"La ciudad escucha",
		"calle",
		4.8,
		Vector3(-1.8, 1.65, -13.0),
		Vector3(-3.5, 1.8, -8.0),
		Vector3(-1.3, 1.55, -8.4),
		Vector3(-3.6, 1.75, -7.0),
		34.0,
		0.0,
		0.20
	)
	_agregar(
		tomas,
		"¿QUIÉN EMITE?",
		"",
		"calle",
		1.4,
		Vector3(0.2, 1.6, -4.9),
		Vector3(-3.6, 1.75, -2.8),
		Vector3(0.1, 1.6, -4.7),
		Vector3(-3.6, 1.75, -2.8),
		24.0
	)
	_agregar(
		tomas,
		"REPETICIÓN",
		"Un rostro que nunca se ve",
		"calle",
		3.0,
		Vector3(1.1, 1.6, 0.9),
		Vector3(3.5, 1.75, -0.2),
		Vector3(2.0, 1.5, 1.3),
		Vector3(3.5, 1.75, -0.2),
		52.0
	)
	_agregar(
		tomas,
		"REPETICIÓN",
		"",
		"calle",
		0.9,
		Vector3(-0.2, 1.55, -4.9),
		Vector3(-3.6, 1.8, -2.8),
		Vector3(-0.2, 1.55, -4.9),
		Vector3(-3.6, 1.8, -2.8),
		16.0,
		0.64,
		0.0
	)
	_agregar(
		tomas,
		"NO HAY SEÑAL",
		"La calle sigue encendida",
		"calle",
		5.2,
		Vector3(0.3, 1.55, -10.5),
		Vector3(0.0, 1.2, 5.0),
		Vector3(0.0, 1.55, -1.0),
		Vector3(0.0, 1.2, 10.0),
		42.0,
		0.0,
		0.35
	)

	# MOVIMIENTO III: EL ARCHIVO COMO SUENO. Sin un monstruo visible, el archivo
	# ya parece una criatura que respira entre puertas, sillas y expedientes.
	_agregar(
		tomas,
		"ARCHIVO / NIVEL -1",
		"Nadie sabe quien construyo este sitio",
		"oficina",
		4.4,
		Vector3(5.0, 1.55, 3.6),
		Vector3(5.5, 0.96, -3.0),
		Vector3(4.2, 1.4, 1.4),
		Vector3(5.5, 0.96, -3.0),
		21.0
	)
	_agregar(
		tomas,
		"LA CUARTA SILLA",
		"",
		"oficina",
		1.0,
		Vector3(1.1, 1.4, 3.4),
		Vector3(1.0, 0.6, 2.1),
		Vector3(1.0, 1.2, 2.6),
		Vector3(1.0, 0.6, 2.1),
		18.0
	)
	_agregar(
		tomas,
		"LA CUARTA SILLA",
		"Estaba vacia antes",
		"oficina",
		3.9,
		Vector3(2.8, 1.65, 2.6),
		Vector3(1.0, 0.6, 2.1),
		Vector3(1.3, 1.48, 2.9),
		Vector3(1.0, 0.6, 2.1),
		28.0
	)
	_agregar(
		tomas,
		"1998",
		"",
		"oficina",
		0.8,
		Vector3(-2.5, 1.60, 0.0),
		Vector3(-4.3, 1.0, -2.1),
		Vector3(-2.5, 1.60, 0.0),
		Vector3(-4.3, 1.0, -2.1),
		58.0,
		0.90,
		0.05
	)
	_agregar(
		tomas,
		"1998",
		"1998",
		"calle",
		0.9,
		Vector3(-1.7, 1.65, -9.2),
		Vector3(-3.6, 1.8, -8.0),
		Vector3(-1.7, 1.65, -9.2),
		Vector3(-3.6, 1.8, -8.0),
		22.0
	)
	_agregar(
		tomas,
		"1998",
		"1998",
		"casa",
		1.0,
		Vector3(2.6, 1.62, 3.1),
		Vector3(-1.1, 0.9, -0.8),
		Vector3(2.6, 1.62, 3.1),
		Vector3(-1.1, 0.9, -0.8),
		50.0
	)

	# MOVIMIENTO IV: LA CASA. Un lugar intimo con la continuidad rota.
	_agregar(
		tomas,
		"ALGUIEN HA REGRESADO",
		"No recuerda haber salido",
		"casa",
		5.8,
		Vector3(2.7, 1.65, 3.3),
		Vector3(-1.1, 0.95, -0.8),
		Vector3(1.5, 1.52, 1.9),
		Vector3(-2.4, 0.7, -2.0),
		32.0
	)
	_agregar(
		tomas,
		"EL OJO DE LA CASA",
		"",
		"casa",
		2.1,
		Vector3(-1.9, 1.63, -0.4),
		Vector3(1.0, 1.1, 1.6),
		Vector3(-1.5, 1.62, -0.3),
		Vector3(1.0, 1.1, 1.6),
		21.0
	)
	_agregar(
		tomas,
		"NO ABRAS",
		"La puerta esta al otro lado",
		"casa",
		4.6,
		Vector3(-0.8, 1.65, 2.8),
		Vector3(0.0, 1.1, -2.7),
		Vector3(0.1, 1.6, 0.9),
		Vector3(0.0, 1.1, -2.7),
		38.0,
		0.0,
		0.54
	)
	_agregar(
		tomas,
		"LOS NOMBRES",
		"No hay ninguno en el expediente",
		"oficina",
		2.2,
		Vector3(2.8, 1.6, 2.8),
		Vector3(5.5, 0.9, 0.5),
		Vector3(1.8, 1.56, 2.5),
		Vector3(5.5, 0.9, 0.5),
		65.0
	)
	_agregar(
		tomas,
		"LA CIUDAD",
		"Queda encendida hasta el amanecer",
		"calle",
		4.8,
		Vector3(0.0, 1.62, 10.0),
		Vector3(0.0, 1.2, -10.0),
		Vector3(0.0, 1.58, 4.6),
		Vector3(0.0, 1.2, -13.0),
		28.0,
		0.55,
		0.0
	)
	_agregar(
		tomas,
		"EXPEDIENTE",
		"La historia comienza antes de la primera pagina",
		"oficina",
		5.5,
		Vector3(-2.0, 1.65, 3.0),
		Vector3(-4.0, 1.0, 0.6),
		Vector3(-2.9, 1.5, 2.4),
		Vector3(-4.0, 1.0, 0.6),
		36.0,
		0.0,
		0.82
	)

	# CODA: tres planos cuya duracion devuelve aire antes de los creditos.
	_agregar(
		tomas,
		"ACCESO DENEGADO",
		"No queda ningun operador conectado",
		"oficina",
		5.0,
		Vector3(-3.1, 1.66, 2.5),
		Vector3(-4.3, 0.98, -2.0),
		Vector3(-3.7, 1.33, 1.35),
		Vector3(-4.3, 0.98, -2.0),
		26.0
	)
	_agregar(
		tomas,
		"EL ULTIMO TREN",
		"La ciudad se refleja dentro de la pantalla",
		"calle",
		5.8,
		Vector3(0.0, 1.7, -15.0),
		Vector3(0.0, 1.2, 10.0),
		Vector3(0.2, 1.6, -9.0),
		Vector3(-3.5, 1.8, -7.5),
		54.0
	)
	_agregar(
		tomas,
		"NO EXISTE REGISTRO",
		"",
		"oficina",
		4.2,
		Vector3(-1.6, 1.62, 3.4),
		Vector3(-4.0, 1.0, 1.0),
		Vector3(-1.6, 1.62, 3.4),
		Vector3(-4.0, 1.0, 1.0),
		40.0,
		0.0,
		1.0
	)

	# Ninguna imagen ajena: cada plano utiliza espacio y assets propios.
	return Cinematica.resolver(tomas)


static func _agregar(
	tomas: Array,
	nombre: String,
	voz: String,
	espacio: String,
	segundos: float,
	desde: Vector3,
	mira_desde: Vector3,
	hasta: Vector3,
	mira_hasta: Vector3,
	fov: float,
	fundido_desde: float = 0.0,
	fundido_hasta: float = 0.0
) -> void:
	var decorado: Dictionary
	match espacio:
		"oficina":
			decorado = EspaciosCatalogo.OFICINA.duplicate(true)
		"calle":
			decorado = EspaciosCatalogo.CALLE.duplicate(true)
		"casa":
			decorado = EspaciosCatalogo.CASA.duplicate(true)
		_:
			push_error("Decorado de apertura desconocido: " + espacio)
			return

	(
		tomas
		. append(
			{
				"tipo": "3d",
				"nombre": nombre,
				"rotulo": nombre,
				"voz": voz,
				"segundos": segundos,
				"decorado": decorado,
				"camara_desde": desde,
				"mira_desde": mira_desde,
				"camara": hasta,
				"mira": mira_hasta,
				"fov": fov,
				"fundido_desde": fundido_desde,
				"fundido_hasta": fundido_hasta,
			}
		)
	)
