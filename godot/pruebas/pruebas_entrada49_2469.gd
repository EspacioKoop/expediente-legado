extends SceneTree

const RUTA := "res://datos/entrada49.json"

var pasadas := 0
var fallos := 0


func _init() -> void:
	var datos_var: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA))
	comprobar("el catálogo carga", datos_var is Dictionary, true)
	var datos: Dictionary = datos_var if datos_var is Dictionary else {}

	var analisis := Entrada49.analizar_fuentes(datos)
	comprobar("hay tres fuentes", analisis.get("fuentes_validas"), 3)
	comprobar("conserva 48 trabajadores", analisis.get("trabajadores"), 48)
	comprobar("conserva 49 raciones", analisis.get("raciones"), 49)
	comprobar("detecta patrón 48/49", analisis.get("patron_48_49"), true)
	comprobar("las tres fuentes discrepan", analisis.get("discrepancias", []).size(), 3)

	for decision in Entrada49.DECISIONES:
		var resultado := Entrada49.procesar_importacion(datos, decision)
		comprobar("%s es válida" % decision, resultado.get("ok"), true)
		comprobar(
			"%s conserva el registro extra" % decision,
			resultado.get("registro_id"),
			Entrada49.REGISTRO_EXTRA
		)
		var eco: Dictionary = resultado.get("eco_onirico", {})
		comprobar("%s deja eco" % decision, not eco.is_empty(), true)
		comprobar(
			"%s no confirma metafísica" % decision,
			eco.get("afirmacion_metafisica"),
			false
		)

	var borrado := Entrada49.procesar_importacion(datos, "borrar")
	comprobar("borrar provoca reaparición", borrado.get("reaparece"), true)
	var investigar := Entrada49.procesar_importacion(datos, "investigar")
	comprobar(
		"investigar abre compañero",
		investigar.get("desbloqueos", []).has("preguntar_companero"),
		true
	)
	var invalida := Entrada49.procesar_importacion(datos, "adorar")
	comprobar("rechaza decisión inventada", invalida.get("ok"), false)

	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO %s\n  esperado: %s\n  obtenido: %s" % [nombre, esperado, obtenido])
