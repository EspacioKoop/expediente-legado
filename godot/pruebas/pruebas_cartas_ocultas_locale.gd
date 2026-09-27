extends SceneTree

## #1500: cada carta oculta debe poder marcarse en el documento que se muestra,
## tanto con el catálogo español como con el inglés.

var pasadas := 0
var fallos := 0


func _init() -> void:
	for ruta in ["res://datos/casos.json", "res://datos/casos.en.json"]:
		var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
		comprobar("%s carga" % ruta, datos is Dictionary, true)
		var registros := _registros_por_folio(datos if datos is Dictionary else {})
		for folio in CartasOcultas.POR_FOLIO:
			var carta: Dictionary = CartasOcultas.POR_FOLIO[folio]
			var registro: Dictionary = registros.get(folio, {})
			comprobar("%s tiene %s" % [ruta, folio], registro.is_empty(), false)
			comprobar(
				"%s marca %s en %s" % [ruta, carta["carta"], folio],
				_cartas_marcadas(registro).has(carta["carta"]),
				true
			)

	comprobar("sin variante no hay frase", CartasOcultas.frase_en_texto({}, "texto"), "")
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _registros_por_folio(datos: Dictionary) -> Dictionary:
	var resultado := {}
	for caso in datos.get("casos", []):
		for registro in caso.get("registros", []):
			resultado[String(registro.get("folio", ""))] = registro
	return resultado


func _cartas_marcadas(registro: Dictionary) -> Array:
	var cartas := []
	for segmento in Marcas.de_registro(registro, [], []):
		if segmento.get("tipo", "") == "carta":
			cartas.append(segmento.get("meta", {}).get("carta", ""))
	return cartas


func comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO %s\n  esperado: %s\n  obtenido: %s" % [nombre, esperado, obtenido])
