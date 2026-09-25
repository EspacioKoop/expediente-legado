extends Node

const Controller = preload("res://guion/dia_climax_os98_app.gd")

var _fallos: Array[String] = []


func _ready() -> void:
	var mundo := Node3D.new()
	var archivador := Node3D.new()
	archivador.name = "ArchivadorPrueba"
	mundo.add_child(archivador)
	var rotulo := Label3D.new()
	rotulo.name = "DestinoArchivado"
	rotulo.text = "ARCHIVO CENTRAL"
	archivador.add_child(rotulo)

	var controller := Controller.new()
	var contexto := {
		"efecto_texto":
		{
			"activo": true,
			"intensidad": 0.88,
			"duracion": 1.0,
			"semilla": "fase-climax",
		},
	}

	controller._sincronizar_rotulos_3d(mundo, contexto, false, 0.75)
	_comprobar(rotulo.text != "ARCHIVO CENTRAL", "rótulo 3D jugable se corrompe")
	var visual := rotulo.text
	controller._sincronizar_rotulos_3d(mundo, contexto, false, 0.0)
	_comprobar(rotulo.text == visual, "mismo estado temporal conserva salida")

	controller._sincronizar_rotulos_3d(mundo, contexto, true, 0.1)
	_comprobar(rotulo.text == "ARCHIVO CENTRAL", "reducción de movimiento restaura rótulo")

	rotulo.text = "ARCHIVO B"
	controller._sincronizar_rotulos_3d(mundo, contexto, false, 0.75)
	_comprobar(rotulo.text != "ARCHIVO B", "cambio externo de destino adopta nueva fuente")
	controller._sincronizar_rotulos_3d(mundo, {"efecto_texto": {"activo": false}}, false, 0.1)
	_comprobar(rotulo.text == "ARCHIVO B", "fase normal restaura destino")

	rotulo.text = "ARCHIVO CRÍTICO"
	rotulo.set_meta("texto_corrupto_critico", true)
	controller._sincronizar_rotulos_3d(mundo, contexto, false, 0.75)
	_comprobar(rotulo.text == "ARCHIVO CRÍTICO", "rótulo crítico conserva legibilidad")

	controller.free()
	mundo.free()
	if _fallos.is_empty():
		print("OK texto corrupto rótulo 3D #806")
		get_tree().quit(0)
	else:
		for fallo in _fallos:
			push_error(fallo)
		get_tree().quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
