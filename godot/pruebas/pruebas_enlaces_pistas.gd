## Regresión de #796: toda pista que tenga frase gatillo debe conservar un
## enlace activo, tanto antes como después de descubrirse. Las pistas sin frase
## no generan un enlace inline; también se recorren para validar su origen.
extends SceneTree

var fallos := 0
var pasadas := 0


func _init() -> void:
	var contenido := Contenido.new()
	comprobar("el catálogo de expedientes carga", contenido.cargar(), true)

	var total := 0
	var enlazables := 0
	var sin_frase := 0
	for caso in contenido.casos:
		for pista in caso.get("pistas", []):
			total += 1
			var id := String(pista.get("id", ""))
			var origen := String(pista.get("registroOrigen", ""))
			var registro := {}
			for candidato in caso.get("registros", []):
				if String(candidato.get("id", "")) == origen:
					registro = candidato
					break

			comprobar(id + ": registro de origen existe", not registro.is_empty(), true)
			if registro.is_empty():
				continue

			var gatillo = pista.get("fraseGatillo")
			if gatillo == null:
				sin_frase += 1
				continue
			enlazables += 1

			var prefijo := "%s / %s / %s" % [caso.get("id", "?"), registro.get("folio", "?"), id]
			comprobar(
				prefijo + ": la frase existe en el folio",
				String(registro.get("contenido", "")).find(String(gatillo)) >= 0,
				true
			)

			var pistas := contenido.pistas_de_registro(caso, origen)
			var meta := "[url=pista:%s]" % id
			var sin_descubrir := BBCode.render(Marcas.de_registro(registro, pistas, []))
			comprobar(
				prefijo + ": enlace activo sin descubrir", sin_descubrir.contains(meta), true
			)

			var descubierta := BBCode.render(Marcas.de_registro(registro, pistas, [id]))
			comprobar(
				prefijo + ": enlace activo ya descubierta", descubierta.contains(meta), true
			)
			comprobar(
				prefijo + ": estado visual de descubierta",
				descubierta.contains("[bgcolor=#c8c800]"),
				true
			)

	comprobar("el recorrido cubre las 47 pistas del catálogo", total, 47)
	comprobar("las 24 pistas con frase son enlazables", enlazables, 24)
	comprobar("las 23 pistas sin frase no se confunden con enlaces", sin_frase, 23)
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO %s\n  esperado: %s\n  obtenido: %s" % [nombre, esperado, obtenido])
