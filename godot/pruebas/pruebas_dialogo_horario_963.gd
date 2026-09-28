## Regresión ejecutable del diálogo horario de compañeros (#963).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	_comprobar(DialogoHorarioCompaneros.franja(9.0) == "manana", "09:00 es mañana")
	_comprobar(DialogoHorarioCompaneros.franja(11.0) == "mediodia", "11:00 inicia mediodía")
	_comprobar(DialogoHorarioCompaneros.franja(15.0) == "tarde", "15:00 inicia tarde")
	_comprobar(DialogoHorarioCompaneros.franja(19.0) == "noche", "19:00 inicia noche")

	_comprobar(
		DialogoHorarioCompaneros.resolver("cunado", 9.0).is_empty(),
		"la mañana conserva el diálogo base",
	)
	_comprobar(
		DialogoHorarioCompaneros.resolver("cunado", 12.0) == "COMPA_HORA_CUNADO_MEDIODIA",
		"el cuñado reacciona al mediodía",
	)
	_comprobar(
		DialogoHorarioCompaneros.resolver("telefono", 16.5) == "COMPA_HORA_TELEFONO_TARDE",
		"el teléfono reacciona por la tarde",
	)
	_comprobar(
		DialogoHorarioCompaneros.resolver("becario", 19.0) == "COMPA_HORA_BECARIO_NOCHE",
		"el becario reacciona a horas extra",
	)
	_comprobar(
		DialogoHorarioCompaneros.resolver("jubilacion", 14.99)
		== "COMPA_HORA_JUBILACION_MEDIODIA",
		"el límite de mediodía es estable",
	)
	_comprobar(
		DialogoHorarioCompaneros.resolver("riegos", 18.99) == "COMPA_HORA_RIEGOS_TARDE",
		"la tarde dura hasta las 19:00",
	)
	_comprobar(
		DialogoHorarioCompaneros.resolver("emperador", 16.0).is_empty(),
		"un actor sin línea horaria conserva su diálogo base",
	)
	_comprobar(
		DialogoHorarioCompaneros.resolver("", 16.0).is_empty(),
		"un actor sin identidad no inventa diálogo",
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
