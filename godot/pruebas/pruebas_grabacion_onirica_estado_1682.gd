## Regresión end-to-end del estado persistente de cámara onírica (#1682).
extends SceneTree

const Estado = preload("res://guion/grabacion_onirica_estado.gd")

var _pasadas := 0
var _fallos := 0
var _ruta := "user://prueba_grabacion_onirica_estado_1682.json"


func _init() -> void:
	_limpiar()
	_probar_roundtrip_y_acusacion()
	_probar_toma_contaminada()
	_probar_sin_seleccion_y_caso_ajeno()
	_probar_migracion_guardado_anterior()
	_probar_validacion()
	_limpiar()

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _toma(original_id: String, proporcion: float = 0.7) -> Dictionary:
	return {
		"original_id": original_id,
		"original_identificado": true,
		"frase_completa": true,
		"tiempo_sujeto": 10.0 * proporcion,
		"duracion_total": 10.0,
		"figura_detecto_camara": false,
		"hubo_corte": false,
	}


func _caso(caso_id: String, original_id: String) -> Dictionary:
	return {
		"id": caso_id,
		"registros": [{"id": original_id}],
		"pistas": [{"id": "pista-" + caso_id}],
	}


func _sospechoso() -> Dictionary:
	return {
		"id": "sospechoso-1",
		"nombre": "Sospechoso",
		"desenlace": "Desenlace",
		"ataques": [],
	}


func _probar_roundtrip_y_acusacion() -> void:
	var partida := Partida.new()
	partida.estado = Partida.nueva()
	Estado.iniciar_cinta(partida.estado, 30.0)

	var registro := Estado.registrar_toma(partida.estado, _toma("doc-caso-a"))
	_comprobar("la toma cabe en la cinta", registro.get("ok"), true)
	_comprobar("registrar no selecciona a escondidas", Estado.seleccion_actual(partida.estado), {})
	_comprobar("selección explícita", Estado.seleccionar_toma(partida.estado, 0), true)
	_comprobar(
		"queda metraje persistible",
		partida.estado[Estado.CLAVE_ESTADO]["cinta"]["metraje_restante"],
		20.0
	)
	_comprobar("guardado con cinta", partida.guardar(_ruta), true)

	var releida := Partida.new()
	var carga := releida.cargar(_ruta)
	_comprobar("la partida relee la cinta", carga.get("resultado"), "cargada")
	var seleccion := Estado.seleccion_actual(releida.estado)
	_comprobar(
		"roundtrip conserva original", seleccion.get("toma", {}).get("original_id"), "doc-caso-a"
	)
	_comprobar(
		"roundtrip conserva evaluación",
		seleccion.get("estado"),
		GrabacionOniricaContrato.ESTADO_VALIDA
	)
	_comprobar(
		"roundtrip conserva metraje",
		releida.estado[Estado.CLAVE_ESTADO]["cinta"]["metraje_restante"],
		20.0
	)

	var jornada := Jornada.nueva()
	var resultado := Acusacion.acusar(
		releida.estado, jornada, _caso("caso-a", "doc-caso-a"), _sospechoso(), ["pista-caso-a"]
	)
	_comprobar("acusación cerrada", resultado.get("resultado"), "cerrado")
	_comprobar(
		"acusación recibe estado ya evaluado",
		resultado.get("cinta_onirica", {}).get("estado"),
		GrabacionOniricaContrato.ESTADO_VALIDA
	)
	_comprobar(
		"acusación conserva el original",
		resultado.get("cinta_onirica", {}).get("original_id"),
		"doc-caso-a"
	)
	_comprobar(
		"la proyección no cambia el veredicto firmado",
		Acusacion.veredicto_de(releida.estado, "caso-a"),
		"sospechoso-1"
	)


func _probar_toma_contaminada() -> void:
	var estado := Partida.nueva()
	Estado.iniciar_cinta(estado, 20.0)
	var registro := Estado.registrar_toma(estado, _toma("doc-caso-b", 0.5))
	_comprobar("toma contaminada también se registra", registro.get("ok"), true)
	_comprobar("selecciona contaminada", Estado.seleccionar_toma(estado, 0), true)

	var resultado := Acusacion.acusar(
		estado, Jornada.nueva(), _caso("caso-b", "doc-caso-b"), _sospechoso(), ["pista-caso-b"]
	)
	_comprobar(
		"contaminada llega sin recalcular",
		resultado.get("cinta_onirica", {}).get("estado"),
		GrabacionOniricaContrato.ESTADO_CONTAMINADA
	)
	_comprobar(
		"no fabrica blanco ni caos",
		resultado.get("cinta_onirica", {}).get("estado") not in ["blanco", "caos"],
		true
	)


func _probar_sin_seleccion_y_caso_ajeno() -> void:
	var sin_seleccion := Partida.nueva()
	Estado.iniciar_cinta(sin_seleccion, 20.0)
	Estado.registrar_toma(sin_seleccion, _toma("doc-caso-c"))
	var resultado_sin := Acusacion.acusar(
		sin_seleccion,
		Jornada.nueva(),
		_caso("caso-c", "doc-caso-c"),
		_sospechoso(),
		["pista-caso-c"]
	)
	_comprobar("sin selección no hay proyección", resultado_sin.has("cinta_onirica"), false)

	var ajeno := Partida.nueva()
	Estado.iniciar_cinta(ajeno, 20.0)
	Estado.registrar_toma(ajeno, _toma("doc-otro"))
	Estado.seleccionar_toma(ajeno, 0)
	var resultado_ajeno := Acusacion.acusar(
		ajeno, Jornada.nueva(), _caso("caso-d", "doc-caso-d"), _sospechoso(), ["pista-caso-d"]
	)
	_comprobar("original de otro caso no se proyecta", resultado_ajeno.has("cinta_onirica"), false)


func _probar_migracion_guardado_anterior() -> void:
	var anterior := Partida.nueva()
	anterior.erase(Estado.CLAVE_ESTADO)
	_escribir_json(_ruta, anterior)

	var partida := Partida.new()
	var carga := partida.cargar(_ruta)
	_comprobar("guardado anterior sigue cargando", carga.get("resultado"), "cargada")
	_comprobar(
		"guardado anterior recibe estado vacío de cámara",
		partida.estado.get(Estado.CLAVE_ESTADO, {}),
		Estado.nuevo()
	)


func _probar_validacion() -> void:
	var valida := Partida.nueva()
	Estado.iniciar_cinta(valida, 10.0)
	Estado.registrar_toma(valida, _toma("doc-validacion"))
	Estado.seleccionar_toma(valida, 0)
	_comprobar(
		"estado de cinta válido no da errores", Estado.validar(valida[Estado.CLAVE_ESTADO]), []
	)

	var rota := valida.duplicate(true)
	rota[Estado.CLAVE_ESTADO]["toma_seleccionada"] = 99
	var errores := Partida.validar(rota)
	_comprobar(
		"Partida rechaza índice de toma fuera de rango",
		errores.has("grabacion_onirica.toma_seleccionada fuera de rango"),
		true
	)


func _escribir_json(ruta: String, datos: Dictionary) -> void:
	var fichero := FileAccess.open(ruta, FileAccess.WRITE)
	if fichero == null:
		_fallos += 1
		printerr("FALLO no se pudo escribir fixture %s" % ruta)
		return
	fichero.store_string(JSON.stringify(datos))
	fichero.close()


func _limpiar() -> void:
	if FileAccess.file_exists(_ruta):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_ruta))
	if FileAccess.file_exists(_ruta + ".nuevo"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_ruta + ".nuevo"))
	if FileAccess.file_exists(_ruta + ".roto"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_ruta + ".roto"))


func _comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		_pasadas += 1
		return
	_fallos += 1
	printerr("FALLO %s: esperado=%s obtenido=%s" % [nombre, esperado, obtenido])
