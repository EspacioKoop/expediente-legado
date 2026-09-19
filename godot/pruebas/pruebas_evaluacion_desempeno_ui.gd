## Regresión headless del historial visual de evaluaciones (#150).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	# Los runners aislados no pasan por Inicio; fijamos el catálogo igual que los demás smokes UI.
	TranslationServer.set_locale("es")
	var estado := {
		"evaluaciones_desempeno": [
			{
				"vuelta": 1,
				"motivo": "reasignacion",
				"veredictos_total": 3,
				"evaluacion": {
					"productividad": EvaluacionDesempeno.MEDIA,
					"precipitacion": EvaluacionDesempeno.ALTA,
					"cuidado_gato": EvaluacionDesempeno.ALTA,
					"liquidez": EvaluacionDesempeno.BAJA,
					"exploracion_onirica": EvaluacionDesempeno.MEDIA,
				},
			},
			{
				"vuelta": 2,
				"motivo": "final_narrativo",
				"veredictos_total": 8,
				"evaluacion": {
					"productividad": EvaluacionDesempeno.ALTA,
					"precipitacion": EvaluacionDesempeno.BAJA,
					"cuidado_gato": EvaluacionDesempeno.MEDIA,
					"liquidez": EvaluacionDesempeno.ALTA,
					"exploracion_onirica": EvaluacionDesempeno.ALTA,
				},
			},
		]
	}
	var antes := JSON.stringify(estado)

	var vista := EvaluacionDesempenoSiga.new()
	vista.configurar_estado(estado)
	root.add_child(vista)
	await process_frame

	var lista := vista.find_child("Vidas", true, false) as ItemList
	_comprobar(lista != null, "la vista crea el índice de vidas")
	_comprobar(lista.item_count == 2, "muestra las dos vidas selladas")
	_comprobar(
		lista.get_selected_items() == PackedInt32Array([0]), "selecciona la vida más reciente"
	)
	_comprobar(lista.get_item_text(0).contains("2"), "la vida más reciente aparece primero")
	_comprobar(
		(vista.find_child("VidaSeleccionada", true, false) as Label).text.contains("2"),
		"el detalle corresponde a la vida seleccionada",
	)
	_comprobar(
		(vista.find_child("MotivoCierre", true, false) as Label).text.to_lower().contains(
			"narrativo"
		),
		"el detalle explica el motivo del cierre",
	)
	_comprobar(
		(
			(vista.find_child("Rango_productividad", true, false) as Label).text
			== tr("EVALUACION_RANGO_ALTA")
		),
		"muestra la productividad sellada",
	)
	_comprobar(
		(
			(vista.find_child("Rango_precipitacion", true, false) as Label).text
			== tr("EVALUACION_RANGO_BAJA")
		),
		"muestra la precipitación sellada",
	)
	_comprobar(
		(
			(vista.find_child("Rango_cuidado_gato", true, false) as Label).text
			== tr("EVALUACION_RANGO_MEDIA")
		),
		"muestra el cuidado del gato sellado",
	)
	_comprobar(JSON.stringify(estado) == antes, "consultar el historial no modifica Partida")

	vista.queue_free()
	await process_frame

	var vacia := EvaluacionDesempenoSiga.new()
	vacia.configurar_estado({})
	root.add_child(vacia)
	await process_frame
	var lista_vacia := vacia.find_child("Vidas", true, false) as ItemList
	_comprobar(lista_vacia.item_count == 1, "sin historial muestra una única fila informativa")
	_comprobar(lista_vacia.is_item_disabled(0), "la fila vacía no finge una vida seleccionable")

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
