extends SceneTree

## Regresión aislada de #787: la casa deja una huella concreta y el sueño la
## traduce solo a presentación del gato, sin introducir afinidad ni progreso.

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _probar() -> void:
	var gato := {"presente": true, "dias_sin_comer": 0}

	_comprobar(
		GatoEcoSueno.accion_de_verbo(Interactuable3D.Verbo.ACARICIAR) == GatoEcoSueno.ACARICIAR,
		"acariciar usa el vocabulario de eco",
	)
	_comprobar(
		GatoEcoSueno.accion_de_verbo(Interactuable3D.Verbo.EXAMINAR).is_empty(),
		"un verbo ajeno no inventa memoria",
	)

	_comprobar(GatoEcoSueno.registrar(gato, 4, GatoEcoSueno.ACARICIAR), "registra caricia")
	var caricia := GatoEcoSueno.efecto(gato, 4)
	_comprobar(caricia.get("estado", "") == "mimos", "caricia reaparece como mimos")
	_comprobar(float(caricia.get("distancia", 9.0)) < 1.4, "caricia acerca al gato")
	_comprobar(GatoEcoSueno.efecto(gato, 5).is_empty(), "otro día no hereda el eco")

	_comprobar(GatoEcoSueno.registrar(gato, 5, GatoEcoSueno.LLAMAR), "registra llamada")
	GatoEcoSueno.registrar(gato, 5, GatoEcoSueno.LLAMAR)
	var llamada := GatoEcoSueno.efecto(gato, 5)
	_comprobar(llamada.get("estado", "") == "observando", "llamada reaparece como mirada")
	_comprobar(
		float(llamada.get("distancia", 9.0)) < 1.0,
		"dos llamadas solo reducen la distancia presentacional",
	)

	GatoEcoSueno.registrar(gato, 5, GatoEcoSueno.COGER)
	var cogido := GatoEcoSueno.efecto(gato, 5)
	_comprobar(cogido.get("estado", "") == "sentado", "coger reaparece como cercanía quieta")

	GatoEcoSueno.registrar(gato, 5, GatoEcoSueno.ALIMENTAR)
	var alimentado := GatoEcoSueno.efecto(gato, 5)
	_comprobar(alimentado.get("estado", "") == "durmiendo", "alimentar reaparece como descanso")
	_comprobar(not alimentado.has("objetivo"), "el eco no contiene objetivo")
	_comprobar(not alimentado.has("pista"), "el eco no contiene pista")

	var visual := Gato.new()
	root.add_child(visual)
	visual.empezar(Vector3.ZERO, [Vector3.ZERO])
	_comprobar(visual.presentar_estado("durmiendo"), "el gato acepta una pose presentacional")
	_comprobar(visual.estado.get("estado", "") == "durmiendo", "la pose queda observable")

	visual.configurar_reduccion_movimiento(true)
	visual.presentar_estado("mimos")
	_comprobar(
		is_zero_approx(visual._cola.rotation.y),
		"reducción de movimiento congela el vaivén decorativo de la cola",
	)
	_comprobar(
		not is_zero_approx(visual._cuerpo.position.x),
		"reducción de movimiento conserva una pose estática legible para mimos",
	)
	visual.interactuar(null)
	visual.interactuar(null)
	_comprobar(visual._cuerpo.position.y > 0.0, "coger conserva una respuesta estática visible")
	visual.avanzar(0, Vector3.ZERO, Gato.DURACION_COGIDO + 0.1)
	_comprobar(is_zero_approx(visual._cuerpo.position.y), "la pose de coger termina sin tween")
	visual.free()

	for i in 10:
		GatoEcoSueno.registrar(gato, 6, GatoEcoSueno.ACARICIAR)
	_comprobar(
		GatoEcoSueno.acciones_de(gato, 6).size() == GatoEcoSueno.MAX_ACCIONES,
		"la memoria está acotada",
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(actual: bool, nombre: String) -> void:
	if actual:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO eco gato sueño: %s" % nombre)
