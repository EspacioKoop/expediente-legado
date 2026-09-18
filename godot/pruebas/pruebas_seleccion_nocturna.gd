extends RefCounted


static func todo(comprobar: Callable) -> void:
	var jornada := Jornada.nueva(17)
	jornada["fase"] = "casa"
	jornada["leido_hoy"] = ["A", "B", "C", "D"]

	comprobar.call("memoria nocturna empieza vacía", jornada["seleccion_nocturna"], [])
	comprobar.call("acepta selección vacía", Jornada.preparar_sueno(jornada, []), true)
	comprobar.call(
		"acepta repetición de un documento leído",
		Jornada.preparar_sueno(jornada, ["B", "B", "A"]),
		true
	)
	comprobar.call("conserva orden y repetición", jornada["seleccion_nocturna"], ["B", "B", "A"])

	var anterior: Array = jornada["seleccion_nocturna"].duplicate()
	comprobar.call(
		"rechaza documento no leído", Jornada.preparar_sueno(jornada, ["B", "X"]), false
	)
	comprobar.call("un rechazo no pisa selección válida", jornada["seleccion_nocturna"], anterior)
	comprobar.call(
		"rechaza más de tres huecos",
		Jornada.preparar_sueno(jornada, ["A", "B", "C", "D"]),
		false
	)

	var sin_memoria := Sueno.semilla(4, jornada["leido_hoy"], 17)
	var con_memoria := Sueno.semilla(4, jornada["leido_hoy"], 17, ["B", "B", "A"])
	comprobar.call("la selección cambia la semilla nocturna", con_memoria == sin_memoria, false)
	comprobar.call(
		"repetir cambia la semilla",
		Sueno.semilla(4, jornada["leido_hoy"], 17, ["B"])
		== Sueno.semilla(4, jornada["leido_hoy"], 17, ["B", "B"]),
		false
	)

	var opciones := SeleccionNocturna.opciones_sueno(jornada)
	var noche := Sueno.noche(4, jornada["leido_hoy"], [], 17, opciones)
	comprobar.call(
		"misma selección y semilla reproducen noche",
		Sueno.noche(4, jornada["leido_hoy"], [], 17, opciones),
		noche
	)

	var resultado := Jornada.dormir(jornada)
	comprobar.call("dormir expone la selección persistida", resultado["seleccion_nocturna"], anterior)
	var recargada: Dictionary = JSON.parse_string(JSON.stringify(jornada))
	Jornada.completar(recargada, 17)
	comprobar.call("recarga conserva selección", recargada["seleccion_nocturna"], anterior)
	Jornada.despertar(recargada)
	comprobar.call("despertar limpia selección", recargada["seleccion_nocturna"], [])

	var vacia := Jornada.nueva(23)
	vacia["fase"] = "casa"
	vacia["leido_hoy"] = ["A"]
	Jornada.preparar_sueno(vacia, [])
	Jornada.dormir(vacia)
	comprobar.call("cero documentos mantiene salida segura", vacia["sueno_escenas"].is_empty(), false)
