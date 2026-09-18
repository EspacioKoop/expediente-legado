extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	# El preflight debe ser inocuo incluso cuando los seis GLB existan: una
	# escena sin anclas nunca puede quedar parcialmente vestida.
	var vacio := Node3D.new()
	root.add_child(vacio)
	var hijos_vacio := vacio.get_child_count()
	_comprobar(not OficinaStylooCc0.montar(vacio), "preflight rechaza mundo sin anclas")
	_comprobar(
		vacio.get_child_count() == hijos_vacio,
		"preflight no deja nodos parciales en un mundo inválido"
	)
	_comprobar(
		not vacio.has_meta("oficina_styloo_cc0"),
		"preflight fallido no marca el mundo como vestido"
	)
	vacio.queue_free()

	TranslationServer.set_locale("es")
	var dia: Node = load("res://escenas/dia.tscn").instantiate()
	root.add_child(dia)
	for frame in 8:
		await process_frame
	var mundo: Node3D = dia._mundo
	var disponible := OficinaStylooCc0.disponible()
	var importados_antes := mundo.find_children("AssetCc0", "Node3D", true, false).size()
	var colisiones_antes := mundo.find_children("*", "CollisionShape3D", true, false).size()

	_comprobar(mundo.has_meta("oficina_assets_cc0"), "fallback CC0 de oficina sigue montado")
	_comprobar(importados_antes >= 25, "la oficina conserva sus visuales CC0 actuales")
	if disponible:
		_comprobar(
			mundo.has_meta("oficina_styloo_cc0"),
			"con lote completo Styloo entra durante el montaje normal"
		)
	else:
		_comprobar(
			not mundo.has_meta("oficina_styloo_cc0"),
			"sin lote completo Styloo no altera ni marca la oficina"
		)

	var resultado := OficinaStylooCc0.montar(mundo)
	_comprobar(resultado == disponible, "segunda llamada refleja disponibilidad del lote")
	_comprobar(
		mundo.find_children("AssetCc0", "Node3D", true, false).size() == importados_antes,
		"segunda llamada es idempotente"
	)
	_comprobar(
		mundo.find_children("*", "CollisionShape3D", true, false).size() == colisiones_antes,
		"Styloo no añade ni retira colisiones"
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	dia.queue_free()
	await process_frame
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO OficinaStylooCc0: " + nombre)
