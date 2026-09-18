extends SceneTree

const CasaEstadoAmbiental = preload("res://guion/casa_estado_ambiental.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var jornada := Jornada.nueva(123, 1)
	var inventario := Inventario.nuevo()
	var taza := {
		"id": "taza",
		"nombre": "Taza",
		"vendible": true,
		"precio": 12,
		"origen": "casa",
	}
	var llaves := {
		"id": "llaves",
		"nombre": "Llaves",
		"vendible": false,
		"precio": 0,
		"origen": "calle",
	}

	var inicial := CasaEstadoAmbiental.derivar(jornada, inventario)
	_comprobar(inicial["gato_estado"] == CasaEstadoAmbiental.GATO_ALIMENTADO, "gato alimentado")
	_comprobar(inicial["objetos_casa"].is_empty(), "casa empieza sin almacen materializable")
	_comprobar(inicial["vuelta"] == 1, "expone la vuelta persistida")
	_comprobar(inicial["consecuencias_casa"].is_empty(), "sin hechos no inventa averias")

	jornada["imprevistos"]["consecuencias"] = [
		"casa_persiana_atascada",
		"externa",
		"casa_luz_reducida",
		"casa_persiana_atascada",
	]
	var con_consecuencias := CasaEstadoAmbiental.derivar(jornada, inventario)
	_comprobar(
		con_consecuencias["consecuencias_casa"] == ["casa_luz_reducida", "casa_persiana_atascada"],
		"expone solo consecuencias domesticas reales"
	)
	con_consecuencias["consecuencias_casa"].clear()
	_comprobar(
		jornada["imprevistos"]["consecuencias"].size() == 4,
		"la señal de consecuencias no muta jornada"
	)

	_comprobar(Inventario.recoger(inventario, taza), "recoge taza")
	_comprobar(Inventario.guardar_en_casa(inventario, "taza"), "guarda taza en casa")
	_comprobar(Inventario.recoger(inventario, llaves), "lleva llaves encima")
	var con_objetos := CasaEstadoAmbiental.derivar(jornada, inventario)
	_comprobar(con_objetos["objetos_casa_ids"] == ["taza"], "solo home_storage materializa casa")
	_comprobar(not con_objetos["objetos_casa_ids"].has("llaves"), "carried no decora la casa")

	# La señal es una instantánea, no una referencia mutable al guardado.
	con_objetos["objetos_casa"][0]["nombre"] = "Mutada"
	_comprobar(
		inventario[Inventario.HOME_STORAGE][0]["nombre"] == "Taza", "derivar no muta inventario"
	)

	jornada["gato"]["dias_sin_comer"] = 1
	_comprobar(
		(
			CasaEstadoAmbiental.derivar(jornada, inventario)["gato_estado"]
			== CasaEstadoAmbiental.GATO_SIN_COMER
		),
		"hambre real cambia la señal del gato"
	)
	jornada["gato"]["presente"] = false
	_comprobar(
		(
			CasaEstadoAmbiental.derivar(jornada, inventario)["gato_estado"]
			== CasaEstadoAmbiental.GATO_AUSENTE
		),
		"gato ausente no se materializa"
	)

	jornada["vuelta"] = 4
	_comprobar(
		CasaEstadoAmbiental.derivar(jornada, inventario)["vuelta"] == 4, "conserva vueltas reales"
	)

	# Vender algo almacenado debe dejar el hueco sin tocar una variable visual.
	var venta := Inventario.vender(inventario, "taza")
	_comprobar(venta["vendido"], "vende objeto guardado")
	_comprobar(
		CasaEstadoAmbiental.derivar(jornada, inventario)["objetos_casa"].is_empty(),
		"venta vacia la señal ambiental"
	)

	# Perder la vivienda elimina solo home_storage; carried sigue existiendo pero
	# no reaparece mágicamente como mobiliario.
	var radio := {
		"id": "radio",
		"nombre": "Radio",
		"vendible": true,
		"precio": 20,
		"origen": "casa",
	}
	_comprobar(Inventario.recoger(inventario, radio), "recoge radio")
	_comprobar(Inventario.guardar_en_casa(inventario, "radio"), "guarda radio")
	Inventario.perder_casa(inventario)
	var sin_casa := CasaEstadoAmbiental.derivar(jornada, inventario)
	_comprobar(sin_casa["objetos_casa"].is_empty(), "perder casa limpia la composicion")
	_comprobar(inventario[Inventario.CARRIED].size() == 1, "perder casa conserva carried")
	_comprobar(
		not sin_casa["objetos_casa_ids"].has("llaves"),
		"carried conservado sigue fuera del decorado"
	)

	# Guardados incompletos o antiguos degradan a ausencia, nunca inventan props.
	_comprobar(
		(
			CasaEstadoAmbiental
			. derivar({}, {Inventario.HOME_STORAGE: "invalido"})["objetos_casa"]
			. is_empty()
		),
		"inventario invalido no inventa objetos"
	)
	_comprobar(
		CasaEstadoAmbiental.derivar({}, {})["gato_estado"] == CasaEstadoAmbiental.GATO_AUSENTE,
		"jornada incompleta no inventa gato"
	)
	_comprobar(
		CasaEstadoAmbiental.derivar({}, {})["vuelta"] == 1, "jornada antigua usa vuelta minima"
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
