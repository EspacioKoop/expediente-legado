## Regresión de esquema v2 y dependencia económica (#150).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var estado := {
		"jornada": Jornada.nueva(),
		"veredictos": {},
		"evaluaciones_desempeno": [],
		"perdio_vida_en_esta_vuelta": false,
	}

	var sin_extra := EvaluacionDesempeno.calcular(estado)
	_comprobar(
		sin_extra["dependencia_dinero"] == EvaluacionDesempeno.BAJA,
		"cero trabajillos produce dependencia baja",
	)

	estado["jornada"]["trabajillos"] = {"hechos": 1}
	var un_extra := EvaluacionDesempeno.calcular(estado)
	_comprobar(
		un_extra["dependencia_dinero"] == EvaluacionDesempeno.MEDIA,
		"un trabajillo produce dependencia media",
	)

	estado["jornada"]["trabajillos"]["hechos"] = 3
	var varios_extra := EvaluacionDesempeno.calcular(estado)
	_comprobar(
		varios_extra["dependencia_dinero"] == EvaluacionDesempeno.ALTA,
		"tres trabajillos producen dependencia alta",
	)

	var sello := EvaluacionDesempeno.sellar(estado, "final_narrativo")
	_comprobar(
		int(sello.get("version_evaluacion", 0)) == EvaluacionDesempeno.VERSION_EVALUACION_ACTUAL,
		"los sellos nuevos declaran la versión actual",
	)
	_comprobar(
		String(sello.get("evaluacion", {}).get("dependencia_dinero", ""))
		== EvaluacionDesempeno.ALTA,
		"el sello conserva la dependencia calculada",
	)

	var v1 := [
		{
			"vuelta": 1,
			"motivo": "reasignacion",
			"veredictos_total": 2,
			"evaluacion":
			{
				"productividad": EvaluacionDesempeno.MEDIA,
				"precipitacion": EvaluacionDesempeno.BAJA,
				"cuidado_gato": EvaluacionDesempeno.ALTA,
				"liquidez": EvaluacionDesempeno.MEDIA,
				"exploracion_onirica": EvaluacionDesempeno.BAJA,
			},
		}
	]
	_comprobar(
		EvaluacionDesempeno.validar_historial(v1).is_empty(),
		"un informe v1 sin sexta categoría sigue siendo válido",
	)

	var v2_incompleta := v1.duplicate(true)
	v2_incompleta[0]["version_evaluacion"] = 2
	_comprobar(
		not EvaluacionDesempeno.validar_historial(v2_incompleta).is_empty(),
		"un informe v2 exige dependencia económica",
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
