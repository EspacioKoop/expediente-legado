## Las cinemáticas y el mando.
##
## Salen de `pruebas_espacios_y_sueno.gd` porque aquel pasó del tope de mil
## líneas que fija gdlint, y porque estas dos no son de espacios ni de sueño:
## son de cómo se PRESENTA el juego y de cómo se le habla. El reparto de las
## pruebas sigue al de los módulos, no al orden en que se escribieron.
class_name PruebasCinematicasYMando
extends RefCounted


static func _cinematicas(comprobar: Callable) -> void:
	var planos := [
		{
			"tipo": "3d",
			"camara": Vector3(0, 1, 3),
			"mira": Vector3.ZERO,
			"segundos": 2.0,
			"rotulo": "{quien}"
		},
		{
			"tipo": "2d",
			"figura": [{"rect": Rect2(0, 0, 10, 10)}],
			"segundos": 1.0,
			"voz": "dice {quien}"
		},
	]

	# Las plantillas se rellenan al reproducir, no al declarar.
	var rodaje := Cinematica.resolver(planos, {"quien": "El Comité"})
	comprobar.call("el rótulo se rellena", rodaje[0]["rotulo"], "El Comité")
	comprobar.call("y la voz también", rodaje[1]["voz"], "dice El Comité")
	comprobar.call(
		"un dato que no se cita no estorba",
		Cinematica.resolver(planos, {"otro": "x"})[0]["rotulo"],
		"{quien}"
	)

	# Se entregan copias: reproducir una no puede estropear la siguiente.
	rodaje[0]["rotulo"] = "ESTROPEADO"
	comprobar.call(
		"los planos se entregan en copia",
		Cinematica.resolver(planos, {"quien": "El Comité"})[0]["rotulo"],
		"El Comité"
	)

	# --- El acortado por repetición ---
	comprobar.call(
		"la primera vez dura lo declarado",
		Cinematica.duracion(Cinematica.resolver(planos, {}, 0)),
		3.0
	)
	var segunda := Cinematica.duracion(Cinematica.resolver(planos, {}, 1))
	comprobar.call("la segunda dura menos", segunda < 3.0, true)
	comprobar.call(
		"y la quinta menos que la segunda",
		Cinematica.duracion(Cinematica.resolver(planos, {}, 4)) < segunda,
		true
	)

	# El suelo: por muy vista que esté, no desaparece sin avisar. Y el REMATE
	# tiene su propio suelo, más alto que el de los demás planos.
	var muy_vista := Cinematica.resolver(planos, {}, 99)
	comprobar.call("ningún plano baja de cero", Cinematica.duracion(muy_vista) > 0.0, true)
	comprobar.call(
		"el remate conserva más que los demás",
		Cinematica.factor(99, true) > Cinematica.factor(99, false),
		true
	)
	comprobar.call(
		"el remate no baja de su suelo", Cinematica.factor(99, true), Cinematica.SUELO_REMATE
	)
	comprobar.call("las vistas negativas no alargan nada", Cinematica.factor(-5, false), 1.0)

	# --- La validación, al construir y no a mitad ---
	comprobar.call("unos planos bien declarados no dan problemas", Cinematica.validar(planos), [])
	comprobar.call(
		"una cinemática sin planos es un problema", Cinematica.validar([]), ["sin planos"]
	)
	comprobar.call(
		"un plano sin tipo se caza", Cinematica.validar([{"segundos": 1.0}]).size() > 0, true
	)
	comprobar.call(
		"un plano sin duración se caza: se quedaría clavado en pantalla",
		(
			"plano 0: sin duración"
			in Cinematica.validar([{"tipo": "3d", "camara": Vector3.ZERO, "mira": Vector3.ZERO}])
		),
		true
	)
	comprobar.call(
		"un 3d sin cámara se caza",
		(
			"plano 0: 3d sin camara"
			in Cinematica.validar([{"tipo": "3d", "mira": Vector3.ZERO, "segundos": 1.0}])
		),
		true
	)
	comprobar.call(
		"un 2d sin figura se caza",
		"plano 0: 2d sin figura" in Cinematica.validar([{"tipo": "2d", "segundos": 1.0}]),
		true
	)

	# La del careo tiene que pasar su propia validación: es la primera que se
	# declara en este formato y la que sirve de ejemplo a las otras nueve.
	comprobar.call(
		"la cinemática del careo está bien declarada",
		Cinematica.validar(CareoCinematica.PLANOS),
		[]
	)

	# --- Encontrar una carta de tarot (#71) ---

	# La del tarot se valida ya RESUELTA: el decorado de la mesa se añade a
	# cada plano al resolver.
	var carta := {"id": "la-luna", "nombre": "La Luna"}
	var tarot := TarotCinematica.planos_de(carta)
	comprobar.call("la cinemática del tarot está bien declarada", Cinematica.validar(tarot), [])
	comprobar.call("tiene los cuatro planos", tarot.size(), 4)
	comprobar.call("todos son 3d", tarot.all(func(p): return p["tipo"] == "3d"), true)
	comprobar.call(
		"todos ruedan sobre la misma mesa",
		tarot.all(func(p): return p["decorado"] == tarot[0]["decorado"]),
		true
	)

	# El volteo es la cámara rodeando una carta con dos caras: el dorso se ve
	# desde -z, el canto de lado y el frontal desde +z.
	var centro := TarotCinematica.CENTRO
	comprobar.call("el reverso mira el dorso", tarot[0]["camara"].z < centro.z, true)
	comprobar.call("el canto se mira de lado", absf(tarot[1]["camara"].z - centro.z) < 0.01, true)
	comprobar.call("el frontal mira el frente", tarot[2]["camara"].z > centro.z, true)

	# El rótulo lleva el nombre de la carta, que es lo único que cambia entre
	# las ocho: el rodaje es el mismo.
	comprobar.call("el rótulo nombra la carta", tarot[2]["rotulo"], "La Luna")
	comprobar.call(
		"una carta sin nombre no deja el hueco a la vista",
		"{carta}" in TarotCinematica.planos_de({})[2]["rotulo"],
		false
	)

	# Se acorta como las demás: la octava carta no puede durar lo que la
	# primera.
	comprobar.call(
		"la octava vez dura menos que la primera",
		Cinematica.duracion(TarotCinematica.planos_de(carta, 7)) < Cinematica.duracion(tarot),
		true
	)

	# Y no se estropea entre reproducciones: el decorado es un valor anidado,
	# que es justo lo que una copia superficial compartiría.
	tarot[0]["decorado"]["bultos"].clear()
	comprobar.call(
		"el decorado se entrega en copia profunda",
		TarotCinematica.planos_de(carta)[0]["decorado"]["bultos"].is_empty(),
		false
	)

	# --- El sello (#70) en 3D sobre la mesa del archivo ---
	var sello := SelloCinematica.planos_de(false)
	var sello_prisa := SelloCinematica.planos_de(true)
	comprobar.call("el sello está bien declarado", Cinematica.validar(sello), [])
	comprobar.call(
		"el sello tiene tres planos 3d", sello.filter(func(p): return p["tipo"] == "3d").size(), 3
	)
	comprobar.call(
		"la prisa deja una huella de más",
		sello_prisa[1]["decorado"]["bultos"].size() > sello[1]["decorado"]["bultos"].size(),
		true
	)
	comprobar.call(
		"un decorado que no es un espacio no valida",
		(
			Cinematica
			. validar(
				[
					{
						"tipo": "3d",
						"segundos": 1.0,
						"camara": Vector3.ONE,
						"mira": Vector3.ZERO,
						"decorado": 3
					}
				]
			)
			. size()
		),
		1
	)

	# --- La entrada de una vida laboral (#68) ---

	comprobar.call(
		"la entrada está bien declarada", Cinematica.validar(EntradaCinematica.planos()), []
	)

	var entrada := EntradaCinematica.planos_de()
	comprobar.call("la entrada tiene sus cuatro planos", entrada.size(), 4)
	comprobar.call("y dura algo", Cinematica.duracion(entrada) > 0.0, true)

	# Las tres cosas que #68 le pide que deje puestas: que es una copia
	# restaurada, quién la abre y que no mira nadie.
	comprobar.call(
		"dice que es una copia restaurada",
		entrada[0]["rotulo"],
		TranslationServer.translate("ENTRADA_RESTAURANDO")
	)
	comprobar.call(
		"nombra al auditor que la abre",
		entrada[2]["rotulo"].contains(EntradaCinematica.USUARIO),
		true
	)
	comprobar.call(
		"y remata diciendo que no mira nadie",
		entrada[3]["rotulo"],
		TranslationServer.translate("ENTRADA_NADIE_MIRA")
	)

	# La variación de cada vuelta: la copia se degrada. Es lo que hace que
	# repetirla sea el reloj del juego y no una repetición.
	comprobar.call(
		"la primera vuelta trae una copia íntegra",
		EntradaCinematica.registro_de(0),
		"ENTRADA_COPIA_INTEGRA"
	)
	comprobar.call(
		"la segunda ya no",
		EntradaCinematica.registro_de(1) != EntradaCinematica.registro_de(0),
		true
	)
	# La serie se agota en su última línea en vez de dar la vuelta: volver a
	# "copia íntegra" en la quinta vida laboral desharía lo que esto afirma.
	comprobar.call(
		"y no vuelve nunca al principio",
		EntradaCinematica.registro_de(99),
		EntradaCinematica.REGISTRO_POR_VUELTA[-1]
	)

	# Por muy vista que esté conserva su remate: una entrada que desapareciera
	# dejaría al jugador dentro de una oficina sin haber entrado en ella.
	var gastada := EntradaCinematica.planos_de(99)
	comprobar.call("muy vista sigue durando algo", Cinematica.duracion(gastada) > 0.0, true)
	comprobar.call(
		"y el remate sigue siendo el más largo de sus planos",
		gastada[3]["segundos"] >= gastada[0]["segundos"],
		true
	)
	comprobar.call(
		"muy vista sigue diciendo que no mira nadie",
		gastada[3]["rotulo"],
		TranslationServer.translate("ENTRADA_NADIE_MIRA")
	)

	# Rodarla no puede estropear la siguiente.
	entrada[0]["rotulo"] = "ESTROPEADO"
	comprobar.call(
		"la entrada se entrega en copia",
		EntradaCinematica.planos_de()[0]["rotulo"],
		TranslationServer.translate("ENTRADA_RESTAURANDO")
	)

	# --- La entrada casa -> sueño (#74) ---
	var entrada_sueno := EntradaSuenoCinematica.planos_de(["F-1996-00187"])
	comprobar.call("la entrada al sueño está bien declarada", Cinematica.validar(entrada_sueno), [])
	comprobar.call("la entrada al sueño tiene tres planos", entrada_sueno.size(), 3)
	comprobar.call(
		"la entrada al sueño rueda en 3D",
		entrada_sueno.all(func(p): return p["tipo"] == "3d"),
		true
	)
	comprobar.call(
		"la entrada solo muestra un folio leído", entrada_sueno[1]["rotulo"], "F-1996-00187"
	)
	comprobar.call(
		"sin lecturas no inventa un folio", EntradaSuenoCinematica.planos_de([])[1]["rotulo"], ""
	)
	comprobar.call(
		"la entrada repetida se acorta",
		(
			Cinematica.duracion(EntradaSuenoCinematica.planos_de(["F-1996-00187"], 4))
			< Cinematica.duracion(entrada_sueno)
		),
		true
	)

	# --- La cuenta de vistas, que es estado de partida ---
	var estado := {}
	comprobar.call(
		"una cinemática nunca vista está a cero", Cinematica.vistas_de(estado, "careo"), 0
	)
	Cinematica.anotar_vista(estado, "careo")
	Cinematica.anotar_vista(estado, "careo")
	comprobar.call("se lleva la cuenta", Cinematica.vistas_de(estado, "careo"), 2)
	comprobar.call("y cada una la suya", Cinematica.vistas_de(estado, "sello"), 0)

	# El reproductor anota la vista por su cuenta si se le da id y estado. Es lo
	# que evita que un llamante despistado deje su cinemática eterna mientras
	# las demás se acortan.
	var partida := Partida.nueva()
	comprobar.call(
		"la partida guarda la cuenta de cinemáticas vistas",
		Cinematica.vistas_de(partida, "careo"),
		0
	)
	Cinematica.anotar_vista(partida, "careo")
	var acortada := CareoCinematica.planos_de(
		{"nombre": "X"}, "F-1", Cinematica.vistas_de(partida, "careo")
	)
	comprobar.call(
		"y la segunda vez el careo dura menos",
		(
			Cinematica.duracion(acortada)
			< Cinematica.duracion(CareoCinematica.planos_de({"nombre": "X"}, "F-1", 0))
		),
		true
	)


# --- Plantas que no son una caja (#86) ---------------------------------------


## Mirar con el stick derecho: que las acciones EXISTAN y estén en el eje que
## toca. Una acción mal escrita en `project.godot` no rompe nada al arrancar —
## `Input.get_vector` devuelve cero—, así que el mando simplemente no movería la
## cámara y no habría forma de distinguirlo de un mando desconectado.
static func _mando(comprobar: Callable) -> void:
	for accion in ["mirar_izquierda", "mirar_derecha", "mirar_arriba", "mirar_abajo"]:
		comprobar.call("existe la acción %s" % accion, InputMap.has_action(accion), true)

	var eje_de := func(accion: String) -> int:
		for evento in InputMap.action_get_events(accion):
			if evento is InputEventJoypadMotion:
				return evento.axis
		return -1

	# Eje 2 y 3 son el stick DERECHO. El izquierdo (0 y 1) mueve, y mirar con
	# él sería mirar mientras se camina.
	comprobar.call("mirar a los lados va en el eje derecho X", eje_de.call("mirar_izquierda"), 2)
	comprobar.call("y a la derecha también", eje_de.call("mirar_derecha"), 2)
	comprobar.call("mirar arriba va en el eje derecho Y", eje_de.call("mirar_arriba"), 3)
	comprobar.call("y abajo también", eje_de.call("mirar_abajo"), 3)

	# Sin zona muerta, un mando gastado gira la cámara solo.
	for accion in ["mirar_izquierda", "mirar_derecha", "mirar_arriba", "mirar_abajo"]:
		comprobar.call(
			"%s tiene zona muerta" % accion, InputMap.action_get_deadzone(accion) > 0.0, true
		)

	_mando_movimiento(comprobar)


## #98: el stick izquierdo no movía y la cruceta estaba desplazada una posición
## (adelante caía en abajo). Se comprueba el mapa que queda tras aplicar las
## preferencias, que es lo que lee `Input.get_vector` del caminante.
static func _mando_movimiento(comprobar: Callable) -> void:
	PreferenciasSiga.aplicar(PreferenciasSiga.nuevas())
	var eventos_de := func(accion: String, clase: String) -> Array:
		return InputMap.action_get_events(accion).filter(func(e): return e.is_class(clase))
	var esperados := {
		"mover_adelante": [JOY_AXIS_LEFT_Y, -1.0, JOY_BUTTON_DPAD_UP],
		"mover_atras": [JOY_AXIS_LEFT_Y, 1.0, JOY_BUTTON_DPAD_DOWN],
		"mover_izquierda": [JOY_AXIS_LEFT_X, -1.0, JOY_BUTTON_DPAD_LEFT],
		"mover_derecha": [JOY_AXIS_LEFT_X, 1.0, JOY_BUTTON_DPAD_RIGHT],
	}
	for accion in esperados:
		var ejes: Array = eventos_de.call(accion, "InputEventJoypadMotion")
		comprobar.call("%s responde al stick izquierdo" % accion, ejes.size(), 1)
		if ejes.size() == 1:
			comprobar.call(
				"%s va en su eje y sentido" % accion,
				[ejes[0].axis, ejes[0].axis_value],
				[esperados[accion][0], esperados[accion][1]]
			)
		var botones: Array = eventos_de.call(accion, "InputEventJoypadButton")
		comprobar.call(
			"%s va en su cruceta" % accion,
			botones.map(func(b): return b.button_index),
			[esperados[accion][2]]
		)
		comprobar.call(
			"%s no exige medio stick" % accion, InputMap.action_get_deadzone(accion) <= 0.25, true
		)

	var accion_de_boton := func(boton: int) -> String:
		for accion in PreferenciasSiga.ACCIONES:
			if int(PreferenciasSiga.ACCIONES[accion]["mando"]) == boton:
				return accion
		return ""
	comprobar.call("A interactúa", accion_de_boton.call(JOY_BUTTON_A), "interactuar")
	comprobar.call("B cancela", accion_de_boton.call(JOY_BUTTON_B), "cancelar")
	comprobar.call("X salta", accion_de_boton.call(JOY_BUTTON_X), "saltar")
	var sin_repetir := {}
	for descripcion in PreferenciasSiga.ACCIONES.values():
		sin_repetir[int(descripcion["mando"])] = true
	comprobar.call(
		"ningún botón hace dos cosas", sin_repetir.size(), PreferenciasSiga.ACCIONES.size()
	)

	# Unas preferencias v1 guardadas conservan las teclas y reponen los botones.
	var ruta := "user://preferencias-v1-prueba.json"
	var v1 := PreferenciasSiga.nuevas()
	v1["version"] = 1
	v1["acciones"]["mover_adelante"] = {"teclado": KEY_UP, "mando": 12}
	var fichero := FileAccess.open(ruta, FileAccess.WRITE)
	fichero.store_string(JSON.stringify(v1))
	fichero.close()
	var migradas := PreferenciasSiga.cargar(ruta)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
	comprobar.call(
		"la v1 conserva la tecla remapeada",
		int(migradas["acciones"]["mover_adelante"]["teclado"]),
		KEY_UP
	)
	comprobar.call(
		"y repone el botón desplazado",
		int(migradas["acciones"]["mover_adelante"]["mando"]),
		JOY_BUTTON_DPAD_UP
	)

	comprobar.call(
		"un DualSense se nombra como PlayStation",
		PreferenciasSiga.familia_por_nombre("PS5 Controller"),
		"playstation"
	)
	comprobar.call(
		"un Pro Controller como Nintendo",
		PreferenciasSiga.familia_por_nombre("Nintendo Switch Pro Controller"),
		"nintendo"
	)
	(
		comprobar
		. call(
			"y el botón de abajo se llama como está impreso",
			[
				PreferenciasSiga.nombre_boton_mando(JOY_BUTTON_A, "xbox"),
				PreferenciasSiga.nombre_boton_mando(JOY_BUTTON_A, "playstation"),
				PreferenciasSiga.nombre_boton_mando(JOY_BUTTON_A, "nintendo"),
			],
			["A", "Cruz", "B"]
		)
	)
