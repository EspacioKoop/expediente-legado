extends SceneTree

const AquilesVigiliaScript := preload("res://guion/aquiles_vigilia.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_contrato_canonico()
	_probar_interaccion_deliberada()
	_probar_cambio_de_dia()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_contrato_canonico() -> void:
	var jornada := {"dia": 4}
	_comprobar(not SuenoAquiles.puede_entrar(jornada), "Aquiles empieza bloqueado")
	_comprobar(
		not SuenoAquiles.registrar_semilla(jornada, 0, true),
		"mirar el talón sin manipular no activa",
	)
	_comprobar(
		not SuenoAquiles.registrar_semilla(jornada, 1, false),
		"manipular sin observar el talón no activa",
	)
	_comprobar(
		SemillasOniricas.obtener_semillas(jornada).is_empty(),
		"los intentos incompletos no escriben semillas",
	)

	_comprobar(
		SuenoAquiles.registrar_semilla(jornada, 1, true),
		"la interacción completa registra la semilla",
	)
	var semillas := SemillasOniricas.obtener_semillas(jornada)
	var clave := SemillasOniricas.clave("aquiles")
	_comprobar(semillas.has(clave), "usa la clave canónica de SemillasOniricas")
	_comprobar(semillas[clave]["id_mito"] == "aquiles", "la familia guardada es Aquiles")
	_comprobar(
		semillas[clave]["fuentes"] == [SuenoAquiles.FUENTE_VIGILIA],
		"la fuente de vigilia queda trazable",
	)
	_comprobar(semillas[clave]["intensidad"] == 2, "la estampa aporta intensidad declarada")
	_comprobar(SuenoAquiles.puede_entrar(jornada), "la familia queda habilitada")
	_comprobar(
		SemillasOniricas.seleccionar_para_noche(jornada, 438)["familias"] == ["aquiles"],
		"si Aquiles es la única semilla la selección común lo elige",
	)


func _probar_interaccion_deliberada() -> void:
	var jornada := {"dia": 8}
	var estampa := AquilesVigiliaScript.new()
	root.add_child(estampa)
	estampa.configurar(jornada)

	_comprobar(
		estampa.get_node_or_null("LaminaAquiles") != null,
		"la estampa tiene lámina física",
	)
	_comprobar(
		estampa.get_node_or_null("ColisionEstampaAquiles") != null,
		"la estampa expone una colisión interactiva",
	)
	_comprobar(estampa.texto_accion() == "Examinar estampa de Aquiles", "prompt semántico")
	_comprobar(
		SemillasOniricas.obtener_semillas(jornada).is_empty(),
		"existir en la escena no activa la semilla",
	)
	_comprobar(not estampa.observar_talon(), "mirar el talón antes de girar no cuenta")
	_comprobar(estampa.interactuar(root), "examinar acepta la interacción común")
	_comprobar(
		estampa.giro_acumulado() >= AquilesVigiliaScript.GIRO_MINIMO_OBSERVACION,
		"examinar cambia el ángulo lo suficiente",
	)
	_comprobar(
		SemillasOniricas.obtener_semillas(jornada).is_empty(),
		"girar sin observar todavía no activa",
	)
	_comprobar(estampa.observar_talon(), "tras girar sí se puede observar el talón")
	_comprobar(estampa.talon_observado(), "la observación queda registrada localmente")
	_comprobar(estampa.esta_activada(), "la secuencia completa activa la fuente")
	_comprobar(SuenoAquiles.puede_entrar(jornada), "el sueño ve la semilla canónica")

	var semillas := SemillasOniricas.obtener_semillas(jornada)
	var clave := SemillasOniricas.clave("aquiles")
	var intensidad_antes := int(semillas[clave]["intensidad"])
	estampa.interactuar(root)
	estampa.observar_talon()
	semillas = SemillasOniricas.obtener_semillas(jornada)
	_comprobar(
		int(semillas[clave]["intensidad"]) == intensidad_antes,
		"repetir la misma fuente es idempotente",
	)
	estampa.queue_free()


func _probar_cambio_de_dia() -> void:
	var jornada := {"dia": 2}
	SuenoAquiles.registrar_semilla(jornada, 1, true)
	_comprobar(SuenoAquiles.puede_entrar(jornada), "la semilla vive durante su día")
	jornada["dia"] = 3
	_comprobar(not SuenoAquiles.puede_entrar(jornada), "no se arrastra al día siguiente")


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Aquiles vigilia: " + nombre)
