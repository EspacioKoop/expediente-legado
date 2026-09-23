## Smoke aislado del vertical nocturno del Minotauro (#437).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	var minotauro := SuenoMinotauro3D.new()
	minotauro.reduccion_movimiento = true
	root.add_child(minotauro)
	minotauro.preparar()

	var arquitectura := minotauro.get_node_or_null("LaberintoMinotauro")
	_comprobar(arquitectura != null, "laberinto 3D montado")
	if arquitectura == null:
		_finalizar(minotauro)
		return

	_comprobar(
		arquitectura.get_node_or_null("AlaReplegable") != null,
		"ala topológica visible",
	)
	_comprobar(
		arquitectura.get_node_or_null("PresenciaMinotauro/Cabeza") != null,
		"presencia procedural visible",
	)
	_comprobar(
		arquitectura.get_node_or_null("AnclaAriadna_bisagra") != null,
		"ancla de Ariadna interactuable",
	)
	_comprobar(
		arquitectura.get_node_or_null("HiloAriadna") != null,
		"hilo de Ariadna tiene contenedor propio",
	)
	var luz := arquitectura.get_node_or_null("LuzArchivo") as OmniLight3D
	_comprobar(luz != null, "luz de archivo disponible")
	var energia_lejana := luz.light_energy if luz != null else 0.0
	var alcance_lejano := luz.omni_range if luz != null else 0.0

	_comprobar(
		minotauro.marcar_y_cruzar(SuenoMinotauro.CRUCE_NORTE),
		"primera marca fija un cruce estable",
	)
	if luz != null:
		_comprobar(luz.light_energy > energia_lejana, "respiración aumenta energía de luz")
		_comprobar(luz.omni_range > alcance_lejano, "respiración amplía alcance de luz")
	_comprobar(
		arquitectura.get_node_or_null("HiloAriadna/Tramo00") != null,
		"primera marca despliega un tramo continuo desde la entrada",
	)

	_comprobar(
		minotauro.marcar_y_cruzar(SuenoMinotauro.BISAGRA),
		"segunda marca cruza la bisagra",
	)
	var estado_1 := minotauro.estado()
	_comprobar(int(estado_1.get("fase_topologica", -1)) == 1, "repliegue determinista")
	_comprobar(
		minotauro.presentacion_transformacion() == "fundido_discreto",
		"reducción de movimiento usa transición discreta",
	)
	_comprobar(
		arquitectura.get_node_or_null("Hilo_bisagra") != null,
		"marca de Ariadna visible",
	)

	_comprobar(
		minotauro.marcar_y_cruzar(SuenoMinotauro.CENTRO),
		"tercera marca cruza el centro",
	)
	var estado_2 := minotauro.estado()
	var bloqueo := String(estado_2.get("bloqueo", ""))
	_comprobar(String(estado_2.get("presencia", "")) == "cerca", "presencia reacciona")
	if luz != null:
		_comprobar(
			is_equal_approx(luz.light_energy, 4.2),
			"presencia cercana refuerza iluminación",
		)
		_comprobar(
			is_equal_approx(luz.omni_range, 16.0),
			"presencia cercana alcanza más laberinto",
		)
		_comprobar(luz.light_color.r > luz.light_color.g, "presencia cercana calienta la luz")

	var marca_norte := arquitectura.get_node_or_null("Hilo_cruce_norte") as MeshInstance3D
	var nudo_norte := (
		arquitectura.get_node_or_null("HiloAriadna/NudoReal_cruce_norte") as MeshInstance3D
	)
	_comprobar(marca_norte != null and nudo_norte != null, "marca y nudo real permanecen visibles")
	if marca_norte != null and nudo_norte != null:
		_comprobar(
			marca_norte.position.distance_to(nudo_norte.position) > 1.0,
			"el repliegue separa marca aparente e hilo real de forma legible",
		)
	var hilo := arquitectura.get_node_or_null("HiloAriadna")
	_comprobar(hilo != null and hilo.get_child_count() == 6, "tres nudos y tres tramos de hilo")

	_comprobar(
		SuenoMinotauro.hay_ruta(SuenoMinotauro.CENTRO, SuenoMinotauro.SALIDA, bloqueo),
		"bloqueo conserva ruta recuperable",
	)

	_finalizar(minotauro)


func _finalizar(minotauro: Node) -> void:
	if is_instance_valid(minotauro):
		minotauro.queue_free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO Minotauro: " + nombre)
