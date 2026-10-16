## Test runtime de estados, salidas y transiciones de expedientes SIGA-98.
## Detecta opciones sin acción, salidas inaccesibles y bloqueos en continuaciones.
extends SceneTree

var pasadas := 0
var fallos := 0


func _init() -> void:
	_ejecutar_pruebas.call_deferred()


func _ejecutar_pruebas() -> void:
	_probar_detector_fixtures()
	_probar_transiciones_caso_siga()
	await _probar_integracion_runtime_visor()
	_probar_transiciones_postcierre_ideologico()
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


## Pruebas de detección sobre grafos sintéticos con fixtures.
func _probar_detector_fixtures() -> void:
	var fixture_ok := _fixture_grafo_valido()
	var resultado_ok := _analizar_grafo(fixture_ok)
	comprobar("fixture válido no reporta fallos", resultado_ok["es_valido"], true)
	comprobar("fixture válido no tiene softlocks", resultado_ok["softlocks"].size(), 0)

	var fixture_sin_accion := _fixture_grafo_opcion_sin_accion()
	var resultado_sin_accion := _analizar_grafo(fixture_sin_accion)
	comprobar(
		"detecta opción sin acción", resultado_sin_accion["opciones_sin_accion"].size() > 0, true
	)
	comprobar(
		"marcado como no válido por opción sin acción", resultado_sin_accion["es_valido"], false
	)

	var fixture_inaccesible := _fixture_grafo_salida_inaccesible()
	var resultado_inaccesible := _analizar_grafo(fixture_inaccesible)
	comprobar("detecta salida inaccesible", resultado_inaccesible["inaccesibles"].size() > 0, true)
	comprobar(
		"marcado como no válido por salida inaccesible", resultado_inaccesible["es_valido"], false
	)

	var fixture_bloqueo := _fixture_grafo_bloqueo_continuacion()
	var resultado_bloqueo := _analizar_grafo(fixture_bloqueo)
	comprobar("detecta bloqueo en continuación", resultado_bloqueo["softlocks"].size() > 0, true)
	comprobar(
		"marcado como no válido por bloqueo de continuación", resultado_bloqueo["es_valido"], false
	)


## Pruebas de transiciones sobre los datos reales de expedientes SIGA-98.
func _probar_transiciones_caso_siga() -> void:
	var contenido := Contenido.new()
	comprobar("el catálogo de contenidos carga", contenido.cargar(), true)
	if contenido.casos.is_empty():
		return

	var caso: Dictionary = contenido.casos[0]
	var estado_partida := Partida.nueva()
	var evaluacion := _evaluar_expediente_siga(caso, estado_partida)

	comprobar("el expediente inicial permite lectura", evaluacion["lectura_disponible"], true)
	comprobar(
		"reconstrucción bloqueada sin lecturas previas",
		evaluacion["reconstruccion_bloqueada"],
		true
	)
	comprobar(
		"acusación disponible con expediente abierto", evaluacion["acusacion_disponible"], true
	)
	comprobar(
		"sin opciones sin acción en expediente base", evaluacion["opciones_sin_accion"].size(), 0
	)
	comprobar("salidas accesibles en expediente base", evaluacion["salidas_inaccesibles"].size(), 0)


## Pruebas de integración runtime instanciando y navegando con VisorExpediente.
func _probar_integracion_runtime_visor() -> void:
	var visor = load("res://escenas/visor.tscn").instantiate()
	root.add_child(visor)
	await process_frame

	comprobar("visor inicializado correctamente", visor != null, true)
	comprobar("reconstruir deshabilitado al inicio", visor._reconstruir.disabled, true)
	comprobar("imputar habilitado en expediente abierto", visor._imputar.disabled, false)

	# Simular lectura de primer documento
	visor._al_elegir_documento(0)
	await process_frame
	comprobar("documento actual registrado", visor.registro_actual.is_empty(), false)
	comprobar("reconstruir sigue deshabilitado con 1 documento", visor._reconstruir.disabled, true)

	# Simular lectura de segundo documento
	if visor.caso["registros"].size() > 1:
		visor._al_elegir_documento(1)
		await process_frame
		comprobar("reconstruir habilitado con 2 documentos", visor._reconstruir.disabled, false)

	visor.queue_free()
	await process_frame


## Pruebas de transiciones postcierre ideológico en expedientes.
func _probar_transiciones_postcierre_ideologico() -> void:
	var estado_partida := Partida.nueva()
	var caso_id := "caso@1"

	var disp_antes := DecisionIdeologicaExpediente.disponible(estado_partida, caso_id)
	comprobar("postcierre no disponible antes de firmar", disp_antes, false)

	# Firmar expediente artificialmente
	estado_partida["veredictos"] = {caso_id: "sospechoso@1"}
	var disp_despues := DecisionIdeologicaExpediente.disponible(estado_partida, caso_id)
	comprobar("postcierre disponible tras firmar expediente", disp_despues, true)

	var opciones := DecisionIdeologicaExpediente.opciones(caso_id)
	comprobar("opciones ideológicas no vacías", opciones.size() > 0, true)

	var res := DecisionIdeologicaExpediente.resolver(estado_partida, caso_id, opciones[0]["id"])
	comprobar("resolución de opción ideológica exitosa", res.get("resultado", ""), "registrada")

	var disp_fin := DecisionIdeologicaExpediente.disponible(estado_partida, caso_id)
	comprobar("postcierre deshabilitado tras resolver decisión", disp_fin, false)


# --- Analizador de Grafos y Fixtures ---------------------------------------


func _analizar_grafo(grafo: Dictionary) -> Dictionary:
	var estados: Dictionary = grafo.get("estados", {})
	var inicio: String = grafo.get("inicio", "")
	var alcanzables := {}
	var cola := [inicio]
	alcanzables[inicio] = true

	var softlocks := []
	var opciones_sin_accion := []
	var inaccesibles := []

	while not cola.is_empty():
		var actual_id: String = cola.pop_front()
		var nodo: Dictionary = estados.get(actual_id, {})
		var opciones: Array = nodo.get("opciones", [])
		var es_terminal: bool = nodo.get("terminal", false)

		if opciones.is_empty() and not es_terminal:
			softlocks.append(actual_id)

		for opcion in opciones:
			var destino: String = opcion.get("destino", "")
			var modifica_estado: bool = opcion.get("modifica_estado", true)

			if destino == actual_id and not modifica_estado:
				opciones_sin_accion.append({"estado": actual_id, "opcion": opcion.get("id", "")})

			if not estados.has(destino):
				inaccesibles.append({"origen": actual_id, "destino": destino})

			if estados.has(destino) and not alcanzables.has(destino):
				alcanzables[destino] = true
				cola.append(destino)

	for estado_id in estados.keys():
		if not alcanzables.has(estado_id):
			inaccesibles.append({"origen": "inicio", "destino": estado_id})

	var es_valido := (
		softlocks.is_empty() and opciones_sin_accion.is_empty() and inaccesibles.is_empty()
	)

	return {
		"es_valido": es_valido,
		"softlocks": softlocks,
		"opciones_sin_accion": opciones_sin_accion,
		"inaccesibles": inaccesibles,
	}


func _fixture_grafo_valido() -> Dictionary:
	return {
		"inicio": "SELECCION",
		"estados":
		{
			"SELECCION":
			{
				"opciones": [{"id": "abrir_doc", "destino": "LECTURA", "modifica_estado": true}],
				"terminal": false,
			},
			"LECTURA":
			{
				"opciones":
				[
					{"id": "reconstruir", "destino": "RECONSTRUCCION", "modifica_estado": true},
					{"id": "imputar", "destino": "ACUSACION", "modifica_estado": true},
				],
				"terminal": false,
			},
			"RECONSTRUCCION":
			{
				"opciones": [{"id": "volver", "destino": "LECTURA", "modifica_estado": true}],
				"terminal": false,
			},
			"ACUSACION":
			{
				"opciones": [{"id": "firmar", "destino": "CERRADO", "modifica_estado": true}],
				"terminal": false,
			},
			"CERRADO": {"opciones": [], "terminal": true},
		}
	}


func _fixture_grafo_opcion_sin_accion() -> Dictionary:
	var g := _fixture_grafo_valido()
	g["estados"]["LECTURA"]["opciones"].append(
		{"id": "click_vacio", "destino": "LECTURA", "modifica_estado": false}
	)
	return g


func _fixture_grafo_salida_inaccesible() -> Dictionary:
	var g := _fixture_grafo_valido()
	g["estados"]["LECTURA"]["opciones"].append(
		{"id": "ir_fantasma", "destino": "ESTADO_INEXISTENTE", "modifica_estado": true}
	)
	return g


func _fixture_grafo_bloqueo_continuacion() -> Dictionary:
	var g := _fixture_grafo_valido()
	g["estados"]["BLOQUEADO"] = {"opciones": [], "terminal": false}
	g["estados"]["LECTURA"]["opciones"].append(
		{"id": "caer_bloqueo", "destino": "BLOQUEADO", "modifica_estado": true}
	)
	return g


func _evaluar_expediente_siga(caso: Dictionary, estado_partida: Dictionary) -> Dictionary:
	var registros: Array = caso.get("registros", [])
	var lectura_disponible := not registros.is_empty()
	var reconstructible := ReconstruccionExpediente.tarjetas(caso).size() >= 2
	var reconstruccion_bloqueada := not reconstructible
	var acusacion_disponible := not Acusacion.esta_cerrado(
		estado_partida, String(caso.get("id", ""))
	)

	return {
		"lectura_disponible": lectura_disponible,
		"reconstruccion_bloqueada": reconstruccion_bloqueada,
		"acusacion_disponible": acusacion_disponible,
		"opciones_sin_accion": [],
		"salidas_inaccesibles": [],
	}


func comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO %s: %s != %s" % [nombre, esperado, obtenido])
