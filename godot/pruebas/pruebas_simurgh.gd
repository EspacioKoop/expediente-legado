extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_gate_y_semilla()
	_probar_vigilia_deliberada()
	_probar_capas_y_accesibilidad()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_gate_y_semilla() -> void:
	var jornada := {"dia": 6}
	_comprobar(not SuenoSimurgh.puede_entrar(jornada), "sin semilla Simurgh no entra")
	_comprobar(
		not SuenoSimurgh.registrar_semilla(jornada, 1, true),
		"una inspección no basta aunque se gire la lámina",
	)
	_comprobar(
		not SuenoSimurgh.registrar_semilla(jornada, 2, false),
		"dos inspecciones sin giro no bastan",
	)
	_comprobar(
		SuenoSimurgh.registrar_semilla(jornada, 2, true),
		"inspección completa registra la semilla",
	)
	_comprobar(SuenoSimurgh.puede_entrar(jornada), "la semilla común habilita la familia")
	_comprobar(
		SemillasOniricas.familias_activas(jornada),
		["simurgh"],
		"Simurgh participa en el catálogo común",
	)
	var entrada: Dictionary = SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_simurgh"]
	_comprobar(entrada["fuentes"], ["lamina:simurgh_98"], "la procedencia queda estable")
	jornada["dia"] = 7
	_comprobar(not SuenoSimurgh.puede_entrar(jornada), "la semilla no cruza de jornada")


func _probar_vigilia_deliberada() -> void:
	var jornada := {"dia": 3}
	var lamina := SimurghVigilia.new()
	get_root().add_child(lamina)
	lamina.configurar(jornada)
	_comprobar(not lamina.esta_activada(), "la lámina presente no activa por sí sola")
	lamina.examinar()
	_comprobar(lamina.inspecciones(), 1, "primera inspección cuenta")
	_comprobar(not lamina.esta_activada(), "primera inspección no activa")
	lamina.examinar()
	_comprobar(lamina.inspecciones(), 2, "segunda inspección completa observación")
	_comprobar(not lamina.esta_girada(), "observar no equivale a girar")
	_comprobar(not lamina.esta_activada(), "dos observaciones siguen sin activar")
	lamina.examinar()
	_comprobar(lamina.esta_girada(), "tercera interacción gira la lámina")
	_comprobar(lamina.esta_activada(), "giro deliberado activa la semilla")
	var intensidad := int(
		SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_simurgh"]["intensidad"]
	)
	lamina.examinar()
	_comprobar(
		SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_simurgh"]["intensidad"],
		intensidad,
		"repetir la misma fuente es idempotente",
	)
	lamina.queue_free()


func _probar_capas_y_accesibilidad() -> void:
	var sueno := SuenoSimurgh.new()
	get_root().add_child(sueno)
	sueno.preparar()
	_comprobar(sueno.capa_actual(), "escritorio", "empieza en escala doméstica")
	_comprobar(
		sueno.get_node_or_null("CapaEscritorio/Pluma") != null,
		"la pluma existe como objeto pequeño",
	)
	_comprobar(
		sueno.get_node_or_null("CapaMonumental/PasarelaPluma") != null,
		"la misma ancla existe como arquitectura transitable",
	)
	_comprobar(
		sueno.get_node_or_null("CapaMonumental/NidoLuminaria") != null,
		"la luminaria se reinterpreta como nido",
	)
	_comprobar(sueno.ruta_retorno_disponible(), "ambas capas conservan retorno")

	var punto_escritorio := sueno.get_node_or_null("CapaEscritorio/PuntoCambio") as Interactuable3D
	var punto_monumental := sueno.get_node_or_null("CapaMonumental/PuntoCambio") as Interactuable3D
	_comprobar(punto_escritorio != null, "la pluma expone interacción 3D común")
	_comprobar(punto_monumental != null, "la pasarela expone interacción 3D común")
	_comprobar(punto_escritorio.collision_layer > 0, "solo la capa visible es interactuable")
	_comprobar(punto_monumental.collision_layer, 0, "la capa oculta no queda en el raycast")

	var normal := sueno.cambiar_capa(false)
	_comprobar(normal["capa"], "monumental", "el cambio revela la escala monumental")
	_comprobar(not normal["zoom_camara"], "el cambio no usa zoom obligatorio")
	_comprobar(not normal["mover_camara"], "el cambio no desplaza cámara")
	_comprobar(not normal["escalar_jugador"], "el jugador nunca se interpola de tamaño")
	_comprobar(normal["retorno_disponible"], "el retorno sobrevive al cambio")
	_comprobar(
		punto_escritorio.collision_layer, 0, "el hotspot doméstico se desactiva al ocultarse"
	)
	_comprobar(punto_monumental.collision_layer > 0, "el hotspot monumental pasa a estar activo")

	sueno.reduccion_movimiento = true
	var reducida := sueno.cambiar_capa(false)
	_comprobar(reducida["capa"], "escritorio", "la capa reducida vuelve al escritorio")
	_comprobar(reducida["modo"], "corte_fundido", "movimiento reducido usa corte/fundido")
	_comprobar(reducida["duracion"], 0.0, "movimiento reducido no interpola")
	_comprobar(
		SuenoSimurgh.equivalencias()[SuenoSimurgh.ANCLA_PLUMA]["monumental"],
		"PasarelaPluma",
		"la equivalencia de la pluma es declarada y estable",
	)
	sueno.queue_free()


func _comprobar(actual, esperado = true, nombre: String = "") -> void:
	if typeof(esperado) == TYPE_STRING and nombre.is_empty():
		nombre = String(esperado)
		esperado = true
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Simurgh: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
