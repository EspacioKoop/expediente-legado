extends SceneTree

const Sesion := preload("res://guion/sueno_puzzle_sesion.gd")
const PartidaModelo := preload("res://guion/partida.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_guardado_y_json()
	_probar_guardado_real_de_partida()
	_probar_aislamiento_por_dia_y_fase()
	_probar_rechazos()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _jornada() -> Dictionary:
	return {
		"dia": 7,
		"fase": "sueño",
		"leido_hoy": ["F-1", "F-2"],
	}


func _probar_guardado_y_json() -> void:
	var jornada := _jornada()
	var datos := {"nucleo": {"state": "pendiente"}, "seleccion": ["r1"]}
	_comprobar(
		Sesion.guardar(jornada, Sesion.TIPO_RELACION, "caso1", "pista7", datos),
		"guarda una sesión válida dentro de Jornada",
	)
	_comprobar(Sesion.tipo_actual(jornada) == Sesion.TIPO_RELACION, "expone el tipo actual")
	var actual := Sesion.actual(jornada)
	_comprobar(actual.get("dia", -1) == 7, "la sesión queda ligada al día")
	_comprobar(actual.get("caso_id", "") == "caso1", "conserva el caso")
	_comprobar(actual.get("reward_id", "") == "pista7", "conserva la recompensa opaca")
	_comprobar(
		actual.get("datos", {}).get("seleccion", []) == ["r1"],
		"conserva el estado serializado del puzzle",
	)

	actual["datos"]["seleccion"].append("intruso")
	_comprobar(
		Sesion.actual(jornada).get("datos", {}).get("seleccion", []) == ["r1"],
		"actual devuelve copia profunda y no deja mutar Jornada desde fuera",
	)

	var texto := JSON.stringify(jornada)
	var recargada: Dictionary = JSON.parse_string(texto)
	_comprobar(
		Sesion.actual(recargada).get("reward_id", "") == "pista7",
		"sobrevive al mismo JSON que usa el guardado de Partida",
	)


func _probar_guardado_real_de_partida() -> void:
	var ruta := "user://prueba-sesion-onirica-%d.json" % Time.get_ticks_usec()
	_limpiar(ruta)
	var partida := PartidaModelo.new()
	partida.estado = PartidaModelo.nueva()
	var jornada: Dictionary = partida.estado["jornada"]
	jornada["dia"] = 11
	jornada["fase"] = "sueño"
	_comprobar(
		(
			Sesion
			. guardar(
				jornada,
				Sesion.TIPO_ECOS,
				"caso-real",
				"pista-real",
				{"nucleo": {"state": "pendiente"}, "intentos": 2},
			)
		),
		"la sesión se integra en la Jornada real de Partida",
	)
	_comprobar(partida.guardar(ruta), "Partida guarda la Jornada con sesión onírica")

	var recargada := PartidaModelo.new()
	var carga := recargada.cargar(ruta)
	_comprobar(carga.get("resultado", "") == "cargada", "Partida recarga el guardado de prueba")
	var sesion := Sesion.actual(recargada.estado["jornada"])
	_comprobar(sesion.get("tipo", "") == Sesion.TIPO_ECOS, "el tipo sobrevive al disco")
	_comprobar(sesion.get("caso_id", "") == "caso-real", "el caso sobrevive al disco")
	_comprobar(sesion.get("reward_id", "") == "pista-real", "la recompensa sobrevive al disco")
	_comprobar(
		int(sesion.get("datos", {}).get("intentos", -1)) == 2,
		"los intentos consumidos sobreviven al disco",
	)
	_limpiar(ruta)


func _probar_aislamiento_por_dia_y_fase() -> void:
	var jornada := _jornada()
	Sesion.guardar(jornada, Sesion.TIPO_ECOS, "caso1", "pista1", {"nucleo": {"seed": 4}})
	var otro_dia := jornada.duplicate(true)
	otro_dia["dia"] = 8
	_comprobar(Sesion.actual(otro_dia).is_empty(), "una noche vieja no bloquea el día siguiente")
	var despierta := jornada.duplicate(true)
	despierta["fase"] = "archivo"
	_comprobar(Sesion.actual(despierta).is_empty(), "fuera del sueño la sesión no es activa")
	_comprobar(
		Sesion.tipo_actual(otro_dia).is_empty(),
		"un estado obsoleto tampoco anuncia tipo de puzzle",
	)


func _probar_rechazos() -> void:
	var jornada := _jornada()
	_comprobar(
		not Sesion.guardar(jornada, "inventado", "caso1", "pista1", {"x": 1}),
		"rechaza tipos no catalogados",
	)
	_comprobar(
		not Sesion.guardar(jornada, Sesion.TIPO_ECOS, "", "pista1", {"x": 1}),
		"rechaza sesión sin caso",
	)
	_comprobar(
		not Sesion.guardar(jornada, Sesion.TIPO_ECOS, "caso1", "", {"x": 1}),
		"rechaza sesión sin reward_id",
	)
	_comprobar(
		not Sesion.guardar(jornada, Sesion.TIPO_ECOS, "caso1", "pista1", {}),
		"rechaza sesión sin estado serializado",
	)
	var fijada := _jornada()
	_comprobar(
		(
			Sesion
			. guardar(
				fijada,
				Sesion.TIPO_RELACION,
				"caso1",
				"pista1",
				{"nucleo": {"state": "pendiente"}},
			)
		),
		"acepta la primera identidad de puzzle de la noche",
	)
	_comprobar(
		not (
			Sesion
			. guardar(
				fijada,
				Sesion.TIPO_ECOS,
				"caso2",
				"pista2",
				{"nucleo": {"state": "pendiente"}},
			)
		),
		"una sesión ya fijada no puede convertirse en otro puzzle",
	)

	var corrupta := _jornada()
	corrupta[Sesion.CLAVE] = {
		"dia": 7,
		"tipo": Sesion.TIPO_ECOS,
		"caso_id": "caso1",
		"reward_id": "pista1",
		"datos": "no-es-diccionario",
	}
	_comprobar(Sesion.registrada_esta_noche(corrupta), "detecta una entrada corrupta de esta noche")
	_comprobar(Sesion.actual(corrupta).is_empty(), "no entrega una sesión manipulada como válida")


func _limpiar(ruta: String) -> void:
	for candidata in [ruta, ruta + ".nuevo", ruta + ".roto"]:
		if FileAccess.file_exists(candidata):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidata))


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO sesión puzzle onírico: " + nombre)
