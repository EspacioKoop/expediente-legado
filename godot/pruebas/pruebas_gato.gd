## El gato de casa (#92): su conducta, su cuenco y la malla con la que está
## hecho. Lo que cuesta la lata y lo que hace la cuenta de días vive con la
## jornada, en `pruebas_prometeo_y_combate.gd`; aquí está el bicho.
##
## Partida en varios ficheros por el tope de `gdlint` (max-file-lines): cada
## función es `static` porque no necesita estado propio, y recibe `comprobar`
## como el `Callable` que lleva la cuenta de pasadas y fallos en `pruebas.gd`.
class_name PruebasGato
extends RefCounted


static func _gato(comprobar: Callable) -> void:
	var sitios := [Vector3(2.8, 0, 1.5), Vector3(-2.4, 0, -0.6), Vector3(0.6, 0, 2.1)]
	var lejos := Vector3(-8, 0, -8)

	# La señal llega ANTES de que se vaya, o no es una señal: es un aviso de
	# algo que ya ha pasado. Quien lo note a tiempo puede arreglarlo.
	comprobar.call(
		"deja de venir antes de irse",
		GatoConducta.DIAS_PARA_DESCONFIAR < Jornada.PACIENCIA_GATO,
		true
	)

	# Y no corre más que tú: un gato al que no se puede alcanzar no se deja
	# cuidar.
	comprobar.call("anda menos que una persona", GatoConducta.VELOCIDAD < Sueno.VELOCIDAD, true)

	# Con hambre, el cuenco, que es el primer sitio de la lista. Es lo que se ve
	# desde la puerta sin que nadie lo diga.
	var hambriento := GatoConducta.nuevo(sitios[2])
	GatoConducta.avanzar(hambriento, sitios, Jornada.PACIENCIA_GATO, lejos, 0.1)
	comprobar.call(
		"con hambre se queda en el cuenco",
		[hambriento["destino"], hambriento["estado"]],
		[sitios[0], "hambriento"]
	)

	# Recién comido y con alguien cerca, se acerca. Es la única recompensa que
	# da el juego por cuidarlo, y no lleva ningún número.
	var contento := GatoConducta.nuevo(sitios[1])
	GatoConducta.avanzar(contento, sitios, 0, sitios[1] + Vector3(1.5, 0, 0), 0.1)
	comprobar.call("bien comido, se acerca", contento["estado"], "viene")

	# Un día sin comer todavía no es desconfianza: hay margen para arreglarlo.
	var dudoso := GatoConducta.nuevo(sitios[1])
	GatoConducta.avanzar(dudoso, sitios, GatoConducta.DIAS_PARA_DESCONFIAR, lejos, 0.1)
	comprobar.call(
		"un día sin comer aún no le hace desconfiar", dudoso["estado"] != "hambriento", true
	)

	# Andar es moverse: el bicho llega, no se teletransporta ni se queda
	# clavado.
	var andante := GatoConducta.nuevo(sitios[1])
	andante["destino"] = sitios[0]
	GatoConducta.avanzar(andante, sitios, 0, lejos, 0.2)
	comprobar.call(
		"anda hacia donde va",
		andante["pos"].distance_to(sitios[0]) < sitios[1].distance_to(sitios[0]),
		true
	)

	(
		comprobar
		. call(
			"se le alcanza de cerca y no de lejos",
			[
				GatoConducta.al_alcance(andante, andante["pos"] + Vector3(1.0, 0, 0)),
				GatoConducta.al_alcance(andante, lejos),
			],
			[true, false]
		)
	)

	# Sin sitios declarados no revienta: una casa que no diga por dónde anda el
	# gato se monta igual y él se queda quieto.
	var sin_sitios := GatoConducta.nuevo(Vector3.ZERO)
	GatoConducta.avanzar(sin_sitios, [], 0, lejos, 0.1)
	comprobar.call("sin sitios se queda donde está", sin_sitios["pos"], Vector3.ZERO)


## Darle de comer. Que la cuenta se reinicie y que sin dinero no se pueda ya se
## prueba con la jornada; lo de aquí es el PRECIO: que se cobre exacto, que no
## se quede a deber y que cueste menos que vivir un día, que es lo que hace de
## la lata una decisión posible en una racha mala y gratuita en ninguna.
static func _cuenco(comprobar: Callable) -> void:
	comprobar.call(
		"la lata cuesta menos que vivir un día",
		Jornada.PRECIO_COMIDA_GATO < Jornada.COSTE_DIARIO,
		true
	)

	var casa := Jornada.nueva()
	casa["gato"]["dias_sin_comer"] = 2
	var antes: int = casa["dinero"]
	(
		comprobar
		. call(
			"darle de comer cobra la lata",
			[
				Jornada.alimentar_gato(casa, Jornada.PRECIO_COMIDA_GATO),
				casa["dinero"],
				casa["gato"]["dias_sin_comer"],
			],
			[true, antes - Jornada.PRECIO_COMIDA_GATO, 0]
		)
	)

	var pobre := Jornada.nueva()
	pobre["dinero"] = Jornada.PRECIO_COMIDA_GATO - 1
	pobre["gato"]["dias_sin_comer"] = 2
	(
		comprobar
		. call(
			"sin dinero no come, y no se le queda a deber",
			[
				Jornada.alimentar_gato(pobre, Jornada.PRECIO_COMIDA_GATO),
				pobre["dinero"],
				pobre["gato"]["dias_sin_comer"],
			],
			[false, Jornada.PRECIO_COMIDA_GATO - 1, 2]
		)
	)

	# El cuenco está donde anda el gato: un sitio para darle de comer al que él
	# no va nunca sería un botón en la pared.
	var cuenco: Array = EspaciosCatalogo.CASA["salidas"].filter(
		func(s): return s["destino"] == "cuenco"
	)
	comprobar.call("la casa tiene cuenco", cuenco.size(), 1)
	var sitio_cuenco: Vector3 = EspaciosCatalogo.CASA["sitios_gato"][0]
	comprobar.call(
		"y el gato hambriento se planta en él",
		(
			(
				Vector2(cuenco[0]["pos"].x - sitio_cuenco.x, cuenco[0]["pos"].z - sitio_cuenco.z)
				. length()
			)
			< 0.5
		),
		true
	)


## Que el bicho tenga malla. Es el único ser vivo del juego y lo único que no
## está hecho de cajas: si esta geometría cambia, ha cambiado el gato y no un
## detalle de implementación.
static func _malla(comprobar: Callable) -> void:
	# Un tubo de N anillos y L lados: dos triángulos por cara y una tapa por
	# punta.
	var espina := [
		{"c": Vector3(0, 0, 0), "r": 0.1},
		{"c": Vector3(0, 0, -0.2), "r": 0.08},
		{"c": Vector3(0, 0, -0.4), "r": 0.05},
	]
	var malla := MallaOrganica.tubo(espina, 6)
	comprobar.call("el tubo sale con una superficie", malla.get_surface_count(), 1)
	var caras: PackedVector3Array = malla.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	comprobar.call(
		"con dos triángulos por cara y sus dos tapas", caras.size(), (3 - 1) * 6 * 6 + 2 * 6 * 3
	)

	# El radio elíptico es lo que hace un lomo y no un cilindro: más ancho que
	# alto. Sin él, el gato es un tubo con orejas.
	var lomo := (
		MallaOrganica
		. tubo(
			[
				{"c": Vector3.ZERO, "r": Vector2(0.1, 0.05)},
				{"c": Vector3(0, 0, -0.2), "r": Vector2(0.1, 0.05)},
			],
			4
		)
	)
	var puntos: PackedVector3Array = lomo.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var ancho := 0.0
	var alto := 0.0
	for punto in puntos:
		ancho = maxf(ancho, absf(punto.x))
		alto = maxf(alto, absf(punto.y))
	comprobar.call("un radio elíptico da un lomo más ancho que alto", ancho > alto, true)

	# Y una punta es un anillo de radio cero: así se hace una oreja sin otra
	# clase que sepa hacer conos.
	var punta := MallaOrganica.tubo(
		[{"c": Vector3.ZERO, "r": 0.03}, {"c": Vector3(0, 0, -0.07), "r": 0.0}], 5
	)
	comprobar.call("una punta sigue siendo una malla", punta.get_surface_count(), 1)
