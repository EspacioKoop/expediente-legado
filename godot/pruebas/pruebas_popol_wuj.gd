extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_gate_y_semilla()
	_probar_vigilia_deliberada()
	_probar_parejas_eco_y_equivalencia()
	_probar_accesibilidad_y_reproduccion()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_gate_y_semilla() -> void:
	var jornada := {"dia": 8}
	_comprobar(not SuenoPopolWuj.puede_entrar(jornada), "sin semilla Popol Wuj no entra")
	_comprobar(
		not SuenoPopolWuj.registrar_semilla(jornada, 1, true),
		"una inspección no basta",
	)
	_comprobar(
		not SuenoPopolWuj.registrar_semilla(jornada, 2, false),
		"sin comparar la pareja no activa",
	)
	_comprobar(
		SuenoPopolWuj.registrar_semilla(jornada, 2, true),
		"interacción completa registra semilla",
	)
	_comprobar(SuenoPopolWuj.puede_entrar(jornada), "la semilla común habilita la familia")
	_comprobar(
		SemillasOniricas.familias_activas(jornada),
		["popol_wuj"],
		"Popol Wuj participa en catálogo común",
	)
	var entrada: Dictionary = SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_popol_wuj"]
	_comprobar(entrada["fuentes"], ["libro:popol_wuj_98"], "la procedencia es estable")
	_comprobar(entrada["intensidad"], 2, "intensidad declarada conservada")
	jornada["dia"] = 9
	_comprobar(not SuenoPopolWuj.puede_entrar(jornada), "la semilla no cruza de jornada")


func _probar_vigilia_deliberada() -> void:
	var jornada := {"dia": 3}
	var libro := PopolWujVigilia.new()
	get_root().add_child(libro)
	libro.configurar(jornada)
	_comprobar(not libro.esta_activada(), "el libro presente no activa solo")
	libro.examinar()
	_comprobar(libro.inspecciones(), 1, "primera página cuenta")
	_comprobar(not libro.esta_activada(), "primera página no activa")
	libro.examinar()
	_comprobar(libro.inspecciones(), 2, "segunda página completa lectura mínima")
	_comprobar(not libro.pareja_comparada(), "leer no equivale a comparar")
	_comprobar(not libro.esta_activada(), "dos inspecciones aún no activan")
	libro.examinar()
	_comprobar(libro.pareja_comparada(), "tercera interacción compara la pareja visual")
	_comprobar(libro.esta_activada(), "comparar la pareja activa semilla")
	var intensidad := int(
		SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_popol_wuj"]["intensidad"]
	)
	libro.examinar()
	_comprobar(
		SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_popol_wuj"]["intensidad"],
		intensidad,
		"misma fuente es idempotente",
	)
	libro.queue_free()


func _probar_parejas_eco_y_equivalencia() -> void:
	var sueno := SuenoPopolWuj.new()
	get_root().add_child(sueno)
	sueno.preparar()
	_comprobar(
		sueno.pareja_de(SuenoPopolWuj.ARCHIVO_OESTE),
		SuenoPopolWuj.ARCHIVO_ESTE,
		"archivadores forman pareja",
	)
	_comprobar(
		sueno.pareja_de(SuenoPopolWuj.TELEFONO_OESTE),
		SuenoPopolWuj.TELEFONO_ESTE,
		"teléfonos forman segunda pareja",
	)
	_comprobar(sueno.get_node_or_null("EcosCausales") != null, "los ecos tienen representación física")
	_comprobar(
		sueno.get_node("EcosCausales").get_child_count(),
		2,
		"hay al menos dos pares espaciales legibles",
	)
	_comprobar(not sueno.puerta_abierta(), "la puerta empieza cerrada por equivalencia")

	var inicial := sueno.estado_reproducible()
	var primer_eco := sueno.intervenir(SuenoPopolWuj.ARCHIVO_OESTE)
	_comprobar(primer_eco["ok"], "intervención válida")
	_comprobar(
		primer_eco["eco_destino"],
		SuenoPopolWuj.ARCHIVO_ESTE,
		"acción en un lado produce eco en el otro",
	)
	_comprobar(primer_eco["eco_util"], "el eco forma parte de la regla, no es decorativo")
	_comprobar(
		primer_eco["estado_origen"],
		wrapi(int(inicial[SuenoPopolWuj.ARCHIVO_OESTE]) + 1, 0, 3),
		"el origen avanza un estado",
	)
	_comprobar(
		primer_eco["estado_eco"],
		wrapi(int(inicial[SuenoPopolWuj.ARCHIVO_ESTE]) + 2, 0, 3),
		"la pareja responde con una variación útil",
	)
	_comprobar(not primer_eco["equivalencias"]["archivadores"], "un eco no fuerza éxito automático")

	var segundo_eco := sueno.intervenir(SuenoPopolWuj.ARCHIVO_OESTE)
	_comprobar(segundo_eco["equivalencias"]["archivadores"], "archivadores pueden quedar equivalentes")
	_comprobar(not segundo_eco["puerta_abierta"], "una sola pareja resuelta no abre la puerta")

	sueno.intervenir(SuenoPopolWuj.TELEFONO_OESTE)
	var telefonos_resueltos := sueno.intervenir(SuenoPopolWuj.TELEFONO_OESTE)
	_comprobar(
		telefonos_resueltos["equivalencias"]["telefonos"],
		"teléfonos también se resuelven por equivalencia",
	)
	_comprobar(telefonos_resueltos["puerta_abierta"], "dos equivalencias abren la puerta")
	_comprobar(telefonos_resueltos["retorno_disponible"], "resolver nunca elimina retorno")

	var invalida := sueno.intervenir("elemento_inexistente")
	_comprobar(not invalida["ok"], "elemento desconocido se rechaza sin mutar")
	_comprobar(invalida["retorno_disponible"], "error tampoco elimina retorno")
	sueno.queue_free()


func _probar_accesibilidad_y_reproduccion() -> void:
	var normal := SuenoPopolWuj.new()
	get_root().add_child(normal)
	normal.preparar()
	var salida_normal := normal.intervenir(SuenoPopolWuj.ARCHIVO_OESTE, false)
	_comprobar(salida_normal["modo"], "eco_breve", "presentación normal usa eco breve")
	_comprobar(salida_normal["duracion"], 0.24, "eco normal está acotado")
	_comprobar(not salida_normal["desplazar_camara"], "la mecánica nunca fuerza cámara")
	_comprobar(salida_normal["eco_visual"], "feedback visual siempre presente")
	_comprobar(salida_normal["eco_sonoro"], "feedback sonoro acompaña sin ser único")

	var reducida := SuenoPopolWuj.new()
	get_root().add_child(reducida)
	reducida.preparar()
	var salida_reducida := reducida.intervenir(SuenoPopolWuj.ARCHIVO_OESTE, true)
	_comprobar(salida_reducida["modo"], "corte_fundido", "movimiento reducido usa corte/fundido")
	_comprobar(salida_reducida["duracion"], 0.0, "movimiento reducido no interpola")
	_comprobar(salida_reducida["eco_visual"], "reducción conserva señal visual")
	_comprobar(salida_reducida["eco_sonoro"], "reducción conserva señal redundante")
	_comprobar(
		reducida.estado_reproducible(),
		normal.estado_reproducible(),
		"accesibilidad no cambia la causalidad",
	)

	var guardado := reducida.estado_reproducible()
	var copia := SuenoPopolWuj.new()
	get_root().add_child(copia)
	copia.preparar()
	copia.restaurar_estado(guardado)
	_comprobar(copia.estado_reproducible(), guardado, "estado se reproduce exactamente")
	copia.restaurar_estado(
		{
			SuenoPopolWuj.ARCHIVO_OESTE: 99,
			SuenoPopolWuj.ARCHIVO_ESTE: -4,
			SuenoPopolWuj.TELEFONO_OESTE: 1,
			SuenoPopolWuj.TELEFONO_ESTE: 1,
		}
	)
	_comprobar(
		copia.estado_reproducible()[SuenoPopolWuj.ARCHIVO_OESTE],
		2,
		"restauración acota máximo",
	)
	_comprobar(
		copia.estado_reproducible()[SuenoPopolWuj.ARCHIVO_ESTE],
		0,
		"restauración acota mínimo",
	)
	_comprobar(copia.ruta_retorno_disponible(), "estado extremo mantiene retorno")
	normal.queue_free()
	reducida.queue_free()
	copia.queue_free()


func _comprobar(actual, esperado = true, nombre: String = "") -> void:
	if typeof(esperado) == TYPE_STRING and nombre.is_empty():
		nombre = String(esperado)
		esperado = true
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Popol Wuj: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
