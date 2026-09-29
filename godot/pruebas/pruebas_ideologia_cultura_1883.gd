extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	_probar_contrato_compartido()
	_probar_correo_postal()
	_probar_tablon_oficina()
	print("issue_1883: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_contrato_compartido() -> void:
	var circular := IdeologiaCulturaCotidiana1883.superficie(
		IdeologiaCulturaCotidiana1883.SUPERFICIE_CIRCULAR
	)
	var postal := IdeologiaCulturaCotidiana1883.superficie(
		IdeologiaCulturaCotidiana1883.SUPERFICIE_POSTAL
	)
	_comprobar(
		String(circular.get("evento_base", "")) == IdeologiaCulturaCotidiana1883.EVENTO_BASE,
		"la circular referencia el hecho compartido",
	)
	_comprobar(
		String(postal.get("evento_base", "")) == IdeologiaCulturaCotidiana1883.EVENTO_BASE,
		"el aviso postal referencia el mismo hecho",
	)
	_comprobar(
		String(circular.get("tratamiento", "")) != String(postal.get("tratamiento", "")),
		"las dos superficies tienen tratamientos distinguibles",
	)

	var estado := {
		Prometeo.CLAVE_ELECCIONES_IDEOLOGICAS:
		[{"id": "eleccion-previa", "eje": "centrista"}],
		Prometeo.CLAVE_EXPOSICION_IDEOLOGICA: [],
	}
	var elecciones_antes: Array = (
		estado[Prometeo.CLAVE_ELECCIONES_IDEOLOGICAS] as Array
	).duplicate(true)
	_comprobar(
		IdeologiaCulturaCotidiana1883.registrar_exposicion(
			estado, IdeologiaCulturaCotidiana1883.SUPERFICIE_CIRCULAR, 1
		),
		"examinar la circular registra exposición",
	)
	_comprobar(
		not IdeologiaCulturaCotidiana1883.registrar_exposicion(
			estado, IdeologiaCulturaCotidiana1883.SUPERFICIE_CIRCULAR, 1
		),
		"repetir la misma circular es idempotente",
	)
	_comprobar(
		IdeologiaCulturaCotidiana1883.registrar_exposicion(
			estado, IdeologiaCulturaCotidiana1883.SUPERFICIE_POSTAL, 1
		),
		"leer el aviso postal registra su tratamiento",
	)
	var exposiciones: Array = estado[Prometeo.CLAVE_EXPOSICION_IDEOLOGICA]
	_comprobar(exposiciones.size() == 2, "cada superficie aporta como máximo una exposición")
	_comprobar(
		estado[Prometeo.CLAVE_ELECCIONES_IDEOLOGICAS] == elecciones_antes,
		"la exposición no modifica elecciones ideológicas",
	)


func _probar_correo_postal() -> void:
	var pieza := {}
	for candidata in CorreoPostal.catalogo():
		if String(candidata.get("id", "")) == "aviso_horario_planta4":
			pieza = candidata
			break
	_comprobar(not pieza.is_empty(), "el catálogo postal contiene el aviso institucional")
	_comprobar(
		String(pieza.get("evento_base", "")) == IdeologiaCulturaCotidiana1883.EVENTO_BASE,
		"el aviso postal conserva el id del hecho base",
	)
	_comprobar(
		String(pieza.get("ideologia_superficie_id", ""))
		== IdeologiaCulturaCotidiana1883.SUPERFICIE_POSTAL,
		"el aviso delega en la superficie compartida",
	)

	var jornada := Jornada.nueva(1883, 1)
	jornada["fase"] = "trayecto"
	var ids: Array[String] = []
	for candidata in CorreoPostal.disponibles(jornada):
		ids.append(String(candidata.get("id", "")))
	_comprobar(ids.has("aviso_horario_planta4"), "el aviso está disponible el primer día")


func _probar_tablon_oficina() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	var ronda := RondaCierre3D.new()
	mundo.add_child(ronda)
	ronda.configurar(
		{
			"ruta": ["comprobar_tablon"],
			"completados": [],
			"abandonada": false,
			"finalizada": false,
		}
	)
	var tablon := ronda.punto("comprobar_tablon")
	_comprobar(tablon != null, "la superficie de tablón usa el interactuable existente")
	if tablon != null:
		_comprobar(
			String(tablon.get_meta("evento_base", ""))
			== IdeologiaCulturaCotidiana1883.EVENTO_BASE,
			"el tablón conserva el mismo hecho base",
		)
		_comprobar(
			String(tablon.get_meta("ideologia_superficie_id", ""))
			== IdeologiaCulturaCotidiana1883.SUPERFICIE_CIRCULAR,
			"el tablón identifica el tratamiento de circular",
		)
		_comprobar(
			not String(tablon.get_meta("tratamiento", "")).is_empty(),
			"el tratamiento institucional queda materializado en la superficie",
		)
	mundo.queue_free()


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error(mensaje)
