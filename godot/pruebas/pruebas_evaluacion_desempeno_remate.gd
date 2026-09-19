## Regresión headless del remate de evaluación sellada (#150 / #100).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	TranslationServer.set_locale("es")
	var estado := {
		"evaluaciones_desempeno":
		[
			{
				"vuelta": 2,
				"motivo": "reasignacion",
				"veredictos_total": 5,
				"evaluacion":
				{
					"productividad": EvaluacionDesempeno.ALTA,
					"precipitacion": EvaluacionDesempeno.ALTA,
					"cuidado_gato": EvaluacionDesempeno.MEDIA,
					"liquidez": EvaluacionDesempeno.BAJA,
					"exploracion_onirica": EvaluacionDesempeno.MEDIA,
				},
			}
		]
	}
	var antes := JSON.stringify(estado)
	var planos := EvaluacionDesempenoCinematica.planos_de(estado)

	_comprobar(planos.size() == 1, "un historial sellado produce un plano de remate")
	_comprobar(String(planos[0].get("tipo", "")) == "2d", "el informe usa el plano 2D común")
	_comprobar(
		String(planos[0].get("rotulo", "")).contains("VIDA 2"),
		"el rótulo identifica la vida archivada",
	)
	_comprobar(
		String(planos[0].get("voz", "")).to_lower().contains("productividad"),
		"la combinación productiva y precipitada obtiene su frase",
	)
	var figura: Array = planos[0].get("figura", [])
	_comprobar(figura.size() == 13, "la hoja contiene cinco barras independientes")
	_comprobar(
		(
			EvaluacionDesempenoCinematica._ancho_de(EvaluacionDesempeno.BAJA)
			< EvaluacionDesempenoCinematica._ancho_de(EvaluacionDesempeno.MEDIA)
		),
		"el rango medio se representa con más longitud que el bajo",
	)
	_comprobar(
		(
			EvaluacionDesempenoCinematica._ancho_de(EvaluacionDesempeno.MEDIA)
			< EvaluacionDesempenoCinematica._ancho_de(EvaluacionDesempeno.ALTA)
		),
		"el rango alto se representa con más longitud que el medio",
	)
	_comprobar(JSON.stringify(estado) == antes, "presentar el informe no modifica Partida")
	_comprobar(
		EvaluacionDesempenoCinematica.planos_de({}).is_empty(),
		"una partida sin evaluación sellada no inventa un informe",
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
