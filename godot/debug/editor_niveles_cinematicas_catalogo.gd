## Controles de catálogo exclusivos del editor de cinemáticas.
extends RefCounted

const CONTRATO := preload("res://debug/editor_niveles_cinematicas_contrato.gd")
const ESPACIOS_CATALOGO := preload("res://guion/espacios_catalogo.gd")
const MODELOS := preload("res://guion/modelos.gd")


static func selector_escenario(texto: TextEdit, estado: Label) -> Dictionary:
	var fila := HBoxContainer.new()
	var selector := OptionButton.new()
	for fase in ESPACIOS_CATALOGO.POR_FASE.keys():
		selector.add_item(String(fase))
	fila.add_child(selector)
	var boton := Button.new()
	boton.text = "Cargar escenario"
	boton.pressed.connect(
		func():
			var fase := selector.get_item_text(selector.selected)
			var escenario := CONTRATO.escenario_catalogado_json(fase)
			if escenario.is_empty():
				estado.text = "El catálogo no contiene el escenario '%s'" % fase
				return
			texto.text = JSON.stringify(escenario, "  ")
			estado.text = "Escenario '%s' preparado; pulsa Aplicar para usarlo en el plano" % fase
	)
	fila.add_child(boton)
	return {"fila": fila, "selector": selector}


static func biblioteca_decorado(texto: TextEdit, estado: Label) -> Dictionary:
	var fila := HBoxContainer.new()
	var selector := OptionButton.new()
	var muebles: Array = MODELOS.MATERIALES_MUEBLE.keys()
	muebles.sort()
	for modelo in muebles:
		if MODELOS.hay(String(modelo)):
			selector.add_item(String(modelo))
	if selector.item_count == 0:
		selector.add_item("No hay modelos disponibles")
		selector.disabled = true
	fila.add_child(selector)
	var boton := Button.new()
	boton.text = "Añadir al decorado"
	boton.disabled = selector.disabled
	boton.pressed.connect(
		func():
			var recurso := selector.get_item_text(selector.selected)
			var resultado := CONTRATO.agregar_mueble_a_decorado(texto.text, recurso)
			if not String(resultado.get("error", "")).is_empty():
				estado.text = resultado["error"]
				return
			texto.text = JSON.stringify(resultado["decorado"], "  ")
			estado.text = "Objeto añadido al decorado; pulsa Aplicar para previsualizarlo"
	)
	fila.add_child(boton)
	return {"fila": fila, "selector": selector}
