## Controles de efectos opt-in que CinematicaApp ya consume.
extends RefCounted


static func montar(padre: Control, plano: Dictionary, indice_plano: int) -> Dictionary:
	padre.add_child(_etiqueta("Efectos de imagen (opcionales):"))
	var interrupcion_crt := CheckButton.new()
	interrupcion_crt.text = "Interrupción CRT"
	interrupcion_crt.button_pressed = bool(plano.get("interrupcion_crt", false))
	padre.add_child(interrupcion_crt)

	var grid_crt := GridContainer.new()
	grid_crt.columns = 4
	padre.add_child(grid_crt)
	var semilla := maxi(0, indice_plano)
	var crt_intensidad := _spin(
		grid_crt, "CRT intensidad:", float(plano.get("crt_intensidad", 0.6)), 0, 1, 0.01
	)
	var crt_duracion := _spin(
		grid_crt, "CRT duración:", float(plano.get("crt_duracion", 0.15)), 0, 2, 0.01
	)
	var crt_semilla := _spin(
		grid_crt,
		"CRT semilla:",
		float(plano.get("crt_semilla", semilla * 13.7)),
		-10000,
		10000,
		0.1
	)

	var superposicion := _campo(
		padre, "Superposición:", "Texto proyectado en pantalla (vacío = desactivado)"
	)
	superposicion.text = String(plano.get("superposicion_texto", ""))
	var grid_superposicion := GridContainer.new()
	grid_superposicion.columns = 6
	padre.add_child(grid_superposicion)
	var sup_intensidad := _spin(
		grid_superposicion, "Texto intensidad:", float(plano.get("sup_intensidad", 0.8)), 0, 1, 0.01
	)
	var sup_ruido := _spin(
		grid_superposicion, "Texto ruido:", float(plano.get("sup_ruido", 0.02)), 0, 0.1, 0.001
	)
	var sup_scanline := _spin(
		grid_superposicion, "Texto scanline:", float(plano.get("sup_scanline", 0.3)), 0, 1, 0.01
	)
	var sup_semilla := _spin(
		grid_superposicion,
		"Texto semilla:",
		float(plano.get("sup_semilla", semilla * 7.3)),
		-10000,
		10000,
		0.1
	)

	var grano_sin_estrobo := CheckButton.new()
	grano_sin_estrobo.text = "Grano no estroboscópico (accesibilidad)"
	grano_sin_estrobo.button_pressed = bool(plano.get("grano_no_estroboscopico", false))
	padre.add_child(grano_sin_estrobo)

	return {
		"crt_activo": interrupcion_crt,
		"crt_intensidad": crt_intensidad,
		"crt_duracion": crt_duracion,
		"crt_semilla": crt_semilla,
		"superposicion": superposicion,
		"sup_intensidad": sup_intensidad,
		"sup_ruido": sup_ruido,
		"sup_scanline": sup_scanline,
		"sup_semilla": sup_semilla,
		"grano_sin_estrobo": grano_sin_estrobo,
	}


static func aplicar(plano: Dictionary, controles: Dictionary) -> void:
	var interrupcion_crt: CheckButton = controles["crt_activo"]
	if interrupcion_crt.button_pressed:
		plano["interrupcion_crt"] = true
		plano["crt_intensidad"] = (controles["crt_intensidad"] as SpinBox).value
		plano["crt_duracion"] = (controles["crt_duracion"] as SpinBox).value
		plano["crt_semilla"] = (controles["crt_semilla"] as SpinBox).value

	var superposicion: LineEdit = controles["superposicion"]
	var texto := superposicion.text.strip_edges()
	if not texto.is_empty():
		plano["superposicion_texto"] = texto
		plano["sup_intensidad"] = (controles["sup_intensidad"] as SpinBox).value
		plano["sup_ruido"] = (controles["sup_ruido"] as SpinBox).value
		plano["sup_scanline"] = (controles["sup_scanline"] as SpinBox).value
		plano["sup_semilla"] = (controles["sup_semilla"] as SpinBox).value

	var grano_sin_estrobo: CheckButton = controles["grano_sin_estrobo"]
	if grano_sin_estrobo.button_pressed:
		plano["grano_no_estroboscopico"] = true


static func _campo(padre: Control, rotulo: String, texto_guia: String) -> LineEdit:
	var fila := HBoxContainer.new()
	padre.add_child(fila)
	var etiqueta := _etiqueta(rotulo)
	etiqueta.custom_minimum_size.x = 140
	fila.add_child(etiqueta)
	var campo := LineEdit.new()
	campo.placeholder_text = texto_guia
	campo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(campo)
	return campo


static func _etiqueta(texto: String) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	return etiqueta


static func _spin(
	padre: Control, rotulo: String, valor: float, minimo: float, maximo: float, paso: float
) -> SpinBox:
	var fila := HBoxContainer.new()
	padre.add_child(fila)
	var etiqueta := _etiqueta(rotulo)
	etiqueta.custom_minimum_size.x = 120
	fila.add_child(etiqueta)
	var spin := SpinBox.new()
	spin.min_value = minimo
	spin.max_value = maximo
	spin.step = paso
	spin.value = valor
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(spin)
	return spin
