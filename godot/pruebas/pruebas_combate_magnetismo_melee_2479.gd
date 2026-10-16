## Regresión headless de magnetismo melee (#2479).
extends SceneTree

const MAGNETISMO = preload("res://guion/juicio_combate_magnetismo_melee.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_hueco_pequeno()
	_probar_dentro_de_alcance()
	_probar_demasiado_lejos()
	_probar_bloqueo()
	_probar_tope_duro()
	_probar_no_sobrepasar()
	_probar_plano_horizontal()
	_probar_determinismo()
	print("combate_magnetismo_melee_2479: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_hueco_pequeno() -> void:
	var resultado := _calcular(Vector3(0.0, 0.0, 2.2), 2.0, 0.30)
	_comprobar(bool(resultado["aplicar"]), "hueco pequeño activa asistencia")
	_comprobar(
		is_equal_approx(float(resultado["distancia_restante"]), 2.0),
		"asistencia deja al jugador justo en alcance",
	)


func _probar_dentro_de_alcance() -> void:
	var resultado := _calcular(Vector3(0.0, 0.0, 1.8), 2.0, 0.30)
	_comprobar(not bool(resultado["aplicar"]), "dentro de alcance no mueve")


func _probar_demasiado_lejos() -> void:
	var resultado := _calcular(Vector3(0.0, 0.0, 2.5), 2.0, 0.30)
	_comprobar(not bool(resultado["aplicar"]), "fuera del margen no mueve")


func _probar_bloqueo() -> void:
	var resultado := _calcular(Vector3(0.0, 0.0, 2.2), 2.0, 0.30, false)
	_comprobar(not bool(resultado["aplicar"]), "línea bloqueada desactiva asistencia")


func _probar_tope_duro() -> void:
	var resultado := _calcular(Vector3(0.0, 0.0, 2.44), 2.0, 1.0)
	_comprobar(bool(resultado["aplicar"]), "margen externo se capa al máximo")
	_comprobar(
		float(resultado["desplazamiento"].length()) <= MAGNETISMO.MAX_DESPLAZAMIENTO,
		"desplazamiento nunca supera 0.45 m",
	)


func _probar_no_sobrepasar() -> void:
	var resultado := _calcular(Vector3(0.0, 0.0, 0.25), 0.0, 0.45)
	_comprobar(bool(resultado["aplicar"]), "alcance cero permite corrección limitada")
	_comprobar(
		float(resultado["desplazamiento"].length()) <= 0.25,
		"asistencia nunca cruza al otro lado del objetivo",
	)


func _probar_plano_horizontal() -> void:
	var resultado := _calcular(Vector3(0.0, 4.0, 2.2), 2.0, 0.30)
	var desplazamiento: Vector3 = resultado["desplazamiento"]
	_comprobar(is_zero_approx(desplazamiento.y), "asistencia ignora eje vertical")


func _probar_determinismo() -> void:
	var a := MAGNETISMO.calcular(Vector3.ZERO, Vector3(0.2, 0.0, 2.1), 2.0, 0.30)
	var b := MAGNETISMO.calcular(Vector3.ZERO, Vector3(0.2, 0.0, 2.1), 2.0, 0.30)
	_comprobar(a == b, "mismo input produce misma salida")


func _calcular(
	objetivo: Vector3,
	alcance: float,
	margen: float,
	linea_libre: bool = true,
) -> Dictionary:
	return MAGNETISMO.calcular(Vector3.ZERO, objetivo, alcance, margen, linea_libre)


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if not condicion:
		_fallos += 1
		push_error("FALLO #2479 magnetismo melee: " + mensaje)
