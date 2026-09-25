extends SceneTree

const IDEOLOGIA_SUENO := preload("res://guion/ideologia_sueno_923.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	_probar_base_intacta()
	_probar_elecciones_deforman_la_misma_familia()
	_probar_exposicion_solo_visual()
	_probar_reproducibilidad()
	_probar_reduccion_movimiento()
	print("ideologia_sueno_923: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _estado() -> Dictionary:
	return {
		"historias_cartas": {},
		Prometeo.CLAVE_ELECCIONES_IDEOLOGICAS: [],
		Prometeo.CLAVE_EXPOSICION_IDEOLOGICA: [],
	}


func _probar_base_intacta() -> void:
	var estado := _estado()
	var modificadores := IDEOLOGIA_SUENO.modificadores(estado, 1, 923, false)
	_comprobar(modificadores.is_empty(), "sin elección ni exposición no hay modificador")

	var mundo := Node3D.new()
	root.add_child(mundo)
	SuenoUtileria.montar(mundo, "crucero", 1, 923, [], ["archivador"], [], modificadores)
	var rima := _primera_rima(mundo)
	_comprobar(rima != null, "el sueño base conserva su rima laberinto")
	if rima != null:
		_comprobar(
			String(rima.get_meta("motivo_simbolico", "")) == "laberinto",
			"la familia base no cambia",
		)
		_comprobar(
			rima.find_child("ModificadorIdeologico", false, false) == null,
			"sin fuente ideológica no aparece estructura adicional",
		)
	mundo.queue_free()


func _probar_elecciones_deforman_la_misma_familia() -> void:
	var reparto := _estado()
	Prometeo.registrar_eleccion_ideologica(
		reparto,
		"fixture:reparto",
		"expediente",
		"comunismo",
		"caso-fixture",
		1,
		["responsabilidad_colectiva", "control_interno"],
	)
	var procedimiento := _estado()
	Prometeo.registrar_eleccion_ideologica(
		procedimiento,
		"fixture:procedimiento",
		"expediente",
		"socialdemocrata",
		"caso-fixture",
		1,
		["garantias_procedimiento", "revision_institucional"],
	)

	var mods_reparto := IDEOLOGIA_SUENO.modificadores(reparto, 1, 923, false)
	var mods_procedimiento := IDEOLOGIA_SUENO.modificadores(procedimiento, 1, 923, false)
	_comprobar(mods_reparto.size() == 1, "una elección semántica produce un modificador")
	_comprobar(mods_procedimiento.size() == 1, "la segunda elección produce un modificador")
	_comprobar(
		String(mods_reparto[0].get("familia", "")) == "reparto",
		"los tags colectivos seleccionan reparto",
	)
	_comprobar(
		String(mods_procedimiento[0].get("familia", "")) == "procedimiento",
		"los tags procedimentales seleccionan capas",
	)
	_comprobar(
		String(mods_reparto[0].get("regla", ""))
		!= String(mods_procedimiento[0].get("regla", "")),
		"dos decisiones pueden producir relaciones estructurales distintas",
	)

	var mundo_reparto := Node3D.new()
	var mundo_procedimiento := Node3D.new()
	root.add_child(mundo_reparto)
	root.add_child(mundo_procedimiento)
	SuenoUtileria.montar(
		mundo_reparto, "crucero", 1, 923, [], ["archivador"], [], mods_reparto
	)
	SuenoUtileria.montar(
		mundo_procedimiento,
		"crucero",
		1,
		923,
		[],
		["archivador"],
		[],
		mods_procedimiento,
	)

	var rima_a := _primera_rima(mundo_reparto)
	var rima_b := _primera_rima(mundo_procedimiento)
	_comprobar(
		rima_a != null and String(rima_a.get_meta("motivo_simbolico", "")) == "laberinto",
		"reparto conserva la misma familia laberinto",
	)
	_comprobar(
		rima_b != null and String(rima_b.get_meta("motivo_simbolico", "")) == "laberinto",
		"procedimiento conserva la misma familia laberinto",
	)
	if rima_a != null and rima_b != null:
		var capa_a := rima_a.find_child("ModificadorIdeologico", false, false) as Node3D
		var capa_b := rima_b.find_child("ModificadorIdeologico", false, false) as Node3D
		_comprobar(capa_a != null and capa_b != null, "ambas decisiones deforman la estructura")
		if capa_a != null and capa_b != null:
			_comprobar(
				String(capa_a.get_meta("regla_modificadora", "")) == "distribuir",
				"reparto usa una relación distribuida",
			)
			_comprobar(
				String(capa_b.get_meta("regla_modificadora", "")) == "capas",
				"procedimiento usa capas sucesivas",
			)
			_comprobar(
				capa_a.find_children("*", "MeshInstance3D", true, false).size()
				!= capa_b.find_children("*", "MeshInstance3D", true, false).size(),
				"la misma base recibe composiciones estructurales distintas",
			)
			_comprobar(
				capa_a.find_children("*", "CollisionShape3D", true, false).is_empty()
				and capa_b.find_children("*", "CollisionShape3D", true, false).is_empty(),
				"el primer vertical no altera colisión ni navegación",
			)
	mundo_reparto.queue_free()
	mundo_procedimiento.queue_free()


func _probar_exposicion_solo_visual() -> void:
	var estado := _estado()
	Prometeo.registrar_exposicion_ideologica(
		estado,
		"tv:fixture",
		"tv:fixture",
		"centrista",
		1,
		["procedimiento", "evaluación"],
	)
	var modificadores := IDEOLOGIA_SUENO.modificadores(estado, 1, 923, false)
	_comprobar(modificadores.size() == 1, "una exposición real puede modular la noche")
	if modificadores.size() == 1:
		_comprobar(
			String(modificadores[0].get("canal", "")) == "exposicion",
			"la exposición conserva su canal",
		)
		_comprobar(
			String(modificadores[0].get("regla", "")).is_empty(),
			"la exposición no se convierte en regla estructural",
		)
		var perfil := SuenoCielos.componer("", modificadores)
		_comprobar(
			float(perfil.get("cirros", 0.0)) != float(SuenoCielos.PERFIL_BASE["cirros"]),
			"la exposición sí puede modificar lenguaje visual",
		)

	var mundo := Node3D.new()
	root.add_child(mundo)
	SuenoUtileria.montar(mundo, "crucero", 1, 923, [], ["archivador"], [], modificadores)
	var rima := _primera_rima(mundo)
	_comprobar(
		rima != null and rima.find_child("ModificadorIdeologico", false, false) == null,
		"consumir medios no fabrica una elección en el espacio",
	)
	mundo.queue_free()

	_comprobar(
		IDEOLOGIA_SUENO.modificadores(estado, 2, 923, false).is_empty(),
		"la exposición del día anterior no se filtra a otra noche",
	)


func _probar_reproducibilidad() -> void:
	var estado := _estado()
	Prometeo.registrar_eleccion_ideologica(
		estado,
		"fixture:a",
		"expediente",
		"comunismo",
		"caso-a",
		1,
		["responsabilidad_colectiva"],
	)
	Prometeo.registrar_eleccion_ideologica(
		estado,
		"fixture:b",
		"expediente",
		"centrista",
		"caso-b",
		1,
		["conciliacion"],
	)
	var a := IDEOLOGIA_SUENO.modificadores(estado, 1, 12345, false)
	var b := IDEOLOGIA_SUENO.modificadores(estado, 1, 12345, false)
	_comprobar(a == b, "mismo estado, día y raíz producen la misma selección")


func _probar_reduccion_movimiento() -> void:
	var estado := _estado()
	Prometeo.registrar_exposicion_ideologica(
		estado,
		"tv:movimiento",
		"tv:fixture",
		"centrista",
		1,
		["procedimiento"],
	)
	var normal := IDEOLOGIA_SUENO.modificadores(estado, 1, 923, false)
	var reducida := IDEOLOGIA_SUENO.modificadores(estado, 1, 923, true)
	_comprobar(
		String(normal[0].get("familia", "")) == String(reducida[0].get("familia", "")),
		"reducir movimiento no cambia la regla o familia seleccionada",
	)
	_comprobar(
		float(reducida[0]["parametros"].get("cirros", 0.0))
			< float(normal[0]["parametros"].get("cirros", 0.0)),
		"reducción de movimiento atenúa únicamente parámetros animados",
	)


func _primera_rima(mundo: Node3D) -> Node3D:
	var capa := mundo.find_child("EspacioSimbolico", false, false) as Node3D
	if capa == null or capa.get_child_count() == 0:
		return null
	return capa.get_child(0) as Node3D


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO #923: " + mensaje)
