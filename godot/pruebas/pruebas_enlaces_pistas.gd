## Regresión de #796: todas las pistas declaradas en los expedientes deben
## conservar un enlace activo, tanto antes como después de descubrirse.
##
## Se ejecuta de forma independiente desde scripts/verificar_godot.py para
## recorrer el catálogo real completo, no una muestra construida a mano.
extends SceneTree

var fallos := 0
var pasadas := 0


func _init() -> void:
	var contenido := Contenido.new()
	comprobar("el catálogo de expedientes carga", contenido.cargar(), true)

	var total := 0
	for caso in contenido.casos:
		for registro in caso.get("registros", []):
			var pistas := contenido.pistas_de_registro(caso, String(registro.get("id", "")))
			if pistas.is_empty():
				continue

			var sin_descubrir := BBCode.render(Marcas.de_registro(registro, pistas, []))
			for pista in pistas:
				total += 1
				var id := String(pista.get("id", ""))
				var prefijo := "%s / %s / %s" % [caso.get("id", "?"), registro.get("folio", "?"), id]
				var gatillo = pista.get("fraseGatillo")

				comprobar(prefijo + ": tiene frase gatillo", gatillo != null, true)
				if gatillo == null:
					continue
				comprobar(
					prefijo + ": la frase existe en el folio",
					String(registro.get("contenido", "")).find(String(gatillo)) >= 0,
					true
				)

				var meta := "[url=pista:%s underline=hover]" % id
				comprobar(prefijo + ": enlace activo sin descubrir", sin_descubrir.contains(meta), true)

				var descubierta := BBCode.render(Marcas.de_registro(registro, pistas, [id]))
				comprobar(prefijo + ": enlace activo ya descubierta", descubierta.contains(meta), true)
				comprobar(
					prefijo + ": estado visual de descubierta",
					descubierta.contains("[bgcolor=#c8c800]"),
					true
				)

	comprobar("el recorrido cubre las 47 pistas del catálogo", total, 47)
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO %s\n  esperado: %s\n  obtenido: %s" % [nombre, esperado, obtenido])
