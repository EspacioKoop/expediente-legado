## Fachadas vivas (#861): cobertura completa, profundidad, LOD, luz y batching.
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
	var interiores := vivas.get_node_or_null("Interiores") as Node3D
	var lotes := vivas.get_node_or_null("Lotes") as Node3D
	_comprobar(interiores != null, "existe el contenedor lógico de interiores")
	_comprobar(lotes != null, "existe el contenedor de lotes MultiMesh")
	if interiores == null or lotes == null:
		_terminar(dia)
		return

	var pisos := calle.get_node("PisosFachada")
	var ventanas_altas := 0
	for hijo in pisos.get_children():
		if hijo is MeshInstance3D and String(hijo.name).begins_with(CalleFachadasVivas.PREFIJO_VENTANA):
			ventanas_altas += 1
	_comprobar(ventanas_altas == 61, "la calle declara 61 ventanas altas")
	_comprobar(
		interiores.get_child_count() == ventanas_altas,
		"todas las ventanas altas reciben profundidad aparente"
	)
	_comprobar(
		int(vivas.get_meta("ventanas_decoradas")) == ventanas_altas,
		"el montaje registra toda la cobertura"
	)
	_comprobar(
		int(vivas.get_meta("ventanas_detalle_3d")) == CalleFachadasVivas.MAX_VENTANAS_DETALLE,
		"solo nueve ventanas mantienen mobiliario 3D"
	)
	_comprobar(lotes.get_child_count() <= 17, "la cobertura completa conserva máximo 17 lotes")

	var variantes := {}
	var estados_luz := {}
	var props := {"Escritorio": false, "Estanteria": false, "Sofa": false}
	var indice := 0
	var detalle_3d := 0
	var piezas_esperadas := 0
	for interior in interiores.get_children():
		var variante := String(interior.get_meta("variante"))
		variantes[variante] = int(variantes.get(variante, 0)) + 1
		var estado_luz := String(interior.get_meta("estado_luz"))
		estados_luz[estado_luz] = int(estados_luz.get(estado_luz, 0)) + 1
		_comprobar(
			(
				estado_luz
				== CalleFachadasVivas.ESTADOS_LUZ[indice % CalleFachadasVivas.ESTADOS_LUZ.size()]
			),
			"el estado de luz es determinista"
		)
		var nombre_ventana := String(interior.get_meta("ventana"))
		_comprobar(
			nombre_ventana.begins_with(CalleFachadasVivas.PREFIJO_VENTANA),
			"solo se decoran ventanas altas"
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
		var fondo_x := float(interior.get_meta("fondo_x"))
		_comprobar(
			absf(ventana.position.x - fondo_x) >= 0.05,
			"hay profundidad visible entre cristal y fondo"
		)
		_comprobar(
			bool(interior.get_meta("marco_volumen")), "cada ventana conserva marco con volumen"
		)

		var es_detalle := bool(interior.get_meta("detalle_3d"))
		var nombres_props := interior.get_meta("props") as Array
		if es_detalle:
			detalle_3d += 1
			_comprobar(
				nombre_ventana.begins_with(CalleFachadasVivas.PREFIJO_TRAMO_DETALLE),
				"el mobiliario 3D queda en el tramo de detalle"
			)
			_comprobar(not nombres_props.is_empty(), "una ventana de detalle conserva props")
		else:
			_comprobar(nombres_props.is_empty(), "las ventanas escaladas no añaden props 3D")
		for prop in props:
			if nombres_props.has(prop):
				props[prop] = true

		piezas_esperadas += 5 + nombres_props.size()
		if estado_luz == "persiana":
			piezas_esperadas += 1
			_comprobar(
				bool(interior.get_meta("tiene_persiana")),
				"el estado persiana añade detalle a una ventana apagada"
			)
		indice += 1

	var instancias := 0
	var lotes_cerca := 0
	var lotes_media := 0
	var lotes_lejos := 0
	for hijo in lotes.get_children():
		var lote := hijo as MultiMeshInstance3D
		_comprobar(lote != null, "cada lote visual es MultiMeshInstance3D")
		if lote == null or lote.multimesh == null:
			continue
		instancias += lote.multimesh.instance_count
		if is_equal_approx(lote.visibility_range_end, CalleFachadasVivas.LOD_CERCA_FIN):
			lotes_cerca += 1
		elif is_equal_approx(lote.visibility_range_end, CalleFachadasVivas.LOD_MEDIA_FIN):
			lotes_media += 1
		elif is_equal_approx(lote.visibility_range_end, CalleFachadasVivas.LOD_LEJOS_FIN):
			lotes_lejos += 1
		else:
			_comprobar(false, "cada lote conserva uno de los tres rangos LOD")

	_comprobar(detalle_3d == 9, "hay nueve ventanas de detalle 3D")
	_comprobar(instancias == piezas_esperadas, "el batching conserva todas las piezas declaradas")
	_comprobar(instancias == 353, "la cobertura completa usa 353 instancias batcheadas")
	_comprobar(
		int(vivas.get_meta("instancias_batcheadas")) == instancias,
		"el montaje registra el total real de instancias"
	)
	_comprobar(lotes_cerca == 9, "los nueve tipos de props usan LOD cercano")
	_comprobar(lotes_media == 3, "marcos y persiana usan tres lotes de LOD medio")
	_comprobar(lotes_lejos == 5, "los cinco estados de fondo usan LOD lejano")
	_comprobar(
		interiores.find_children("*", "MeshInstance3D", true, false).is_empty(),
		"los grupos por ventana no crean draw calls individuales"
	)

	_comprobar(variantes.size() == 3, "hay tres composiciones interiores deterministas")
	for variante in CalleFachadasVivas.VARIANTES:
		_comprobar(variantes.has(variante), "aparece la variante " + variante)
	_comprobar(
		estados_luz.size() == CalleFachadasVivas.ESTADOS_LUZ.size(),
		"la calle contiene todos los estados de luz"
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
