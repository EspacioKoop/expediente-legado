extends SceneTree

const ESCENA: PackedScene = preload("res://escenas/minijuego_aviones_papel.tscn")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var app = ESCENA.instantiate()
	root.add_child(app)
	await process_frame

	var antes: Dictionary = app.estado.duplicate(true)
	var previo: Dictionary = app._vuelo_previo()
	_comprobar(not previo.is_empty(), "el turno inicial ofrece una previsión")
	var esperado := AvionesPapel.simular(
		app.MODELOS[app.modelo.selected],
		float(app.direccion.value),
		float(app.altura.value),
		float(app.potencia.value),
	)
	_comprobar(
		previo.get("posicion", Vector3.INF) == esperado.get("posicion", Vector3.ZERO),
		"la previsión reutiliza exactamente el simulador canónico",
	)
	_comprobar(app.estado == antes, "previsualizar no consume lanzamiento ni muta estado")

	var posicion_inicial: Vector3 = previo.get("posicion", Vector3.ZERO)
	app.direccion.value = 0.75
	await process_frame
	var lateral := app._vuelo_previo()
	_comprobar(
		not lateral.is_empty() and lateral.get("posicion", Vector3.ZERO) != posicion_inicial,
		"cambiar dirección actualiza el punto previsto",
	)
	_comprobar(app.estado == antes, "ajustar la previsión sigue sin tocar la ronda")

	app._vuelo_en_curso = true
	_comprobar(app._vuelo_previo().is_empty(), "la previsión se oculta durante el vuelo")
	app._vuelo_en_curso = false
	app.estado["turno"] = 1
	_comprobar(app._vuelo_previo().is_empty(), "la previsión no aparece en turno ajeno")

	app.queue_free()
	await process_frame
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO AvionesPapelPreview160: " + nombre)
