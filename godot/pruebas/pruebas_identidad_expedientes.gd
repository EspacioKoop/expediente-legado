extends SceneTree

const RUTA_IDENTIDADES := "res://datos/identidad_expedientes.json"

var pasadas := 0
var fallos := 0


func _init() -> void:
	var contenido := Contenido.new()
	comprobar("el catálogo de casos carga", contenido.cargar(), true)

	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_IDENTIDADES))
	comprobar("la identidad visual es un diccionario", datos is Dictionary, true)
	var catalogo: Dictionary = datos if datos is Dictionary else {}
	comprobar("hay una identidad por expediente", catalogo.size(), contenido.casos.size())

	for caso in contenido.casos:
		var caso_id := String(caso.get("id", ""))
		var valor: Variant = catalogo.get(caso_id, {})
		var identidad: Dictionary = valor if valor is Dictionary else {}
		comprobar("%s tiene identidad" % caso_id, not identidad.is_empty(), true)
		comprobar(
			"%s tiene código" % caso_id, not String(identidad.get("codigo", "")).is_empty(), true
		)

		var ruta := String(identidad.get("icono", ""))
		var existe := not ruta.is_empty() and ResourceLoader.exists(ruta)
		comprobar("%s tiene icono importable" % caso_id, existe, true)
		var textura: Variant = load(ruta) if existe else null
		comprobar("%s carga como textura" % caso_id, textura is Texture2D, true)

	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO %s\n  esperado: %s\n  obtenido: %s" % [nombre, esperado, obtenido])
