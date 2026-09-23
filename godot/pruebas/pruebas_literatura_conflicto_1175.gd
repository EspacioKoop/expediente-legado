extends SceneTree

var pasadas := 0
var fallos := 0


func _initialize() -> void:
	_probar_ritual_explicito()
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _probar_ritual_explicito() -> void:
	var registro := LiteraturaEventos.nuevo()
	var momentum := 70.0
	var resistencia_miedo := 0.0

	var sin_insight := (
		LiteraturaConflicto
		. ejecutar_cita(
			registro,
			"vida_es_sueno_1635",
			"combate:accion:citar",
			"encuentro:archivo:01",
			4,
			momentum,
		)
	)
	_comprobar(not bool(sin_insight["aplicado"]), "sin insight no se aplica el ritual")
	_comprobar(
		String(sin_insight["motivo"]) == "insight_requerido",
		"el ritual explica que falta insight",
	)
	_comprobar(
		is_equal_approx(float(sin_insight["momentum_restante"]), momentum),
		"fallar por falta de insight no consume momentum",
	)
	_comprobar(is_equal_approx(resistencia_miedo, 0.0), "leer aun no ha alterado el combate")

	var lectura := (
		LiteraturaLectura
		. registrar_interaccion(
			registro,
			"vida_es_sueno_1635",
			"documento:biblioteca:estante_03",
			4,
			1.0,
		)
	)
	_comprobar(bool(lectura["insight_nuevo"]), "la lectura significativa produce insight")
	_comprobar(
		LiteraturaEventos.eventos(registro, LiteraturaEventos.CANAL_RITUAL).is_empty(),
		"leer no ejecuta rituales",
	)
	_comprobar(is_equal_approx(momentum, 70.0), "leer no cambia momentum")
	_comprobar(is_equal_approx(resistencia_miedo, 0.0), "leer no concede resistencia")

	var cita := (
		LiteraturaConflicto
		. ejecutar_cita(
			registro,
			"vida_es_sueno_1635",
			"combate:accion:citar",
			"encuentro:archivo:01",
			4,
			momentum,
		)
	)
	_comprobar(bool(cita["aplicado"]), "el ritual explicito aplica el efecto")
	_comprobar(bool(cita["ritual_nuevo"]), "el ritual queda registrado como hecho nuevo")
	_comprobar(
		String(cita["motivo"]) == "ritual_ejecutado",
		"el resultado distingue ejecucion real",
	)
	_comprobar(
		is_equal_approx(float(cita["momentum_restante"]), 40.0),
		"el consumidor cobra 30 de momentum",
	)
	var modificador: Dictionary = cita["modificador"]
	_comprobar(
		String(modificador.get("tipo", "")) == "resistencia_estado",
		"el efecto de combate es contextual",
	)
	_comprobar(
		String(modificador.get("estado", "")) == "miedo",
		"La vida es sueno habilita resistencia al miedo",
	)
	_comprobar(
		String(modificador.get("duracion", "")) == "encuentro_actual",
		"el efecto esta acotado al encuentro",
	)
	resistencia_miedo += float(modificador.get("delta", 0.0))
	momentum = float(cita["momentum_restante"])
	_comprobar(is_equal_approx(resistencia_miedo, 0.25), "el consumidor puede aplicar el delta")

	var repetida := (
		LiteraturaConflicto
		. ejecutar_cita(
			registro,
			"vida_es_sueno_1635",
			"combate:accion:citar",
			"encuentro:archivo:01",
			4,
			momentum,
		)
	)
	_comprobar(not bool(repetida["aplicado"]), "el mismo ritual no se aplica dos veces")
	_comprobar(String(repetida["motivo"]) == "ya_ejecutado", "la idempotencia es explicita")
	_comprobar(
		is_equal_approx(float(repetida["momentum_restante"]), momentum),
		"repetir el ritual no vuelve a cobrar momentum",
	)
	_comprobar(
		LiteraturaEventos.eventos(registro, LiteraturaEventos.CANAL_RITUAL).size() == 1,
		"solo se registra un ritual por encuentro/obra/efecto",
	)

	var sin_recurso := (
		LiteraturaConflicto
		. ejecutar_cita(
			registro,
			"vida_es_sueno_1635",
			"combate:accion:citar",
			"encuentro:archivo:02",
			4,
			20.0,
		)
	)
	_comprobar(not bool(sin_recurso["aplicado"]), "un encuentro nuevo exige pagar el coste")
	_comprobar(
		String(sin_recurso["motivo"]) == "momentum_insuficiente",
		"el coste insuficiente se informa sin registrar ritual",
	)
	_comprobar(
		LiteraturaEventos.eventos(registro, LiteraturaEventos.CANAL_RITUAL).size() == 1,
		"fallar por coste no crea un hecho ritual",
	)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO #1175/#1183: %s" % nombre)
