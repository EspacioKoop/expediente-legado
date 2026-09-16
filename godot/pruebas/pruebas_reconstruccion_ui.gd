extends SceneTree

const CASO := {
	"id": "caso_ui_155",
	"registros":
	[
		{"id": "doc_a", "tipo": "informe", "folio": "1", "fecha": "1998-01-01"},
		{"id": "doc_b", "tipo": "oficio", "folio": "2", "fecha": "1998-01-02"},
	]
}

var _pasadas := 0
var _fallos := 0
var _guardados := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	var panel: Control = load("res://escenas/reconstruccion_expediente.tscn").instantiate()
	panel.caso = CASO
	panel.estado = Partida.nueva()
	panel.visibles = ["doc_a", "doc_b"]
	panel.guardar = Callable(self, "_guardar_prueba")
	root.add_child(panel)
	await process_frame

	_comprobar(panel._orden == ["doc_a", "doc_b"], "parte del orden del catálogo")
	_comprobar(panel._botones_tarjeta.size() == 2, "crea una tarjeta por documento visible")
	_comprobar("ORDEN COMPATIBLE" in panel._estado.text, "explica el estado compatible")

	panel._indice_mover = 1
	panel._mover_seleccion(-1)
	await process_frame
	_comprobar(panel._orden == ["doc_b", "doc_a"], "reordena la tarjeta seleccionada")
	_comprobar("CONTRADICCIÓN" in panel._estado.text, "muestra la contradicción sin afirmar verdad")

	panel._mover_seleccion(1)
	await process_frame
	panel._validar_y_guardar()
	_comprobar(_guardados == 1, "persiste al mejorar el resultado")
	var mejor := ReconstruccionExpediente.mejor_guardado(panel.estado, CASO["id"])
	_comprobar(mejor.get("orden", []) == ["doc_a", "doc_b"], "guarda el mejor orden")
	_comprobar(int(mejor.get("puntuacion", 0)) == 100, "guarda la coherencia calculada")

	panel.queue_free()
	await process_frame
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _guardar_prueba() -> bool:
	_guardados += 1
	return true


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO ReconstruccionUI: " + nombre)
