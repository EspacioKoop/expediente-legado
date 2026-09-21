extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	process_frame.connect(_ejecutar, CONNECT_ONE_SHOT)


func _ejecutar() -> void:
	_probar_compatibilidad()
	_probar_franjas()
	_probar_discretizacion()
	_probar_streams_adaptativos()
	_probar_eco_de_vigilia()
	_probar_reproduccion_y_fundido()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_compatibilidad() -> void:
	var base := Ambiente.stream("archivo")
	_comprobar(base != null, "la cama base sigue existiendo")
	_comprobar(
		Ambiente.stream_adaptativo("archivo", {}) == base,
		"sin contexto se reutiliza exactamente la cama de #119",
	)
	_comprobar(
		Ambiente.stream_adaptativo("invalida", {"hora": 9.0}) == null,
		"una fase invalida sigue sin producir audio",
	)
	_comprobar(
		Ambiente.perfil_adaptativo("invalida", {"estres": 1.0}).is_empty(),
		"una fase invalida no fabrica perfil",
	)


func _probar_franjas() -> void:
	_comprobar(_franja(9.0) == Ambiente.FRANJA_MANANA, "09:00 es manana")
	_comprobar(_franja(13.0) == Ambiente.FRANJA_MEDIODIA, "13:00 es mediodia")
	_comprobar(_franja(17.0) == Ambiente.FRANJA_TARDE, "17:00 es tarde")
	_comprobar(_franja(21.0) == Ambiente.FRANJA_NOCHE, "21:00 es noche")
	_comprobar(_franja(6.0) == Ambiente.FRANJA_NOCHE, "06:00 conserva edificio vacio")
	_comprobar(
		int(Ambiente.perfil_adaptativo("archivo", {"estres": 9.0})["estres"]) == 2,
		"el estres se acota antes de discretizar",
	)
	_comprobar(
		int(Ambiente.perfil_adaptativo("archivo", {"meticulosidad": -2.0})["detalle"]) == 0,
		"la meticulosidad negativa no crea detalle",
	)


func _probar_discretizacion() -> void:
	var media_a := Ambiente.stream_adaptativo("archivo", {"estres": 0.40})
	var media_b := Ambiente.stream_adaptativo("archivo", {"estres": 0.60})
	_comprobar(media_a == media_b, "dos valores de la misma banda reutilizan stream")

	var alta := Ambiente.stream_adaptativo("archivo", {"estres": 0.90})
	_comprobar(alta != media_a, "cambiar de banda crea otra variante")
	_comprobar(
		alta.data != media_a.data,
		"la banda alta de estres cambia la senal y no solo la identidad del recurso",
	)


func _probar_streams_adaptativos() -> void:
	var base := Ambiente.stream("archivo") as AudioStreamWAV
	var manana := Ambiente.stream_adaptativo("archivo", {"hora": 9.0}) as AudioStreamWAV
	var mediodia := Ambiente.stream_adaptativo("archivo", {"hora": 13.0}) as AudioStreamWAV
	var tarde := Ambiente.stream_adaptativo("archivo", {"hora": 17.0}) as AudioStreamWAV
	var noche := Ambiente.stream_adaptativo("archivo", {"hora": 21.0}) as AudioStreamWAV

	_comprobar(manana.data != base.data, "la manana modifica actividad de oficina")
	_comprobar(mediodia.data != manana.data, "el mediodia baja la actividad")
	_comprobar(tarde.data != mediodia.data, "la tarde recupera actividad")
	_comprobar(noche.data != tarde.data, "la noche vacia el edificio")

	var detalle := Ambiente.stream_adaptativo(
		"archivo", {"meticulosidad": 0.95}
	) as AudioStreamWAV
	_comprobar(detalle.data != base.data, "alta meticulosidad deja microdetalle opcional")


func _probar_eco_de_vigilia() -> void:
	var base := Ambiente.stream("sueño") as AudioStreamWAV
	var eco := Ambiente.stream_adaptativo(
		"sueño", {"vigilia_fase": "archivo"}
	) as AudioStreamWAV
	_comprobar(eco != base, "el sueño puede recibir una huella de vigilia")
	_comprobar(eco.data != base.data, "la huella de vigilia altera la cama onirica")
	_comprobar(
		Ambiente.stream_adaptativo("sueño", {"vigilia_fase": "desconocida"}) == base,
		"una vigilia invalida no inventa una fuente sonora",
	)
	_comprobar(
		Ambiente.stream_adaptativo("archivo", {"vigilia_fase": "casa"}) == Ambiente.stream("archivo"),
		"el eco de vigilia solo existe dentro del sueño",
	)


func _probar_reproduccion_y_fundido() -> void:
	var escena := Node.new()
	root.add_child(escena)

	var manana := Ambiente.reproducir(escena, "archivo", -24.0, {"hora": 9.0})
	_comprobar(manana != null, "se crea una voz adaptativa")
	_comprobar(
		Ambiente.reproducir(escena, "archivo", -24.0, {"hora": 10.0}) == manana,
		"misma franja conserva la voz y evita reinicios",
	)

	var tarde := Ambiente.reproducir(escena, "archivo", -24.0, {"hora": 17.0})
	_comprobar(tarde != null and tarde != manana, "cambiar de perfil cruza a una voz nueva")
	_comprobar(
		String(manana.name) == "%sSaliente" % Ambiente.NODO,
		"la voz anterior sale por el fundido comun",
	)
	_comprobar(
		escena.get_node_or_null(Ambiente.NODO) == tarde,
		"la voz nueva ocupa el nodo canonico",
	)
	escena.free()


func _franja(hora: float) -> String:
	return String(Ambiente.perfil_adaptativo("archivo", {"hora": hora})["franja"])


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO: " + descripcion)
