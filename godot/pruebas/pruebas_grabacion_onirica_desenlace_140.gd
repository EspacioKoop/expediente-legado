## Regresión del resolver de CAOS de la cámara onírica (#2286 / #140).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_valida_reactiva()
	_probar_no_reactiva_y_legacy()
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
	var salida := GrabacionOniricaDesenlace.resolver(
		entrada,
		{"anomalia_id": "anomalia-crt", "reactiva": true},
	)
	_comprobar(String(salida["estado"]) == "caos", "toma valida + sujeto reactivo produce CAOS")
	_comprobar(
		String(salida.get("desencadenante", "")) == "sujeto_reactivo",
		"CAOS conserva causa trazable",
	)


func _probar_no_reactiva_y_legacy() -> void:
	var base := {"estado": GrabacionOniricaContrato.ESTADO_VALIDA, "motivos": []}
	for sujeto in [
		{"anomalia_id": "anomalia-crt", "reactiva": false},
		{"anomalia_id": "", "reactiva": true},
		{},
	]:
		var salida := GrabacionOniricaDesenlace.resolver(base, sujeto)
		_comprobar(
			String(salida["estado"]) == GrabacionOniricaContrato.ESTADO_VALIDA,
			"sujeto no elegible conserva VALIDA",
		)
		_comprobar(not salida.has("desencadenante"), "sin promoción no inventa causa")


func _probar_contaminada_no_promociona() -> void:
	var entrada := {
		"estado": GrabacionOniricaContrato.ESTADO_CONTAMINADA,
		"motivos": ["interrupcion"],
	}
	var salida := GrabacionOniricaDesenlace.resolver(
		entrada,
		{"anomalia_id": "anomalia-crt", "reactiva": true},
	)
	_comprobar(
		String(salida["estado"]) == GrabacionOniricaContrato.ESTADO_CONTAMINADA,
		"CONTAMINADA tiene prioridad sobre CAOS",
	)
	_comprobar(salida["motivos"] == ["interrupcion"], "no reevalua calidad de toma")


func _probar_inmutabilidad() -> void:
	var entrada := {
		"estado": GrabacionOniricaContrato.ESTADO_VALIDA,
		"motivos": [],
		"anidado": {"valor": 1},
	}
	var original := entrada.duplicate(true)
	var salida := GrabacionOniricaDesenlace.resolver(
		entrada,
		{"anomalia_id": "a", "reactiva": true},
	)
	salida["anidado"]["valor"] = 7
	_comprobar(entrada == original, "resolver no muta la proyeccion recibida")


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error("FALLO #2286 CAOS: " + mensaje)
