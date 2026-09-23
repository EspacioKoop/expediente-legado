extends SceneTree

var pasadas := 0
var fallos := 0


func _initialize() -> void:
	_probar_lectura_fisica_y_ritual()
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _probar_lectura_fisica_y_ritual() -> void:
	GestorLiteratura.registro_literario = LiteraturaEventos.nuevo()
	GestorLiteratura.obras_conocidas.clear()

	var script_libro = load("res://interactables/libros/libro_lectura_significativa.gd")
	var libro = script_libro.new()
	libro.obra_id = "vida_es_sueno_1635"
	libro.fuente_documental = "biblioteca:edicion_1998:vida_es_sueno"
	libro.pasos_para_completar = 2

	var hojeo: Dictionary = libro.avanzar_lectura(5)
	_comprobar(not bool(hojeo.get("completa", false)), "hojear no completa la obra")
	_comprobar(
		String(hojeo.get("motivo", "")) == "lectura_incompleta",
		"el primer paso queda como lectura incompleta",
	)
	_comprobar(
		LiteraturaEventos.eventos(
			GestorLiteratura.registro_literario,
			LiteraturaEventos.CANAL_INSIGHT,
		).is_empty(),
		"hojear no crea insight",
	)

	var completa: Dictionary = libro.avanzar_lectura(5)
	_comprobar(bool(completa.get("completa", false)), "el segundo paso completa la lectura")
	_comprobar(bool(completa.get("conocimiento_nuevo", false)), "la lectura crea conocimiento")
	_comprobar(bool(completa.get("insight_nuevo", false)), "la lectura crea insight")
	_comprobar(
		not LiteraturaEventos.obra_poseida(
			GestorLiteratura.registro_literario,
			"vida_es_sueno_1635",
		),
		"leer en biblioteca no concede posesion",
	)

	var ritual := (
		GestorLiteratura
		. ejecutar_ritual_cita(
			"vida_es_sueno_1635",
			"biblioteca:mesa_cita",
			"biblioteca:practica:01",
			5,
			70.0,
		)
	)
	_comprobar(bool(ritual.get("aplicado", false)), "la mesa puede ejecutar el ritual")
	_comprobar(
		is_equal_approx(float(ritual.get("momentum_restante", 0.0)), 40.0),
		"el ritual conserva el coste explicito",
	)
	var modificador: Dictionary = ritual.get("modificador", {})
	_comprobar(
		String(modificador.get("estado", "")) == "miedo",
		"el ritual devuelve el buff contextual esperado",
	)
	_comprobar(
		String(modificador.get("duracion", "")) == "encuentro_actual",
		"el buff queda limitado al encuentro",
	)

	var repetido := (
		GestorLiteratura
		. ejecutar_ritual_cita(
			"vida_es_sueno_1635",
			"biblioteca:mesa_cita",
			"biblioteca:practica:01",
			5,
			40.0,
		)
	)
	_comprobar(not bool(repetido.get("aplicado", false)), "la misma cita no se duplica")
	_comprobar(
		String(repetido.get("motivo", "")) == "ya_ejecutado",
		"la mesa conserva idempotencia por encuentro",
	)

	libro.free()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO #1181: %s" % nombre)
