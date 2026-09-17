## Vertical slice de fachadas vivas (#861): profundidad, variantes y props.
extends SceneTree

const DIA := preload("res://escenas/dia.tscn")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	if OS.get_environment("LEGADO_PRUEBAS_AISLADAS") != "1":
		printerr("Ejecuta esta prueba desde unittest con datos aislados.")
		quit(1)
		return
	_probar.call_deferred()


func _probar() -> void:
	var dia = DIA.instantiate()
	root.add_child(dia)
	await process_frame
	dia._entrar_en("trayecto")
	await process_frame

	var calle := dia._mundo.get_node_or_null("CalleIdentidad") as Node3D
	_comprobar(calle != null, "la calle existe")
	if calle == null:
		_terminar(dia)
		return

	var vivas := calle.get_node_or_null("FachadasVivas") as Node3D
	_comprobar(vivas != null, "se monta FachadasVivas")
	if vivas == null:
		_terminar(dia)
		return

	_comprobar(
		CalleFachadasVivas.montar(calle) == vivas,
		"el montaje de fachadas vivas es idempotente"
	)
	_comprobar(
		vivas.get_child_count() == CalleFachadasVivas.MAX_VENTANAS,
		"la vertical slice limita el número de ventanas"
	)

	var pisos := calle.get_node("PisosFachada")
	var variantes := {}
	var props := {"Escritorio": false, "Estanteria": false, "Sofa": false}
	for interior in vivas.get_children():
		var variante := String(interior.get_meta("variante"))
		variantes[variante] = int(variantes.get(variante, 0)) + 1
		var nombre_ventana := String(interior.get_meta("ventana"))
		_comprobar(
			nombre_ventana.begins_with(CalleFachadasVivas.PREFIJO_TRAMO),
			"solo se decora el tramo elegido"
		)
		var ventana := pisos.get_node_or_null(nombre_ventana) as MeshInstance3D
		_comprobar(ventana != null, "la ventana decorada sigue existiendo")
		if ventana == null:
			continue
		var material := ventana.material_override as StandardMaterial3D
		_comprobar(material != null, "la ventana decorada usa cristal compartido")
		if material != null:
			_comprobar(
				material.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA,
				"el cristal deja ver el interior"
			)

		var fondo := interior.get_node_or_null("Fondo") as MeshInstance3D
		_comprobar(fondo != null, "cada ventana tiene fondo interior")
		if fondo != null:
			_comprobar(
				absf(ventana.position.x - fondo.position.x) >= 0.05,
				"hay profundidad visible entre cristal y fondo"
			)
		for marco in ["MarcoSuperior", "MarcoInferior", "MarcoIzquierdo", "MarcoDerecho"]:
			_comprobar(interior.get_node_or_null(marco) != null, "marco con volumen: " + marco)
		for prop in props:
			if interior.get_node_or_null(prop) != null:
				props[prop] = true

	_comprobar(variantes.size() == 3, "hay tres composiciones interiores")
	for variante in CalleFachadasVivas.VARIANTES:
		_comprobar(int(variantes.get(variante, 0)) == 3, "variante equilibrada: " + variante)
	for prop in props:
		_comprobar(props[prop], "aparece el prop 3D " + prop)

	_terminar(dia)


func _terminar(dia) -> void:
	dia.queue_free()
	await process_frame
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO FachadasVivas: " + nombre)
