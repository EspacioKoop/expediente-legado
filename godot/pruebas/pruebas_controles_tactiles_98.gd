## Regresión pura del overlay táctil de acciones (#98).
extends SceneTree

const ControlesTactiles = preload("res://guion/dia_controles_tactiles_app.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_visibilidad()
	_probar_eventos_semanticos()
	print("controles_tactiles_98: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_visibilidad() -> void:
	_comprobar(
		ControlesTactiles.debe_mostrar_overlay(true, true, false, false, false),
		"touch + gameplay activo muestra overlay",
	)
	for caso in [
		[false, true, false, false, false, "sin touchscreen"],
		[true, false, false, false, false, "fisica detenida"],
		[true, true, true, false, false, "arbol pausado"],
		[true, true, false, true, false, "pantalla modal"],
		[true, true, false, false, true, "entrada/cinematica"],
	]:
		_comprobar(
			not ControlesTactiles.debe_mostrar_overlay(
				bool(caso[0]),
				bool(caso[1]),
				bool(caso[2]),
				bool(caso[3]),
				bool(caso[4]),
			),
			String(caso[5]) + " oculta overlay",
		)


func _probar_eventos_semanticos() -> void:
	for accion in [&"interactuar", &"cancelar"]:
		var pulsar := ControlesTactiles.evento_accion(accion, true)
		_comprobar(pulsar is InputEventAction, "%s produce InputEventAction" % accion)
		_comprobar(pulsar.action == accion, "%s conserva accion semantica" % accion)
		_comprobar(pulsar.pressed, "%s produce pulsacion" % accion)
		_comprobar(is_equal_approx(pulsar.strength, 1.0), "%s fuerza pulsada completa" % accion)

		var soltar := ControlesTactiles.evento_accion(accion, false)
		_comprobar(soltar.action == accion, "%s conserva accion al soltar" % accion)
		_comprobar(not soltar.pressed, "%s produce liberacion" % accion)
		_comprobar(is_zero_approx(soltar.strength), "%s libera fuerza" % accion)


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error("FALLO #98 tactil: " + mensaje)
