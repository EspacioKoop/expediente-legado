## Regresión standalone del primer vertical de meticulosidad (#961).
##
##     godot4 --headless --path godot --script pruebas/issue_961_smoke.gd
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	_probar_estado_pasivo()
	_probar_frontera_de_dia()
	_probar_ecos_oniricos()
	print("issue_961: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_estado_pasivo() -> void:
	var jornada := {"dia": 4}
	_comprobar(
		Meticulosidad.registrar(jornada, "memo@1", "lectura_completa", "margen"),
		true,
		"llegar al final registra atención",
	)
	_comprobar(
		Meticulosidad.registrar(jornada, "memo@1", "lectura_completa", "margen"),
		false,
		"el mismo gesto no se puede farmear",
	)
	_comprobar(
		Meticulosidad.registrar(jornada, "memo@1", "relectura", "fecha"),
		true,
		"releer puede reforzar otro motivo",
	)
	_comprobar(Meticulosidad.puntos(jornada), 3, "los puntos internos agregan gestos distintos")
	_comprobar(
		Meticulosidad.motivos_oniricos(jornada),
		["margen", "fecha"],
		"los motivos se ordenan por peso y de forma estable",
	)
	_comprobar(
		Meticulosidad.registrar(jornada, "memo@1", "evento_inventado", "margen"),
		false,
		"un evento desconocido no contamina estado",
	)


func _probar_frontera_de_dia() -> void:
	var jornada := {"dia": 2}
	Meticulosidad.registrar(jornada, "oficio@1", "marcador", "folio")
	_comprobar(Meticulosidad.puntos(jornada), 1, "el día guarda su atención")
	jornada["dia"] = 3
	_comprobar(Meticulosidad.puntos(jornada), 0, "el día nuevo no hereda meticulosidad")
	_comprobar(Meticulosidad.motivos_oniricos(jornada), [], "el sueño nuevo empieza sin motivos")


func _probar_ecos_oniricos() -> void:
	var ids := SuenoFormas.ids()
	_comprobar(ids.is_empty(), false, "hay al menos una forma onírica de serie")
	if ids.is_empty():
		return
	var mundo := Node3D.new()
	root.add_child(mundo)
	var ecos := (
		SuenoAtencionDocumental
		. montar(
			mundo,
			String(ids[0]),
			4,
			961,
			["fecha", "relacion", "fecha"],
		)
	)
	_comprobar(ecos.size(), 2, "como máximo dos motivos visten una sala")
	for eco in ecos:
		_comprobar(eco.get_meta("decorativo", false), true, "el eco se declara decorativo")
		_comprobar(
			String(eco.get_meta("motivo_meticulosidad", "")).is_empty(),
			false,
			"cada eco conserva su motivo",
		)
		_comprobar(eco is CollisionObject3D, false, "el eco no añade colisión jugable")
	mundo.queue_free()


func _comprobar(actual, esperado, nombre: String) -> void:
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO #961: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
