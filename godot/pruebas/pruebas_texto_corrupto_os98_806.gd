extends Node

const Controller = preload("res://guion/dia_climax_os98_app.gd")

var _fallos: Array[String] = []


func _ready() -> void:
	var pantalla := Control.new()
	var contenedor := VBoxContainer.new()
	pantalla.add_child(contenedor)
	var visor := RichTextLabel.new()
	visor.name = "VisorDocumento"
	visor.text = "MEMORÁNDUM ENLACE 13 / ACCESO RESTRINGIDO"
	contenedor.add_child(visor)

	var controller := Controller.new()
	var contexto := {
		"efecto_texto": {
			"activo": true,
			"intensidad": 0.88,
			"duracion": 1.0,
			"semilla": "fase-climax",
		},
	}

	controller._sincronizar_documento(pantalla, contexto, false, 0.75)
	_comprobar(visor.text != "MEMORÁNDUM ENLACE 13 / ACCESO RESTRINGIDO", "documento real se corrompe")
	var primer_visual := visor.text
	controller._sincronizar_documento(pantalla, contexto, false, 0.0)
	_comprobar(visor.text == primer_visual, "mismo estado temporal es determinista")

	controller._sincronizar_documento(pantalla, contexto, true, 0.1)
	_comprobar(
		visor.text == "MEMORÁNDUM ENLACE 13 / ACCESO RESTRINGIDO",
		"reducción de movimiento restaura el original",
	)

	visor.text = "SEGUNDO DOCUMENTO"
	controller._sincronizar_documento(pantalla, contexto, false, 0.75)
	_comprobar(visor.text != "SEGUNDO DOCUMENTO", "un refresco externo adopta nuevo texto fuente")
	controller._sincronizar_documento(pantalla, {"efecto_texto": {"activo": false}}, false, 0.1)
	_comprobar(visor.text == "SEGUNDO DOCUMENTO", "fase normal restaura el segundo documento")

	visor.text = "INFORMACIÓN CRÍTICA"
	visor.set_meta("texto_corrupto_critico", true)
	controller._sincronizar_documento(pantalla, contexto, false, 0.75)
	_comprobar(visor.text == "INFORMACIÓN CRÍTICA", "contenido crítico queda legible")

	controller.free()
	pantalla.free()
	if _fallos.is_empty():
		print("OK texto corrupto OS98 #806")
		get_tree().quit(0)
	else:
		for fallo in _fallos:
			push_error(fallo)
		get_tree().quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
