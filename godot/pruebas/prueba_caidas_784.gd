## Regresión ejecutable del playtest #784.
##
## Cubre los tres fallos observados en el mismo runtime que juega `dia.tscn`:
## todas las salas oníricas tienen suelo bajo su entrada, una caída profunda
## vuelve a la entrada y la salida oficina→trayecto permite remontar la oficina
## sin volver a introducir la salida accidental por proximidad corregida en #790.
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	TranslationServer.set_locale("es")
	await _probar_suelos_sueno()
	await _probar_rescate_y_reentrada()
	# La prueba crea mundos físicos y una escena completa. Darles varios ciclos
	# de proceso antes de cerrar evita confundir recursos pendientes de liberar
	# con un fallo funcional del contrato que se acaba de comprobar.
	for frame in 3:
		await process_frame
		await physics_frame
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

		root.remove_child(mundo)
		mundo.free()
		await process_frame
		await physics_frame


func _probar_rescate_y_reentrada() -> void:
	var dia: Variant = load("res://escenas/dia.tscn").instantiate()
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
		# #790 invalida el gesto antiguo de esta regresión: colocarse sobre el
		# Area3D ya no puede cambiar de fase. Se conserva el mismo umbral para
		# comprobar reentrada, pero el tránsito exige puerta + confirmación.
		dia._caminante.global_position = salida.global_position
		for frame in 3:
			await physics_frame
			await process_frame
		_comprobar(
			dia.jornada["fase"] == "archivo",
			"pisar la salida de oficina ya no cambia de fase",
		)
		_comprobar(not salida.monitoring, "el umbral automático queda desactivado")

		var puerta: Interactuable3D = dia._puerta_salida_oficina
		_comprobar(puerta != null, "la reentrada conserva la puerta interactuable")
		if puerta != null:
			puerta.interactuar(dia._caminante)
			var confirmar: ConfirmationDialog = dia._confirmacion_salida
			_comprobar(confirmar != null, "la puerta pide confirmación")
			if confirmar != null:
				confirmar.emit_signal("confirmed")
			_comprobar(
				dia.jornada["fase"] == "trayecto",
				"confirmar la salida física entra al trayecto",
			)

	# Reentrada explícita en oficina tras haber desmontado el exterior. Además de
	# cubrir el caso informado, deja que Godot procese un ciclo completo de baja
	# y alta de Areas antes de comprobar que el mundo nuevo sigue siendo válido.
	dia._entrar_en("archivo")
	await process_frame
	await physics_frame
	_comprobar(dia.jornada["fase"] == "archivo", "se puede volver a la oficina")
	_comprobar(is_instance_valid(dia._mundo), "la oficina remontada conserva mundo")

	# #813 añadió un `_process` para el rescate. En Godot 4 ese callback sustituye
	# al heredado si no llama a `super`, lo que congelaría reloj del sueño, pasos
	# y avance del gato. Verificarlo en runtime evita una falsa solución del P0.
	_probar_process_heredado(dia)

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

	salida = null
	root.remove_child(dia)
	dia.free()
	dia = null
	for frame in 3:
		await process_frame
		await physics_frame


func _probar_process_heredado(dia: Variant) -> void:
	var fase_antes := String(dia.jornada.get("fase", "archivo"))
	var resto_antes := float(dia.jornada.get("sueno_resto", 0.0))
	var total_antes := float(dia.jornada.get("sueno_total", 0.0))
	dia.jornada["fase"] = "sueño"
	dia.jornada["sueno_total"] = 10.0
	dia.jornada["sueno_resto"] = 10.0
	dia._process(0.25)
	_comprobar(
		is_equal_approx(float(dia.jornada["sueno_resto"]), 9.75),
		"el rescate conserva el _process base y el reloj del sueño",
	)
	dia.jornada["fase"] = fase_antes
	dia.jornada["sueno_total"] = total_antes
	dia.jornada["sueno_resto"] = resto_antes


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
