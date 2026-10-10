## Regresión de la pantalla «Créditos» del menú de inicio (#2530).
##
## La pantalla existe para que ninguna atribución dependa de ver la apertura:
## por eso se comprueba nombre a nombre contra la fuente canónica, y no solo
## que haya «bastantes» etiquetas.
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	TranslationServer.set_locale("es")
	await _probar_pantalla()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_pantalla() -> void:
	var pantalla := PantallaCreditos.new()
	root.add_child(pantalla)

	var etiquetas := pantalla.find_children("*", "Label", true, false)

	var bloques := CreditosInicio.bloques_completos()
	var entradas_esperadas := 0
	var titulos_esperados := 0
	for b in bloques:
		if not (b is Dictionary):
			continue
		var entradas: Array = b.get("entradas", [])
		if entradas.is_empty():
			continue
		titulos_esperados += 1
		entradas_esperadas += entradas.size()

	# +1 por CREDITOS_TITULO
	var total_esperado = 1 + titulos_esperados + entradas_esperadas

	_comprobar(
		etiquetas.size() == total_esperado,
		"hay un label por entrada, títulos de bloque y título principal"
	)
	_comprobar(titulos_esperados > 0, "aparecen los títulos de los bloques")
	_comprobar(entradas_esperadas > 0, "hay un label por cada entrada")

	var textos := etiquetas.map(func(e: Label) -> String: return e.text)
	var todo := "\n".join(PackedStringArray(textos))
	for b in bloques:
		for entrada in b.get("entradas", []):
			var nombre := String(entrada.get("nombre", ""))
			_comprobar(nombre.is_empty() or todo.contains(nombre), "aparece «%s»" % nombre)
			var licencia := String(entrada.get("licencia", ""))
			if not licencia.is_empty():
				_comprobar(todo.contains(licencia), "con su licencia %s" % licencia)

	await process_frame
	var boton := pantalla.find_children("*", "Button", true, false)
	_comprobar(boton.size() == 1 and boton[0].has_focus(), "«Cerrar» toma el foco al abrir")

	for accion in ["ui_cancel", "cancelar"]:
		var cerrada := [false]
		var conexion := func(): cerrada[0] = true
		pantalla.cerrada.connect(conexion)
		var evento := InputEventAction.new()
		evento.action = accion
		evento.pressed = true
		pantalla._input(evento)
		_comprobar(cerrada[0], "%s cierra la pantalla" % accion)
		pantalla.cerrada.disconnect(conexion)

	pantalla.free()


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		print("FALLO: " + mensaje)
