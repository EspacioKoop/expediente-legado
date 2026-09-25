## Contrato de los ecos del día en el sueño: vuelve de noche quien te ha dado
## conversación hoy, con su cara, su luz y una voz soñada; nadie de otros días;
## y siempre en un sitio de la sala donde se le encuentra sin tenerlo encima.
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	TranslationServer.set_locale("es")
	_probar_registro()
	_probar_reparto()
	_probar_textos()
	_probar_sitio_en_rejilla()
	_probar_sitio_poligonal()
	await _probar_montaje()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_registro() -> void:
	var jornada := {"dia": 4}
	_comprobar(EcosSueno.registrar(jornada, "paco"), "registra a Paco")
	EcosSueno.registrar(jornada, "kike")
	EcosSueno.registrar(jornada, "paco")
	_comprobar(EcosSueno.hablados_hoy(jornada) == ["paco", "kike"], "en orden y sin repetir")
	_comprobar(not EcosSueno.registrar(jornada, "fantasma"), "no registra a desconocidos")
	# Al día siguiente la huella ya no vale, y el primer registro la reinicia.
	jornada["dia"] = 5
	_comprobar(EcosSueno.hablados_hoy(jornada).is_empty(), "no hereda días viejos")
	EcosSueno.registrar(jornada, "remedios")
	_comprobar(EcosSueno.hablados_hoy(jornada) == ["remedios"], "cada día empieza de cero")
	# Un guardado editado a mano no mete a nadie.
	var rota := {"dia": 5, EcosSueno.CLAVE: {"dia": 5, "personas": ["remedios", 7, "nadie"]}}
	_comprobar(EcosSueno.hablados_hoy(rota) == ["remedios"], "ignora ids que no existen")
	_comprobar(
		EcosSueno.hablados_hoy({"dia": 5, EcosSueno.CLAVE: "basura"}).is_empty(),
		"ignora una huella con forma rota"
	)


func _probar_reparto() -> void:
	var jornada := {"dia": 2}
	EcosSueno.registrar(jornada, "remedios")
	EcosSueno.registrar(jornada, "julian")
	var salas := []
	for quedan in [2, 1, 0]:
		salas.append(EcosSueno.de_sala(jornada, quedan)["id"])
	_comprobar(salas == ["remedios", "julian", "remedios"], "rota por sala (%s)" % [salas])
	var frases := []
	for quedan in [2, 0]:
		frases.append(EcosSueno.de_sala(jornada, quedan)["frase"])
	_comprobar(
		frases[0] != frases[1] and String(frases[0]).begins_with("DEPEND_REMEDIOS_SUENO_"),
		"la misma persona no repite frase en la noche (%s)" % [frases]
	)

	# Sin nadie con quien hayas hablado: un desconocido solo en la última sala.
	var sola := {"dia": 3}
	_comprobar(EcosSueno.de_sala(sola, 2).is_empty(), "sin charlas, las primeras salas vacías")
	var ultima := EcosSueno.de_sala(sola, 0)
	_comprobar(
		String(ultima.get("frase", "")).ends_with("_SUENO_EXTRANO"),
		"sin charlas, la última sala trae a alguien que no te conoce"
	)


func _probar_textos() -> void:
	for dependiente in DependientesTiendas.todos():
		for clave in EcosSueno.claves(dependiente):
			_comprobar(TranslationServer.translate(clave) != clave, "%s tiene texto" % clave)
			# La voz soñada no es la de día: ninguna frase se repite.
			for diurna in DependientesTiendas.claves(dependiente):
				if TranslationServer.translate(diurna) == TranslationServer.translate(clave):
					_comprobar(false, "%s repite %s" % [clave, diurna])


func _probar_sitio_en_rejilla() -> void:
	var bloques := [Rect2i(0, 0, 8, 6)]
	var entrada := Planta.centro_en_metros(bloques, Vector2i(0, 0))
	var salida := Planta.centro_en_metros(bloques, Vector2i(7, 5))
	var figura := Planta.centro_en_metros(bloques, Vector2i(7, 0))
	var espacio := {
		"planta": bloques,
		"entrada": entrada,
		"salidas": [{"pos": salida}],
		"figuras": [{"pos": figura}],
	}
	var sitio := EcosSueno3D.sitio(espacio)
	for otro in [entrada, salida, figura]:
		_comprobar(
			Vector2(sitio.x - otro.x, sitio.z - otro.z).length() > 3.0,
			"en rejilla, lejos de entrada, salida y figuras (%s frente a %s)" % [sitio, otro]
		)
	_comprobar(sitio.y == 0.0, "a ras de suelo")


func _probar_sitio_poligonal() -> void:
	# El contorno de la sala real que lo destapó: sin salidas ni figuras, el
	# eco caía justo en la entrada, dentro del jugador.
	var contorno := [
		Vector2(-16, -15),
		Vector2(4, -17),
		Vector2(13, -9),
		Vector2(10, 3),
		Vector2(16, 12),
		Vector2(1, 17),
		Vector2(-13, 12),
		Vector2(-9, 1),
	]
	var entrada := Vector3(-10, 0, -10)
	var espacio := {"contorno": contorno, "planta": [], "entrada": entrada, "salidas": []}
	var sitio := EcosSueno3D.sitio(espacio)
	var plano := Vector2(sitio.x, sitio.z)
	_comprobar(
		Geometry2D.is_point_in_polygon(plano, PackedVector2Array(contorno)),
		"poligonal: dentro de la sala"
	)
	var distancia := plano.distance_to(Vector2(entrada.x, entrada.z))
	_comprobar(
		distancia > 4.0 and distancia < 10.0,
		"poligonal: a la vista pero no encima (%.1f m)" % distancia
	)
	# Con la salida justo donde caería, se aparta.
	espacio["salidas"] = [{"pos": sitio}]
	var otro := EcosSueno3D.sitio(espacio)
	_comprobar(
		Vector2(otro.x, otro.z).distance_to(plano) > 1.0, "poligonal: no se pone en la salida"
	)


func _probar_montaje() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	var jornada := {"dia": 6, "sueno_escenas": ["a", "b"]}
	var espacio := {"planta": [Rect2i(0, 0, 6, 6)], "entrada": Vector3.ZERO, "salidas": []}
	_comprobar(
		EcosSueno3D.montar(mundo, espacio, jornada) == null,
		"sin charlas y sin ser la última, nadie"
	)
	EcosSueno.registrar(jornada, "julian")
	var charla := EcosSueno3D.montar(mundo, espacio, jornada)
	await process_frame
	_comprobar(charla != null, "con charla, eco")
	if charla == null:
		mundo.free()
		return
	var raiz := charla.get_parent() as Node3D
	_comprobar(charla.clave_dialogo.begins_with("DEPEND_JULIAN_SUENO_"), "habla con su voz soñada")
	_comprobar(raiz.get_node_or_null("LuzEco") is OmniLight3D, "trae su luz")
	var pieza := raiz.get_node("Cuerpo").get_child(0) as Node3D
	_comprobar(
		String(pieza.scene_file_path).ends_with("male_adult_08.glb"),
		"con la misma cara que en su tienda"
	)
	var reproductor := Modelos._reproductor(pieza)
	_comprobar(
		reproductor != null and reproductor.speed_scale < 1.0, "se mueve más despacio que de día"
	)
	EcosSueno3D.montar(mundo, espacio, jornada)
	_comprobar(
		mundo.find_children(EcosSueno3D.NOMBRE, "", false, false).size() == 1, "sin duplicar"
	)
	mundo.free()


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO: " + mensaje)
