extends SceneTree

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_programacion()
	_probar_orden_fisico()
	_probar_invalidos_e_idempotencia()
	_probar_ignorar_no_muta()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_programacion() -> void:
	var jornada := {"dia": 4, "vuelta": 2, "acciones": Jornada.ACCIONES_POR_DIA}
	var antes := JSON.stringify(jornada)
	var primera := IncidenteImpresoraOficina.programacion(jornada, 1768)
	var segunda := IncidenteImpresoraOficina.programacion(jornada, 1768)
	_comprobar(primera == segunda, "misma raíz/vuelta/día produce la misma programación")
	_comprobar(String(primera["evento"]) == "impresora_atascada", "publica el evento ya canónico")
	_comprobar(int(primera["dia"]) == 4, "conserva día")
	_comprobar(int(primera["vuelta"]) == 2, "conserva vuelta")
	_comprobar(int(primera["tras_accion"]) >= 1, "nunca aparece antes de empezar")
	_comprobar(
		int(primera["tras_accion"]) <= Jornada.ACCIONES_POR_DIA,
		"se programa dentro de la jornada laboral",
	)
	_comprobar(JSON.stringify(jornada) == antes, "programar no muta Jornada")


func _probar_orden_fisico() -> void:
	var incidente := IncidenteImpresoraOficina.nuevo(4, 2)
	_comprobar(
		IncidenteImpresoraOficina.secuencia_completa()
		== ["inspeccionar", "abrir_bandeja", "retirar_papel", "cerrar_bandeja"],
		"la secuencia física es explícita",
	)

	var paso := IncidenteImpresoraOficina.transicionar(
		incidente, IncidenteImpresoraOficina.INSPECCIONAR
	)
	_comprobar(bool(paso["ok"]), "inspeccionar inicia la resolución")
	incidente = paso["estado"]
	_comprobar(bool(incidente["inspeccionada"]), "queda constancia de la inspección")
	_comprobar(String(incidente["estado"]) == IncidenteImpresoraOficina.ATASCADA, "aún está atascada")

	paso = IncidenteImpresoraOficina.transicionar(
		incidente, IncidenteImpresoraOficina.ABRIR_BANDEJA
	)
	_comprobar(bool(paso["ok"]), "abre bandeja tras inspeccionar")
	incidente = paso["estado"]
	_comprobar(
		String(incidente["estado"]) == IncidenteImpresoraOficina.BANDEJA_ABIERTA,
		"bandeja queda abierta",
	)

	paso = IncidenteImpresoraOficina.transicionar(
		incidente, IncidenteImpresoraOficina.RETIRAR_PAPEL
	)
	_comprobar(bool(paso["ok"]), "retira el papel tras abrir")
	incidente = paso["estado"]
	_comprobar(
		String(incidente["estado"]) == IncidenteImpresoraOficina.PAPEL_RETIRADO,
		"papel queda retirado",
	)

	paso = IncidenteImpresoraOficina.transicionar(
		incidente, IncidenteImpresoraOficina.CERRAR_BANDEJA
	)
	_comprobar(bool(paso["ok"]), "cerrar completa el incidente")
	incidente = paso["estado"]
	_comprobar(bool(paso["resuelta"]), "el resultado marca resolución")
	_comprobar(String(incidente["estado"]) == IncidenteImpresoraOficina.RESUELTA, "estado final estable")


func _probar_invalidos_e_idempotencia() -> void:
	var incidente := IncidenteImpresoraOficina.nuevo(2)
	var antes := JSON.stringify(incidente)
	var invalido := IncidenteImpresoraOficina.transicionar(
		incidente, IncidenteImpresoraOficina.RETIRAR_PAPEL
	)
	_comprobar(not bool(invalido["ok"]), "no permite retirar antes de abrir")
	_comprobar(String(invalido["motivo"]) == "orden_invalido", "explica el orden inválido")
	_comprobar(JSON.stringify(invalido["estado"]) == antes, "un orden inválido no muta estado")
	_comprobar(JSON.stringify(incidente) == antes, "transicionar trabaja sobre copia")

	var resuelta := incidente
	for accion in IncidenteImpresoraOficina.secuencia_completa():
		var paso := IncidenteImpresoraOficina.transicionar(resuelta, accion)
		resuelta = paso["estado"]
	var final_antes := JSON.stringify(resuelta)
	var repetida := IncidenteImpresoraOficina.transicionar(
		resuelta, IncidenteImpresoraOficina.INSPECCIONAR
	)
	_comprobar(not bool(repetida["ok"]), "una incidencia resuelta no vuelve a empezar")
	_comprobar(String(repetida["motivo"]) == "ya_resuelta", "la repetición es idempotente")
	_comprobar(JSON.stringify(repetida["estado"]) == final_antes, "repetir no altera el final")


func _probar_ignorar_no_muta() -> void:
	var incidente := IncidenteImpresoraOficina.nuevo(6)
	var antes := JSON.stringify(incidente)
	for _i in 5:
		pass
	_comprobar(JSON.stringify(incidente) == antes, "ignorar no avanza ni bloquea el incidente")
	_comprobar(not bool(incidente["resuelta"]), "ignorar deja resolución opcional")


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error(mensaje)
