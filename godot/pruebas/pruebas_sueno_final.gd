## Cuarto y último tramo de la suite: que todo el árbol compile, la salida del
## sueño, la jornada de una partida antigua, compañeros y sonido.
##
## Partida en varios ficheros por el tope de `gdlint` (max-file-lines): cada
## función es la MISMA prueba que antes, ahora `static` porque no necesita
## estado propio, recibiendo `comprobar` como el `Callable` que ya llevaba la
## cuenta de pasadas y fallos en `pruebas.gd`.
class_name PruebasSuenoFinal
extends RefCounted

# --- Que todo lo del árbol compile -------------------------------------------


## La suite no toca todos los guiones: `dia_app.gd` no lo carga ninguna prueba,
## y por eso pudo estar ROTO con las 320 en verde. Un error de tipo en una
## pantalla no es un fallo sutil —el juego no arranca— y aun así no lo veía
## nadie hasta abrirlo a mano.
##
## Esto no comprueba qué hace cada guion: comprueba que existe como código.
static func _compilan(comprobar: Callable) -> void:
	var rotos := []
	for carpeta in ["res://guion", "res://pruebas"]:
		for nombre in DirAccess.get_files_at(carpeta):
			if not nombre.ends_with(".gd"):
				continue
			var guion = load("%s/%s" % [carpeta, nombre])
			if guion == null or not guion.can_instantiate():
				rotos.append(nombre)
	comprobar.call("todos los guiones compilan", rotos, [])


# --- La salida del sueño (#90) ----------------------------------------------


static func _salida_del_sueno(comprobar: Callable) -> void:
	# La salida NO se ve. Es la decisión de #90 y tiene que estar declarada en
	# el espacio, no conseguida por no ponerla: una zona sin marca sigue siendo
	# una salida y se pisa igual.
	var escena := Sueno.espacio("crucero", 0)
	comprobar.call("la salida del sueño no se ve", escena["salidas"][0].get("visible", true), false)
	comprobar.call(
		"y es más ancha que una puerta, porque hay que dar con ella",
		escena["salidas"][0]["tam"].x > 3.0,
		true
	)

	# El tiempo sale de la GEOMETRÍA: una nave y un pasillo no se buscan igual.
	var una := Sueno.segundos_de_noche(["crucero"])
	var tres := Sueno.segundos_de_noche(["crucero", "patio", "peine"])
	comprobar.call("tres salas dan más noche que una", tres > una, true)
	var salas := SuenoFormas.ids().map(func(id): return Sueno.segundos_de_noche([id]))
	comprobar.call("y no todas las salas dan lo mismo", salas.max() > salas.min(), true)

	# #210 prepara el sueño degradado sin decidir aún la política de #84.
	# La noche corriente tiene que seguir siendo EXACTAMENTE la de siempre.
	var normal := Sueno.noche(3, ["MEMO-1999-088"], [], 17)
	var normal_explicita := Sueno.noche(
		3,
		["MEMO-1999-088"],
		[],
		17,
		{"cantidad": Sueno.ESCENAS_POR_NOCHE, "priorizar_vistas": false}
	)
	comprobar.call("la política por defecto no cambia la noche", normal_explicita, normal)

	# Una variante puede pedir menos escenas sin duplicar el generador.
	var corta := Sueno.noche(3, ["MEMO-1999-088"], [], 17, {"cantidad": 1})
	comprobar.call("se puede pedir una noche más corta", corta.size(), 1)
	comprobar.call("y conserva el mismo primer destino que la noche normal", corta[0], normal[0])

	# La política degradada puede favorecer lo ya visto. Con tres salas en el
	# mapa hay suficientes para llenar una noche corta solo con repetidas.
	var mapa := normal.duplicate()
	var repetida := Sueno.noche(
		4, ["FAC-1998-014"], mapa, 17, {"cantidad": 2, "priorizar_vistas": true}
	)
	comprobar.call(
		"se pueden priorizar salas vistas", repetida.all(func(id): return mapa.has(id)), true
	)
	comprobar.call(
		"la misma política sigue siendo determinista",
		Sueno.noche(4, ["FAC-1998-014"], mapa, 17, {"cantidad": 2, "priorizar_vistas": true}),
		repetida
	)
	comprobar.call("pedir cero escenas es seguro", Sueno.noche(1, [], [], 0, {"cantidad": 0}), [])
	comprobar.call(
		"una cantidad negativa se limita a cero", Sueno.noche(1, [], [], 0, {"cantidad": -5}), []
	)
	comprobar.call(
		"una cantidad enorme se limita al catálogo",
		Sueno.noche(1, [], [], 0, {"cantidad": 999}).size(),
		SuenoFormas.ids().size()
	)

	# Y da para cruzar la sala VARIAS veces: la salida no se ve, así que el
	# tiempo es el de buscarla y no el de ir a ella.
	var forma := SuenoFormas.de("crucero")
	var directo: float = (
		Planta.distancias_desde(forma["bloques"], forma["entrada"])["pasos"]
		* Planta.CELDA
		/ Sueno.VELOCIDAD
	)
	comprobar.call("hay tiempo para buscar, no solo para llegar", una > directo * 3.0, true)

	# El caminante y el cálculo tienen que andar a la misma velocidad. Está
	# copiado a propósito —esto es lógica pura y no puede depender de un nodo—
	# y por eso hace falta una prueba que los ate.
	var fuente := FileAccess.get_file_as_string("res://guion/caminante.gd")
	comprobar.call(
		"la velocidad del cálculo es la del caminante",
		fuente.contains("const VELOCIDAD := %s" % Sueno.VELOCIDAD),
		true
	)

	# --- El reloj ---
	var noche := Jornada.nueva()
	noche["fase"] = "casa"
	Jornada.dormir(noche)
	comprobar.call("dormir da noche", noche["sueno_resto"] > 0.0, true)
	comprobar.call("y guarda el mapa de antes", noche["mapa_anoche"], [])

	comprobar.call("gastar un rato no acaba la noche", Jornada.gastar_sueno(noche, 1.0), false)
	comprobar.call(
		"la señal empieza entera", Sueno.senal_de_noche(Jornada.noche_restante(noche)), "·  ·  ·"
	)

	# Fuera del sueño el reloj no corre: el día no tiene prisa.
	var dia := Jornada.nueva()
	comprobar.call("en el archivo no se gasta noche", Jornada.gastar_sueno(dia, 10.0), false)

	# --- Perderse ---
	var perdido := Jornada.nueva()
	perdido["fase"] = "casa"
	perdido["mapa"] = ["patio"]
	Jornada.dormir(perdido)
	# Se recorren dos salas y se acaba la noche dentro de la tercera.
	for id in perdido["sueno_escenas"]:
		Sueno.recordar(perdido["mapa"], id)
	comprobar.call("el mapa creció mientras soñaba", perdido["mapa"].size() > 1, true)
	comprobar.call("se acaba la noche", Jornada.gastar_sueno(perdido, 100000.0), true)
	Jornada.despertar_de_golpe(perdido)
	comprobar.call("perderse deja el mapa como estaba", perdido["mapa"], ["patio"])
	comprobar.call(
		"pero el día siguiente empieza entero",
		[perdido["dia"], perdido["acciones"], perdido["fase"]],
		[2, Jornada.ACCIONES_POR_DIA, "archivo"]
	)

	# Salir por la salida sí conserva lo andado. Es toda la diferencia.
	var salio := Jornada.nueva()
	salio["fase"] = "casa"
	Jornada.dormir(salio)
	for id in salio["sueno_escenas"]:
		Sueno.recordar(salio["mapa"], id)
	Jornada.despertar(salio)
	comprobar.call(
		"salir por su pie deja el mapa crecido", salio["mapa"].size(), Sueno.ESCENAS_POR_NOCHE
	)
	comprobar.call("y no queda noche colgando", salio["sueno_resto"], 0.0)

	# La señal avisa sin decir un número.
	comprobar.call(
		"la señal se apaga",
		[Sueno.senal_de_noche(1.0), Sueno.senal_de_noche(0.5), Sueno.senal_de_noche(0.1)],
		["·  ·  ·", "·  ·", "·"]
	)


# --- Partidas de una versión anterior ----------------------------------------


## Cada vez que la jornada estrena una clave, una partida guardada antes se la
## encuentra a faltar. Pasó con el reloj del sueño (#90): la primera partida
## que entró en el sueño con el reloj nuevo despertó de golpe nada más
## dormirse, porque su noche valía cero segundos.
static func _jornada_antigua(comprobar: Callable) -> void:
	var vieja := {
		"dia": 4,
		"fase": "casa",
		"dinero": 310,
		"cerrados_hoy": 1,
		"acciones": 2,
		"gato": {"presente": true, "dias_sin_comer": 1},
		"leido_hoy": ["MEMO-1999-088"]
	}
	Jornada.completar(vieja)

	var faltan := Jornada.nueva().keys().filter(func(c): return not vieja.has(c))
	comprobar.call("una jornada vieja se completa", faltan, [])
	comprobar.call(
		"y no se pisa lo que ya traía",
		[vieja["dia"], vieja["dinero"], vieja["acciones"]],
		[4, 310, 2]
	)

	# La que se guardó DENTRO del sueño es el caso que duele: sin noche que
	# gastar, se despierta en el primer fotograma.
	var sonando := {
		"dia": 6,
		"fase": "sueño",
		"dinero": 90,
		"cerrados_hoy": 0,
		"acciones": 0,
		"gato": {"presente": false, "dias_sin_comer": 4},
		"leido_hoy": []
	}
	Jornada.completar(sonando)
	comprobar.call("la que se guardó soñando recibe una noche", sonando["sueno_resto"] > 0.0, true)
	comprobar.call(
		"y las escenas que le faltaban", sonando["sueno_escenas"].size(), Sueno.ESCENAS_POR_NOCHE
	)
	comprobar.call(
		"y no se despierta en el primer fotograma", Jornada.gastar_sueno(sonando, 0.016), false
	)


# --- La plantilla del archivo (#125) -----------------------------------------


static func _companeros(comprobar: Callable) -> void:
	# El cuñado está siempre, y es el primero: es la continuidad de una vuelta
	# a otra, igual que el gato.
	for semilla in [1, 7, 4242, 999999]:
		var quienes := Companeros.plantilla(semilla)
		comprobar.call("el cuñado está en la vuelta %d" % semilla, quienes[0]["id"], "cunado")
		comprobar.call("y la planta se llena", quienes.size(), Companeros.POR_VUELTA + 1)
		var ids := {}
		for quien in quienes:
			ids[quien["id"]] = true
		comprobar.call("sin repetir a nadie en la %d" % semilla, ids.size(), quienes.size())

	# Dos vidas laborales distintas traen gente distinta...
	var una := Companeros.plantilla(1).map(func(q): return q["id"])
	var otra := Companeros.plantilla(2).map(func(q): return q["id"])
	comprobar.call("dos vueltas no traen la misma plantilla", una == otra, false)
	# ...y la misma vuelta, recargada, trae la misma: una oficina cuya gente
	# cambia al recargar la partida no es una oficina.
	comprobar.call(
		"la misma vuelta trae siempre la misma",
		Companeros.plantilla(1).map(func(q): return q["id"]),
		una
	)

	# Lo que dice rota con el DÍA. Al azar por fotograma no estaría hablando,
	# estaría sorteando.
	var quien: Dictionary = Companeros.ROSTER[0]
	comprobar.call(
		"dice lo mismo si pasas dos veces el mismo día",
		Companeros.frase_de(quien, 3),
		Companeros.frase_de(quien, 3)
	)
	comprobar.call(
		"y otra cosa al día siguiente",
		Companeros.frase_de(quien, 3) == Companeros.frase_de(quien, 4),
		false
	)

	# LA REGLA: ninguno da información. Es la del cuñado extendida a todos.
	var contenido := Contenido.new()
	contenido.cargar()
	var prohibido := []
	for caso in contenido.casos:
		for registro in caso["registros"]:
			prohibido.append(registro["folio"])
		for sospechoso in caso["sospechosos"]:
			prohibido.append(sospechoso["nombre"])
	var chivatazos := []
	for frase in Companeros.todas_las_frases():
		for termino in prohibido:
			if frase.contains(termino):
				chivatazos.append(frase)
	comprobar.call("ningún compañero nombra un documento ni un sospechoso", chivatazos, [])

	# Y ninguno se queda mudo: una silueta con nombre y sin nada que decir se
	# lee como que está rota.
	var mudos := []
	for alguien in [Companeros.CUNADO] + Companeros.ROSTER:
		if alguien["frases"].is_empty() or Companeros.frase_de(alguien, 1).is_empty():
			mudos.append(alguien["id"])
		if TranslationServer.translate(alguien["nombre"]) == alguien["nombre"]:
			mudos.append(alguien["id"])
	comprobar.call("ninguno se queda sin nombre ni sin voz", mudos, [])

	# Hay sitio para todos los que se sortean: con menos sillas que gente, uno
	# se queda de pie dentro de otro.
	comprobar.call(
		"la oficina tiene sillas para la plantilla",
		EspaciosCatalogo.OFICINA["sitios_companeros"].size() >= Companeros.POR_VUELTA + 1,
		true
	)

	# --- El cuerpo de cada uno (#194) ---

	# Un compañero sin cuerpo NO se ve como un fallo: se ve como una caja gris
	# de pie entre gente, que es exactamente el aspecto que tenía la oficina
	# entera antes. Así que se caza aquí y no en pantalla.
	var sin_cuerpo := []
	for alguien in [Companeros.CUNADO] + Array(Companeros.ROSTER):
		var cuerpo := Companeros.cuerpo_de(alguien)
		if cuerpo.is_empty() or not Modelos.hay(cuerpo):
			sin_cuerpo.append(alguien["id"])
	comprobar.call("todos tienen un cuerpo que existe", sin_cuerpo, [])

	# El mismo siempre: alguien que cambiara de cuerpo entre partidas no sería
	# la misma persona, y el cuñado es sobre todo una persona reconocible.
	comprobar.call(
		"el cuerpo de alguien no cambia",
		Companeros.cuerpo_de(Companeros.CUNADO),
		Companeros.cuerpo_de(Companeros.CUNADO)
	)

	# Y sin id no hay cuerpo, en vez de un `persona-` a medias que Modelos
	# buscaría en el disco por nada.
	comprobar.call("sin id no hay cuerpo", Companeros.cuerpo_de({}), "")


# --- El sonido (#119) --------------------------------------------------------


static func _sonido(comprobar: Callable) -> void:
	# Todo lo que el catálogo puede pedir existe. Un nombre que apunta a un
	# fichero que no está no falla al arrancar: falla el día que alguien abre
	# esa puerta, que es el peor momento para enterarse.
	var faltan := []
	for fichero in Sonido.ficheros():
		if not ResourceLoader.exists(Sonido.RUTA + fichero):
			faltan.append(fichero)
	comprobar.call("todo sonido del catálogo existe", faltan, [])

	comprobar.call("y se carga de verdad", Sonido.stream("nomina") != null, true)
	comprobar.call("un nombre que no está no revienta", Sonido.stream("no_existe"), null)

	# Los pasos son varios: uno solo repetido a cada zancada deja de ser un
	# paso y pasa a ser un tic.
	comprobar.call("hay más de un paso", Sonido.PASOS.size() > 1, true)
	comprobar.call(
		"y se pueden pedir en orden", Sonido.paso(0) == Sonido.paso(Sonido.PASOS.size()), true
	)

	# Todos llevan ficha. Es la regla de assets/ aplicada al primer material de
	# terceros que entra en el repositorio: sin esto, la procedencia se
	# documenta «luego», que es como no documentarla.
	var registro = JSON.parse_string(FileAccess.get_file_as_string("res://assets/procedencia.json"))
	var con_ficha := {}
	for ficha in registro["assets"]:
		con_ficha[String(ficha["ruta"]).replace("audio/", "")] = ficha
	var sin_ficha := Sonido.ficheros().filter(func(f): return not con_ficha.has(f))
	comprobar.call("todo sonido tiene su ficha", sin_ficha, [])

	var mal_licenciados := []
	for fichero in Sonido.ficheros():
		if con_ficha.has(fichero) and con_ficha[fichero]["licencia"] != "CC0-1.0":
			mal_licenciados.append(fichero)
	comprobar.call("y todos son CC0", mal_licenciados, [])


# --- Combates oníricos (#88) -------------------------------------------------


## Contra quién se pelea en el sueño y qué pasa después. El motor de combate es
## el de siempre y no se prueba aquí: lo que esto fija son las dos decisiones
## propias de #88 —solo contra los que acusaste, y ganar tiene consecuencia—,
## que es lo que distingue esto del careo, donde el duelo no cambia nada.
static func _sueno_combate(comprobar: Callable) -> void:
	var casos := [
		{
			"id": "caso1",
			"registros": [{"id": "memo1", "folio": "MEMO-1"}],
			"pistas": [],
			"sospechosos":
			[
				{"id": "s1", "nombre": "J. Ibarra", "ataques": ["Yo firmé lo que me dieron."]},
				{"id": "s2", "nombre": "Comité de Adquisiciones"},
			],
		}
	]

	# Contra quién: solo contra los que acusaste. Sin firma no hay con quién
	# pelear, y una partida entera sin acusar a nadie no tiene combates.
	var sin_firmar := SuenoContenido.fuentes(["MEMO-1"], casos, [], {})
	comprobar.call(
		"sin haber firmado, nadie se deja pelear",
		sin_firmar["figuras"].filter(func(f): return SuenoCombate.se_pelea(f, {})).size(),
		0
	)

	var firmado := SuenoContenido.fuentes(["MEMO-1"], casos, [], {"caso1": "s1"})
	comprobar.call(
		"se pelea con el que firmaste, y solo con él",
		(
			firmado["figuras"]
			. filter(func(f): return SuenoCombate.se_pelea(f, {}))
			. map(func(f): return f["id"])
		),
		["s1"]
	)

	# La figura viaja con lo que el duelo necesita: contra quién y qué dice.
	comprobar.call("la figura lleva su id", firmado["figuras"][0]["id"], "s1")
	comprobar.call(
		"y sus réplicas",
		SuenoCombate.nuevo(firmado["figuras"][0])["rival"],
		{"nombre": "J. Ibarra", "ataques": ["Yo firmé lo que me dieron."]}
	)
	comprobar.call(
		"el sueño contesta a lo último que hiciste",
		SuenoCombate.nuevo(firmado["figuras"][0])["modo"],
		"reactiva"
	)

	# Y la sala lo planta con su reto puesto: lo que se ve distinto es lo que
	# se puede tocar.
	var escena := Sueno.espacio("patio", 1, {"frases": [], "figuras": firmado["figuras"]})
	comprobar.call(
		"solo el acusado trae duelo", escena["figuras"].map(func(f): return f["duelo"]), ["s1", ""]
	)

	# Ganar: se apunta, devuelve una vida y deja de aparecer.
	var estado := {"vida": 2, "dificultad": "normal"}
	var jornada := Jornada.nueva()
	jornada["fase"] = "sueño"
	var ganado := SuenoCombate.resolver(estado, jornada, firmado["figuras"][0], true)
	comprobar.call("ganar devuelve una vida", [ganado["vida"], ganado["recuperada"]], [3, true])
	comprobar.call("y se apunta a quién callaste", SuenoCombate.vencidos(estado), ["s1"])
	comprobar.call(
		"al que ya venciste no se le vuelve a retar",
		SuenoCombate.se_pelea(firmado["figuras"][0], estado),
		false
	)
	var tras_ganar := SuenoContenido.fuentes(
		["MEMO-1"], casos, [], {"caso1": "s1"}, SuenoCombate.vencidos(estado)
	)
	comprobar.call(
		"y deja de aparecer en el sueño", tras_ganar["figuras"].map(func(f): return f["id"]), ["s2"]
	)

	# La vida no es una fuente infinita: el tope es el de la dificultad, así
	# que la única forma de tener más es firmar más.
	var lleno := {"vida": 3, "dificultad": "normal", "sueno_vencidos": []}
	var otro := SuenoCombate.resolver(
		lleno, jornada, {"id": "s9", "nombre": "Otro", "acusado": true}, true
	)
	comprobar.call("ganar al tope no sube de tres", [lleno["vida"], otro["recuperada"]], [3, false])
	comprobar.call(
		"en difícil el tope son dos",
		(SuenoCombate.resolver(
			{"vida": 1, "dificultad": "dificil"}, jornada, firmado["figuras"][0], true
		))["vida"],
		2
	)

	# Perder: no cuesta vida —eso ya lo cobró la firma— y corta la noche. El
	# mapa de esta noche no queda, que es lo que de verdad pasó.
	var perdedor := {"vida": 2, "dificultad": "normal"}
	var noche := Jornada.nueva()
	noche["fase"] = "casa"
	Jornada.dormir(noche)
	noche["mapa"] = ["patio"]
	var perdido := SuenoCombate.resolver(perdedor, noche, firmado["figuras"][0], false)
	comprobar.call("perder no cuesta una vida", perdedor["vida"], 2)
	comprobar.call("perder despierta de golpe", [noche["fase"], perdido["dia"]], ["archivo", 2])
	comprobar.call("y la noche no deja mapa", noche["mapa"], [])
	comprobar.call("ni deja a nadie por vencido", SuenoCombate.vencidos(perdedor), [])

	# La partida nueva trae el sitio donde apuntarlo: sin la clave, una partida
	# vieja entraría al sueño con `vencidos` a nulo.
	comprobar.call(
		"una partida nueva no ha vencido a nadie", Partida.nueva()[SuenoCombate.CLAVE_VENCIDOS], []
	)
