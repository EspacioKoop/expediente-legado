## Regresión headless de composición mixta (#2268 / #2067).
extends SceneTree

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")
const MIXTO = preload("res://guion/juicio_combate_mixto_runtime_2067.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_determinismo_y_composicion()
	_probar_presupuesto_enjambre()
	_probar_derrotas_estables()
	_probar_singular_independiente()
	_probar_terminacion_unica()
	_probar_ventana_compuesta()
	print("mixto_runtime_2067: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_determinismo_y_composicion() -> void:
	var a := MIXTO.nuevo(2067, ARQUETIPOS.BLOQUEADOR)
	var b := MIXTO.nuevo(2067, ARQUETIPOS.BLOQUEADOR)
	_comprobar(a == b, "mismo seed produce composición idéntica")
	_comprobar(a["enjambre"].size() == 2, "composición usa dos cuerpos ENJAMBRE")
	_comprobar(
		String(a["singular"]["tipo"]) == ARQUETIPOS.BLOQUEADOR,
		"singular conserva BLOQUEADOR",
	)
	var hostigador := MIXTO.nuevo(2067, ARQUETIPOS.HOSTIGADOR)
	_comprobar(
		String(hostigador["singular"]["tipo"]) == ARQUETIPOS.HOSTIGADOR,
		"composición admite HOSTIGADOR",
	)


func _probar_presupuesto_enjambre() -> void:
	var estado := MIXTO.nuevo(2067, ARQUETIPOS.BLOQUEADOR)
	for unidad in estado["enjambre"]:
		unidad["cooldown"] = 0.0
	var maximo := HOST.presupuesto_enjambre()
	for _tick in range(240):
		var paso := (
			MIXTO
			. avanzar(
				estado,
				0.02,
				{"flanqueado": false, "guardia_rota": false},
			)
		)
		estado = paso["estado"]
		_comprobar(
			int(paso["enjambre"]["atacantes_activos"]) <= maximo,
			"arena mixta no amplía presupuesto ENJAMBRE",
		)


func _probar_derrotas_estables() -> void:
	var estado := MIXTO.nuevo(2067, ARQUETIPOS.BLOQUEADOR)
	var unidad_uno: Dictionary = estado["enjambre"][1].duplicate(true)
	var paso := MIXTO.avanzar(estado, 0.01, {}, [0])
	_comprobar(int(paso["vivos_enjambre"]) == 1, "derrotar un cuerpo conserva otro vivo")
	_comprobar(
		int(paso["estado"]["enjambre"][0]["determinacion"]) == 0,
		"derrotado permanece en su índice",
	)
	_comprobar(
		paso["estado"]["enjambre"][1] != {},
		"segundo índice sigue presente",
	)
	_comprobar(
		String(paso["estado"]["enjambre"][1]["tipo"]) == String(unidad_uno["tipo"]),
		"derrota no reindexa el compañero",
	)
	paso = MIXTO.avanzar(paso["estado"], 10.0, {}, [])
	_comprobar(
		int(paso["estado"]["enjambre"][0]["determinacion"]) == 0,
		"derrotado no reaparece tras ticks posteriores",
	)


func _probar_singular_independiente() -> void:
	var estado := MIXTO.nuevo(2067, ARQUETIPOS.HOSTIGADOR)
	var paso := (
		MIXTO
		. avanzar(
			estado,
			0.01,
			{"distancia": 6.0, "rumbo_objetivo": 0.5},
			[],
			true,
		)
	)
	_comprobar(not bool(paso["singular_vivo"]), "singular puede caer sin matar enjambre")
	_comprobar(int(paso["vivos_enjambre"]) == 2, "enjambre sigue activo sin singular")
	_comprobar(paso["singular"].is_empty(), "singular derrotado deja de avanzar")
	_comprobar(not bool(paso["terminado"]), "encuentro no termina mientras queden cuerpos")


func _probar_terminacion_unica() -> void:
	var estado := MIXTO.nuevo(2067, ARQUETIPOS.BLOQUEADOR)
	var paso := MIXTO.avanzar(estado, 0.01, {}, [0, 1], false)
	_comprobar(not bool(paso["terminado"]), "matar enjambre no basta con singular vivo")
	paso = MIXTO.avanzar(paso["estado"], 0.01, {}, [], true)
	_comprobar(bool(paso["terminado"]), "termina al caer último rival de ambos grupos")
	_comprobar(int(paso["vivos_enjambre"]) == 0, "terminación conserva enjambre a cero")
	_comprobar(not bool(paso["singular_vivo"]), "terminación conserva singular derrotado")
	var repetido := MIXTO.avanzar(paso["estado"], 1.0)
	_comprobar(bool(repetido["terminado"]), "estado terminado no revive ni se softlockea")


func _probar_ventana_compuesta() -> void:
	var estado := MIXTO.nuevo(2067, ARQUETIPOS.BLOQUEADOR)
	estado["singular"]["estado"] = ARQUETIPOS.APERTURA
	estado["singular"]["temporizador"] = 0.4
	var paso := MIXTO.avanzar(estado, 0.01)
	_comprobar(bool(paso["ventana_respuesta"]), "ventana singular se expone en arena mixta")

	estado = MIXTO.nuevo(2067, ARQUETIPOS.BLOQUEADOR)
	estado["enjambre"][0]["estado"] = ARQUETIPOS.RECUPERAR
	estado["enjambre"][0]["temporizador"] = 0.4
	paso = MIXTO.avanzar(estado, 0.01)
	_comprobar(bool(paso["ventana_respuesta"]), "ventana ENJAMBRE también se expone")


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if not condicion:
		_fallos += 1
		push_error("FALLO #2268 mixto: " + mensaje)
