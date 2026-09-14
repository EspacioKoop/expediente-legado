## La semilla de la partida (#147): que una partida se pueda volver a ver.
##
## En su propio fichero por el tope de `gdlint` (max-file-lines), como el resto
## de tramos: la misma prueba, `static`, recibiendo `comprobar` como el
## `Callable` que lleva la cuenta de pasadas y fallos en `pruebas.gd`.
class_name PruebasSemilla
extends RefCounted


static func _semilla(comprobar: Callable) -> void:
	# Derivar es una FUNCIÓN: los mismos argumentos dan siempre el mismo
	# número. Si esto dejara de cumplirse, nada de lo de abajo valdría nada.
	comprobar.call(
		"derivar es pura", Azar.derivar(1234, "sueno", [3]), Azar.derivar(1234, "sueno", [3])
	)
	comprobar.call(
		"cada dominio va por su lado",
		Azar.derivar(1234, "sueno", [3]) == Azar.derivar(1234, "clima", [3]),
		false
	)
	comprobar.call(
		"y cada índice también",
		Azar.derivar(1234, "sueno", [3]) == Azar.derivar(1234, "sueno", [4]),
		false
	)
	comprobar.call(
		"dos semillas no dan lo mismo",
		Azar.derivar(1, "sueno", [3]) == Azar.derivar(2, "sueno", [3]),
		false
	)

	# Nunca negativo: hay semillas que acaban en un `%` o en un `slice`, y un
	# negativo ahí no falla, hace algo raro.
	for raiz in [0, 1, 999999, 9007199254740993]:
		for dominio in Azar.DOMINIOS:
			comprobar.call(
				"%s con raíz %d no sale en negativo" % [dominio, raiz],
				Azar.derivar(raiz, dominio, [7]) >= 0,
				true
			)
	comprobar.call(
		"y por texto tampoco", Azar.derivar_texto(5, "sueno", "MEMO-1999-088") >= 0, true
	)
	comprobar.call(
		"derivar por texto también es puro",
		Azar.derivar_texto(5, "sueno", "MEMO-1999-088", [2]),
		Azar.derivar_texto(5, "sueno", "MEMO-1999-088", [2])
	)
	comprobar.call(
		"y distingue el texto",
		(
			Azar.derivar_texto(5, "sueno", "MEMO-1999-088")
			== Azar.derivar_texto(5, "sueno", "FAC-1998-014")
		),
		false
	)

	# Una partida nueva nace con semilla, y no con la misma para todos.
	var partida := Partida.new()
	partida.estado = Partida.nueva()
	comprobar.call("una partida nueva trae semilla", int(partida.estado["semilla"]) > 0, true)

	# LO QUE PIDE EL ISSUE: misma semilla y mismas acciones, misma partida.
	var primera := Jornada.nueva(4242)
	var segunda := Jornada.nueva(4242)
	comprobar.call(
		"la misma semilla da la misma vuelta", primera["plantilla"], segunda["plantilla"]
	)
	comprobar.call(
		"y otra semilla otra vuelta",
		Jornada.nueva(4243)["plantilla"] == primera["plantilla"],
		false
	)

	# Guardar y recargar NO vuelve a sortear. Pasa por JSON de verdad y no por
	# una copia del diccionario, porque el fallo está justo ahí: JSON no tiene
	# enteros, y un número que no quepa exacto en un decimal vuelve redondeado
	# y con media oficina cambiada.
	var vuelta_json: Dictionary = JSON.parse_string(JSON.stringify(primera))
	comprobar.call(
		"la semilla de la plantilla sobrevive al guardado",
		int(vuelta_json["plantilla"]),
		primera["plantilla"]
	)
	comprobar.call(
		"recargar no cambia a los compañeros",
		Companeros.plantilla(int(vuelta_json["plantilla"])).map(func(q): return q["id"]),
		Companeros.plantilla(primera["plantilla"]).map(func(q): return q["id"])
	)

	# Y la raíz de la partida, igual: es lo primero que se guarda.
	var estado_json: Dictionary = JSON.parse_string(JSON.stringify(Partida.nueva()))
	comprobar.call(
		"la semilla de la partida sobrevive al guardado", int(estado_json["semilla"]) > 0, true
	)
	comprobar.call(
		"y vuelve siendo la misma", str(int(estado_json["semilla"])).length() <= 10, true
	)

	# Que te reasignen SÍ cambia la planta, y sin perder la raíz: la semilla es
	# de la partida y el despido no la toca.
	var reasignado := Jornada.nueva(4242)
	Jornada.reiniciar_vuelta(reasignado)
	comprobar.call("la raíz sobrevive al despido", reasignado["raiz"], 4242)
	comprobar.call("y la vuelta avanza", reasignado["vuelta"], 2)
	comprobar.call(
		"y la planta se llena de otra gente", reasignado["plantilla"] == primera["plantilla"], false
	)
	# ...y esa segunda vuelta también es reproducible.
	var otro_camino := Jornada.nueva(4242)
	Jornada.reiniciar_vuelta(otro_camino)
	comprobar.call(
		"la segunda vuelta también se repite", otro_camino["plantilla"], reasignado["plantilla"]
	)

	# El sueño entra en el contrato: mismo día y misma lectura, misma noche,
	# pero la noche es de SU partida y no del calendario.
	var leido := ["MEMO-1999-088", "FAC-1998-014"]
	comprobar.call(
		"la misma noche con la misma semilla",
		Sueno.noche(2, leido, [], 4242),
		Sueno.noche(2, leido, [], 4242)
	)
	comprobar.call(
		"y otra semilla sueña otra cosa",
		Sueno.semilla(2, leido, 4242) == Sueno.semilla(2, leido, 4243),
		false
	)
	comprobar.call(
		"lo leído sigue contando",
		Sueno.semilla(2, leido, 4242) == Sueno.semilla(2, ["FAC-1998-014"], 4242),
		false
	)
	comprobar.call(
		"y el día también", Sueno.semilla(2, leido, 4242) == Sueno.semilla(3, leido, 4242), false
	)

	# Una jornada guardada ANTES de que existiera la semilla se completa con la
	# de su partida, pero conserva su plantilla: a quien va por el día quince no
	# se le vacía la oficina porque haya actualizado.
	var antigua := {
		"dia": 15,
		"fase": "archivo",
		"dinero": 300,
		"cerrados_hoy": 0,
		"acciones": 6,
		"leido_hoy": [],
		"plantilla": 777,
		"gato": {"presente": true, "dias_sin_comer": 0},
	}
	Jornada.completar(antigua, 4242)
	comprobar.call("una jornada antigua hereda la raíz", antigua["raiz"], 4242)
	comprobar.call("y se queda con sus compañeros", antigua["plantilla"], 777)
	# Pero una que YA tiene raíz no se la deja pisar.
	var suya := Jornada.nueva(11)
	Jornada.completar(suya, 4242)
	comprobar.call("y una que ya tiene raíz se la queda", suya["raiz"], 11)

	# El manifiesto: lo que acompaña a un informe de bug (#116).
	partida.estado["jornada"] = Jornada.nueva(4242)
	partida.estado["jornada"]["dia"] = 9
	partida.estado["semilla"] = 4242
	var manifiesto := Azar.manifiesto(partida.estado)
	comprobar.call("el manifiesto lleva la semilla", manifiesto["semilla"], 4242)
	comprobar.call("y la vuelta", manifiesto["vuelta"], 1)
	comprobar.call("y el día", manifiesto["dia"], 9)
	comprobar.call("y la versión del guardado", manifiesto["version_guardado"], Partida.VERSION)
	comprobar.call(
		"la huella de los catálogos es estable", Azar.huella_catalogos(), Azar.huella_catalogos()
	)
	comprobar.call(
		"y tiene forma de huella y no de número con signo", Azar.huella_catalogos().length(), 16
	)
	comprobar.call(
		"y el manifiesto se puede pegar en un informe",
		Azar.manifiesto_en_texto(partida.estado).contains("semilla=4242"),
		true
	)

	# LA GUARDA: nada JUGABLE puede volver a sortear con el azar global, que no
	# tiene raíz y por tanto no se puede reproducir. La presentación sí —el tono
	# de una pisada, hacia dónde mira el gato— porque no decide nada.
	var presentacion := [
		"gato_conducta.gd",  # hacia dónde mira y cuánto espera
		"sonido.gd",  # qué variación de una pisada suena
		"dia_app.gd",  # el tono de esa pisada
		"textura_procedural.gd",  # el grano de una textura
	]
	var con_azar_global := []
	for fichero in DirAccess.get_files_at("res://guion"):
		if not fichero.ends_with(".gd") or fichero in presentacion:
			continue
		var texto := FileAccess.get_file_as_string("res://guion/" + fichero)
		for linea in texto.split("\n"):
			var codigo := linea.strip_edges()
			if codigo.begins_with("#"):
				continue
			for suelto in [
				"randi()", "randf()", "randi_range(", "randf_range(", "randomize()", "pick_random("
			]:
				if (
					codigo.contains(suelto)
					and not codigo.contains("_azar.")
					and not codigo.contains("rng.")
				):
					con_azar_global.append(fichero + ": " + codigo)
					break
	comprobar.call("ningún sistema jugable sortea sin raíz", con_azar_global, [])
