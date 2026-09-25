## Contrato headless de fallos normales y fixtures anómalos del OS98 (#668).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var catalogo := FallosMundanosOs98.catalogo()
	_comprobar(catalogo.size() >= 5, "existen al menos cinco fallos mundanos declarados")

	for regla in catalogo:
		_comprobar(not String(regla.get("id", "")).is_empty(), "cada regla tiene id")
		_comprobar(not String(regla.get("causa", "")).is_empty(), "cada regla tiene causa")
		_comprobar(not String(regla.get("resolucion", "")).is_empty(), "cada regla tiene resolución")
		_comprobar(not String(regla.get("salida_segura", "")).is_empty(), "cada regla tiene salida segura")
		_comprobar(not String(regla.get("regla_normal", "")).is_empty(), "cada regla define normalidad")
		_comprobar(not String(regla.get("fixture_anomalo", "")).is_empty(), "cada regla expone fixture anómalo")

	var shareware := FallosMundanosOs98.evaluar(
		"shareware_expirado", {"evento": "licencia_expirada"}
	)
	_comprobar(shareware["activo"], "el trial expirado se reproduce de forma explícita")
	_comprobar(
		shareware["estado"] == FallosMundanosOs98.ESTADO_FALLO_MUNDANO,
		"un fallo normal no se clasifica como anomalía",
	)
	_comprobar(not shareware["viola_regla"], "el fallo normal conserva la regla aprendida")
	_comprobar(shareware["superficie"] == "software", "shareware enlaza con #663")

	var medio := FallosMundanosOs98.evaluar(
		"medio_solo_lectura", {"evento": "escritura_en_solo_lectura"}
	)
	_comprobar(medio["activo"], "solo lectura se reproduce sin tocar dispositivos reales")
	_comprobar(medio["superficie"] == "medios", "solo lectura enlaza con #664")
	_comprobar(medio["salida_segura"] == "cancelar_escritura", "solo lectura siempre permite salir")

	var cache := FallosMundanosOs98.evaluar(
		"cache_desactualizada", {"evento": "cache_antigua_consultada"}
	)
	_comprobar(cache["activo"], "la caché antigua es un fallo normal reproducible")
	_comprobar(cache["superficie"] == "web98", "caché enlaza con #667")

	var retirado_anomalo := FallosMundanosOs98.evaluar(
		"medio_retirado",
		{
			"evento": "ruta_medio_retirado",
			"fixture_anomalo": "archivo_accesible_tras_retirada",
		},
	)
	_comprobar(
		retirado_anomalo["estado"] == FallosMundanosOs98.ESTADO_FIXTURE_ANOMALO,
		"el fixture imposible se distingue del fallo normal",
	)
	_comprobar(retirado_anomalo["viola_regla"], "el fixture marca explícitamente la violación")
	_comprobar(
		retirado_anomalo["regla_normal"].contains("Retirar un medio"),
		"la anomalía conserva la regla normal que está rompiendo",
	)

	var inactivo := FallosMundanosOs98.evaluar(
		"formato_no_reconocido", {"evento": "otro_evento"}
	)
	_comprobar(not inactivo["activo"], "un evento distinto no fabrica fallos")
	_comprobar(
		inactivo["estado"] == FallosMundanosOs98.ESTADO_NORMAL,
		"sin disparador la regla permanece en normalidad",
	)

	var desconocido := FallosMundanosOs98.evaluar("no_existe", {"evento": "cualquier_cosa"})
	_comprobar(not desconocido["activo"], "un id desconocido no inventa una incidencia")
	_comprobar(
		desconocido["estado"] == FallosMundanosOs98.ESTADO_DESCONOCIDO,
		"un id desconocido queda explícitamente separado de normalidad/anomalía",
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
