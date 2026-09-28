## Regresión ejecutable del modelo de memoria nocturna (#162).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var casos := [_caso_uno(), _caso_dos()]

	var vacia := MemoriaNocturna.analizar([], casos, [])
	_comprobar(vacia["documentos_unicos"] == 0, "vacío no inventa documentos")
	_comprobar(vacia["intensidad_maxima"] == 0, "vacío tiene intensidad cero")
	_comprobar(vacia["relaciones"].is_empty(), "vacío no inventa relaciones")

	var repetida := MemoriaNocturna.analizar(["F-1", "F-1", "F-2"], casos, ["P-12"])
	_comprobar(repetida["documentos_unicos"] == 2, "repetir conserva dos documentos únicos")
	_comprobar(repetida["intensidad_maxima"] == 2, "repetir intensifica la memoria")
	_comprobar(repetida["repeticiones"].size() == 1, "solo se marca el folio repetido")
	_comprobar(
		repetida["repeticiones"][0] == {"folio": "F-1", "veces": 2},
		"la repetición conserva folio y cantidad",
	)
	_comprobar(repetida["relaciones"].size() == 1, "una relación conocida se detecta")
	_comprobar(
		repetida["relaciones"][0]["folios"] == ["F-1", "F-2"],
		"la relación usa folios visibles y no descripciones",
	)
	_comprobar(
		repetida["relaciones"][0]["pistas"] == ["P-12"],
		"solo viaja la identidad de una pista ya conocida",
	)

	var desconocida := MemoriaNocturna.analizar(["F-1", "F-2"], casos, [])
	_comprobar(
		desconocida["relaciones"].is_empty(),
		"una relación no descubierta no se filtra mediante el sueño",
	)

	var incompleta := MemoriaNocturna.analizar(["F-1"], casos, ["P-12"])
	_comprobar(
		incompleta["relaciones"].is_empty(),
		"la memoria exige los dos documentos de la relación",
	)

	var cruzada := MemoriaNocturna.analizar(["F-1", "G-1"], casos, ["P-12", "P-G"])
	_comprobar(
		cruzada["relaciones"].is_empty(),
		"documentos de casos distintos no crean una relación por proximidad",
	)

	var orden_a := MemoriaNocturna.analizar(["F-1", "F-2", "F-1"], casos, ["P-12"])
	var orden_b := MemoriaNocturna.analizar(["F-2", "F-1", "F-1"], casos, ["P-12"])
	_comprobar(
		orden_a["firma"] != orden_b["firma"],
		"la firma preserva el orden elegido aunque la relación sea la misma",
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _caso_uno() -> Dictionary:
	return {
		"id": "caso-1",
		"registros":
		[
			{"id": "R-1", "folio": "F-1"},
			{"id": "R-2", "folio": "F-2"},
			{"id": "R-3", "folio": "F-3"},
		],
		"pistas":
		[
			{
				"id": "P-12",
				"registroOrigen": "R-1",
				"registroOrigen2": "R-2",
				"descripcion": "Texto que el modelo no debe copiar",
			},
			{"id": "P-1", "registroOrigen": "R-1", "descripcion": "Detalle simple"},
		],
	}


func _caso_dos() -> Dictionary:
	return {
		"id": "caso-2",
		"registros":
		[
			{"id": "G-R1", "folio": "G-1"},
			{"id": "G-R2", "folio": "G-2"},
		],
		"pistas":
		[
			{
				"id": "P-G",
				"registroOrigen": "G-R1",
				"registroOrigen2": "G-R2",
				"descripcion": "Otra relación",
			}
		],
	}


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
