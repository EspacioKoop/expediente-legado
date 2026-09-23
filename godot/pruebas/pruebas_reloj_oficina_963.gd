extends SceneTree

const Reloj := preload("res://guion/reloj_oficina_3d.gd")
const Horario := preload("res://guion/dia_reloj_horario_app.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	var reloj := Reloj.new()
	root.add_child(reloj)

	reloj.poner_hora(9 * 60)
	_comprobar(
		_aprox_angulo(reloj.get_node("PivoteHora").rotation.z, deg_to_rad(90.0)),
		"las nueve ponen la aguja horaria a la izquierda"
	)
	_comprobar(
		_aprox_angulo(reloj.get_node("PivoteMinuto").rotation.z, 0.0),
		"las nueve dejan minutos en punto"
	)
	_comprobar(int(reloj.get_meta("hora_minutos", -1)) == 9 * 60, "conserva la hora mostrada")

	reloj.poner_hora(14 * 60 + 30)
	_comprobar(
		_aprox_angulo(reloj.get_node("PivoteHora").rotation.z, deg_to_rad(285.0)),
		"las dos y media desplazan también la aguja de hora"
	)
	_comprobar(
		_aprox_angulo(reloj.get_node("PivoteMinuto").rotation.z, deg_to_rad(180.0)),
		"media hora apunta abajo"
	)
	_comprobar(reloj.find_child("Marca11", true, false) != null, "la esfera conserva doce marcas")

	var manana := Horario.perfil_luz(9 * 60)
	var mediodia := Horario.perfil_luz(14 * 60)
	var tarde := Horario.perfil_luz(16 * 60 + 30)
	var noche := Horario.perfil_luz(19 * 60)
	_comprobar(String(manana["franja"]) == "manana", "09:00 usa perfil de mañana")
	_comprobar(String(mediodia["franja"]) == "mediodia", "14:00 usa perfil de mediodía")
	_comprobar(String(tarde["franja"]) == "tarde", "16:30 usa perfil de tarde")
	_comprobar(String(noche["franja"]) == "noche", "19:00 usa perfil de horas extra")
	_comprobar(
		float(mediodia["ambiente_factor"]) > float(manana["ambiente_factor"]),
		"mediodía refuerza sutilmente la luz"
	)
	_comprobar(
		float(noche["sol_factor"]) < float(tarde["sol_factor"]),
		"las horas extra reducen la luz direccional"
	)
	# #789: la ventana también dice la hora, y no puede contradecir al reloj.
	for perfil in [manana, mediodia, tarde]:
		_comprobar(float(perfil["ventana_energia"]) > 0.0, "de día entra luz por la ventana")
		_comprobar(
			Color(perfil["cristal"]).get_luminance() > Color(noche["cristal"]).get_luminance(),
			"el cristal de día es más claro que el de noche"
		)
	_comprobar(float(noche["ventana_energia"]) == 0.0, "de noche no entra sol")

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _aprox_angulo(actual: float, esperado: float) -> bool:
	return absf(angle_difference(actual, esperado)) < 0.001


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO reloj #963: " + nombre)
