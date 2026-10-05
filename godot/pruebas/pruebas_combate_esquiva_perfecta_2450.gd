## Regresión headless de esquiva perfecta (#2450).
extends SceneTree

const PERFECTA = preload("res://guion/juicio_combate_esquiva_perfecta.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_ventana_valida()
	_probar_demasiado_pronto_y_tarde()
	_probar_limites_exactos()
	_probar_amenaza_invalida()
	_probar_idempotencia()
	_probar_amenazas_distintas()
	_probar_determinismo()
	print("combate_esquiva_perfecta_2450: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_ventana_valida() -> void:
	var resultado := _evaluar(PERFECTA.nuevo(), "hostigador:1", true, true, 0.08, 0.10)
	_comprobar(bool(resultado["perfecta"]), "amenaza dentro de ventana produce perfecta")
	_comprobar(
		String(resultado["amenaza_consumida"]) == "hostigador:1",
		"devuelve la amenaza consumida",
	)
	_comprobar(
		is_equal_approx(float(resultado["ventana_contraataque"]), PERFECTA.VENTANA_CONTRAATAQUE),
		"perfecta abre contraataque declarativo",
	)
	_comprobar(
		int(resultado["bonus_momentum"]) == PERFECTA.BONUS_MOMENTUM,
		"perfecta declara bonus de momentum",
	)


func _probar_demasiado_pronto_y_tarde() -> void:
	var temprano := _evaluar(
		PERFECTA.nuevo(), "golpe:temprano", true, true, PERFECTA.VENTANA_IMPACTO + 0.01, 0.10
	)
	_comprobar(not bool(temprano["perfecta"]), "amenaza lejana sigue siendo esquiva normal")

	var tarde := _evaluar(PERFECTA.nuevo(), "golpe:tarde", true, true, -0.001, 0.10)
	_comprobar(not bool(tarde["perfecta"]), "impacto ya ocurrido no concede perfecta")

	var recovery := _evaluar(
		PERFECTA.nuevo(), "golpe:recovery", true, true, 0.05, PERFECTA.ESQUIVA_MAXIMA + 0.01
	)
	_comprobar(not bool(recovery["perfecta"]), "recovery tardío no concede perfecta")


func _probar_limites_exactos() -> void:
	var impacto := _evaluar(
		PERFECTA.nuevo(),
		"borde:impacto",
		true,
		true,
		PERFECTA.VENTANA_IMPACTO,
		PERFECTA.ESQUIVA_MINIMA,
	)
	_comprobar(bool(impacto["perfecta"]), "borde exterior de impacto es inclusivo")

	var esquiva := _evaluar(
		PERFECTA.nuevo(), "borde:esquiva", true, true, 0.0, PERFECTA.ESQUIVA_MAXIMA
	)
	_comprobar(bool(esquiva["perfecta"]), "bordes exactos de esquiva son inclusivos")


func _probar_amenaza_invalida() -> void:
	var sin_impacto := _evaluar(PERFECTA.nuevo(), "senal:decorativa", false, true, 0.05, 0.10)
	_comprobar(not bool(sin_impacto["perfecta"]), "telegraph sin impacto no premia")

	var sin_esquiva := _evaluar(PERFECTA.nuevo(), "golpe:real", true, false, 0.05, 0.10)
	_comprobar(not bool(sin_esquiva["perfecta"]), "sin esquiva activa no existe perfecta")

	var sin_id := _evaluar(PERFECTA.nuevo(), " ", true, true, 0.05, 0.10)
	_comprobar(not bool(sin_id["perfecta"]), "amenaza sin id no puede premiar")


func _probar_idempotencia() -> void:
	var primero := _evaluar(PERFECTA.nuevo(), "embestidor:7", true, true, 0.04, 0.08)
	var segundo := _evaluar(primero["estado"], "embestidor:7", true, true, 0.03, 0.09)
	_comprobar(bool(primero["perfecta"]), "primera resolución de amenaza premia")
	_comprobar(not bool(segundo["perfecta"]), "misma amenaza no premia dos veces")
	_comprobar(
		PERFECTA.consumida(segundo["estado"], "embestidor:7"),
		"estado recuerda amenaza consumida",
	)


func _probar_amenazas_distintas() -> void:
	var primera := _evaluar(PERFECTA.nuevo(), "enjambre:0", true, true, 0.06, 0.08)
	var segunda := _evaluar(primera["estado"], "enjambre:1", true, true, 0.06, 0.08)
	_comprobar(bool(segunda["perfecta"]), "amenaza distinta puede conceder otra perfecta")


func _probar_determinismo() -> void:
	var a := _evaluar(PERFECTA.nuevo(), "det:1", true, true, 0.07, 0.11)
	var b := _evaluar(PERFECTA.nuevo(), "det:1", true, true, 0.07, 0.11)
	_comprobar(a == b, "mismos datos producen exactamente la misma salida")


func _evaluar(
	estado: Dictionary,
	id: String,
	valida: bool,
	esquivando: bool,
	hasta: float,
	desde: float,
) -> Dictionary:
	return PERFECTA.evaluar(estado, id, valida, esquivando, hasta, desde)


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if not condicion:
		_fallos += 1
		push_error("FALLO #2450 esquiva perfecta: " + mensaje)
