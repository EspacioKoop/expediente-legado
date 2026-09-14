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

	# La del tarot se valida ya RESUELTA: sus planos declaran el ancho y la
	# cara, y la figura en el formato del reproductor se construye al resolver.
	var carta := {"id": "la-luna", "nombre": "La Luna"}
	var tarot := TarotCinematica.planos_de(carta)
	comprobar.call("la cinemática del tarot está bien declarada", Cinematica.validar(tarot), [])
	comprobar.call("tiene los cuatro planos", tarot.size(), 4)
	comprobar.call("todos son 2d", tarot.all(func(p): return p["tipo"] == "2d"), true)

	# El volteo es un estrechamiento: el reproductor no sabe escalar, así que
	# si el canto dejara de ser más estrecho, la carta no se voltearía.
	var anchos := tarot.map(func(p): return p["figura"][0]["rect"].size.x)
	comprobar.call("el canto es el plano más estrecho", anchos[1], anchos.min())
	comprobar.call("y el dorso y el frontal miden igual", anchos[0], anchos[2])

	# El frontal es el único momento de color del juego: si se quedara del gris
	# del dorso, encontrar una carta no se distinguiría de no encontrarla.
	comprobar.call(
		"el frontal no tiene el color del dorso",
		tarot[2]["figura"][0]["color"] != tarot[0]["figura"][0]["color"],
		true
	)

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

	# Y no se estropea entre reproducciones: la figura es un valor anidado, que
	# es justo lo que una copia superficial compartiría.
	tarot[0]["figura"][0]["color"] = Color.RED
	comprobar.call(
		"la figura se entrega en copia profunda",
		TarotCinematica.planos_de(carta)[0]["figura"][0]["color"] != Color.RED,
		true
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
		"la entrada al sueño no mueve la figura",
		entrada_sueno.all(func(p): return p["desde"] == p["hasta"]),
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

	# Eje 2 y 3 son el stick DERECHO. El izquierdo (0 y 1) ya anda, y mirar con
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
