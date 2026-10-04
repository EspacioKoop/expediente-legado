## Regresión de desenlaces especiales de la cámara onírica (#2322 / #2286 / #140).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_valida_reactiva()
	_probar_blanco_por_degradacion()
	_probar_misma_vuelta_y_legacy()
	_probar_contaminada_no_promociona()
	_probar_inmutabilidad()
	print("grabacion_onirica_desenlace_140: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_valida_reactiva() -> void:
	var entrada := {
		"estado": GrabacionOniricaContrato.ESTADO_VALIDA,
		"motivos": [],
		"original_id": "folio-1",
	}
	var salida := (
		GrabacionOniricaDesenlace
		. resolver(
			entrada,
			{
				"anomalia_id": "anomalia-crt",
				"reactiva": true,
				"vuelta_grabada": 1,
			},
			{"vuelta_actual": 3},
		)
	)
	_comprobar(String(salida["estado"]) == "caos", "sujeto reactivo conserva prioridad CAOS")
	_comprobar(
		String(salida.get("desencadenante", "")) == "sujeto_reactivo",
		"CAOS conserva causa trazable",
	)


func _probar_blanco_por_degradacion() -> void:
	var entrada := {
		"estado": GrabacionOniricaContrato.ESTADO_VALIDA,
		"motivos": [],
		"original_id": "folio-1",
	}
	var sujeto := {
		"anomalia_id": "anomalia-crt",
		"reactiva": false,
		"vuelta_grabada": 2,
	}
	var salida := (
		GrabacionOniricaDesenlace
		. resolver(
			entrada,
			sujeto,
			{"vuelta_actual": 3},
		)
	)
	_comprobar(String(salida["estado"]) == "blanco", "toma valida antigua produce BLANCO")
	_comprobar(
		String(salida.get("desencadenante", "")) == "degradacion_vuelta",
		"BLANCO conserva causa trazable",
	)


func _probar_misma_vuelta_y_legacy() -> void:
	var base := {"estado": GrabacionOniricaContrato.ESTADO_VALIDA, "motivos": []}
	var misma_vuelta := (
		GrabacionOniricaDesenlace
		. resolver(
			base,
			{
				"anomalia_id": "anomalia-crt",
				"reactiva": false,
				"vuelta_grabada": 3,
			},
			{"vuelta_actual": 3},
		)
	)
	_comprobar(
		String(misma_vuelta["estado"]) == GrabacionOniricaContrato.ESTADO_VALIDA,
		"una toma de la vuelta actual conserva VALIDA",
	)

	var legacy := (
		GrabacionOniricaDesenlace
		. resolver(
			base,
			{"anomalia_id": "anomalia-crt", "reactiva": false},
			{"vuelta_actual": 4},
		)
	)
	_comprobar(
		String(legacy["estado"]) == GrabacionOniricaContrato.ESTADO_VALIDA,
		"una toma legacy sin vuelta no se degrada",
	)
	_comprobar(not legacy.has("desencadenante"), "legacy no inventa causa")


func _probar_contaminada_no_promociona() -> void:
	var entrada := {
		"estado": GrabacionOniricaContrato.ESTADO_CONTAMINADA,
		"motivos": ["interrupcion"],
	}
	var salida := (
		GrabacionOniricaDesenlace
		. resolver(
			entrada,
			{
				"anomalia_id": "anomalia-crt",
				"reactiva": true,
				"vuelta_grabada": 1,
			},
			{"vuelta_actual": 4},
		)
	)
	_comprobar(
		String(salida["estado"]) == GrabacionOniricaContrato.ESTADO_CONTAMINADA,
		"CONTAMINADA tiene prioridad sobre desenlaces especiales",
	)
	_comprobar(salida["motivos"] == ["interrupcion"], "no reevalua calidad de toma")


func _probar_inmutabilidad() -> void:
	var entrada := {
		"estado": GrabacionOniricaContrato.ESTADO_VALIDA,
		"motivos": [],
		"anidado": {"valor": 1},
	}
	var sujeto := {
		"anomalia_id": "a",
		"reactiva": false,
		"vuelta_grabada": 1,
	}
	var contexto := {"vuelta_actual": 2}
	var original := entrada.duplicate(true)
	var sujeto_original := sujeto.duplicate(true)
	var contexto_original := contexto.duplicate(true)
	var salida := GrabacionOniricaDesenlace.resolver(entrada, sujeto, contexto)
	salida["anidado"]["valor"] = 7
	_comprobar(entrada == original, "resolver no muta la proyeccion recibida")
	_comprobar(sujeto == sujeto_original, "resolver no muta hechos del sujeto")
	_comprobar(contexto == contexto_original, "resolver no muta contexto temporal")


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error("FALLO #2322 desenlace onirico: " + mensaje)
