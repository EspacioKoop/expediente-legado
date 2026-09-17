## Vertical slice de fachadas vivas (#861): profundidad, variantes, LOD y luz.
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
		CalleFachadasVivas.montar(calle) == vivas, "el montaje de fachadas vivas es idempotente"
	)
	_comprobar(
		vivas.get_child_count() == CalleFachadasVivas.MAX_VENTANAS,
		"la vertical slice limita el número de ventanas"
	)

	var pisos := calle.get_node("PisosFachada")
	var variantes := {}
	var estados_luz := {}
	var props := {"Escritorio": false, "Estanteria": false, "Sofa": false}
	var indice := 0
	for interior in vivas.get_children():
		var variante := String(interior.get_meta("variante"))
		variantes[variante] = int(variantes.get(variante, 0)) + 1
		var estado_luz := String(interior.get_meta("estado_luz"))
		estados_luz[estado_luz] = int(estados_luz.get(estado_luz, 0)) + 1
		_comprobar(
			estado_luz == CalleFachadasVivas.ESTADOS_LUZ[indice % CalleFachadasVivas.ESTADOS_LUZ.size()],
			"el estado de luz es determinista"
		)
		var nombre_ventana := String(interior.get_meta("ventana"))
		_comprobar(
			nombre_ventana.begins_with(CalleFachadasVivas.PREFIJO_TRAMO),
			"solo se decora el tramo elegido"
		)
		var ventana := pisos.get_node_or_null(nombre_ventana) as MeshInstance3D
		_comprobar(ventana != null, "la ventana decorada sigue existiendo")
		if ventana == null:
			indice += 1
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
			_comprobar(
				is_equal_approx(fondo.visibility_range_end, CalleFachadasVivas.LOD_LEJOS_FIN),
				"el fondo sobrevive hasta el LOD lejano"
			)
		for marco in ["MarcoSuperior", "MarcoInferior", "MarcoIzquierdo", "MarcoDerecho"]:
			var pieza_marco := interior.get_node_or_null(marco) as MeshInstance3D
			_comprobar(pieza_marco != null, "marco con volumen: " + marco)
			if pieza_marco != null:
				_comprobar(
					is_equal_approx(
						pieza_marco.visibility_range_end, CalleFachadasVivas.LOD_MEDIA_FIN
					),
					"el marco usa LOD medio: " + marco
				)
		for prop in props:
			var pieza_prop := interior.get_node_or_null(prop) as MeshInstance3D
			if pieza_prop != null:
				props[prop] = true
				_comprobar(
					is_equal_approx(
						pieza_prop.visibility_range_end, CalleFachadasVivas.LOD_CERCA_FIN
					),
					"el mobiliario 3D se limita al LOD cercano: " + prop
				)
		if estado_luz == "persiana":
			var persiana := interior.get_node_or_null("Persiana") as MeshInstance3D
			_comprobar(persiana != null, "el estado persiana añade detalle a una ventana apagada")
			if persiana != null:
				_comprobar(
					is_equal_approx(
						persiana.visibility_range_end, CalleFachadasVivas.LOD_MEDIA_FIN
					),
					"la persiana se conserva hasta el LOD medio"
				)
		indice += 1

	_comprobar(variantes.size() == 3, "hay tres composiciones interiores")
	for variante in CalleFachadasVivas.VARIANTES:
		_comprobar(int(variantes.get(variante, 0)) == 3, "variante equilibrada: " + variante)
	_comprobar(
		estados_luz.size() == CalleFachadasVivas.ESTADOS_LUZ.size(),
		"la slice contiene todos los estados de luz"
	)
	for estado_luz in CalleFachadasVivas.ESTADOS_LUZ:
		_comprobar(estados_luz.has(estado_luz), "aparece el estado de luz " + estado_luz)
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
