extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_sin_interaccion()
	_probar_activacion_estable()
	_probar_idempotencia_y_limite()
	_probar_persistencia_y_cambio_de_dia()
	_probar_migracion_temprana()
	_probar_seleccion_reproducible()
	_probar_guardado_de_partida()
	_probar_catalogo_cerrado()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_sin_interaccion() -> void:
	var jornada := {"dia": 4}
	_comprobar(
		SemillasOniricas.obtener_semillas(jornada).is_empty(),
		"sin interacción no existe ninguna semilla",
	)
	_comprobar(
		SemillasOniricas.seleccionar_para_noche(jornada, 1234)["familias"].is_empty(),
		"sin semillas la selección mitológica queda vacía",
	)
	_comprobar(
		not SemillasOniricas.activar_semilla_onirica(jornada, "mito_inventado", "tv:algo"),
		"un id fuera del catálogo no puede activarse",
	)
	_comprobar(
		not SemillasOniricas.activar_semilla_onirica(jornada, "minotauro", ""),
		"una interacción sin fuente estable no activa nada",
	)


func _probar_activacion_estable() -> void:
	var jornada := {"dia": 7}
	_comprobar(
		SemillasOniricas.activar_semilla_onirica(
			jornada, "minotauro", "rom:laberinto_gbc", 1
		),
		"una interacción deliberada activa la semilla",
	)
	var semillas := SemillasOniricas.obtener_semillas(jornada)
	var clave := "semilla_onirica_minotauro"
	_comprobar(semillas.has(clave), "la jornada guarda una clave estable semilla_onirica_<mito>")
	_comprobar(
		semillas[clave]["fuentes"],
		["rom:laberinto_gbc"],
		"la fuente concreta viaja con la semilla",
	)
	_comprobar(semillas[clave]["activada_en"], 7, "la activación queda ligada al día actual")


func _probar_idempotencia_y_limite() -> void:
	var jornada := {"dia": 3}
	SemillasOniricas.activar_semilla_onirica(jornada, "gilgamesh", "libro:tablillas", 1)
	SemillasOniricas.activar_semilla_onirica(jornada, "gilgamesh", "libro:tablillas", 3)
	var clave := "semilla_onirica_gilgamesh"
	var semillas := SemillasOniricas.obtener_semillas(jornada)
	_comprobar(semillas[clave]["intensidad"], 1, "repetir la misma fuente no suma intensidad")
	_comprobar(semillas[clave]["fuentes"].size(), 1, "repetir la misma fuente no la duplica")

	SemillasOniricas.activar_semilla_onirica(jornada, "gilgamesh", "rom:tablillas", 2)
	SemillasOniricas.activar_semilla_onirica(jornada, "gilgamesh", "poster:uruk", 2)
	semillas = SemillasOniricas.obtener_semillas(jornada)
	_comprobar(
		semillas[clave]["intensidad"],
		SemillasOniricas.INTENSIDAD_MAX,
		"varias fuentes respetan el límite de intensidad",
	)
	_comprobar(semillas[clave]["fuentes"].size(), 3, "las fuentes distintas sí quedan registradas")


func _probar_persistencia_y_cambio_de_dia() -> void:
	var jornada := {"dia": 9}
	SemillasOniricas.activar_semilla_onirica(jornada, "duat", "tv:documental_egipto", 2)
	var recargada = JSON.parse_string(JSON.stringify(jornada))
	_comprobar(typeof(recargada) == TYPE_DICTIONARY, "la jornada con semillas serializa como JSON")
	_comprobar(
		SemillasOniricas.familias_activas(recargada),
		["duat"],
		"guardar y recargar conserva las activaciones del día",
	)

	recargada["dia"] = 10
	_comprobar(
		SemillasOniricas.obtener_semillas(recargada).is_empty(),
		"al cambiar de día no se arrastran semillas temporales",
	)
	_comprobar(
		recargada[SemillasOniricas.CAMPO_JORNADA].is_empty(),
		"la limpieza diaria también sanea el estado persistido",
	)


func _probar_migracion_temprana() -> void:
	var jornada := {
		"dia": 2,
		"semillas_oniricas_hoy":
		{
			"gilgamesh":
			{
				"fuente": "libro:epopeya",
				"intensidad": 1,
				"activada_en": 2,
			}
		},
	}
	var semillas := SemillasOniricas.obtener_semillas(jornada)
	_comprobar(
		semillas.has("semilla_onirica_gilgamesh"),
		"el formato temprano se normaliza a la clave estable",
	)
	_comprobar(
		semillas["semilla_onirica_gilgamesh"]["fuentes"],
		["libro:epopeya"],
		"la fuente singular temprana se conserva",
	)


func _probar_seleccion_reproducible() -> void:
	var jornada := {"dia": 6}
	SemillasOniricas.activar_semilla_onirica(jornada, "gilgamesh", "rom:tablillas", 1)
	SemillasOniricas.activar_semilla_onirica(jornada, "minotauro", "poster:laberinto", 1)
	var primera := SemillasOniricas.seleccionar_para_noche(jornada, 4242)
	var segunda := SemillasOniricas.seleccionar_para_noche(jornada.duplicate(true), 4242)
	_comprobar(primera, segunda, "igual estado y raíz producen la misma selección")
	_comprobar(primera["familias"].size(), 2, "dos semillas compatibles pueden compartir noche")
	_comprobar(
		primera["mezcla"],
		"gilgamesh_minotauro",
		"solo una pareja declarada produce su mezcla declarada",
	)

	var solo_minotauro := {"dia": 6}
	SemillasOniricas.activar_semilla_onirica(
		solo_minotauro, "minotauro", "rom:laberinto_gbc", 1
	)
	var seleccion := SemillasOniricas.seleccionar_para_noche(solo_minotauro, 4242)
	_comprobar(
		seleccion["familias"],
		["minotauro"],
		"una familia sin semilla nunca entra por acompañar a otra",
	)

	var sin_reduccion := SemillasOniricas.seleccionar_para_noche(jornada, 99)
	jornada["reduccion_movimiento"] = true
	var con_reduccion := SemillasOniricas.seleccionar_para_noche(jornada, 99)
	_comprobar(
		sin_reduccion,
		con_reduccion,
		"reduccion_movimiento no altera qué familia se selecciona",
	)

	SemillasOniricas.activar_semilla_onirica(jornada, "aquiles", "tv:deporte", 3)
	SemillasOniricas.activar_semilla_onirica(jornada, "hidra", "rom:hidra", 2)
	var limitada: Array = SemillasOniricas.seleccionar_para_noche(jornada, 99, 2)["familias"]
	_comprobar(limitada.size(), 2, "la competición nocturna respeta el máximo de familias")
	_comprobar(_sin_duplicados(limitada), "una familia no ocupa dos huecos de la noche")


func _probar_guardado_de_partida() -> void:
	var guardado := Partida.nueva()
	guardado["jornada"]["dia"] = 5
	SemillasOniricas.activar_semilla_onirica(
		guardado["jornada"], "dragon_japones", "poster:importacion_98", 1
	)
	var recargado = JSON.parse_string(JSON.stringify(guardado))
	_comprobar(Partida.validar(recargado), [], "Partida acepta una jornada persistida con semillas")
	Jornada.completar(recargado["jornada"])
	_comprobar(
		SemillasOniricas.familias_activas(recargado["jornada"]),
		["dragon_japones"],
		"Jornada.completar no borra semillas de una partida recargada",
	)


func _probar_catalogo_cerrado() -> void:
	var esperadas := ["gilgamesh", "minotauro", "aquiles", "hidra", "dragon_japones", "duat"]
	for id_mito in esperadas:
		_comprobar(
			SemillasOniricas.clave(id_mito),
			"semilla_onirica_" + id_mito,
			"%s pertenece al catálogo común" % id_mito,
		)
	_comprobar(SemillasOniricas.clave("otro"), "", "un mito futuro requiere alta explícita")


func _sin_duplicados(familias: Array) -> bool:
	var unicas := []
	for familia in familias:
		if unicas.has(familia):
			return false
		unicas.append(familia)
	return true


func _comprobar(actual, esperado = true, nombre: String = "") -> void:
	if typeof(esperado) == TYPE_STRING and nombre.is_empty():
		nombre = String(esperado)
		esperado = true
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Semillas oníricas: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
