extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_gate_y_semilla()
	_probar_vigilia_deliberada()
	_probar_rutas_climaticas()
	_probar_controles_climaticos_interactivos()
	_probar_niebla_tormenta_y_retorno()
	_probar_pack_visual_integrado()
	_probar_accesibilidad_y_reproduccion()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_gate_y_semilla() -> void:
	var jornada := {"dia": 11}
	_comprobar(not SuenoMari.puede_entrar(jornada), "sin semilla Mari no entra")
	_comprobar(
		not SuenoMari.registrar_semilla(jornada, 1, true, true),
		"una inspección no basta",
	)
	_comprobar(
		not SuenoMari.registrar_semilla(jornada, 2, false, true),
		"folleto sin desplegar no activa",
	)
	_comprobar(
		not SuenoMari.registrar_semilla(jornada, 2, true, false),
		"sin seguir la ruta no activa",
	)
	_comprobar(
		SuenoMari.registrar_semilla(jornada, 2, true, true),
		"interacción completa registra semilla",
	)
	_comprobar(SuenoMari.puede_entrar(jornada), "semilla común habilita familia")
	_comprobar(SemillasOniricas.familias_activas(jornada), ["mari"], "Mari usa catálogo común")
	var entrada: Dictionary = SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_mari"]
	_comprobar(entrada["fuentes"], ["folleto:cuevas_montana_98"], "procedencia estable")
	_comprobar(entrada["intensidad"], 2, "intensidad declarada conservada")
	jornada["dia"] = 12
	_comprobar(not SuenoMari.puede_entrar(jornada), "semilla no cruza de jornada")


func _probar_vigilia_deliberada() -> void:
	var jornada := {"dia": 4}
	var folleto := MariVigilia.new()
	get_root().add_child(folleto)
	folleto.configurar(jornada)
	_comprobar(not folleto.esta_activada(), "folleto presente no activa solo")
	folleto.examinar()
	_comprobar(folleto.inspecciones(), 1, "primera lectura cuenta")
	_comprobar(not folleto.esta_activada(), "primera lectura no activa")
	folleto.examinar()
	_comprobar(folleto.inspecciones(), 2, "segunda lectura completa inspección")
	_comprobar(not folleto.esta_desplegado(), "leer no equivale a desplegar")
	folleto.examinar()
	_comprobar(folleto.esta_desplegado(), "tercera interacción despliega folleto")
	_comprobar(not folleto.ruta_trazada(), "desplegar no equivale a seguir ruta")
	_comprobar(not folleto.esta_activada(), "desplegar aún no activa")
	folleto.examinar()
	_comprobar(folleto.ruta_trazada(), "cuarta interacción sigue ruta")
	_comprobar(folleto.esta_activada(), "seguir ruta activa semilla")
	var intensidad := int(
		SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_mari"]["intensidad"]
	)
	folleto.examinar()
	_comprobar(
		SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_mari"]["intensidad"],
		intensidad,
		"misma fuente es idempotente",
	)
	folleto.queue_free()


func _probar_rutas_climaticas() -> void:
	var sueno := SuenoMari.new()
	get_root().add_child(sueno)
	sueno.preparar()
	_comprobar(sueno.clima_actual(), SuenoMari.CLIMA_CALMA, "empieza en calma")
	var inicial := sueno.rutas_disponibles()
	_comprobar(inicial[SuenoMari.RUTA_RETORNO], "retorno abierto desde inicio")
	_comprobar(not inicial[SuenoMari.RUTA_CAUCE], "cauce cerrado en calma")
	_comprobar(not inicial[SuenoMari.RUTA_CORNISA], "cornisa cerrada en calma")
	_comprobar(not inicial[SuenoMari.RUTA_CUEVA], "cueva cerrada en calma")

	var lluvia := sueno.aplicar_accion("abrir_compuerta")
	_comprobar(lluvia["ok"], "compuerta es acción válida")
	_comprobar(lluvia["clima"], SuenoMari.CLIMA_LLUVIA, "compuerta provoca lluvia")
	_comprobar(lluvia["rutas"][SuenoMari.RUTA_CAUCE], "lluvia revela cauce")
	_comprobar(not lluvia["rutas"][SuenoMari.RUTA_CORNISA], "lluvia no inventa cornisa")

	var viento := sueno.aplicar_accion("abrir_conducto")
	_comprobar(viento["clima"], SuenoMari.CLIMA_VIENTO, "conducto provoca viento")
	_comprobar(viento["rutas"][SuenoMari.RUTA_CORNISA], "viento habilita cornisa")
	_comprobar(not viento["rutas"][SuenoMari.RUTA_CAUCE], "viento retira lectura del cauce")
	_comprobar(
		sueno.get_node("IndiciosClimaticos/HojasViento").visible,
		"hojas dan feedback espacial al viento",
	)

	var invalida := sueno.aplicar_accion("esperar_aleatoriamente")
	_comprobar(not invalida["ok"], "no existe espera aleatoria como regla")
	_comprobar(invalida["clima"], SuenoMari.CLIMA_VIENTO, "acción inválida no cambia estado")
	_comprobar(invalida["retorno_disponible"], "acción inválida conserva retorno")
	sueno.queue_free()


func _probar_controles_climaticos_interactivos() -> void:
	var sueno := SuenoMari.new()
	get_root().add_child(sueno)
	sueno.preparar()
	var actor := Node.new()
	get_root().add_child(actor)

	var compuerta := (
		sueno.get_node_or_null("ControlesClimaticos/CompuertaLluvia") as Interactuable3D
	)
	_comprobar(compuerta != null, "la compuerta climática existe en el mundo")
	_comprobar(compuerta.interactuar(actor), "la compuerta usa el contrato Interactuable3D")
	_comprobar(
		sueno.clima_actual(), SuenoMari.CLIMA_LLUVIA, "interactuar con compuerta provoca lluvia"
	)
	_comprobar(
		sueno.rutas_disponibles()[SuenoMari.RUTA_CAUCE],
		"la interacción real revela el cauce",
	)

	var conducto := sueno.get_node_or_null("ControlesClimaticos/ConductoViento") as Interactuable3D
	_comprobar(conducto != null, "el conducto de viento existe en el mundo")
	_comprobar(conducto.interactuar(actor), "el conducto se activa por interacción 3D")
	_comprobar(
		sueno.clima_actual(), SuenoMari.CLIMA_VIENTO, "interactuar con conducto provoca viento"
	)
	_comprobar(
		sueno.rutas_disponibles()[SuenoMari.RUTA_CORNISA],
		"la interacción real habilita la cornisa",
	)

	var refugio := sueno.get_node_or_null("ControlesClimaticos/RefugioTormenta") as Interactuable3D
	_comprobar(refugio != null, "el refugio de tormenta existe en el mundo")
	refugio.interactuar(actor)
	_comprobar(sueno.clima_actual(), SuenoMari.CLIMA_TORMENTA, "refugiarse materializa la tormenta")
	_comprobar(
		sueno.rutas_disponibles()[SuenoMari.RUTA_CUEVA],
		"la tormenta abierta por interacción habilita la cueva",
	)

	actor.queue_free()
	sueno.queue_free()


func _probar_niebla_tormenta_y_retorno() -> void:
	var sueno := SuenoMari.new()
	get_root().add_child(sueno)
	sueno.preparar()
	var niebla := sueno.aplicar_accion("cerrar_conducto")
	_comprobar(niebla["clima"], SuenoMari.CLIMA_NIEBLA, "cerrar conducto produce niebla")
	_comprobar(not niebla["referencias"]["lejana"], "niebla oculta referencia lejana")
	_comprobar(niebla["referencias"]["cercana"], "niebla conserva referencia cercana")
	_comprobar(niebla["retorno_disponible"], "niebla conserva salida")
	_comprobar(
		sueno.get_node("IndiciosClimaticos/BalizaCercana").visible,
		"baliza cercana sigue visible físicamente",
	)

	var tormenta := sueno.aplicar_accion("refugiarse")
	_comprobar(tormenta["clima"], SuenoMari.CLIMA_TORMENTA, "refugiarse dispara frente de tormenta")
	_comprobar(tormenta["rutas"][SuenoMari.RUTA_CAUCE], "tormenta conserva cauce")
	_comprobar(tormenta["rutas"][SuenoMari.RUTA_CORNISA], "tormenta conserva cornisa")
	_comprobar(tormenta["rutas"][SuenoMari.RUTA_CUEVA], "tormenta abre boca de cueva")
	_comprobar(tormenta["retorno_disponible"], "tormenta nunca cierra única salida")
	_comprobar(sueno.get_node_or_null("VolumenCueva") != null, "hay volumen de cueva 3D")
	_comprobar(
		sueno.get_node_or_null("ArquitecturaCotidiana/Archivador1") != null,
		"cueva comparte escena con arquitectura cotidiana",
	)
	_comprobar(
		sueno.get_node("IndiciosClimaticos/PresenciaPaisaje").visible,
		"presencia se expresa por paisaje y no NPC",
	)
	sueno.queue_free()


func _probar_pack_visual_integrado() -> void:
	var sueno := SuenoMari.new()
	get_root().add_child(sueno)
	sueno.preparar()

	var portal := sueno.get_node_or_null("ArteMari/PortalCuevaArte") as MeshInstance3D
	var estratos := sueno.get_node_or_null("ArteMari/EstratosMontanaArte") as MeshInstance3D
	var frente := sueno.get_node_or_null("ArteMari/FrenteTormentaArte") as Sprite3D
	var cauce := sueno.get_node_or_null("ArteMari/CauceAguaArte") as Sprite3D
	_comprobar(portal != null and portal.mesh != null, "asset OBJ de boca de cueva está montado")
	_comprobar(estratos != null and estratos.mesh != null, "asset OBJ de estratos está montado")
	_comprobar(frente != null and frente.texture != null, "asset SVG de tormenta está montado")
	_comprobar(cauce != null and cauce.texture != null, "asset SVG de cauce está montado")
	_comprobar(not portal.visible, "boca de cueva artística empieza cerrada")
	_comprobar(not cauce.visible, "cauce artístico empieza oculto")

	sueno.aplicar_accion("abrir_compuerta")
	_comprobar(cauce.visible, "lluvia revela el cauce artístico")
	_comprobar(not portal.visible, "lluvia no abre la boca de cueva artística")

	sueno.aplicar_accion("refugiarse")
	_comprobar(portal.visible, "tormenta abre la boca de cueva artística")
	_comprobar(frente.visible, "tormenta muestra el frente visual del pack")
	sueno.queue_free()


func _probar_accesibilidad_y_reproduccion() -> void:
	var sueno := SuenoMari.new()
	get_root().add_child(sueno)
	sueno.preparar()
	var normal := sueno.aplicar_accion("abrir_compuerta", false)
	_comprobar(normal["modo"], "fundido_climatico", "presentación normal usa transición breve")
	_comprobar(normal["duracion"], 0.24, "transición normal está acotada")
	_comprobar(normal["particulas"], "modo normal puede usar partículas")
	_comprobar(not normal["mover_camara"], "clima no exige mover cámara")
	_comprobar(not normal["flash"], "clima no exige flashes")

	var reducida := sueno.aplicar_accion("refugiarse", true)
	_comprobar(reducida["modo"], "corte_fundido", "reducción de movimiento usa corte/fundido")
	_comprobar(reducida["duracion"], 0.0, "reducción no interpola")
	_comprobar(not reducida["particulas"], "reducción desactiva partículas")
	_comprobar(reducida["rutas"][SuenoMari.RUTA_CUEVA], "reducción conserva regla de rutas")
	_comprobar(reducida["retorno_disponible"], "reducción conserva retorno")

	var guardado := sueno.estado_reproducible()
	var copia := SuenoMari.new()
	get_root().add_child(copia)
	copia.preparar()
	copia.restaurar_estado(guardado)
	_comprobar(copia.estado_reproducible(), guardado, "clima se reproduce exactamente")
	_comprobar(
		copia.rutas_disponibles(), sueno.rutas_disponibles(), "mismas rutas para mismo estado"
	)
	copia.restaurar_estado({"clima": "inventado"})
	_comprobar(copia.clima_actual(), SuenoMari.CLIMA_CALMA, "estado inválido vuelve a calma segura")
	_comprobar(copia.ruta_retorno_disponible(), "restauración inválida conserva salida")
	sueno.queue_free()
	copia.queue_free()


func _comprobar(actual, esperado = true, nombre: String = "") -> void:
	if typeof(esperado) == TYPE_STRING and nombre.is_empty():
		nombre = String(esperado)
		esperado = true
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Mari: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
