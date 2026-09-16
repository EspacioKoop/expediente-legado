extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_gate_y_semilla()
	_probar_vigilia_deliberada()
	_probar_red_y_senuelo()
	_probar_reversibilidad_y_solucion()
	_probar_accesibilidad_y_prototipo()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_gate_y_semilla() -> void:
	var jornada := {"dia": 5}
	_comprobar(not SuenoAnansiAkan.puede_entrar(jornada), "sin semilla Anansi no entra")
	_comprobar(
		not SuenoAnansiAkan.registrar_semilla(jornada, 2, true),
		"dos tramos no bastan aunque el relato figure terminado",
	)
	_comprobar(
		not SuenoAnansiAkan.registrar_semilla(jornada, 3, false),
		"tres tramos sin terminar no activan",
	)
	_comprobar(
		SuenoAnansiAkan.registrar_semilla(jornada, 3, true),
		"la escucha completa registra la semilla",
	)
	_comprobar(SuenoAnansiAkan.puede_entrar(jornada), "la semilla común habilita la familia")
	_comprobar(
		SemillasOniricas.familias_activas(jornada),
		["anansi_akan"],
		"Anansi akan participa en el catálogo común",
	)
	var entrada: Dictionary = SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_anansi_akan"]
	_comprobar(
		entrada["fuentes"],
		["cassette:anansi_akan_relato_98"],
		"la procedencia de vigilia queda estable",
	)
	jornada["dia"] = 6
	_comprobar(not SuenoAnansiAkan.puede_entrar(jornada), "la semilla no cruza de jornada")


func _probar_vigilia_deliberada() -> void:
	var jornada := {"dia": 3}
	var cassette := AnansiAkanVigilia.new()
	get_root().add_child(cassette)
	cassette.configurar(jornada)
	_comprobar(not cassette.esta_activada(), "el cassette presente no activa nada")
	_comprobar(not cassette.escuchar(), "primer tramo no completa el relato")
	_comprobar(cassette.pasos_escuchados(), 1, "primer tramo queda registrado")
	_comprobar(not cassette.esta_activada(), "primer tramo no activa la familia")
	_comprobar(not cassette.escuchar(), "segundo tramo tampoco completa")
	_comprobar(cassette.pasos_escuchados(), 2, "segundo tramo queda registrado")
	_comprobar(cassette.escuchar(), "tercer tramo termina la escucha")
	_comprobar(cassette.relato_terminado(), "el relato queda marcado como terminado")
	_comprobar(cassette.esta_activada(), "terminar activa la semilla")
	var intensidad := int(
		SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_anansi_akan"]["intensidad"]
	)
	cassette.escuchar()
	_comprobar(
		SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_anansi_akan"]["intensidad"],
		intensidad,
		"repetir la misma fuente es idempotente",
	)
	cassette.queue_free()


func _probar_red_y_senuelo() -> void:
	var estado := SuenoAnansiAkan.estado_inicial()
	_comprobar((estado["nodos"] as Dictionary).size(), 4, "la red parte de cuatro nodos")
	_comprobar((estado["conexiones"] as Dictionary).size(), 4, "la red parte de cuatro hilos")

	var pista_real := SuenoAnansiAkan.observar_conexion(estado, "telefono_impresora")
	_comprobar(not pista_real["senuelo_detectable"], "una conexión real mantiene continuidad")
	var pista_falsa := SuenoAnansiAkan.observar_conexion(estado, "telefono_puerta_senuelo")
	_comprobar(pista_falsa["senuelo_detectable"], "el señuelo se detecta por observación")
	_comprobar(
		pista_falsa["pista_espacial"],
		"orientacion_incompatible_en_destino",
		"la pista del señuelo es espacial y explícita",
	)

	var remoto := SuenoAnansiAkan.manipular_conexion(estado, "telefono_impresora", "tensar")
	_comprobar(remoto["efecto_remoto"], "impresora", "tensar afecta un nodo remoto rastreable")
	_comprobar(
		int((remoto["nodos"] as Dictionary)["impresora"]["valor"]),
		1,
		"el efecto remoto altera el estado observable",
	)

	var falso := SuenoAnansiAkan.manipular_conexion(estado, "telefono_puerta_senuelo", "tensar")
	_comprobar(falso["efecto_remoto"], "", "el señuelo no finge un efecto remoto")
	_comprobar(
		int((falso["nodos"] as Dictionary)["puerta"]["valor"]),
		0,
		"el señuelo no modifica la puerta",
	)


func _probar_reversibilidad_y_solucion() -> void:
	var estado := SuenoAnansiAkan.estado_inicial()
	var tensado := SuenoAnansiAkan.manipular_conexion(estado, "telefono_impresora", "tensar")
	_comprobar(tensado["reversible"], "toda manipulación válida se marca reversible")
	var restaurado := SuenoAnansiAkan.revertir_ultima(tensado)
	_comprobar(restaurado["revertido"], "se puede deshacer la última manipulación")
	_comprobar(
		int((restaurado["nodos"] as Dictionary)["impresora"]["valor"]),
		0,
		"deshacer restaura el nodo remoto",
	)

	var cortado := SuenoAnansiAkan.manipular_conexion(estado, "impresora_archivador", "cortar")
	_comprobar(
		not bool((cortado["conexiones"] as Dictionary)["impresora_archivador"]["activa"]),
		"cortar desactiva sin destruir el hilo",
	)
	var reconectado := SuenoAnansiAkan.manipular_conexion(
		cortado, "impresora_archivador", "reconectar"
	)
	_comprobar(
		bool((reconectado["conexiones"] as Dictionary)["impresora_archivador"]["activa"]),
		"una conexión cortada siempre puede reconectarse",
	)

	var solucion := SuenoAnansiAkan.estado_inicial()
	solucion = SuenoAnansiAkan.manipular_conexion(solucion, "telefono_impresora", "tensar")
	solucion = SuenoAnansiAkan.manipular_conexion(solucion, "impresora_archivador", "tensar")
	solucion = SuenoAnansiAkan.manipular_conexion(solucion, "archivador_puerta", "tensar")
	_comprobar(solucion["resuelto"], "las tres relaciones observables resuelven el estado")
	_comprobar(SuenoAnansiAkan.objetivo_resuelto(solucion), "la solución es determinista")


func _probar_accesibilidad_y_prototipo() -> void:
	var normal := SuenoAnansiAkan.plan_presentacion(false)
	var reducida := SuenoAnansiAkan.plan_presentacion(true)
	_comprobar(normal["pistas_visuales"], "la presentación normal conserva señales visuales")
	_comprobar(reducida["pistas_visuales"], "movimiento reducido conserva señales visuales")
	_comprobar(reducida["duracion"], 0.0, "movimiento reducido evita interpolación")
	_comprobar(not reducida["sacudida_camara"], "movimiento reducido nunca sacude la cámara")

	var sueno := SuenoAnansiAkan.new()
	sueno.reduccion_movimiento = true
	get_root().add_child(sueno)
	sueno.preparar()
	for id_nodo in ["telefono", "impresora", "archivador", "puerta"]:
		_comprobar(
			sueno.get_node_or_null("Nodo_%s" % id_nodo) != null,
			"el prototipo materializa nodo %s" % id_nodo,
		)
	for id_hilo in [
		"telefono_impresora",
		"impresora_archivador",
		"archivador_puerta",
		"telefono_puerta_senuelo",
	]:
		_comprobar(
			sueno.get_node_or_null("Hilo_%s" % id_hilo) != null,
			"el prototipo materializa hilo %s" % id_hilo,
		)
	_comprobar(
		sueno.get_node_or_null("Hilo_telefono_puerta_senuelo/PistaOrientacion") != null,
		"el señuelo tiene una pista visual en geometría",
	)
	var resultado := sueno.usar_conexion("telefono_impresora", "tensar")
	_comprobar(resultado["efecto_remoto"], "impresora", "el prototipo usa la misma regla pura")
	sueno.queue_free()


func _comprobar(actual, esperado = true, nombre: String = "") -> void:
	if typeof(esperado) == TYPE_STRING and nombre.is_empty():
		nombre = String(esperado)
		esperado = true
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Anansi akan: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
