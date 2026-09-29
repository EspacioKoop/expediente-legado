extends SceneTree

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_sin_herramienta()
	_probar_estabilizar_por_metadata()
	_probar_alias_calzar_y_no_consumo()
	_probar_home_storage_no_cuenta()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_sin_herramienta() -> void:
	var inventario := Inventario.nuevo()
	var ventana := _ventana(inventario)
	_comprobar(not ventana.interactuar(ventana), "sin herramienta falla cerrado")
	_comprobar(not ventana.esta_estabilizada(), "sin herramienta sigue floja")
	_comprobar(
		String(ventana.get_meta("ultimo_resultado", "")) == "falta_herramienta",
		"deja feedback semántico",
	)
	ventana.queue_free()


func _probar_estabilizar_por_metadata() -> void:
	var inventario := Inventario.nuevo()
	var herramienta := _herramienta("sargento-prueba", "Sargento de prueba", ["estabilizar"])
	_comprobar(Inventario.recoger(inventario, herramienta), "prepara herramienta estabilizadora")
	var ventana := _ventana(inventario)
	_comprobar(ventana.interactuar(ventana), "estabilizar funciona por metadata")
	_comprobar(ventana.esta_estabilizada(), "la hoja queda estable")
	_comprobar(
		String(ventana.get_meta("herramienta_usada", "")) == "sargento-prueba",
		"registra la herramienta elegida sin conocer su id de antemano",
	)
	_comprobar(inventario[Inventario.CARRIED].size() == 1, "el uso no consume herramienta")
	ventana.queue_free()


func _probar_alias_calzar_y_no_consumo() -> void:
	var inventario := Inventario.nuevo()
	var alternativa := _herramienta("cuna-prueba", "Cuña de prueba", ["calzar"])
	_comprobar(Inventario.recoger(inventario, alternativa), "prepara segundo objeto compatible")
	var ventana := _ventana(inventario)
	_comprobar(ventana.interactuar(ventana), "calzar resuelve el mismo uso canónico")
	_comprobar(ventana.esta_estabilizada(), "otro objeto con el mismo uso también sirve")
	_comprobar(
		String(inventario[Inventario.CARRIED][0].get("id", "")) == "cuna-prueba",
		"el objeto alternativo sigue en carried",
	)
	ventana.queue_free()


func _probar_home_storage_no_cuenta() -> void:
	var inventario := Inventario.nuevo()
	inventario[Inventario.HOME_STORAGE].append(
		_herramienta("guardada", "Herramienta guardada", ["estabilizar"])
	)
	var ventana := _ventana(inventario)
	_comprobar(
		ventana.herramienta_disponible().is_empty(), "home_storage no resuelve fuera de casa"
	)
	_comprobar(not ventana.interactuar(ventana), "una herramienta guardada no se teletransporta")
	ventana.queue_free()


func _ventana(inventario: Dictionary) -> VentanaFlojaOficina1773:
	var ventana := VentanaFlojaOficina1773.new()
	get_root().add_child(ventana)
	ventana.configurar(inventario)
	return ventana


func _herramienta(id: String, nombre: String, usos: Array) -> Dictionary:
	return {
		"id": id,
		"nombre": nombre,
		"categoria": "herramienta",
		"usos": usos,
		"vendible": false,
		"origen": "prueba",
	}


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error(mensaje)
