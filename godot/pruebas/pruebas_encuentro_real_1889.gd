extends SceneTree

const Encuentro := preload("res://guion/dia_encuentro_real_1889_app.gd")

var _fallos := 0
var _pasadas := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var jornada := {"fase": "trayecto", "dia": 2}
	var encuentro := Encuentro.new()
	get_root().add_child(encuentro)
	encuentro.configurar(jornada)
	await process_frame

	_comprobar(encuentro.zona_interactiva() != null, "el encuentro monta una interaccion real")
	_comprobar(not encuentro.resuelto(), "el encuentro empieza pendiente")
	_comprobar(
		jornada.get(Encuentro.CLAVE_ESTADO, {}).is_empty(), "no aplica consecuencia al montar"
	)

	var objetivo := encuentro.objetivo()
	var decision := CombateContextual.evaluar("trayecto", objetivo, {})
	_comprobar(bool(decision.get("permitido", false)), "el objetivo autorado puede abrir combate")
	_comprobar(
		String(decision.get("plano", "")) == CombateContextual.PLANO_REALIDAD,
		"el encuentro se clasifica como realidad",
	)
	_comprobar(
		String(decision.get("consecuencia", {}).get("tipo", "")) == Encuentro.TIPO_CONSECUENCIA,
		"la consecuencia viaja declarada antes de abrir",
	)

	var no_autorizado := objetivo.duplicate(true)
	no_autorizado.erase("combate_autorizado")
	_comprobar(
		not bool(CombateContextual.evaluar("trayecto", no_autorizado, {}).get("permitido", true)),
		"sin autorizacion no se abre arena",
	)
	_comprobar(
		not (
			encuentro
			. resolver_resultado(
				Encuentro.ID_OBJETIVO,
				true,
				{"tipo": "otra_consecuencia"},
			)
		),
		"una consecuencia ajena no muta la jornada",
	)
	_comprobar(jornada.get(Encuentro.CLAVE_ESTADO, {}).is_empty(), "el rechazo deja estado intacto")

	_comprobar(
		(
			encuentro
			. resolver_resultado(
				Encuentro.ID_OBJETIVO,
				true,
				{"tipo": Encuentro.TIPO_CONSECUENCIA},
			)
		),
		"el resultado autorizado se consume",
	)
	_comprobar(encuentro.estado() == "victoria", "la victoria queda acotada a la jornada")
	_comprobar(encuentro.resuelto(), "el encuentro queda resuelto")
	_comprobar(
		not (
			encuentro
			. resolver_resultado(
				Encuentro.ID_OBJETIVO,
				false,
				{"tipo": Encuentro.TIPO_CONSECUENCIA},
			)
		),
		"el resultado es idempotente",
	)

	var jornada_derrota := {"fase": "trayecto", "dia": 2}
	var derrota := Encuentro.new()
	get_root().add_child(derrota)
	derrota.configurar(jornada_derrota)
	_comprobar(
		(
			derrota
			. resolver_resultado(
				Encuentro.ID_OBJETIVO,
				false,
				{"tipo": Encuentro.TIPO_CONSECUENCIA},
			)
		),
		"la derrota tambien se consume por el mismo contrato",
	)
	_comprobar(derrota.estado() == "derrota", "la derrota no inventa otra economia o progreso")

	var repetido := Encuentro.new()
	get_root().add_child(repetido)
	repetido.configurar(jornada)
	_comprobar(repetido.zona_interactiva() == null, "una jornada resuelta no remonta el encuentro")

	print("encuentro_real_1889: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
