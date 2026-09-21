## Regresión standalone del segundo vertical de meticulosidad (#961).
##
##     godot4 --headless --path godot --script pruebas/issue_961_detalles_smoke.gd
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	_probar_catalogo()
	_probar_desbloqueo_por_motivo()
	_probar_estado_sin_progreso()
	print("issue_961_detalles: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_catalogo() -> void:
	var datos: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://datos/detalles_meticulosos.json")
	)
	_comprobar(datos is Dictionary, true, "el catálogo de detalles es un diccionario")
	if not datos is Dictionary:
		return
	_comprobar(
		DetallesMeticulosos.errores_catalogo(datos, ["memo1@1", "oficio2@2"]),
		[],
		"las dos referencias del corte son válidas",
	)


func _probar_desbloqueo_por_motivo() -> void:
	var jornada := {"dia": 4, "vuelta": 1}
	_comprobar(
		DetallesMeticulosos.detalles_para("memo1@1", []),
		[],
		"sin atención no aparece detalle adicional",
	)

	Meticulosidad.registrar(jornada, "memo1@1", "relectura", "fecha")
	var motivos_fecha := Meticulosidad.motivos_documento(jornada, "memo1@1")
	_comprobar(motivos_fecha, ["fecha"], "la relectura conserva su motivo documental")
	_comprobar(
		DetallesMeticulosos.detalles_para("memo1@1", motivos_fecha),
		[],
		"un motivo distinto no desbloquea el detalle de margen",
	)

	Meticulosidad.registrar(jornada, "memo1@1", "lectura_completa", "margen")
	var motivos_memo := Meticulosidad.motivos_documento(jornada, "memo1@1")
	var detalles_memo := DetallesMeticulosos.detalles_para("memo1@1", motivos_memo)
	_comprobar(detalles_memo.size(), 1, "leer hasta el margen revela un detalle autorado")
	if not detalles_memo.is_empty():
		_comprobar(
			detalles_memo[0].get("texto"),
			"VISOR_DETALLE_961_MEMO1_MARGEN",
			"el detalle usa una clave de traducción estable",
		)

	var jornada_oficio := {"dia": 4, "vuelta": 1}
	Meticulosidad.registrar(jornada_oficio, "oficio2@2", "marcador", "folio")
	var detalles_oficio := DetallesMeticulosos.detalles_para(
		"oficio2@2",
		Meticulosidad.motivos_documento(jornada_oficio, "oficio2@2"),
	)
	_comprobar(detalles_oficio.size(), 1, "marcar el oficio habilita su detalle de folio")


func _probar_estado_sin_progreso() -> void:
	var estado := {
		"pistas_descubiertas": ["pista1@1"],
		"veredictos": {"caso@1": "sin-cambio"},
	}
	var antes := estado.duplicate(true)
	var jornada := {"dia": 7, "vuelta": 2}
	Meticulosidad.registrar(jornada, "memo1@1", "lectura_completa", "margen")
	DetallesMeticulosos.detalles_para(
		"memo1@1",
		Meticulosidad.motivos_documento(jornada, "memo1@1"),
	)
	_comprobar(estado, antes, "consultar detalles no toca pistas ni veredictos")


func _comprobar(actual, esperado, nombre: String) -> void:
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO #961 detalles: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
