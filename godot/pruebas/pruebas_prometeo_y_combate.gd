## Segundo tramo de la suite de `pruebas.gd`: Prometeo, partida guardada,
## historias, combate, ventanilla, jornada y procedencia de assets.
##
## Partida en varios ficheros por el tope de `gdlint` (max-file-lines): cada
## función es la MISMA prueba que antes, ahora `static` porque no necesita
## estado propio, recibiendo `comprobar` como el `Callable` que ya llevaba la
## cuenta de pasadas y fallos en `pruebas.gd`.
class_name PruebasPrometeoYCombate
extends RefCounted

const RUTA_PRUEBA := "user://partida-de-prueba.json"
const RUTA_ASSETS := "res://assets"

## Dos sitios donde un guardado NO puede salir bien: una carpeta que no existe
## y un nombre ya ocupado por un directorio con algo dentro. Son las dos formas
## de fallar de `Partida.guardar()` —el temporal y el renombrado—, provocadas a
## propósito para comprobar que ninguna se lleva la partida por delante (#191).
const RUTA_SIN_CARPETA := "user://carpeta-que-no-existe/partida-de-prueba.json"
const RUTA_ESTORBADA := "user://estorbo-de-prueba.json"

# --- prometeo-logic.test.js -------------------------------------------------


static func _prometeo(comprobar: Callable) -> void:
	# fusionarConGuardado
	var actuales := [{"id": "a", "titulo": "Nuevo título", "desbloqueado": false}]
	comprobar.call(
		"fusión: conserva el estado guardado y adopta los metadatos nuevos",
		Prometeo.fusionar_con_guardado(
			[{"id": "a", "titulo": "Título viejo", "desbloqueado": true}],
			actuales,
			["desbloqueado"]
		),
		[{"id": "a", "titulo": "Nuevo título", "desbloqueado": true}]
	)
	comprobar.call(
		"fusión: sin guardado previo quedan los valores de serie",
		Prometeo.fusionar_con_guardado([], actuales, ["desbloqueado"]),
		actuales
	)
	comprobar.call(
		"fusión: encuentra el guardado por un id renombrado",
		(
			Prometeo
			. fusionar_con_guardado(
				[{"id": "viejo", "desbloqueado": true}], actuales, ["desbloqueado"], {"a": "viejo"}
			)[0]["desbloqueado"]
		),
		true
	)
	comprobar.call("fusión: no muta la lista de entrada", actuales[0]["desbloqueado"], false)

	# desbloquearCartaEnLista
	var tarot := [{"id": "la-luna", "recogida": false}, {"id": "el-loco", "recogida": true}]
	comprobar.call("carta nueva: hay novedad", Prometeo.desbloquear_carta(tarot, "la-luna"), true)
	comprobar.call(
		"carta ya recogida: no hay novedad", Prometeo.desbloquear_carta(tarot, "el-loco"), false
	)
	comprobar.call(
		"carta inexistente: no hay novedad", Prometeo.desbloquear_carta(tarot, "no-existe"), false
	)

	# esAcusacionPrecipitada
	comprobar.call(
		"acusar con poca evidencia es precipitado", Prometeo.acusacion_precipitada(1, 5, 0.5), true
	)
	comprobar.call(
		"acusar justo en el umbral no es precipitado",
		Prometeo.acusacion_precipitada(3, 6, 0.5),
		false
	)
	comprobar.call(
		"un caso sin pistas nunca da acusación precipitada",
		Prometeo.acusacion_precipitada(0, 0, 0.5),
		false
	)

	# calcularEjeGanador
	var historias := {"la-luna": "neoliberal", "el-sol": "neoliberal", "el-carro": "centrista"}
	comprobar.call(
		"gana el eje más votado",
		Prometeo.eje_ganador(historias, ["la-luna", "el-sol", "el-carro"]),
		"neoliberal"
	)
	comprobar.call(
		"en empate gana el primero del orden",
		Prometeo.eje_ganador({"a": "centrista", "b": "comunismo"}, ["a", "b"]),
		"comunismo"
	)
	comprobar.call(
		"sin historias resueltas gana el primero del orden",
		Prometeo.eje_ganador({}, []),
		"comunismo"
	)
	comprobar.call(
		"un eje desconocido no cuenta", Prometeo.eje_ganador({"a": "monarquia"}, ["a"]), "comunismo"
	)

	# contarPuntosPorEje
	comprobar.call(
		"puntos por eje",
		Prometeo.puntos_por_eje(historias, ["la-luna", "el-sol", "el-carro"]),
		{"comunismo": 0, "socialdemocrata": 0, "centrista": 1, "neoliberal": 2}
	)
	comprobar.call(
		"una historia sin resolver no puntúa",
		Prometeo.puntos_por_eje(historias, [])["neoliberal"],
		0
	)

	# UTILIDAD_CARTAS: las dos invariantes de #45
	comprobar.call(
		"las ocho historias tienen dos ejes útiles cada una",
		Prometeo.UTILIDAD_CARTAS.values().all(func(u): return u.size() == 2),
		true
	)
	var veces_util := {}
	for eje in Prometeo.EJES:
		veces_util[eje] = 0
	for utiles in Prometeo.UTILIDAD_CARTAS.values():
		for eje in utiles:
			veces_util[eje] += 1
	# Sin esto el juego estaría diciendo cuál es la ideología correcta.
	comprobar.call(
		"cada ideología es útil en exactamente 4 de las 8 cartas",
		veces_util,
		{"comunismo": 4, "socialdemocrata": 4, "centrista": 4, "neoliberal": 4}
	)
	comprobar.call(
		"un eje útil de la carta es pista",
		Prometeo.clasificar_eleccion("la-luna", "centrista"),
		"pista"
	)
	comprobar.call(
		"un eje que no lo es, confusión",
		Prometeo.clasificar_eleccion("la-luna", "comunismo"),
		"confusion"
	)

	# indiceJugadaRival
	comprobar.call(
		"modo ciclo: el ritmo autorado del duelo",
		[
			Prometeo.jugada_rival("ciclo", 0, 3, func(): return 0.0),
			Prometeo.jugada_rival("ciclo", 4, 3, func(): return 0.0)
		],
		[0, 1]
	)
	# Con tirada baja contesta a la última jugada: lo que vence a X es el
	# índice anterior a X en la cadena circular. La tirada va como secuencia y
	# no como valor fijo porque la rama que NO reacciona gasta dos tiradas (una
	# para decidir y otra para elegir), y con un valor único las dos ramas
	# pueden dar el mismo número por casualidad — que es lo que le pasaba a
	# esta prueba antes.
	comprobar.call(
		"modo reactiva: con tirada baja contraataca la jugada 1",
		Prometeo.jugada_rival("reactiva", 0, 3, _tiradas([0.1]), 1),
		0
	)
	comprobar.call(
		"modo reactiva: con tirada alta ignora la jugada y va al azar",
		Prometeo.jugada_rival("reactiva", 0, 3, _tiradas([0.9, 0.5]), 1),
		1
	)
	comprobar.call(
		"modo reactiva: en la primera ronda no hay a qué contestar",
		Prometeo.jugada_rival("reactiva", 0, 3, _tiradas([0.99]), -1),
		2
	)

	# actualizarRacha
	comprobar.call(
		"ganar suma y puede batir la marca",
		Prometeo.actualizar_racha(2, 2, true),
		{"racha": 3, "mejor": 3}
	)
	comprobar.call(
		"ganar sin batir conserva la marca",
		Prometeo.actualizar_racha(1, 9, true),
		{"racha": 2, "mejor": 9}
	)
	comprobar.call(
		"perder devuelve a cero sin tocar la marca",
		Prometeo.actualizar_racha(5, 9, false),
		{"racha": 0, "mejor": 9}
	)

	# reiniciarEstadoPerRunEnEstado: la frontera de #46
	var estado := {
		"vida": 1,
		"despido_mostrado": true,
		"historias_cartas": {"a": "comunismo"},
		"final_politico_mostrado": true,
		"final_verdadero_mostrado": true,
		"epilogo_avisado": true,
		"perdio_vida_en_esta_vuelta": true,
		"tarot":
		[
			{"id": "el-loco", "recogida": false, "gastada": true},
			{"id": "la-luna", "recogida": true, "gastada": true}
		],
		"logros":
		[
			{"id": "desempeno", "por_vuelta": true, "desbloqueado": true},
			{"id": "vitrina", "por_vuelta": false, "desbloqueado": true}
		],
		"cartas_conocidas": ["la-luna"],
		"coliseo_racha_mejor": 7,
		"dificultad": "dura",
		"algunavez_perdio": true,
	}
	Prometeo.reiniciar_vuelta(estado, 3)

	comprobar.call(
		"la vuelta borra la vida y los avisos",
		[estado["vida"], estado["despido_mostrado"], estado["epilogo_avisado"]],
		[3, false, false]
	)
	comprobar.call(
		"la vuelta borra las decisiones políticas y los finales",
		[
			estado["historias_cartas"],
			estado["final_politico_mostrado"],
			estado["final_verdadero_mostrado"]
		],
		[{}, false, false]
	)
	comprobar.call(
		"el tarot vuelve a la posesión inicial: solo El Loco",
		estado["tarot"],
		[
			{"id": "el-loco", "recogida": true, "gastada": false},
			{"id": "la-luna", "recogida": false, "gastada": false}
		]
	)
	comprobar.call(
		"los logros de desempeño se re-bloquean", estado["logros"][0]["desbloqueado"], false
	)
	comprobar.call("los de vitrina NO se tocan", estado["logros"][1]["desbloqueado"], true)
	comprobar.call(
		"la memoria de por vida sobrevive entera",
		[
			estado["cartas_conocidas"],
			estado["coliseo_racha_mejor"],
			estado["dificultad"],
			estado["algunavez_perdio"]
		],
		[["la-luna"], 7, "dura", true]
	)


## Un generador de tiradas guionizado, para poder distinguir las dos ramas del
## rival reactivo.
static func _tiradas(valores: Array) -> Callable:
	var estado := {"i": 0}
	return func():
		var valor: float = valores[estado["i"]]
		estado["i"] += 1
		return valor


# --- Persistencia -----------------------------------------------------------


static func _partida(comprobar: Callable) -> void:
	_borrar_pruebas()

	# Sin fichero se empieza de cero, y se DICE que se empieza de cero: que una
	# partida no se haya podido leer no puede parecerse a no haber jugado nunca.
	var partida := Partida.new()
	comprobar.call(
		"sin partida guardada se empieza una nueva",
		partida.cargar(RUTA_PRUEBA)["resultado"],
		"nueva"
	)
	comprobar.call(
		"los catálogos llegan enteros",
		[partida.estado["logros"].size(), partida.estado["tarot"].size()],
		[20, 22]
	)
	comprobar.call(
		"solo El Loco viene de serie",
		partida.estado["tarot"].filter(func(c): return c["recogida"]).map(func(c): return c["id"]),
		["el-loco"]
	)

	# Ida y vuelta.
	partida.estado["pistas_descubiertas"] = ["p1", "p2"]
	partida.estado["coliseo_racha_mejor"] = 4
	var jornada := Jornada.nueva()
	jornada["dia"] = 5
	jornada["fase"] = "sueño"
	jornada["dinero"] = 310
	jornada["acciones"] = 2
	jornada["plantilla"] = 427
	jornada["gato"] = {"presente": false, "dias_sin_comer": 4}
	jornada["leido_hoy"] = ["MEMO-1999-088"]
	jornada["mapa"] = ["patio"]
	jornada["sueno_escenas"] = ["peine", "crucero"]
	jornada["sueno_resto"] = 42.5
	partida.estado["jornada"] = jornada
	partida.estado["veredictos"] = {"caso1": "sospechoso1"}
	Prometeo.desbloquear_carta(partida.estado["tarot"], "la-luna")
	comprobar.call("guardar dice que guardó", partida.guardar(RUTA_PRUEBA), true)

	var releida := Partida.new()
	comprobar.call("la partida se recupera", releida.cargar(RUTA_PRUEBA)["resultado"], "cargada")
	comprobar.call("recargar conserva toda la jornada", releida.estado.get("jornada", {}), jornada)
	comprobar.call(
		"recargar conserva los veredictos firmes",
		Acusacion.veredicto_de(releida.estado, "caso1"),
		"sospechoso1"
	)
	comprobar.call(
		"con sus pistas y su racha",
		[releida.estado["pistas_descubiertas"], releida.estado["coliseo_racha_mejor"]],
		[["p1", "p2"], 4]
	)
	comprobar.call(
		"y con la carta conseguida",
		releida.estado["tarot"].filter(func(c): return c["recogida"]).map(func(c): return c["id"]),
		["el-loco", "la-luna"]
	)

	# El guardado NO se lleva una copia del contenido: si lo hiciera, reescribir
	# la descripción de un logro dejaría las partidas viejas mostrando la
	# antigua. Solo ids y banderas.
	var crudo := FileAccess.open(RUTA_PRUEBA, FileAccess.READ).get_as_text()
	comprobar.call(
		"la partida guardada no lleva texto de los catálogos",
		crudo.contains("Abriste el menú"),
		false
	)
	comprobar.call(
		"pero sí los ids y su estado",
		crudo.contains("primer-mirada") and crudo.contains("desbloqueado"),
		true
	)
	comprobar.call(
		"y al releerla los títulos vuelven del catálogo",
		releida.estado["logros"][0]["titulo"],
		"Primer mirada"
	)

	# Un logro que la versión nueva añade aparece en una partida antigua sin
	# borrar lo ya conseguido: es la fusión de #46, no una carga a secas.
	var vieja := Partida.nueva()
	vieja.erase("jornada")
	vieja.erase("veredictos")
	vieja["logros"] = [{"id": "sospecha", "desbloqueado": true}]
	vieja["tarot"] = []
	_escribir(RUTA_PRUEBA, vieja)
	var migrada := Partida.new()
	migrada.cargar(RUTA_PRUEBA)
	comprobar.call("la partida anterior al día recibe jornada", migrada.estado["jornada"]["dia"], 1)
	comprobar.call("la partida antigua no inventa firmas", migrada.estado["veredictos"], {})
	comprobar.call(
		"una partida con menos logros recupera el catálogo entero",
		migrada.estado["logros"].size(),
		20
	)
	comprobar.call(
		"y conserva el que ya tenía desbloqueado",
		migrada.estado["logros"].filter(func(l): return l["id"] == "sospecha")[0]["desbloqueado"],
		true
	)
	comprobar.call(
		"los logros nuevos llegan bloqueados",
		migrada.estado["logros"].filter(func(l): return l["id"] == "primer-mirada")[0]["desbloqueado"],
		false
	)

	# Una partida ilegible se aparta, NO se pisa. Es la diferencia entre perder
	# una partida y poder recuperarla.
	_escribir_texto(RUTA_PRUEBA, "{esto no es json")
	var rota := Partida.new()
	var resultado := rota.cargar(RUTA_PRUEBA)
	comprobar.call("una partida corrupta se aparta", resultado["resultado"], "apartada")
	comprobar.call(
		"y queda una copia del fichero original",
		FileAccess.file_exists(RUTA_PRUEBA + ".roto"),
		true
	)
	comprobar.call("mientras tanto se juega con una nueva", rota.estado["pistas_descubiertas"], [])

	# Una partida de una versión POSTERIOR tampoco se interpreta a medias.
	var futura := Partida.nueva()
	futura["version"] = Partida.VERSION + 1
	futura["pistas_descubiertas"] = ["no debería leerse"]
	_escribir(RUTA_PRUEBA, futura)
	var adelantada := Partida.new()
	comprobar.call(
		"una partida de una versión posterior se aparta",
		adelantada.cargar(RUTA_PRUEBA)["resultado"],
		"apartada"
	)
	comprobar.call("y no se lee nada de ella", adelantada.estado["pistas_descubiertas"], [])

	_borrar_pruebas()


# --- Un guardado que falla no se lleva la partida por delante (#191) ----------


static func _guardado_seguro(comprobar: Callable) -> void:
	_borrar_pruebas()
	_borrar_estorbo()

	# Una partida de verdad, guardada bien: es la que tiene que seguir en el
	# disco pase lo que pase después.
	var partida := Partida.new()
	partida.cargar(RUTA_PRUEBA)
	partida.estado["pistas_descubiertas"] = ["antes"]
	partida.estado["coliseo_racha_mejor"] = 4
	comprobar.call("el guardado bueno sale", partida.guardar(RUTA_PRUEBA), true)
	comprobar.call("y no deja nada pendiente", partida.guardado_pendiente, false)

	# 1. No se puede ni crear el temporal. La jugada siguiente YA está hecha en
	#    memoria y ahí se queda: lo que no se ha movido es el disco.
	partida.estado["pistas_descubiertas"] = ["antes", "despues"]
	comprobar.call(
		"un guardado sin carpeta donde escribir dice que no",
		partida.guardar(RUTA_SIN_CARPETA),
		false
	)
	comprobar.call("y lo deja apuntado como pendiente", partida.guardado_pendiente, true)
	comprobar.call(
		"con un motivo que se puede enseñar", partida.fallo_de_guardado.is_empty(), false
	)
	comprobar.call(
		"el estado vigente NO desaparece",
		partida.estado["pistas_descubiertas"],
		["antes", "despues"]
	)
	comprobar.call(
		"y el guardado anterior sigue entero", _leer(RUTA_PRUEBA)["pistas_descubiertas"], ["antes"]
	)

	# 2. El temporal se escribe pero el renombrado no puede ser: un directorio
	#    con algo dentro ocupa el sitio del fichero bueno.
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RUTA_ESTORBADA))
	_escribir_texto(RUTA_ESTORBADA + "/dentro", "ocupado")
	comprobar.call("un renombrado imposible dice que no", partida.guardar(RUTA_ESTORBADA), false)
	comprobar.call(
		"y tampoco deja el temporal a medias por ahí",
		FileAccess.file_exists(RUTA_ESTORBADA + ".nuevo"),
		false
	)
	comprobar.call(
		"el estado vigente sigue sin tocarse",
		partida.estado["pistas_descubiertas"],
		["antes", "despues"]
	)

	# 3. Reintentar es volver a guardar el MISMO estado, no rehacer la jugada.
	#    Ni una pista, ni un duro, ni una acción de más.
	comprobar.call("el reintento sale", partida.guardar(RUTA_PRUEBA), true)
	comprobar.call("y ya no hay nada pendiente", partida.guardado_pendiente, false)
	comprobar.call("ni motivo que enseñar", partida.fallo_de_guardado, "")
	comprobar.call(
		"reintentar otra vez no duplica nada",
		(
			partida.guardar(RUTA_PRUEBA)
			and partida.estado["coliseo_racha_mejor"] == 4
			and partida.estado["pistas_descubiertas"] == ["antes", "despues"]
		),
		true
	)

	# 4. Y lo que queda en el disco es lo que se ve en pantalla: se recarga
	#    desde el guardado y sale la partida vigente, no la de antes del fallo.
	var releida := Partida.new()
	comprobar.call(
		"la partida se recupera del guardado bueno",
		releida.cargar(RUTA_PRUEBA)["resultado"],
		"cargada"
	)
	comprobar.call(
		"con lo que había en memoria cuando se reintentó",
		[releida.estado["pistas_descubiertas"], releida.estado["coliseo_racha_mejor"]],
		[["antes", "despues"], 4]
	)
	comprobar.call("y con su versión sellada", releida.estado["version"], Partida.VERSION)

	# 5. La versión se sella al escribir, no al intentarlo. Una partida que
	#    nunca llegó a guardarse no puede decir que es de la versión vigente:
	#    mentiría sobre lo que hay en el disco.
	var nunca := Partida.new()
	nunca.estado["version"] = 0
	nunca.guardar(RUTA_SIN_CARPETA)
	comprobar.call("un guardado fallido no sella la versión", nunca.estado["version"], 0)

	_borrar_estorbo()
	_borrar_pruebas()


static func _borrar_estorbo() -> void:
	var carpeta := ProjectSettings.globalize_path(RUTA_ESTORBADA)
	if DirAccess.dir_exists_absolute(carpeta):
		for nombre in DirAccess.get_files_at(RUTA_ESTORBADA):
			DirAccess.remove_absolute(carpeta + "/" + nombre)
		DirAccess.remove_absolute(carpeta)
	if FileAccess.file_exists(RUTA_ESTORBADA + ".nuevo"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA_ESTORBADA + ".nuevo"))


static func _leer(ruta: String) -> Dictionary:
	return JSON.parse_string(FileAccess.open(ruta, FileAccess.READ).get_as_text())


static func _escribir(ruta: String, datos: Dictionary) -> void:
	_escribir_texto(ruta, JSON.stringify(datos))


static func _escribir_texto(ruta: String, texto: String) -> void:
	var fichero := FileAccess.open(ruta, FileAccess.WRITE)
	fichero.store_string(texto)
	fichero.close()


static func _borrar_el_avance(comprobar: Callable) -> void:
	_borrar_pruebas()

	# Una partida con avance PERMANENTE: una carta conocida de una vuelta
	# anterior y una racha, que son justo lo que `reiniciar_vuelta` conserva a
	# propósito y lo que este borrado sí se lleva.
	var partida := Partida.new()
	partida.cargar(RUTA_PRUEBA)
	partida.estado["cartas_conocidas"] = ["la-luna"]
	partida.estado["coliseo_racha_mejor"] = 7
	Prometeo.desbloquear_carta(partida.estado["tarot"], "la-luna")
	comprobar.call("la partida de prueba se guarda", partida.guardar(RUTA_PRUEBA), true)

	comprobar.call("borrar dice que sí", partida.borrar(RUTA_PRUEBA), true)
	comprobar.call("y no queda partida guardada", FileAccess.file_exists(RUTA_PRUEBA), false)
	comprobar.call(
		"la memoria de por vida también se va", partida.estado.get("cartas_conocidas", []), []
	)
	comprobar.call("y la mejor racha vuelve a cero", int(partida.estado["coliseo_racha_mejor"]), 0)

	# La diferencia con reiniciar_vuelta, dicha en una prueba: aquella conserva
	# lo permanente y esta no. Si alguien las confunde, esto lo caza.
	var otra := Partida.new()
	otra.cargar(RUTA_PRUEBA)
	otra.estado["cartas_conocidas"] = ["la-luna"]
	Prometeo.reiniciar_vuelta(otra.estado, Partida.VIDA_MAXIMA)
	comprobar.call(
		"reiniciar una vuelta NO borra lo conocido", otra.estado["cartas_conocidas"], ["la-luna"]
	)

	# Volver a cargar después de borrar es empezar de cero, no una partida rota.
	comprobar.call(
		"tras borrar se empieza de nuevo", partida.cargar(RUTA_PRUEBA)["resultado"], "nueva"
	)

	# Borrar cuando no hay nada que borrar ya está hecho: el botón no puede
	# fallar por pulsarlo dos veces.
	comprobar.call("borrar sin partida no es un fallo", partida.borrar(RUTA_PRUEBA), true)

	# Y la anterior sigue en el disco: un borrado por error es recuperable.
	comprobar.call(
		"la partida borrada queda apartada", FileAccess.file_exists(RUTA_PRUEBA + ".roto"), true
	)

	_borrar_pruebas()


static func _borrar_pruebas() -> void:
	for sufijo in ["", ".roto", ".nuevo"]:
		var ruta: String = RUTA_PRUEBA + sufijo
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))


# --- Las historias políticas -------------------------------------------------


static func _historias(comprobar: Callable) -> void:
	var historias := Historias.new()
	comprobar.call("el catálogo de historias carga", historias.cargar(), true)
	comprobar.call("son ocho", historias.catalogo.size(), 8)

	# Una historia por carta oculta, ni más ni menos: una carta sin historia
	# sería un hallazgo que no lleva a ninguna parte, y una historia sin carta
	# un relato inalcanzable.
	var ids_historias := historias.catalogo.keys()
	ids_historias.sort()
	var ids_cartas := CartasOcultas.POR_FOLIO.values().map(func(c): return c["carta"])
	ids_cartas.sort()
	comprobar.call("cada carta oculta tiene su historia y al revés", ids_historias, ids_cartas)

	var estado := {"historias_cartas": {}}

	# Sin resolver se ofrecen las cuatro salidas.
	var pendiente := historias.vista(estado, "la-luna")
	comprobar.call(
		"una historia sin resolver ofrece sus opciones", pendiente["estado"], "pendiente"
	)
	comprobar.call(
		"y son cuatro, una por eje",
		pendiente["opciones"].map(func(o): return o["eje"]),
		["comunismo", "centrista", "socialdemocrata", "neoliberal"]
	)

	# La Luna es útil para centrista y neoliberal (Prometeo.UTILIDAD_CARTAS).
	var util := historias.resolver(estado, "la-luna", "centrista")
	comprobar.call("la elección útil se clasifica como pista", util["clasificacion"], "pista")
	comprobar.call(
		"y su secuela apunta a documentos reales",
		util["secuela"] == historias.de("la-luna")["secuelaUtil"],
		true
	)

	# Una historia resuelta ya no se vuelve a preguntar, y NO se puede cambiar
	# el voto: en el original la asignación era incondicional y solo la interfaz
	# lo impedía.
	comprobar.call(
		"una historia resuelta no vuelve a ofrecer opciones",
		historias.vista(estado, "la-luna")["estado"],
		"resuelta"
	)
	historias.resolver(estado, "la-luna", "comunismo")
	comprobar.call(
		"y el voto no se puede cambiar", estado["historias_cartas"]["la-luna"], "centrista"
	)

	# Una elección que no era la útil da la secuela que despista.
	var confusa := historias.resolver(estado, "la-justicia", "centrista")
	comprobar.call(
		"la elección inútil se clasifica como confusión", confusa["clasificacion"], "confusion"
	)
	comprobar.call(
		"y su secuela es la que despista",
		confusa["secuela"] == historias.de("la-justicia")["secuelaConfusion"],
		true
	)

	# Las cargas: tope de dos, así que casarse con una ideología no da ocho usos.
	comprobar.call(
		"dos elecciones del mismo eje dan dos cargas", historias.cargas(estado)["centrista"], 2
	)
	historias.resolver(estado, "el-carro", "centrista")
	comprobar.call(
		"la tercera ya no suma: el tope es dos", historias.cargas(estado)["centrista"], 2
	)
	comprobar.call("un eje sin elegir no tiene cargas", historias.cargas(estado)["neoliberal"], 0)

	comprobar.call("quedan cinco historias por decidir", historias.pendientes(estado), 5)

	# Cada eje tiene su habilidad declarada, o una carga sería inservible.
	comprobar.call(
		"los cuatro ejes tienen habilidad",
		Prometeo.EJES.all(func(e): return Historias.HABILIDADES.has(e)),
		true
	)

	# Una carta que no existe no revienta ni inventa una historia.
	comprobar.call("una carta sin historia devuelve vacío", historias.vista(estado, "el-loco"), {})


# --- El motor de combate -----------------------------------------------------


static func _combate(comprobar: Callable) -> void:
	# La cadena circular tiene que cerrarse: si un tipo no venciera a nadie o
	# venciera a dos, habría una jugada dominante y el juego se acabaría.
	var vencidos := Combate.TIPOS.map(func(t): return Combate.vence_a(t))
	vencidos.sort()
	var todos := Combate.TIPOS.duplicate()
	todos.sort()
	comprobar.call("cada tipo lo vence exactamente otro", vencidos, todos)
	comprobar.call("objeción vence al silencio", Combate.vence_a("silencio"), "objecion")

	var rival := {"nombre": "La Ventanilla", "ataques": ["Vuelva usted mañana."]}
	var sin_azar := func(): return 0.0

	# En modo ciclo el rival es la ronda módulo tres: determinista y aprendible.
	var duelo := Combate.nuevo("ciclo", rival)
	var r1 := Combate.jugar(duelo, "objecion", "", sin_azar)
	comprobar.call("ronda 0 en ciclo: el rival abre con el primero", r1["tipo_rival"], "objecion")
	comprobar.call("mismo tipo es empate", r1["veredicto"], "empate")
	comprobar.call(
		"y un empate no cuesta vidas", [duelo["vida_jugador"], duelo["vida_rival"]], [3, 3]
	)

	var r2 := Combate.jugar(duelo, "objecion", "", sin_azar)
	comprobar.call("ronda 1: el rival pasa al siguiente", r2["tipo_rival"], "silencio")
	comprobar.call("objeción vence a silencio", r2["veredicto"], "gana_jugador")
	comprobar.call("y el rival pierde una vida", duelo["vida_rival"], 2)

	# Tres victorias acaban el combate. En ciclo el rival juega TIPOS[ronda % 3],
	# así que para ganar hay que jugar el que le vence.
	Combate.jugar(duelo, "silencio", "", sin_azar)  # ronda 2: rival insistencia
	var final := Combate.jugar(duelo, "insistencia", "", sin_azar)  # ronda 3: objecion
	comprobar.call("el combate termina al agotar al rival", final["terminado"], true)
	comprobar.call("y lo gana el jugador", final["ganador"], "jugador")
	comprobar.call("una ronda más no hace nada", Combate.jugar(duelo, "objecion", "", sin_azar), {})

	# --- Las cuatro habilidades ---
	var cargas := {"comunismo": 1, "centrista": 1, "socialdemocrata": 1, "neoliberal": 1}

	# Asamblea: el empate también golpea al rival. Es lo único que hace que un
	# empate sirva de algo.
	var asamblea := Combate.nuevo("ciclo", rival, cargas)
	var ra := Combate.jugar(asamblea, "objecion", "comunismo", sin_azar)
	comprobar.call(
		"Asamblea: el empate golpea al rival",
		[ra["veredicto"], asamblea["vida_rival"]],
		["empate", 2]
	)
	comprobar.call("y gasta su carga", asamblea["cargas"]["comunismo"], 0)
	comprobar.call(
		"gastar una carga que no se tiene no hace nada",
		Combate.jugar(asamblea, "objecion", "comunismo", sin_azar)["habilidad"],
		""
	)

	# Mesa de diálogo: nadie pierde vida, ni siquiera perdiendo la ronda.
	var mesa := Combate.nuevo("ciclo", rival, cargas)
	Combate.jugar(mesa, "objecion", "", sin_azar)  # ronda 0, empate
	var rm := Combate.jugar(mesa, "insistencia", "centrista", sin_azar)
	comprobar.call("Mesa de diálogo: la ronda se pierde igual", rm["veredicto"], "gana_rival")
	comprobar.call("pero no cuesta vidas", [mesa["vida_jugador"], mesa["vida_rival"]], [3, 3])

	# Externalizar: el daño cuenta doble, y también en contra.
	var externa := Combate.nuevo("ciclo", rival, cargas)
	Combate.jugar(externa, "objecion", "", sin_azar)
	var re := Combate.jugar(externa, "objecion", "neoliberal", sin_azar)
	comprobar.call(
		"Externalizar: ganar quita dos vidas",
		[re["veredicto"], externa["vida_rival"]],
		["gana_jugador", 1]
	)
	var contra := Combate.nuevo("ciclo", rival, cargas)
	Combate.jugar(contra, "objecion", "", sin_azar)
	Combate.jugar(contra, "insistencia", "neoliberal", sin_azar)
	comprobar.call("y perder también cuesta dos", contra["vida_jugador"], 1)

	# Comisión de seguimiento: revela la réplica que viene, y esa réplica es la
	# que sale de verdad. Si el motor volviera a tirar, la habilidad mentiría.
	var comision := Combate.nuevo("reactiva", rival, cargas)
	var rc := Combate.jugar(comision, "objecion", "socialdemocrata", sin_azar)
	comprobar.call("Comisión de seguimiento anuncia una réplica", rc["revelada"].is_empty(), false)
	var anunciada: String = rc["revelada"]
	var siguiente := Combate.jugar(comision, "objecion", "", sin_azar)
	comprobar.call(
		"y la ronda siguiente juega justo esa", Combate.etiqueta(siguiente["tipo_rival"]), anunciada
	)

	# El rival reactivo contesta a la última jugada: se puede cebar.
	var ventanilla := Combate.nuevo("reactiva", rival, {})
	# Cada ronda gasta tiradas: las del rival (una o dos) y una más para elegir
	# su réplica de ambiente.
	Combate.jugar(ventanilla, "objecion", "", _tiradas([0.9, 0.5, 0.0]))
	var cebo := Combate.jugar(ventanilla, "silencio", "", _tiradas([0.1, 0.0]))
	comprobar.call(
		"el rival reactivo contraataca la última jugada",
		cebo["tipo_rival"],
		Combate.vence_a("objecion")
	)

	# La réplica es ambiente y nada más: un rival sin ataques calla en vez de
	# soltar una frase genérica.
	comprobar.call("un rival con réplicas dice una", cebo["replica"], "Vuelva usted mañana.")
	var mudo := Combate.nuevo("ciclo", {"nombre": "Nadie"}, {})
	comprobar.call(
		"uno sin réplicas no dice nada",
		Combate.jugar(mudo, "objecion", "", sin_azar)["replica"],
		""
	)

	# Las cargas a cero no se ofrecen: una habilidad sin carga no es una opción.
	comprobar.call(
		"solo se ofrecen las cargas que quedan",
		Combate.cargas_disponibles({"cargas": {"comunismo": 0, "centrista": 2}}),
		{"centrista": 2}
	)


# --- La Ventanilla -----------------------------------------------------------


static func _ventanilla(comprobar: Callable) -> void:
	var contenido := Contenido.new()
	contenido.cargar()

	# Sin haber investigado nada, la Ventanilla NO está vacía: atiende el de
	# oficio. Una lista vacía sería indistinguible de una pantalla rota.
	var recien_llegado := Ventanilla.disponibles(contenido, [])
	comprobar.call("una partida nueva tiene un reclamante", recien_llegado.size(), 1)
	comprobar.call("y es el de oficio", recien_llegado[0]["de_oficio"], true)
	comprobar.call("que tiene réplicas propias", recien_llegado[0]["ataques"].is_empty(), false)

	# Al descubrir pistas se van presentando los conceptos que las citan.
	var todas := []
	for c in contenido.casos:
		for p in c["pistas"]:
			todas.append(p["id"])
	var con_todo := Ventanilla.disponibles(contenido, todas)
	comprobar.call(
		"investigándolo todo se presentan los ocho conocidos y el de oficio", con_todo.size(), 9
	)
	comprobar.call(
		"y ninguno es una empresa, un lugar ni un documento",
		con_todo.all(func(r): return r["tipo"] in ["PERSONA", "COMITE"]),
		true
	)

	# La racha: la marca solo sube, y los hitos son los tres logros de #43.
	var estado := {"coliseo_racha_mejor": 0}
	var dos := Ventanilla.cerrar(estado, 2, true)
	comprobar.call("ganar sube la racha y la marca", [dos["racha"], dos["mejor"]], [3, 3])
	comprobar.call("y a las tres seguidas se gana su logro", dos["logros"], ["ventanilla-tres"])
	var perdida := Ventanilla.cerrar(estado, 3, false)
	comprobar.call("perder devuelve la racha a cero", perdida["racha"], 0)
	comprobar.call("pero la mejor marca no baja nunca", estado["coliseo_racha_mejor"], 3)
	comprobar.call("sin racha no hay logros", perdida["logros"], [])
	comprobar.call(
		"a las diez se ganan los tres hitos",
		Ventanilla.cerrar(estado, 9, true)["logros"],
		["ventanilla-tres", "funcionario-del-mes", "ventanilla-inagotable"]
	)


# --- La jornada --------------------------------------------------------------


static func _jornada(comprobar: Callable) -> void:
	var dia := Jornada.nueva()
	comprobar.call("se empieza el día uno en el archivo", [dia["dia"], dia["fase"]], [1, "archivo"])

	# El orden del día es circular y vive en un solo sitio.
	comprobar.call(
		"el día va archivo -> trayecto -> casa -> sueño -> archivo",
		[
			Jornada.siguiente_fase("archivo"),
			Jornada.siguiente_fase("trayecto"),
			Jornada.siguiente_fase("casa"),
			Jornada.siguiente_fase("sueño")
		],
		["trayecto", "casa", "sueño", "archivo"]
	)

	# La nómina: se cobra por CERRAR, no por acertar. Un expediente mal cerrado
	# paga lo mismo, que es toda la sátira.
	dia["cerrados_hoy"] = 2
	var nomina := Jornada.fichar_salida(dia)
	comprobar.call(
		"la nómina se desglosa",
		[nomina["base"], nomina["expedientes"], nomina["por_expedientes"]],
		[Jornada.BASE_DIARIA, 2, Jornada.POR_EXPEDIENTE * 2]
	)
	comprobar.call(
		"y se cobra entera", dia["dinero"], 120 + Jornada.BASE_DIARIA + Jornada.POR_EXPEDIENTE * 2
	)
	comprobar.call("fichar lleva al trayecto", dia["fase"], "trayecto")
	comprobar.call("no se puede fichar dos veces", Jornada.fichar_salida(dia), {})

	# Un día sin cerrar nada también paga: el sueldo base no depende de ti.
	var flojo := Jornada.nueva()
	comprobar.call(
		"un día sin cerrar nada paga la base",
		Jornada.fichar_salida(flojo)["bruto"],
		Jornada.BASE_DIARIA
	)

	# Gastar: sin dinero no hay compra, y no hay crédito.
	comprobar.call(
		"no se puede gastar más de lo que hay", Jornada.gastar(dia, dia["dinero"] + 1), false
	)
	var antes: int = dia["dinero"]
	comprobar.call("una compra que cabe se hace", Jornada.gastar(dia, 10), true)
	comprobar.call("y descuenta", dia["dinero"], antes - 10)
	comprobar.call("gastar cero o menos no es una compra", Jornada.gastar(dia, 0), false)

	# --- El gato ---
	# No se muere: si lo desatiendes, un día no está.
	var casa := Jornada.nueva()
	casa["fase"] = "casa"
	for i in Jornada.PACIENCIA_GATO:
		var noche := Jornada.dormir(casa)
		comprobar.call("el gato aguanta la noche %d" % (i + 1), noche["gato_se_fue"], false)
		casa["fase"] = "sueño"
		Jornada.despertar(casa)
		casa["fase"] = "casa"
	var ultima := Jornada.dormir(casa)
	comprobar.call("pasada su paciencia, el gato se va", ultima["gato_se_fue"], true)
	comprobar.call("y ya no está", casa["gato"]["presente"], false)
	comprobar.call(
		"no vuelve a irse: ya se fue", Jornada.dormir(casa).get("gato_se_fue", false), false
	)

	# Darle de comer reinicia la cuenta, y es una compra: puede no poder hacerse.
	var cuidada := Jornada.nueva()
	cuidada["fase"] = "casa"
	Jornada.dormir(cuidada)
	comprobar.call(
		"darle de comer reinicia la cuenta",
		Jornada.alimentar_gato(cuidada, 10) and cuidada["gato"]["dias_sin_comer"] == 0,
		true
	)
	cuidada["dinero"] = 0
	comprobar.call(
		"sin dinero no se le puede dar de comer", Jornada.alimentar_gato(cuidada, 10), false
	)
	comprobar.call("y a un gato que ya se fue tampoco", Jornada.alimentar_gato(casa, 0), false)

	# Vivir cuesta, y no se baja de cero: no hay deuda.
	var pobre := Jornada.nueva()
	pobre["fase"] = "casa"
	pobre["dinero"] = 5
	comprobar.call("el coste de vivir no deja saldo negativo", Jornada.dormir(pobre)["dinero"], 0)

	# --- El día siguiente ---
	var ciclo := Jornada.nueva()
	Jornada.anotar_lectura(ciclo, "MEMO-1999-088")
	Jornada.anotar_lectura(ciclo, "MEMO-1999-088")
	comprobar.call("lo leído hoy no se repite", ciclo["leido_hoy"].size(), 1)
	Jornada.anotar_lectura(ciclo, "")
	comprobar.call("un folio vacío no se anota", ciclo["leido_hoy"].size(), 1)

	ciclo["cerrados_hoy"] = 3
	ciclo["fase"] = "sueño"
	comprobar.call("despertar pasa al día dos", Jornada.despertar(ciclo), 2)
	comprobar.call(
		"y devuelve al archivo con todo a cero",
		[ciclo["fase"], ciclo["cerrados_hoy"], ciclo["leido_hoy"]],
		["archivo", 0, []]
	)
	comprobar.call("no se despierta dos veces", Jornada.despertar(ciclo), 2)


# --- Procedencia de los assets ------------------------------------------------


static func _procedencia(comprobar: Callable) -> void:
	var fichero := FileAccess.open(RUTA_ASSETS + "/procedencia.json", FileAccess.READ)
	comprobar.call("hay registro de procedencia", fichero != null, true)
	if fichero == null:
		return
	var registro = JSON.parse_string(fichero.get_as_text())
	fichero.close()
	comprobar.call("y es un objeto", typeof(registro), TYPE_DICTIONARY)

	var fichas: Array = registro.get("assets", [])
	var por_ruta := {}
	var fichas_incompletas := []
	for ficha in fichas:
		for campo in ["ruta", "titulo", "autor", "licencia", "fuente", "sha256"]:
			if String(ficha.get(campo, "")).strip_edges().is_empty():
				fichas_incompletas.append("%s sin %s" % [ficha.get("ruta", "?"), campo])
		por_ruta[ficha.get("ruta", "")] = ficha
	comprobar.call("ninguna ficha está a medias", fichas_incompletas, [])

	# En las dos direcciones: ni ficheros sin ficha ni fichas sin fichero.
	var sin_ficha := []
	var mal_resumidos := []
	for ruta in _ficheros_bajo(RUTA_ASSETS):
		if ruta in ["procedencia.json", "LEEME.md"]:
			continue
		if not por_ruta.has(ruta):
			sin_ficha.append(ruta)
			continue
		var real := FileAccess.get_sha256(RUTA_ASSETS + "/" + ruta)
		if real != por_ruta[ruta]["sha256"]:
			mal_resumidos.append(ruta)
	comprobar.call("ningún asset sin ficha", sin_ficha, [])
	comprobar.call("el sha256 de cada ficha es el del fichero real", mal_resumidos, [])

	var huerfanas := []
	for ruta in por_ruta:
		if not FileAccess.file_exists(RUTA_ASSETS + "/" + ruta):
			huerfanas.append(ruta)
	comprobar.call("ninguna ficha apunta a un fichero que no existe", huerfanas, [])


## Todo lo que cuelga de un directorio, con la ruta relativa a él. Se ignoran
## los `.import` que Godot genera: son suyos, no material de terceros.
static func _ficheros_bajo(raiz: String, prefijo: String = "") -> Array:
	var encontrados := []
	var actual := raiz + ("/" + prefijo if not prefijo.is_empty() else "")
	for nombre in DirAccess.get_files_at(actual):
		if nombre.ends_with(".import") or nombre.ends_with(".uid"):
			continue
		encontrados.append(prefijo + nombre if prefijo.is_empty() else prefijo + "/" + nombre)
	for dir in DirAccess.get_directories_at(actual):
		encontrados.append_array(
			_ficheros_bajo(raiz, dir if prefijo.is_empty() else prefijo + "/" + dir)
		)
	return encontrados
