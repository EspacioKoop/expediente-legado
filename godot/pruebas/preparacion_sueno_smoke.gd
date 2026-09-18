## Smoke de la preparación de sueño #162: foco, 3 huecos, repetición y salida.
extends SceneTree

var pasadas := 0
var fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var panel := PreparacionSueno.new()
	panel.configurar(["A", "B"], ["B"])
	root.add_child(panel)
	await process_frame
	await process_frame

	comprobar(panel.seleccion_actual() == ["B"], "recupera selección persistida")
	for i in 3:
		comprobar(
			panel.find_child("Hueco%d" % (i + 1), true, false) is Button,
			"existe hueco %d" % (i + 1),
		)

	var documento_a := panel.find_child("Documento0", true, false) as Button
	var confirmar := panel.find_child("Confirmar", true, false) as Button
	var cancelar := panel.find_child("Cancelar", true, false) as Button
	comprobar(documento_a != null, "lista solo documentos leídos")
	comprobar(confirmar != null and cancelar != null, "confirmar y cancelar existen")
	comprobar(root.gui_get_focus_owner() is Button, "la pantalla entrega foco")

	documento_a.pressed.emit()
	documento_a.pressed.emit()
	comprobar(panel.seleccion_actual() == ["B", "A", "A"], "un folio puede repetirse")
	documento_a.pressed.emit()
	comprobar(panel.seleccion_actual().size() == 3, "nunca supera tres huecos")

	var hueco_uno := panel.find_child("Hueco1", true, false) as Button
	hueco_uno.pressed.emit()
	comprobar(panel.seleccion_actual() == ["A", "A"], "pulsar hueco retira esa memoria")

	var recibidas := []
	panel.confirmada.connect(func(seleccion: Array): recibidas.append(seleccion))
	confirmar.pressed.emit()
	comprobar(recibidas == [["A", "A"]], "confirmar devuelve la selección visible")

	var cancelaciones := []
	panel.cancelada.connect(func(): cancelaciones.append(true))
	var evento := InputEventAction.new()
	evento.action = "ui_cancel"
	evento.pressed = true
	panel._unhandled_input(evento)
	comprobar(cancelaciones.size() == 1, "ui_cancel cubre Esc/B")

	panel.queue_free()
	await process_frame
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos else 0)


func comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		pasadas += 1
		return
	fallos += 1
	push_error("FALLO preparación sueño #162: " + mensaje)
