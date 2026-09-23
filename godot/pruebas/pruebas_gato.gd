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

	# #1240: quedarse junto al cuenco no significa convertirse en geometría.
	# En treinta segundos debe moverse, sin salir de la zona ni pedir mimos.
	var inquieto := GatoConducta.nuevo(sitios[0])
	var recorrido := 0.0
	var distancia_maxima := 0.0
	var estados := {}
	for _paso in 600:
		var antes: Vector3 = inquieto["pos"]
		GatoConducta.avanzar(inquieto, sitios, Jornada.PACIENCIA_GATO, sitios[0], 0.05)
		recorrido += antes.distance_to(inquieto["pos"])
		distancia_maxima = maxf(distancia_maxima, inquieto["pos"].distance_to(sitios[0]))
		estados[String(inquieto["estado"])] = true
	comprobar.call("hambriento sigue moviéndose junto al cuenco", recorrido > 0.5, true)
	comprobar.call(
		"hambriento no abandona el cuenco",
		distancia_maxima <= GatoConducta.RADIO_HAMBRIENTO + 0.01,
		true
	)
	comprobar.call(
		"hambriento no viene ni pide mimos",
		[estados.has("viene"), estados.has("mimos")],
		[false, false]
	)

	# Recién comido y con alguien cerca, se acerca. Es la única recompensa que
	# da el juego por cuidarlo, y no lleva ningún número.
	var contento := GatoConducta.nuevo(sitios[1])
	var jugador: Vector3 = sitios[1] + Vector3(1.5, 0, 0)
	GatoConducta.avanzar(contento, sitios, 0, jugador, 0.1)
	comprobar.call("bien comido, se acerca", contento["estado"], "viene")

	# #570: alcanzar al jugador no termina en un parado indistinguible del
	# paseo. Se frota durante un instante, sin tocar hambre ni jornada.
	for _paso in 12:
		GatoConducta.avanzar(contento, sitios, 0, jugador, 0.1)
	comprobar.call("al alcanzar al jugador pide mimos", contento["estado"], "mimos")
	var pos_mimos: Vector3 = contento["pos"]
	GatoConducta.avanzar(contento, sitios, 0, jugador, 0.2)
	comprobar.call(
		"durante los mimos se queda junto al jugador",
		[contento["estado"], contento["pos"]],
		["mimos", pos_mimos]
	)

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

	# Tercer corte de #787: los sitios de casa ya son affordances declarativas.
	# La misma conducta sigue aceptando Vector3 simples (todos los tests previos)
	# y traduce las affordances a estados que la malla puede mostrar.
	var sitios_casa: Array = EspaciosCatalogo.CASA["sitios_gato"]
	(
		comprobar
		. call(
			"el primer sitio declarativo sigue siendo el cuenco",
			[
				GatoConducta.posicion_sitio(sitios_casa[0]),
				GatoConducta.rutina_sitio(sitios_casa[0]),
			],
			[Vector3(2.8, 0, 1.5), "cuenco"]
		)
	)
	var rutinas: Array = sitios_casa.map(func(sitio): return GatoConducta.rutina_sitio(sitio))
	for rutina in ["dormir", "sentarse", "observar", "esconderse"]:
		comprobar.call("la casa declara rutina " + rutina, rutinas.has(rutina), true)

	var estados_rutina := {
		"dormir": "durmiendo",
		"sentarse": "sentado",
		"observar": "observando",
	}
	for rutina in estados_rutina:
		var candidatos: Array = sitios_casa.filter(
			func(sitio): return GatoConducta.rutina_sitio(sitio) == rutina
		)
		var pos_rutina := GatoConducta.posicion_sitio(candidatos[0])
		var en_rutina := GatoConducta.nuevo(pos_rutina)
		en_rutina["estado"] = "anda"
		en_rutina["destino"] = pos_rutina
		en_rutina["rutina_destino"] = rutina
		GatoConducta.avanzar(en_rutina, candidatos, 0, lejos, 0.05)
		comprobar.call(
			"la affordance " + rutina + " produce estado observable",
			en_rutina["estado"],
			estados_rutina[rutina]
		)

	# #787: el propio gato usa el contrato común de interacción, de modo que la
	# misma instancia sirve en casa y en sueño. Cerca se acaricia y después se
	# ofrece coger; desde más lejos se le llama y pasa al estado de acercarse.
	var interactivo := Gato.new()
	interactivo.empezar(Vector3.ZERO, sitios)
	comprobar.call("el gato es un interactuable 3D", interactivo is Interactuable3D, true)
	comprobar.call("de cerca ofrece acariciar", interactivo.texto_accion(), "Acariciar gato")
	comprobar.call("la interacción física tiene sonido", interactivo.nombre_sonido(), "coger")
	comprobar.call("acariciarlo acepta la acción", interactivo.interactuar(null), true)
	comprobar.call(
		"acariciarlo activa mimos y permite cogerlo",
		[interactivo.estado["estado"], interactivo.texto_accion()],
		["mimos", "Coger gato"]
	)
	comprobar.call("cogerlo acepta la acción", interactivo.interactuar(null), true)
	comprobar.call(
		"tras cogerlo vuelve a ofrecer mimos", interactivo.texto_accion(), "Acariciar gato"
	)

	var actor := Node3D.new()
	actor.position = Vector3(2.0, 0, 0)
	comprobar.call("llamarlo acepta la acción", interactivo.interactuar(actor), true)
	comprobar.call(
		"llamarlo lo pone en camino hacia el jugador",
		[interactivo.estado["estado"], interactivo.estado["destino"]],
		["viene", Vector3(2.0, 0, 0)]
	)
	actor.free()
	interactivo.free()

	# Segundo corte de #787: con hambre y a distancia física, la acción cambia
	# a dar de comer. El propio Gato no cobra ni reinicia Jornada: solo emite el
	# verbo DAR para que la capa propietaria reutilice _dar_de_comer().
	var hambriento_interactivo := Gato.new()
	hambriento_interactivo.empezar(Vector3.ZERO, sitios)
	hambriento_interactivo.avanzar(2, Vector3.ZERO, 0.0)
	comprobar.call(
		"con hambre ofrece dar de comer",
		hambriento_interactivo.texto_accion(),
		"Dar de comer al gato"
	)
	comprobar.call("dar de comer acepta la acción", hambriento_interactivo.interactuar(null), true)
	comprobar.call(
		"dar de comer usa el verbo común", hambriento_interactivo.verbo, Interactuable3D.Verbo.DAR
	)
	hambriento_interactivo.actualizar_hambre(0)
	comprobar.call(
		"tras comer vuelve a ofrecer contacto",
		hambriento_interactivo.texto_accion(),
		"Acariciar gato"
	)
	hambriento_interactivo.free()

	var capa_gato := FileAccess.get_file_as_string("res://guion/dia_gato_app.gd")
	comprobar.call(
		"la capa de jornada escucha la activación del gato",
		capa_gato.contains("_gato.activado.connect(_al_activar_gato.bind(_gato))"),
		true
	)
	comprobar.call(
		"la alimentación directa reutiliza el flujo del cuenco",
		capa_gato.contains("_dar_de_comer()"),
		true
	)


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
	var sitio_cuenco := GatoConducta.posicion_sitio(EspaciosCatalogo.CASA["sitios_gato"][0])
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


## Comer tú, no el gato (#93): compra aparte, mismo dinero. Misma frontera que
## la lata, así que la prueba es simétrica y vive aquí por tema, aunque el
## estado sea de Jornada y no del bicho.
static func _comida_propia(comprobar: Callable) -> void:
	comprobar.call(
		"comer cuesta menos que vivir un día",
		Jornada.PRECIO_COMIDA_PROPIA < Jornada.COSTE_DIARIO,
		true
	)
	var hambriento := Jornada.nueva()
	hambriento["comida_propia"]["dias_sin_comer"] = 2
	var saldo_antes: int = hambriento["dinero"]
	(
		comprobar
		. call(
			"comer reinicia la cuenta y cobra",
			[
				Jornada.comer(hambriento, Jornada.PRECIO_COMIDA_PROPIA),
				hambriento["dinero"],
				hambriento["comida_propia"]["dias_sin_comer"],
			],
			[true, saldo_antes - Jornada.PRECIO_COMIDA_PROPIA, 0]
		)
	)
	hambriento["dinero"] = 0
	comprobar.call(
		"sin dinero no se come, y no se queda a deber",
		[Jornada.comer(hambriento, Jornada.PRECIO_COMIDA_PROPIA), hambriento["dinero"]],
		[false, 0]
	)

	# Dormir sin comer suma la cuenta, igual que con el gato, sin castigo aquí:
	# lo que se note en la casa lo decide #96.
	var sin_comer := Jornada.nueva()
	sin_comer["fase"] = "casa"
	Jornada.dormir(sin_comer)
	comprobar.call(
		"una noche sin comer suma un día", sin_comer["comida_propia"]["dias_sin_comer"], 1
	)


## Que el bicho tenga malla. Es el único ser vivo del juego y lo único que no
## está hecho de cajas: si esta geometría cambia, ha cambiado el gato y no un
## detalle de implementación.
static func _malla(comprobar: Callable) -> void:
	# #570/#787: la raíz sigue sin ser un cuerpo bloqueante, pero ahora es el
	# Area3D que usa el detector común y mantiene su sonda volumétrica separada.
	var codigo_gato := FileAccess.get_file_as_string("res://guion/gato.gd")
	comprobar.call(
		"el gato es interactuable sin cuerpo bloqueante",
		(
			codigo_gato.contains("extends Interactuable3D")
			and not codigo_gato.contains("extends CharacterBody3D")
		),
		true
	)
	comprobar.call(
		"el gato tiene volumen de interacción", codigo_gato.contains("CollisionShape3D.new()"), true
	)
	comprobar.call(
		"el gato tiene sonda volumétrica", codigo_gato.contains("ShapeCast3D.new()"), true
	)
	comprobar.call(
		"la sonda fuerza consulta física", codigo_gato.contains("force_shapecast_update()"), true
	)

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
