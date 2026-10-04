extends SceneTree

var pasadas := 0
var fallos := 0


func _initialize() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_comprobar(
		"gameplay activo muestra overlay",
		AccionesTactiles98.debe_mostrarse(true, false, false, true),
	)
	_comprobar(
		"pausa oculta overlay",
		not AccionesTactiles98.debe_mostrarse(true, true, false, true),
	)
	_comprobar(
		"diálogo oculta overlay",
		not AccionesTactiles98.debe_mostrarse(true, false, true, true),
	)
	_comprobar(
		"física desactivada oculta overlay",
		not AccionesTactiles98.debe_mostrarse(false, false, false, true),
	)
	_comprobar(
		"puntero liberado por menú/modal oculta overlay",
		not AccionesTactiles98.debe_mostrarse(true, false, false, false),
	)

	var host := Node.new()
	root.add_child(host)
	var overlay := AccionesTactiles98.new()
	host.add_child(overlay)
	await process_frame

	var interactuar := overlay.get_node_or_null("Interactuar") as TouchScreenButton
	var cancelar := overlay.get_node_or_null("Cancelar") as TouchScreenButton
	_comprobar("existe botón táctil interactuar", interactuar != null)
	_comprobar("existe botón táctil cancelar", cancelar != null)
	if interactuar != null:
		_comprobar("interactuar usa acción semántica", interactuar.action == "interactuar")
		_comprobar(
			"interactuar solo se dibuja en táctil",
			interactuar.visibility_mode == TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY,
		)
		_comprobar("interactuar tiene área táctil", interactuar.shape is CircleShape2D)
	if cancelar != null:
		_comprobar("cancelar usa acción semántica", cancelar.action == "cancelar")
		_comprobar(
			"cancelar solo se dibuja en táctil",
			cancelar.visibility_mode == TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY,
		)
		_comprobar("cancelar tiene área táctil", cancelar.shape is CircleShape2D)

	host.queue_free()
	await process_frame
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _comprobar(nombre: String, condicion: bool) -> void:
	if condicion:
		pasadas += 1
		print("OK: ", nombre)
	else:
		fallos += 1
		printerr("FALLO: ", nombre)
