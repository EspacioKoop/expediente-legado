## Regresión headless de receta de impacto (#2473).
extends SceneTree

const IMPACTO = preload("res://guion/juicio_combate_impacto_feedback.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_jerarquia()
	_probar_bloqueado()
	_probar_stagger()
	_probar_reduccion_movimiento()
	_probar_limites()
	_probar_desconocido()
	_probar_determinismo()
	print("combate_impacto_feedback_2473: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_jerarquia() -> void:
	var ligero := IMPACTO.receta(IMPACTO.LIGERO)
	var fuerte := IMPACTO.receta(IMPACTO.FUERTE)
	var finisher := IMPACTO.receta(IMPACTO.FINISHER)
	_comprobar(
		float(ligero["hitstop"]) < float(fuerte["hitstop"]),
		"fuerte tiene más hitstop que ligero",
	)
	_comprobar(
		float(fuerte["hitstop"]) < float(finisher["hitstop"]),
		"finisher tiene más hitstop que fuerte",
	)
	_comprobar(
		float(ligero["shake"]) < float(fuerte["shake"]),
		"fuerte tiene más shake que ligero",
	)
	_comprobar(
		float(fuerte["shake"]) < float(finisher["shake"]),
		"finisher tiene más shake que fuerte",
	)


func _probar_bloqueado() -> void:
	var limpio := IMPACTO.receta(IMPACTO.LIGERO)
	var bloqueado := IMPACTO.receta(IMPACTO.BLOQUEADO)
	_comprobar(
		is_zero_approx(float(bloqueado["desplazamiento_reaccion"])),
		"bloqueado no desplaza al rival",
	)
	_comprobar(
		int(bloqueado["particulas"]) < int(limpio["particulas"]),
		"bloqueado usa feedback más seco",
	)
	_comprobar(not bool(bloqueado["flash"]), "bloqueado no usa flash ofensivo")


func _probar_stagger() -> void:
	var stagger := IMPACTO.receta(IMPACTO.STAGGER)
	var fuerte := IMPACTO.receta(IMPACTO.FUERTE)
	var finisher := IMPACTO.receta(IMPACTO.FINISHER)
	_comprobar(
		float(stagger["hitstop"]) > float(fuerte["hitstop"]),
		"stagger se distingue de fuerte",
	)
	_comprobar(
		float(stagger["hitstop"]) < float(finisher["hitstop"]),
		"stagger no supera al finisher",
	)


func _probar_reduccion_movimiento() -> void:
	var normal := IMPACTO.receta(IMPACTO.FUERTE)
	var reducido := IMPACTO.receta(IMPACTO.FUERTE, true)
	_comprobar(
		is_equal_approx(float(normal["hitstop"]), float(reducido["hitstop"])),
		"reducción conserva duración temporal",
	)
	_comprobar(is_zero_approx(float(reducido["shake"])), "reducción elimina shake")
	_comprobar(
		is_zero_approx(float(reducido["desplazamiento_reaccion"])),
		"reducción elimina desplazamiento animado",
	)
	_comprobar(not bool(reducido["flash"]), "reducción elimina flash animado")
	_comprobar(bool(reducido["senal_estatica"]), "reducción conserva señal estática")


func _probar_limites() -> void:
	for tipo in [
		IMPACTO.LIGERO,
		IMPACTO.FUERTE,
		IMPACTO.FINISHER,
		IMPACTO.STAGGER,
		IMPACTO.BLOQUEADO,
	]:
		var receta := IMPACTO.receta(tipo)
		_comprobar(float(receta["hitstop"]) <= IMPACTO.HITSTOP_MAX, "hitstop queda capado")
		_comprobar(float(receta["shake"]) <= IMPACTO.SHAKE_MAX, "shake queda capado")
		_comprobar(
			float(receta["desplazamiento_reaccion"]) <= IMPACTO.REACCION_MAX,
			"reacción queda capada",
		)


func _probar_desconocido() -> void:
	var receta := IMPACTO.receta("desconocido")
	_comprobar(is_zero_approx(float(receta["hitstop"])), "tipo desconocido no inventa hitstop")
	_comprobar(int(receta["particulas"]) == 0, "tipo desconocido no inventa partículas")


func _probar_determinismo() -> void:
	var a := IMPACTO.receta(IMPACTO.STAGGER, true)
	var b := IMPACTO.receta(IMPACTO.STAGGER, true)
	_comprobar(a == b, "mismo evento produce misma receta")


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if not condicion:
		_fallos += 1
		push_error("FALLO #2473 impacto feedback: " + mensaje)
