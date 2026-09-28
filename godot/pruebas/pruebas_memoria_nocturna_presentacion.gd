## Regresión ejecutable de la presentación de memoria nocturna (#162).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var base := {
		"entrada": Vector3(2.0, 0.0, 3.0),
		"ambiente_energia": 0.30,
		"luces":
		[
			{
				"pos": Vector3.ZERO,
				"color": Color.WHITE,
				"energia": 1.0,
				"alcance": 4.0,
				"carcasa": false,
			}
		],
		"planta": [Vector2i.ZERO],
		"salidas": [{"destino": "archivo"}],
	}
	var casos := [_caso()]

	var vacio := MemoriaNocturnaPresentacion.aplicar(
		base, [], MemoriaNocturna.analizar([], casos, [])
	)
	_comprobar(vacio["luces"].size() == 1, "vacío no añade luces")
	_comprobar(
		is_equal_approx(vacio["ambiente_energia"], 0.30),
		"vacío conserva el ambiente",
	)

	var unica_analisis := MemoriaNocturna.analizar(["F-1", "F-2"], casos, [])
	var unica := MemoriaNocturnaPresentacion.aplicar(base, ["F-1", "F-2"], unica_analisis)
	_comprobar(unica["luces"].size() == 3, "cada hueco seleccionado añade un acento")
	_comprobar(
		is_equal_approx(unica["luces"][1]["energia"], MemoriaNocturnaPresentacion.ENERGIA_BASE),
		"una lectura simple usa energía base",
	)

	var repetida_analisis := MemoriaNocturna.analizar(["F-1", "F-1"], casos, [])
	var repetida := MemoriaNocturnaPresentacion.aplicar(base, ["F-1", "F-1"], repetida_analisis)
	_comprobar(repetida["luces"].size() == 3, "repetir conserva dos apariciones visibles")
	_comprobar(
		repetida["luces"][1]["energia"] > unica["luces"][1]["energia"],
		"repetir intensifica la aparición",
	)
	_comprobar(
		repetida["luces"][1]["alcance"] > unica["luces"][1]["alcance"],
		"repetir amplía el halo",
	)

	var relacionada_analisis := MemoriaNocturna.analizar(["F-1", "F-2"], casos, ["P-12"])
	var relacionada := MemoriaNocturnaPresentacion.aplicar(
		base, ["F-1", "F-2"], relacionada_analisis
	)
	_comprobar(
		relacionada["luces"][1]["color"] == MemoriaNocturnaPresentacion.COLOR_RELACION,
		"una relación conocida cambia el tono",
	)
	_comprobar(
		relacionada["ambiente_energia"] > unica["ambiente_energia"],
		"una relación conocida altera el ambiente",
	)
	_comprobar(
		relacionada["planta"] == base["planta"] and relacionada["salidas"] == base["salidas"],
		"la presentación no cambia navegación ni salida",
	)
	_comprobar(
		relacionada["memoria_nocturna_visual"]["relaciones"] == 1,
		"el metadato visual solo registra cantidad de relaciones",
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _caso() -> Dictionary:
	return {
		"id": "caso-1",
		"registros":
		[
			{"id": "R-1", "folio": "F-1"},
			{"id": "R-2", "folio": "F-2"},
		],
		"pistas":
		[
			{
				"id": "P-12",
				"registroOrigen": "R-1",
				"registroOrigen2": "R-2",
				"descripcion": "No debe llegar a la presentación",
			}
		],
	}


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
