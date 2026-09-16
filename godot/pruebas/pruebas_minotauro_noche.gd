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
		minotauro.marcar_y_cruzar(SuenoMinotauro.BISAGRA),
		"primera marca cruza la bisagra",
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
		"segunda marca cruza el centro",
	)
	var estado_2 := minotauro.estado()
	var bloqueo := String(estado_2.get("bloqueo", ""))
	_comprobar(String(estado_2.get("presencia", "")) == "cruce", "presencia reacciona")
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
