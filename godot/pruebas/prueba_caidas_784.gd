## Regresión ejecutable del playtest #784.
##
## Cubre los tres fallos observados en el mismo runtime que juega `dia.tscn`:
## todas las salas oníricas tienen suelo bajo su entrada, una caída profunda
## vuelve a la entrada y la salida física oficina→trayecto permite remontar la
## oficina sin liberar Areas durante el callback de física.
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	TranslationServer.set_locale("es")
	await _probar_suelos_sueno()
	await _probar_rescate_y_reentrada()
	if _fallos == 0:
		print("Caídas #784: OK")
		quit(0)
		return
	push_error("Caídas #784: %d fallos" % _fallos)
	quit(1)


func _probar_suelos_sueno() -> void:
	for id in SuenoFormas.ids():
		var mundo := Node3D.new()
		root.add_child(mundo)
		var espacio := Sueno.espacio(String(id), 0)
		Espacio3D.construir(mundo, espacio)
		await physics_frame
		await process_frame

		var entrada: Vector3 = espacio["entrada"]
		var consulta := PhysicsRayQueryParameters3D.create(
			entrada + Vector3(0.0, 1.6, 0.0), entrada + Vector3(0.0, -2.0, 0.0)
		)
		var golpe := mundo.get_world_3d().direct_space_state.intersect_ray(consulta)
		_comprobar(not golpe.is_empty(), "hay suelo bajo la entrada de %s" % id)
		if not golpe.is_empty():
			_comprobar(
				absf(float(golpe["position"].y)) <= 0.15,
				"el suelo de %s está a cota jugable" % id,
			)

		mundo.queue_free()
		await process_frame
		await physics_frame


func _probar_rescate_y_reentrada() -> void:
	var dia := load("res://escenas/dia.tscn").instantiate()
	root.add_child(dia)
	for frame in 8:
		await process_frame
	await physics_frame

	# Fuerza la oficina para que la prueba no dependa del progreso persistente
	# que pueda existir en user:// durante un playtest o una ejecución local.
	dia._entrar_en("archivo")
	await process_frame
	await physics_frame
	var salida := _buscar_salida(dia._mundo, "trayecto")
	_comprobar(salida != null, "la oficina conserva su salida al trayecto")
	if salida != null:
		# Esto dispara `body_entered` desde el servidor de física: es la ruta que
		# antes desmontaba `_mundo` dentro del callback y provocaba _body_exit_tree.
		dia._caminante.global_position = salida.global_position
		for frame in 3:
			await physics_frame
			await process_frame
		_comprobar(dia.jornada["fase"] == "trayecto", "la salida física entra al trayecto")

	# Reentrada explícita en oficina tras haber desmontado el exterior. Además de
	# cubrir el caso informado, deja que Godot procese un ciclo completo de baja
	# y alta de Areas antes de comprobar que el mundo nuevo sigue siendo válido.
	dia._entrar_en("archivo")
	await process_frame
	await physics_frame
	_comprobar(dia.jornada["fase"] == "archivo", "se puede volver a la oficina")
	_comprobar(is_instance_valid(dia._mundo), "la oficina remontada conserva mundo")

	var entrada: Vector3 = dia._espacio_actual["entrada"]
	dia._caminante.position = Vector3(entrada.x, -20.0, entrada.z)
	dia._caminante.velocity = Vector3(1.0, -30.0, 1.0)
	dia._rescatar_caida()
	_comprobar(
		dia._caminante.position.is_equal_approx(entrada + Vector3(0.0, 1.0, 0.0)),
		"una caída profunda vuelve a la entrada actual",
	)
	_comprobar(
		dia._caminante.velocity.length() <= 0.001, "el rescate cancela la velocidad de caída"
	)

	dia.queue_free()
	await process_frame
	await physics_frame


func _buscar_salida(nodo: Node, destino: String) -> Area3D:
	for hijo in nodo.get_children():
		if hijo is Area3D and String(hijo.get_meta("destino", "")) == destino:
			return hijo
		var encontrada := _buscar_salida(hijo, destino)
		if encontrada != null:
			return encontrada
	return null


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO #784: " + nombre)
