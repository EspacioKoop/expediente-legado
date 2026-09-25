extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_gate_y_semilla()
	_probar_vigilia_activa()
	_probar_puzzle_reversible()
	_probar_transformacion_y_accesibilidad()
	_probar_vertical_3d()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_gate_y_semilla() -> void:
	var jornada := {"dia": 8}
	_comprobar(not SuenoGilgamesh.puede_entrar(jornada), "sin semilla Gilgamesh no entra")
	_comprobar(
		not SuenoGilgamesh.registrar_semilla(jornada, 2, true),
		"dos páginas no bastan aunque se marque la tablilla",
	)
	_comprobar(
		not SuenoGilgamesh.registrar_semilla(jornada, 3, false),
		"tres páginas sin examinar la tablilla no bastan",
	)
	_comprobar(
		SuenoGilgamesh.registrar_semilla(jornada, 3, true),
		"tres páginas y tablilla observada registran la semilla",
	)
	_comprobar(SuenoGilgamesh.puede_entrar(jornada), "la semilla común habilita la familia")
	var semillas := SemillasOniricas.obtener_semillas(jornada)
	_comprobar(
		semillas.has("semilla_onirica_gilgamesh"),
		"la clave persistida es semilla_onirica_gilgamesh",
	)
	_comprobar(
		semillas["semilla_onirica_gilgamesh"]["fuentes"],
		["libro:arqueologia_uruk_98"],
		"la fuente de vigilia queda registrada",
	)
	_comprobar(
		SemillasOniricas.seleccionar_para_noche(jornada, 436, 1)["familias"],
		["gilgamesh"],
		"con Gilgamesh como única semilla la selección nocturna es Gilgamesh",
	)

	jornada["dia"] = 9
	_comprobar(
		not SuenoGilgamesh.puede_entrar(jornada),
		"la semilla no se arrastra a la jornada siguiente",
	)


func _probar_vigilia_activa() -> void:
	var jornada := {"dia": 4}
	var libro := GilgameshVigilia.new()
	get_root().add_child(libro)
	libro.configurar(jornada)
	_comprobar(not libro.esta_activada(), "el objeto presente no activa el sueño")
	_comprobar(libro.paginas_examinadas(), 0, "el libro empieza sin páginas examinadas")

	libro.examinar()
	libro.examinar()
	_comprobar(libro.paginas_examinadas(), 2, "dos interacciones avanzan dos páginas")
	_comprobar(not libro.esta_activada(), "dos interacciones siguen sin activar")

	libro.examinar()
	_comprobar(libro.paginas_examinadas(), 3, "la tercera interacción alcanza la reproducción")
	_comprobar(
		not libro.tablilla_observada(), "alcanzar la página no equivale a examinar la tablilla"
	)
	_comprobar(not libro.esta_activada(), "la mera aparición de la reproducción no activa")

	libro.examinar()
	_comprobar(libro.tablilla_observada(), "la cuarta interacción examina la reproducción")
	_comprobar(libro.esta_activada(), "la interacción completa activa la semilla")
	_comprobar(
		SemillasOniricas.familias_activas(jornada),
		["gilgamesh"],
		"la vigilia usa el contrato común y no un booleano paralelo",
	)
	var intensidad: int = int(
		SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_gilgamesh"]["intensidad"]
	)
	libro.examinar()
	_comprobar(
		SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_gilgamesh"]["intensidad"],
		intensidad,
		"reexaminar la misma fuente es idempotente",
	)
	libro.queue_free()


func _probar_puzzle_reversible() -> void:
	var estado := {}
	var invalida := (
		SuenoGilgamesh
		. evaluar_colocacion(
			estado,
			"fragmento_puerta",
			"ancla_ola",
		)
	)
	_comprobar(not invalida["aceptada"], "una pareja visual incorrecta se rechaza")
	_comprobar(invalida["revertir"], "una pareja incorrecta pide reversión")
	_comprobar(invalida["estado"].is_empty(), "el error no consume progreso")

	var ids: Array = SuenoGilgamesh.ENCAJES.keys()
	ids.sort()
	for fragmento in ids:
		var resultado := (
			SuenoGilgamesh
			. evaluar_colocacion(
				estado,
				fragmento,
				SuenoGilgamesh.ENCAJES[fragmento],
			)
		)
		_comprobar(resultado["aceptada"], "%s acepta su ancla visual" % fragmento)
		_comprobar(not resultado["revertir"], "%s no revierte al acertar" % fragmento)
		estado = resultado["estado"]

	_comprobar(estado.size(), 4, "los cuatro fragmentos producen cuatro estados resueltos")
	var final := (
		SuenoGilgamesh
		. evaluar_colocacion(
			estado,
			"fragmento_puerta",
			"ancla_puerta",
		)
	)
	_comprobar(final["completa"], "repetir un acierto no rompe el estado completo")
	_comprobar(final["total"], 4, "repetir un acierto no duplica progreso")


func _probar_transformacion_y_accesibilidad() -> void:
	var normal := SuenoGilgamesh.plan_transformacion(false, 4)
	var reducida := SuenoGilgamesh.plan_transformacion(true, 4)
	_comprobar(
		normal["transformacion_final"],
		"muralla_archivo_continua_por_techo",
		"resolver dispara la transformación imposible declarada",
	)
	_comprobar(
		reducida["transformacion_final"],
		normal["transformacion_final"],
		"reducción de movimiento conserva el resultado lógico",
	)
	_comprobar(normal["modo"], "interpolacion_arquitectura", "modo normal interpola arquitectura")
	_comprobar(reducida["modo"], "corte_fundido", "modo reducido usa sustitución discreta")
	_comprobar(not normal["sacudida_camara"], "el modo normal no sacude cámara")
	_comprobar(not reducida["sacudida_camara"], "el modo reducido no sacude cámara")
	_comprobar(not reducida["desplazar_camara"], "el modo reducido no desplaza cámara")
	_comprobar(reducida["duracion"], 0.0, "el cambio reducido no anima geometría")


func _probar_vertical_3d() -> void:
	var sueno := SuenoGilgamesh.new()
	get_root().add_child(sueno)
	# SceneTree._initialize() corre antes del primer ciclo de lifecycle. Ejecutamos
	# _ready de forma explícita para validar el mismo montaje que usa la escena real.
	sueno._ready()
	_comprobar(sueno.get_node_or_null("CiudadImposible") != null, "la escena monta una ciudad 3D")
	_comprobar(
		sueno.get_node_or_null("CiudadImposible/MurallaVertical") != null,
		"la ciudad incluye muralla/archivo vertical",
	)
	_comprobar(
		sueno.get_node_or_null("CiudadImposible/HitosUruk/ZiguratArchivo") != null,
		"la ciudad incluye un zigurat/archivo escalonado reconocible",
	)
	_comprobar(
		sueno.get_node_or_null("CiudadImposible/HitosUruk/PuertaMonumentalArchivo") != null,
		"la ciudad incluye una puerta monumental propia",
	)
	_comprobar(
		sueno.get_node_or_null("CiudadImposible/HitosUruk/InundacionVertical") != null,
		"el agua imposible asciende por la pared",
	)
	_comprobar(
		sueno.get_node_or_null("CiudadImposible/HitosUruk/SellosCelestes") != null,
		"los sellos suspendidos refuerzan la hibridacion SIGA",
	)
	var techo := sueno.get_node_or_null("CiudadImposible/MurallaArchivoTecho") as Node3D
	_comprobar(techo != null, "existe la continuidad imposible por el techo")
	_comprobar(not techo.visible, "la continuidad cenital empieza oculta")
	var puzzle := sueno.get_node_or_null("CiudadImposible/PuzzleTablilla") as Node3D
	_comprobar(puzzle != null, "el puzzle vive dentro de la escena 3D y no en HUD")

	var ids: Array = SuenoGilgamesh.ENCAJES.keys()
	ids.sort()
	for fragmento in ids:
		var pieza := puzzle.get_node(fragmento) as MeshInstance3D
		var ancla_id := String(SuenoGilgamesh.ENCAJES[fragmento])
		var ancla := puzzle.get_node(ancla_id) as MeshInstance3D
		var motivo_pieza := pieza.get_node_or_null("MotivoVisual") as MeshInstance3D
		var motivo_ancla := ancla.get_node_or_null("MotivoVisual") as MeshInstance3D
		_comprobar(motivo_pieza != null, "%s lleva su motivo visual propio" % fragmento)
		_comprobar(motivo_ancla != null, "%s comparte motivo con su ancla" % fragmento)
		var resultado := (
			sueno
			. colocar_fragmento(
				fragmento,
				ancla_id,
				true,
			)
		)
		_comprobar(resultado["aceptada"], "la instancia acepta %s" % fragmento)
		_comprobar(not pieza.visible, "%s desaparece al resolverse" % fragmento)
		_comprobar(
			motivo_pieza.get_parent() == pieza,
			"%s mantiene el motivo ligado a la pieza que gobierna su visibilidad" % fragmento,
		)

	_comprobar(sueno.resuelto(), "los cuatro aciertos resuelven la instancia")
	_comprobar(techo.visible, "resolver revela la muralla que continúa por el techo")
	var puerta := sueno.get_node("CiudadImposible/PuertaBloqueada") as MeshInstance3D
	var ruta := sueno.get_node("CiudadImposible/RutaFinal") as MeshInstance3D
	_comprobar(not puerta.visible, "resolver retira el bloqueo de salida")
	_comprobar(ruta.visible, "resolver abre una ruta visible")
	_comprobar(techo.scale, Vector3.ONE, "reducción de movimiento aplica el techo sin tween")
	sueno.queue_free()


func _comprobar(actual, esperado = true, nombre: String = "") -> void:
	if typeof(esperado) == TYPE_STRING and nombre.is_empty():
		nombre = String(esperado)
		esperado = true
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Gilgamesh: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
