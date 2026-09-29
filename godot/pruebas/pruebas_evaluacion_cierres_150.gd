## Regresión end-to-end de cierres reales de vida para #150.
##
## Recorre las dos fronteras que hoy terminan una vida laboral:
## reasignación aceptada y final narrativo. La prueba no llama a sellar()
## directamente: exige que los dueños reales produzcan y conserven el historial.
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	var estado := Partida.nueva()
	var jornada: Dictionary = estado["jornada"]
	jornada["dia"] = 7
	jornada["gato"]["dias_sin_comer"] = 1
	estado["vida"] = 1
	estado["veredictos"]["vida-1"] = "firma"

	var ultimo_recurso := Acusacion.perder_vida(estado, jornada, 1)
	_comprobar(
		bool(ultimo_recurso.get("despido_pendiente", false)),
		"agotar la última vida abre la frontera de reasignación",
	)
	_comprobar(
		estado.get("evaluaciones_desempeno", []).is_empty(),
		"la frontera previa al cese todavía no sella la evaluación",
	)

	var cese := Acusacion.aceptar_cese(estado, jornada)
	_comprobar(bool(cese.get("despido", false)), "aceptar el cese termina la primera vida")
	var tras_reasignacion: Array = estado.get("evaluaciones_desempeno", [])
	_comprobar(tras_reasignacion.size() == 1, "la reasignación sella exactamente una evaluación")
	if tras_reasignacion.size() == 1:
		_comprobar(
			int(tras_reasignacion[0].get("vuelta", 0)) == 1,
			"la evaluación conserva la vuelta que terminó",
		)
		_comprobar(
			String(tras_reasignacion[0].get("motivo", "")) == "reasignacion",
			"la evaluación conserva el motivo de reasignación",
		)

	_comprobar(int(jornada.get("vuelta", 0)) == 2, "el cese abre la segunda vida")
	estado["veredictos"]["vida-2"] = "firma"
	FinalPolitico.confirmar_cierre(estado)

	var historial: Array = estado.get("evaluaciones_desempeno", [])
	_comprobar(historial.size() == 2, "el final narrativo añade la segunda evaluación")
	if historial.size() == 2:
		_comprobar(
			int(historial[1].get("vuelta", 0)) == 2,
			"el final sella la segunda vida real",
		)
		_comprobar(
			String(historial[1].get("motivo", "")) == "final_narrativo",
			"el segundo sello distingue el final narrativo",
		)
		_comprobar(
			int(historial[1].get("veredictos_total", 0))
				> int(historial[0].get("veredictos_total", 0)),
			"el historial acumulado permite aislar productividad entre vidas",
		)

	FinalPolitico.confirmar_cierre(estado)
	_comprobar(
		estado.get("evaluaciones_desempeno", []).size() == 2,
		"reconfirmar el final no duplica evaluaciones",
	)
	var cese_repetido := Acusacion.aceptar_cese(estado, jornada)
	_comprobar(
		not bool(cese_repetido.get("despido", false)),
		"aceptar cese fuera de una frontera real no crea otra vida",
	)
	_comprobar(
		estado.get("evaluaciones_desempeno", []).size() == 2,
		"un cese rechazado tampoco duplica historial",
	)

	var restaurado: Variant = JSON.parse_string(JSON.stringify(estado))
	_comprobar(restaurado is Dictionary, "el estado con ambas vidas sobrevive a JSON")
	if restaurado is Dictionary:
		_comprobar(
			Partida.validar(restaurado as Dictionary).is_empty(),
			"Partida valida el historial producido por ambos cierres reales",
		)
		_comprobar(
			(restaurado as Dictionary).get("evaluaciones_desempeno", []).size() == 2,
			"recargar conserva exactamente los dos sellos",
		)

	print("evaluacion_cierres_150: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO #150: %s" % mensaje)
