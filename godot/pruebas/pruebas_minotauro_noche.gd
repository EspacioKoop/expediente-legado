## Smoke aislado del vertical nocturno del Minotauro (#437).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	var minotauro := SuenoMinotauro3D.new()
	minotauro.reduccion_movimiento = true
	minotauro.preparar()
	root.add_child(minotauro)

	var arquitectura := minotauro.get_node_or_null("ArquitecturaMinotauro")
	_comprobar(arquitectura != null, "arquitectura montada")
	if arquitectura == null:
		_finalizar(minotauro, null)
		return

	var corredores := arquitectura.get_node_or_null("Corredores")
	_comprobar(corredores != null, "red de corredores montada")
	if corredores != null:
		_comprobar(corredores.get_child_count() > 20, "laberinto no reticular materializado")
	_comprobar(
		arquitectura.get_node_or_null("PresenciaMinotauro/Cabeza") != null,
		"presencia del Minotauro visible",
	)
	_comprobar(
		arquitectura.get_node_or_null("RepliegueTopologico/Ala_archivo_este") != null,
		"ala topologica visible",
	)

	var actor := Node.new()
	actor.name = "ActorPrueba"
	root.add_child(actor)
	var marca := (
		arquitectura.get_node_or_null("AnclajesAriadna/Marca_archivo_este") as Interactuable3D
	)
	var bisagra := arquitectura.get_node_or_null("BisagraTopologica") as Interactuable3D
	_comprobar(marca != null and bisagra != null, "interacciones espaciales disponibles")
	if marca != null and bisagra != null:
		_comprobar(marca.interactuar(actor), "se puede dejar una marca deliberada")
		_comprobar(minotauro.cantidad_marcas_visibles() == 1, "marca visible materializada")
		_comprobar(minotauro.lectura_marca(0).get("lectura", "") == "estable", "marca estable")

		_comprobar(bisagra.interactuar(actor), "se puede cruzar la bisagra")
		_comprobar(
			int(minotauro.estado_topologico().get("fase_topologica", -1)) == 1,
			"primer repliegue topologico",
		)
		_comprobar(
			minotauro.lectura_marca(0).get("lectura", "") == "desplazada",
			"Ariadna delata el intercambio aparente",
		)

		_comprobar(bisagra.interactuar(actor), "segundo cruce reproducible")
		_comprobar(minotauro.presencia_actual() == "cruce", "presencia escala sin combate")
		_comprobar(minotauro.ruta_recuperable(), "el bloqueo conserva una ruta a salida")

	_finalizar(minotauro, actor)


func _finalizar(minotauro: Node, actor: Node) -> void:
	if is_instance_valid(actor):
		actor.queue_free()
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
