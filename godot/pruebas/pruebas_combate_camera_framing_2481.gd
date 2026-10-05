## Regresión headless de framing multiblanco (#2481).
extends SceneTree

const FRAMING = preload("res://guion/juicio_combate_camera_framing.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_sin_objetivos()
	_probar_un_objetivo()
	_probar_varios_objetivos()
	_probar_orden_invariante()
	_probar_zoom_creciente()
	_probar_zoom_capado()
	_probar_determinismo()
	print("combate_camera_framing_2481: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_sin_objetivos() -> void:
	var resultado := FRAMING.calcular(Vector3(1.0, 3.0, 2.0), [])
	_comprobar(resultado["centro"] == Vector3(1.0, 0.0, 2.0), "sin objetivos centra en jugador")
	_comprobar(int(resultado["cantidad_objetivos"]) == 0, "sin objetivos reporta cero")


func _probar_un_objetivo() -> void:
	var resultado := FRAMING.calcular(Vector3.ZERO, [Vector3(0.0, 0.0, 4.0)])
	_comprobar(resultado["centro"] == Vector3(0.0, 0.0, 2.0), "un objetivo usa punto medio")
	_comprobar(
		is_equal_approx(float(resultado["distancia_camara"]), FRAMING.DISTANCIA_BASE),
		"duelo 1v1 conserva distancia base",
	)
	_comprobar(int(resultado["cantidad_objetivos"]) == 1, "cuenta un objetivo")


func _probar_varios_objetivos() -> void:
	var resultado := _calcular(
		[
			Vector3(-2.0, 0.0, 3.0),
			Vector3(2.0, 0.0, 3.0),
			Vector3(0.0, 0.0, 4.0),
		]
	)
	_comprobar(int(resultado["cantidad_objetivos"]) == 3, "admite tres objetivos")
	_comprobar(float(resultado["radio"]) > 0.0, "grupo múltiple produce radio")


func _probar_orden_invariante() -> void:
	var a := [Vector3(-2.0, 0.0, 3.0), Vector3(2.0, 0.0, 3.0)]
	var b := [Vector3(2.0, 0.0, 3.0), Vector3(-2.0, 0.0, 3.0)]
	var primero := FRAMING.calcular(Vector3.ZERO, a)
	var segundo := FRAMING.calcular(Vector3.ZERO, b)
	_comprobar(primero == segundo, "reordenar objetivos no cambia framing")


func _probar_zoom_creciente() -> void:
	var estrecho := FRAMING.calcular(Vector3.ZERO, [Vector3(0.0, 0.0, 1.0)])
	var ancho := _calcular([Vector3(-3.0, 0.0, 3.0), Vector3(3.0, 0.0, 3.0)])
	_comprobar(
		float(ancho["distancia_camara"]) > float(estrecho["distancia_camara"]),
		"grupo más ancho aleja cámara",
	)


func _probar_zoom_capado() -> void:
	var resultado := _calcular([Vector3(-20.0, 0.0, 20.0), Vector3(20.0, 0.0, 20.0)])
	_comprobar(
		float(resultado["distancia_camara"]) <= FRAMING.DISTANCIA_MAX,
		"zoom no supera máximo duro",
	)


func _probar_determinismo() -> void:
	var objetivos := [Vector3(-1.0, 0.0, 2.0), Vector3(1.0, 0.0, 2.0)]
	var a := FRAMING.calcular(Vector3.ZERO, objetivos)
	var b := FRAMING.calcular(Vector3.ZERO, objetivos)
	_comprobar(a == b, "mismo conjunto produce misma salida")


func _calcular(objetivos: Array) -> Dictionary:
	return FRAMING.calcular(Vector3.ZERO, objetivos)


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if not condicion:
		_fallos += 1
		push_error("FALLO #2481 camera framing: " + mensaje)
