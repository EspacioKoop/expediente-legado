extends SceneTree

## Regresión de #787: las interacciones obligatorias del gato no conocen el
## dispositivo físico. Teclado, ratón y mando producen la misma acción
## semántica `interactuar`, y el estado contextual del gato decide después si
## eso significa acariciar, coger, llamar o dar de comer.

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _probar() -> void:
	PreferenciasSiga.aplicar(PreferenciasSiga.nuevas())

	var teclado := InputEventKey.new()
	teclado.physical_keycode = KEY_E
	teclado.pressed = true

	var raton := InputEventMouseButton.new()
	raton.button_index = MOUSE_BUTTON_LEFT
	raton.pressed = true

	var mando := InputEventJoypadButton.new()
	mando.button_index = JOY_BUTTON_A
	mando.pressed = true

	_probar_dispositivo("teclado", teclado)
	_probar_dispositivo("ratón", raton)
	_probar_dispositivo("mando", mando)

	var detector := FileAccess.get_file_as_string("res://guion/detector_interaccion_3d.gd")
	_comprobar(
		detector.contains('evento.is_action_pressed("interactuar")'),
		"el detector común consume la acción semántica y no una tecla concreta",
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_dispositivo(nombre: String, evento: InputEvent) -> void:
	_comprobar(
		evento.is_action_pressed("interactuar"),
		"%s activa la acción interactuar" % nombre,
	)
	if not evento.is_action_pressed("interactuar"):
		return

	var gato := Gato.new()
	gato.empezar(Vector3.ZERO, [Vector3.ZERO])

	# Cerca: primero acariciar, luego coger. Ambos pasos atraviesan exactamente
	# la misma acción física; el contexto vive en Gato, no en el mapa de input.
	gato.interactuar(null)
	_comprobar(
		String(gato.estado.get("estado", "")) == "mimos",
		"%s permite acariciar" % nombre,
	)
	_comprobar(
		gato.texto_accion() == "Coger gato",
		"%s deja disponible coger tras acariciar" % nombre,
	)

	gato.interactuar(null)
	_comprobar(
		gato.texto_accion() == "Acariciar gato",
		"%s permite coger y volver al contacto" % nombre,
	)

	# Lejos: la misma entrada llama al gato.
	var actor := Node3D.new()
	actor.position = Vector3(2.0, 0.0, 0.0)
	gato.interactuar(actor)
	_comprobar(
		(
			String(gato.estado.get("estado", "")) == "viene"
			and gato.estado.get("destino", Vector3.ZERO) == Vector3(2.0, 0.0, 0.0)
		),
		"%s permite llamar" % nombre,
	)

	# Con hambre y cerca: la misma entrada solicita DAR. El cobro y persistencia
	# siguen siendo autoridad de Jornada, cubiertos por las regresiones previas.
	actor.position = Vector3.ZERO
	gato.actualizar_hambre(2)
	gato.interactuar(actor)
	_comprobar(
		gato.verbo == Interactuable3D.Verbo.DAR,
		"%s permite pedir alimentación directa" % nombre,
	)

	actor.free()
	gato.free()


func _comprobar(actual: bool, nombre: String) -> void:
	if actual:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO controles gato #787: %s" % nombre)
