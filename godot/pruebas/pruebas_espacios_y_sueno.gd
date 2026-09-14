## Tercer tramo de la suite de `pruebas.gd`: espacios del día, acusación,
## careo, cinemáticas, plantas y el sueño con su contenido.
##
## Partida en varios ficheros por el tope de `gdlint` (max-file-lines): cada
## función es la MISMA prueba que antes, ahora `static` porque no necesita
## estado propio, recibiendo `comprobar` como el `Callable` que ya llevaba la
## cuenta de pasadas y fallos en `pruebas.gd`.
class_name PruebasEspaciosYSueno
extends RefCounted

## Los ficheros de datos que pueden nombrar una clave de traducción.
const CATALOGOS := ["res://datos/casos.json", "res://datos/prometeo.json"]

# --- Los espacios del día ----------------------------------------------------


static func _espacios(comprobar: Callable) -> void:
	# Cada fase de la jornada tiene su sitio: una fase sin espacio dejaría al
	# jugador en la nada.
	# El sueño es la excepción declarada: no es un sitio, son tres cada noche
	# (#86), y lo compone `Sueno`. Se comprueba aparte, en `_sueno()`.
	var sin_sitio := Jornada.FASES.filter(
		func(f): return f != "sueño" and not EspaciosCatalogo.POR_FASE.has(f)
	)
	comprobar.call("cada fase del día tiene su espacio", sin_sitio, [])

	# Todo `modelo` que declara un bulto existe de verdad en el árbol. Sin esta
	# guarda una errata NO se ve: `Modelos.vestir` devuelve false y el bulto se
	# queda siendo su caja, que es exactamente el aspecto que tenía antes — así
	# que un mueble mal escrito se leería como «todavía no le han puesto malla».
	var modelos_rotos := []
	var con_modelo := 0
	for fase in EspaciosCatalogo.POR_FASE:
		var sitio: Dictionary = EspaciosCatalogo.POR_FASE[fase]
		for bulto in sitio.get("bultos", []):
			var modelo: String = bulto.get("modelo", "")
			if modelo.is_empty():
				continue
			con_modelo += 1
			if not Modelos.hay(modelo):
				modelos_rotos.append("%s: %s" % [fase, modelo])
	comprobar.call("ningún bulto nombra un modelo que no está", modelos_rotos, [])
	comprobar.call("y hay muebles con malla de verdad", con_modelo > 0, true)

	# Y al revés: todo modelo del árbol tiene su ficha de procedencia. Lo cubre
	# `_procedencia()` en las dos direcciones, así que aquí solo se comprueba que
	# los modelos entren por ese camino y no por otro.
	var sin_ficha := []
	var registro = JSON.parse_string(FileAccess.get_file_as_string("res://assets/procedencia.json"))
	var rutas := []
	for ficha in registro.get("assets", []):
		rutas.append(ficha.get("ruta", ""))
	for nombre in DirAccess.get_files_at(Modelos.RUTA):
		if nombre.ends_with(".import") or nombre.ends_with(".uid"):
			continue
		if not ("modelos/" + nombre) in rutas:
			sin_ficha.append(nombre)
	comprobar.call("ningún modelo sin ficha de procedencia", sin_ficha, [])

	# Y las salidas forman un ciclo cerrado que vuelve al archivo: un sitio del
	# que no se sale es un sitio donde se acaba la partida sin decirlo.
	var rotos := []
	var sin_salida := []
	for fase in EspaciosCatalogo.POR_FASE:
		var espacio: Dictionary = EspaciosCatalogo.POR_FASE[fase]
		var salidas: Array = espacio.get("salidas", [])
		if salidas.is_empty():
			sin_salida.append(fase)
		for salida in salidas:
			# Una salida lleva a otra fase del día, abre una PANTALLA o se
			# queda donde está. Las tres se declaran aquí: si aparece un
			# destino que no es ninguna, es un sitio al que no se puede ir.
			#
			# El cuenco es de los terceros (#92): se pisa, se le da de comer al
			# gato y se sigue estando en casa. No es una fase ni una pantalla,
			# y por eso hay que nombrarlo para que esta guarda no lo cante.
			if (
				not EspaciosCatalogo.POR_FASE.has(salida["destino"])
				and not salida["destino"] in ["sueño", "expediente", "cuenco"]
			):
				rotos.append("%s -> %s" % [fase, salida["destino"]])
	comprobar.call("ningún espacio es un callejón sin salida", sin_salida, [])
	comprobar.call("ninguna salida lleva a un sitio que no existe", rotos, [])

	# Las salidas siguen el orden del día: no hay atajos que se salten una fase.
	var desordenadas := []
	var pantallas := []
	for fase in EspaciosCatalogo.POR_FASE:
		for salida in EspaciosCatalogo.POR_FASE[fase].get("salidas", []):
			if not Jornada.FASES.has(salida["destino"]):
				pantallas.append(salida["destino"])
				continue
			if salida["destino"] != Jornada.siguiente_fase(fase):
				desordenadas.append("%s -> %s" % [fase, salida["destino"]])
	comprobar.call("las salidas siguen el orden del día", desordenadas, [])

	# Y cada fase tiene UNA sola salida hacia el día siguiente: dos formas de
	# fichar es una forma de cobrar dos veces.
	for fase in EspaciosCatalogo.POR_FASE:
		var hacia_el_dia: Array = EspaciosCatalogo.POR_FASE[fase].get("salidas", []).filter(
			func(s): return Jornada.FASES.has(s["destino"])
		)
		comprobar.call("de %s se sale por un solo sitio" % fase, hacia_el_dia.size(), 1)

	# Los dos sitios que se pisan y NO llevan a otra fase: el puesto de trabajo,
	# que abre el expediente, y el cuenco del gato (#92), donde se sigue estando
	# en casa. Se listan para que añadir un tercero tenga que decirse aquí.
	comprobar.call(
		"los sitios que se pisan sin cambiar de fase son el puesto y el cuenco",
		pantallas,
		["expediente", "cuenco"]
	)

	# Se entra pisando suelo, no dentro de un muro ni fuera de la sala.
	var mal_situadas := []
	for fase in EspaciosCatalogo.POR_FASE:
		var espacio: Dictionary = EspaciosCatalogo.POR_FASE[fase]
		var medidas: Vector2 = espacio["suelo"]
		var entrada: Vector3 = espacio["entrada"]
		if absf(entrada.x) >= medidas.x / 2.0 or absf(entrada.z) >= medidas.y / 2.0:
			mal_situadas.append(fase)
	comprobar.call("se entra dentro de la sala", mal_situadas, [])


# --- Las acciones del día y lo que sobrevive a un despido --------------------


static func _acciones_y_vuelta(comprobar: Callable) -> void:
	var dia := Jornada.nueva()
	comprobar.call("el día empieza con sus acciones", dia["acciones"], Jornada.ACCIONES_POR_DIA)
	comprobar.call("y no está agotado", Jornada.jornada_agotada(dia), false)

	for i in Jornada.ACCIONES_POR_DIA:
		comprobar.call("queda acción %d" % (i + 1), Jornada.gastar_accion(dia), true)
	comprobar.call("agotadas, no se puede hacer nada más", Jornada.gastar_accion(dia), false)
	comprobar.call("y la jornada se declara agotada", Jornada.jornada_agotada(dia), true)

	# Fuera del archivo no se gastan acciones: andar a casa no es trabajar.
	var fuera := Jornada.nueva()
	fuera["fase"] = "trayecto"
	comprobar.call("fuera del archivo no se gastan acciones", Jornada.gastar_accion(fuera), false)
	comprobar.call("y no se descuenta nada", fuera["acciones"], Jornada.ACCIONES_POR_DIA)

	# El día siguiente devuelve las acciones.
	dia["fase"] = "sueño"
	Jornada.despertar(dia)
	comprobar.call("el día nuevo trae acciones otra vez", dia["acciones"], Jornada.ACCIONES_POR_DIA)

	# --- El despido ---
	var vida := Jornada.nueva()
	vida["dia"] = 12
	vida["dinero"] = 900
	vida["cerrados_hoy"] = 2
	vida["leido_hoy"] = ["MEMO-1999-088"]
	vida["gato"]["dias_sin_comer"] = 2
	Jornada.reiniciar_vuelta(vida)

	comprobar.call(
		"tras el despido se empieza otra vida laboral",
		[vida["dia"], vida["cerrados_hoy"], vida["leido_hoy"]],
		[1, 0, []]
	)
	comprobar.call("con el dinero de partida", vida["dinero"], Jornada.nueva()["dinero"])
	comprobar.call(
		"pero el gato se queda como estaba",
		[vida["gato"]["presente"], vida["gato"]["dias_sin_comer"]],
		[true, 2]
	)

	# Y si se había ido, no vuelve: es la única cosa que no da segundas
	# oportunidades, precisamente porque no es del trabajo.
	var sin_gato := Jornada.nueva()
	sin_gato["gato"]["presente"] = false
	Jornada.reiniciar_vuelta(sin_gato)
	comprobar.call(
		"un gato que se fue no vuelve con la vuelta nueva", sin_gato["gato"]["presente"], false
	)


# --- Acusar y cerrar ---------------------------------------------------------


static func _acusacion(comprobar: Callable) -> void:
	var contenido := Contenido.new()
	contenido.cargar()
	var caso: Dictionary = contenido.casos[0]
	var todas_sus_pistas: Array = caso["pistas"].map(func(p): return p["id"])

	var estado := Partida.nueva()
	var dia := Jornada.nueva()

	comprobar.call(
		"un expediente empieza abierto", Acusacion.esta_cerrado(estado, caso["id"]), false
	)

	# Acusar sin haber leído nada: se puede, y por eso duele.
	var precipitada := Acusacion.acusar(estado, dia, caso, caso["sospechosos"][0], [])
	comprobar.call("se puede firmar sin evidencia", precipitada["resultado"], "cerrado")
	comprobar.call("y el sistema lo apunta", precipitada["precipitada"], true)
	comprobar.call("cuesta una vida", precipitada["vida"], Partida.VIDA_MAXIMA - 1)
	comprobar.call("pero cuenta como cerrado igual: la nómina no distingue", dia["cerrados_hoy"], 1)
	comprobar.call("gasta una acción del día", dia["acciones"], Jornada.ACCIONES_POR_DIA - 1)
	comprobar.call(
		"y trae el desenlace de ese sospechoso",
		precipitada["desenlace"] == caso["sospechosos"][0]["desenlace"],
		true
	)

	# Irreversible: no se firma dos veces.
	comprobar.call("el expediente queda cerrado", Acusacion.esta_cerrado(estado, caso["id"]), true)
	var repetida := Acusacion.acusar(estado, dia, caso, caso["sospechosos"][1], [])
	comprobar.call("no se puede volver a firmar", repetida["resultado"], "ya_cerrado")
	comprobar.call(
		"y no gasta acción por intentarlo", dia["acciones"], Jornada.ACCIONES_POR_DIA - 1
	)
	comprobar.call(
		"el veredicto sigue siendo el primero",
		Acusacion.veredicto_de(estado, caso["id"]),
		caso["sospechosos"][0]["id"]
	)

	# Con la evidencia suficiente no hay castigo.
	var limpio := Partida.nueva()
	var dia2 := Jornada.nueva()
	var bien := Acusacion.acusar(limpio, dia2, caso, caso["sospechosos"][0], todas_sus_pistas)
	comprobar.call("con todas las pistas no es precipitada", bien["precipitada"], false)
	comprobar.call("y no cuesta vidas", bien["vida"], Partida.VIDA_MAXIMA)

	# Sin acciones no se puede acusar, y no se firma nada a medias.
	var agotado := Partida.nueva()
	var sin_dia := Jornada.nueva()
	sin_dia["acciones"] = 0
	var tarde := Acusacion.acusar(agotado, sin_dia, caso, caso["sospechosos"][0], todas_sus_pistas)
	comprobar.call("sin acciones no se acusa", tarde["resultado"], "sin_acciones")
	comprobar.call(
		"y el expediente sigue abierto", Acusacion.esta_cerrado(agotado, caso["id"]), false
	)

	# --- El careo ---
	comprobar.call("un sospechoso sin réplicas no abre duelo", bien["duelo"], {})
	var con_ataques := func(s): return not s.get("ataques", []).is_empty()
	var alguno_con_ataques := func(c): return c["sospechosos"].any(con_ataques)
	var caso6: Dictionary = contenido.casos.filter(alguno_con_ataques)[0]
	var con_replicas: Dictionary = caso6["sospechosos"].filter(con_ataques)[0]
	var careo := Acusacion.acusar(Partida.nueva(), Jornada.nueva(), caso6, con_replicas, [])
	comprobar.call("uno con réplicas sí", careo["duelo"]["nombre"], con_replicas["nombre"])

	# El duelo no cambia el veredicto: ya está firmado. Perderlo cuesta una vida.
	var duelista := Partida.nueva()
	var dia3 := Jornada.nueva()
	Acusacion.acusar(duelista, dia3, caso6, con_replicas, [])
	var antes_de_perder: int = duelista["vida"]
	Acusacion.resolver_duelo(duelista, dia3, false)
	comprobar.call("perder el careo cuesta una vida", duelista["vida"], antes_de_perder - 1)
	comprobar.call(
		"pero el expediente sigue cerrado con el mismo veredicto",
		Acusacion.veredicto_de(duelista, caso6["id"]),
		con_replicas["id"]
	)
	var ganador := Partida.nueva()
	var vida_intacta: int = ganador["vida"]
	Acusacion.resolver_duelo(ganador, Jornada.nueva(), true)
	comprobar.call("ganarlo no cuesta nada", ganador["vida"], vida_intacta)

	# --- El despido ---
	var ultimo := Partida.nueva()
	var dia4 := Jornada.nueva()
	ultimo["vida"] = 1
	dia4["dia"] = 9
	dia4["gato"]["dias_sin_comer"] = 2
	var caida := Acusacion.perder_vida(ultimo, dia4, 1)
	comprobar.call("sin vidas, te reasignan", caida["despido"], true)
	comprobar.call("y empieza otra vida laboral", dia4["dia"], 1)
	comprobar.call(
		"con las vidas de la dificultad", ultimo["vida"], Acusacion.DIFICULTADES["normal"]["vidas"]
	)
	comprobar.call("el gato sigue siendo tuyo", dia4["gato"]["dias_sin_comer"], 2)

	comprobar.call(
		"en fácil se exige menos evidencia",
		Acusacion.DIFICULTADES["facil"]["umbral"] < Acusacion.DIFICULTADES["dificil"]["umbral"],
		true
	)


# --- La cinemática del careo y el cuñado -------------------------------------


static func _careo(comprobar: Callable) -> void:
	var contenido := Contenido.new()
	contenido.cargar()
	var acusado: Dictionary = {}
	for c in contenido.casos:
		for s in c["sospechosos"]:
			if not s.get("ataques", []).is_empty():
				acusado = s
				break

	var rodaje := CareoCinematica.planos_de(acusado, "ACTA-1958-001")
	comprobar.call("la cinemática tiene sus cuatro planos", rodaje.size(), 4)
	comprobar.call("dura lo que dura", Cinematica.duracion(rodaje) > 0.0, true)
	comprobar.call("presenta al acusado por su nombre", rodaje[1]["rotulo"], acusado["nombre"])
	comprobar.call("y dice su cargo", rodaje[2]["rotulo"].is_empty(), false)
	comprobar.call(
		"el último plano cita el expediente", rodaje[3]["rotulo"], "EXPEDIENTE ACTA-1958-001"
	)

	# Sin folio no se inventa un número: se dice que no consta.
	comprobar.call(
		"sin expediente lo dice",
		CareoCinematica.planos_de(acusado)[3]["rotulo"],
		"EXPEDIENTE SIN NÚMERO"
	)

	# Rodar una no puede estropear la siguiente.
	rodaje[0]["rotulo"] = "ESTROPEADO"
	comprobar.call(
		"los planos se entregan en copia", CareoCinematica.planos_de(acusado)[0]["rotulo"], ""
	)

	# Un acusado sin descripción no se queda sin cartela: que no conste su
	# cargo es parte del problema, y se dice.
	comprobar.call(
		"un acusado sin descripción tiene cartela igual",
		CareoCinematica.planos_de({"nombre": "Nadie"})[2]["rotulo"],
		TranslationServer.translate(CareoCinematica.CARGO_POR_DEFECTO)
	)

	# --- El cuñado ---
	var azar := func(): return 0.0
	comprobar.call("llega diciendo algo", Cunado.comentario("llegada", azar).is_empty(), false)
	comprobar.call(
		"comenta una ronda perdida", Cunado.comentario("gana_rival", azar).is_empty(), false
	)
	comprobar.call(
		"un momento que no existe le deja callado", Cunado.comentario("no_existe", azar), ""
	)

	# Si se ha gastado una habilidad, es de lo que habla: es lo que miraría.
	comprobar.call(
		"comenta la habilidad antes que el resultado",
		(
			Cunado.sobre_ronda({"habilidad": "comunismo", "veredicto": "gana_rival"}, azar)
			in Cunado.AL_GASTAR_HABILIDAD.map(TranslationServer.translate)
		),
		true
	)
	comprobar.call(
		"y si no hubo, el resultado",
		(
			Cunado.sobre_ronda({"habilidad": "", "veredicto": "gana_jugador"}, azar)
			in Cunado.AL_GANAR_RONDA.map(TranslationServer.translate)
		),
		true
	)

	# LA REGLA: no da información. Si nunca nombra una jugada, no puede estar
	# diciéndote qué hacer. Se comprueba sobre TODO lo que puede decir, no sobre
	# una muestra: una regla sobre lo que se dice solo vale así.
	var chivatazos := []
	for frase in Cunado.todas_las_frases():
		for prohibida in Cunado.palabras_prohibidas():
			if frase.contains(prohibida):
				chivatazos.append(frase)
	comprobar.call("el cuñado no nombra ninguna jugada", chivatazos, [])
	comprobar.call(
		"y tiene algo que decir en cada momento",
		Cunado.POR_MOMENTO.values().all(func(f): return f.size() >= 3),
		true
	)


# --- El reproductor común de cinemáticas (#67) -------------------------------


static func _plantas(comprobar: Callable) -> void:
	# El caso fácil sigue saliendo igual: una sala rectangular tiene cuatro
	# muros, ni uno más. Si la generalización rompiera esto, habría cambiado
	# todos los sitios del día por el camino.
	var caja := [Rect2i(0, 0, 5, 4)]
	comprobar.call("una planta rectangular da cuatro muros", Planta.contorno(caja).size(), 4)
	comprobar.call("y una sola losa de suelo", Planta.rectangulos(caja), [Rect2i(0, 0, 5, 4)])

	# Una ele tiene seis: es la primera forma que una caja no puede declarar.
	var ele := [Rect2i(0, 0, 4, 2), Rect2i(0, 2, 2, 2)]
	comprobar.call("una ele da seis muros", Planta.contorno(ele).size(), 6)

	# Y un anillo, ocho: cuatro fuera y cuatro dentro. El patio no lo declara
	# nadie — sale de que también es contorno.
	var anillo := [
		Rect2i(0, 0, 5, 1),
		Rect2i(0, 4, 5, 1),
		Rect2i(0, 0, 1, 5),
		Rect2i(4, 0, 1, 5),
	]
	comprobar.call(
		"un anillo da ocho muros (los cuatro del patio incluidos)",
		Planta.contorno(anillo).size(),
		8
	)
	comprobar.call("y su patio no es suelo", Planta.contiene(anillo, Vector2i(2, 2)), false)

	# La invariante que de verdad importa: los muros tapan TODO el borde. Un
	# tramo que faltara es un hueco por el que se sale de la sala, y eso no se
	# ve en una captura sino andando hasta que te caes del mundo.
	for nombre in ["caja", "ele", "anillo"]:
		var bloques: Array = {"caja": caja, "ele": ele, "anillo": anillo}[nombre]
		var celdas := Planta.celdas(bloques)
		var expuestas := 0
		for celda in celdas:
			for lado in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if not celdas.has(celda + lado):
					expuestas += 1
		var cubiertas := 0
		for tramo in Planta.contorno(bloques):
			cubiertas += tramo["hasta"] - tramo["desde"]
		comprobar.call("los muros cubren todo el borde de %s" % nombre, cubiertas, expuestas)

	# El suelo se parte en rectángulos que no se pisan entre sí: dos losas en el
	# mismo plano son dos caras peleándose por el mismo píxel.
	var solapadas := [Rect2i(0, 0, 6, 3), Rect2i(2, 0, 6, 3)]
	var cubierto := 0
	var vistas := {}
	var repetidas := 0
	for rect in Planta.rectangulos(solapadas):
		cubierto += rect.size.x * rect.size.y
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			for z in range(rect.position.y, rect.position.y + rect.size.y):
				if vistas.has(Vector2i(x, z)):
					repetidas += 1
				vistas[Vector2i(x, z)] = true
	comprobar.call("bloques solapados se cubren enteros", cubierto, Planta.area(solapadas))
	comprobar.call("y sin poner dos losas en la misma celda", repetidas, 0)

	# La distancia es de camino, no en línea recta: en un anillo, la celda de
	# enfrente está al lado y a media vuelta de andar.
	var lejana := Planta.mas_lejana(anillo, Vector2i(0, 0))
	comprobar.call(
		"la celda más lejana de un anillo está a media vuelta", lejana == Vector2i(0, 0), false
	)
	comprobar.call("y es una celda de la planta", Planta.contiene(anillo, lejana), true)

	# Las medidas: una celda son dos metros y la planta aparece centrada.
	comprobar.call(
		"la planta se centra en el mundo",
		Planta.centro_en_metros([Rect2i(0, 0, 2, 2)], Vector2i(0, 0)),
		Vector3(-Planta.CELDA / 2.0, 0, -Planta.CELDA / 2.0)
	)


# --- El esqueleto del sueño (#86) -------------------------------------------


static func _sueno(comprobar: Callable) -> void:
	# Las salas del sueño son pocas y GRANDES, de una pieza, y ninguna es un
	# rectángulo: una caja más grande no es una sala rara.
	var pequenas := []
	var partidas := []
	var cajas := []
	var entradas_fuera := []
	for id in SuenoFormas.ids():
		var forma := SuenoFormas.de(id)
		var bloques: Array = forma["bloques"]
		if Planta.area(bloques) < SuenoFormas.MINIMO_GRANDE:
			pequenas.append(id)
		if not Planta.conexa(bloques):
			partidas.append(id)
		if Planta.contorno(bloques).size() <= 4:
			cajas.append(id)
		if not Planta.contiene(bloques, forma["entrada"]):
			entradas_fuera.append(id)
	comprobar.call("ninguna sala del sueño es pequeña", pequenas, [])
	comprobar.call("ninguna está partida en dos", partidas, [])
	comprobar.call("ninguna es una caja", cajas, [])
	comprobar.call("se entra dentro de la sala", entradas_fuera, [])
	comprobar.call(
		"hay salas de sobra para una noche",
		SuenoFormas.ids().size() >= Sueno.ESCENAS_POR_NOCHE,
		true
	)

	# Una noche son tres escenas distintas.
	var noche := Sueno.noche(1, ["MEMO-1999-088"], [])
	comprobar.call("una noche son tres escenas", noche.size(), Sueno.ESCENAS_POR_NOCHE)
	var sin_repetir := {}
	for id in noche:
		sin_repetir[id] = true
	comprobar.call(
		"y no se repite ninguna dentro de la misma noche", sin_repetir.size(), noche.size()
	)

	# El sueño es de su día: misma lectura, mismo sueño; otra lectura, otro.
	comprobar.call(
		"el mismo día leyendo lo mismo sueña lo mismo", Sueno.noche(1, ["MEMO-1999-088"], []), noche
	)
	comprobar.call(
		"leer otra cosa cambia la noche", Sueno.noche(1, ["FAC-1998-014"], []) == noche, false
	)
	comprobar.call("y otro día también", Sueno.noche(2, ["MEMO-1999-088"], []) == noche, false)

	# El mapa crece: mientras queden salas sin ver, se ven salas sin ver.
	var mapa := []
	for id in noche:
		Sueno.recordar(mapa, id)
	comprobar.call("el mapa crece de tres en tres", mapa.size(), Sueno.ESCENAS_POR_NOCHE)
	comprobar.call(
		"y una sala ya vista no se apunta dos veces", Sueno.recordar(mapa, noche[0]), false
	)
	var segunda := Sueno.noche(2, ["FAC-1998-014"], mapa)
	var nuevas := segunda.filter(func(id): return not mapa.has(id))
	comprobar.call(
		"la segunda noche enseña lo que queda sin ver",
		nuevas.size(),
		mini(Sueno.ESCENAS_POR_NOCHE, SuenoFormas.ids().size() - mapa.size())
	)

	# Solo la última escena despierta. Las otras dos llevan a la siguiente: un
	# sueño que devolviera al archivo en la primera sala no sería tres escenas.
	var destinos := []
	for i in noche.size():
		destinos.append(Sueno.espacio(noche[i], noche.size() - 1 - i)["salidas"][0]["destino"])
	comprobar.call("solo la última escena despierta", destinos, ["sueño", "sueño", "archivo"])

	# La salida no está donde entras, y está dentro de la sala.
	var espacio := Sueno.espacio(noche[0], 2)
	comprobar.call(
		"no se sale por donde se entra",
		espacio["salidas"][0]["pos"] - Vector3(0, 1.1, 0) == espacio["entrada"],
		false
	)

	# --- El mapa es de la vuelta, no de por vida ---
	var vida := Jornada.nueva()
	vida["fase"] = "casa"
	vida["leido_hoy"] = ["MEMO-1999-088"]
	Jornada.dormir(vida)
	comprobar.call("dormir compone la noche", vida["sueno_escenas"].size(), Sueno.ESCENAS_POR_NOCHE)
	Jornada.despertar(vida)
	comprobar.call("y despertar no deja media noche esperando", vida["sueno_escenas"], [])

	vida["mapa"] = ["patio", "peine"]
	Jornada.reiniciar_vuelta(vida)
	comprobar.call("el mapa del sueño no sobrevive al despido", vida["mapa"], [])


# --- Que el texto siga fuera del código (#105) -------------------------------


## Extraer el texto una vez no sirve de nada si la pantalla siguiente vuelve a
## escribirlo dentro. Estas tres comprobaciones son lo que impide que esto se
## deshaga solo: no revisan el español, revisan que el español no esté aquí.
static func _traducciones(comprobar: Callable) -> void:
	var claves := {}
	var csv := FileAccess.open("res://datos/textos.csv", FileAccess.READ)
	comprobar.call("hay fichero de traducción", csv != null, true)
	if csv == null:
		return
	var primera := true
	while not csv.eof_reached():
		var linea := csv.get_csv_line()
		if primera:
			comprobar.call("la cabecera declara clave e idioma", Array(linea), ["clave", "es"])
			primera = false
			continue
		if linea.size() < 2 or linea[0].is_empty():
			continue
		claves[linea[0]] = linea[1]
	csv.close()

	var fuentes := PackedStringArray()
	for nombre in DirAccess.get_files_at("res://guion"):
		if nombre.ends_with(".gd"):
			fuentes.append(FileAccess.get_file_as_string("res://guion/" + nombre))
	# Los CATÁLOGOS también piden claves, no solo el código. El texto de los
	# casos vive en `casos.json`, así que un título traducido es una clave que
	# nadie nombra en un `.gd` — y sin esto se contaba como huérfana y se
	# borraba. Vale en las dos direcciones: una clave mal escrita en el catálogo
	# se caza igual que si estuviera en un guion, porque lo que se busca es la
	# FORMA de una clave.
	for catalogo in CATALOGOS:
		fuentes.append(FileAccess.get_file_as_string(catalogo))
	var codigo := "\n".join(fuentes)

	# 1. Toda clave que el código nombra existe. Godot devuelve la clave tal
	#    cual cuando no la encuentra, así que una errata no revienta: se ve en
	#    pantalla como un grito en mayúsculas y nadie la nota hasta que alguien
	#    llega a esa esquina del juego. Pasó de verdad con los nombres de las
	#    jugadas, y por eso esto NO busca solo `tr("...")`: media docena de
	#    claves viven en tablas (`Combate.ETIQUETAS`, el cuñado, los rótulos de
	#    los sitios) y se traducen lejos de donde se escriben. Lo que se busca
	#    es la FORMA de una clave, que la convención hace inconfundible.
	var pedidas := RegEx.create_from_string('"([A-Z][A-Z0-9]*(?:_[A-Z0-9]+)+)"')
	var sin_texto := []
	for hallazgo in pedidas.search_all(codigo):
		if not claves.has(hallazgo.get_string(1)):
			sin_texto.append(hallazgo.get_string(1))
	comprobar.call("ninguna clave pedida se queda sin texto", sin_texto, [])

	# 2. Y ninguna sobra. Una clave que ya no pide nadie es texto que se sigue
	#    traduciendo —y pagando— para una pantalla que se quitó.
	var huerfanas := []
	for clave in claves:
		if not codigo.contains('"%s"' % clave):
			huerfanas.append(clave)
	comprobar.call("ninguna clave se queda sin quien la pida", huerfanas, [])

	# 3. Ninguna pantalla escribe texto a mano. Es la comprobación que de
	#    verdad sostiene esto: sin ella, la casa y el sueño llegan con el suyo
	#    dentro y en tres pantallas hemos vuelto al principio.
	# La letra tiene que ser letra de verdad: la "n" de un salto de línea y la
	# "s" de un "%s" no son texto, y sin descontarlas la guarda se dispara sobre
	# cadenas que no dicen nada.
	var literales := RegEx.create_from_string(
		'(\\.text|tooltip_text|placeholder_text)\\s*(=|\\+=)\\s*"[^"]*(?<![\\\\%])[a-zá-úA-ZÁ-Ú]'
	)
	var escritos := []
	for nombre in DirAccess.get_files_at("res://guion"):
		if not nombre.ends_with(".gd"):
			continue
		var fuente := FileAccess.get_file_as_string("res://guion/" + nombre)
		for linea in fuente.split("\n"):
			if literales.search(linea) != null:
				escritos.append("%s: %s" % [nombre, linea.strip_edges()])
	comprobar.call("ninguna pantalla escribe texto a mano", escritos, [])


# --- De qué está hecho el sueño (#87) ---------------------------------------


static func _sueno_contenido(comprobar: Callable) -> void:
	var casos := [
		{
			"id": "caso1",
			"registros":
			[
				{"id": "memo1", "folio": "MEMO-1"},
				{"id": "fac1", "folio": "FAC-1"},
				{"id": "acta1", "folio": "ACTA-1"},
			],
			"pistas":
			[
				{"id": "p1", "registroOrigen": "memo1", "fraseGatillo": "sin revisión previa"},
				{"id": "p2", "registroOrigen": "memo1", "fraseGatillo": "por orden directa"},
				{"id": "p3", "registroOrigen": "acta1", "fraseGatillo": "no consta"},
			],
			"sospechosos":
			[
				{"id": "s1", "nombre": "J. Ibarra"},
				{"id": "s2", "nombre": "Comité de Adquisiciones"},
			],
		}
	]

	# Solo lo LEÍDO hoy: un expediente que no se abrió no está en el sueño.
	comprobar.call(
		"sin leer nada, no hay nada que deformar",
		SuenoContenido.fuentes([], casos, ["p1"], {}),
		{"frases": [], "figuras": [], "casos": []}
	)

	# Y solo las frases que SÍ notaste. La que se te pasó no se escribe en la
	# pared: eso sería decirte dónde mirar, y dormir pasaría a ser lo óptimo.
	var leido := SuenoContenido.fuentes(["MEMO-1"], casos, ["p1"], {})
	comprobar.call("se escriben las frases que notaste", leido["frases"], ["sin revisión previa"])

	comprobar.call(
		"y no las que se te pasaron",
		SuenoContenido.fuentes(["MEMO-1"], casos, [], {})["frases"],
		[]
	)

	# Una pista descubierta en otro documento tampoco: el sueño es de HOY.
	comprobar.call(
		"ni las de un documento que hoy no abriste",
		SuenoContenido.fuentes(["MEMO-1"], casos, ["p1", "p3"], {})["frases"],
		["sin revisión previa"]
	)

	# Las figuras: todos los sospechosos del expediente que tocaste, y el que
	# firmaste se distingue.
	comprobar.call("aparecen todos los sospechosos del expediente", leido["figuras"].size(), 2)
	comprobar.call(
		"y ninguno es el acusado si no has acusado",
		leido["figuras"].any(func(f): return f["acusado"]),
		false
	)
	var tras_acusar := SuenoContenido.fuentes(["MEMO-1"], casos, ["p1"], {"caso1": "s2"})
	comprobar.call(
		"a quien firmaste se le ve distinto",
		tras_acusar["figuras"].map(func(f): return f["acusado"]),
		[false, true]
	)

	# El reparto: lo leído amuebla las TRES salas, no una.
	var reparto := SuenoContenido.repartir(tras_acusar, Sueno.ESCENAS_POR_NOCHE, 7)
	comprobar.call(
		"el reparto tiene una entrada por escena", reparto.size(), Sueno.ESCENAS_POR_NOCHE
	)
	var repartidas := 0
	for escena in reparto:
		repartidas += escena["figuras"].size()
	comprobar.call(
		"y no se pierde ni se duplica ninguna figura", repartidas, tras_acusar["figuras"].size()
	)
	comprobar.call(
		"con dos figuras y tres salas, una sala se queda vacía",
		reparto.map(func(e): return e["figuras"].size()),
		[1, 1, 0]
	)
	comprobar.call(
		"el mismo día reparte igual",
		SuenoContenido.repartir(tras_acusar, Sueno.ESCENAS_POR_NOCHE, 7),
		reparto
	)

	# --- Cómo cae en la sala ---
	var escena := Sueno.espacio("patio", 2, reparto[0])
	comprobar.call(
		"la figura de la escena se planta en la sala",
		escena["figuras"].size(),
		reparto[0]["figuras"].size()
	)
	var dentro := Planta.celdas(SuenoFormas.de("patio")["bloques"])
	var fuera := []
	for figura in escena["figuras"]:
		# Nadie se queda dentro del patio al que no se entra.
		if not dentro.has(_celda_de(SuenoFormas.de("patio")["bloques"], figura["pos"])):
			fuera.append(figura["rotulo"])
	comprobar.call("y ninguna figura acaba fuera de la sala", fuera, [])

	# Los carteles miran hacia dentro. Es el fallo que ninguna prueba ve y que
	# se nota a la primera: media colección pintada por fuera del edificio.
	var con_frases := Sueno.espacio("crucero", 1, {"frases": ["una frase"], "figuras": []})
	comprobar.call("la frase se cuelga de una pared", con_frases["carteles"].size(), 1)
	var bloques: Array = SuenoFormas.de("crucero")["bloques"]
	var pared: Dictionary = Planta.paredes(bloques)[0]
	var sitio := Planta.en_pared(bloques, pared, 0.5)
	comprobar.call(
		"y a este lado del muro está la sala",
		Planta.contiene(bloques, _celda_de(bloques, sitio["pos"])),
		true
	)

	# Y quedan por FUERA del muro. Un muro es una caja centrada en la línea de
	# la planta: separarse menos de medio grosor deja la frase dentro de la
	# pared, que no es un parpadeo sino una frase que no está.
	comprobar.call(
		"un cartel se cuelga por delante del muro y no dentro",
		Sueno.SEPARACION_PARED > Espacio3D.GROSOR_MURO / 2.0,
		true
	)

	# Sin nada leído, la sala se monta igual y sale vacía.
	var vacia := Sueno.espacio("peine", 0)
	comprobar.call(
		"una noche sin lecturas da salas vacías", [vacia["figuras"], vacia["carteles"]], [[], []]
	)
	comprobar.call("pero con su salida", vacia["salidas"].size(), 1)


## En qué celda cae un punto del mundo. Solo para las pruebas: es el camino de
## vuelta de `Planta.centro_en_metros`, y sirve para preguntar si algo acabó
## dentro de la sala o en mitad de un muro.
static func _celda_de(bloques: Array, pos: Vector3) -> Vector2i:
	var origen := Planta.esquina_en_metros(bloques, Vector2i.ZERO)
	return Vector2i(
		int(floor((pos.x - origen.x) / Planta.CELDA)), int(floor((pos.z - origen.z) / Planta.CELDA))
	)
