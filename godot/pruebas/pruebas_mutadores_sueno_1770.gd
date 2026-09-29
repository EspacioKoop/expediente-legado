extends SceneTree

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_catalogo_y_candidatos()
	_probar_seleccion_reproducible()
	_probar_aplicacion_sin_tocar_ruta()
	_probar_reduccion_movimiento()
	_probar_dos_espacios_reales()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_catalogo_y_candidatos() -> void:
	var catalogo := MutadoresSueno.catalogo()
	_comprobar(catalogo.size() == 4, "declara cuatro mutadores")
	for id in [
		MutadoresSueno.HUMEDAD,
		MutadoresSueno.APAGONES,
		MutadoresSueno.REPETICION,
		MutadoresSueno.DESFASE,
	]:
		_comprobar(
			catalogo.any(func(ficha): return String(ficha.get("id", "")) == id),
			"el catalogo contiene %s" % id,
		)

	var jornada := {
		"dia": 3,
		"vuelta": 2,
		"leido_hoy": ["folio-1"],
		"eventos": [],
		"imprevistos": {"consecuencias": ["casa_luz_reducida"]},
		Estres.CAMPO_JORNADA: {"valor": 45.0},
	}
	var candidatos := MutadoresSueno.candidatos(jornada)
	_comprobar(candidatos.has(MutadoresSueno.HUMEDAD), "la lluvia propone humedad")
	_comprobar(candidatos.has(MutadoresSueno.APAGONES), "una luz reducida propone apagones")
	_comprobar(candidatos.has(MutadoresSueno.REPETICION), "lo examinado propone repeticion")
	_comprobar(candidatos.has(MutadoresSueno.DESFASE), "el estres alto propone desfase")

	var limpia := {"dia": 1, "vuelta": 1, "leido_hoy": [], "eventos": []}
	var antes := JSON.stringify(limpia)
	_comprobar(MutadoresSueno.candidatos(limpia).is_empty(), "sin hechos no inventa mutador")
	_comprobar(JSON.stringify(limpia) == antes, "consultar candidatos no muta Jornada")
	_comprobar(MutadoresSueno.seleccionar(limpia, 99).is_empty(), "sin candidato selecciona cero")


func _probar_seleccion_reproducible() -> void:
	var jornada := {
		"dia": 3,
		"vuelta": 4,
		"leido_hoy": ["a", "b"],
		"imprevistos": {"consecuencias": ["casa_luz_reducida"]},
		Estres.CAMPO_JORNADA: {"valor": 60.0},
	}
	var primera := MutadoresSueno.seleccionar(jornada, 8172)
	var segunda := MutadoresSueno.seleccionar(jornada, 8172)
	_comprobar(not primera.is_empty(), "con candidatos elige uno")
	_comprobar(primera == segunda, "misma noche y raiz repiten seleccion")
	_comprobar(MutadoresSueno.IDS.has(String(primera.get("id", ""))), "la seleccion sale del catalogo")


func _probar_aplicacion_sin_tocar_ruta() -> void:
	var espacio := {
		"bloques": [Rect2i(0, 0, 4, 4)],
		"entrada": Vector2i(1, 1),
		"salida": Vector2i(3, 3),
		"objetivo": {"id": "principal", "hecho": false},
	}
	var original := espacio.duplicate(true)
	for id in MutadoresSueno.IDS:
		var aplicado := MutadoresSueno.aplicar(espacio, {"id": id})
		_comprobar(aplicado.has("mutador_nocturno"), "%s añade metadata" % id)
		_comprobar(aplicado["bloques"] == original["bloques"], "%s conserva bloques" % id)
		_comprobar(aplicado["entrada"] == original["entrada"], "%s conserva entrada" % id)
		_comprobar(aplicado["salida"] == original["salida"], "%s conserva salida" % id)
		_comprobar(aplicado["objetivo"] == original["objetivo"], "%s conserva objetivo" % id)
		_comprobar(
			not bool(aplicado["mutador_nocturno"].get("afecta_navegacion", true)),
			"%s no bloquea navegacion" % id,
		)
	_comprobar(espacio == original, "aplicar nunca muta el espacio de origen")
	_comprobar(
		not MutadoresSueno.aplicar(espacio, {"id": "desconocido"}).has("mutador_nocturno"),
		"un id desconocido no inventa efecto",
	)


func _probar_reduccion_movimiento() -> void:
	var espacio := {"entrada": Vector2i.ZERO, "salida": Vector2i.ONE}
	var normal := MutadoresSueno.aplicar(espacio, {"id": MutadoresSueno.DESFASE}, false)
	var reducida := MutadoresSueno.aplicar(espacio, {"id": MutadoresSueno.DESFASE}, true)
	var normal_meta: Dictionary = normal["mutador_nocturno"]
	var reducida_meta: Dictionary = reducida["mutador_nocturno"]
	_comprobar(bool(normal_meta["animacion"]), "normal conserva animacion")
	_comprobar(not bool(reducida_meta["animacion"]), "reduccion apaga animacion")
	_comprobar(not bool(reducida_meta["particulas"]), "reduccion apaga particulas")
	_comprobar(float(reducida_meta["retardo_ambiental"]) > 0.0, "desfase conserva su lectura")
	_comprobar(
		float(reducida_meta["retardo_ambiental"]) < float(normal_meta["retardo_ambiental"]),
		"reduccion acorta el retardo",
	)


func _probar_dos_espacios_reales() -> void:
	for id_espacio in ["crucero", "peine"]:
		var base := Sueno.espacio(id_espacio, 1, {})
		var aplicado := MutadoresSueno.aplicar(base, {"id": MutadoresSueno.REPETICION})
		_comprobar(not base.is_empty(), "%s existe como sueño base" % id_espacio)
		_comprobar(
			String(aplicado["mutador_nocturno"]["id"]) == MutadoresSueno.REPETICION,
			"%s acepta el mismo mutador generico" % id_espacio,
		)
		for clave in base.keys():
			_comprobar(aplicado.get(clave) == base[clave], "%s conserva %s" % [id_espacio, clave])


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error(mensaje)
