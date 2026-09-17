extends SceneTree

## Regresión aislada de #787: el gato reacciona a estado real ya existente,
## pero la política no conoce objetivos, coordenadas ni pistas.

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _probar() -> void:
	var normal := GatoReaccionContextual.decidir(
		ContaminacionOs98.FASE_NORMALIDAD, 0, true
	)
	_comprobar(normal.is_empty(), "normalidad no fabrica reacción")

	var anomalia := GatoReaccionContextual.decidir(
		ContaminacionOs98.FASE_NORMALIDAD, 1, true
	)
	_comprobar(
		anomalia.get("id", "") == GatoReaccionContextual.ANOMALIA_SUENO,
		"una anomalía ya montada produce reacción",
	)
	_comprobar(anomalia.get("estado", "") == "observando", "la anomalía se observa")
	_comprobar(not anomalia.has("objetivo"), "la reacción no contiene objetivo")
	_comprobar(not anomalia.has("pos"), "la reacción no contiene coordenadas")
	_comprobar(not anomalia.has("pista"), "la reacción no contiene pista")

	var contaminacion := GatoReaccionContextual.decidir(
		ContaminacionOs98.FASE_CONTAMINACION_CRUZADA, 0, true
	)
	_comprobar(
		contaminacion.get("id", "") == GatoReaccionContextual.CONTAMINACION,
		"la contaminación cruzada produce reacción",
	)
	_comprobar(
		contaminacion.get("estado", "") == "escondido",
		"la contaminación se distingue de la anomalía onírica",
	)

	var prioridad := GatoReaccionContextual.decidir(
		ContaminacionOs98.FASE_CONTAMINACION_CRUZADA, 3, true
	)
	_comprobar(
		prioridad.get("id", "") == GatoReaccionContextual.CONTAMINACION,
		"la contaminación tiene prioridad determinista",
	)

	var escasa := GatoReaccionContextual.decidir(
		ContaminacionOs98.FASE_CLIMAX, 4, false
	)
	_comprobar(escasa.is_empty(), "un gato sin ayuda completa no reaparece por la reacción")

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(actual: bool, nombre: String) -> void:
	if actual:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO reacción contextual gato: %s" % nombre)
